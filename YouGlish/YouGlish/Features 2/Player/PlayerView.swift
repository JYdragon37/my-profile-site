import SwiftUI
import YouTubePlayerKit

// Design Ref: §2.1 — PlayerView: 영상 재생 + 자막 하이라이트 + 이전/다음 이동
struct PlayerView: View {
    @StateObject private var viewModel: PlayerViewModel

    init(videoResult: VideoResult, startSegmentIndex: Int = 0) {
        _viewModel = StateObject(wrappedValue: PlayerViewModel(
            videoResult: videoResult,
            startSegmentIndex: startSegmentIndex
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── 유튜브 플레이어 ──────────────────────────────────────────
            YouTubePlayerView(viewModel.player)
                .frame(height: 220)
                .background(Color.black)

            // ── 영상 제목 + 채널 ─────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.videoResult.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(viewModel.videoResult.channelName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // ── 구간 텍스트 (하이라이트) ─────────────────────────────────
            if let segment = viewModel.currentSegment {
                SegmentTextView(
                    text: segment.text,
                    highlight: segment.matchWord
                )
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
            }

            Divider()

            // ── 이전 / 구간 카운터 / 다음 ────────────────────────────────
            HStack {
                Button(action: viewModel.goToPrevious) {
                    Label("이전", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .disabled(!viewModel.hasPrevious)

                Spacer()

                Text("\(viewModel.currentSegmentIndex + 1) / \(viewModel.videoResult.segments.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: viewModel.goToNext) {
                    Label("다음", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .disabled(!viewModel.hasNext)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)

            Spacer()
        }
        .navigationTitle(viewModel.videoResult.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 자막 텍스트 하이라이트 뷰
// Design Ref: §2.1 — 검색어를 굵게 강조 표시
struct SegmentTextView: View {
    let text: String
    let highlight: String

    var body: some View {
        // 대소문자 무시하고 검색어 위치 찾아 AttributedString으로 강조
        Text(attributedText)
            .font(.body)
    }

    private var attributedText: AttributedString {
        var attributed = AttributedString(text)
        let lowercasedText = text.lowercased()
        let lowercasedHighlight = highlight.lowercased()

        var searchRange = lowercasedText.startIndex..<lowercasedText.endIndex
        while let range = lowercasedText.range(of: lowercasedHighlight, range: searchRange) {
            // 같은 위치의 AttributedString range로 변환
            if let attrRange = Range(range, in: attributed) {
                attributed[attrRange].font = .body.bold()
                attributed[attrRange].foregroundColor = .blue
            }
            searchRange = range.upperBound..<lowercasedText.endIndex
        }
        return attributed
    }
}

// MARK: - Preview (하드코딩 데이터로 seekTo 검증용)
#Preview {
    NavigationStack {
        PlayerView(
            videoResult: VideoResult(
                id: "dQw4w9WgXcQ",            // Rick Astley - Never Gonna Give You Up
                title: "Never Gonna Give You Up",
                channelName: "Rick Astley",
                thumbnailURL: "https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
                segments: [
                    TranscriptSegment(
                        id: UUID(),
                        text: "never gonna give you up",
                        startTime: 43.0,        // ← 이 시간부터 재생되는지 검증
                        duration: 2.5,
                        matchWord: "never"
                    ),
                    TranscriptSegment(
                        id: UUID(),
                        text: "never gonna let you down",
                        startTime: 46.0,
                        duration: 2.5,
                        matchWord: "never"
                    ),
                    TranscriptSegment(
                        id: UUID(),
                        text: "never gonna run around and desert you",
                        startTime: 49.0,
                        duration: 3.0,
                        matchWord: "never"
                    )
                ]
            ),
            startSegmentIndex: 0
        )
    }
}
