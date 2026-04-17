import SwiftUI

// MARK: - 완료 화면 (해방!)
struct CompletionView: View {
    let elapsedSeconds: Int
    let onDismiss: () -> Void

    @AppStorage("userNickname") private var nickname: String = "친구"
    @AppStorage("personalBestSeconds") private var personalBestSeconds: Int = Int.max
    @State private var showContent: Bool = false
    @State private var showConfetti: Bool = false

    var isNewRecord: Bool { elapsedSeconds < personalBestSeconds && personalBestSeconds != Int.max }

    var elapsedDisplay: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return s > 0 ? "\(m)분 \(s)초" : "\(m)분"
    }

    var bestDisplay: String {
        let bestSec = personalBestSeconds == Int.max ? elapsedSeconds : min(elapsedSeconds, personalBestSeconds)
        let m = bestSec / 60
        let s = bestSec % 60
        return (s > 0 ? "\(m)분 \(s)초" : "\(m)분") + " 🏆"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                // 컨페티
                if showConfetti {
                    ConfettiLayer()
                }

                VStack(spacing: Spacing.xxxl) {
                    // 이모지 (스프링 애니메이션)
                    Text("🎉")
                        .font(.system(size: 80))
                        .scaleEffect(showContent ? 1.0 : 0.2)
                        .rotationEffect(.degrees(showContent ? 0 : -30))
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.55).delay(0.05),
                            value: showContent
                        )

                    // 메시지 (지연 등장)
                    VStack(spacing: Spacing.md) {
                        Text("해냈어요, \(nickname)!")
                            .titleLarge()

                        if isNewRecord {
                            Label("새로운 최고 기록! 🏆", systemImage: "star.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColor.accent)
                                .scaleEffect(showContent ? 1 : 0.7)
                                .animation(.spring(duration: 0.4).delay(0.35), value: showContent)
                        } else {
                            Text("오늘도 완주했어요! ✨")
                                .font(.subheadline)
                                .foregroundStyle(AppColor.labelSec)
                                .scaleEffect(showContent ? 1 : 0.7)
                                .animation(.spring(duration: 0.4).delay(0.35), value: showContent)
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 12)
                    .animation(.easeOut(duration: 0.35).delay(0.2), value: showContent)

                    // 기록 카드
                    VStack(spacing: Spacing.md) {
                        Divider()
                        RecordRow(label: "완료", value: "9 / 9")
                        RecordRow(label: "오늘 시간", value: elapsedDisplay)
                        RecordRow(label: "최고 기록", value: bestDisplay)
                        Divider()
                    }
                    .padding(.horizontal, Spacing.xxxl)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.4), value: showContent)

                    Text("나머지 시간은 자유입니다 ✨")
                        .bodySecondary()
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(0.55), value: showContent)
                }
            }

            Spacer()

            Button("자유 시간 시작하기 ✨") {
                Haptic.tap()
                updatePersonalBest()
                onDismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.huge)
            .opacity(showContent ? 1 : 0)
            .animation(.easeIn(duration: 0.3).delay(0.6), value: showContent)
        }
        .onAppear {
            Haptic.success()
            withAnimation { showContent = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }

    private func updatePersonalBest() {
        if elapsedSeconds < personalBestSeconds {
            personalBestSeconds = elapsedSeconds
        }
    }
}

// MARK: - 미완료 화면
struct IncompleteView: View {
    let completedCount: Int
    let incompleteItems: [RoutineItem]
    let reason: TodayViewModel.FailReason
    let onDismiss: () -> Void
    let onContinue: () -> Void

    @AppStorage("userNickname") private var nickname: String = "친구"
    @State private var showContent: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Spacing.xxxl) {
                // 이모지
                Text(reason == .timeout ? "⏰" : "😮‍💨")
                    .font(.system(size: 64))
                    .scaleEffect(showContent ? 1 : 0.5)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showContent)

                // 메시지
                VStack(spacing: Spacing.sm) {
                    Text(reason == .timeout ? "시간이 다 됐습니다" : "오늘은 여기까지")
                        .titleMedium()

                    Text("\(completedCount) / 9 완료")
                        .bodySecondary()
                }

                // 미완료 항목 카드
                if !incompleteItems.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("미완료 항목")
                            .bodySecondary()
                            .padding(.bottom, Spacing.xs)

                        ForEach(incompleteItems) { item in
                            HStack(spacing: Spacing.sm) {
                                Text(item.type.emoji)
                                    .font(.body)
                                Text(item.title)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColor.labelSec)
                            }
                        }
                    }
                    .padding(Spacing.lg)
                    .cardStyle()
                    .padding(.horizontal, Spacing.xxxl)
                }

                // 격려 메시지
                Text("내일은 더 일찍 시작해봐요, \(nickname)")
                    .bodySecondary()
                    .multilineTextAlignment(.center)
            }
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.3).delay(0.1), value: showContent)

            Spacer()

            // 버튼들
            VStack(spacing: Spacing.sm) {
                if reason == .manualStop {
                    Button("계속하기") {
                        Haptic.medium()
                        onContinue()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, Spacing.xl)
                }

                Button("확인") {
                    Haptic.tap()
                    onDismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, Spacing.xl)
            }
            .padding(.bottom, Spacing.huge)
        }
        .onAppear {
            Haptic.warning()
            withAnimation { showContent = true }
        }
    }
}

// MARK: - 기록 행
struct RecordRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).bodySecondary()
            Spacer()
            Text(value).font(.subheadline).fontWeight(.medium)
        }
    }
}

// MARK: - 컨페티 레이어
struct ConfettiLayer: View {
    let emojis = ["🎉", "⭐", "✨", "🎊", "🌟"]
    @State private var particles: [(id: Int, x: CGFloat, y: CGFloat, emoji: String, scale: CGFloat)] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles, id: \.id) { p in
                    Text(p.emoji)
                        .font(.system(size: 24))
                        .scaleEffect(p.scale)
                        .position(x: p.x, y: p.y)
                }
            }
            .onAppear {
                particles = (0..<20).map { i in
                    (id: i,
                     x: CGFloat.random(in: 0...geo.size.width),
                     y: CGFloat.random(in: -50...geo.size.height * 0.6),
                     emoji: emojis.randomElement()!,
                     scale: CGFloat.random(in: 0.6...1.4))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
