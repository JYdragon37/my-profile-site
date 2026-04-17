import Foundation
import SwiftData

// Design Ref: §2.1 — 검색 상태 관리. 디바운스 0.5초 적용.
@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [VideoResult] = []
    @Published var state: SearchState = .idle

    private var debounceTask: Task<Void, Never>?

    enum SearchState: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(String)
    }

    // 검색어 변경 시 디바운스 후 실행
    // Design Ref: §7 — 0.5초 디바운스로 과도한 API 호출 방지
    func onQueryChanged() {
        debounceTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            state = .idle
            return
        }

        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }

    func performSearch() async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }

        state = .loading
        do {
            let found = try await SearchService.shared.search(query: q)
            results = found
            state = found.isEmpty ? .empty : .loaded
        } catch {
            state = .error(errorMessage(from: error))
        }
    }

    private func errorMessage(from error: Error) -> String {
        // Design Ref: §4.2 — 에러 케이스별 메시지
        let desc = error.localizedDescription
        if desc.contains("offline") || desc.contains("network") {
            return "네트워크를 확인하세요"
        }
        if desc.contains("429") { return "잠시 후 다시 시도해주세요" }
        return "검색 중 오류가 발생했습니다"
    }
}
