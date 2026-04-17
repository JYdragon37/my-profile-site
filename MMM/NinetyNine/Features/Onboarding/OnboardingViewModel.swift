import Foundation
import SwiftUI
import SwiftData
import FirebaseAuth

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - State (AppStorage로 앱 종료 시에도 유지)
    @AppStorage("onboarding_step") private var savedStep: Int = 0
    @AppStorage("onboarding_nickname") var nickname: String = ""
    @AppStorage("onboarding_template") private var savedTemplate: String = ""

    @Published var currentStep: OnboardingStep = .slide1
    @Published var selectedTemplate: String = Config.defaultTemplateID
    @Published var weekdayRoutine: Routine = Routine.defaultTemplate
    @Published var weekendRoutine: Routine = Routine.defaultTemplate
    @Published var isLoading: Bool = false
    @Published var loadingMessage: String = "설정 중..."
    @Published var errorMessage: String?

    enum OnboardingStep: Int, CaseIterable {
        case slide1 = 0      // 공감1
        case slide2          // 공감2
        case slide3          // 아이덴티티
        case slide4          // 리빌
        case nickname        // 닉네임 입력
        case modeSelection   // 모드 선택
        case alarmSetup      // 알람 설정
        case routineSetup    // 루틴 세팅
        case permissionSetup // 권한 + 알림 설정 (마지막)
    }

    // MARK: - Dependencies
    private let userRepository: UserRepositoryProtocol
    private let routineRepository: RoutineRepositoryProtocol
    private let analytics = AnalyticsService.shared

    init(userRepository: UserRepositoryProtocol, routineRepository: RoutineRepositoryProtocol) {
        self.userRepository = userRepository
        self.routineRepository = routineRepository
        // 이전 세션 진행 상황 복원
        if let step = OnboardingStep(rawValue: savedStep) {
            currentStep = step
        }
    }

    // MARK: - Navigation
    func nextStep() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            completeOnboarding()
            return
        }
        withAnimation { currentStep = next }
        savedStep = next.rawValue  // 진행 상황 영속 저장
    }

    func previousStep() {
        guard currentStep.rawValue > 0,
              let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation { currentStep = prev }
        savedStep = prev.rawValue
    }

    func skipAlarmSetup() {
        analytics.log(.onboardingAlarmSkipped)
        withAnimation { currentStep = .routineSetup }
    }

    func selectMode(_ mode: String) {
        UserDefaults.standard.set(mode, forKey: "selectedMode")
        if mode == "morning" {
            withAnimation { currentStep = .alarmSetup }
        } else {
            withAnimation { currentStep = .routineSetup }
        }
    }

    // MARK: - 루틴 템플릿 선택
    func loadTemplate(_ templateID: String) {
        guard let templates = loadTemplatesFromBundle(),
              let template = templates.first(where: { $0.id == templateID })
        else { return }
        selectedTemplate = templateID
        weekdayRoutine = Routine(
            spark: template.weekday.spark,
            flow: template.weekday.flow,
            deep: template.weekday.deep
        )
        weekendRoutine = Routine(
            spark: template.weekend.spark,
            flow: template.weekend.flow,
            deep: template.weekend.deep
        )
    }

    private func loadTemplatesFromBundle() -> [RoutineTemplate]? {
        guard let url = Bundle.main.url(forResource: "RoutineTemplates", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode([RoutineTemplate].self, from: data)
    }

    // MARK: - 재시도
    func retryOnboarding() {
        errorMessage = nil
        completeOnboarding()
    }

    // MARK: - 온보딩 완료
    func completeOnboarding() {
        Task {
            isLoading = true
            loadingMessage = "프로필 저장 중..."
            do {
                // 1. 익명 로그인
                let repo = userRepository as? UserRepository
                try await repo?.signInAnonymouslyIfNeeded()

                // 2. 유저 프로필 저장
                guard let uid = Auth.auth().currentUser?.uid else { return }
                let profile = UserProfile(
                    id: uid,
                    nickname: nickname.trimmingCharacters(in: .whitespaces),
                    createdAt: Date(),
                    activeProjectId: nil
                )
                try await userRepository.saveProfile(profile)

                // 3. 첫 프로젝트 저장
                var project = Project.new(id: UUID().uuidString)
                project.weekdayRoutine = weekdayRoutine
                project.weekendRoutine = weekendRoutine
                try await routineRepository.saveProject(project)

                // 4. Analytics
                analytics.log(.onboardingCompleted)

                // 5. 온보딩 완료 플래그
                await MainActor.run {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "설정 중 오류가 발생했습니다. 다시 시도해주세요."
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - RoutineTemplate (JSON 파싱용)
struct RoutineTemplate: Decodable {
    let id: String
    let name: String
    let weekday: RoutineData
    let weekend: RoutineData

    struct RoutineData: Decodable {
        let spark: [String]
        let flow: [String]
        let deep: [String]
    }
}
