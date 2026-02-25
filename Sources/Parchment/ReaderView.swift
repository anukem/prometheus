import SwiftUI
import Markdown
import AppKit

struct ReaderScrollRequest: Equatable {
    let token: Int
    let outlineIndex: Int
    let fallbackProgress: Double
}

struct ReaderView: View {
    let source: String
    let scrollRequest: ReaderScrollRequest?
    let onScrollProgressChanged: (Double) -> Void

    var body: some View {
        ReaderScrollContainer(
            source: source,
            scrollRequest: scrollRequest,
            onScrollProgressChanged: onScrollProgressChanged
        )
            .background(Theme.background)
    }
}

private struct ReaderScrollContainer: NSViewRepresentable {
    let source: String
    let scrollRequest: ReaderScrollRequest?
    let onScrollProgressChanged: (Double) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScrollProgressChanged: onScrollProgressChanged)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.contentView.postsBoundsChangedNotifications = true

        let hostingView = NSHostingView(
            rootView: ReaderContentView(
                source: source,
                onHeadingPositionsChanged: context.coordinator.updateHeadingPositions
            )
        )
        hostingView.translatesAutoresizingMaskIntoConstraints = true
        hostingView.autoresizingMask = [.width]
        hostingView.postsFrameChangedNotifications = true
        scrollView.documentView = hostingView
        context.coordinator.attach(scrollView: scrollView, hostingView: hostingView)
        context.coordinator.updateSource(source)
        context.coordinator.syncDocumentFrame()
        context.coordinator.emitProgress(reason: "makeNSView")

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.updateSource(source)
        context.coordinator.handle(scrollRequest: scrollRequest)
    }

    final class Coordinator {
        private let onScrollProgressChanged: (Double) -> Void
        private var observers: [NSObjectProtocol] = []
        weak var scrollView: NSScrollView?
        weak var hostingView: NSHostingView<ReaderContentView>?
        private var lastSource: String = ""
        private var lastProgress: Double = -1
        private var lastScrollToken: Int?
        private var headingMinYByOutlineIndex: [Int: CGFloat] = [:]
        private var pendingScrollRequest: ReaderScrollRequest?

        init(onScrollProgressChanged: @escaping (Double) -> Void) {
            self.onScrollProgressChanged = onScrollProgressChanged
        }

        func attach(scrollView: NSScrollView, hostingView: NSHostingView<ReaderContentView>) {
            self.scrollView = scrollView
            self.hostingView = hostingView

            for token in observers {
                NotificationCenter.default.removeObserver(token)
            }
            observers.removeAll()

            let boundsObserver = NotificationCenter.default.addObserver(
                forName: NSView.boundsDidChangeNotification,
                object: scrollView.contentView,
                queue: .main
            ) { [weak self] _ in
                self?.emitProgress(reason: "boundsDidChange")
            }
            observers.append(boundsObserver)

            let liveObserver = NotificationCenter.default.addObserver(
                forName: NSScrollView.didLiveScrollNotification,
                object: scrollView,
                queue: .main
            ) { [weak self] _ in
                self?.emitProgress(reason: "didLiveScroll")
            }
            observers.append(liveObserver)

            let frameObserver = NotificationCenter.default.addObserver(
                forName: NSView.frameDidChangeNotification,
                object: hostingView,
                queue: .main
            ) { [weak self] _ in
                self?.emitProgress(reason: "documentFrameDidChange")
            }
            observers.append(frameObserver)
        }

        func syncDocumentFrame() {
            guard let scrollView, let hostingView else { return }
            let viewportWidth = scrollView.contentView.bounds.width
            let fitting = hostingView.fittingSize
            hostingView.setFrameSize(NSSize(width: viewportWidth, height: fitting.height))
        }

        func updateSource(_ source: String) {
            guard source != lastSource else { return }
            lastSource = source
            headingMinYByOutlineIndex = [:]
            pendingScrollRequest = nil

            guard let hostingView else { return }
            hostingView.rootView = ReaderContentView(
                source: source,
                onHeadingPositionsChanged: updateHeadingPositions
            )
            DispatchQueue.main.async { [weak self] in
                self?.syncDocumentFrame()
                self?.emitProgress(reason: "sourceChanged")
            }
        }

        func handle(scrollRequest: ReaderScrollRequest?) {
            guard let scrollRequest else {
                return
            }
            guard scrollRequest.token != lastScrollToken else {
                return
            }
            lastScrollToken = scrollRequest.token
            scrollToRequest(scrollRequest, reason: "outlineTap")
        }

        func updateHeadingPositions(_ positions: [Int: CGFloat]) {
            headingMinYByOutlineIndex = positions
            if let pendingScrollRequest {
                scrollToRequest(pendingScrollRequest, reason: "pendingWithAnchors")
            }
        }

        private func scrollToRequest(_ request: ReaderScrollRequest, reason: String) {
            if let headingY = headingMinYByOutlineIndex[request.outlineIndex] {
                pendingScrollRequest = nil
                scroll(toOffsetY: headingY, reason: reason, mode: "anchor")
                return
            }

            pendingScrollRequest = request
            scroll(toProgress: request.fallbackProgress, reason: reason, mode: "fallback")
        }

        private func scroll(toProgress progress: Double, reason: String, mode: String) {
            guard let scrollView, let documentView = scrollView.documentView else { return }

            let viewportHeight = scrollView.contentView.bounds.height
            let contentHeight = documentView.bounds.height
            let maxOffset = max(0, contentHeight - viewportHeight)
            let targetProgress = min(1, max(0, progress))
            let targetOffset = targetProgress * maxOffset
            animateScroll(scrollView: scrollView, targetOffset: targetOffset)
        }

        private func scroll(toOffsetY headingMinY: CGFloat, reason: String, mode: String) {
            guard let scrollView, let documentView = scrollView.documentView else { return }

            let viewportHeight = scrollView.contentView.bounds.height
            let contentHeight = documentView.bounds.height
            let maxOffset = max(0, contentHeight - viewportHeight)
            let topPadding: CGFloat = 10
            let targetOffset = min(max(0, headingMinY - topPadding), maxOffset)
            animateScroll(scrollView: scrollView, targetOffset: targetOffset)
        }

        private func animateScroll(scrollView: NSScrollView, targetOffset: CGFloat) {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.22
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                scrollView.contentView.animator().setBoundsOrigin(NSPoint(x: 0, y: targetOffset))
            } completionHandler: { [weak self, weak scrollView] in
                guard let scrollView else { return }
                scrollView.reflectScrolledClipView(scrollView.contentView)
                self?.emitProgress(reason: "outlineScroll")
            }
        }

        func emitProgress(reason: String) {
            guard let scrollView, let documentView = scrollView.documentView else { return }

            let viewportHeight = scrollView.contentView.bounds.height
            let contentHeight = documentView.bounds.height
            let maxOffset = max(0, contentHeight - viewportHeight)
            let rawOffset = scrollView.contentView.bounds.origin.y
            let offset = min(max(0, rawOffset), maxOffset)
            let progress: Double = maxOffset <= 0 ? 0 : Double(offset / maxOffset)
            if abs(progress - lastProgress) < 0.0001 && reason == "sourceChanged" {
                return
            }
            lastProgress = progress

            onScrollProgressChanged(progress)
        }

        deinit {
            for token in observers {
                NotificationCenter.default.removeObserver(token)
            }
        }
    }
}

