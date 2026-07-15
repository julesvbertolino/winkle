import Foundation
import ServiceManagement

/// Gère le lancement au démarrage via SMAppService (macOS 13+).
///
/// SMAppService exige un vrai bundle .app enregistré auprès de LaunchServices :
/// en binaire nu (`swift run`), toutes les opérations sont des no-op silencieux.
enum LoginItem {
    private static var isAvailable: Bool { Bundle.main.bundleIdentifier != nil }

    static func set(_ enabled: Bool) {
        guard isAvailable else { return }
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Winkle: login item update failed: \(error)")
        }
    }

    /// Aligne l'enregistrement système sur la préférence stockée (appelé au démarrage).
    static func syncWithPreference() {
        guard isAvailable else { return }
        set(Preferences.shared.launchAtLogin)
    }
}
