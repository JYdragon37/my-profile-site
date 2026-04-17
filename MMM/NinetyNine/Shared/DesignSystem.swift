import SwiftUI

// MARK: - 색상 시스템
enum AppColor {
    static let primary   = Color.primary            // 시스템 (다크모드 자동 대응)
    static let accent    = Color.orange              // 강조 (챌린지 자동시작, 최고기록)
    static let success   = Color.green              // 완료 체크
    static let warning   = Color.red                // 타이머 위험 구간
    static let bg        = Color(.systemBackground)
    static let bgSecond  = Color(.secondarySystemBackground)
    static let bgThird   = Color(.tertiarySystemFill)
    static let labelSec  = Color(.secondaryLabel)
    static let labelTer  = Color(.tertiaryLabel)
}

// MARK: - 여백 시스템 (4pt 그리드)
enum Spacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let huge: CGFloat = 48
}

// MARK: - 버튼 높이
enum ButtonHeight {
    static let primary:   CGFloat = 56  // 메인 CTA
    static let secondary: CGFloat = 48  // 보조 버튼
    static let small:     CGFloat = 40  // 소형 버튼
}

// MARK: - 코너 반경
enum Radius {
    static let sm:  CGFloat = 10
    static let md:  CGFloat = 14
    static let lg:  CGFloat = 16
    static let full: CGFloat = 999
}

// MARK: - 타이포그래피 View Extension
extension View {
    func titleLarge() -> some View {
        self.font(.system(.title, design: .default))
            .fontWeight(.bold)
    }
    func titleMedium() -> some View {
        self.font(.system(.title2, design: .default))
            .fontWeight(.semibold)
    }
    func titleSmall() -> some View {
        self.font(.system(.title3, design: .default))
            .fontWeight(.semibold)
    }
    func bodyPrimary() -> some View {
        self.font(.body)
    }
    func bodySecondary() -> some View {
        self.font(.subheadline)
            .foregroundStyle(AppColor.labelSec)
    }
    func caption() -> some View {
        self.font(.caption)
            .foregroundStyle(AppColor.labelTer)
    }
}

// MARK: - Haptic Helper
enum Haptic {
    static func tap()     { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium()  { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func heavy()   { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func error()   { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func select()  { UISelectionFeedbackGenerator().selectionChanged() }
}

// MARK: - 메인 CTA 버튼 스타일
struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? Color(.systemBackground) : AppColor.labelSec)
            .frame(maxWidth: .infinity)
            .frame(height: ButtonHeight.primary)
            .background(isEnabled ? AppColor.primary : AppColor.bgSecond)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.15), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { Haptic.tap() }
            }
    }
}

// MARK: - 보조 버튼 스타일
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundStyle(AppColor.labelSec)
            .frame(maxWidth: .infinity)
            .frame(height: ButtonHeight.secondary)
            .background(AppColor.bgSecond)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - 카드 스타일
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColor.bgSecond)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - 스켈레톤 로딩
struct SkeletonRow: View {
    var width: CGFloat = .infinity
    var height: CGFloat = 20
    @State private var opacity: Double = 0.4

    var body: some View {
        RoundedRectangle(cornerRadius: Radius.sm)
            .fill(AppColor.bgSecond)
            .frame(maxWidth: width)
            .frame(height: height)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    opacity = 0.9
                }
            }
    }
}

// MARK: - 향상된 로딩 오버레이
struct LoadingOverlay: View {
    var message: String = "로딩 중..."
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        .frame(width: 44, height: 44)
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(rotation))
                }
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(Spacing.xxl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        }
        .onAppear {
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - 빈 상태 공통 컴포넌트
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 52))
                .foregroundStyle(AppColor.labelSec)
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .titleSmall()
                Text(description)
                    .bodySecondary()
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            if let actionTitle, let onAction {
                Button(actionTitle, action: onAction)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, Spacing.xxl)
            }
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - 완료 뱃지
struct CompletionBadge: View {
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "bolt.fill")
                .font(.caption2)
            Text("자동시작")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(AppColor.accent)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(AppColor.accent.opacity(0.15))
        .clipShape(Capsule())
    }
}
