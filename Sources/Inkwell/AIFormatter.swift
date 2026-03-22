import Foundation
import FoundationModels

enum AIFormatter {
    static func format(_ text: String) async throws -> String {
        guard case .available = SystemLanguageModel.default.availability else {
            throw AIFormatterError.unavailable
        }

        let session = LanguageModelSession {
            """
            Add markdown formatting to the user's text.

            CRITICAL RULES:
            1. NEVER delete, remove, shorten, summarize, or rephrase ANY text
            2. NEVER add new words or sentences
            3. The output must contain EVERY word from the input — word for word
            4. You may ONLY insert markdown syntax characters between existing words:
               # ## ### for headings, ** for bold, * for italic, ` for inline code,
               ``` for code blocks, - for bullet lists, 1. for numbered lists, > for quotes
            5. You may split or join lines for better structure
            6. Output ONLY the formatted text, no explanations

            If the text is already well-formatted, return it unchanged.
            """
        }

        let response = try await session.respond(to: text)
        let formatted = response.content

        // Safety check: AI must not remove significant content
        let originalWords = Set(text.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }))
        let formattedWords = Set(formatted.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }))
        let missingWords = originalWords.subtracting(formattedWords)

        // Allow up to 5% word loss (whitespace/formatting artifacts)
        let lossRatio = Double(missingWords.count) / Double(max(originalWords.count, 1))
        if lossRatio > 0.05 {
            throw AIFormatterError.contentRemoved
        }

        return formatted
    }
}

enum AIFormatterError: LocalizedError {
    case unavailable
    case contentRemoved

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "Apple Intelligence is not available. Enable it in System Settings > Apple Intelligence."
        case .contentRemoved:
            "AI tried to remove content. Formatting rejected — your text is unchanged."
        }
    }
}
