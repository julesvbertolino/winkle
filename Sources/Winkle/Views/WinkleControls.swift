import AppKit
import SwiftUI

// MARK: - Segmented (pilules periwinkle)

/// Contrôle segmenté maison, calqué sur le design HTML (fond sombre, pilule active periwinkle).
struct WinkleSegmented<T: Hashable>: View {
    let options: [(value: T, label: String)]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { i in
                let option = options[i]
                let isOn = selection == option.value
                Text(option.label)
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(isOn ? WinkleStyle.buttonInk : WinkleStyle.inkDim)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 13)
                    .background {
                        if isOn {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(WinkleStyle.peri.opacity(0.85))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.18)) { selection = option.value }
                    }
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.black.opacity(0.22))
        )
    }
}

// MARK: - Toggle

/// Interrupteur maison (piste periwinkle quand actif).
struct WinkleToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? WinkleStyle.peri : Color.white.opacity(0.16))
            Circle()
                .fill(.white)
                .padding(3)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
        }
        .frame(width: 46, height: 27)
        .contentShape(Capsule())
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.18)) { isOn.toggle() }
        }
    }
}

// MARK: - Rangée & groupe

/// Rangée de réglage : titre (+ description) à gauche, contrôle à droite.
struct SettingRow<Trailing: View>: View {
    let title: String
    var description: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundColor(WinkleStyle.ink)
                if let description {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(WinkleStyle.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.045))
        )
    }
}

/// Groupe de rangées avec en-tête en petites capitales.
struct SettingGroup<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 11.5, weight: .bold))
                .tracking(1.4)
                .foregroundColor(WinkleStyle.inkFaint)
                .padding(.leading, 4)
                .padding(.bottom, 2)
            content()
        }
    }
}

// MARK: - Utilitaires apps

enum AppInfo {
    /// Nom lisible d'une app à partir de son bundle ID (ex. "com.apple.Safari" → "Safari").
    /// Retombe sur le bundle ID si l'app est introuvable.
    static func displayName(forBundleID bundleID: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        else { return bundleID }
        return FileManager.default.displayName(atPath: url.path)
            .replacingOccurrences(of: ".app", with: "")
    }

    /// Ouvre un sélecteur d'applications ; renvoie le bundle ID choisi.
    @MainActor
    static func pickApplication() -> String? {
        let panel = NSOpenPanel()
        panel.title = L10n.t("settings.pickAppTitle")
        panel.prompt = L10n.t("settings.pickAppPrompt")
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return Bundle(url: url)?.bundleIdentifier
    }
}
