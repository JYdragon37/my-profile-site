import Foundation

struct WidgetData: Codable {
    var completedCount: Int        // 0~9
    var totalCount: Int            // always 9
    var streak: Int
    var isSuccess: Bool
    var nextItems: [String]        // first 3 incomplete item titles
    var updatedAt: Date

    static let empty = WidgetData(completedCount: 0, totalCount: 9, streak: 0, isSuccess: false, nextItems: [], updatedAt: Date())

    static func load() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: "group.com.ninetynine.shared") else {
            #if DEBUG
            assertionFailure("App Group UserDefaults unavailable")
            #endif
            return .empty
        }
        guard let data = defaults.data(forKey: "widget_data"),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return .empty
        }
        return decoded
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: "group.com.ninetynine.shared") else {
            #if DEBUG
            assertionFailure("App Group UserDefaults unavailable")
            #endif
            return
        }
        defaults.set(try? JSONEncoder().encode(self), forKey: "widget_data")
    }
}
