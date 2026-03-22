import Foundation
import FoundationModels

enum AIFormatter {
    static func format(_ text: String) async throws -> String {
        guard case .available = SystemLanguageModel.default.availability else {
            throw AIFormatterError.unavailable
        }

        let session = LanguageModelSession {
            """
            You are a markdown formatting assistant. Your ONLY job is to add markdown
            formatting to the user's text. Strict rules:
            - NEVER remove, rephrase, summarize, or rewrite any text
            - NEVER add new content that wasn't in the original
            - ONLY add markdown syntax: # for headings, ** for bold, * for italic,
              ` for code, - for lists, > for quotes, ``` for code blocks
            - Every single word from the original must appear in your output
            - Add heading levels (# ## ###) where the structure suggests them
            - Use bullet lists when items are listed
            - Use numbered lists for sequential steps
            - Bold key terms and important phrases
            - Use inline code for technical terms, file names, commands, paths
            - Use code blocks with language tags for code snippets
            - Output ONLY the formatted markdown, nothing else
            """
        }

        let response = try await session.respond(to: text)
        return response.content
    }
}

enum AIFormatterError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Apple Intelligence is not available. Enable it in System Settings > Apple Intelligence."
    }
}
