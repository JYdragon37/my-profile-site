import SwiftUI

// MARK: - 완료 화면 (해방!)
struct CompletionView: View {
    let elapsedSeconds: Int
    let onDismiss: () -> Void
    var recordRepository: (any RecordRepositoryProtocol)? = nil

    @AppStorage("userNickname") private var nickname: String = "친구"
    @AppStorage("personalBestSeconds") private var personalBestSeconds: Int = Int.max
    @State private var showContent: Bool = false
    @State private var showConfetti: Bool = false

    // Podium state
    @State private var podiumRank: Int? = nil         // 1~3 if in top 3
    @State private var isNewBestRecord: Bool = false  // true if this run is a new personal best
    @State private var diffToTopSeconds: Int? = nil   // diff from rank 1 if not in top 3

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

                    // 개인 포디엄 배지
                    podiumBadge
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.3).delay(0.3), value: showContent)

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
            Task { await loadPodiumData() }
        }
    }

    // MARK: - 포디엄 배지 뷰
    @ViewBuilder
    private var podiumBadge: some View {
        if isNewBestRecord {
            // 새 개인 기록
            HStack(spacing: Spacing.sm) {
                Text("🏆")
                    .font(.title3)
                Text("새 개인 기록!")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColor.accent)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(AppColor.accent.opacity(0.12))
            .clipShape(Capsule())
        } else if let rank = podiumRank {
            // 개인 순위 1~3위
            let medal = rank == 1 ? "🥇" : rank == 2 ? "🥈" : "🥉"
            HStack(spacing: Spacing.sm) {
                Text(medal)
                    .font(.title3)
                Text("오늘 개인 \(rank)위예요")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.primary)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(AppColor.bgSecond)
            .clipShape(Capsule())
        } else if let diff = diffToTopSeconds {
            // 포디엄 밖
            let diffMin = diff / 60
            let diffSec = diff % 60
            let diffStr = diffSec > 0 ? "\(diffMin)분 \(diffSec)초" : "\(diffMin)분"
            HStack(spacing: Spacing.sm) {
                Image(systemName: "trophy")
                    .font(.subheadline)
                    .foregroundStyle(AppColor.labelSec)
                Text("개인 최고까지 \(diffStr) 차이에요")
                    .font(.subheadline)
                    .foregroundStyle(AppColor.labelSec)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(AppColor.bgSecond)
            .clipShape(Capsule())
        }
    }

    // MARK: - 포디엄 데이터 로드
    private func loadPodiumData() async {
        guard let repo = recordRepository else { return }
        let records = (try? await repo.getAllRecords()) ?? []
        // isSuccess == true 인 기록을 elapsedSeconds 오름차순 정렬
        let successRecords = records
            .filter { $0.isSuccess }
            .sorted { $0.elapsedSeconds < $1.elapsedSeconds }

        // 현재 기록이 새 최고인지 확인
        let topSeconds = successRecords.first?.elapsedSeconds
        if let top = topSeconds {
            isNewBestRecord = elapsedSeconds < top
        } else {
            // 기록이 없으면 첫 완주 = 새 최고
            isNewBestRecord = true
        }

        if isNewBestRecord {
            // 새 최고 기록이면 별도 배지로 처리
            return
        }

        // 포디엄 상위 3 개에 현재 기록이 들어가는지 확인
        // 현재 세션을 포함해 다시 삽입해 순위 산정
        var updatedRecords = successRecords.map { $0.elapsedSeconds }
        updatedRecords.append(elapsedSeconds)
        updatedRecords.sort()

        // 중복 허용 순위: 현재 기록의 첫 번째 위치 (1-indexed)
        if let firstIndex = updatedRecords.firstIndex(of: elapsedSeconds) {
            let rank = firstIndex + 1
            if rank <= 3 {
                podiumRank = rank
            } else if let best = updatedRecords.first {
                diffToTopSeconds = elapsedSeconds - best
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
                // 이모지 — 따뜻한 톤으로 교체
                Text(completedCount > 0 ? "🌱" : (reason == .timeout ? "⏰" : "🌿"))
                    .font(.system(size: 72))
                    .scaleEffect(showContent ? 1 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.05), value: showContent)

                // 메시지 — 달성한 것을 먼저 칭찬
                VStack(spacing: Spacing.sm) {
                    if completedCount > 0 {
                        Text("오늘 \(completedCount)개 해냈어요!")
                            .titleMedium()
                    } else {
                        Text(reason == .timeout ? "시간이 다 됐어요" : "오늘은 여기까지")
                            .titleMedium()
                    }

                    Text("작은 시작이 변화를 만들어요")
                        .bodySecondary()
                        .multilineTextAlignment(.center)
                }

                // 항목 카드 — 완료/미완료 모두 표시, 미완료는 부드럽게
                if !incompleteItems.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("남은 항목")
                            .font(.caption)
                            .foregroundStyle(AppColor.labelTer)
                            .padding(.bottom, Spacing.xs)

                        ForEach(incompleteItems) { item in
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "circle.dashed")
                                    .font(.subheadline)
                                    .foregroundStyle(AppColor.labelTer)
                                Text(item.type.emoji)
                                    .font(.body)
                                Text(item.title)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColor.labelTer)
                            }
                        }
                    }
                    .padding(Spacing.lg)
                    .cardStyle()
                    .padding(.horizontal, Spacing.xxxl)
                }

                // 격려 메시지
                Text("내일 또 만나요, \(nickname) 👋")
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

                Button("내일 또 만나요") {
                    Haptic.tap()
                    onDismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, Spacing.xl)
            }
            .padding(.bottom, Spacing.huge)
        }
        .onAppear {
            Haptic.medium()
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
