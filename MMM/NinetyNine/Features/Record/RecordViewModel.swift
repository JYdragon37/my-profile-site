import Foundation
import SwiftData

// MARK: - Weekly / Monthly Report Models

struct WeeklyReport {
    let completionRate: Double      // 0~1
    let totalItemsCompleted: Int
    let bestDayCount: Int           // highest completion count in a day
    let sparkRate: Double           // spark items completion rate
    let flowRate: Double
    let deepRate: Double
    let activeDays: Int             // days with at least 1 item done
}

struct MonthlyReport {
    let completionRate: Double
    let currentStreak: Int
    let longestStreak: Int
    let personalBestSeconds: Int?   // fastest 9/9 completion
    let totalChallengesCompleted: Int  // 9/9 days
}

// MARK: - Podium Entry
struct PodiumEntry: Identifiable {
    let id = UUID()
    let rank: Int          // 1, 2, 3
    let date: String       // "2026-04-08"
    let elapsedSeconds: Int

    var display: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return s > 0 ? "\(m)분 \(s)초" : "\(m)분"
    }

    var dateDisplay: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f.string(from: date.toDate() ?? Date())
    }

    var medal: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        default: return "🥉"
        }
    }
}

@MainActor
final class RecordViewModel: ObservableObject {

    @Published var monthlyRecords: [DailyRecord] = []
    @Published var selectedDate: String?
    @Published var selectedRecord: DailyRecord?
    @Published var allRecords: [DailyRecord] = []
    @Published var currentYearMonth: String = Date().yearMonthKey
    /// 현재 활성 루틴의 9개 항목 이름 (DayDetailView 에서 표시)
    @Published var activeRoutineItemNames: [String] = []

    private var recordRepository: RecordRepositoryProtocol?
    private var routineRepository: RoutineRepositoryProtocol?

    func setup(recordRepo: RecordRepositoryProtocol, routineRepo: RoutineRepositoryProtocol? = nil) {
        self.recordRepository = recordRepo
        self.routineRepository = routineRepo
        loadMonthlyRecords()
        loadAllRecords()
        loadActiveRoutineNames()
    }

    // MARK: - 활성 루틴 이름 로드
    private func loadActiveRoutineNames() {
        guard let repo = routineRepository else { return }
        Task {
            guard let project = try? await repo.getActiveProject() else { return }
            let items = project.todayRoutine().allItems
            self.activeRoutineItemNames = items.map { $0.title }
        }
    }

    // MARK: - 월별 기록
    func loadMonthlyRecords() {
        Task {
            let records = (try? await recordRepository?.getMonthlyRecords(yearMonth: currentYearMonth)) ?? []
            await MainActor.run { self.monthlyRecords = records }
        }
    }

    func selectDate(_ dateKey: String) {
        selectedDate = dateKey
        selectedRecord = monthlyRecords.first { $0.date == dateKey }
    }

    func deleteRecord(_ record: DailyRecord) {
        Task {
            try? await recordRepository?.deleteRecord(date: record.date)
            await MainActor.run {
                self.selectedRecord = nil
                self.loadMonthlyRecords()
                self.loadAllRecords()
            }
        }
    }

    func changeMonth(offset: Int) {
        guard let date = Calendar.current.date(
            byAdding: .month, value: offset,
            to: currentYearMonth.toYearMonthDate() ?? Date()
        ) else { return }
        currentYearMonth = date.yearMonthKey
        loadMonthlyRecords()
    }

    // MARK: - 전체 통계
    func loadAllRecords() {
        Task {
            let records = (try? await recordRepository?.getAllRecords()) ?? []
            await MainActor.run { self.allRecords = records }
        }
    }

    var currentStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        var checkDate = Date()
        while true {
            let key = checkDate.recordKey
            if allRecords.first(where: { $0.date == key && $0.isSuccess }) != nil {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else { break }
        }
        return streak
    }

