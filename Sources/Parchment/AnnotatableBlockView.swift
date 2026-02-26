import SwiftUI
import Markdown

struct AnnotatableBlockView: View {
    let block: any Markup
    let outlineIndex: Int?
    let blockId: BlockIdentifier
    @ObservedObject var annotationStore: AnnotationStore

    @State private var isComposing = false
    @State private var showActionBar = false
    @State private var commentText = ""
    @State private var isHovered = false
    @State private var submitGate = CommentSubmissionGate()

    private var isDeletionMarked: Bool {
        annotationStore.hasAnnotation(type: .deletion, for: blockId)
    }

    private var blockComments: [Annotation] {
        annotationStore.annotations(for: blockId).filter { $0.type == .comment }
    }

    private var isActive: Bool {
        annotationStore.isActive
    }

    var body: some View {
        if isActive {
            annotatedBody
        } else {
            // Plain rendering — no annotation UI, but @ObservedObject still
            // triggers re-render when isActive flips back to true
            BlockView(block: block, outlineIndex: outlineIndex)
        }
    }

    private var annotatedBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main block row
            HStack(alignment: .top, spacing: 0) {
                gutter
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 0) {
                    BlockView(block: block, outlineIndex: outlineIndex)
                        .overlay {
                            if isDeletionMarked {
                                GeometryReader { geo in
                                    Rectangle()
                                        .fill(Theme.annotationRed)
                                        .frame(height: 1.5)
                                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                                }
                            }
                        }
                        .opacity(isDeletionMarked ? 0.35 : 1.0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(blockBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isHovered ? Theme.border : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if isComposing {
                        // Don't toggle action bar while composing
                    } else {
                        showActionBar.toggle()
                    }
                }
            }

            // Action bar
            if showActionBar && !isComposing {
                actionBar
                    .padding(.leading, 36)
                    .padding(.top, 6)
                    .transition(.opacity)
            }

            // Inline comment composer
            if isComposing {
                commentComposer
                    .padding(.leading, 36)
                    .padding(.top, 8)
                    .transition(.opacity)
            }

            // Existing comments
            if !blockComments.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(blockComments) { annotation in
                        commentBubble(annotation)
                    }
                }
                .padding(.leading, 36)
                .padding(.top, 6)
            }
        }
    }

    // MARK: - Background

    private var blockBackground: Color {
        if isDeletionMarked { return Theme.annotationRedLight }
        if isHovered { return Theme.subtle.opacity(0.5) }
        return Color.clear
    }

    // MARK: - Gutter

    @ViewBuilder
    private var gutter: some View {
        VStack(spacing: 4) {
            if !blockComments.isEmpty {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.annotationComment)
            }
            if isDeletionMarked {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.annotationRed)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 2)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 8) {
            Button {
                commentText = ""
                withAnimation(.easeInOut(duration: 0.15)) {
                    isComposing = true
                    showActionBar = false
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.bubble")
                        .font(.system(size: 11))
                    Text("Comment")
                        .font(Theme.uiFont)
                }
                .foregroundColor(Theme.annotationComment)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.annotationComment.opacity(0.10))
                .cornerRadius(5)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("annotation.comment.open")

            Button {
                annotationStore.toggleDeletion(blockId: blockId)
                withAnimation(.easeInOut(duration: 0.15)) { showActionBar = false }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isDeletionMarked ? "arrow.uturn.backward" : "strikethrough")
                        .font(.system(size: 11))
                    Text(isDeletionMarked ? "Unmark" : "Delete")
                        .font(Theme.uiFont)
                }
                .foregroundColor(Theme.annotationRed)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.annotationRedLight)
                .cornerRadius(5)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.15)) { showActionBar = false }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.textFaint)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Comment Composer (inline)

    private var commentComposer: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thin accent bar at top
            Rectangle()
                .fill(Theme.annotationComment)
                .frame(height: 2)
                .cornerRadius(1)

            VStack(alignment: .leading, spacing: 10) {
                TextField("Leave feedback...", text: $commentText, onCommit: submitComment)
                    .font(.custom("IBMPlexSerif-Light", size: 14))
                    .foregroundColor(Theme.textBody)
                    .textFieldStyle(.plain)
                    .submitLabel(.send)
                    .accessibilityIdentifier("annotation.comment.input")

                HStack(spacing: 12) {
                    Spacer()

                    Button {
                        commentText = ""
                        withAnimation(.easeInOut(duration: 0.15)) { isComposing = false }
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.textFaint)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("annotation.comment.cancel")

                    Button {
                        submitComment()
                    } label: {
                        Text("Save")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .background(
                                commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? Theme.textMeta
                                    : Theme.annotationComment
                            )
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                    .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("annotation.comment.save")
                }
            }
            .padding(12)
            .background(Theme.background)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .strokeBorder(Theme.border, lineWidth: 1)
                    .padding(.top, -1) // overlap with accent bar
            )
        }
        .cornerRadius(6)
        .shadow(color: Color.black.opacity(0.06), radius: 4, y: 2)
    }

    private func submitComment() {
        submitGate.run {
            guard annotationStore.addCommentIfNotBlank(blockId: blockId, text: commentText) else { return }
            commentText = ""
            withAnimation(.easeInOut(duration: 0.15)) { isComposing = false }
        }
    }

    // MARK: - Comment Bubble

    private func commentBubble(_ annotation: Annotation) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Rectangle()
                .fill(Theme.annotationComment)
                .frame(width: 2)
                .cornerRadius(1)

            Text(annotation.comment ?? "")
                .font(.custom("IBMPlexSerif-LightItalic", size: 13))
                .foregroundColor(Theme.textMuted)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                annotationStore.removeAnnotation(id: annotation.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Theme.textFaint)
                    .padding(4)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
        .padding(.leading, 8)
        .padding(.vertical, 6)
        .accessibilityIdentifier("annotation.comment.row.\(annotation.id.uuidString)")
    }
}
