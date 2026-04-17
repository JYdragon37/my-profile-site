import Foundation

final class MotivationService: ObservableObject {

    static let shared = MotivationService()

    // init에서 캐시를 동기 로드 → 첫 렌더 시 즉시 이미지 표시 (3초 버퍼 제거)
    private init() {
        // 구버전 UserDefaults 캐시 키 일괄 제거 (현재는 FileManager Caches 사용)
        let legacyKeys = [
            "motivation_images_cache",
            "motivation_quotes_cache",
            "motivation_greetings_cache",
        ]
        let defaults = UserDefaults.standard
        for key in legacyKeys where defaults.object(forKey: key) != nil {
            defaults.removeObject(forKey: key)
        }

        if let imgs = loadImagesCache(),
           let qts  = loadQuotesCache(),
           let grs  = loadGreetingsCache(),
           !imgs.isEmpty {
            images    = imgs
            quotes    = qts
            greetings = grs
            refreshCurrentContent()
        }
    }

    @Published var images:    [MotivationImage]   = []
    @Published var quotes:    [MotivationQuote]   = []
    @Published var greetings: [MotivationGreeting] = []

    private let imgCacheKey  = "motivation_images_cache"
    private let qtCacheKey   = "motivation_quotes_cache"
    private let grCacheKey   = "motivation_greetings_cache"
    private let cacheTimeKey = "motivation_cache_time"

    // 고정 로직용 키
    private let lockedImageIDKey  = "motivation_locked_image_id"
    private let imageLockZoneKey  = "motivation_image_lock_zone"
    private let lockedQuoteIDKey  = "motivation_locked_quote_id"
    private let quoteLockExpiryKey = "motivation_quote_lock_expiry"  // 다음 4AM

    // MARK: - 현재 콘텐츠 (1회 선택 후 고정 — 매 렌더마다 randomElement 방지)
    @Published private(set) var current: MotivationContent = MotivationContent(
        image: MotivationImage.defaults[0],
        quote: MotivationQuote.defaults[0],
        greeting: MotivationGreeting.defaults[0]
    )

    /// 콘텐츠 갱신:
    /// - 배경: 현재 zone이 바뀔 때만 교체 (3시간마다 1회)
    /// - 글귀: 하루 고정, 매일 오전 4시 리셋
    /// - 인사말: zone 기반 (매 갱신마다 zone에 맞게 선택)
    func refreshCurrentContent() {
        let zone = currentZone()
        let img = resolveLockedImage(zone: zone)
        let qt  = resolveLockedQuote()
        let gr  = greetings.filter { $0.zone == zone }.randomElement()
               ?? greetings.randomElement()
               ?? MotivationGreeting.defaults.first { $0.zone == zone }
               ?? MotivationGreeting.defaults[0]
        current = MotivationContent(image: img, quote: qt, greeting: gr)
    }

    // MARK: - 배경 고정 (zone 변경 시에만 교체)
    private func resolveLockedImage(zone: String) -> MotivationImage {
        let lockedZone = UserDefaults.standard.string(forKey: imageLockZoneKey)
        let lockedID   = UserDefaults.standard.string(forKey: lockedImageIDKey)

        if lockedZone == zone,
           let lid = lockedID,
           let img = images.first(where: { $0.id == lid }) {
            return img
        }

        // zone 변경 → 새 이미지 선택 후 고정
        let img = images.filter { $0.zone == zone }.randomElement()
               ?? images.randomElement()
               ?? MotivationImage.defaults.first { $0.zone == zone }
               ?? MotivationImage.defaults[0]
        UserDefaults.standard.set(zone, forKey: imageLockZoneKey)
        UserDefaults.standard.set(img.id, forKey: lockedImageIDKey)
        return img
    }

