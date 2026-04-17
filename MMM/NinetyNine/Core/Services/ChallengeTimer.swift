import Foundation
import Combine

// MARK: - ChallengeTimer
// 백그라운드에서도 정확하게 작동하는 타이머
// Date 기반으로 시간 계산 → 앱이 잠시 꺼져도 실제 경과시간 반영
final class ChallengeTimer: ObservableObject {

    @Published var remainingSeconds: Int = Config.challengeTotalSeconds
    @Published var isRunning: Bool = false
    @Published var isExpired: Bool = false

    var startedAt: Date?
    private var timer: Timer?

    // MARK: - Computed
    var elapsedMinutes: Int {
        guard let start = startedAt else { return 0 }
        return max(0, Int(Date().timeIntervalSince(start) / 60))
    }

    var elapsedSeconds: Int {
        guard let start = startedAt else { return 0 }
        return max(0, Int(Date().timeIntervalSince(start)))
    }

    var remainingFormatted: String {
        let secs = max(0, remainingSeconds)
        let m = secs / 60
        let s = secs % 60
        return String(format: "%d분%02d초", m, s)
    }

    var progress: Double {
        let total = Double(Config.challengeTotalSeconds)
        return max(0, min(1, 1 - Double(remainingSeconds) / total))
    }

    // MARK: - Control
    func start() {
        guard !isRunning else { return }
        startedAt = Date()
        isRunning = true
        // UserDefaults에 시작 시각 저장 → 앱 재시작 후 복원 가능
        UserDefaults.standard.set(startedAt, forKey: "challengeStartedAt")
        scheduleTimer()
    }

    /// 포그라운드 복귀 시 호출 — 실제 경과시간으로 재동기화
    func syncWithRealTime() {
        guard isRunning, let start = startedAt else { return }
        let elapsed = Int(Date().timeIntervalSince(start))
        let newRemaining = Config.challengeTotalSeconds - elapsed
        if newRemaining <= 0 {
            expire()
        } else {
            remainingSeconds = newRemaining
        }
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func resume() {
        guard !isRunning, startedAt != nil else { return }
        syncWithRealTime()  // 백그라운드에서 흐른 시간 반영
        if remainingSeconds > 0 {
            isRunning = true
            scheduleTimer()
        }
    }

    @discardableResult
    func stop() -> Int {
        timer?.invalidate()
        timer = nil
        isRunning = false
        UserDefaults.standard.removeObject(forKey: "challengeStartedAt")
        return elapsedSeconds   // 초 단위 반환 (분 아님)
    }

    func reset() {
        stop()
        remainingSeconds = Config.challengeTotalSeconds
        isExpired = false
        startedAt = nil
    }

    /// 앱 재시작 시 진행 중인 챌린지 복원 시도
    func tryRestoreInProgress() -> Bool {
        guard let saved = UserDefaults.standard.object(forKey: "challengeStartedAt") as? Date else {
            return false
        }
        let elapsed = Int(Date().timeIntervalSince(saved))
        let remaining = Config.challengeTotalSeconds - elapsed
        guard remaining > 0 else {
            // 이미 시간 초과
            UserDefaults.standard.removeObject(forKey: "challengeStartedAt")
            return false
        }
        startedAt = saved
        remainingSeconds = remaining
        isRunning = true
        scheduleTimer()
        return true
    }

    // MARK: - Private
    // 1초마다 Date 기반으로 재계산 → 백그라운드 복귀 후에도 정확
    private func scheduleTimer() {
        timer?.invalidate()
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.startedAt else { return }
            let elapsed = Int(Date().timeIntervalSince(start))
            let remaining = Config.challengeTotalSeconds - elapsed
            if remaining > 0 {
                self.remainingSeconds = remaining
            } else {
                self.expire()
            }
        }
        RunLoop.main.add(t, forMode: .common)  // 스크롤 중에도 작동
        timer = t
    }

    private func expire() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        remainingSeconds = 0
        isExpired = true
        UserDefaults.standard.removeObject(forKey: "challengeStartedAt")
    }
}
