import Foundation

// MARK: - HabitPause Model

struct HabitPause: Codable, Identifiable {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var reason: String?    // optional note

    var daysCount: Int {
        (Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1
    }

    func covers(date: Date) -> Bool {
        let cal = Calendar.current
        let d = cal.startOfDay(for: date)
        return d >= cal.startOfDay(for: startDate) && d <= cal.startOfDay(for: endDate)
    }
}

// MARK: - HabitPauseService

class HabitPauseService {
    static let shared = HabitPauseService()
    private let key = "habit_pauses"

    private init() {}

    func loadPauses() -> [HabitPause] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let pauses = try? JSONDecoder().decode([HabitPause].self, from: data) else {
            return []
        }
        return pauses
    }

    func savePauses(_ pauses: [HabitPause]) {
        if let data = try? JSONEncoder().encode(pauses) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func addPause(_ pause: HabitPause) {
        var pauses = loadPauses()
        pauses.append(pause)
        savePauses(pauses)
    }

    func removePause(id: UUID) {
        var pauses = loadPauses()
        pauses.removeAll { $0.id == id }
        savePauses(pauses)
    }

    func isPaused(date: Date) -> Bool {
        loadPauses().contains { $0.covers(date: date) }
    }

    /// Returns total paused days within the current calendar month
    func pausedDaysThisMonth() -> Int {
        let calendar = Calendar.current
        let today = Date()
        guard let monthRange = calendar.range(of: .day, in: .month, for: today),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else {
            return 0
        }
        let monthEnd = calendar.date(byAdding: .day, value: monthRange.count - 1, to: monthStart) ?? monthStart

        var count = 0
        var cursor = monthStart
        while cursor <= monthEnd {
            if isPaused(date: cursor) { count += 1 }
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor.addingTimeInterval(86400)
        }
        return count
    }

    /// Returns the pause that covers today, if any
    func activePause() -> HabitPause? {
        let today = Date()
        return loadPauses().first { $0.covers(date: today) }
    }
}
