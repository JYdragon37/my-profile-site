import Foundation
import SwiftData

@MainActor
final class AlarmViewModel: ObservableObject {

    @Published var alarms: [AlarmConfig] = []
    @Published var isShowingEdit: Bool = false
    @Published var editingAlarm: AlarmConfig?
    @Published var errorMessage: String?

    private let alarmService = AlarmService.shared
    private var modelContext: ModelContext?

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadAlarms()
    }

    // MARK: - 알람 목록 로드
    func loadAlarms() {
        guard let context = modelContext else { return }
        let locals = (try? context.fetch(FetchDescriptor<LocalAlarmConfig>())) ?? []
        alarms = locals.map { $0.toAlarmConfig() }
            .sorted { $0.hour * 60 + $0.minute < $1.hour * 60 + $1.minute }
    }

    // MARK: - 알람 저장
    func saveAlarm(_ config: AlarmConfig) {
        guard let context = modelContext else { return }

        // SwiftData 저장
        do {
            if let existing = try context.fetch(
                FetchDescriptor<LocalAlarmConfig>(predicate: #Predicate { $0.id == config.id })
            ).first {
                // 기존 객체 in-place 업데이트 (delete+insert 대신)
                existing.label = config.label
                existing.hour = config.hour
                existing.minute = config.minute
                existing.repeatDaysJSON = (try? JSONEncoder().encode(config.repeatDays)) ?? Data()
                existing.soundName = config.soundName
                existing.volume = config.volume
                existing.fadeIn = config.fadeIn
                existing.vibration = config.vibration
                existing.snoozeEnabled = config.snoozeEnabled
                existing.snoozeDurationMinutes = config.snoozeDurationMinutes
                existing.snoozeMaxCount = config.snoozeMaxCount
                existing.challengeAutoStart = config.challengeAutoStart
                existing.isEnabled = config.isEnabled
            } else {
                context.insert(LocalAlarmConfig(from: config))
            }
            try context.save()
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        // 알람 서비스에 등록
        alarmService.scheduleAlarm(config)
        loadAlarms()
    }

    // MARK: - 알람 삭제
    func deleteAlarm(_ config: AlarmConfig) {
        guard let context = modelContext else { return }
        if let local = try? context.fetch(
            FetchDescriptor<LocalAlarmConfig>(predicate: #Predicate { $0.id == config.id })
        ).first {
            context.delete(local)
            try? context.save()
        }
        alarmService.cancelAlarm(id: config.id)
        loadAlarms()
    }

    // MARK: - 알람 ON/OFF 토글
    // saveAlarm이 내부적으로 scheduleAlarm을 호출하므로 여기서는 중복 호출 없이 저장만 수행
    func toggleAlarm(_ config: AlarmConfig) {
        var updated = config
        updated.isEnabled.toggle()
        saveAlarm(updated)
        // 비활성화 시 UNUserNotificationCenter에서 제거 (saveAlarm은 scheduleAlarm만 호출하므로)
        if !updated.isEnabled {
            alarmService.cancelAlarm(id: updated.id)
        }
    }

    // MARK: - 편집 화면 열기
    func openEdit(alarm: AlarmConfig? = nil) {
        editingAlarm = alarm ?? AlarmConfig.defaultWeekday()
        isShowingEdit = true
    }
}
