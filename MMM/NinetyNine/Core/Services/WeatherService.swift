import Foundation
import WeatherKit
import CoreLocation

// MARK: - WeatherService
// WeatherKit 우선 → OpenWeatherMap 폴백 → 캐시 폴백 → placeholder
// 절대 throw하지 않음 (앱 크래시 방지)
final class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = WeatherService()

    @Published var weather: WeatherData = .placeholder

    private let locationManager = CLLocationManager()
    private let cacheManager = WeatherCacheManager()
    private var isFetching = false

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: - 외부 진입점
    func requestAndFetch() {
        // 캐시가 유효하면 바로 반환
        if let cached = cacheManager.load(), cached.isValid {
            weather = cached
            return
        }
        // 위치 권한에 따라 분기
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            // 권한 없으면 캐시 또는 placeholder
            weather = cacheManager.load() ?? .placeholder
        }
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, !isFetching else { return }
        isFetching = true
        Task {
            let result = await fetchWeather(for: location)
            await MainActor.run {
                self.weather = result
                self.isFetching = false
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 위치 실패 → 캐시 또는 placeholder
        weather = cacheManager.load() ?? .placeholder
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            weather = cacheManager.load() ?? .placeholder
        }
    }

    // MARK: - 날씨 Fetch (WeatherKit → OWM → 캐시 → placeholder)
    private func fetchWeather(for location: CLLocation) async -> WeatherData {
        // 1. WeatherKit 시도
        if let data = await fetchFromWeatherKit(location: location) {
            cacheManager.save(data)
            return data
        }
        // 2. OpenWeatherMap 폴백
        if let data = await fetchFromOpenWeatherMap(location: location) {
            cacheManager.save(data)
            return data
        }
        // 3. 구 캐시 반환
        if let stale = cacheManager.load() { return stale }
        // 4. placeholder
        return .placeholder
    }

    // MARK: - WeatherKit
    private func fetchFromWeatherKit(location: CLLocation) async -> WeatherData? {
        do {
            let weatherKitService = WeatherKit.WeatherService.shared
            let result = try await weatherKitService.weather(for: location)
            let current = result.currentWeather

            let conditionKo = mapConditionKo(current.condition)
            // 단일 reverse geocode 호출로 cityName과 sido를 동시에 해석
            let (cityName, sido) = await reverseGeocodeOnce(location)
            let dustGrade = await fetchDustGrade(location: location, sido: sido)

            return WeatherData(
                temperature: Int(current.temperature.converted(to: .celsius).value.rounded()),
                conditionKo: conditionKo,
                dustGrade: dustGrade,
                cityName: cityName,
                cachedAt: Date()
            )
        } catch {
            return nil
        }
    }

    // MARK: - OpenWeatherMap 폴백
    private func fetchFromOpenWeatherMap(location: CLLocation) async -> WeatherData? {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let apiKey = Bundle.main.infoDictionary?["OPENWEATHER_API_KEY"] as? String ?? ""
        guard !apiKey.isEmpty,
              let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric")
        else { return nil }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let response = try? JSONDecoder().decode(OWMCurrentResponse.self, from: data)
        else { return nil }

        let weatherId = response.weather.first?.id ?? 800
        let conditionKo = mapOWMIdKo(weatherId)
        // 단일 reverse geocode 호출로 cityName과 sido를 동시에 해석 (WeatherKit 경로와 동일)
        let (cityName, sido) = await reverseGeocodeOnce(location)
        let dustGrade = await fetchDustGrade(location: location, sido: sido)

        return WeatherData(
            temperature: Int(response.main.temp.rounded()),
            conditionKo: conditionKo,
            dustGrade: dustGrade,
            cityName: cityName,
            cachedAt: Date()
        )
    }

    // MARK: - 대기질 (에어코리아 우선 → OWM 폴백)
    private func fetchDustGrade(location: CLLocation, sido: String? = nil) async -> String {
        // 에어코리아 시도
        if let grade = await fetchAirKoreaGrade(location: location, sido: sido) { return grade }
        // OWM AQI 폴백
        if let grade = await fetchOWMAQIGrade(location: location) { return grade }
        return "보통"
    }

    private func fetchAirKoreaGrade(location: CLLocation, sido preResolved: String? = nil) async -> String? {
        let apiKey = Bundle.main.infoDictionary?["AIRKOREA_API_KEY"] as? String ?? ""
        guard !apiKey.isEmpty else { return nil }

        let sido = preResolved ?? "서울"
        let encodedSido = sido.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? sido
        let urlStr = "https://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty"
            + "?sidoName=\(encodedSido)&pageNo=1&numOfRows=10&returnType=json"
            + "&serviceKey=\(apiKey)&ver=1.0"
        guard let url = URL(string: urlStr),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let response = try? JSONDecoder().decode(AirKoreaResponse.self, from: data),
              let item = response.response.body.items.first(where: { $0.khaiGrade != nil && $0.khaiGrade != "-" })
        else { return nil }

        switch item.khaiGrade {
        case "1": return "좋음"
        case "2": return "보통"
        case "3": return "나쁨"
        case "4": return "매우나쁨"
        default: return "보통"
        }
    }

    private func fetchOWMAQIGrade(location: CLLocation) async -> String? {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let apiKey = Bundle.main.infoDictionary?["OPENWEATHER_API_KEY"] as? String ?? ""
        guard !apiKey.isEmpty,
              let url = URL(string: "https://api.openweathermap.org/data/2.5/air_pollution?lat=\(lat)&lon=\(lon)&appid=\(apiKey)"),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let response = try? JSONDecoder().decode(OWMAirPollutionResponse.self, from: data),
              let item = response.list.first
        else { return nil }

        if let pm25 = item.components?.pm2_5 {
            switch pm25 {
            case ..<15:  return "좋음"
            case ..<35:  return "보통"
            case ..<75:  return "나쁨"
            default:     return "매우나쁨"
            }
        }
        switch item.main.aqi {
        case 1: return "좋음"
        case 2: return "보통"
        case 3: return "나쁨"
        default: return "매우나쁨"
        }
    }

    // MARK: - Helpers

    /// 단일 CLGeocoder 호출로 cityName과 sido를 동시에 반환 (WeatherKit 경로의 이중 geocode 제거용)
    private func reverseGeocodeOnce(_ location: CLLocation) async -> (cityName: String, sido: String) {
        await withCheckedContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
                let placemark = placemarks?.first
                let cityName: String = {
                    let parts = [placemark?.locality, placemark?.subLocality]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    return parts.isEmpty ? "현재 위치" : parts
                }()
                let admin = placemark?.administrativeArea ?? ""
                let sidoMap: [String: String] = [
                    "Seoul": "서울", "서울특별시": "서울", "서울": "서울",
                    "Busan": "부산", "부산광역시": "부산",
                    "Daegu": "대구", "대구광역시": "대구",
                    "Incheon": "인천", "인천광역시": "인천",
                    "Gwangju": "광주", "광주광역시": "광주",
                    "Daejeon": "대전", "대전광역시": "대전",
                    "Ulsan": "울산", "울산광역시": "울산",
                    "Gyeonggi-do": "경기", "경기도": "경기",
                    "Gangwon-do": "강원", "강원도": "강원",
                    "Chungcheongbuk-do": "충북", "충청북도": "충북",
                    "Chungcheongnam-do": "충남", "충청남도": "충남",
                    "Jeollabuk-do": "전북", "전라북도": "전북",
                    "Jeollanam-do": "전남", "전라남도": "전남",
                    "Gyeongsangbuk-do": "경북", "경상북도": "경북",
                    "Gyeongsangnam-do": "경남", "경상남도": "경남",
                    "Jeju-do": "제주", "제주특별자치도": "제주",
                    "Sejong": "세종", "세종특별자치시": "세종",
                ]
                let sido = sidoMap[admin] ?? "서울"
                continuation.resume(returning: (cityName, sido))
            }
        }
    }

    // MARK: - Condition Mapping

    private func mapConditionKo(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear, .mostlyClear, .partlyCloudy: return "맑음"
        case .cloudy, .mostlyCloudy:              return "흐림"
        case .rain, .heavyRain, .drizzle, .freezingRain, .freezingDrizzle: return "비"
        case .snow, .heavySnow, .blowingSnow, .sleet, .wintryMix:          return "눈"
        default: return "흐림"
        }
    }

    private func mapOWMIdKo(_ id: Int) -> String {
        switch id {
        case 200...232: return "뇌우"
        case 300...321: return "이슬비"
        case 500...531: return "비"
        case 600...622: return "눈"
        case 700...799: return "안개"
        case 800:       return "맑음"
        case 801:       return "구름 조금"
        case 802...804: return "흐림"
        default:        return "흐림"
        }
    }
}

// MARK: - Response Models (private)

private struct OWMCurrentResponse: Codable {
    let main: OWMMain
    let weather: [OWMWeather]
    let name: String
    struct OWMMain: Codable { let temp: Double }
    struct OWMWeather: Codable { let id: Int }
}

private struct OWMAirPollutionResponse: Codable {
    let list: [AirItem]
    struct AirItem: Codable {
        let main: AirMain
        let components: AirComponents?
    }
    struct AirMain: Codable { let aqi: Int }
    struct AirComponents: Codable { let pm2_5: Double? }
}

private struct AirKoreaResponse: Codable {
    let response: AKBody
    struct AKBody: Codable { let body: AKItems }
    struct AKItems: Codable { let items: [AKItem] }
    struct AKItem: Codable {
        let khaiGrade: String?
    }
}
