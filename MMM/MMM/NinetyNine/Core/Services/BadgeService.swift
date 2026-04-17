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
        let snapshot = badges

        let longest      = longestStreak(records: records)
        let successCount = countSuccesses(records: records)
        let fastest      = fastestSuccessSeconds(records: records)
        let sparkItems   = countSparkItems(records: records)   // 뚝딱 항목 누적 개수
        let flowItems    = countFlowItems(records: records)    // 착착 항목 누적 개수
        let deepItems    = countDeepItems(records: records)    // 몰입 항목 누적 개수

        // 난이도 오름차순으로 평가
        mutateIfUnearned("first_challenge")  { successCount >= 1 }
        mutateIfUnearned("streak_3")         { longest >= 3 }
        mutateIfUnearned("spark_items_15")   { sparkItems >= 15 }
        mutateIfUnearned("flow_items_21")    { flowItems >= 21 }
        mutateIfUnearned("streak_7")         { longest >= 7 }
        mutateIfUnearned("speed_120")        { (fastest ?? Int.max) < 120 * 60 }
        mutateIfUnearned("count_10")         { successCount >= 10 }
        mutateIfUnearned("deep_items_30")    { deepItems >= 30 }
        mutateIfUnearned("streak_14")        { longest >= 14 }
        mutateIfUnearned("speed_90")         { (fastest ?? Int.max) < 90 * 60 }
        mutateIfUnearned("streak_30")        { longest >= 30 }
        mutateIfUnearned("count_50")         { successCount >= 50 }

        save()

        let snapshotMap = Dictionary(uniqueKeysWithValues: snapshot.map { ($0.id, $0.isEarned) })
        return badges.filter { $0.isEarned && snapshotMap[$0.id] == false }
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

    /// 최장 연속 성공 스트릭
    private func longestStreak(records: [DailyRecord]) -> Int {
        let cal = Calendar.current
        let dates = records
            .filter { $0.isSuccess }
            .compactMap { $0.date.toDate() }
            .map { cal.startOfDay(for: $0) }
            .sorted()
        guard !dates.isEmpty else { return 0 }
        var longest = 1, current = 1
        for i in 1..<dates.count {
            let diff = cal.dateComponents([.day], from: dates[i-1], to: dates[i]).day ?? 0
            if diff == 1 { current += 1; longest = max(longest, current) }
            else if diff > 1 { current = 1 }
        }
        return longest
    }

    /// 9/9 완료 총 횟수
    private func countSuccesses(records: [DailyRecord]) -> Int {
        records.filter { $0.isSuccess }.count
    }

    /// 9/9 성공 중 가장 빠른 소요 시간(초)
    private func fastestSuccessSeconds(records: [DailyRecord]) -> Int? {
        records.filter { $0.isSuccess && $0.elapsedSeconds > 0 }
               .map { $0.elapsedSeconds }.min()
    }

    /// 뚝딱 항목(index 0,1,2) 누적 완료 개수
    private func countSparkItems(records: [DailyRecord]) -> Int {
        records.reduce(0) { sum, r in
            guard r.itemStatus.count >= 3 else { return sum }
            return sum + [r.itemStatus[0], r.itemStatus[1], r.itemStatus[2]].filter { $0 }.count
        }
    }

    /// 착착 항목(index 3,4,5) 누적 완료 개수
    private func countFlowItems(records: [DailyRecord]) -> Int {
        records.reduce(0) { sum, r in
            guard r.itemStatus.count >= 6 else { return sum }
            return sum + [r.itemStatus[3], r.itemStatus[4], r.itemStatus[5]].filter { $0 }.count
        }
    }

    /// 몰입 항목(index 6,7,8) 누적 완료 개수
    private func countDeepItems(records: [DailyRecord]) -> Int {
        records.reduce(0) { sum, r in
            guard r.itemStatus.count >= 9 else { return sum }
            return sum + [r.itemStatus[6], r.itemStatus[7], r.itemStatus[8]].filter { $0 }.count
        }
    }
}
