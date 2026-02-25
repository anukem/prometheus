import SwiftUI

struct OutlinePanel: View {
    @ObservedObject var model: DocumentModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("IN THIS DOCUMENT")
                .font(Theme.metaFont)
                .foregroundColor(Theme.textMeta)
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 14)

            // TOC items
            ScrollView {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(Array(model.outline.enumerated()), id: \.element.id) { index, item in
                        OutlineItemRow(
                            item: item,
                            isActive: index == model.activeHeadingIndex,
                            onTap: { model.activeHeadingIndex = index }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 24)
            }

            Divider()
                .overlay(Theme.border)
                .padding(.vertical, 20)

            // Progress
            VStack(alignment: .leading, spacing: 8) {
                Text("PROGRESS")
                    .font(Theme.metaFont)
                    .foregroundColor(Theme.textMeta)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.border).frame(height: 3)
                        let fraction = model.outline.isEmpty ? 0.0 :
                            Double(model.activeHeadingIndex + 1) / Double(model.outline.count)
                        Capsule()
                            .fill(Theme.accent)
                            .frame(width: geo.size.width * fraction, height: 3)
                    }
                }
                .frame(height: 3)

                HStack {
                    let pct = model.outline.isEmpty ? 0 :
                        Int((Double(model.activeHeadingIndex + 1) / Double(model.outline.count)) * 100)
                    Text("\(pct)% read")
                    Spacer()
                    let remaining = max(0, model.readingTime - (model.readingTime * pct / 100))
                    Text("~\(remaining) min left")
                }
                .font(Theme.statusFont)
                .foregroundColor(Theme.textMeta)
            }
            .padding(.horizontal, 20)

            Divider()
                .overlay(Theme.border)
                .padding(.vertical, 20)

            // Stats
            VStack(alignment: .leading, spacing: 10) {
                Text("DOCUMENT")
                    .font(Theme.metaFont)
                    .foregroundColor(Theme.textMeta)

                StatRow(label: "Words",     value: "\(model.wordCount.formatted())")
                StatRow(label: "Headings",  value: "\(model.outline.count)")
                StatRow(label: "Read time", value: "\(model.readingTime) min")
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .frame(width: 220)
        .background(Theme.background)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Theme.border)
                .frame(width: 1)
        }
    }
}

struct OutlineItemRow: View {
    let item: OutlineItem
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                if item.level == 1 {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Circle()
                            .fill(isActive ? Theme.accent : Theme.border)
                            .frame(width: 5, height: 5)
                            .padding(.top, 1)
                        Text(item.title)
                            .font(.system(size: 12, weight: isActive ? .semibold : .medium, design: .default))
                            .foregroundColor(isActive ? Theme.textPrimary : Theme.textBody)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                } else {
                    HStack(spacing: 0) {
                        // Active indicator for h2+
                        Rectangle()
                            .fill(isActive ? Theme.accent : Color.clear)
                            .frame(width: 2)
                            .cornerRadius(1)

                        Text(item.title)
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundColor(isActive ? Theme.accent : Theme.textFaint)
                            .lineLimit(2)
                            .padding(.vertical, 5)
                            .padding(.leading, 12 + CGFloat((item.level - 2) * 10))
                    }
                    .padding(.leading, 14)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isActive && item.level == 1 ? Theme.accentLight : Color.clear)
            .cornerRadius(5)
        }
        .buttonStyle(.plain)
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(Theme.uiFont)
                .foregroundColor(Theme.textFaint)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .default))
                .foregroundColor(Theme.textPrimary)
        }
    }
}
