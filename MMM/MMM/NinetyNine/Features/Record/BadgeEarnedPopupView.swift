import SwiftUI
import Photos

// MARK: - Badge Save Card (standalone, designed for ImageRenderer)

struct BadgeSaveCardView: View {
    let badge: Badge
    let earnedDate: Date

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: earnedDate)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Dark gradient background
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.08, blue: 0.20)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Brand label top-right
            Text("99")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.35))
                .padding(.top, Spacing.lg)
                .padding(.trailing, Spacing.lg)

            // Main content
            VStack(spacing: Spacing.xl) {
                Spacer()

                Text(badge.emoji)
                    .font(.system(size: 80))

                VStack(spacing: Spacing.sm) {
                    Text(badge.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(badge.description)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }

                Text(dateString)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.40))

                Spacer()
            }
            .padding(.horizontal, Spacing.xxl)
        }
        .frame(width: 280, height: 400)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }
}

// MARK: - Badge Earned Popup

struct BadgeEarnedPopupView: View {
    let badge: Badge
    let onDismiss: () -> Void

    @State private var badgeScale: CGFloat = 0.4
    @State private var cardOpacity: Double = 0
    @State private var saveStatus: SaveStatus = .idle

    private enum SaveStatus {
        case idle
        case saving
        case success
        case failure
    }

    private var earnedDate: Date {
        badge.earnedAt ?? Date()
    }

    private var earnedDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: earnedDate)
    }

    var body: some View {
        ZStack {
            // Full-screen dim overlay
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture { /* block passthrough */ }

            // Card
            VStack(spacing: 0) {
                // Header
                Text("🎉 새 뱃지 달성!")
                    .font(.system(.headline, design: .default))
                    .foregroundStyle(AppColor.accent)
                    .padding(.top, Spacing.xxl)
                    .padding(.bottom, Spacing.lg)

                // Badge emoji (animated)
                Text(badge.emoji)
                    .font(.system(size: 72))
                    .scaleEffect(badgeScale)
                    .padding(.bottom, Spacing.lg)

                // Badge info
                VStack(spacing: Spacing.sm) {
                    Text(badge.title)
                        .font(.system(.title3, design: .default))
                        .fontWeight(.bold)
                        .foregroundStyle(AppColor.primary)

                    Text(badge.description)
                        .font(.subheadline)
                        .foregroundStyle(AppColor.labelSec)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text(earnedDateString)
                        .font(.caption)
                        .foregroundStyle(AppColor.labelTer)
                        .padding(.top, Spacing.xs)
                }
                .padding(.horizontal, Spacing.xxl)

                Spacer().frame(height: Spacing.xxl)

                // Save status feedback
                if saveStatus != .idle {
                    Text(saveStatus == .success ? "저장됐어요 ✅" : "저장 실패")
                        .font(.caption)
                        .foregroundStyle(saveStatus == .success ? AppColor.success : AppColor.warning)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .padding(.bottom, Spacing.sm)
                }

                // Buttons
                VStack(spacing: Spacing.sm) {
                    Button {
                        saveImage()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            if saveStatus == .saving {
                                ProgressView()
                                    .tint(AppColor.bg)
                                    .scaleEffect(0.8)
                            }
                            Text("이미지 저장")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(isEnabled: saveStatus != .saving))
                    .disabled(saveStatus == .saving)

                    Button("확인") {
                        Haptic.tap()
                        onDismiss()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, Spacing.xxl)
                .padding(.bottom, Spacing.xxl)
            }
            .background(AppColor.bg)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .padding(.horizontal, Spacing.xxl)
            .opacity(cardOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                badgeScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.25)) {
                cardOpacity = 1.0
            }
            Haptic.success()
        }
    }

    // MARK: - Image Save

    private func saveImage() {
        saveStatus = .saving
        Haptic.medium()

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    withAnimation { saveStatus = .failure }
                }
                return
            }
            renderAndSave()
        }
    }

    private func renderAndSave() {
        let card = BadgeSaveCardView(badge: badge, earnedDate: earnedDate)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0

        guard let uiImage = renderer.uiImage else {
            DispatchQueue.main.async {
                withAnimation { saveStatus = .failure }
            }
            return
        }

        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
        } completionHandler: { success, _ in
            DispatchQueue.main.async {
                withAnimation {
                    saveStatus = success ? .success : .failure
                }
                if success { Haptic.success() } else { Haptic.error() }
            }
        }
    }
}

// MARK: - Preview

#Preview("Badge Earned Popup") {
    BadgeEarnedPopupView(
        badge: Badge(
            id: "streak_7",
            emoji: "⚔️",
            title: "일주일 전사",
            description: "7일 연속 챌린지 완료",
            category: .streak,
            earnedAt: Date()
        ),
        onDismiss: {}
    )
}

#Preview("Badge Save Card") {
    BadgeSaveCardView(
        badge: Badge(
            id: "streak_30",
            emoji: "🏆",
            title: "한 달의 기적",
            description: "30일 연속 챌린지 완료",
            category: .streak,
            earnedAt: Date()
        ),
        earnedDate: Date()
    )
    .padding()
    .background(Color.gray)
}
