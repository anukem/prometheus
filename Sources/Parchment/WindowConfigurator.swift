import SwiftUI
import AppKit

/// Reaches into the hosting NSWindow and applies Parchment's chrome color to the titlebar.
struct WindowConfigurator: NSViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            context.coordinator.attach(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            Self.apply(to: window)
        }
    }

    static func apply(to window: NSWindow) {
        // Keep chrome appearance stable across key/non-key transitions.
        window.appearance = NSAppearance(named: .aqua)
        window.styleMask.insert(.fullSizeContentView)
        window.backgroundColor = NSColor(Theme.chrome)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.toolbar = nil
        window.isMovableByWindowBackground = true
    }

    class Coordinator {
        private var tokens: [NSObjectProtocol] = []

        func attach(to window: NSWindow) {
            WindowConfigurator.apply(to: window)

            let didBecomeKey = NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: window,
                queue: .main
            ) { _ in
                WindowConfigurator.apply(to: window)
            }
            tokens.append(didBecomeKey)

            let didResignKey = NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: window,
                queue: .main
            ) { _ in }
            tokens.append(didResignKey)
        }

        deinit {
            for token in tokens {
                NotificationCenter.default.removeObserver(token)
            }
        }
    }
}
