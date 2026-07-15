import AppKit
import CoreMediaIO

/// Raison pour laquelle le compteur est gelé (état 🔵 Suspendu).
enum SuspensionReason: Equatable {
    case manual(until: Date?)   // nil = jusqu'à réactivation
    case camera                 // visio en cours
    case fullscreen             // vidéo / app plein écran
    case whitelistedApp(String)
    case doNotDisturb
}

/// Évalue les règles de suspension du §5 : visio, plein écran, whitelist, Ne pas déranger.
enum SuspensionMonitor {

    static func currentReason(prefs: Preferences, manualUntil: Date??) -> SuspensionReason? {
        if case .some(let until) = manualUntil {
            if let until, until < Date() {
                // Suspension manuelle expirée — l'appelant la nettoiera au prochain tick.
            } else {
                return .manual(until: until ?? nil)
            }
        }
        if let bundleID = frontmostWhitelistedApp(prefs: prefs) {
            return .whitelistedApp(bundleID)
        }
        if prefs.suspendOnCamera, isCameraInUse() {
            return .camera
        }
        if prefs.suspendOnFullscreen, hasFullscreenWindow() {
            return .fullscreen
        }
        if prefs.respectDoNotDisturb, isFocusActive() {
            return .doNotDisturb
        }
        return nil
    }

    // MARK: - Whitelist

    private static func frontmostWhitelistedApp(prefs: Preferences) -> String? {
        guard let front = NSWorkspace.shared.frontmostApplication,
              let bundleID = front.bundleIdentifier else { return nil }
        return prefs.whitelistApps.contains(bundleID) ? bundleID : nil
    }

    // MARK: - Caméra (visio) — lecture d'un simple statut, jamais du flux vidéo.

    static func isCameraInUse() -> Bool {
        var address = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        var dataSize: UInt32 = 0
        guard CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &address, 0, nil, &dataSize) == noErr,
              dataSize > 0 else { return false }

        let count = Int(dataSize) / MemoryLayout<CMIOObjectID>.size
        var devices = [CMIOObjectID](repeating: 0, count: count)
        var dataUsed: UInt32 = 0
        guard CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &address, 0, nil,
                                        dataSize, &dataUsed, &devices) == noErr else { return false }

        var runningAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
        )
        for device in devices {
            var isRunning: UInt32 = 0
            var used: UInt32 = 0
            let size = UInt32(MemoryLayout<UInt32>.size)
            if CMIOObjectGetPropertyData(device, &runningAddress, 0, nil, size, &used, &isRunning) == noErr,
               isRunning != 0 {
                return true
            }
        }
        return false
    }

    // MARK: - Plein écran

    /// Heuristique v1 : une fenêtre de premier plan (layer 0) couvre exactement un écran.
    /// Couvre les lecteurs vidéo plein écran ; ne distingue pas encore "vidéo" d'une app
    /// quelconque en plein écran (affinage prévu, cf. spec §5).
    static func hasFullscreenWindow() -> Bool {
        guard let windows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
        ) as? [[String: Any]] else { return false }

        let ownPID = ProcessInfo.processInfo.processIdentifier
        let screenSizes = NSScreen.screens.map { $0.frame.size }

        for window in windows {
            guard let layer = window[kCGWindowLayer as String] as? Int, layer == 0,
                  let pid = window[kCGWindowOwnerPID as String] as? pid_t, pid != ownPID,
                  let boundsDict = window[kCGWindowBounds as String] as? [String: CGFloat]
            else { continue }
            let size = CGSize(width: boundsDict["Width"] ?? 0, height: boundsDict["Height"] ?? 0)
            // La barre de menus disparaît en plein écran : la fenêtre couvre 100 % de l'écran.
            if screenSizes.contains(where: { abs($0.width - size.width) < 1 && abs($0.height - size.height) < 1 }) {
                return true
            }
        }
        return false
    }

    // MARK: - Ne pas déranger / Focus

    /// Lit les assertions Focus de macOS (fichier local, aucune API privée appelée).
    /// Retourne false silencieusement si le format change ou si le fichier est illisible.
    static func isFocusActive() -> Bool {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/DoNotDisturb/DB/Assertions.json")
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let records = json["data"] as? [[String: Any]]
        else { return false }
        return records.contains { record in
            guard let assertions = record["storeAssertionRecords"] as? [[String: Any]] else { return false }
            return !assertions.isEmpty
        }
    }
}
