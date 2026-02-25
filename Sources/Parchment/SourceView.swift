import SwiftUI

struct SourceView: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            TextEditor(text: $text)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundColor(Theme.textBody)
                .scrollContentBackground(.hidden)
                .frame(width: 640)
                .padding(.top, 64)
                .padding(.bottom, 80)
            Spacer(minLength: 0)
        }
        .background(Theme.background)
    }
}
