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
    static let allDefinitions: [Badge] = [
        // First Steps
        Badge(
            id: "first_challenge",
            emoji: "🌱",
            title: "첫 출발",
            description: "첫 챌린지 완료 (9/9)",
            category: .firstSteps
        ),
        Badge(
            id: "spark_streak_7",
            emoji: "⚡",
            title: "뚝딱 마스터",
            description: "뚝딱 7일 연속 완료",
            category: .firstSteps
        ),
        Badge(
            id: "flow_count_30",
            emoji: "🔹",
            title: "착착 챔피언",
            description: "착착 완료 30회 누적",
            category: .firstSteps
        ),
        Badge(
            id: "deep_count_10",
            emoji: "🔵",
            title: "몰입 고수",
            description: "몰입 완료 10회 누적",
            category: .firstSteps
        ),

        // Streak
        Badge(
            id: "streak_3",
            emoji: "🔥",
            title: "3일의 힘",
            description: "3일 연속 챌린지 완료",
            category: .streak
        ),
        Badge(
            id: "streak_7",
            emoji: "⚔️",
            title: "일주일 전사",
            description: "7일 연속 챌린지 완료",
            category: .streak
        ),
        Badge(
            id: "streak_14",
            emoji: "🏅",
            title: "2주 챔피언",
            description: "14일 연속 챌린지 완료",
            category: .streak
        ),
        Badge(
            id: "streak_30",
            emoji: "🏆",
            title: "한 달의 기적",
            description: "30일 연속 챌린지 완료",
            category: .streak
        ),

        // Speed
        Badge(
            id: "speed_199",
            emoji: "⚡⚡",
            title: "번개 같은",
            description: "199분 이내 9/9 완료 최초",
            category: .speed
        ),
        Badge(
            id: "speed_120",
            emoji: "🚀",
            title: "속도의 신",
            description: "120분 이내 9/9 완료",
            category: .speed
        ),

        // Count
        Badge(
            id: "count_10",
            emoji: "💪",
            title: "10번의 도전",
            description: "9/9 완료 10회",
            category: .count
        ),
        Badge(
            id: "count_50",
            emoji: "✨",
            title: "50번의 기적",
            description: "9/9 완료 50회",
            category: .count
        ),
    ]
}
