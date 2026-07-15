import SwiftUI

/// Contenu de l'overlay de pause : invitation puis compte à rebours.
struct OverlayRootView: View {
    @ObservedObject var engine: BreakEngine
    @State private var mouse = CGPoint(x: 0.5, y: 0.5)

    var body: some View {
        ZStack {
            WinkleBackground(mouse: mouse)
            switch engine.phase {
            case .prompting:
                PromptView(engine: engine)
                    .transition(.opacity)
            case .breaking:
                BreakCountdownView(engine: engine)
                    .transition(.opacity)
            case .counting:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: engine.phase)
        .onContinuousHover { hoverPhase in
            if case .active(let location) = hoverPhase {
                // Normalise par rapport à l'écran ; l'overlay couvre tout l'écran.
                if let screen = NSScreen.main {
                    mouse = CGPoint(
                        x: location.x / screen.frame.width,
                        y: location.y / screen.frame.height
                    )
                }
            }
        }
    }
}

// MARK: - Invitation

private struct PromptView: View {
    @ObservedObject var engine: BreakEngine

    var body: some View {
        VStack(spacing: 0) {
            WinkleEye()
                .padding(.bottom, 30)

            Text(L10n.t("prompt.title"))
                .font(.system(size: 40, weight: .medium, design: .rounded))
                .foregroundColor(WinkleStyle.ink)
                .padding(.bottom, 16)

            Text(L10n.t("prompt.hint"))
                .font(.system(size: 17))
                .foregroundColor(WinkleStyle.inkDim)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.bottom, 44)

            VStack(spacing: 12) {
                Button(action: { engine.startBreakCountdown() }) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.55))
                                .frame(width: 40, height: 40)
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(WinkleStyle.buttonInk)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(L10n.t("prompt.start"))
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                            Text("\(engine.prefs.pauseDuration) \(L10n.t("prompt.startSub"))")
                                .font(.system(size: 12))
                                .opacity(0.7)
                        }
                    }
                    .foregroundColor(WinkleStyle.buttonInk)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 34)
                    .background(
                        LinearGradient(
                            colors: [WinkleStyle.periSoft, Color(red: 0.624, green: 0.737, blue: 1.0)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: WinkleStyle.periDeep.opacity(0.5), radius: 17, y: 6)
                }
                .buttonStyle(.plain)

                Button(action: { engine.snooze() }) {
                    Text(L10n.t("prompt.snooze"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(WinkleStyle.inkDim)
                        .padding(.vertical, 11)
                        .padding(.horizontal, 22)
                        .background(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: { engine.skip() }) {
                    Text(L10n.t("prompt.skip"))
                        .font(.system(size: 12.5))
                        .foregroundColor(WinkleStyle.inkFaint)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Compte à rebours

private struct BreakCountdownView: View {
    @ObservedObject var engine: BreakEngine
    @State private var breathe = false

    private var progress: CGFloat {
        let total = CGFloat(max(engine.prefs.pauseDuration, 1))
        return CGFloat(engine.breakRemaining) / total
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(WinkleStyle.peri, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: WinkleStyle.peri, radius: 6)
                    .animation(.linear(duration: 1), value: progress)
                VStack(spacing: 2) {
                    Text("\(engine.breakRemaining)")
                        .font(.system(size: 62, design: .rounded))
                        .foregroundColor(WinkleStyle.ink)
                        .monospacedDigit()
                    Text(L10n.t("break.seconds").uppercased())
                        .font(.system(size: 11))
                        .tracking(3)
                        .foregroundColor(WinkleStyle.inkFaint)
                }
            }
            .frame(width: 200, height: 200)
            .scaleEffect(breathe ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: breathe)
            .padding(.bottom, 34)
            .onAppear { breathe = true }

            Text(L10n.t("break.title"))
                .font(.system(size: 40, weight: .medium, design: .rounded))
                .foregroundColor(WinkleStyle.ink)
                .padding(.bottom, 16)

            Text(L10n.t("break.hint"))
                .font(.system(size: 17))
                .foregroundColor(WinkleStyle.inkDim)
                .padding(.bottom, 30)

            if !engine.prefs.strictMode {
                Button(action: { engine.endBreakEarly() }) {
                    Text(L10n.t("break.end"))
                        .font(.system(size: 12.5))
                        .foregroundColor(WinkleStyle.inkFaint)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 30)
    }
}
