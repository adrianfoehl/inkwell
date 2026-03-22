import SwiftUI

struct ContentView: View {
    @State private var text = ""
    @State private var frontMatter = "" // stored separately, not shown in editor
    @State private var fileURL: URL?
    @State private var isTargeted = false
    @State private var folderURL: URL?
    @State private var folderFiles: [URL] = []
    @State private var showOutline = false
    @State private var showFrontMatter = false

    var hasFile: Bool { fileURL != nil }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            VStack(spacing: 0) {
                if hasFile && !frontMatter.isEmpty {
                    frontMatterBanner
                }
                ZStack {
                    if hasFile {
                        InkEditorView(text: text) { newText in
                            text = newText
                        }
                    } else {
                        dropZone
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers)
            }
            .overlay(alignment: .bottom) {
                if hasFile {
                    statusBar
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 4) {
                        Button(action: newFile) {
                            Label("New", systemImage: "doc.badge.plus")
                        }
                        .help("New File (Cmd+N)")

                        Button(action: openFile) {
                            Label("Open", systemImage: "folder")
                        }
                        .help("Open File (Cmd+O)")

                        if hasFile {
                            Button(action: { showOutline.toggle() }) {
                                Label("Outline", systemImage: "sidebar.trailing")
                            }
                            .help("Toggle Outline")
                        }
                    }
                }
            }
            .navigationTitle(fileURL?.lastPathComponent ?? "Inkwell")
        }
        .navigationTitle(fileURL?.lastPathComponent ?? "Inkwell")
        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
        .inspector(isPresented: $showOutline) {
            outlinePanel
                .inspectorColumnWidth(min: 180, ideal: 200, max: 280)
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveFile)) { _ in
            saveFile()
        }
        .onReceive(NotificationCenter.default.publisher(for: .formatCommand)) { notification in
            if let cmd = notification.object as? String {
                NotificationCenter.default.post(name: .editorFormatCommand, object: cmd)
            }
        }
    }

    // MARK: - Sidebar (File Tree)

    private var sidebar: some View {
        Group {
            if folderFiles.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("No folder open")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("Open Folder") { openFolder() }
                        .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $fileURL) {
                    ForEach(folderFiles, id: \.self) { file in
                        Label(file.lastPathComponent, systemImage: "doc.text")
                            .tag(file)
                    }
                }
                .onChange(of: fileURL) { _, newURL in
                    if let url = newURL {
                        loadFile(url)
                    }
                }
                .navigationTitle(folderURL?.lastPathComponent ?? "Files")
            }
        }
    }

    // MARK: - Outline Panel

    private var outlinePanel: some View {
        let headings = parseHeadings(from: text)
        return List {
            if headings.isEmpty {
                Text("No headings found")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(headings) { heading in
                    Button(action: {}) {
                        Text(heading.title)
                            .font(heading.level == 1 ? .headline : heading.level == 2 ? .subheadline : .caption)
                            .padding(.leading, CGFloat((heading.level - 1) * 12))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Outline")
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 16) {
            let words = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
            let chars = text.count
            let lines = text.components(separatedBy: .newlines).count
            let readTime = max(1, words / 200)

            Text("\(words) words")
            Text("\(chars) chars")
            Text("\(lines) lines")
            Text("~\(readTime) min read")

            Spacer()

            if let url = fileURL {
                Text(url.path(percentEncoded: false))
                    .help(url.path(percentEncoded: false))
                    .lineLimit(1)
                    .truncationMode(.head)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.bar)
    }

    // MARK: - Front Matter Banner

    private var frontMatterBanner: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showFrontMatter.toggle() } }) {
                HStack(spacing: 6) {
                    Image(systemName: showFrontMatter ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                    Image(systemName: "doc.badge.gearshape")
                        .font(.caption)
                    Text("Front Matter")
                        .font(.caption)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            if showFrontMatter {
                TextEditor(text: $frontMatter)
                    .font(.system(.caption, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .frame(maxHeight: 150)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
            }

            Divider()
        }
        .background(.bar)
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

    // MARK: - File Handling

    private func newFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "Untitled.md"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        let initial = "# \(url.deletingPathExtension().lastPathComponent)\n\n"
        try? initial.write(to: url, atomically: true, encoding: .utf8)
        loadFile(url)
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        loadFile(url)
    }

    private func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        folderURL = url
        scanFolder(url)
    }

    private func scanFolder(_ url: URL) {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        var files: [URL] = []
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            if ["md", "markdown", "mdown", "mkd"].contains(ext) {
                files.append(fileURL)
            }
        }
        folderFiles = files.sorted { $0.lastPathComponent.localizedCompare($1.lastPathComponent) == .orderedAscending }

        if let first = folderFiles.first, !hasFile {
            loadFile(first)
        }
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
        let (fm, body) = splitFrontMatter(content)
        frontMatter = fm
        text = body
        fileURL = url
    }

    private func saveFile() {
        guard let url = fileURL else { return }
        let full = frontMatter.isEmpty ? text : frontMatter + "\n" + text
        try? full.write(to: url, atomically: true, encoding: .utf8)
    }

    private func splitFrontMatter(_ content: String) -> (String, String) {
        guard content.hasPrefix("---") else { return ("", content) }
        let lines = content.components(separatedBy: .newlines)
        guard let endIndex = lines.dropFirst().firstIndex(where: {
            $0.trimmingCharacters(in: .whitespaces) == "---"
        }) else {
            return ("", content)
        }
        let fm = lines[...endIndex].joined(separator: "\n")
        let body = lines.suffix(from: endIndex + 1).joined(separator: "\n").trimmingCharacters(in: .newlines)
        return (fm, body)
    }

    // MARK: - Heading Parser

    private func parseHeadings(from markdown: String) -> [HeadingItem] {
        markdown.components(separatedBy: .newlines).compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("#") else { return nil }

            var level = 0
            for char in trimmed {
                if char == "#" { level += 1 } else { break }
            }
            guard level >= 1, level <= 6 else { return nil }

            let title = String(trimmed.dropFirst(level)).trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty else { return nil }
            return HeadingItem(level: level, title: title)
        }
    }
}

// MARK: - Models

struct HeadingItem: Identifiable {
    let id = UUID()
    let level: Int
    let title: String
}
