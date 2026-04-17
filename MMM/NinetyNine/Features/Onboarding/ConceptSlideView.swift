import SwiftUI

enum ConceptSlide {
    case empathy1   // 슬라이드 1: 오늘 하루 끝났는데 할일 그대로
    case empathy2   // 슬라이드 2: 며칠째 지워지지 않는 불편함
    case identity   // 슬라이드 3: 서비스 아이덴티티
    case reveal     // 슬라이드 4: 3-3-30 구조 + 99분9초

    var index: Int {
        switch self {
        case .empathy1: return 0
        case .empathy2: return 1
        case .identity: return 2
        case .reveal:   return 3
        }
    }
}

struct ConceptSlideView: View {
    let slide: ConceptSlide
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Group {
                switch slide {
                case .empathy1: Empathy1Slide()
                case .empathy2: Empathy2Slide()
                case .identity: IdentitySlide()
                case .reveal:   RevealSlide()
                }
            }

            Spacer()

            PageIndicator(current: slide.index, total: 4)
                .padding(.bottom, Spacing.xxxl)

            Button(action: onNext) {
                Text(slide == .reveal ? "시작하기" : "다음")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.huge)
        }
        .background(AppColor.bg)
    }
}

// MARK: - 슬라이드 1: 공감 — 오늘 하루 끝
struct Empathy1Slide: View {
    var body: some View {
        VStack(spacing: Spacing.xxxl) {
            // 일러스트: 저녁 체크 안 된 할일 목록 느낌
            ZStack {
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(AppColor.bgSecond)
                    .frame(width: 220, height: 200)
                VStack(spacing: Spacing.sm) {
                    ForEach(0..<5) { i in
                        HStack(spacing: Spacing.md) {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(AppColor.labelTer, lineWidth: 1.5)
                                .frame(width: 18, height: 18)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColor.bgThird)
                                .frame(width: CGFloat(80 + i * 12), height: 12)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, Spacing.xxl)

                // 저녁 달 아이콘
                VStack {
                    HStack {
                        Spacer()
                        Text("🌙")
                            .font(.title3)
                            .offset(x: 12, y: -12)
                    }
                    Spacer()
                }
            }

            VStack(spacing: Spacing.md) {
                Text("할일을 적었는데\n오늘 하루가 끝났어요.")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("그 일, 아직 거기 있어요.")
                    .font(.subheadline)
                    .foregroundStyle(AppColor.labelSec)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Spacing.xxxl)
    }
}

// MARK: - 슬라이드 2: 공감 — 며칠이 지남
struct Empathy2Slide: View {
    var body: some View {
        VStack(spacing: Spacing.xxxl) {
            // 일러스트: 날짜가 쌓이는 느낌
            ZStack {
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(AppColor.bgSecond)
                    .frame(width: 220, height: 200)
                VStack(spacing: Spacing.xs) {
                    ForEach(0..<4) { row in
                        HStack(spacing: Spacing.xs) {
                            ForEach(0..<7) { col in
                                let dayNum = row * 7 + col + 1
                                let isPast = dayNum <= 18
                                let isToday = dayNum == 19
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(isPast ? AppColor.bgThird : Color.clear)
                                        .frame(width: 22, height: 22)
                                    if isToday {
                                        Circle()
                                            .fill(AppColor.accent.opacity(0.3))
                                            .frame(width: 22, height: 22)
                                    }
                                    if dayNum <= 28 {
                                        Text("\(dayNum)")
                                            .font(.system(size: 9))
                                            .foregroundStyle(isPast ? AppColor.labelSec : AppColor.labelTer)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
            }

            VStack(spacing: Spacing.md) {
                Text("내일은 꼭 하려고 했는데\n며칠이 지났어요.")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("그 불편함, 99가 함께할게요.")
                    .font(.subheadline)
                    .foregroundStyle(AppColor.labelSec)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Spacing.xxxl)
    }
}

// MARK: - 슬라이드 3: 아이덴티티
struct IdentitySlide: View {
    var body: some View {
        VStack(spacing: Spacing.xxxl) {
            Text("해결책은 단순해요.")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            VStack(spacing: Spacing.lg) {
                IdentityPoint(icon: "✦", label: "심플하게")
                IdentityPoint(icon: "⏱", label: "정해진 시간 안에")
                IdentityPoint(icon: "↑", label: "우선순위 높은 것부터")
            }
            .padding(Spacing.xxl)
            .background(AppColor.bgSecond)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))

            Text("Todo에 쫓기지 않고\n일상 습관을 건강하게 만드는 비결")
                .font(.subheadline)
                .foregroundStyle(AppColor.labelSec)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.horizontal, Spacing.xxxl)
    }
}

struct IdentityPoint: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: Spacing.lg) {
            Text(icon)
                .font(.title3)
                .frame(width: 32)
            Text(label)
                .font(.headline)
            Spacer()
        }
    }
}

// MARK: - 슬라이드 4: 리빌 — 99분9초
struct RevealSlide: View {
    @State private var visibleRows: Int = 0

    private let rows: [(emoji: String, label: String, calc: String)] = [
        ("⚡", "뚝딱", "3초 × 3 = 9초"),
        ("🔹", "착착", "3분 × 3 = 9분"),
        ("🔵", "몰입", "30분 × 3 = 90분"),
    ]

    var body: some View {
        VStack(spacing: Spacing.xxxl) {
            Text("하루에 딱 9가지만")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            // 계산식 카드
            VStack(spacing: 0) {
                ForEach(rows.indices, id: \.self) { i in
                    if i < visibleRows {
                        VStack(spacing: 0) {
                            HStack(spacing: Spacing.md) {
                                Text(rows[i].emoji)
                                    .font(.title3)
                                    .frame(width: 32)
                                Text(rows[i].label)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(rows[i].calc)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColor.labelSec)
                                    .monospacedDigit()
                            }
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, Spacing.md)

                            if i < rows.count - 1 {
                                Divider()
                                    .padding(.horizontal, Spacing.xl)
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }

                if visibleRows >= rows.count {
                    VStack(spacing: 0) {
                        Divider()
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, Spacing.xs)
                        HStack {
                            Text("합계")
                                .font(.headline)
                                .frame(width: 32 + Spacing.md, alignment: .leading)
                            Spacer()
                            totalTimeText
                        }
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                    }
                    .transition(.opacity)
                }
            }
            .background(AppColor.bgSecond)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))

            // 제한시간 표시: ¹99분
            if visibleRows >= rows.count {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("제한시간")
                        .font(.subheadline)
                        .foregroundStyle(AppColor.labelSec)
                    limitTimeText
                }
                .transition(.opacity)
            }

            // 힌트
            Text("매일 얼마나 빠르게 끝냈는지\n기록으로 남아요")
                .font(.caption)
                .foregroundStyle(AppColor.labelSec)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.xxxl)
        .onAppear {
            animateRows()
        }
    }

