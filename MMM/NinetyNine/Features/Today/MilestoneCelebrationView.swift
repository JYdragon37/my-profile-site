import SwiftUI

// MARK: - Confetti 조각 데이터
private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let initX: CGFloat
    let initY: CGFloat
    let finalX: CGFloat
    let finalY: CGFloat
    let finalRotation: Double
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let shape: PieceShape
    let delay: Double
    let duration: Double

    enum PieceShape { case rect, circle, oval }
}

// MARK: - 마일스톤 축하 팝업
struct MilestoneCelebrationView: View {

    let type: ItemType
    let completedGroupCount: Int
    let onDismiss: () -> Void

    @State private var pieces: [ConfettiPiece] = []
    @State private var flying = false       // confetti 비행 트리거
    @State private var cardVisible = false  // 카드 등장 트리거
    @State private var progressDot: CGFloat = 0

    private let autoDismiss: Double = 2.8

    // 레퍼런스 이미지와 동일한 컬러 팔레트
    private let confettiColors: [Color] = [
        Color(red: 0.52, green: 0.42, blue: 1.00),  // purple
        Color(red: 1.00, green: 0.28, blue: 0.58),  // hot pink
        Color(red: 1.00, green: 0.84, blue: 0.10),  // yellow
        Color(red: 0.95, green: 0.20, blue: 0.40),  // rose
        Color(red: 0.45, green: 0.70, blue: 1.00),  // blue
        Color(red: 0.90, green: 0.68, blue: 0.95),  // lavender
        Color(red: 1.00, green: 0.52, blue: 0.18),  // orange
        Color.white,
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── confetti 조각들 ──────────────────────
                ForEach(pieces) { piece in
                    PieceView(piece: piece, flying: flying)
                }

                // ── 중앙 다크 카드 ───────────────────────
                VStack(spacing: 0) {
                    Spacer()
                    cardView
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .scaleEffect(cardVisible ? 1.0 : 0.68)
                .opacity(cardVisible ? 1.0 : 0)
                .animation(.spring(response: 0.42, dampingFraction: 0.58), value: cardVisible)
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { dismissView() }
            .onAppear {
                pieces = makePieces(in: geo.size)
                Haptic.success()

                // confetti burst (약간 딜레이 후 시작)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation { flying = true }
                }
                // 카드 등장
                withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.08)) {
                    cardVisible = true
                }
                // 프로그레스 바
                withAnimation(.linear(duration: autoDismiss)) {
                    progressDot = 1.0
                }
                // 자동 닫기
                DispatchQueue.main.asyncAfter(deadline: .now() + autoDismiss) {
                    dismissView()
                }
            }
        }
    }

    // MARK: - 다크 카드
    private var cardView: some View {
        VStack(spacing: 16) {

            // 이모지 (스프링 바운스)
            Text(type.celebrationEmoji)
                .font(.system(size: 72))
                .scaleEffect(cardVisible ? 1.0 : 0.3)
                .rotationEffect(.degrees(cardVisible ? 0 : -18))
                .animation(.spring(response: 0.38, dampingFraction: 0.48).delay(0.12), value: cardVisible)

            // 텍스트
            VStack(spacing: 8) {
                Text(type.milestoneTitle)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(type.milestoneSubtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(cardVisible ? 1 : 0)
            .offset(y: cardVisible ? 0 : 12)
            .animation(.easeOut(duration: 0.3).delay(0.2), value: cardVisible)

            // 그룹 도트 + 진행 바
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i < completedGroupCount
                                  ? .white
                                  : Color.white.opacity(0.25))
                            .frame(width: 8, height: 8)
                    }
                }

                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.15)).frame(height: 3)
                        Capsule().fill(Color.white.opacity(0.5))
                            .frame(width: g.size.width * progressDot, height: 3)
                    }
                }
                .frame(height: 3)
            }
            .opacity(cardVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.3).delay(0.28), value: cardVisible)
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color(white: 0.09).opacity(0.96))
        )
        .padding(.horizontal, 52)
    }

    // MARK: - 퇴장
    private func dismissView() {
        withAnimation(.easeIn(duration: 0.22)) {
            cardVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }

    // MARK: - Confetti 생성
    private func makePieces(in size: CGSize) -> [ConfettiPiece] {
        let cx = size.width / 2
        let cy = size.height * 0.38

        return (0..<58).map { _ in
            let isCircle = Int.random(in: 0...3) == 0
            let isOval   = !isCircle && Int.random(in: 0...2) == 0
            let shape: ConfettiPiece.PieceShape = isCircle ? .circle : (isOval ? .oval : .rect)

            let w: CGFloat
            let h: CGFloat
            switch shape {
            case .circle:
                w = CGFloat.random(in: 7...13); h = w
            case .oval:
                w = CGFloat.random(in: 8...14); h = w * CGFloat.random(in: 1.4...2.0)
            case .rect:
                w = CGFloat.random(in: 6...11); h = CGFloat.random(in: 14...24)
            }

            return ConfettiPiece(
                initX:  cx + CGFloat.random(in: -24...24),
                initY:  cy + CGFloat.random(in: -24...24),
                finalX: CGFloat.random(in: 12...(size.width - 12)),
                finalY: CGFloat.random(in: 40...(size.height - 60)),
                finalRotation: Double.random(in: -300...300),
                color: confettiColors.randomElement()!,
                width: w,
                height: h,
                shape: shape,
                delay: Double.random(in: 0...0.28),
                duration: Double.random(in: 0.75...1.3)
            )
        }
    }
}

