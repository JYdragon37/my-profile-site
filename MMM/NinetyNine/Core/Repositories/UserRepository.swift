import Foundation
import SwiftData
import FirebaseAuth
import FirebaseFirestore

// MARK: - UserRepository
// Firestore 우선, 실패/오프라인 시 SwiftData 폴백
@MainActor
final class UserRepository: UserRepositoryProtocol {

    private let db = Firestore.firestore()
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - 현재 Firebase UID
    private var currentUID: String? {
        Auth.auth().currentUser?.uid
    }

    private var userDocRef: DocumentReference? {
        guard let uid = currentUID else { return nil }
        return db.collection("users").document(uid)
    }

    // MARK: - 익명 로그인 (앱 첫 실행)
    func signInAnonymouslyIfNeeded() async throws {
        if Auth.auth().currentUser == nil {
            try await Auth.auth().signInAnonymously()
        }
    }

    // MARK: - 프로필 조회
    func getProfile() async throws -> UserProfile? {
        // 1. 로컬 SwiftData 먼저
        let localProfiles = try modelContext.fetch(FetchDescriptor<LocalUserProfile>())
        if let local = localProfiles.first {
            // 2. 백그라운드 Firestore 동기화 (무시해도 무방)
            Task { try? await syncProfileFromFirestore() }
            return local.toUserProfile()
        }

        // 3. 로컬 없으면 Firestore에서 fetch
        return try await syncProfileFromFirestore()
    }

    @discardableResult
    private func syncProfileFromFirestore() async throws -> UserProfile? {
        guard let ref = userDocRef else { return nil }
        let snapshot = try await ref.getDocument()
        guard snapshot.exists,
              let profile = try? snapshot.data(as: UserProfile.self)
        else { return nil }

        // SwiftData 업데이트
        let local = LocalUserProfile(from: profile)
        modelContext.insert(local)
        try modelContext.save()
        return profile
    }

    // MARK: - 프로필 저장
    func saveProfile(_ profile: UserProfile) async throws {
        // 1. SwiftData 즉시 저장
        let locals = try modelContext.fetch(FetchDescriptor<LocalUserProfile>())
        if let existing = locals.first {
            existing.nickname = profile.nickname
            existing.activeProjectId = profile.activeProjectId
            existing.lastSyncedAt = Date()
        } else {
            modelContext.insert(LocalUserProfile(from: profile))
        }
        try modelContext.save()

        // 2. Firestore 비동기 업로드
        guard let ref = userDocRef else { return }
        try ref.setData(from: profile, merge: true)
    }
}
