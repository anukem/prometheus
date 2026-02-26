import SwiftUI
import Markdown

struct MarkdownRenderer: View {
    let source: String
    let onHeadingPositionsChanged: ([Int: CGFloat]) -> Void
    let onBlockPositionsChanged: ([Int: CGFloat]) -> Void
    var annotationStore: AnnotationStore?
    var selectedBlockIndex: Int?
    var blockActionRequest: BlockKeyboardActionRequest?

    var body: some View {
        let blocks = parsedBlocks()
        VStack(alignment: .leading, spacing: 0) {
            ForEach(blocks) { block in
                if let store = annotationStore {
                    AnnotatableBlockView(
                        block: block.markup,
                        outlineIndex: block.outlineIndex,
                        blockId: block.blockId,
                        annotationStore: store,
                        isSelected: selectedBlockIndex == block.blockId.blockIndex,
                        blockActionRequest: blockActionRequest
                    )
                } else {
                    BlockView(
                        block: block.markup,
                        outlineIndex: block.outlineIndex,
                        blockIndex: block.blockId.blockIndex,
                        isSelected: selectedBlockIndex == block.blockId.blockIndex
                    )
                }
            }
        }
        .onPreferenceChange(HeadingPositionPreferenceKey.self, perform: onHeadingPositionsChanged)
        .onPreferenceChange(BlockPositionPreferenceKey.self, perform: onBlockPositionsChanged)
    }

    private func parsedBlocks() -> [RenderedBlock] {
        let doc = Document(parsing: source)
        var headingIndex = 0
        var result: [RenderedBlock] = []

        for (index, block) in doc.children.enumerated() {
            let outlineIndex: Int?
            if block is Heading {
                outlineIndex = headingIndex
                headingIndex += 1
            } else {
                outlineIndex = nil
            }
            let blockId = blockIdentifier(for: block, at: index)
            result.append(RenderedBlock(markup: block, outlineIndex: outlineIndex, blockId: blockId))
        }
        return result
    }
}

private struct RenderedBlock: Identifiable {
    var id: Int { blockId.blockIndex }
    let markup: any Markup
    let outlineIndex: Int?
    let blockId: BlockIdentifier
}

// MARK: - Block

struct BlockView: View {
    let block: any Markup
    let outlineIndex: Int?
    var blockIndex: Int? = nil
    var isSelected: Bool = false

    var body: some View {
        Group {
            if let heading = block as? Heading {
                HeadingView(heading: heading)
                    .background {
                        if let outlineIndex {
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: HeadingPositionPreferenceKey.self,
                                    value: [outlineIndex: geo.frame(in: .named("readerContent")).minY]
                                )
                            }
                        }
                    }
                    .padding(.bottom, heading.level == 1 ? 10 : 8)
                    .padding(.top, heading.level == 1 ? 0 : 24)
            } else if let para = block as? Paragraph {
                ParagraphView(paragraph: para)
                    .padding(.bottom, 22)
            } else if let bq = block as? BlockQuote {
                BlockQuoteView(blockQuote: bq)
                    .padding(.bottom, 26)
            } else if let list = block as? UnorderedList {
                UnorderedListView(list: list)
                    .padding(.bottom, 22)
            } else if let list = block as? OrderedList {
                OrderedListView(list: list)
                    .padding(.bottom, 22)
            } else if let code = block as? CodeBlock {
                CodeBlockView(code: code)
                    .padding(.bottom, 22)
            } else if block is ThematicBreak {
                Divider()
                    .overlay(Theme.border)
                    .padding(.vertical, 24)
            } else {
                EmptyView()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Theme.accentLight.opacity(0.45) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(isSelected ? Theme.accent : Color.clear, lineWidth: 1)
        )
        .background {
            GeometryReader { geo in
                Color.clear.preference(
                    key: BlockPositionPreferenceKey.self,
                    value: blockIndex.map { [$0: geo.frame(in: .named("readerContent")).minY] } ?? [:]
                )
            }
        }
    }
}

private struct HeadingPositionPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]

    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct BlockPositionPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]

    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

// MARK: - Heading

struct HeadingView: View {
    let heading: Heading

