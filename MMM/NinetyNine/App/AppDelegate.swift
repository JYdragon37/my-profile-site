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
        let soundName = userInfo["soundName"] as? String ?? "default"
        let volume = userInfo["volume"] as? Float ?? 0.8
        let fadeIn = userInfo["fadeIn"] as? Bool ?? false

        // 앱 포그라운드 상태에서는 시스템 알림 소리가 재생되지 않으므로 명시적으로 재생
        AlarmService.shared.playAlarmSound(named: soundName, volume: volume, fadeIn: fadeIn)
        completionHandler([.banner, .badge])
    }

    // MARK: - 알람 해제 처리 (사용자가 알람 탭/해제)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let alarmID = response.notification.request.identifier
        let challengeAutoStart = userInfo["challengeAutoStart"] as? Bool ?? false

        switch response.actionIdentifier {
        case "SNOOZE":
            // 스누즈: userInfo에 저장된 snoozeDurationMinutes 후 1회성 알람 재예약
            let snoozeMins = userInfo["snoozeDurationMinutes"] as? Int ?? 5
            let snoozeDate = Date().addingTimeInterval(Double(snoozeMins) * 60)
            let snoozeComponents = Calendar.current.dateComponents([.hour, .minute], from: snoozeDate)
            let content = UNMutableNotificationContent()
            content.title = userInfo["alarmLabel"] as? String ?? "알람"
            content.body = "스누즈 알람이에요. 오늘의 99분 챌린지를 시작할 시간이에요 💪"
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            content.userInfo = userInfo
            let trigger = UNCalendarNotificationTrigger(dateMatching: snoozeComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(alarmID)-snooze",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        default:
            // 알람 해제 → 챌린지 자동 시작 여부 결정
            AlarmService.shared.handleDismissed(
                alarmID: alarmID,
                challengeAutoStart: challengeAutoStart
            )

            // AlarmFullscreenView 표시를 위한 노티피케이션
            NotificationCenter.default.post(
                name: .alarmDismissed,
                object: nil,
                userInfo: [
                    "alarmID": alarmID,
                    "challengeAutoStart": challengeAutoStart
                ]
            )
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
