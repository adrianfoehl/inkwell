import SwiftUI
import MarkdownUI

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @State private var isEditing = false
    @State private var editBuffer = ""

    var body: some View {
        Group {
            if isEditing {
                editView
            } else {
                readView
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Picker("Mode", selection: $isEditing) {
                    Text("Read").tag(false)
                    Text("Edit").tag(true)
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
        }
        .onAppear {
            editBuffer = document.text
        }
        .onChange(of: document.text) { _, newValue in
            if !isEditing {
                editBuffer = newValue
            }
        }
    }

    // MARK: - Read Mode

    private var readView: some View {
        ScrollView {
            Markdown(document.text)
                .markdownTheme(.inkwell)
                .textSelection(.enabled)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .environment(\.openURL, OpenURLAction { url in
            openSafeLink(url)
            return .handled
        })
    }

    // MARK: - Edit Mode

    private var editView: some View {
        TextEditor(text: $editBuffer)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.visible)
            .padding(8)
            .onChange(of: editBuffer) { _, newValue in
                document.text = newValue
            }
    }

    // MARK: - Link Safety

    private func openSafeLink(_ url: URL) {
        let allowedSchemes: Set<String> = ["http", "https", "mailto"]
        guard let scheme = url.scheme?.lowercased(),
              allowedSchemes.contains(scheme)
        else { return }
        NSWorkspace.shared.open(url)
    }
}
