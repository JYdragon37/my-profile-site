import Foundation

// MARK: - 루틴 타입
enum ItemType: String, Codable, CaseIterable, Hashable {
    case spark = "spark"  // 뚝딱 (3초, 즉시 완료)
    case flow  = "flow"   // 착착 (3분, 타이머)
    case deep  = "deep"   // 몰입 (30분, 타이머)

    var displayName: String {
        switch self {
        case .spark: return "뚝딱"
        case .flow:  return "착착"
        case .deep:  return "몰입"
        }
    }

    var durationSeconds: Int {
        switch self {
        case .spark: return 3  // 3초, 즉시 완료
        case .flow:  return Config.flowTimerSeconds   // 180초
        case .deep:  return Config.deepTimerSeconds   // 1800초
        }
    }

    var emoji: String {
        switch self {
        case .spark: return "⚡"
        case .flow:  return "🔹"
        case .deep:  return "🔵"
        }
    }
}

// MARK: - 루틴 항목
struct RoutineItem: Identifiable {
    let id: Int          // 0~8 (전체 인덱스)
    let title: String
    let type: ItemType

    var durationSeconds: Int { type.durationSeconds }
    var isInstant: Bool { type == .spark }
}

// MARK: - 루틴 (Firestore Codable)
struct Routine: Codable {
    var spark: [String]  // 뚝딱 × 3
    var flow: [String]   // 착착 × 3
    var deep: [String]   // 몰입 × 3

    // 9개 RoutineItem 배열로 변환
    var allItems: [RoutineItem] {
        var items: [RoutineItem] = []
        for (i, title) in spark.enumerated() {
            items.append(RoutineItem(id: i, title: title, type: .spark))
        }
        for (i, title) in flow.enumerated() {
            items.append(RoutineItem(id: 3 + i, title: title, type: .flow))
        }
        for (i, title) in deep.enumerated() {
            items.append(RoutineItem(id: 6 + i, title: title, type: .deep))
        }
        return items
    }

    static let empty = Routine(
        spark: ["", "", ""],
        flow:  ["", "", ""],
        deep:  ["", "", ""]
    )

    static let defaultTemplate = Routine(
        spark: ["물 한 잔 마시기", "오늘 날씨 확인", "감사한 것 1가지 떠올리기"],
        flow:  ["스트레칭 3분", "일기 쓰기", "뉴스 헤드라인 읽기"],
        deep:  ["독서 30분", "영어 공부 30분", "사이드 프로젝트 30분"]
    )
}
