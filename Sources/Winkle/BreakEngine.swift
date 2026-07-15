import AppKit
import Combine

/// Machine à états du cycle 20-20-20.
///
/// Tick 1 s : incrémente le temps d'écran quand l'utilisateur est actif,
/// remet à zéro en repos naturel, gèle en suspension, et déclenche
/// pré-alerte puis invitation à la pause.
@MainActor
final class BreakEngine: ObservableObject {

    enum Phase: Equatable {
        case counting          // 🟢 / ⚪️ — le compteur vit sa vie
        case prompting         // overlay "C'est le moment d'une pause"
        case breaking          // compte à rebours de pause en cours
    }

    @Published private(set) var phase: Phase = .counting
    @Published private(set) var screenSeconds: Int = 0
    @Published private(set) var breakRemaining: Int = 0
    @Published private(set) var suspensionReason: SuspensionReason?

    /// Suspension manuelle : `.some(nil)` = jusqu'à réactivation, `.some(date)` = jusqu'à date.
    private var manualSuspensionUntil: Date?? = nil
    private var preAlertSent = false
    private var timer: Timer?
    private var breakTimer: Timer?

    let prefs = Preferences.shared
    var overlay: OverlayController?

    var secondsUntilBreak: Int { max(0, prefs.workInterval - screenSeconds) }
    var isSuspended: Bool { suspensionReason != nil }

    func start() {
        timer?.invalidate()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    // MARK: - Tick

    private func tick() {
        // Nettoie une suspension manuelle expirée.
        if case .some(.some(let until)) = manualSuspensionUntil, until < Date() {
            manualSuspensionUntil = nil
        }

        suspensionReason = SuspensionMonitor.currentReason(
            prefs: prefs, manualUntil: manualSuspensionUntil
        )

        guard phase == .counting else {
            // Overlay d'invitation affiché mais l'utilisateur s'est absenté :
            // ses yeux se reposent déjà, on referme sans le culpabiliser.
            if phase == .prompting, !prefs.strictMode,
               ActivityMonitor.isNaturallyResting(threshold: Double(prefs.idleResetSeconds)) {
                dismissPrompt(resetCounter: true)
            }
            return
        }

        // 🔵 Suspendu : compteur gelé, aucune alerte.
        if isSuspended { return }

        // ⚪️ Repos naturel : les yeux se sont déjà reposés, on repart de zéro.
        if ActivityMonitor.isNaturallyResting(threshold: Double(prefs.idleResetSeconds)) {
            screenSeconds = 0
            preAlertSent = false
            return
        }

        // 🟢 Actif.
        screenSeconds += 1

        if prefs.preAlertEnabled, !preAlertSent, secondsUntilBreak == 20,
           prefs.displayMode != .notification {
            preAlertSent = true
            Notifier.sendPreAlert()
        }

        if screenSeconds >= prefs.workInterval {
            triggerBreak()
        }
    }

    // MARK: - Déclenchement

    func triggerBreak() {
        guard phase == .counting else { return }
        preAlertSent = false

        switch prefs.displayMode {
        case .notification:
            // Pas d'overlay : simple invitation, puis nouveau cycle.
            Notifier.sendBreakInvitation(duration: prefs.pauseDuration)
            screenSeconds = 0
        case .overlay, .both:
            if prefs.displayMode == .both {
                Notifier.sendBreakInvitation(duration: prefs.pauseDuration)
            }
            phase = .prompting
            if prefs.soundEnabled { NSSound(named: "Glass")?.play() }
            if prefs.strictMode {
                startBreakCountdown()
            } else {
                overlay?.showPrompt()
            }
        }
    }

    // MARK: - Actions utilisateur

    /// « Lancer la pause »
    func startBreakCountdown() {
        phase = .breaking
        breakRemaining = prefs.pauseDuration
        overlay?.showBreak()

        breakTimer?.invalidate()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.breakRemaining -= 1
                if self.breakRemaining <= 0 { self.endBreak(completed: true) }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        breakTimer = timer
    }

    /// « Reporter · +5 min » — sans limite de reports.
    func snooze() {
        dismissPrompt(resetCounter: false)
        screenSeconds = max(0, prefs.workInterval - 5 * 60)
    }

    /// « Ignorer » — rendez-vous au prochain cycle.
    func skip() {
        dismissPrompt(resetCounter: true)
    }

    /// « Terminer maintenant » pendant la pause (indisponible en mode strict).
    func endBreakEarly() {
        guard !prefs.strictMode else { return }
        endBreak(completed: false)
    }

    /// « Pause maintenant » depuis la barre de menus.
    func breakNow() {
        guard phase == .counting else { return }
        screenSeconds = prefs.workInterval
        triggerBreak()
    }

    // MARK: - Suspension manuelle

    func suspend(hours: Int?) {
        manualSuspensionUntil = .some(hours.map { Date().addingTimeInterval(Double($0) * 3600) })
    }

    func resumeFromManualSuspension() {
        manualSuspensionUntil = nil
    }

    var isManuallySuspended: Bool {
        if case .some = manualSuspensionUntil { return true }
        return false
    }

    // MARK: - Interne

    private func endBreak(completed: Bool) {
        breakTimer?.invalidate()
        breakTimer = nil
        if completed, prefs.soundEnabled { NSSound(named: "Blow")?.play() }
        overlay?.hide()
        screenSeconds = 0
        phase = .counting
    }

    private func dismissPrompt(resetCounter: Bool) {
        overlay?.hide()
        if resetCounter { screenSeconds = 0 }
        phase = .counting
    }
}