    // MARK: - 글귀 고정 (매일 오전 4시 리셋)
    private func resolveLockedQuote() -> MotivationQuote {
        let expiry   = UserDefaults.standard.object(forKey: quoteLockExpiryKey) as? Date
        let lockedID = UserDefaults.standard.string(forKey: lockedQuoteIDKey)

        if let exp = expiry,
           Date() < exp,
           let lid = lockedID,
           let qt = quotes.first(where: { $0.id == lid }) {
            return qt
        }

        // 만료(또는 최초) → 새 글귀 선택 후 다음 4AM까지 고정
        let qt = quotes.randomElement()
               ?? MotivationQuote.defaults[0]
        UserDefaults.standard.set(qt.id,          forKey: lockedQuoteIDKey)
        UserDefaults.standard.set(nextFourAMDate(), forKey: quoteLockExpiryKey)
        return qt
    }

    // MARK: - 다음 오전 4시 계산
    private func nextFourAMDate() -> Date {
        let cal  = Calendar.current
        let now  = Date()
        var comps = cal.dateComponents([.year, .month, .day], from: now)
        comps.hour = 4; comps.minute = 0; comps.second = 0
        let todayFourAM = cal.date(from: comps)!
        // 이미 4시 이후라면 내일 4시
        return now >= todayFourAM
            ? cal.date(byAdding: .day, value: 1, to: todayFourAM)!
            : todayFourAM
    }

    // MARK: - 앱 시작 시 fetch + 캐시
    func fetchIfNeeded() async {
        if let lastFetch = UserDefaults.standard.object(forKey: cacheTimeKey) as? Date,
           Date().timeIntervalSince(lastFetch) < Config.motivationFetchIntervalHours * 3600,
           let cachedImgs = loadImagesCache(),
           let cachedQts  = loadQuotesCache(),
           let cachedGrs  = loadGreetingsCache() {
            await MainActor.run {
                self.images    = cachedImgs
                self.quotes    = cachedQts
                self.greetings = cachedGrs
                self.refreshCurrentContent()
            }
            return
        }
        await fetchFromSheets()
    }

    // MARK: - 세 탭 병렬 fetch
    private func fetchFromSheets() async {
        async let imgFetch = fetchCSV(gid: 0)           // images 탭
        async let qtFetch  = fetchCSV(gid: 2048045779)  // quotes 탭
        async let grFetch  = fetchCSV(gid: 1916171287)  // greetings 탭

        let (imgCSV, qtCSV, grCSV) = await (imgFetch, qtFetch, grFetch)

        let parsedImgs: [MotivationImage]    = imgCSV.flatMap(parseImages)    ?? []
        let parsedQts:  [MotivationQuote]    = qtCSV.flatMap(parseQuotes)     ?? []
        let parsedGrs:  [MotivationGreeting] = grCSV.flatMap(parseGreetings)  ?? []

        let imgs: [MotivationImage]   = parsedImgs.isEmpty ? MotivationImage.defaults   : parsedImgs
        let qts:  [MotivationQuote]   = parsedQts.isEmpty  ? MotivationQuote.defaults   : parsedQts
        let grs:  [MotivationGreeting] = parsedGrs.isEmpty ? MotivationGreeting.defaults : parsedGrs

        saveImagesCache(imgs)
        saveQuotesCache(qts)
        saveGreetingsCache(grs)
        UserDefaults.standard.set(Date(), forKey: cacheTimeKey)

        await MainActor.run {
            self.images    = imgs
            self.quotes    = qts
            self.greetings = grs
            self.refreshCurrentContent()
        }

        Task { await preloadImages(imgs) }
    }

