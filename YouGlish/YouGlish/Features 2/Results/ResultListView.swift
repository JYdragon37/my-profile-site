import SwiftUI

// Design Ref: §2.1 — 검색 결과 목록. 영상 선택 시 PlayerView로 이동.
struct ResultListView: View {
    let results: [VideoResult]
    let query: String

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(results) { result in
                    NavigationLink {
                        PlayerView(videoResult: result, startSegmentIndex: 0)
                    } label: {
                        VideoResultCard(result: result, query: query)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}