// MARK: - 개별 Confetti 조각 View
private struct PieceView: View {
    let piece: ConfettiPiece
    let flying: Bool

    var body: some View {
        pieceShape
            .rotationEffect(.degrees(flying ? piece.finalRotation : 0))
            .position(
                x: flying ? piece.finalX : piece.initX,
                y: flying ? piece.finalY : piece.initY
            )
            .opacity(flying ? 0.92 : 0)
            .animation(
                .easeOut(duration: piece.duration).delay(piece.delay),
                value: flying
            )
    }

    @ViewBuilder
    private var pieceShape: some View {
        switch piece.shape {
        case .circle:
            Circle()
                .fill(piece.color)
                .frame(width: piece.width, height: piece.width)
        case .oval:
            Ellipse()
                .fill(piece.color)
                .frame(width: piece.width, height: piece.height)
        case .rect:
            RoundedRectangle(cornerRadius: 2.5)
                .fill(piece.color)
                .frame(width: piece.width, height: piece.height)
        }
    }
}

// MARK: - ItemType 마일스톤 속성
extension ItemType {

    var celebrationEmoji: String {
        switch self {
        case .spark: return "⚡"
        case .flow:  return "🔥"
        case .deep:  return "🎯"
        }
    }

    var milestoneTitle: String {
        switch self {
        case .spark: return "뚝딱 완료!"
        case .flow:  return "착착 완료!"
        case .deep:  return "몰입 완료!"
        }
    }

    var milestoneSubtitle: String {
        switch self {
        case .spark: return "작은 행동들이 쌓였어요\n습관의 씨앗을 심었어요"
        case .flow:  return "9분의 집중이 빛났어요\n이 리듬, 계속 유지해요"
        case .deep:  return "90분 딥워크 달성!\n오늘 최고의 순간이에요"
        }
    }

    var milestoneThemeColor: Color {
        switch self {
        case .spark: return Color(red: 1.0, green: 0.75, blue: 0.0)
        case .flow:  return Color(red: 1.0, green: 0.45, blue: 0.1)
        case .deep:  return Color(red: 0.3, green: 0.6, blue: 1.0)
        }
    }

    var groupIndex: Int {
        switch self {
        case .spark: return 1
        case .flow:  return 2
        case .deep:  return 3
        }
    }
}
