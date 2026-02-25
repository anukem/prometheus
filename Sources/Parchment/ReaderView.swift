import SwiftUI
import Markdown

struct ReaderView: View {
    let source: String

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
        ScrollView {
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
                }
                .frame(width: 640)
                .padding(.top, 64)
                .padding(.bottom, 80)
                Spacer(minLength: 0)
            }
        }
        .background(Theme.background)
    }
}