    var longestStreak: Int {
        let calendar = Calendar.current
        let successDates = allRecords
            .filter { $0.isSuccess }
            .compactMap { $0.date.toDate() }
            .map { calendar.startOfDay(for: $0) }
            .sorted()
        guard !successDates.isEmpty else { return 0 }
        var longest = 1
        var current = 1
        for i in 1..<successDates.count {
            let diff = calendar.dateComponents([.day], from: successDates[i - 1], to: successDates[i]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else if diff > 1 {
                current = 1
            }
            // diff == 0 means duplicate date entries — skip without resetting
        }
        return longest
    }

    var personalBestSeconds: Int {
        allRecords.filter { $0.isSuccess }.map { $0.elapsedSeconds }.min() ?? 0
    }

    var personalBestDisplay: String {
        guard personalBestSeconds > 0 else { return "-" }
        let m = personalBestSeconds / 60
        let s = personalBestSeconds % 60
        return s > 0 ? "\(m)분 \(s)초" : "\(m)분"
    }

    var averageDisplay: String {
        let completed = allRecords.filter { $0.isSuccess }
        guard !completed.isEmpty else { return "-" }
        let avgSeconds = completed.map { $0.elapsedSeconds }.reduce(0, +) / completed.count
        let m = avgSeconds / 60
        let s = avgSeconds % 60
        return s > 0 ? "\(m)분 \(s)초" : "\(m)분"
    }

    var totalCompleted: Int {
        allRecords.filter { $0.isSuccess }.count
    }

    var monthlyCompletionRate: Double {
        let success = monthlyRecords.filter { $0.isSuccess }.count
        guard success > 0 else { return 0 }
        let calendar = Calendar.current
        let today = Date()
        let todayYearMonth = today.yearMonthKey
        let denominator: Int
        if currentYearMonth == todayYearMonth {
            // Current month: use days elapsed up to and including today
            denominator = calendar.component(.day, from: today)
        } else if let monthDate = currentYearMonth.toYearMonthDate(),
                  let range = calendar.range(of: .day, in: .month, for: monthDate) {
            // Past (or future) month: use total days in that month
            denominator = range.count
        } else {
            denominator = max(monthlyRecords.count, 1)
        }
        return Double(success) / Double(denominator)
    }

    // MARK: - 포디움 Top 3
    var podiumTop3: [PodiumEntry] {
        let maxSeconds = 199 * 60
        let eligible = allRecords
            .filter { $0.isSuccess && $0.elapsedSeconds > 0 && $0.elapsedSeconds <= maxSeconds }
            .sorted { $0.elapsedSeconds < $1.elapsedSeconds }
            .prefix(3)
        return eligible.enumerated().map { (i, r) in
            PodiumEntry(rank: i + 1, date: r.date, elapsedSeconds: r.elapsedSeconds)
        }
    }

    /// 특정 기록의 포디움 순위 (없으면 nil)
    func podiumRank(for elapsedSeconds: Int, date: String) -> Int? {
        let entry = podiumTop3.first { $0.date == date && $0.elapsedSeconds == elapsedSeconds }
        return entry?.rank
    }

    // 유형별 완료율
    var sparkCompletionRate: Double { itemCompletionRate(indices: [0, 1, 2]) }
    var flowCompletionRate: Double  { itemCompletionRate(indices: [3, 4, 5]) }
    var deepCompletionRate: Double  { itemCompletionRate(indices: [6, 7, 8]) }

    private func itemCompletionRate(indices: [Int]) -> Double {
        let records = allRecords.filter { !$0.itemStatus.isEmpty }
        guard !records.isEmpty else { return 0 }
        let total = records.count * indices.count
        let completed = records.flatMap { r in indices.map { r.itemStatus[safe: $0] ?? false } }.filter { $0 }.count
        return Double(completed) / Double(total)
    }

    // MARK: - Weekly Report
    var weeklyReport: WeeklyReport {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // Last 7 days including today
        let last7Keys: [String] = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today).map { $0.recordKey }
        }
        let weekRecords = allRecords.filter { last7Keys.contains($0.date) }

        // Completion rate: success days / 7
        let successDays = weekRecords.filter { $0.isSuccess }.count
        let completionRate = Double(successDays) / 7.0

        // Total items completed across all 7 days
        let totalItemsCompleted = weekRecords.reduce(0) { $0 + $1.completedCount }

        // Best day: highest completedCount in a single day
        let bestDayCount = weekRecords.map { $0.completedCount }.max() ?? 0

        // Active days: days with at least 1 item done
        let activeDays = weekRecords.filter { $0.completedCount > 0 }.count

        // Type-specific rates
        let sparkRate = weeklyItemCompletionRate(records: weekRecords, indices: [0, 1, 2])
        let flowRate  = weeklyItemCompletionRate(records: weekRecords, indices: [3, 4, 5])
        let deepRate  = weeklyItemCompletionRate(records: weekRecords, indices: [6, 7, 8])

        return WeeklyReport(
            completionRate: completionRate,
            totalItemsCompleted: totalItemsCompleted,
            bestDayCount: bestDayCount,
            sparkRate: sparkRate,
            flowRate: flowRate,
            deepRate: deepRate,
            activeDays: activeDays
        )
    }

    private func weeklyItemCompletionRate(records: [DailyRecord], indices: [Int]) -> Double {
        let filtered = records.filter { !$0.itemStatus.isEmpty }
        guard !filtered.isEmpty else { return 0 }
        let total = filtered.count * indices.count
        let completed = filtered.flatMap { r in indices.map { r.itemStatus[safe: $0] ?? false } }.filter { $0 }.count
        return Double(completed) / Double(total)
    }

    // MARK: - Monthly Report
    var monthlyReport: MonthlyReport {
        let calendar = Calendar.current
        let today = Date()
        let monthKey = today.yearMonthKey
        let monthRecords = allRecords.filter { $0.date.hasPrefix(monthKey) }

        // Completion rate: success days / days elapsed this month
        let successCount = monthRecords.filter { $0.isSuccess }.count
        let daysElapsed = calendar.component(.day, from: today)
        let completionRate = daysElapsed > 0 ? Double(successCount) / Double(daysElapsed) : 0

        // Personal best (fastest 9/9 completion)
        let bestSeconds = monthRecords.filter { $0.isSuccess && $0.elapsedSeconds > 0 }
            .map { $0.elapsedSeconds }.min()

        return MonthlyReport(
            completionRate: completionRate,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            personalBestSeconds: bestSeconds,
            totalChallengesCompleted: successCount
        )
    }
}

// MARK: - Date Extensions
extension Date {
    var yearMonthKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f.string(from: self)
    }
}

// String.toYearMonthDate() 및 String.toDate() 는 RecordView.swift 에 정의됨
