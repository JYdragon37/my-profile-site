import Foundation
import SwiftData

// MARK: - 이미지 모델 (images 탭)
struct MotivationImage: Codable, Identifiable {
    var id: String           // "img_001"
    var storagePath: String  // "alarm-images/bg_deep_dark.jpg"
    var zone: String         // "deep_dark" | "first_light" | ...
}

// MARK: - 문구 모델 (quotes 탭)
struct MotivationQuote: Codable, Identifiable {
    var id: String           // "q_001"
    var quote: String
    var author: String
    var zone: String
}

// MARK: - 인사말 모델 (greetings 탭)
struct MotivationGreeting: Codable, Identifiable {
    var id: String       // "g_001"
    var greeting: String // "오늘 아침이 참 반가워요"  → 앱에서 "..., {name}" 조합
    var zone: String

    /// "{greeting}, {name}" 조합 — 이미 문장 끝에 구두점이면 공백만 추가
    func display(for name: String) -> String {
        let last = greeting.last
        let separator = (last == "," || last == "." || last == "!" || last == "?") ? " " : ", "
        return "\(greeting)\(separator)\(name)"
    }
}

// MARK: - 조합 콘텐츠 (화면 표시용)
struct MotivationContent {
    var image: MotivationImage
    var quote: MotivationQuote
    var greeting: MotivationGreeting

    var storagePath: String { image.storagePath }
    var zone: String { image.zone }
}

// MARK: - 기본 오프라인 콘텐츠
extension MotivationImage {
    static let defaults: [MotivationImage] = [
        MotivationImage(id: "img_000", storagePath: "", zone: "deep_dark"),
        MotivationImage(id: "img_001", storagePath: "", zone: "first_light"),
        MotivationImage(id: "img_002", storagePath: "", zone: "rise_ignite"),
        MotivationImage(id: "img_003", storagePath: "", zone: "peak_mode"),
        MotivationImage(id: "img_004", storagePath: "", zone: "recharge"),
        MotivationImage(id: "img_005", storagePath: "", zone: "second_wind"),
        MotivationImage(id: "img_006", storagePath: "", zone: "golden_hour"),
        MotivationImage(id: "img_007", storagePath: "", zone: "wind_down"),
    ]
}

extension MotivationGreeting {
    static let defaults: [MotivationGreeting] = [
        MotivationGreeting(id: "g_000", greeting: "오늘 아침이 참 반가워요",                   zone: "rise_ignite"),
        MotivationGreeting(id: "g_001", greeting: "이 고요한 밤에도 함께할 수 있어 좋아요",    zone: "deep_dark"),
        MotivationGreeting(id: "g_002", greeting: "새벽빛이 스며드는 이 순간이 좋아요",        zone: "first_light"),
        MotivationGreeting(id: "g_003", greeting: "지금 이 순간 당신의 집중력이 빛나고 있어요", zone: "peak_mode"),
        MotivationGreeting(id: "g_004", greeting: "잠깐 숨 고르는 시간이에요",                zone: "recharge"),
        MotivationGreeting(id: "g_005", greeting: "오후의 두 번째 바람이 불어오고 있어요",     zone: "second_wind"),
        MotivationGreeting(id: "g_006", greeting: "오늘 저녁도 포근하게 마무리해요",           zone: "golden_hour"),
        MotivationGreeting(id: "g_007", greeting: "고요한 밤이 왔네요. 오늘도 충분히 잘하셨어요", zone: "wind_down"),
    ]
}

extension MotivationQuote {
    static let defaults: [MotivationQuote] = [
        MotivationQuote(id: "q_000", quote: "작은 것을 매일 하는 사람이 결국 이깁니다.", author: "99", zone: "deep_dark"),
        MotivationQuote(id: "q_001", quote: "새벽을 연 사람이 하루를 완성합니다.", author: "99", zone: "first_light"),
        MotivationQuote(id: "q_002", quote: "해가 뜨는 속도로, 당신의 집중력도 올라갑니다.", author: "99", zone: "rise_ignite"),
        MotivationQuote(id: "q_003", quote: "중요한 것을 먼저. 나머지는 선물이다.", author: "99", zone: "peak_mode"),
        MotivationQuote(id: "q_004", quote: "숨 고르는 시간이 다음 질주를 만듭니다.", author: "99", zone: "recharge"),
        MotivationQuote(id: "q_005", quote: "하루의 절반이 남았습니다. 지금부터가 진짜입니다.", author: "99", zone: "second_wind"),
        MotivationQuote(id: "q_006", quote: "수고한 오늘, 이 노을이 당신의 것입니다.", author: "99", zone: "golden_hour"),
        MotivationQuote(id: "q_007", quote: "오늘도 잘 했어요. 이제 쉬어도 됩니다.", author: "99", zone: "wind_down"),
    ]
}