    private var totalTimeText: some View {
        Text("99분 9초")
            .font(.headline)
            .fontWeight(.bold)
            .monospacedDigit()
    }

    private var limitTimeText: some View {
        // ¹99분: 위첨자 1 + 굵고 큰 99분
        Text(limitAttributedString)
    }

    private var limitAttributedString: AttributedString {
        var one = AttributedString("1")
        one.font = .system(size: 16, weight: .bold)   // 28 → 16
        one.foregroundColor = AppColor.labelTer

        var ninetyNine = AttributedString("99")
        ninetyNine.font = .system(size: 28, weight: .bold)

        var unit = AttributedString("분")
        unit.font = .system(.title3, design: .default, weight: .semibold)

        return one + ninetyNine + unit
    }

    private func animateRows() {
        for i in 0..<rows.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.4) {
                withAnimation(.spring(duration: 0.4)) {
                    visibleRows = i + 1
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(rows.count) * 0.4 + 0.2) {
            withAnimation(.easeIn(duration: 0.3)) {
                visibleRows = rows.count + 1
            }
        }
    }
}

// MARK: - 페이지 인디케이터
struct PageIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == current ? AppColor.primary : AppColor.bgThird)
                    .frame(width: i == current ? 20 : 8, height: 8)
                    .animation(.spring(duration: 0.3), value: current)
            }
        }
    }
}
