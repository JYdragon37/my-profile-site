import Foundation
import SwiftData
import Combine

@MainActor
final class TodayViewModel: ObservableObject {

    // MARK: - Challenge State
    enum ChallengeState {
        case beforeStart
        case inProgress
        case completed(elapsedSeconds: Int)
        case failed(completedCount: Int, reason: FailReason)
    }
    enum FailReason { case timeout, manualStop }

    // MARK: - Published
    @Published var state: ChallengeState = .beforeStart {
        didSet { stateID += 1 }
    }
    @Published var stateID: Int = 0
    @Published var routine: [RoutineItem] = []
    @Published var completedItems: Set<Int> = []
    @Published var activeTimerItem: RoutineItem?     // 현재 착착/몰입 타이머 중인 항목
    @Published var isShowingStopConfirm: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var weather: WeatherData = .placeholder
    @Published var milestoneToShow: ItemType?        // 그룹 완료 축하 팝업

    private var pendingFinish = false                // 마일스톤 닫힌 뒤 finishChallenge 예약

    // MARK: - Dependencies
    let challengeTimer = ChallengeTimer()
    private var routineRepository: RoutineRepositoryProtocol?
    var recordRepository: RecordRepositoryProtocol?
    private let analytics = AnalyticsService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup
    func setup(routineRepo: RoutineRepositoryProtocol, recordRepo: RecordRepositoryProtocol) {
        self.routineRepository = routineRepo
        self.recordRepository = recordRepo
        loadTodayRoutine()
        observeTimer()
        observeAlarmDismiss()
        observeWeather()
        // 날씨는 약간 지연 후 요청 (뷰 렌더링 우선)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            WeatherService.shared.requestAndFetch()
        }
    }

    // MARK: - 오늘 루틴 로드 (요일 자동 감지)
    func loadTodayRoutine() {
        Task {
            isLoading = true
            do {
                guard let project = try await routineRepository?.getActiveProject() else {
                    isLoading = false
                    return
                }
                let todayRoutine = project.todayRoutine()
                self.routine = todayRoutine.allItems
            } catch {
                self.errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - 챌린지 시작
    func startChallenge() {
        guard case .beforeStart = state else { return }
        challengeTimer.start()
        state = .inProgress
        analytics.log(.challengeStarted)
    }

    // MARK: - 항목 탭
    func tapItem(_ item: RoutineItem) {
        guard case .inProgress = state else { return }
        if item.isInstant {
            completeItem(item.id)
        } else {
            activeTimerItem = item
        }
    }

    // MARK: - 타이머 팝업 취소 (항목은 미완료 상태로 복귀)
    func cancelTimerItem() {
        activeTimerItem = nil
    }

    // MARK: - 항목 완료 (타이머 완료 or 즉시)
    func completeItem(_ id: Int) {
        completedItems.insert(id)
        activeTimerItem = nil

        let isAllDone = completedItems.count == routine.count
        let completedGroup = detectGroupCompletion(for: id)

        if let group = completedGroup {
            if isAllDone {
                // 마지막 그룹(몰입) 완료 = 전체 완료 → 마일스톤 먼저, 닫힌 후 완료 처리
                milestoneToShow = group
                pendingFinish = true
            } else {
                milestoneToShow = group
            }
        } else if isAllDone {
            finishChallenge()
        }
    }

    // MARK: - 마일스톤 팝업 닫기
    func dismissMilestone() {
        milestoneToShow = nil
        if pendingFinish {
            pendingFinish = false
            finishChallenge()
        }
    }

    // MARK: - 그룹 완료 감지 (spark/flow/deep 3개 모두 완료 시 해당 타입 반환)
    private func detectGroupCompletion(for id: Int) -> ItemType? {
        guard let item = routine.first(where: { $0.id == id }) else { return nil }
        let type = item.type
        let typeItems = routine.filter { $0.type == type }
        let completedCount = typeItems.filter { completedItems.contains($0.id) }.count
        return completedCount == typeItems.count ? type : nil
    }

    /// 현재까지 완료된 그룹 수 (1~3)
    var completedGroupCount: Int {
        ItemType.allCases.filter { type in
            let typeItems = routine.filter { $0.type == type }
            return !typeItems.isEmpty && typeItems.allSatisfy { completedItems.contains($0.id) }
        }.count
    }

    // MARK: - 챌린지 완료
    private func finishChallenge() {
        let elapsed = challengeTimer.stop()
        state = .completed(elapsedSeconds: elapsed)
        saveRecord(completed: routine.count, elapsed: elapsed, success: true)
        Task {
            let streak = await computeCurrentStreak()
            UserDefaults.standard.set(streak, forKey: "currentStreak")
            analytics.log(.challengeCompleted(elapsedMinutes: elapsed / 60, streak: streak))
            analytics.checkStreakMilestone(streak: streak)
        }
    }

    // MARK: - 종료 버튼 (진행 중 수동 종료)
    func requestStop() {
        isShowingStopConfirm = true
    }

    func confirmStop() {
        let elapsed = challengeTimer.stop()
        let count = completedItems.count
        state = .failed(completedCount: count, reason: .manualStop)
        saveRecord(completed: count, elapsed: elapsed, success: false)
        analytics.log(.challengeFailed(completedCount: count, reason: "manual"))
        isShowingStopConfirm = false
    }

    func cancelStop() {
        isShowingStopConfirm = false
    }

    // MARK: - 타이머 만료 (199분 초과)
    private func handleTimeout() {
        let count = completedItems.count
        let elapsed = challengeTimer.stop()
        state = .failed(completedCount: count, reason: .timeout)
        saveRecord(completed: count, elapsed: elapsed, success: false)
        analytics.log(.challengeFailed(completedCount: count, reason: "timeout"))
    }

    // MARK: - 다음 날 리셋
    func resetForNewDay() {
        completedItems.removeAll()
        activeTimerItem = nil
        milestoneToShow = nil
        pendingFinish = false
        challengeTimer.reset()
        state = .beforeStart
        loadTodayRoutine()
    }

    // MARK: - 오늘 챌린지 리셋 (홈에서 롱프레스)
    func resetTodayChallenge() {
        challengeTimer.reset()
        completedItems.removeAll()
        activeTimerItem = nil
        milestoneToShow = nil
        pendingFinish = false
        state = .beforeStart
        Task {
            try? await recordRepository?.deleteRecord(date: Date().recordKey)
        }
    }

    // MARK: - 기록 저장
    private func saveRecord(completed: Int, elapsed: Int, success: Bool) {
        // 루틴 항목의 실제 ID 순서를 기반으로 완료 여부 기록
        // 루틴이 비어있는 경우 fallback으로 0..<9 인덱스 사용
        let orderedIDs: [Int] = routine.isEmpty
            ? Array(0..<9)
            : ([ItemType.spark, .flow, .deep].flatMap { type in
                routine.filter { $0.type == type }.map { $0.id }
            })
        let itemStatus = orderedIDs.map { completedItems.contains($0) }
        let record = DailyRecord(
            date: recordDate,
            completedCount: completed,
            elapsedSeconds: elapsed,
            isSuccess: success,
            itemStatus: itemStatus
        )
        Task { try? await recordRepository?.saveDailyRecord(record) }
    }

    private func computeCurrentStreak() async -> Int {
        guard let repo = recordRepository else {
            return UserDefaults.standard.integer(forKey: "currentStreak")
        }
        let records = (try? await repo.getAllRecords()) ?? []
        var streak = 0
        var checkDate = Date()
        let calendar = Calendar.current
        while true {
            let key = checkDate.recordKey
            if records.first(where: { $0.date == key && $0.isSuccess }) != nil {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else { break }
        }
        return streak
    }

    // MARK: - 타이머 만료 구독
    private func observeTimer() {
        challengeTimer.$isExpired
            .filter { $0 }
            .sink { [weak self] _ in self?.handleTimeout() }
            .store(in: &cancellables)
    }

    // MARK: - 알람 해제 → 자동 시작
    private func observeAlarmDismiss() {
        NotificationCenter.default.publisher(for: .challengeShouldStart)
            .sink { [weak self] _ in
                Task { self?.startChallenge() }
            }
            .store(in: &cancellables)
    }

    // MARK: - 날씨 구독
    private func observeWeather() {
        WeatherService.shared.$weather
            .receive(on: RunLoop.main)
            .assign(to: &$weather)
    }

    // MARK: - 포그라운드 복귀 시 타이머 동기화
    func handleForeground() {
        if case .inProgress = state {
            challengeTimer.syncWithRealTime()
        }
    }

    // MARK: - 시작일 기준 기록 날짜
    private var recordDate: String {
        let start = challengeTimer.startedAt ?? Date()
        return start.recordKey
    }

    // MARK: - 오늘 이미 완료했는지 확인
    func checkAlreadyCompletedToday() {
        Task {
            let today = Date().recordKey
            if let record = try? await recordRepository?.getDailyRecord(date: today),
               record.isSuccess {
                // 이미 completed 상태면 stateID를 증가시키지 않기 위해 재설정 방지
                if case .completed = self.state { return }
                self.state = .completed(elapsedSeconds: record.elapsedSeconds)
            } else if case .completed = self.state {
                // 오늘 완료 기록 없는데 completed 상태 → 날짜 넘어간 경우, 리셋
                self.state = .beforeStart
            }
        }
    }
}
