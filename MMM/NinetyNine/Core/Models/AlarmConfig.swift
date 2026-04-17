import Foundation
import SwiftData

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .sunday:    return "일"
        case .monday:    return "월"
        case .tuesday:   return "화"
        case .wednesday: return "수"
        case .thursday:  return "목"
        case .friday:    return "금"
        case .saturday:  return "토"
        }
    }

    static var weekdays: [Weekday] { [.monday, .tuesday, .wednesday, .thursday, .friday] }
    static var weekends: [Weekday] { [.saturday, .sunday] }
}

// MARK: - AlarmConfig (로컬 전용, Firestore 미동기)
struct AlarmConfig: Identifiable, Codable {
    var id: UUID
    var label: String
    var hour: Int
    var minute: Int
    var repeatDays: [Weekday]
    var soundName: String
    var volume: Float           // 0.0~1.0
    var fadeIn: Bool
    var vibration: Bool
    var snoozeEnabled: Bool
    var snoozeDurationMinutes: Int
    var snoozeMaxCount: Int
    var challengeAutoStart: Bool
    var isEnabled: Bool

    var timeString: String {
        String(format: "%02d:%02d", hour, minute)
    }

    var repeatDaysString: String {
        if repeatDays.isEmpty { return "반복 없음" }
        if repeatDays.count == 7 { return "매일" }
        if Set(repeatDays) == Set(Weekday.weekdays) { return "평일" }
        if Set(repeatDays) == Set(Weekday.weekends) { return "주말" }
        return repeatDays
            .sorted { $0.rawValue < $1.rawValue }
            .map { $0.shortName }
            .joined()
    }

    static func defaultWeekday() -> AlarmConfig {
        AlarmConfig(
            id: UUID(),
            label: "평일 기상",
            hour: 6,
            minute: 30,
            repeatDays: Weekday.weekdays,
            soundName: "default",
            volume: 0.8,
            fadeIn: false,
            vibration: true,
            snoozeEnabled: false,
            snoozeDurationMinutes: 5,
            snoozeMaxCount: 3,
            challengeAutoStart: true,
            isEnabled: true
        )
    }
}

// MARK: - SwiftData 로컬 저장
@Model
final class LocalAlarmConfig {
    var id: UUID
    var label: String
    var hour: Int
    var minute: Int
    var repeatDaysJSON: Data
    var soundName: String
    var volume: Float
    var fadeIn: Bool
    var vibration: Bool
    var snoozeEnabled: Bool
    var snoozeDurationMinutes: Int
    var snoozeMaxCount: Int
    var challengeAutoStart: Bool
    var isEnabled: Bool

    init(from config: AlarmConfig) {
        self.id = config.id
        self.label = config.label
        self.hour = config.hour
        self.minute = config.minute
        self.repeatDaysJSON = (try? JSONEncoder().encode(config.repeatDays)) ?? Data()
        self.soundName = config.soundName
        self.volume = config.volume
        self.fadeIn = config.fadeIn
        self.vibration = config.vibration
        self.snoozeEnabled = config.snoozeEnabled
        self.snoozeDurationMinutes = config.snoozeDurationMinutes
        self.snoozeMaxCount = config.snoozeMaxCount
        self.challengeAutoStart = config.challengeAutoStart
        self.isEnabled = config.isEnabled
    }

    func toAlarmConfig() -> AlarmConfig {
        let days = (try? JSONDecoder().decode([Weekday].self, from: repeatDaysJSON)) ?? []
        return AlarmConfig(
            id: id, label: label, hour: hour, minute: minute,
            repeatDays: days, soundName: soundName, volume: volume,
            fadeIn: fadeIn, vibration: vibration,
            snoozeEnabled: snoozeEnabled,
            snoozeDurationMinutes: snoozeDurationMinutes,
            snoozeMaxCount: snoozeMaxCount,
            challengeAutoStart: challengeAutoStart,
            isEnabled: isEnabled
        )
    }
}
