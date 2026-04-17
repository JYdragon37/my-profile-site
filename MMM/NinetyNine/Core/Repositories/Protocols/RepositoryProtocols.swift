import Foundation

// MARK: - UserRepository Protocol
@MainActor
protocol UserRepositoryProtocol {
    func getProfile() async throws -> UserProfile?
    func saveProfile(_ profile: UserProfile) async throws
}

// MARK: - RoutineRepository Protocol
@MainActor
protocol RoutineRepositoryProtocol {
    func getActiveProject() async throws -> Project?
    func saveProject(_ project: Project) async throws
    func getProjectHistory() async throws -> [Project]
}

// MARK: - RecordRepository Protocol
@MainActor
protocol RecordRepositoryProtocol {
    func getDailyRecord(date: String) async throws -> DailyRecord?
    func saveDailyRecord(_ record: DailyRecord) async throws
    func getMonthlyRecords(yearMonth: String) async throws -> [DailyRecord]  // "YYYY-MM"
    func getAllRecords() async throws -> [DailyRecord]
    func deleteRecord(date: String) async throws
}
