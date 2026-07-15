import SwiftUI

/// Onboarding court : valeur de l'app + choix du preset, dans le langage
/// visuel signature (fond bleuté qui suit le curseur).
struct OnboardingView: View {
    @ObservedObject var prefs = Preferences.shared
    @State private var mouse = CGPoint(x: 0.5, y: 0.5)
    @State private var selected: Preset = .balanced
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            WinkleBackground(mouse: mouse)

            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    WinkleEye(size: 46, lineWidth: 4)
                    Text("winkle")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundColor(WinkleStyle.ink)
                }
                .padding(.bottom, 46)

                Text(L10n.t("onb.title"))
                    .font(.system(size: 34, weight: .medium, design: .rounded))
                    .foregroundColor(WinkleStyle.ink)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 18)

                Text(L10n.t("onb.sub"))
                    .font(.system(size: 16))
                    .foregroundColor(WinkleStyle.inkDim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 430)
                    .padding(.bottom, 42)

                HStack(alignment: .top, spacing: 14) {
                    presetCard(.relaxed, description: L10n.t("onb.relaxedDesc"))
                    presetCard(.balanced, description: L10n.t("onb.balancedDesc"))
                    presetCard(.intense, description: L10n.t("onb.intenseDesc"))
                }
                .padding(.bottom, 46)

                Button(action: finish) {
                    Text(L10n.t("onb.start"))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(WinkleStyle.buttonInk)
                        .frame(width: 260)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [WinkleStyle.periSoft, Color(red: 0.624, green: 0.737, blue: 1.0)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: WinkleStyle.periDeep.opacity(0.5), radius: 15, y: 5)
                }
                .buttonStyle(.plain)
            }
            .padding(30)
        }
        .frame(minWidth: 720, minHeight: 560)
        .onContinuousHover { hoverPhase in
            if case .active(let location) = hoverPhase {
                mouse = CGPoint(x: location.x / 720, y: location.y / 560)
            }
        }
    }

    private func presetCard(_ preset: Preset, description: String) -> some View {
        let isSelected = selected == preset
        return Button(action: { selected = preset }) {
            VStack(spacing: 6) {
                Text(preset.label)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(WinkleStyle.ink)
                Text(description)
                    .font(.system(size: 12.5))
                    .foregroundColor(WinkleStyle.inkDim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 176)
            .padding(.vertical, 20)
            .padding(.horizontal, 4)
            .background(isSelected ? WinkleStyle.peri.opacity(0.16) : Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? WinkleStyle.peri : Color.white.opacity(0.10),
                            lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .scaleEffect(isSelected ? 1.06 : 1.0)
            .shadow(color: isSelected ? WinkleStyle.periDeep.opacity(0.30) : .clear, radius: 20, y: 7)
            .animation(.easeOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private func finish() {
        prefs.preset = selected
        prefs.hasCompletedOnboarding = true
        Notifier.requestAuthorizationIfNeeded()
        onFinish()
    }
}
