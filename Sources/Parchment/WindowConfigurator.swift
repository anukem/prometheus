import SwiftUI
import AppKit

/// Reaches into the hosting NSWindow and applies Parchment's chrome color to the titlebar.
struct WindowConfigurator: NSViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            Self.logWindowState(window, event: "makeNSView.attach")
            context.coordinator.attach(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            Self.logWindowState(window, event: "updateNSView.beforeApply")
            Self.apply(to: window)
            Self.logWindowState(window, event: "updateNSView.afterApply")
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

    static func logWindowState(_ window: NSWindow, event: String) {
        let target = NSColor(Theme.chrome)
        let current = window.backgroundColor ?? .clear
        let targetDesc = colorDescription(target)
        let currentDesc = colorDescription(current)
        let stamp = ISO8601DateFormatter().string(from: Date())
        print("[WindowChrome] \(stamp) event=\(event) key=\(window.isKeyWindow) main=\(window.isMainWindow) target=\(targetDesc) current=\(currentDesc)")
    }

    private static func colorDescription(_ color: NSColor) -> String {
        guard let sRGB = color.usingColorSpace(.sRGB) else { return "unconvertible" }
        return String(format: "r=%.4f g=%.4f b=%.4f a=%.4f", sRGB.redComponent, sRGB.greenComponent, sRGB.blueComponent, sRGB.alphaComponent)
    }

    class Coordinator {
        private var tokens: [NSObjectProtocol] = []

        func attach(to window: NSWindow) {
            WindowConfigurator.logWindowState(window, event: "coordinator.attach.beforeApply")
            WindowConfigurator.apply(to: window)
            WindowConfigurator.logWindowState(window, event: "coordinator.attach.afterApply")

            let didBecomeKey = NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: window,
                queue: .main
            ) { _ in
                WindowConfigurator.logWindowState(window, event: "didBecomeKey.beforeApply")
                WindowConfigurator.apply(to: window)
                WindowConfigurator.logWindowState(window, event: "didBecomeKey.afterApply")
            }
            tokens.append(didBecomeKey)

            let didResignKey = NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: window,
                queue: .main
            ) { _ in
                WindowConfigurator.logWindowState(window, event: "didResignKey")
            }
            tokens.append(didResignKey)
        }

        deinit {
            for token in tokens {
                NotificationCenter.default.removeObserver(token)
            }
        }
    }
}
