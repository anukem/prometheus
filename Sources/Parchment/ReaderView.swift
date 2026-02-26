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
    var annotationStore: AnnotationStore?
    var selectedBlockIndex: Int?
    var shouldAutoFocus: Bool = false
    var blockActionRequest: BlockKeyboardActionRequest?
    var onNavigationAction: (VimNavigationAction) -> Void = { _ in }

    var body: some View {
        ReaderScrollContainer(
            source: source,
            scrollRequest: scrollRequest,
            onScrollProgressChanged: onScrollProgressChanged,
            annotationStore: annotationStore,
            annotationVersion: annotationStore?.version ?? 0,
            annotationActive: annotationStore?.isActive ?? false,
            selectedBlockIndex: selectedBlockIndex,
            shouldAutoFocus: shouldAutoFocus,
            blockActionRequest: blockActionRequest,
            onNavigationAction: onNavigationAction
        )
            .background(Theme.background)
    }
}

private struct ReaderScrollContainer: NSViewRepresentable {
    let source: String
    let scrollRequest: ReaderScrollRequest?
    let onScrollProgressChanged: (Double) -> Void
    var annotationStore: AnnotationStore?
    var annotationVersion: Int = 0
    var annotationActive: Bool = false
    var selectedBlockIndex: Int?
    var shouldAutoFocus: Bool
    var blockActionRequest: BlockKeyboardActionRequest?
    var onNavigationAction: (VimNavigationAction) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScrollProgressChanged: onScrollProgressChanged, onNavigationAction: onNavigationAction)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = ReaderKeyHandlingScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.contentView.postsBoundsChangedNotifications = true
        scrollView.wantsLayer = true
        scrollView.onMouseDown = { [weak coordinator = context.coordinator] in
            coordinator?.didReceiveFocus()
        }
        scrollView.onKeyCommand = { [weak coordinator = context.coordinator] command in
            coordinator?.handleKeyCommand(command)
        }

        let hostingView = NSHostingView(
            rootView: ReaderContentView(
                source: source,
                onHeadingPositionsChanged: context.coordinator.updateHeadingPositions,
                onBlockPositionsChanged: context.coordinator.updateBlockPositions,
                annotationStore: annotationStore,
                selectedBlockIndex: selectedBlockIndex,
                blockActionRequest: blockActionRequest
            )
        )
        hostingView.translatesAutoresizingMaskIntoConstraints = true
        hostingView.autoresizingMask = [.width]
        hostingView.postsFrameChangedNotifications = true
        scrollView.documentView = hostingView
        context.coordinator.annotationStore = annotationStore
        context.coordinator.attach(scrollView: scrollView, hostingView: hostingView)
        context.coordinator.setAutoFocusEnabled(shouldAutoFocus)
        context.coordinator.updateSelection(selectedBlockIndex)
        context.coordinator.updateSource(source)
        context.coordinator.syncDocumentFrame()
        context.coordinator.emitProgress(reason: "makeNSView")
        if shouldAutoFocus {
            DispatchQueue.main.async {
                scrollView.window?.makeFirstResponder(scrollView)
                context.coordinator.didReceiveFocus()
            }
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.annotationStore = annotationStore
        context.coordinator.setAutoFocusEnabled(shouldAutoFocus)
        context.coordinator.updateSelection(selectedBlockIndex)
        context.coordinator.updateSource(source)
        context.coordinator.refreshAnnotations(version: annotationVersion, active: annotationActive)
        context.coordinator.handle(scrollRequest: scrollRequest)
        context.coordinator.updateBlockActionRequest(blockActionRequest)
    }

    final class Coordinator {
        private let onScrollProgressChanged: (Double) -> Void
        private let onNavigationAction: (VimNavigationAction) -> Void
        private var observers: [NSObjectProtocol] = []
        weak var scrollView: ReaderKeyHandlingScrollView?
        weak var hostingView: NSHostingView<ReaderContentView>?
        private var lastSource: String = ""
        private var lastProgress: Double = -1
        private var lastScrollToken: Int?
        private var headingMinYByOutlineIndex: [Int: CGFloat] = [:]
        private var pendingScrollRequest: ReaderScrollRequest?
        var annotationStore: AnnotationStore?
        private var lastAnnotationVersion: Int = -1
        private var lastAnnotationActive: Bool = false
        private var vimEngine = VimNavigationEngine(blockCount: 0)
        private var blockMinYByIndex: [Int: CGFloat] = [:]
        private var hasReaderFocus: Bool = false
        private var autoFocusEnabled: Bool = false
        private var lastBlockActionToken: Int?
        private var latestBlockActionRequest: BlockKeyboardActionRequest?
        private var localKeyMonitor: Any?

        init(
            onScrollProgressChanged: @escaping (Double) -> Void,
            onNavigationAction: @escaping (VimNavigationAction) -> Void
        ) {
            self.onScrollProgressChanged = onScrollProgressChanged
            self.onNavigationAction = onNavigationAction
        }

        func attach(scrollView: ReaderKeyHandlingScrollView, hostingView: NSHostingView<ReaderContentView>) {
            self.scrollView = scrollView
            self.hostingView = hostingView

            for token in observers {
                NotificationCenter.default.removeObserver(token)
            }
            observers.removeAll()
            if let localKeyMonitor {
                NSEvent.removeMonitor(localKeyMonitor)
                self.localKeyMonitor = nil
            }

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

            localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self else { return event }
                guard self.hasReaderFocus else { return event }
                guard let scrollView = self.scrollView,
                      let window = scrollView.window,
                      event.window === window else { return event }
                guard !self.isTextInputFocused() else { return event }
                guard let command = ReaderKeyHandlingScrollView.command(for: event) else { return event }
                self.handleKeyCommand(command)
                return nil
            }
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
            blockMinYByIndex = [:]
            pendingScrollRequest = nil

            guard let hostingView else { return }
            hostingView.rootView = ReaderContentView(
                source: source,
                onHeadingPositionsChanged: updateHeadingPositions,
                onBlockPositionsChanged: updateBlockPositions,
                annotationStore: annotationStore,
                selectedBlockIndex: vimEngine.selectedBlockIndex,
                blockActionRequest: latestBlockActionRequest
            )
            vimEngine.updateBlockCount(Array(Document(parsing: source).children).count)
            DispatchQueue.main.async { [weak self] in
                self?.syncDocumentFrame()
                self?.emitProgress(reason: "sourceChanged")
            }
        }

        func refreshAnnotations(version: Int, active: Bool) {
            guard version != lastAnnotationVersion || active != lastAnnotationActive else { return }
            lastAnnotationVersion = version
            lastAnnotationActive = active
            guard let hostingView else { return }
            hostingView.rootView = ReaderContentView(
                source: lastSource,
                onHeadingPositionsChanged: updateHeadingPositions,
                onBlockPositionsChanged: updateBlockPositions,
                annotationStore: annotationStore,
                selectedBlockIndex: vimEngine.selectedBlockIndex,
                blockActionRequest: latestBlockActionRequest
            )
        }

        func setAutoFocusEnabled(_ enabled: Bool) {
            autoFocusEnabled = enabled
            if enabled {
                hasReaderFocus = true
            }
        }

        func updateSelection(_ selection: Int?) {
            guard let selection else { return }
            let action = vimEngine.setSelection(selection)
            if case .moveSelection(let index) = action {
                scrollToBlock(index)
            }
            refreshReaderRootView()
        }

        func updateBlockActionRequest(_ request: BlockKeyboardActionRequest?) {
            guard let request, request.token != lastBlockActionToken else { return }
            lastBlockActionToken = request.token
            latestBlockActionRequest = request
            refreshReaderRootView()
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

        func updateBlockPositions(_ positions: [Int: CGFloat]) {
            blockMinYByIndex = positions
            vimEngine.updateBlockCount(positions.count)
            if autoFocusEnabled && hasReaderFocus == false {
                didReceiveFocus()
            }
        }

        func didReceiveFocus() {
            hasReaderFocus = true
            guard vimEngine.selectedBlockIndex == nil else { return }
            guard let index = firstVisibleBlockIndex() else { return }
            let action = vimEngine.setSelection(index)
            if case .moveSelection = action {
                onNavigationAction(action)
                refreshReaderRootView()
            }
        }

        func handleKeyCommand(_ command: VimNavigationCommand) {
            guard hasReaderFocus, !isTextInputFocused() else { return }
            let action = vimEngine.handle(command)
            switch action {
            case .moveSelection(let index):
                scrollToBlock(index)
                onNavigationAction(action)
                refreshReaderRootView()
            case .selectBlock, .commentBlock, .deleteBlock:
                onNavigationAction(action)
                refreshReaderRootView()
            case .none:
                break
            }
        }

        private func refreshReaderRootView() {
            guard let hostingView else { return }
            hostingView.rootView = ReaderContentView(
                source: lastSource,
                onHeadingPositionsChanged: updateHeadingPositions,
                onBlockPositionsChanged: updateBlockPositions,
                annotationStore: annotationStore,
                selectedBlockIndex: vimEngine.selectedBlockIndex,
                blockActionRequest: latestBlockActionRequest
            )
        }

        private func scrollToBlock(_ index: Int) {
            guard let minY = blockMinYByIndex[index] else { return }
            scroll(toOffsetY: minY, reason: "keyboardNav", mode: "block")
        }

        private func firstVisibleBlockIndex() -> Int? {
            guard let scrollView else { return nil }
            let top = scrollView.contentView.bounds.minY
            let sorted = blockMinYByIndex.sorted { $0.value < $1.value }
            return sorted.first(where: { $0.value >= top - 2 })?.key ?? sorted.last?.key
        }

        private func isTextInputFocused() -> Bool {
            guard let firstResponder = scrollView?.window?.firstResponder else { return false }
            return firstResponder is NSTextView
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
            if let localKeyMonitor {
                NSEvent.removeMonitor(localKeyMonitor)
            }
        }
    }
}

