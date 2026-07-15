import SwiftUI

/// Palette et styles partagés — transcription du design HTML validé.
enum WinkleStyle {
    static let ink       = Color(red: 0.953, green: 0.965, blue: 1.0)
    static let inkDim    = ink.opacity(0.62)
    static let inkFaint  = ink.opacity(0.40)
    static let peri      = Color(red: 0.663, green: 0.761, blue: 1.0)    // #a9c2ff
    static let periSoft  = Color(red: 0.765, green: 0.835, blue: 1.0)    // #c3d5ff
    static let periDeep  = Color(red: 0.545, green: 0.663, blue: 0.949)  // #8ba9f2
    static let navyTop   = Color(red: 0.086, green: 0.129, blue: 0.247)  // #16213f
    static let navyMid   = Color(red: 0.063, green: 0.102, blue: 0.208)  // #101a35
    static let navyDeep  = Color(red: 0.047, green: 0.078, blue: 0.165)  // #0c142a
    static let buttonInk = Color(red: 0.071, green: 0.125, blue: 0.247)  // #12203f
}

/// Fond signature : dégradé navy + blobs periwinkle flous qui suivent le curseur.
struct WinkleBackground: View {
    var mouse: CGPoint  // position normalisée (0…1)

    var body: some View {
        GeometryReader { geo in
            let mx = mouse.x - 0.5
            let my = mouse.y - 0.5
            ZStack {
                LinearGradient(
                    colors: [WinkleStyle.navyTop, WinkleStyle.navyMid, WinkleStyle.navyDeep],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                blob(WinkleStyle.peri, size: 640, opacity: 0.55)
                    .position(x: 260 + mx * 90, y: 180 + my * 90)
                blob(WinkleStyle.periDeep, size: 560, opacity: 0.50)
                    .position(x: geo.size.width - 240 - mx * 80, y: geo.size.height - 120 - my * 80)
                blob(WinkleStyle.periSoft, size: 520, opacity: 0.35)
                    .position(x: geo.size.width * 0.62 + mx * 60, y: geo.size.height * 0.42 - my * 70)
                // Halo qui suit le curseur — la signature visuelle.
                RadialGradient(
                    colors: [WinkleStyle.peri.opacity(0.30), .clear],
                    center: .center, startRadius: 0, endRadius: 280
                )
                .frame(width: 560, height: 560)
                .blur(radius: 30)
                .position(x: mouse.x * geo.size.width, y: mouse.y * geo.size.height)
            }
            .animation(.easeOut(duration: 0.25), value: mouse)
        }
        .ignoresSafeArea()
    }

    private func blob(_ color: Color, size: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 110)
            .opacity(opacity)
    }
}

/// L'œil Winkle : un arc doux, comme un clin d'œil.
struct WinkleEye: View {
    var size: CGFloat = 88
    var lineWidth: CGFloat = 5.5

    var body: some View {
        EyeArc()
            .stroke(WinkleStyle.periSoft, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: size, height: size)
            .shadow(color: WinkleStyle.peri.opacity(0.5), radius: 13, y: 3)
    }

    private struct EyeArc: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.width * 0.25, y: rect.height * 0.59))
            path.addQuadCurve(
                to: CGPoint(x: rect.width * 0.75, y: rect.height * 0.59),
                control: CGPoint(x: rect.width * 0.5, y: rect.height * 0.295)
            )
            return path
        }
    }
}
