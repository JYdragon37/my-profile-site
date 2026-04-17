import Foundation

// MARK: - WeatherCacheManager
// UserDefaults에 WeatherData를 JSON으로 캐싱
final class WeatherCacheManager {
    private let key = "cached_weather_data_99"

    func save(_ data: WeatherData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        UserDefaults.standard.set(encoded, forKey: key)
    }

    func load() -> WeatherData? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WeatherData.self, from: data)
    }
}
