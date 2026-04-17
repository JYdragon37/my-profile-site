import SwiftUI

struct TimerPopupView: View {

    let item: RoutineItem
    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var remainingSeconds: Int
    @State private var timer: Timer?
    @Environment(\.dismiss) private var dismiss

    init(item: RoutineItem, onComplete: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.item = item
        self.onComplete = onComplete
        self.onCancel = onCancel
        _remainingSeconds = State(initialValue: item.durationSeconds)
    }

    var progress: Double {
        1 - Double(remainingSeconds) / Double(item.durationSeconds)
    }

    var timeString: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        VStack(spacing: Spacing.xxxl) {
            // 항목 정보
            VStack(spacing: Spacing.sm) {
                Text(item.type.emoji)
                    .font(.system(size: 44))
                Text(item.title)
                    .titleSmall()
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Spacing.xxxl)

            // 원형 타이머
            ZStack {
                Circle()
                    .stroke(AppColor.bgSecond, lineWidth: 8)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AppColor.primary,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                Text(timeString)
                    .font(.system(size: 40, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 1), value: timeString)
            }

            // 버튼
            VStack(spacing: Spacing.sm) {
                Button {
                    stopTimer()
                    Haptic.success()
                    onComplete()
                    dismiss()
                } label: {
                    Text("완료")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Spacing.xxl)

                Button(role: .cancel) {
                    stopTimer()
                    Haptic.tap()
                    onCancel()
                    dismiss()
                } label: {
                    Text("취소")
                        .frame(maxWidth: .infinity)
                        .frame(height: ButtonHeight.secondary)
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, Spacing.xxl)
            }
            .padding(.bottom, Spacing.xxxl)
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private func startTimer() {
        // .common 모드로 등록해야 스크롤 중에도 타이머가 정확히 작동함 (ChallengeTimer와 동일 패턴)
        let t = Timer(timeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                // 타이머 10초 전 햅틱
                if remainingSeconds == 10 { Haptic.medium() }
            } else {
                stopTimer()
                Haptic.success()
                onComplete()
                dismiss()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

extension RoutineItem: Hashable {
    static func == (lhs: RoutineItem, rhs: RoutineItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
