import MarkdownUI
import HighlightSwift
import SwiftUI

extension Theme {
    static let inkwell = Theme()
        .text {
            FontSize(16)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.85))
            ForegroundColor(.secondary)
        }
        .heading1 { configuration in
            configuration.label
                .markdownMargin(top: 24, bottom: 16)
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(32)
                }
        }
        .heading2 { configuration in
            configuration.label
                .markdownMargin(top: 24, bottom: 12)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(24)
                }
        }
        .heading3 { configuration in
            configuration.label
                .markdownMargin(top: 20, bottom: 8)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(20)
                }
        }
        .blockquote { configuration in
            configuration.label
                .padding(.leading, 16)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.4))
                        .frame(width: 4)
                }
                .markdownMargin(top: 8, bottom: 8)
        }
        .codeBlock { configuration in
            HighlightedCodeBlock(code: configuration.content, language: configuration.language)
                .markdownMargin(top: 8, bottom: 8)
        }
        .paragraph { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.3))
                .markdownMargin(top: 0, bottom: 12)
        }
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: .em(0.2))
        }
}

struct HighlightedCodeBlock: View {
    let code: String
    let language: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            codeContent
        }
        .padding(12)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var codeContent: some View {
        if let language = language, let lang = HighlightLanguage(rawValue: language) {
            CodeText(code)
                .codeTextColors(.theme(.xcode))
                .highlightLanguage(lang)
                .font(.system(.callout, design: .monospaced))
        } else {
            CodeText(code)
                .codeTextColors(.theme(.xcode))
                .highlightMode(.automatic)
                .font(.system(.callout, design: .monospaced))
        }
    }
}
