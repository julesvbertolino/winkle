import SwiftUI

// MARK: - Presets

enum Preset: String, CaseIterable, Identifiable {
    case relaxed, balanced, intense, custom

    var id: String { rawValue }

    /// (intervalle de travail, durée de pause) en secondes
    var timing: (work: Int, pause: Int)? {
        switch self {
        case .relaxed:  return (30 * 60, 30)
        case .balanced: return (20 * 60, 20)
        case .intense:  return (15 * 60, 20)
        case .custom:   return nil
        }
    }

    var label: String {
        switch self {
        case .relaxed:  return L10n.t("preset.relaxed")
        case .balanced: return L10n.t("preset.balanced")
        case .intense:  return L10n.t("preset.intense")
        case .custom:   return L10n.t("preset.custom")
        }
    }
}

enum DisplayMode: String, CaseIterable, Identifiable {
    case overlay, notification, both
    var id: String { rawValue }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case light, dark, auto
    var id: String { rawValue }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case fr, en
    var id: String { rawValue }
}

// MARK: - Preferences

/// Toutes les préférences persistées (UserDefaults), observables par SwiftUI.
final class Preferences: ObservableObject {
    static let shared = Preferences()

    @AppStorage("preset") var presetRaw: String = Preset.balanced.rawValue
    @AppStorage("customWorkMinutes") var customWorkMinutes: Int = 20
    @AppStorage("customPauseSeconds") var customPauseSeconds: Int = 20
    /// Seuil d'inactivité (repos naturel), en secondes — défaut 90 s.
    @AppStorage("idleResetSeconds") var idleResetSeconds: Int = 90
    @AppStorage("displayMode") var displayModeRaw: String = DisplayMode.overlay.rawValue
    @AppStorage("preAlertEnabled") var preAlertEnabled: Bool = true
    @AppStorage("allScreens") var allScreens: Bool = true
    @AppStorage("strictMode") var strictMode: Bool = false
    @AppStorage("soundEnabled") var soundEnabled: Bool = false
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = true
    @AppStorage("respectDoNotDisturb") var respectDoNotDisturb: Bool = true
    @AppStorage("suspendOnCamera") var suspendOnCamera: Bool = true
    @AppStorage("suspendOnFullscreen") var suspendOnFullscreen: Bool = true
    @AppStorage("themeRaw") var themeRaw: String = AppTheme.auto.rawValue
    @AppStorage("languageRaw") var languageRaw: String = AppLanguage.fr.rawValue
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    /// Bundle identifiers d'apps en whitelist, séparés par des retours ligne.
    @AppStorage("whitelistApps") var whitelistAppsRaw: String = ""

    var preset: Preset {
        get { Preset(rawValue: presetRaw) ?? .balanced }
        set { presetRaw = newValue.rawValue }
    }

    var displayMode: DisplayMode {
        get { DisplayMode(rawValue: displayModeRaw) ?? .overlay }
        set { displayModeRaw = newValue.rawValue }
    }

    var language: AppLanguage {
        get { AppLanguage(rawValue: languageRaw) ?? .fr }
        set { languageRaw = newValue.rawValue; objectWillChange.send() }
    }

    /// Intervalle de travail effectif, en secondes.
    var workInterval: Int {
        preset.timing?.work ?? customWorkMinutes * 60
    }

    /// Durée de pause effective, en secondes.
    var pauseDuration: Int {
        preset.timing?.pause ?? customPauseSeconds
    }

    var whitelistApps: [String] {
        get {
            whitelistAppsRaw
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        set { whitelistAppsRaw = newValue.joined(separator: "\n") }
    }
}
