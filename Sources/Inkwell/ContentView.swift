import SwiftUI
import MarkdownUI

struct ContentView: View {
    @State private var text = ""
    @State private var fileURL: URL?
    @State private var isEditing = false
    @State private var editBuffer = ""
    @State private var isTargeted = false

    var hasFile: Bool { fileURL != nil }

    var body: some View {
        Group {
            if hasFile {
                fileView
            } else {
                dropZone
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
        .toolbar {
            if hasFile {
                ToolbarItem(placement: .primaryAction) {
                    Picker("Mode", selection: $isEditing) {
                        Text("Read").tag(false)
                        Text("Edit").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
            }
            ToolbarItem(placement: .automatic) {
                Button(action: openFile) {
                    Label("Open", systemImage: "doc")
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
        .navigationTitle(fileURL?.lastPathComponent ?? "Inkwell")
    }

    // MARK: - Drop Zone

    private var dropZone: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Drop a .md file here")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("or press Cmd+O to open")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.clear,
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .padding(20)
        )
    }

    // MARK: - File View

    private var fileView: some View {
        Group {
            if isEditing {
                editView
            } else {
                readView
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
    }

    // MARK: - Read Mode

    private var readView: some View {
        ScrollView {
            Markdown(text)
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
                text = newValue
            }
    }

    // MARK: - File Handling

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        loadFile(url)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil)
            else { return }

            let ext = url.pathExtension.lowercased()
            guard ["md", "markdown", "mdown", "mkd", "txt"].contains(ext) else { return }

            DispatchQueue.main.async {
                loadFile(url)
            }
        }
        return true
    }

    private func loadFile(_ url: URL) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        text = content
        editBuffer = content
        fileURL = url
        isEditing = false
    }

    private func saveFile() {
        guard let url = fileURL else { return }
        try? text.write(to: url, atomically: true, encoding: .utf8)
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
