import SwiftUI

@main
struct InkwellApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 900, height: 700)
        .commands {
            CommandGroup(after: .saveItem) {
                Button("Save") {
                    NotificationCenter.default.post(name: .saveFile, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
            }

            CommandMenu("Format") {
                Section("Inline") {
                    Button("Bold") {
                        NotificationCenter.default.post(name: .formatCommand, object: "bold")
                    }
                    .keyboardShortcut("b", modifiers: .command)

                    Button("Italic") {
                        NotificationCenter.default.post(name: .formatCommand, object: "italic")
                    }
                    .keyboardShortcut("i", modifiers: .command)

                    Button("Inline Code") {
                        NotificationCenter.default.post(name: .formatCommand, object: "code")
                    }
                    .keyboardShortcut("e", modifiers: .command)

                    Button("Strikethrough") {
                        NotificationCenter.default.post(name: .formatCommand, object: "strikethrough")
                    }
                    .keyboardShortcut("d", modifiers: [.command, .shift])
                }

                Divider()

                Section("Block") {
                    Button("Heading 1") {
                        NotificationCenter.default.post(name: .formatCommand, object: "h1")
                    }
                    .keyboardShortcut("1", modifiers: [.command, .option])

                    Button("Heading 2") {
                        NotificationCenter.default.post(name: .formatCommand, object: "h2")
                    }
                    .keyboardShortcut("2", modifiers: [.command, .option])

                    Button("Heading 3") {
                        NotificationCenter.default.post(name: .formatCommand, object: "h3")
                    }
                    .keyboardShortcut("3", modifiers: [.command, .option])
                }

                Divider()

                Section("Insert") {
                    Button("Bullet List") {
                        NotificationCenter.default.post(name: .formatCommand, object: "bulletList")
                    }

                    Button("Numbered List") {
                        NotificationCenter.default.post(name: .formatCommand, object: "orderedList")
                    }

                    Button("Blockquote") {
                        NotificationCenter.default.post(name: .formatCommand, object: "blockquote")
                    }

                    Button("Code Block") {
                        NotificationCenter.default.post(name: .formatCommand, object: "codeBlock")
                    }

                    Button("Divider") {
                        NotificationCenter.default.post(name: .formatCommand, object: "hr")
                    }
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        NotificationCenter.default.post(name: .openFileFromOS, object: url)
    }
}

extension Notification.Name {
    static let saveFile = Notification.Name("inkwell.saveFile")
    static let formatCommand = Notification.Name("inkwell.formatCommand")
    static let editorFormatCommand = Notification.Name("inkwell.editorFormatCommand")
    static let openFileFromOS = Notification.Name("inkwell.openFileFromOS")
}
