import SwiftUI

struct ModeSelectionView: View {
    let onMorning: () -> Void
    let onGeneral: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Spacing.xxxl) {
                VStack(spacing: Spacing.sm) {
                    Text("어떻게 사용하실 건가요?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("언제든지 설정에서 변경할 수 있어요")
                        .font(.subheadline)
                        .foregroundStyle(AppColor.labelSec)
                }

                VStack(spacing: Spacing.lg) {
                    ModeCard(
                        icon: "🌅",
                        title: "모닝 모드",
                        subtitle: "기상 알람과 함께 시작해요",
                        description: "오전을 생산적으로 보내고 싶은 분께 추천",
                        onTap: onMorning
                    )
                    ModeCard(
                        icon: "🕐",
                        title: "일반 모드",
                        subtitle: "원할 때 직접 시작해요",
                        description: "스케줄이 유동적인 분께 추천",
                        onTap: onGeneral
                    )
                }
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()
        }
        .background(AppColor.bg)
    }
}

// MARK: - 모드 선택 카드
struct ModeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let onTap: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: {
            Haptic.tap()
            onTap()
        }) {
            HStack(spacing: Spacing.lg) {
                Text(icon)
                    .font(.system(size: 40))
                    .frame(width: 56, height: 56)
                    .background(AppColor.bgThird)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppColor.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppColor.labelSec)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(AppColor.labelTer)
                        .lineSpacing(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(AppColor.labelTer)
            }
            .padding(Spacing.xl)
            .background(AppColor.bgSecond)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.15), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}
