import Foundation
import UserNotifications

/// Notifications locales (pré-alerte et invitation à la pause).
///
/// UNUserNotificationCenter exige un vrai bundle .app : lancé en binaire nu
/// (`swift run`), on saute silencieusement — utiliser `make app` pour tester.
enum Notifier {
    private static var isAvailable: Bool { Bundle.main.bundleIdentifier != nil }
    private static var authorizationRequested = false

    static func requestAuthorizationIfNeeded() {
        guard isAvailable, !authorizationRequested else { return }
        authorizationRequested = true
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func sendPreAlert() {
        send(title: L10n.t("notif.preAlert.title"), body: L10n.t("notif.preAlert.body"))
    }

    static func sendBreakInvitation(duration: Int) {
        send(
            title: L10n.t("notif.break.title"),
            body: String(format: L10n.t("notif.break.body"), duration)
        )
    }

    private static func send(title: String, body: String) {
        guard isAvailable else { return }
        requestAuthorizationIfNeeded()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(
            identifier: UUID().uuidString, content: content, trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
