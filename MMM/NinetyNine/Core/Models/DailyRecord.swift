import Foundation
import SwiftData

// MARK: - Firestore 모델
struct DailyRecord: Codable {
    var date: String           // "YYYY-MM-DD"
    var completedCount: Int    // 0~9
    var elapsedSeconds: Int    // 실제 소요시간 (초 단위)
    var isSuccess: Bool        // 9/9 완료 여부
    var itemStatus: [Bool]     // 9개 각 항목 완료 여부

    /// "103분 12초" 형식으로 표시
    var elapsedDisplay: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return s > 0 ? "\(m)분 \(s)초" : "\(m)분"
    }

    var completionRate: Double {
        guard !itemStatus.isEmpty else { return 0 }
        return Double(completedCount) / Double(itemStatus.count)
    }

    static func empty(date: String = Date().recordKey) -> DailyRecord {
        DailyRecord(
            date: date,
            completedCount: 0,
            elapsedSeconds: 0,
            isSuccess: false,
            itemStatus: Array(repeating: false, count: 9)
        )
    }
}

// MARK: - SwiftData 로컬 캐시
@Model
final class LocalDailyRecord {
    var date: String
    var completedCount: Int
    var elapsedSeconds: Int
    var isSuccess: Bool
    var itemStatusJSON: Data    // [Bool] JSON 직렬화
    var lastSyncedAt: Date?

    init(from record: DailyRecord) {
        self.date = record.date
        self.completedCount = record.completedCount
        self.elapsedSeconds = record.elapsedSeconds
        self.isSuccess = record.isSuccess
        self.itemStatusJSON = (try? JSONEncoder().encode(record.itemStatus)) ?? Data()
        self.lastSyncedAt = Date()
    }

    func toDailyRecord() -> DailyRecord {
        let status = (try? JSONDecoder().decode([Bool].self, from: itemStatusJSON))
                     ?? Array(repeating: false, count: 9)
        return DailyRecord(
            date: date,
            completedCount: completedCount,
            elapsedSeconds: elapsedSeconds,
            isSuccess: isSuccess,
            itemStatus: status
        )
    }
}

// MARK: - Date Extension
extension Date {
    var recordKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    var isWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: self)
        return weekday == 1 || weekday == 7
    }
}