private struct ReaderContentView: View {
    let source: String
    let onHeadingPositionsChanged: ([Int: CGFloat]) -> Void

    private var metadata: (type: String, date: String) {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        let hasType = lines.first(where: { $0.lowercased().contains("essay") || $0.lowercased().contains("note") }) != nil
        let type_ = hasType ? "Essay" : "Note"

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return (type_, formatter.string(from: Date()))
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Text(metadata.type.uppercased())
                        .font(Theme.metaFont)
                        .foregroundColor(Theme.textMeta)
                    Text("·").foregroundColor(Theme.border)
                    Text(metadata.date)
                        .font(Theme.statusFont)
                        .foregroundColor(Theme.textMeta)
                    Text("·").foregroundColor(Theme.border)

                    let words = source
                        .components(separatedBy: .whitespacesAndNewlines)
                        .filter { !$0.isEmpty }.count
                    let mins = max(1, words / 200)
                    Text("\(mins) min read")
                        .font(Theme.statusFont)
                        .foregroundColor(Theme.textMeta)
                }
                .padding(.bottom, 28)

                MarkdownRenderer(source: source, onHeadingPositionsChanged: onHeadingPositionsChanged)
            }
            .frame(width: 640)
            .padding(.top, 64)
            .padding(.bottom, 80)
            Spacer(minLength: 0)
        }
        .coordinateSpace(name: "readerContent")
        .background(Theme.background)
    }
}
