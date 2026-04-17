import Foundation
import SwiftData
import StoreKit

@MainActor
final class SettingsViewModel: ObservableObject {

    @Published var projects: [Project] = []
    @Published var activeProject: Project?
    @Published var isShowingNicknameEdit: Bool = false
    @Published var isShowingRoutineEdit: Bool = false
    @Published var completionNotificationEnabled: Bool = true

    private var routineRepository: RoutineRepositoryProtocol?

    func setup(modelContext: ModelContext) {
        routineRepository = RoutineRepository(modelContext: modelContext)
        loadProjects()
        checkAndActivateScheduledProject()
    }

    // MARK: - 프로젝트 로드
    func loadProjects() {
        Task {
            let history = (try? await routineRepository?.getProjectHistory()) ?? []
            let active = try? await routineRepository?.getActiveProject()
            // @MainActor 클래스이므로 직접 할당 가능
            self.projects = history
            self.activeProject = active
        }
    }

    // MARK: - 루틴 저장 (덮어쓰기)
    func saveRoutine(_ project: Project, asNewVersion: Bool) {
        Task {
            var updated = project
            if asNewVersion {
                updated.version = (activeProject?.version ?? 1) + 1
            }
            try? await routineRepository?.saveProject(updated)
            await MainActor.run { self.loadProjects() }
        }
    }

    // MARK: - 새 버전으로 저장
    func saveNewVersion(_ project: Project, name: String, startDate: Date) {
        Task {
            var newProject = project
            newProject.id = UUID().uuidString
            newProject.name = name
            newProject.version = (activeProject?.version ?? 1) + 1
            newProject.startDate = startDate
            newProject.endDate = nil
            newProject.endDateSetBy = nil

            // 이전 active 루틴의 endDate 자동 설정 (시작일 - 1일)
            if var current = activeProject {
                let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate
                current.endDate = dayBefore
                current.endDateSetBy = "auto"
                try? await routineRepository?.saveProject(current)
            }

            try? await routineRepository?.saveProject(newProject)
            self.loadProjects()
        }
    }

    // MARK: - 예약 버전 취소
    func cancelScheduledVersion(_ project: Project) {
        Task {
            // TODO: deleteProject 구현 필요
            if var prevActive = projects.first(where: { $0.status == .active }) {
                if prevActive.endDateSetBy == "auto" {
                    prevActive.endDate = nil
                    prevActive.endDateSetBy = nil
                    try? await routineRepository?.saveProject(prevActive)
                }
            }
            self.loadProjects()
        }
    }

    // MARK: - scheduled → active 자동 전환 체크
    func checkAndActivateScheduledProject() {
        Task {
            let all = (try? await routineRepository?.getProjectHistory()) ?? []
            let today = Calendar.current.startOfDay(for: Date())
            for project in all {
                let start = Calendar.current.startOfDay(for: project.startDate)
                if start <= today && project.status == .scheduled { break }
            }
            self.loadProjects()
        }
    }

    // MARK: - 완료율 계산 (stub)
    func completionRate(for project: Project) -> Double {
        // TODO: DailyRecord 기반 실제 완료율 계산 구현
        return 0
    }

    // MARK: - 앱 리뷰 요청
    func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    // MARK: - 문의 메일
    func openSupport() {
        // TODO: 지원 이메일 주소 설정
        // let email = "support@yourapp.com"
        // UIApplication.shared.open(URL(string: "mailto:\(email)")!)
    }
}
