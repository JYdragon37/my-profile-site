import Foundation
import Combine

// MARK: - BadgeService

@MainActor
final class BadgeService: ObservableObject {

    static let shared = BadgeService()

    @Published var badges: [Badge] = []

    private let userDefaultsKey = "com.ninetynine.badges"

    private init() {
        badges = load()
    }

    // MARK: - Persistence

    private func load() -> [Badge] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let saved = try? JSONDecoder().decode([Badge].self, from: data) else {
            // First launch: return all definitions with earnedAt = nil
            return Badge.allDefinitions
        }

        // Merge saved earned dates onto the canonical definitions
        // (so new badges added in updates appear automatically)
        let savedMap = Dictionary(uniqueKeysWithValues: saved.map { ($0.id, $0.earnedAt) })
        return Badge.allDefinitions.map { definition in
            var badge = definition
            badge.earnedAt = savedMap[definition.id] ?? nil
            return badge
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(badges) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    // MARK: - Evaluate

    /// Checks all badge conditions against the full record history and marks newly earned badges.
    /// Returns the list of badges that were just earned in this evaluation.
    @discardableResult
    func evaluate(records: [DailyRecord]) -> [Badge] {
        let snapshot = badges  // before state
        let now = Date()

        // Pre-compute helpers
        let longest = longestStreak(records: records)
        let successCount = countSuccesses(records: records)
        let fastest = fastestSuccessSeconds(records: records)
        let sparkConsecutiveDays = longestSparkDays(records: records)
        let flowTotalSuccessDays = countFlowSuccessDays(records: records)
        let deepTotalSuccessDays = countDeepSuccessDays(records: records)

        mutateIfUnearned("first_challenge") {
            successCount >= 1
        }

        mutateIfUnearned("spark_streak_7") {
            sparkConsecutiveDays >= 7
        }

        mutateIfUnearned("flow_count_30") {
            flowTotalSuccessDays >= 30
        }

        mutateIfUnearned("deep_count_10") {
            deepTotalSuccessDays >= 10
        }

        mutateIfUnearned("streak_3") {
            longest >= 3
        }

        mutateIfUnearned("streak_7") {
            longest >= 7
        }

        mutateIfUnearned("streak_14") {
            longest >= 14
        }

        mutateIfUnearned("streak_30") {
            longest >= 30
        }

        mutateIfUnearned("speed_199") {
            // Fastest successful completion is under 199 minutes
            guard let f = fastest else { return false }
            return f < 199 * 60
        }

        mutateIfUnearned("speed_120") {
            guard let f = fastest else { return false }
            return f < 120 * 60
        }

        mutateIfUnearned("count_10") {
            successCount >= 10
        }

        mutateIfUnearned("count_50") {
            successCount >= 50
        }

        save()

        // Determine newly earned badges by comparing earnedAt before/after
        let snapshotMap = Dictionary(uniqueKeysWithValues: snapshot.map { ($0.id, $0.isEarned) })
        let newlyEarned = badges.filter { badge in
            badge.isEarned && snapshotMap[badge.id] == false
        }
        return newlyEarned
    }

    // MARK: - Private Mutation Helper

    private func mutateIfUnearned(_ id: String, condition: () -> Bool) {
        guard let index = badges.firstIndex(where: { $0.id == id }),
              !badges[index].isEarned else { return }
        if condition() {
            badges[index].earnedAt = Date()
        }
    }

    // MARK: - Statistical Helpers

    /// Longest consecutive daily streak of successful (9/9) completions
    private func longestStreak(records: [DailyRecord]) -> Int {
        let calendar = Calendar.current
        let successDates = records
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
        }
        return longest
    }

    /// Total number of 9/9 success days
    private func countSuccesses(records: [DailyRecord]) -> Int {
        records.filter { $0.isSuccess }.count
    }

    /// Fastest elapsed seconds among successful completions
    private func fastestSuccessSeconds(records: [DailyRecord]) -> Int? {
        records.filter { $0.isSuccess && $0.elapsedSeconds > 0 }
               .map { $0.elapsedSeconds }
               .min()
    }

    /// Longest run of consecutive days where ALL spark items (indices 0,1,2) were completed
    private func longestSparkDays(records: [DailyRecord]) -> Int {
        let calendar = Calendar.current
        let sparkDates = records
            .filter { r in
                guard r.itemStatus.count >= 3 else { return false }
                return r.itemStatus[0] && r.itemStatus[1] && r.itemStatus[2]
            }
            .compactMap { $0.date.toDate() }
            .map { calendar.startOfDay(for: $0) }
            .sorted()

        guard !sparkDates.isEmpty else { return 0 }
        var longest = 1
        var current = 1
        for i in 1..<sparkDates.count {
            let diff = calendar.dateComponents([.day], from: sparkDates[i - 1], to: sparkDates[i]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else if diff > 1 {
                current = 1
            }
        }
        return longest
    }

    /// Total number of days where ALL flow items (indices 3,4,5) were completed
    private func countFlowSuccessDays(records: [DailyRecord]) -> Int {
        records.filter { r in
            guard r.itemStatus.count >= 6 else { return false }
            return r.itemStatus[3] && r.itemStatus[4] && r.itemStatus[5]
        }.count
    }

    /// Total number of days where ALL deep items (indices 6,7,8) were completed
    private func countDeepSuccessDays(records: [DailyRecord]) -> Int {
        records.filter { r in
            guard r.itemStatus.count >= 9 else { return false }
            return r.itemStatus[6] && r.itemStatus[7] && r.itemStatus[8]
        }.count
    }
}
