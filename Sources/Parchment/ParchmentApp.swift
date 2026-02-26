import SwiftUI

@main
struct ParchmentApp: App {
    init() {
        FontLoader.registerFonts()
    }

    var body: some Scene {
        DocumentGroup(newDocument: ParchmentDocument()) { file in
            ContentView(document: file.$document)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open…") {
                    NSDocumentController.shared.openDocument(nil)
                }
                .keyboardShortcut("o")
            }

            FindCommands()
        }
    }
}

private struct FindCommands: Commands {
    @FocusedValue(\.previewFindController) var previewFindController

    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Button("Find…") {
                FindCommandRouting.performFind(previewFindController: previewFindController)
            }
            .keyboardShortcut("f")
        }
    }
}
