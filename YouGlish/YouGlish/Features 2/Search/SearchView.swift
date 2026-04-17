import SwiftUI
import SwiftData

// Design Ref: §2.1 — 홈 화면. 검색창 + 최근 검색어 + 결과 목록.
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Query(sort: \RecentSearch.searchedAt, order: .reverse) private var recentSearches: [RecentSearch]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── 검색창 ───────────────────────────────────────────────
                searchBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                Divider()

                // ── 콘텐츠 영역 ───────────────────────────────────────────
                Group {
                    switch viewModel.state {
                    case .idle:
                        recentSearchList
                    case .loading:
                        loadingView
                    case .loaded:
                        ResultListView(results: viewModel.results, query: viewModel.query)
                    case .empty:
                        emptyView
                    case .error(let msg):
                        errorView(msg)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: viewModel.state)
            }
            .navigationTitle("YouGlish")
            .navigationBarTitleDisplayMode(.large)
            // 검색 완료 시 최근 검색어 저장
            .onChange(of: viewModel.state) { _, newState in
                if case .loaded = newState { saveRecentSearch(viewModel.query) }
            }
        }
    }

    // MARK: - 검색창
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("단어를 입력하세요 (예: serendipity)", text: $viewModel.query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit { Task { await viewModel.performSearch() } }
            if !viewModel.query.isEmpty {
                Button { viewModel.query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(11)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: viewModel.query) { viewModel.onQueryChanged() }
    }

    // MARK: - 최근 검색어
    private var recentSearchList: some View {
        Group {
            if recentSearches.isEmpty {
                ContentUnavailableView(
                    "검색어를 입력하세요",
                    systemImage: "magnifyingglass",
                    description: Text("단어가 발음된 유튜브 영상을 찾아드립니다")
                )
            } else {
                List {
                    Section("최근 검색") {
                        ForEach(recentSearches.prefix(10)) { item in
                            Button {
                                viewModel.query = item.query
                                Task { await viewModel.performSearch() }
                            } label: {
                                Label(item.query, systemImage: "clock")
                            }
                            .foregroundStyle(.primary)
                        }
                        .onDelete { offsets in
                            offsets.map { recentSearches[$0] }.forEach { modelContext.delete($0) }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - 로딩
    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
            Text("검색 중...").font(.caption).foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - 결과 없음
    private var emptyView: some View {
        ContentUnavailableView(
            "결과 없음",
            systemImage: "film.slash",
            description: Text("'\(viewModel.query)'가 포함된 영어 영상을 찾지 못했습니다")
        )
    }

    // MARK: - 에러
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundStyle(.orange)
            Text(message).multilineTextAlignment(.center)
            Button("다시 시도") { Task { await viewModel.performSearch() } }
                .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }

    // MARK: - 검색 실행 시 최근 검색어 저장
    // SearchViewModel.performSearch 호출 후 실행되도록 onChange로 연결
    private func saveRecentSearch(_ query: String) {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        // 중복 제거
        if let existing = recentSearches.first(where: { $0.query == q }) {
            existing.searchedAt = Date()
        } else {
            modelContext.insert(RecentSearch(query: q))
        }
    }
}

#Preview {
    SearchView()
        .modelContainer(for: RecentSearch.self, inMemory: true)
}