    var body: some View {
        Group {
            switch heading.level {
            case 1:
                VStack(alignment: .leading, spacing: 16) {
                    Text(heading.plainText)
                        .font(Theme.titleFont)
                        .foregroundColor(Theme.textPrimary)
                        .tracking(-0.8)
                    Rectangle()
                        .fill(Theme.accent)
                        .frame(width: 36, height: 2)
                        .cornerRadius(1)
                }
                .padding(.bottom, 32)
            case 2:
                Text(heading.plainText)
                    .font(Theme.h2Font)
                    .foregroundColor(Theme.textPrimary)
                    .tracking(-0.5)
            case 3:
                Text(heading.plainText)
                    .font(Theme.h3Font)
                    .foregroundColor(Theme.textBody)
            default:
                Text(heading.plainText)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(Theme.textBody)
            }
        }
    }
}

// MARK: - Paragraph

struct ParagraphView: View {
    let paragraph: Paragraph

    var body: some View {
        InlineText(inlines: Array(paragraph.inlineChildren))
            .font(Theme.bodyFont)
            .foregroundColor(Theme.textBody)
            .lineSpacing(8)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Inline text

struct InlineText: View {
    let inlines: [any InlineMarkup]

    var body: some View {
        inlines.reduce(SwiftUI.Text("")) { result, inline in
            result + inlineText(inline)
        }
    }

    private func inlineText(_ inline: any InlineMarkup) -> SwiftUI.Text {
        if let text = inline as? Markdown.Text {
            return SwiftUI.Text(text.string)
        } else if let strong = inline as? Strong {
            return strong.inlineChildren.reduce(SwiftUI.Text("")) { r, c in
                r + inlineText(c)
            }.bold()
        } else if let em = inline as? Emphasis {
            return em.inlineChildren.reduce(SwiftUI.Text("")) { r, c in
                r + inlineText(c)
            }.italic()
        } else if let code = inline as? InlineCode {
            return SwiftUI.Text(code.code)
                .font(Theme.monoFont)
                .foregroundColor(Theme.codeText)
        } else if let link = inline as? Markdown.Link {
            return link.inlineChildren.reduce(SwiftUI.Text("")) { r, c in
                r + inlineText(c)
            }.foregroundColor(Theme.accent).underline(color: Theme.accent.opacity(0.4))
        } else if inline is SoftBreak || inline is LineBreak {
            return SwiftUI.Text(" ")
        } else {
            return SwiftUI.Text("")
        }
    }
}

// MARK: - Blockquote

struct BlockQuoteView: View {
    let blockQuote: BlockQuote

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(Theme.accent)
                .frame(width: 3)
                .cornerRadius(1.5)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(blockQuote.children.enumerated()), id: \.offset) { _, child in
                    if let para = child as? Paragraph {
                        InlineText(inlines: Array(para.inlineChildren))
                            .font(.custom("IBMPlexSerif-LightItalic", size: 18))
                            .foregroundColor(Theme.codeText)
                            .lineSpacing(8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, 24)
        }
    }
}

// MARK: - Unordered list

struct UnorderedListView: View {
    let list: UnorderedList

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(list.listItems.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Circle()
                        .fill(Theme.textMuted)
                        .frame(width: 4, height: 4)
                        .padding(.top, 7)
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(item.children.enumerated()), id: \.offset) { _, child in
                            if let para = child as? Paragraph {
                                InlineText(inlines: Array(para.inlineChildren))
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textBody)
                                    .lineSpacing(6)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Ordered list

struct OrderedListView: View {
    let list: OrderedList

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(list.listItems.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(index + 1).")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textMuted)
                        .frame(minWidth: 20, alignment: .trailing)
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(item.children.enumerated()), id: \.offset) { _, child in
                            if let para = child as? Paragraph {
                                InlineText(inlines: Array(para.inlineChildren))
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textBody)
                                    .lineSpacing(6)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Code block

struct CodeBlockView: View {
    let code: CodeBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let lang = code.language, !lang.isEmpty {
                Text(lang.lowercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textFaint)
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code.code.trimmingCharacters(in: .newlines))
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(Theme.textBody)
                    .lineSpacing(5)
                    .padding(14)
            }
        }
        .background(Theme.subtle)
        .cornerRadius(8)
    }
}
