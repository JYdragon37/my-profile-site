import Foundation
import SwiftData

// MARK: - Firestore 모델
struct Project: Codable, Identifiable {
    var id: String
    var name: String          // 기본값: "일상습관"
    var version: Int
    var startDate: Date
    var endDate: Date?
    /// "auto": 다음 버전 생성 시 자동 설정 → 예약 취소 시 nil 복원
    /// "manual": 사용자가 직접 설정 → 취소해도 유지
    var endDateSetBy: String?
    var weekdayRoutine: Routine
    var weekendRoutine: Routine
    var createdAt: Date
    var colorHex: String      // 프로젝트 테마 컬러 (기본: "#4A9EFF")
    var emoji: String         // 프로젝트 대표 이모지 (기본: "⚡")

    /// 날짜 기반 파생 상태
    var status: ProjectStatus {
        let today = Calendar.current.startOfDay(for: Date())
        let start = Calendar.current.startOfDay(for: startDate)
        if start > today { return .scheduled }
        if let end = endDate, Calendar.current.startOfDay(for: end) < today { return .completed }
        return .active
    }

    enum ProjectStatus { case active, scheduled, completed }

    static func new(id: String = UUID().uuidString) -> Project {
        Project(
            id: id,
            name: "일상습관",
            version: 1,
            startDate: Date(),
            endDate: nil,
            endDateSetBy: nil,
            weekdayRoutine: Routine.defaultTemplate,
            weekendRoutine: Routine.defaultTemplate,
            createdAt: Date(),
            colorHex: "#4A9EFF",
            emoji: "⚡"
        )
    }

    // Codable 하위호환: 구 데이터에 colorHex/emoji 없으면 기본값 적용
    enum CodingKeys: String, CodingKey {
        case id, name, version, startDate, endDate, endDateSetBy
        case weekdayRoutine, weekendRoutine, createdAt, colorHex, emoji
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(String.self,  forKey: .id)
        name           = try c.decode(String.self,  forKey: .name)
        version        = try c.decode(Int.self,     forKey: .version)
        startDate      = try c.decode(Date.self,    forKey: .startDate)
        endDate        = try c.decodeIfPresent(Date.self,   forKey: .endDate)
        endDateSetBy   = try c.decodeIfPresent(String.self, forKey: .endDateSetBy)
        weekdayRoutine = try c.decode(Routine.self, forKey: .weekdayRoutine)
        weekendRoutine = try c.decode(Routine.self, forKey: .weekendRoutine)
        createdAt      = try c.decode(Date.self,    forKey: .createdAt)
        colorHex       = (try? c.decode(String.self, forKey: .colorHex)) ?? "#4A9EFF"
        emoji          = (try? c.decode(String.self, forKey: .emoji))    ?? "⚡"
    }

    // 요일 기반 오늘의 루틴 반환
    func todayRoutine(for date: Date = Date()) -> Routine {
        let weekday = Calendar.current.component(.weekday, from: date)
        let isWeekend = (weekday == 1 || weekday == 7) // 일(1), 토(7)
        return isWeekend ? weekendRoutine : weekdayRoutine
    }
}

// MARK: - SwiftData 로컬 캐시
@Model
final class LocalProject {
    var id: String
    var name: String
    var version: Int
    var startDate: Date
    var endDate: Date?
    var endDateSetBy: String?
    var weekdayRoutineJSON: Data
    var weekendRoutineJSON: Data
    var createdAt: Date
    var lastSyncedAt: Date?
    var colorHex: String?   // optional — 기존 데이터 하위호환
    var emoji: String?      // optional — 기존 데이터 하위호환

    init(from project: Project) {
        self.id = project.id
        self.name = project.name
        self.version = project.version
        self.startDate = project.startDate
        self.endDate = project.endDate
        self.endDateSetBy = project.endDateSetBy
        self.weekdayRoutineJSON = (try? JSONEncoder().encode(project.weekdayRoutine)) ?? Data()
        self.weekendRoutineJSON = (try? JSONEncoder().encode(project.weekendRoutine)) ?? Data()
        self.createdAt = project.createdAt
        self.lastSyncedAt = Date()
        self.colorHex = project.colorHex
        self.emoji = project.emoji
    }

    func toProject() -> Project? {
        guard
            let weekday = try? JSONDecoder().decode(Routine.self, from: weekdayRoutineJSON),
            let weekend = try? JSONDecoder().decode(Routine.self, from: weekendRoutineJSON)
        else { return nil }

        return Project(
            id: id,
            name: name,
            version: version,
            startDate: startDate,
            endDate: endDate,
            endDateSetBy: endDateSetBy,
            weekdayRoutine: weekday,
            weekendRoutine: weekend,
            createdAt: createdAt,
            colorHex: colorHex ?? "#4A9EFF",
            emoji: emoji ?? "⚡"
        )
    }
}
