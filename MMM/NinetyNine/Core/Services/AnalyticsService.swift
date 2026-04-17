import Foundation
import FirebaseAnalytics

// MARK: - Analytics 이벤트 정의
enum AnalyticsEvent {
    case onboardingCompleted
    case alarmSetDuringOnboarding
    case onboardingAlarmSkipped
    case challengeStarted
    case challengeCompleted(elapsedMinutes: Int, streak: Int)
    case challengeFailed(completedCount: Int, reason: String)
    case alarmDismissed
    case alarmSnoozed(count: Int)
    case streakAchieved(days: Int)
    case routineEdited
    case routineVersionCreated
    case appOpenedFromAlarm

    var name: String {
        switch self {
        case .onboardingCompleted:          return "onboarding_completed"
        case .alarmSetDuringOnboarding:     return "alarm_set_during_onboarding"
        case .onboardingAlarmSkipped:       return "onboarding_alarm_skipped"
        case .challengeStarted:             return "challenge_started"
        case .challengeCompleted:           return "challenge_completed"
        case .challengeFailed:              return "challenge_failed"
        case .alarmDismissed:               return "alarm_dismissed"
        case .alarmSnoozed:                 return "alarm_snoozed"
        case .streakAchieved:               return "streak_achieved"
        case .routineEdited:                return "routine_edited"
        case .routineVersionCreated:        return "routine_version_created"
        case .appOpenedFromAlarm:           return "app_opened_from_alarm"
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .challengeCompleted(let minutes, let streak):
            return ["elapsed_minutes": minutes, "streak": streak]
        case .challengeFailed(let count, let reason):
            return ["completed_count": count, "reason": reason]
        case .alarmSnoozed(let count):
            return ["snooze_count": count]
        case .streakAchieved(let days):
            return ["streak_days": days]
        default:
            return nil
        }
    }
}

// MARK: - AnalyticsService
final class AnalyticsService {

    static let shared = AnalyticsService()
    private init() {}

    func log(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }

    // 스트릭 마일스톤 자동 감지
    func checkStreakMilestone(streak: Int) {
        if Config.streakMilestoneDays.contains(streak) {
            log(.streakAchieved(days: streak))
        }
    }
}
