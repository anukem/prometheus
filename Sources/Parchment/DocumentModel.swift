import SwiftUI
import Markdown

struct OutlineItem: Identifiable {
    let id = UUID()
    let level: Int
    let title: String
    let index: Int  // character offset in source, used for scroll targeting
}

@MainActor
class DocumentModel: ObservableObject {
    @Published var source: String = ""
    @Published var outline: [OutlineItem] = []
    @Published var wordCount: Int = 0
    @Published var activeHeadingIndex: Int = 0

    private var parseTask: Task<Void, Never>?

    func update(source: String) {
        self.source = source
        parseTask?.cancel()
        parseTask = Task {
            let (outline, wordCount) = Self.parse(source)
            guard !Task.isCancelled else { return }
            self.outline = outline
            self.wordCount = wordCount
        }
    }

    private static func parse(_ source: String) -> ([OutlineItem], Int) {
        let doc = Document(parsing: source)
        var items: [OutlineItem] = []
        var charIndex = 0

        for child in doc.children {
            if let heading = child as? Heading {
                let title = heading.plainText
                items.append(OutlineItem(level: heading.level, title: title, index: charIndex))
            }
            charIndex += child.debugDescription().count
        }

        let words = source
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count

        return (items, words)
    }

    var readingTime: Int {
        max(1, wordCount / 200)
    }

    var activeHeadingTitle: String {
        outline.indices.contains(activeHeadingIndex) ? outline[activeHeadingIndex].title : ""
    }
}
