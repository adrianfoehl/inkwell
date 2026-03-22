import Foundation
import FoundationModels

enum AIFormatter {
    static func format(_ text: String) async throws -> String {
        guard case .available = SystemLanguageModel.default.availability else {
            throw AIFormatterError.unavailable
        }

        let session = LanguageModelSession {
            """
            You are a markdown formatting assistant. Take the user's text and return it
            as clean, well-structured markdown. Apply these rules:
            - Add appropriate heading levels (# ## ###) based on content hierarchy
            - Use bullet lists for enumerations
            - Use numbered lists for sequential steps
            - Bold key terms and important phrases
            - Use inline code for technical terms, file names, commands
            - Use code blocks with language tags for code snippets
            - Use blockquotes for quotes or callouts
            - Keep the content identical — only add formatting, never change meaning
            - Output only the formatted markdown, nothing else
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
