import SwiftUI

// 알람이 울릴 때 전체화면으로 표시되는 뷰
// AppDelegate에서 노티피케이션 수신 시 fullScreenCover로 표시
struct AlarmFullscreenView: View {

    let alarmID: String
    let challengeAutoStart: Bool
    let onDismiss: () -> Void

    @StateObject private var motivationService = MotivationService.shared
    @State private var dragOffset: CGFloat = 0
    @State private var nickname: String = UserDefaults.standard.string(forKey: "userNickname") ?? "친구"
    @State private var currentTime: Date = Date()
    @State private var showChallengeStartOverlay: Bool = false  // Feature O: 챌린지 시작 오버레이
    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let dismissThreshold: CGFloat = 80

    var body: some View {
        ZStack {
            // MARK: - 배경 이미지
            backgroundLayer

            // MARK: - 콘텐츠 오버레이
            VStack {
                Spacer()

                // 글귀
                VStack(spacing: 12) {
                    Text("\"\(motivationService.current.quote.quote)\"")
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .shadow(radius: 4)

                    if !motivationService.current.quote.author.isEmpty {
                        Text("— \(motivationService.current.quote.author)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                Spacer()

                // 시간 + 닉네임
                VStack(spacing: 8) {
                    Text(currentTimeString)
                        .font(.system(size: 72, weight: .thin, design: .rounded))
                        .foregroundStyle(.white)

                    Text("준비됐나요, \(nickname)? 👋")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()

                // 슬라이드 해제 버튼
                slideToStart
                    .padding(.bottom, 60)
            }

            // MARK: - Feature O: 챌린지 시작 오버레이 (슬라이드 후 0.8초 표시)
            if showChallengeStartOverlay {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        Text("💪")
                            .font(.system(size: 64))
                        Text("챌린지 시작!")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(showChallengeStartOverlay ? 1.0 : 0.6)
                    .opacity(showChallengeStartOverlay ? 1.0 : 0.0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.65), value: showChallengeStartOverlay)
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .onReceive(clockTimer) { date in
            currentTime = date
        }
        .onAppear {
            loadNickname()
            Task { await motivationService.fetchIfNeeded() }
        }
    }

    // MARK: - 배경 레이어
    @ViewBuilder
    private var backgroundLayer: some View {
        if let url = MotivationService.storageURL(for: motivationService.current.storagePath) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .overlay(Color.black.opacity(0.45))
                default:
                    defaultBackground
                }
            }
        } else {
            defaultBackground
        }
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

    // MARK: - 슬라이드 해제
    // 드래그 또는 트랙 전체 탭으로 해제 가능 (손이 미끄러져도 앱이 잠기지 않도록)
    private var slideToStart: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(.white.opacity(0.25))
                .frame(height: 56)
                // 트랙 전체 탭으로도 해제 허용 (접근성 폴백)
                .onTapGesture { dismiss() }

            Capsule()
                .fill(.white.opacity(0.15))
                .frame(width: max(56, 56 + dragOffset), height: 56)
                .animation(.interactiveSpring(), value: dragOffset)
                .allowsHitTesting(false)

            HStack {
                Circle()
                    .fill(.white)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "chevron.right.2")
                            .foregroundStyle(.black)
                    )
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = max(0, min(value.translation.width, 200))
                            }
                            .onEnded { value in
                                if dragOffset > dismissThreshold {
                                    dismiss()
                                } else {
                                    withAnimation(.spring()) { dragOffset = 0 }
                                }
                            }
                    )

                Spacer()

                Text("밀어서 시작")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.trailing, 20)
            }
            .padding(.leading, 4)
            .allowsHitTesting(false)
        }
        .frame(width: 280)
        .contentShape(Rectangle())
    }

    // MARK: - Helpers
    private var currentTimeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: currentTime)
    }

    private func loadNickname() {
        nickname = UserDefaults.standard.string(forKey: "userNickname") ?? "친구"
    }

    private func dismiss() {
        AlarmService.shared.handleDismissed(
            alarmID: alarmID,
            challengeAutoStart: challengeAutoStart
        )
        // Feature O: 챌린지 자동시작인 경우 "챌린지 시작! 💪" 오버레이 0.8초 표시 후 해제
        if challengeAutoStart {
            withAnimation { showChallengeStartOverlay = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                onDismiss()
            }
        } else {
            onDismiss()
        }
    }
}
