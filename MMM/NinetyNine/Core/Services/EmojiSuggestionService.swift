import Foundation

final class EmojiSuggestionService {
    static let shared = EmojiSuggestionService()
    private init() {}

    private var apiKey: String {
        Bundle.main.infoDictionary?["ANTHROPIC_API_KEY"] as? String ?? ""
    }

    /// 단일 항목 → 이모지 1개
    func suggestEmoji(for text: String) async -> String? {
        guard !apiKey.isEmpty, !text.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }

        let prompt = "다음 할 일 텍스트에 가장 잘 어울리는 이모지를 딱 1개만 반환해. 이모지 외에 다른 텍스트나 공백 없이 이모지만: \(text)"

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 10,
            "messages": [["role": "user", "content": prompt]]
        ]

        guard let url = URL(string: "https://api.anthropic.com/v1/messages"),
              let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = jsonData

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let response = try? JSONDecoder().decode(AnthropicResponse.self, from: data),
              let content = response.content.first?.text.trimmingCharacters(in: .whitespaces),
              !content.isEmpty else { return nil }

        // 이모지만 추출 (혹시 텍스트가 섞여있을 경우 대비)
        let emoji = content.unicodeScalars.filter { $0.properties.isEmoji }.map { String($0) }.first
        return emoji ?? content.prefix(2).description
    }

    /// 9개 일괄 처리
    func suggestEmojis(for items: [String]) async -> [Int: String] {
        await withTaskGroup(of: (Int, String?).self) { group in
            for (i, item) in items.enumerated() {
                group.addTask { (i, await self.suggestEmoji(for: item)) }
            }
            var result: [Int: String] = [:]
            for await (i, emoji) in group {
                if let e = emoji { result[i] = e }
            }
            return result
        }
    }

    /// 텍스트 끝 이모지 교체 후 새 이모지 추가
    static func applyEmoji(_ emoji: String, to text: String) -> String {
        var trimmed = text.trimmingCharacters(in: .whitespaces)
        if let last = trimmed.unicodeScalars.last, last.properties.isEmoji {
            trimmed = String(trimmed.dropLast())
            trimmed = trimmed.trimmingCharacters(in: .whitespaces)
        }
        return trimmed.isEmpty ? emoji : "\(trimmed) \(emoji)"
    }
}

// MARK: - Anthropic API Response
private struct AnthropicResponse: Decodable {
    let content: [ContentBlock]
    struct ContentBlock: Decodable {
        let text: String
    }
}
