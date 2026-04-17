import Foundation
import SwiftData
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class RoutineRepository: RoutineRepositoryProtocol {

    private let db = Firestore.firestore()
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    private var uid: String? { Auth.auth().currentUser?.uid }

    // MARK: - 활성 프로젝트 조회
    func getActiveProject() async throws -> Project? {
        let locals = try modelContext.fetch(FetchDescriptor<LocalProject>())
        if let local = locals.last, let project = local.toProject() {
            Task { try? await syncFromFirestore() }
            return project
        }
        return try await syncFromFirestore()
    }

    @discardableResult
    private func syncFromFirestore() async throws -> Project? {
        guard let uid else { return nil }
        let snapshot = try await db
            .collection("users").document(uid)
            .collection("projects")
            .order(by: "createdAt", descending: true)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first,
              let project = try? doc.data(as: Project.self)
        else { return nil }

        modelContext.insert(LocalProject(from: project))
        try modelContext.save()
        return project
    }

    // MARK: - 프로젝트 저장
    func saveProject(_ project: Project) async throws {
        // SwiftData 즉시
        modelContext.insert(LocalProject(from: project))
        try modelContext.save()

        // Firestore 비동기
        guard let uid else { return }
        try db.collection("users").document(uid)
            .collection("projects").document(project.id)
            .setData(from: project)
    }

    // MARK: - 버전 히스토리 조회
    func getProjectHistory() async throws -> [Project] {
        let locals = try modelContext.fetch(FetchDescriptor<LocalProject>())
        return locals.compactMap { $0.toProject() }
                     .sorted { $0.version > $1.version }
    }
}
