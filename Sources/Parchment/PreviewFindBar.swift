import SwiftUI
import Markdown

final class PreviewFindController: ObservableObject {
    @Published var isVisible = false
    @Published var query = ""
    @Published var engine = PreviewFindEngine()

    func show() {
        isVisible = true
    }

    func dismiss() {
        isVisible = false
        query = ""
        engine = PreviewFindEngine()
    }

    func updateSearch(source: String) {
        let blockTexts = Self.blockTexts(from: source)
        engine.search(query: query, in: blockTexts)
    }

    func nextMatch() {
        engine.nextMatch()
    }

    func previousMatch() {
        engine.previousMatch()
    }

    static func blockTexts(from source: String) -> [String] {
        let doc = Document(parsing: source)
        return doc.children.map { extractPlainText(from: $0) }
    }
}

// MARK: - FocusedValue for menu command integration

struct PreviewFindControllerKey: FocusedValueKey {
    typealias Value = PreviewFindController
}

extension FocusedValues {
    var previewFindController: PreviewFindController? {
        get { self[PreviewFindControllerKey.self] }
        set { self[PreviewFindControllerKey.self] = newValue }
    }
}

// MARK: - Find bar view

struct PreviewFindBar: View {
    @ObservedObject var controller: PreviewFindController
    let source: String

    @FocusState private var isFieldFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textMuted)

                TextField("Find in preview…", text: $controller.query)
                    .textFieldStyle(.plain)
                    .font(Theme.uiFont)
                    .foregroundColor(Theme.textBody)
                    .focused($isFieldFocused)
                    .onSubmit {
                        if NSApp.currentEvent?.modifierFlags.contains(.shift) == true {
                            controller.previousMatch()
                        } else {
                            controller.nextMatch()
                        }
                    }
                    .onChange(of: controller.query) { _ in
                        controller.updateSearch(source: source)
                    }

                if !controller.query.isEmpty {
                    Text(matchLabel)
                        .font(.system(size: 11, weight: .regular, design: .default))
                        .foregroundColor(Theme.textFaint)
                        .fixedSize()
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.background)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Theme.border, lineWidth: 1)
            )

            HStack(spacing: 2) {
                Button {
                    controller.previousMatch()
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .disabled(controller.engine.matchCount == 0)

                Button {
                    controller.nextMatch()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .disabled(controller.engine.matchCount == 0)
            }
            .foregroundColor(controller.engine.matchCount > 0 ? Theme.textBody : Theme.textFaint)

            Button {
                controller.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.textFaint)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.chrome)
        .onAppear {
            isFieldFocused = true
        }
        .onExitCommand {
            controller.dismiss()
        }
    }

    private var matchLabel: String {
        let count = controller.engine.matchCount
        if count == 0 {
            return "No results"
        }
        return "\(controller.engine.currentIndex + 1) of \(count)"
    }
}
