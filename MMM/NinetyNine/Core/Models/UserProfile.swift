import Foundation
import SwiftData

// MARK: - Firestore 모델 (Codable)
struct UserProfile: Codable {
    var id: String
    var nickname: String
    var createdAt: Date
    var activeProjectId: String?
}

// MARK: - SwiftData 로컬 캐시 모델
@Model
final class LocalUserProfile {
    var id: String
    var nickname: String
    var createdAt: Date
    var activeProjectId: String?
    var lastSyncedAt: Date?

    init(from profile: UserProfile) {
        self.id = profile.id
        self.nickname = profile.nickname
        self.createdAt = profile.createdAt
        self.activeProjectId = profile.activeProjectId
        self.lastSyncedAt = Date()
    }

    func toUserProfile() -> UserProfile {
        UserProfile(
            id: id,
            nickname: nickname,
            createdAt: createdAt,
            activeProjectId: activeProjectId
        )
    }
}
