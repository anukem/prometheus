import Foundation
import AppKit
import Markdown

// MARK: - Data Model

struct BlockIdentifier: Codable, Hashable {
    let blockIndex: Int
    let contentPrefix: String
}

enum AnnotationType: String, Codable {
    case comment
    case deletion
}

struct Annotation: Identifiable, Codable {
    let id: UUID
    let blockId: BlockIdentifier
    let type: AnnotationType
    let comment: String?

    init(blockId: BlockIdentifier, type: AnnotationType, comment: String? = nil) {
        self.id = UUID()
        self.blockId = blockId
        self.type = type
        self.comment = comment
    }
}

// MARK: - Store

@MainActor
class AnnotationStore: ObservableObject {
    @Published var annotations: [Annotation] = []
    @Published var isActive: Bool = false
    @Published var version: Int = 0
    private var fileURL: URL?

    func load(for documentURL: URL?) {
        guard let documentURL else {
            fileURL = nil
            annotations = []
            return
        }
        fileURL = sidecarURL(for: documentURL)
        guard let fileURL,
              FileManager.default.fileExists(atPath: fileURL.path) else {
            annotations = []
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            annotations = try JSONDecoder().decode([Annotation].self, from: data)
        } catch {
            annotations = []
        }
    }

    func save() {
        guard let fileURL else { return }
        do {
            let data = try JSONEncoder().encode(annotations)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Silently fail — the file may not be writable
        }
    }

    func annotations(for blockId: BlockIdentifier) -> [Annotation] {
        annotations.filter { $0.blockId == blockId }
    }

    func hasAnnotation(type: AnnotationType, for blockId: BlockIdentifier) -> Bool {
        annotations.contains { $0.blockId == blockId && $0.type == type }
    }

    func addComment(blockId: BlockIdentifier, text: String) {
        let annotation = Annotation(blockId: blockId, type: .comment, comment: text)
        annotations.append(annotation)
        version += 1
        save()
    }

    func toggleDeletion(blockId: BlockIdentifier) {
        if let index = annotations.firstIndex(where: { $0.blockId == blockId && $0.type == .deletion }) {
            annotations.remove(at: index)
        } else {
            annotations.append(Annotation(blockId: blockId, type: .deletion))
        }
        version += 1
        save()
    }

    func removeAnnotation(id: UUID) {
        annotations.removeAll { $0.id == id }
        version += 1
        save()
    }

    func exportToClipboard(source: String) {
        let doc = Document(parsing: source)
        let blocks = Array(doc.children)

        let title = blocks.compactMap { $0 as? Heading }.first?.plainText ?? "Untitled"

        var lines: [String] = []
        lines.append("ANNOTATIONS FOR: \(title)")
        lines.append(String(repeating: "=", count: 48))
        lines.append("")

        let sorted = annotations.sorted { $0.blockId.blockIndex < $1.blockId.blockIndex }
        var commentCount = 0
        var deletionCount = 0

        for annotation in sorted {
            let idx = annotation.blockId.blockIndex
            let blockPreview: String
            let blockType: String

            if idx < blocks.count {
                let block = blocks[idx]
                blockType = String(describing: Swift.type(of: block)).lowercased()
                let plain = extractPlainText(from: block)
                blockPreview = String(plain.prefix(200))
            } else {
                blockType = "unknown"
                blockPreview = annotation.blockId.contentPrefix
            }

            switch annotation.type {
            case .deletion:
                deletionCount += 1
                lines.append("[DELETE] Block \(idx) (\(blockType)):")
                for line in blockPreview.components(separatedBy: "\n").prefix(5) {
                    lines.append("> \(line)")
                }
                lines.append("→ Remove this block.")
                lines.append("")
            case .comment:
                commentCount += 1
                lines.append("[COMMENT] Block \(idx) (\(blockType)):")
                for line in blockPreview.components(separatedBy: "\n").prefix(3) {
                    lines.append("> \(line)")
                }
                lines.append("→ \"\(annotation.comment ?? "")\"")
                lines.append("")
            }
        }

        lines.append(String(repeating: "-", count: 48))
        lines.append("Summary: \(deletionCount) deletion(s), \(commentCount) comment(s)")
        lines.append("Instructions: For each deletion, remove the referenced block entirely from the markdown. For each comment, revise the referenced block according to the feedback provided.")

        let text = lines.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func sidecarURL(for documentURL: URL) -> URL {
        documentURL.appendingPathExtension("annotations.json")
    }
}

// MARK: - Helpers

func extractPlainText(from markup: any Markup) -> String {
    if let heading = markup as? Heading {
        return heading.plainText
    }
    if let text = markup as? Markdown.Text {
        return text.string
    }
    if let code = markup as? CodeBlock {
        return code.code
    }
    if let code = markup as? InlineCode {
        return code.code
    }

    var result = ""
    for child in markup.children {
        let childText = extractPlainText(from: child)
        if !childText.isEmpty {
            if !result.isEmpty && !(child is SoftBreak || child is LineBreak) {
                // Add separator between list items
                if child is ListItem {
                    result += "\n"
                }
            }
            result += childText
        }
        if child is SoftBreak || child is LineBreak {
            result += " "
        }
    }
    return result
}

func blockIdentifier(for markup: any Markup, at index: Int) -> BlockIdentifier {
    let plain = extractPlainText(from: markup)
    let prefix = String(plain.prefix(80))
    return BlockIdentifier(blockIndex: index, contentPrefix: prefix)
}
