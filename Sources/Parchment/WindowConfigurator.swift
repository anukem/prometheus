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
        window.backgroundColor = NSColor(Theme.chrome)
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
    }

    class Coordinator {
        private var token: NSObjectProtocol?

        func attach(to window: NSWindow) {
            Self.apply(to: window)
            token = NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: window,
                queue: .main
            ) { _ in WindowConfigurator.apply(to: window) }
        }

        deinit {
            if let token { NotificationCenter.default.removeObserver(token) }
        }
    }
}
