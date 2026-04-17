import SwiftUI

struct OnboardingView: View {

    @StateObject private var vm: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext

    init() {
        _vm = StateObject(wrappedValue: OnboardingViewModel(
            userRepository: UserRepository(modelContext: ModelContextProvider.shared),
            routineRepository: RoutineRepository(modelContext: ModelContextProvider.shared)
        ))
    }

    var body: some View {
        ZStack {
            AppColor.bg.ignoresSafeArea()

            // 슬라이드 전환에 애니메이션 적용
            Group {
                switch vm.currentStep {
                case .slide1: ConceptSlideView(slide: .empathy1, onNext: vm.nextStep)
                case .slide2: ConceptSlideView(slide: .empathy2, onNext: vm.nextStep)
                case .slide3: ConceptSlideView(slide: .identity, onNext: vm.nextStep)
                case .slide4: ConceptSlideView(slide: .reveal, onNext: vm.nextStep)
                case .nickname: NicknameInputView(nickname: $vm.nickname, onNext: vm.nextStep)
                case .modeSelection:
                    ModeSelectionView(
                        onMorning: { vm.selectMode("morning") },
                        onGeneral: { vm.selectMode("general") }
                    )
                case .alarmSetup: OnboardingAlarmView(onSetup: vm.nextStep, onSkip: vm.skipAlarmSetup)
                case .routineSetup:
                    RoutineSetupView(
                        weekdayRoutine: $vm.weekdayRoutine,
                        weekendRoutine: $vm.weekendRoutine,
                        onTemplateSelected: vm.loadTemplate,
                        onComplete: vm.nextStep  // 권한 설정 페이지로 이동
                    )
                case .permissionSetup:
                    OnboardingPermissionsView(
                        projectName: "일상습관",
                        projectEmoji: "⚡",
                        projectColorHex: "#4A9EFF",
                        routineSummary: (
                            spark: vm.weekdayRoutine.spark.filter { !$0.isEmpty }.prefix(2).joined(separator: " · "),
                            flow:  vm.weekdayRoutine.flow.filter  { !$0.isEmpty }.prefix(2).joined(separator: " · "),
                            deep:  vm.weekdayRoutine.deep.filter  { !$0.isEmpty }.prefix(2).joined(separator: " · ")
                        ),
                        onNext: vm.completeOnboarding,
                        onBack: vm.previousStep
                    )
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.3), value: vm.currentStep)

            // 상단 뒤로가기 버튼 + 단계 진행 도트 (slide1 아닐 때만)
            if vm.currentStep != .slide1 {
                VStack {
                    HStack {
                        Button(action: vm.previousStep) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AppColor.labelSec)
                                .padding(Spacing.md)
                        }

                        Spacer()

                        // Step progress dots
                        HStack(spacing: 6) {
                            ForEach(OnboardingViewModel.OnboardingStep.allCases, id: \.self) { step in
                                Circle()
                                    .fill(step == vm.currentStep
                                          ? AppColor.primary
                                          : AppColor.labelSec.opacity(0.3))
                                    .frame(width: step == vm.currentStep ? 8 : 6,
                                           height: step == vm.currentStep ? 8 : 6)
                                    .animation(.spring(duration: 0.25), value: vm.currentStep)
                            }
                        }
                        .padding(.trailing, Spacing.xl)
                    }
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
            }

            // 로딩 오버레이
            if vm.isLoading {
                LoadingOverlay(message: vm.loadingMessage)
            }
        }
        .alert("설정 중 문제가 발생했어요", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("재시도") { vm.retryOnboarding() }
            Button("나중에", role: .cancel) { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }
}
