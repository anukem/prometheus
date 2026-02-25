import SwiftUI
import Markdown

struct ReaderView: View {
    let source: String
    let onScrollProgressChanged: (Double) -> Void

    @State private var contentTotalHeight: CGFloat = 0

    private var metadata: (type: String, date: String) {
        // Try to extract front-matter style metadata from first heading or fallback
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        let hasType = lines.first(where: { $0.lowercased().contains("essay") || $0.lowercased().contains("note") }) != nil
        let type_ = hasType ? "Essay" : "Note"

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return (type_, formatter.string(from: Date()))
    }

    var body: some View {
        GeometryReader { viewport in
            ScrollView {
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("readerScroll")).minY)
                }
                .frame(height: 0)

                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    VStack(alignment: .leading, spacing: 0) {
                        // Meta row
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

                        MarkdownRenderer(source: source)
                            .background(
                                GeometryReader { contentProxy in
                                    Color.clear
                                        .preference(key: ContentHeightPreferenceKey.self, value: contentProxy.size.height)
                                }
                            )
                    }
                    .frame(width: 640)
                    .padding(.top, 64)
                    .padding(.bottom, 80)
                    Spacer(minLength: 0)
                }
            }
            .coordinateSpace(name: "readerScroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { minY in
                let scrollOffset = max(0, -minY)
                let contentHeight = max(0, contentTotalHeight)
                let maxOffset = contentHeight - viewport.size.height
                let progress: CGFloat
                if maxOffset <= 0 {
                    progress = 0
                } else {
                    progress = min(1, max(0, scrollOffset / maxOffset))
                }
                onScrollProgressChanged(progress)
            }
            .onPreferenceChange(ContentHeightPreferenceKey.self) { value in
                contentTotalHeight = value + 64 + 80
            }
            .onAppear {
                onScrollProgressChanged(0)
            }
        }
        .background(Theme.background)
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
