import Foundation

// MARK: - Badge Model

struct Badge: Identifiable, Codable {
    let id: String
    let emoji: String
    let title: String
    let description: String
    let category: BadgeCategory
    var earnedAt: Date?

    var isEarned: Bool { earnedAt != nil }

    enum BadgeCategory: String, Codable, CaseIterable {
        case firstSteps
        case streak
        case speed
        case count

        var displayName: String {
            switch self {
            case .firstSteps: return "첫 발걸음"
            case .streak:     return "연속 달성"
            case .speed:      return "스피드"
            case .count:      return "누적 도전"
            }
        }
    }
}

// MARK: - All Badge Definitions

extension Badge {
    // 난이도 단조 증가 순서 (Day 1 → Day 50+)
    static let allDefinitions: [Badge] = [

        // ── Day ~1 ──────────────────────────────────────
        Badge(
            id: "first_challenge",
            emoji: "🌱",
            title: "첫 출발",
            description: "9/9 챌린지 첫 완료",
            category: .firstSteps
        ),

        // ── Day ~3 ──────────────────────────────────────
        Badge(
            id: "streak_3",
            emoji: "🔥",
            title: "3일의 힘",
            description: "3일 연속 챌린지 완료",
            category: .streak
        ),

        // ── Day ~5 ──────────────────────────────────────
        Badge(
            id: "spark_items_15",
            emoji: "⚡",
            title: "뚝딱 마스터",
            description: "뚝딱 항목 15회 완료 (3개 × 5일)",
            category: .firstSteps
        ),

        // ── Day ~7 ──────────────────────────────────────
        Badge(
            id: "flow_items_21",
            emoji: "🔹",
            title: "착착 챔피언",
            description: "착착 항목 21회 완료 (3개 × 7일)",
            category: .firstSteps
        ),
        Badge(
            id: "streak_7",
            emoji: "⚔️",
            title: "일주일 전사",
            description: "7일 연속 챌린지 완료",
            category: .streak
        ),

        // ── Day ~7-10 (속도 기준) ───────────────────────
        Badge(
            id: "speed_120",
            emoji: "⚡⚡",
            title: "번개 같은",
            description: "120분 이내 9/9 첫 완료",
            category: .speed
        ),

        // ── Day ~10-14 ──────────────────────────────────
        Badge(
            id: "count_10",
            emoji: "💪",
            title: "10번의 도전",
            description: "9/9 완료 10회",
            category: .count
        ),
        Badge(
            id: "deep_items_30",
            emoji: "🔵",
            title: "몰입 고수",
            description: "몰입 항목 30회 완료 (3개 × 10일)",
            category: .firstSteps
        ),

        // ── Day ~14 ─────────────────────────────────────
        Badge(
            id: "streak_14",
            emoji: "🏅",
            title: "2주 챔피언",
            description: "14일 연속 챌린지 완료",
            category: .streak
        ),

        // ── Day ~20+ (속도 기준) ────────────────────────
        Badge(
            id: "speed_90",
            emoji: "🚀",
            title: "속도의 신",
            description: "90분 이내 9/9 완료",
            category: .speed
        ),

        // ── Day ~30 ─────────────────────────────────────
        Badge(
            id: "streak_30",
            emoji: "🏆",
            title: "한 달의 기적",
            description: "30일 연속 챌린지 완료",
            category: .streak
        ),

        // ── Day ~50+ ────────────────────────────────────
        Badge(
            id: "count_50",
            emoji: "✨",
            title: "50번의 기적",
            description: "9/9 완료 50회",
            category: .count
        ),
    ]
}
