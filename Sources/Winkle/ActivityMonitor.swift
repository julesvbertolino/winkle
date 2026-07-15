import CoreGraphics

/// Mesure l'inactivité clavier et souris séparément, via CGEventSource
/// (aucune permission requise : on lit des délais, jamais le contenu des frappes).
enum ActivityMonitor {
    private static let keyboardEvents: [CGEventType] = [.keyDown, .flagsChanged]
    private static let mouseEvents: [CGEventType] = [
        .mouseMoved, .leftMouseDown, .rightMouseDown, .otherMouseDown,
        .leftMouseDragged, .rightMouseDragged, .scrollWheel,
    ]

    /// Secondes depuis le dernier événement clavier.
    static var keyboardIdleSeconds: Double {
        idleSeconds(for: keyboardEvents)
    }

    /// Secondes depuis le dernier événement souris / trackpad.
    static var mouseIdleSeconds: Double {
        idleSeconds(for: mouseEvents)
    }

    /// Repos naturel : clavier ET souris inactifs depuis au moins `threshold` secondes.
    static func isNaturallyResting(threshold: Double) -> Bool {
        keyboardIdleSeconds >= threshold && mouseIdleSeconds >= threshold
    }

    private static func idleSeconds(for events: [CGEventType]) -> Double {
        events
            .map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }
            .min() ?? .infinity
    }
}
