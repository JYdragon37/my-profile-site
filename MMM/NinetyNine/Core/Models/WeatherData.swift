import Foundation

// MARK: - WeatherData (홈 화면 전용 간소화 버전)
struct WeatherData: Codable, Equatable {
    let temperature: Int        // 현재 기온 (°C)
    let conditionKo: String     // "맑음" | "흐림" | "비" | "눈"
    let dustGrade: String       // "좋음" | "보통" | "나쁨" | "매우나쁨"
    let cityName: String
    let cachedAt: Date

    /// 30분 유효
    var isValid: Bool {
        Date().timeIntervalSince(cachedAt) < 1800
    }

    static let placeholder = WeatherData(
        temperature: 20,
        conditionKo: "맑음",
        dustGrade: "좋음",
        cityName: "서울",
        cachedAt: Date()
    )
}
