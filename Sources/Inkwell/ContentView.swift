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
    @State private var isFormatting = false
    @State private var textBeforeFormat: String?
    @State private var formattedPreview: String?
    @State private var showFormatPreview = false
    @State private var formatError: String?

    var hasFile: Bool { fileURL != nil }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            VStack(spacing: 0) {
                if hasFile && !frontMatter.isEmpty {
                    frontMatterBanner
                }
                if hasFile {
                    formatBar
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
        .onReceive(NotificationCenter.default.publisher(for: .openFileFromOS)) { notification in
            if let url = notification.object as? URL {
                loadFile(url)
            }
        }
        .alert("Auto-Format", isPresented: Binding(get: { formatError != nil }, set: { if !$0 { formatError = nil } })) {
            Button("OK") { formatError = nil }
        } message: {
            Text(formatError ?? "")
        }
        .sheet(isPresented: $showFormatPreview) {
            formatPreviewSheet
        }
    }

    // MARK: - Format Preview

    private var formatPreviewSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Auto-Format Preview")
                    .font(.headline)
                Spacer()
                Button("Reject") { rejectFormat() }
                    .keyboardShortcut(.escape)
                Button("Accept") { acceptFormat() }
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    let diffs = computeDiff(
                        old: textBeforeFormat ?? "",
                        new: formattedPreview ?? ""
                    )
                    ForEach(Array(diffs.enumerated()), id: \.offset) { _, line in
                        HStack(spacing: 8) {
                            Text(line.prefix)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(line.color)
                                .frame(width: 14, alignment: .center)
                            Text(line.text)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(line.color)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 1)
                        .background(line.background)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(minWidth: 800, minHeight: 500)
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

    // MARK: - Format Bar

    private var formatBar: some View {
        HStack(spacing: 2) {
            formatButton("B", help: "Bold (⌘B)") { sendFormat("bold") }
            formatButton("I", help: "Italic (⌘I)") { sendFormat("italic") }
            formatButton("S", help: "Strikethrough (⇧⌘D)") { sendFormat("strikethrough") }
            formatButton("</>", help: "Code (⌘E)") { sendFormat("code") }

            Divider().frame(height: 16).padding(.horizontal, 4)

            formatButton("H1", help: "Heading 1 (⌥⌘1)") { sendFormat("h1") }
            formatButton("H2", help: "Heading 2 (⌥⌘2)") { sendFormat("h2") }
            formatButton("H3", help: "Heading 3 (⌥⌘3)") { sendFormat("h3") }

            Divider().frame(height: 16).padding(.horizontal, 4)

            formatButton("•", help: "Bullet List") { sendFormat("bulletList") }
            formatButton("1.", help: "Numbered List") { sendFormat("orderedList") }
            formatButton(">", help: "Blockquote") { sendFormat("blockquote") }

            Spacer()

            if AIFormatter.isAvailable { Button(action: autoFormat) {
                HStack(spacing: 4) {
                    if isFormatting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isFormatting ? "Formatting..." : "Auto-Format")
                        .font(.system(size: 11))
                }
                .frame(minHeight: 22)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(isFormatting || text.isEmpty)
            .help("Format with Apple Intelligence")
            }

            if textBeforeFormat != nil {
                Button(action: undoFormat) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Undo")
                            .font(.system(size: 11))
                    }
                    .frame(minHeight: 22)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.orange)
                .help("Undo Auto-Format")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(.bar)
    }

    private func autoFormat() {
        isFormatting = true
        textBeforeFormat = text
        Task {
            do {
                let formatted = try await AIFormatter.format(text)
                formattedPreview = formatted
                showFormatPreview = true
            } catch {
                formatError = error.localizedDescription
                textBeforeFormat = nil
            }
            isFormatting = false
        }
    }

    private func acceptFormat() {
        if let formatted = formattedPreview {
            text = formatted
        }
        showFormatPreview = false
        formattedPreview = nil
    }

    private func rejectFormat() {
        showFormatPreview = false
        formattedPreview = nil
        textBeforeFormat = nil
    }

    private func undoFormat() {
        if let previous = textBeforeFormat {
            text = previous
            textBeforeFormat = nil
        }
    }

    private func formatButton(_ label: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: label == "B" ? .bold : .regular))
                .frame(minWidth: 24, minHeight: 22)
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func sendFormat(_ cmd: String) {
        NotificationCenter.default.post(name: .editorFormatCommand, object: cmd)
    }

    // MARK: - Diff

    private func computeDiff(old: String, new: String) -> [DiffLine] {
        let oldLines = old.components(separatedBy: .newlines)
        let newLines = new.components(separatedBy: .newlines)

        // LCS-based diff
        let lcs = longestCommonSubsequence(oldLines, newLines)
        var result: [DiffLine] = []
        var oldIdx = 0
        var newIdx = 0
        var lcsIdx = 0
        var skippedUnchanged = 0

        while oldIdx < oldLines.count || newIdx < newLines.count {
            if lcsIdx < lcs.count,
               oldIdx < oldLines.count, oldLines[oldIdx] == lcs[lcsIdx],
               newIdx < newLines.count, newLines[newIdx] == lcs[lcsIdx] {
                // Unchanged — skip but track count
                skippedUnchanged += 1
                oldIdx += 1
                newIdx += 1
                lcsIdx += 1
            } else if oldIdx < oldLines.count && (lcsIdx >= lcs.count || oldLines[oldIdx] != lcs[lcsIdx]) {
                if skippedUnchanged > 0 {
                    result.append(DiffLine(prefix: "·", text: "\(skippedUnchanged) unchanged lines", kind: .separator))
                    skippedUnchanged = 0
                }
                result.append(DiffLine(prefix: "−", text: oldLines[oldIdx], kind: .removed))
                oldIdx += 1
            } else if newIdx < newLines.count && (lcsIdx >= lcs.count || newLines[newIdx] != lcs[lcsIdx]) {
                if skippedUnchanged > 0 {
                    result.append(DiffLine(prefix: "·", text: "\(skippedUnchanged) unchanged lines", kind: .separator))
                    skippedUnchanged = 0
                }
                result.append(DiffLine(prefix: "+", text: newLines[newIdx], kind: .added))
                newIdx += 1
            }
        }

        if result.isEmpty {
            result.append(DiffLine(prefix: "✓", text: "No changes", kind: .separator))
        }

        return result
    }

    private func longestCommonSubsequence(_ a: [String], _ b: [String]) -> [String] {
        let m = a.count, n = b.count
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        for i in 1...m {
            for j in 1...n {
                dp[i][j] = a[i-1] == b[j-1] ? dp[i-1][j-1] + 1 : max(dp[i-1][j], dp[i][j-1])
            }
        }
        var result: [String] = []
        var i = m, j = n
        while i > 0 && j > 0 {
            if a[i-1] == b[j-1] {
                result.append(a[i-1])
                i -= 1; j -= 1
            } else if dp[i-1][j] > dp[i][j-1] {
                i -= 1
            } else {
                j -= 1
            }
        }
        return result.reversed()
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

struct DiffLine {
    let prefix: String
    let text: String
    let kind: Kind

    enum Kind {
        case added, removed, unchanged, separator
    }

    var color: Color {
        switch kind {
        case .added: .green
        case .removed: .red
        case .unchanged: .primary
        case .separator: .gray
        }
    }

    var background: Color {
        switch kind {
        case .added: .green.opacity(0.1)
        case .removed: .red.opacity(0.1)
        default: .clear
        }
    }
}
