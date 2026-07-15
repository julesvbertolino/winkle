import AppKit
import SwiftUI

@main
struct WinkleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuContent(engine: appDelegate.engine)
        } label: {
            MenuBarLabel(engine: appDelegate.engine)
        }
    }
}

// MARK: - Barre de menus

struct MenuBarLabel: View {
    @ObservedObject var engine: BreakEngine

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: engine.isSuspended ? "eye.slash" : "eye")
            if !engine.isSuspended {
                Text(countdown)
                    .monospacedDigit()
            }
        }
    }

    private var countdown: String {
        let seconds = engine.secondsUntilBreak
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

struct MenuContent: View {
    @ObservedObject var engine: BreakEngine

    var body: some View {
        if let reason = engine.suspensionReason {
            Text("\(L10n.t("menu.suspended")) · \(describe(reason))")
        } else {
            Text("\(L10n.t("menu.nextPause")) \(format(engine.secondsUntilBreak))")
        }

        Divider()

        Button(L10n.t("menu.pauseNow")) { engine.breakNow() }
            .disabled(engine.phase != .counting)

        if engine.isManuallySuspended {
            Button(L10n.t("menu.resume")) { engine.resumeFromManualSuspension() }
        } else {
            Menu(L10n.t("menu.suspend")) {
                Button(L10n.t("menu.suspend1h")) { engine.suspend(hours: 1) }
                Button(L10n.t("menu.suspend2h")) { engine.suspend(hours: 2) }
                Button(L10n.t("menu.suspendUntil")) { engine.suspend(hours: nil) }
            }
        }

        Divider()

        SettingsButton()

        Button(L10n.t("menu.quit")) { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    private func format(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func describe(_ reason: SuspensionReason) -> String {
        switch reason {
        case .manual: return L10n.t("menu.suspend").lowercased()
        case .camera: return "visio"
        case .fullscreen: return "plein écran"
        case .whitelistedApp: return "whitelist"
        case .doNotDisturb: return "focus"
        }
    }
}

/// Ouvre la fenêtre Réglages custom (design signature, sans barre de titre système).
private struct SettingsButton: View {
    var body: some View {
        Button(L10n.t("menu.settings")) {
            (AppDelegate.shared ?? NSApp.delegate as? AppDelegate)?.showSettings()
        }
        .keyboardShortcut(",")
    }
}

// MARK: - AppDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static private(set) weak var shared: AppDelegate?

    let engine = BreakEngine()
    private var overlay: OverlayController?
    private var onboardingWindow: NSWindow?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // App menu bar : pas d'icône dans le Dock.
        NSApp.setActivationPolicy(.accessory)

        overlay = OverlayController(engine: engine)
        engine.overlay = overlay
        engine.start()

        // Aligne le login item système sur la préférence (activé par défaut).
        LoginItem.syncWithPreference()

        if !Preferences.shared.hasCompletedOnboarding {
            showOnboarding()
        }

        // Aide au test : WINKLE_OPEN_SETTINGS=1 ouvre les Réglages au lancement.
        if ProcessInfo.processInfo.environment["WINKLE_OPEN_SETTINGS"] == "1" {
            showSettings()
        }
    }

    func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 660, height: 700),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.backgroundColor = NSColor(red: 0.047, green: 0.078, blue: 0.165, alpha: 1)
            window.isReleasedWhenClosed = false
            window.center()
            window.contentView = NSHostingView(rootView: SettingsView())
            window.delegate = self
            settingsWindow = window
        }
        presentAuxiliaryWindow(settingsWindow)
    }

    /// Ramène une fenêtre auxiliaire au premier plan de façon fiable pour une app
    /// `.accessory` : sans `orderFrontRegardless` + activation, la fenêtre s'ouvre
    /// derrière l'app active et paraît « ne rien faire ».
    private func presentAuxiliaryWindow(_ window: NSWindow?) {
        guard let window else { return }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    func windowWillClose(_ notification: Notification) {
        if (notification.object as? NSWindow) === settingsWindow {
            settingsWindow = nil
        }
    }

    private func showOnboarding() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 560),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: OnboardingView { [weak self] in
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
        })
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window
    }
}