private final class ReaderKeyHandlingScrollView: NSScrollView {
    var onMouseDown: (() -> Void)?
    var onKeyCommand: ((VimNavigationCommand) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        onMouseDown?()
        super.mouseDown(with: event)
    }

    override func keyDown(with event: NSEvent) {
        guard let command = Self.command(for: event) else {
            super.keyDown(with: event)
            return
        }
        onKeyCommand?(command)
    }

    static func command(for event: NSEvent) -> VimNavigationCommand? {
        guard let chars = event.charactersIgnoringModifiers?.lowercased(), chars.count == 1 else {
            return nil
        }
        return parseVimNavigationCommand(chars)
    }
}

private struct ReaderContentView: View {
    let source: String
    let onHeadingPositionsChanged: ([Int: CGFloat]) -> Void
    let onBlockPositionsChanged: ([Int: CGFloat]) -> Void
    var annotationStore: AnnotationStore?
    var selectedBlockIndex: Int?
    var blockActionRequest: BlockKeyboardActionRequest?

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

                MarkdownRenderer(
                    source: source,
                    onHeadingPositionsChanged: onHeadingPositionsChanged,
                    onBlockPositionsChanged: onBlockPositionsChanged,
                    annotationStore: annotationStore,
                    selectedBlockIndex: selectedBlockIndex,
                    blockActionRequest: blockActionRequest
                )
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
