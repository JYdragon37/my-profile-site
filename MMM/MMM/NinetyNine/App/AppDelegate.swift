import UIKit
import FirebaseCore
import UserNotifications
import AVFoundation

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // MARK: Firebase 초기화
        // GoogleService-Info.plist가 프로젝트에 추가되어야 합니다.
        FirebaseApp.configure()

        // MARK: 알람 권한 + 델리게이트 설정
        UNUserNotificationCenter.current().delegate = self
        setupAudioSession()

        return true
    }

    // MARK: - 오디오 세션 (알람음 재생 — 무음 모드 관통)
    private func setupAudioSession() {
        do {
            // .mixWithOthers 제거: 알람 재생 시 다른 오디오를 덮어써야 함
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession 설정 실패: \(error)")
        }
    }

    // MARK: - 포그라운드 알람 처리 (앱이 열린 상태에서 알람 수신)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        let alarmID  = notification.request.identifier
        let challengeAutoStart = userInfo["challengeAutoStart"] as? Bool ?? false
        let soundName = userInfo["soundName"] as? String ?? "default"
        let volume    = userInfo["volume"] as? Float ?? 0.8
        let fadeIn    = userInfo["fadeIn"] as? Bool ?? false

        // 소리 재생 (포그라운드에서 시스템 사운드 미재생)
        AlarmService.shared.playAlarmSound(named: soundName, volume: volume, fadeIn: fadeIn)

        // 전체화면 뷰 즉시 표시 — 배너 대신 AlarmFullscreenView가 담당
        DispatchQueue.main.async {
            AlarmService.shared.pendingAlarm = AlarmService.PendingAlarm(
                id: alarmID, challengeAutoStart: challengeAutoStart
            )
        }
        completionHandler([.badge])  // 배너 표시 안 함 — fullscreen이 담당
    }

    // MARK: - 백그라운드/잠금화면 알람 배너 탭 처리
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo           = response.notification.request.content.userInfo
        let alarmID            = response.notification.request.identifier
        let challengeAutoStart = userInfo["challengeAutoStart"] as? Bool ?? false

        switch response.actionIdentifier {
        case "SNOOZE":
            let snoozeMins      = userInfo["snoozeDurationMinutes"] as? Int ?? 5
            let snoozeDate      = Date().addingTimeInterval(Double(snoozeMins) * 60)
            let snoozeComps     = Calendar.current.dateComponents([.hour, .minute], from: snoozeDate)
            let snoozeContent   = UNMutableNotificationContent()
            snoozeContent.title = userInfo["alarmLabel"] as? String ?? "알람"
            snoozeContent.body  = "스누즈 알람이에요. 오늘의 99분 챌린지를 시작할 시간이에요 💪"
            snoozeContent.sound = .default
            snoozeContent.interruptionLevel = .timeSensitive
            snoozeContent.userInfo = userInfo
            let snoozeTrigger   = UNCalendarNotificationTrigger(dateMatching: snoozeComps, repeats: false)
            UNUserNotificationCenter.current().add(
                UNNotificationRequest(identifier: "\(alarmID)-snooze",
                                      content: snoozeContent, trigger: snoozeTrigger)
            )

        default:
            // @Published 사용 — NotificationCenter.post 대신
            // 앱 콜드스타트 시 ContentView 구독 전 post 소실 문제 방지
            DispatchQueue.main.async {
                AlarmService.shared.pendingAlarm = AlarmService.PendingAlarm(
                    id: alarmID, challengeAutoStart: challengeAutoStart
                )
            }
        }

        completionHandler()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let alarmDismissed      = Notification.Name("alarmDismissed")
    static let challengeShouldStart = Notification.Name("challengeShouldStart")
    static let alarmLimitExceeded  = Notification.Name("alarmLimitExceeded")
}
