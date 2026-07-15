import AppKit
import SwiftUI

/// Gère les fenêtres d'overlay de pause : une par écran (ou écran principal seul),
/// au-dessus de tout, avec fondu d'apparition et de disparition.
@MainActor
final class OverlayController {
    private var windows: [NSWindow] = []
    private weak var engine: BreakEngine?

    init(engine: BreakEngine) {
        self.engine = engine
    }

    func showPrompt() { show() }
    func showBreak() {
        if windows.isEmpty { show() }
    }

    private func show() {
        guard let engine, windows.isEmpty else { return }

        let screens = engine.prefs.allScreens
            ? NSScreen.screens
            : [NSScreen.main].compactMap { $0 }

        for screen in screens {
            let window = OverlayWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.acceptsMouseMovedEvents = true
            window.isReleasedWhenClosed = false
            window.animationBehavior = .none
            window.strictMode = engine.prefs.strictMode

            let view = OverlayRootView(engine: engine)
            window.contentView = NSHostingView(rootView: view)
            window.alphaValue = 0
            window.setFrame(screen.frame, display: true)
            window.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.6
                window.animator().alphaValue = 1
            }
            windows.append(window)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        let closing = windows
        windows = []
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            closing.forEach { $0.animator().alphaValue = 0 }
        }, completionHandler: {
            Task { @MainActor in closing.forEach { $0.orderOut(nil) } }
        })
    }
}

/// Fenêtre borderless pouvant devenir key (pour capter Échap hors mode strict).
private final class OverlayWindow: NSWindow {
    var strictMode = false

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        // Échap = ignorer la pause, sauf en mode strict (overlay non-esquivable).
        if event.keyCode == 53, !strictMode {
            Task { @MainActor in
                (NSApp.delegate as? AppDelegate)?.engine.skip()
            }
            return
        }
        // On avale tout le reste : l'overlay est une invitation à lâcher le clavier.
    }
}
