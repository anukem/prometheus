import SwiftUI

enum ViewMode: String, CaseIterable {
    case preview = "Preview"
    case source  = "Source"
    case split   = "Split"
}

struct ContentView: View {
    @Binding var document: ParchmentDocument
    @StateObject private var model = DocumentModel()

    @State private var viewMode: ViewMode = .preview
    @State private var showOutline: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider().overlay(Theme.border)


            HStack(spacing: 0) {
                mainArea
                if showOutline {
                    OutlinePanel(model: model)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }

            Divider().overlay(Theme.border)
            statusBar
        }
        .background(WindowConfigurator())
        .background(Theme.background)
        .onChange(of: document.text) { newValue in
            model.update(source: newValue)
        }
        .onAppear {
            model.update(source: document.text)
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    var toolbar: some View {
        HStack(spacing: 0) {
            // View mode picker
            HStack(spacing: 2) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Button(mode.rawValue) { viewMode = mode }
                        .buttonStyle(SegmentButtonStyle(isSelected: viewMode == mode))
                }
            }
            .padding(3)
            .background(Theme.subtle)
            .cornerRadius(7)

            Spacer()

            // Right actions
            HStack(spacing: 4) {
                Button {
                    exportDocument()
                } label: {
                    Label("Export", systemImage: "arrow.down.to.line")
                        .labelStyle(.titleAndIcon)
                        .font(Theme.uiFont)
                        .foregroundColor(Theme.textFaint)
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(height: 16)
                    .padding(.horizontal, 4)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showOutline.toggle() }
                } label: {
                    Label("Outline", systemImage: "list.bullet.indent")
                        .labelStyle(.titleAndIcon)
                        .font(Theme.uiFontMedium)
                        .foregroundColor(showOutline ? Theme.accent : Theme.textFaint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(showOutline ? Theme.accentLight : Color.clear)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 44)
        .background(Theme.background)
    }

    // MARK: - Main area

    @ViewBuilder
    var mainArea: some View {
        switch viewMode {
        case .preview:
            ReaderView(source: document.text, onScrollProgressChanged: updateScrollProgress)
        case .source:
            SourceView(text: $document.text)
        case .split:
            HStack(spacing: 0) {
                SourceView(text: $document.text)
                    .frame(maxWidth: .infinity)
                Divider().overlay(Theme.border)
                ReaderView(source: document.text, onScrollProgressChanged: updateScrollProgress)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Status bar

    var statusBar: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 5, height: 5)
                Text(model.activeHeadingTitle)
                    .font(Theme.statusFont)
                    .foregroundColor(Theme.textFaint)
            }

            Spacer()

            HStack(spacing: 20) {
                Text("\(model.wordCount.formatted()) words")
                Text("Markdown")
            }
            .font(Theme.statusFont)
            .foregroundColor(Theme.textMeta)
        }
        .padding(.horizontal, 20)
        .frame(height: 28)
        .background(Theme.chrome)
    }

    // MARK: - Helpers

    private func exportDocument() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "document.pdf"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            // Basic text export for now
            try? document.text.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func updateScrollProgress(_ value: Double) {
        model.scrollProgress = min(1, max(0, value))
    }
}

// MARK: - Segment button style

struct SegmentButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(isSelected ? Theme.uiFontMedium : Theme.uiFont)
            .foregroundColor(isSelected ? Theme.textPrimary : Theme.textFaint)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(isSelected ? Theme.background : Color.clear)
            .cornerRadius(5)
            .shadow(color: isSelected ? Color.black.opacity(0.06) : .clear, radius: 1, y: 1)
    }
}
