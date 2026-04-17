import Foundation
import UserNotifications
import AVFoundation
import SwiftData

final class AlarmService: NSObject, ObservableObject {

    static let shared = AlarmService()
    private override init() { super.init() }

    private var audioPlayer: AVAudioPlayer?
    @Published var activeAlarmID: String?

    /// NotificationCenter.post 대신 @Published 사용 — 앱 백그라운드 복귀 시 타이밍 경쟁 없이 ContentView에 안전하게 전달
    @Published var pendingAlarm: PendingAlarm?
    @Published var shouldGoHome: Bool = false   // 챌린지 완료 상태 알람 해제 시 홈으로

    struct PendingAlarm: Identifiable, Equatable {
        var id: String           // alarmID — Identifiable 준수
        let challengeAutoStart: Bool
    }

    /// Serial queue used to serialize the limit-check + schedule pair atomically.
    private let scheduleQueue = DispatchQueue(label: "com.ninetynine.alarmService.schedule")

    // MARK: - 권한 요청
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // iOS 로컬 알람 최대 개수
    private let maxLocalNotifications = 60  // 안전 마진 확보 (iOS 한도 64)

    // MARK: - 알람 예약
    func scheduleAlarm(_ config: AlarmConfig) {
        cancelAlarm(id: config.id)
        guard config.isEnabled, !config.repeatDays.isEmpty else { return }

        // 현재 예약된 알람 수 확인 — serial queue로 check+schedule을 원자적으로 수행
        scheduleQueue.async { [weak self] in
            guard let self else { return }
            let semaphore = DispatchSemaphore(value: 0)
            var pendingCount = 0
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                pendingCount = requests.count
                semaphore.signal()
            }
            semaphore.wait()

            let newCount = config.repeatDays.count
            guard pendingCount + newCount <= self.maxLocalNotifications else {
                NotificationCenter.default.post(name: .alarmLimitExceeded, object: nil)
                return
            }

            for day in config.repeatDays {
                let id = "\(config.id.uuidString)-\(day.rawValue)"
                let content = self.makeNotificationContent(config: config)
                let trigger = self.makeWeeklyTrigger(weekday: day.rawValue, hour: config.hour, minute: config.minute)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("⚠️ 알람 예약 실패 (\(day.shortName)): \(error.localizedDescription)")
                    } else {
                        print("✅ 알람 예약 성공: \(config.label) \(config.hour):\(String(format: "%02d", config.minute)) \(day.shortName)")
                    }
                }
            }
        }
    }

    // 반복 없는 1회성 알람
    func scheduleOnce(_ config: AlarmConfig) {
        let content = makeNotificationContent(config: config)
        var components = DateComponents()
        components.hour = config.hour
        components.minute = config.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: config.id.uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 알람 취소
    func cancelAlarm(id: UUID) {
        let ids = Weekday.allCases.map { "\(id.uuidString)-\($0.rawValue)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids + [id.uuidString])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - 알람 해제 처리 (AlarmFullscreenView dismiss 시 호출)
    func handleDismissed(alarmID: String, challengeAutoStart: Bool) {
        activeAlarmID = nil
        pendingAlarm  = nil   // fullScreenCover 닫기
        stopAlarmSound()
        // 항상 발행 — TodayViewModel이 challengeState + autoStart 조합으로 처리
        NotificationCenter.default.post(
            name: .challengeShouldStart,
            object: nil,
            userInfo: ["challengeAutoStart": challengeAutoStart]
        )
        AnalyticsService.shared.log(.alarmDismissed)
    }

    // MARK: - 알람음 재생 (포그라운드)
    func playAlarmSound(named soundName: String, volume: Float, fadeIn: Bool) {
        let name = soundName == "default" ? "alarm_default" : soundName
        guard let url = Bundle.main.url(forResource: name, withExtension: "caf")
                     ?? Bundle.main.url(forResource: name, withExtension: "wav")
        else { return }

        do {
            // ① 무음 모드 관통: .playback + mixWithOthers 제거
            // ② 이어폰 연결 상태에서도 스피커 강제 출력
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            try session.overrideOutputAudioPort(.speaker)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = fadeIn ? 0.0 : volume
            audioPlayer?.play()

            if fadeIn {
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
                    guard let self, let player = self.audioPlayer else { timer.invalidate(); return }
                    if player.volume < volume {
                        player.volume = min(player.volume + 0.05, volume)
                    } else {
                        timer.invalidate()
                    }
                }
            }
        } catch {
            print("알람음 재생 실패: \(error)")
        }
    }

    func stopAlarmSound() {
        audioPlayer?.stop()
        audioPlayer = nil
        // 다른 오디오(음악 등)가 재개될 수 있도록 세션 비활성화
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Private Helpers
    private func makeNotificationContent(config: AlarmConfig) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = config.label
        content.body = "오늘의 99분 챌린지를 시작할 시간이에요 💪"
        // 커스텀 사운드 파일이 없으면 iOS가 알림 자체를 drop하므로 반드시 폴백 처리
        let hasCafFile = Bundle.main.url(forResource: config.soundName, withExtension: "caf") != nil
        content.sound = (config.soundName == "default" || !hasCafFile)
            ? .default
            : UNNotificationSound(named: UNNotificationSoundName(config.soundName + ".caf"))
        // 집중 모드(방해금지) 관통 — Time-Sensitive 엔타이틀먼트 필요
        content.interruptionLevel = .timeSensitive
        content.userInfo = [
            "alarmID": config.id.uuidString,
            "alarmLabel": config.label,
            "challengeAutoStart": config.challengeAutoStart,
            "soundName": config.soundName,
            "volume": config.volume,
            "fadeIn": config.fadeIn,
            "snoozeDurationMinutes": config.snoozeDurationMinutes
        ]
        if config.snoozeEnabled {
            let snoozeAction = UNNotificationAction(
                identifier: "SNOOZE",
                title: "스누즈 (\(config.snoozeDurationMinutes)분)",
                options: []
            )
            let category = UNNotificationCategory(
                identifier: "ALARM",
                actions: [snoozeAction],
                intentIdentifiers: [],
                options: []
            )
            UNUserNotificationCenter.current().setNotificationCategories([category])
            content.categoryIdentifier = "ALARM"
        }
        return content
    }

    private func makeWeeklyTrigger(weekday: Int, hour: Int, minute: Int) -> UNCalendarNotificationTrigger {
        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = minute
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    }
}
