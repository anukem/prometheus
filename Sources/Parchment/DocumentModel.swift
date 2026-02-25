import SwiftUI

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
    @Published var scrollProgress: Double = 0

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
        var items: [OutlineItem] = []
        var charOffset = 0

        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        for (lineIndex, rawLine) in lines.enumerated() {
            let line = String(rawLine)
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if let (level, title) = parseHeading(trimmed), !title.isEmpty {
                items.append(OutlineItem(level: level, title: title, index: charOffset))
            }

            let hasNextLine = lineIndex < lines.count - 1
            charOffset += line.count + (hasNextLine ? 1 : 0)
        }

        let words = source
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count

        return (items, words)
    }

    private static func parseHeading(_ line: String) -> (Int, String)? {
        guard !line.isEmpty else { return nil }

        var level = 0
        for char in line {
            if char == "#" {
                level += 1
            } else {
                break
            }
        }

        guard (1...6).contains(level) else { return nil }

        let start = line.index(line.startIndex, offsetBy: level)
        guard start < line.endIndex, line[start] == " " else { return nil }

        let title = line[line.index(after: start)...].trimmingCharacters(in: .whitespaces)
        return title.isEmpty ? nil : (level, title)
    }

    var readingTime: Int {
        max(1, wordCount / 200)
    }

    var activeHeadingTitle: String {
        outline.indices.contains(activeHeadingIndex) ? outline[activeHeadingIndex].title : ""
    }
}
