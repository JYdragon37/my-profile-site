import SwiftUI

struct RoutineSetupView: View {
    @Binding var weekdayRoutine: Routine
    @Binding var weekendRoutine: Routine
    let onTemplateSelected: (String) -> Void
    let onComplete: () -> Void

    @State private var tutorialStep: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            VStack(spacing: 8) {
                Text("나의 일상습관 만들기")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.top, 48)
            .padding(.bottom, 16)

            // 튜토리얼 배너
            if tutorialStep < 3 {
                TutorialBanner(tutorialStep: tutorialStep) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        tutorialStep += 1
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // 루틴 아이템 편집
            ScrollView {
                VStack(spacing: 24) {
                    RoutineSection(
                        type: .spark,
                        items: weekdayRoutine.spark,
                        onEdit: { i, val in weekdayRoutine.spark[i] = val }
                    )
                    .opacity(tutorialStep == 0 || tutorialStep >= 3 ? 1.0 : 0.35)
                    .animation(.easeInOut(duration: 0.3), value: tutorialStep)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(tutorialStep == 0 ? 0.4 : 0), lineWidth: 1.5))

                    RoutineSection(
                        type: .flow,
                        items: weekdayRoutine.flow,
                        onEdit: { i, val in weekdayRoutine.flow[i] = val }
                    )
                    .opacity(tutorialStep == 1 || tutorialStep >= 3 ? 1.0 : 0.35)
                    .animation(.easeInOut(duration: 0.3), value: tutorialStep)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(tutorialStep == 1 ? 0.4 : 0), lineWidth: 1.5))

                    RoutineSection(
                        type: .deep,
                        items: weekdayRoutine.deep,
                        onEdit: { i, val in weekdayRoutine.deep[i] = val }
                    )
                    .opacity(tutorialStep == 2 || tutorialStep >= 3 ? 1.0 : 0.35)
                    .animation(.easeInOut(duration: 0.3), value: tutorialStep)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(tutorialStep == 2 ? 0.4 : 0), lineWidth: 1.5))
                }
                .padding(20)
            }

            // 시작 버튼
            let filledCount = countFilledItems()
            VStack(spacing: 8) {
                if filledCount < 9 {
                    Text("\(filledCount)/9개 입력됨 — 모두 채워야 시작할 수 있어요")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button(action: {
                    weekendRoutine = weekdayRoutine
                    onComplete()
                }) {
                    Text("챌린지 시작하기! 🚀")
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: filledCount >= 9))
                .disabled(filledCount < 9)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private func countFilledItems() -> Int {
        let all = weekdayRoutine.spark + weekdayRoutine.flow + weekdayRoutine.deep
        return all.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
    }
}

// MARK: - 루틴 섹션
struct RoutineSection: View {
    let type: ItemType
    let items: [String]
    let onEdit: (Int, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(type.emoji)
                Text(type.displayName)
                    .font(.headline)
                Text(durationLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(items.indices, id: \.self) { i in
                RoutineItemField(
                    index: i + 1,
                    text: items[i],
                    placeholder: placeholder(for: type, index: i),
                    onChanged: { val in onEdit(i, val) }
                )
            }
        }
    }

    private var durationLabel: String {
        switch type {
        case .spark: return "(3초)"
        case .flow:  return "(3분)"
        case .deep:  return "(30분)"
        }
    }

    private func placeholder(for type: ItemType, index: Int) -> String {
        switch type {
        case .spark: return ["💧 물 한 잔 마시기", "🎯 오늘 하루 의도 정하기", "🪟 창문 열기"][safe: index] ?? ""
        case .flow:  return ["🧘 스트레칭", "✍️ 감사한 것 3가지", "📋 오늘 우선순위 정하기"][safe: index] ?? ""
        case .deep:  return ["📚 독서", "🎧 영어 공부", "🔨 나만의 프로젝트"][safe: index] ?? ""
        }
    }
}

// MARK: - 루틴 항목 입력 필드
struct RoutineItemField: View {
    let index: Int
    let text: String
    let placeholder: String
    let onChanged: (String) -> Void

    @State private var localText: String = ""

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            TextField(placeholder, text: $localText)
                .font(.subheadline)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onChange(of: localText) { _, val in onChanged(val) }
        }
        .onAppear { localText = text }
    }
}

// MARK: - 튜토리얼 배너
struct TutorialBanner: View {
    let tutorialStep: Int
    let onNext: () -> Void

    private var bannerInfo: (emoji: String, title: String, body: String) {
        switch tutorialStep {
        case 0:
            return ("⚡", "뚝딱 — 3초짜리", "딱 3초면 되는 간단한 일을 적어요")
        case 1:
            return ("🔹", "착착 — 3분짜리", "3분만 집중하면 충분한 일이에요")
        default:
            return ("🔵", "몰입 — 30분짜리", "30분 온전히 집중할 일이에요")
        }
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text(bannerInfo.emoji)
                .font(.title3)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(bannerInfo.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.blue)
                Text(bannerInfo.body)
                    .font(.caption)
                    .foregroundStyle(AppColor.labelSec)
            }

            Spacer()

            Button(action: onNext) {
                Text("알겠어요")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.blue)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.blue.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: tutorialStep)
    }
}

// MARK: - Safe Array Subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