    // MARK: - CSV fetch
    private func fetchCSV(gid: Int) async -> String? {
        let urlStr = "https://docs.google.com/spreadsheets/d/\(Config.googleSheetID)/export?format=csv&gid=\(gid)"
        guard let url = URL(string: urlStr),
              let data = try? await URLSession.shared.data(from: url).0
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - CSV 파싱
    // images 탭 헤더: id, storage_path, zone
    private func parseImages(_ csv: String) -> [MotivationImage] {
        var lines = csv.components(separatedBy: "\n")
        guard lines.count > 1 else { return [] }
        lines.removeFirst()
        return lines.compactMap { line -> MotivationImage? in
            let cols = line.components(separatedBy: ",")
                          .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard cols.count >= 3, !cols[0].isEmpty else { return nil }
            return MotivationImage(id: cols[0], storagePath: cols[1], zone: cols[2])
        }
    }

    // quotes 탭 헤더: id, quote, author, zone
    private func parseQuotes(_ csv: String) -> [MotivationQuote] {
        var lines = csv.components(separatedBy: "\n")
        guard lines.count > 1 else { return [] }
        lines.removeFirst()
        return lines.compactMap { line -> MotivationQuote? in
            let cols = line.components(separatedBy: ",")
                          .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard cols.count >= 4, !cols[0].isEmpty else { return nil }
            return MotivationQuote(id: cols[0], quote: cols[1], author: cols[2], zone: cols[3])
        }
    }

    // greetings 탭 헤더: id, greeting, zone
    private func parseGreetings(_ csv: String) -> [MotivationGreeting] {
        var lines = csv.components(separatedBy: "\n")
        guard lines.count > 1 else { return [] }
        lines.removeFirst()
        return lines.compactMap { line -> MotivationGreeting? in
            let cols = line.components(separatedBy: ",")
                          .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard cols.count >= 3, !cols[0].isEmpty else { return nil }
            return MotivationGreeting(id: cols[0], greeting: cols[1], zone: cols[2])
        }
    }

    // MARK: - 이미지 프리로드
    private func preloadImages(_ images: [MotivationImage]) async {
        let urls = images.compactMap { MotivationService.storageURL(for: $0.storagePath) }
        for url in urls.prefix(3) {
            _ = try? await URLSession.shared.data(from: url)
        }
    }

    // MARK: - 캐시 (FileManager Caches — UserDefaults 대신 사용해 plist 비대화 방지)
    private var cacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    private func cacheURL(for key: String) -> URL {
        cacheDirectory.appendingPathComponent("\(key).json")
    }

    private func saveImagesCache(_ items: [MotivationImage]) {
        try? JSONEncoder().encode(items).write(to: cacheURL(for: imgCacheKey))
    }
    private func saveQuotesCache(_ items: [MotivationQuote]) {
        try? JSONEncoder().encode(items).write(to: cacheURL(for: qtCacheKey))
    }
    private func saveGreetingsCache(_ items: [MotivationGreeting]) {
        try? JSONEncoder().encode(items).write(to: cacheURL(for: grCacheKey))
    }
    private func loadImagesCache() -> [MotivationImage]? {
        guard let d = try? Data(contentsOf: cacheURL(for: imgCacheKey)) else { return nil }
        return try? JSONDecoder().decode([MotivationImage].self, from: d)
    }
    private func loadQuotesCache() -> [MotivationQuote]? {
        guard let d = try? Data(contentsOf: cacheURL(for: qtCacheKey)) else { return nil }
        return try? JSONDecoder().decode([MotivationQuote].self, from: d)
    }
    private func loadGreetingsCache() -> [MotivationGreeting]? {
        guard let d = try? Data(contentsOf: cacheURL(for: grCacheKey)) else { return nil }
        return try? JSONDecoder().decode([MotivationGreeting].self, from: d)
    }

    // MARK: - 현재 zone 계산 (8 Zone 시스템)
    private func currentZone() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<3:   return "deep_dark"
        case 3..<6:   return "first_light"
        case 6..<9:   return "rise_ignite"
        case 9..<12:  return "peak_mode"
        case 12..<15: return "recharge"
        case 15..<18: return "second_wind"
        case 18..<21: return "golden_hour"
        default:      return "wind_down"
        }
    }

    // MARK: - Firebase Storage URL 변환
    static func storageURL(for path: String) -> URL? {
        guard !path.isEmpty else { return nil }
        // Firebase Storage REST API: / 는 %2F 로 인코딩 필요
        var cs = CharacterSet.urlPathAllowed
        cs.remove("/")
        let encoded = path.addingPercentEncoding(withAllowedCharacters: cs) ?? path
        let urlString = "https://firebasestorage.googleapis.com/v0/b/\(Config.firebaseStorageBucket)/o/\(encoded)?alt=media"
        return URL(string: urlString)
    }
}
