import Foundation
import SwiftData
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class RecordRepository: RecordRepositoryProtocol {

    private let db = Firestore.firestore()
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    private var uid: String? { Auth.auth().currentUser?.uid }

    // MARK: - 특정 날짜 기록 조회
    func getDailyRecord(date: String) async throws -> DailyRecord? {
        let descriptor = FetchDescriptor<LocalDailyRecord>(
            predicate: #Predicate { $0.date == date }
        )
        if let local = try modelContext.fetch(descriptor).first {
            return local.toDailyRecord()
        }
        // Firestore fallback
        guard let uid else { return nil }
        let doc = try await db.collection("users").document(uid)
            .collection("records").document(date).getDocument()
        guard doc.exists, let record = try? doc.data(as: DailyRecord.self) else { return nil }
        modelContext.insert(LocalDailyRecord(from: record))
        try modelContext.save()
        return record
    }

    // MARK: - 기록 저장
    func saveDailyRecord(_ record: DailyRecord) async throws {
        // SwiftData 즉시
        let descriptor = FetchDescriptor<LocalDailyRecord>(
            predicate: #Predicate { $0.date == record.date }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.completedCount = record.completedCount
            existing.elapsedSeconds = record.elapsedSeconds
            existing.isSuccess = record.isSuccess
            existing.itemStatusJSON = (try? JSONEncoder().encode(record.itemStatus)) ?? Data()
            existing.lastSyncedAt = Date()
        } else {
            modelContext.insert(LocalDailyRecord(from: record))
        }
        try modelContext.save()

        // Firestore 비동기
        guard let uid else { return }
        try db.collection("users").document(uid)
            .collection("records").document(record.date)
            .setData(from: record)
    }

    // MARK: - 월별 기록 조회 (달력용)
    func getMonthlyRecords(yearMonth: String) async throws -> [DailyRecord] {
        let lowerBound = "\(yearMonth)-01"
        let upperBound = "\(yearMonth)-99"
        let descriptor = FetchDescriptor<LocalDailyRecord>(
            predicate: #Predicate { $0.date >= lowerBound && $0.date <= upperBound }
        )
        let locals = try modelContext.fetch(descriptor)
        if !locals.isEmpty {
            return locals.map { $0.toDailyRecord() }
        }
        // Firestore에서 월별 fetch
        guard let uid else { return [] }
        // 다음 달 첫날을 upper bound으로 사용해 월말 날짜 오류 방지
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let nextMonthBound: String
        if let date = dateFormatter.date(from: yearMonth),
           let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: date) {
            nextMonthBound = dateFormatter.string(from: nextMonth) + "-01"
        } else {
            nextMonthBound = "\(yearMonth)-31"
        }
        let snapshot = try await db.collection("users").document(uid)
            .collection("records")
            .whereField("date", isGreaterThanOrEqualTo: "\(yearMonth)-01")
            .whereField("date", isLessThan: nextMonthBound)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: DailyRecord.self) }
    }

    // MARK: - 전체 기록 (통계용)
    func getAllRecords() async throws -> [DailyRecord] {
        let locals = try modelContext.fetch(FetchDescriptor<LocalDailyRecord>())
        return locals.map { $0.toDailyRecord() }.sorted { $0.date > $1.date }
    }

    // MARK: - 기록 삭제
    func deleteRecord(date: String) async throws {
        let descriptor = FetchDescriptor<LocalDailyRecord>(
            predicate: #Predicate { $0.date == date }
        )
        if let local = try modelContext.fetch(descriptor).first {
            modelContext.delete(local)
            try modelContext.save()
        }
        guard let uid else { return }
        try await db.collection("users").document(uid)
            .collection("records").document(date).delete()
    }
}
