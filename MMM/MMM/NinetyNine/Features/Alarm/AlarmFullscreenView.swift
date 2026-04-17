import SwiftUI
import Kingfisher

// 알람이 울릴 때 전체화면으로 표시되는 뷰
// AppDelegate에서 노티피케이션 수신 시 fullScreenCover로 표시
struct AlarmFullscreenView: View {

    let alarmID: String
    let challengeAutoStart: Bool
    let onDismiss: () -> Void

    @ObservedObject private var motivationService = MotivationService.shared
    @AppStorage("userNickname") private var nickname: String = "친구"
    @State private var currentTime: Date = Date()
    @State private var isPulsing = false                        // 종료 버튼 펄스
    @State private var showChallengeStartOverlay = false
    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // MARK: - 배경 이미지
            backgroundLayer

            // MARK: - 콘텐츠 오버레이
            VStack(spacing: 0) {
                Spacer()

                // 동기부여 글귀
                VStack(spacing: 10) {
                    Text("\"\(motivationService.current.quote.quote)\"")
                        .font(.system(size: 17, weight: .medium, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 36)
                        .shadow(color: .black.opacity(0.6), radius: 6)

                    if !motivationService.current.quote.author.isEmpty {
                        Text("— \(motivationService.current.quote.author)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()

                // 시계 + 인사
                VStack(spacing: 6) {
                    Text(currentTimeString)
                        .font(.system(size: 80, weight: .thin, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 8)

                    Text("준비됐나요, \(nickname)? 👋")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                // ── 알라미 스타일 종료 버튼 ──────────────────────
                stopButton
                    .padding(.bottom, 56)
            }

            // 챌린지 시작 오버레이
            if showChallengeStartOverlay {
                Color.black.opacity(0.5).ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("💪").font(.system(size: 72))
                    Text("챌린지 시작!")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .scaleEffect(showChallengeStartOverlay ? 1.0 : 0.7)
                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: showChallengeStartOverlay)
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .onReceive(clockTimer) { date in currentTime = date }
        .onAppear {
            // 버튼 펄스 시작
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
            Haptic.warning()
        }
    }

    // MARK: - 알라미 스타일 종료 버튼
    private var stopButton: some View {
        Button {
            Haptic.heavy()
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 20, weight: .semibold))
                Text("알람 끄기")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: .white.opacity(0.5), radius: isPulsing ? 20 : 8)
            )
            .scaleEffect(isPulsing ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 48)
    }

    // MARK: - 배경 레이어 (Kingfisher 디스크 캐시)
    @ViewBuilder
    private var backgroundLayer: some View {
        ZStack {
            // 항상 기본 그라디언트 먼저 표시 → 이미지 로딩 전 흑화 방지
            defaultBackground

            if let url = motivationService.current.imageURL {
                KFImage(url)
                    .fade(duration: 0.2)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }

            // 딤 오버레이 — 항상 적용 (이미지 로딩 여부 무관)
            Color.black.opacity(0.4)
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }

    private var defaultBackground: some View {
        LinearGradient(
            colors: [Color(hue: 0.6, saturation: 0.7, brightness: 0.3),
                     Color(hue: 0.65, saturation: 0.8, brightness: 0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Helpers
    private var currentTimeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: currentTime)
    }

    private func dismiss() {
        AlarmService.shared.handleDismissed(
            alarmID: alarmID,
            challengeAutoStart: challengeAutoStart
        )
        if challengeAutoStart {
            withAnimation { showChallengeStartOverlay = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { onDismiss() }
        } else {
            onDismiss()
        }
    }
}
