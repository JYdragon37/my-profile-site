import Foundation
import Combine
import YouTubePlayerKit

// Design Ref: §5 — Player 상태 관리. 현재 구간 인덱스와 seekTo 로직 담당.
@MainActor
final class PlayerViewModel: ObservableObject {
    // MARK: - Published State
    @Published var currentSegmentIndex: Int = 0
    @Published var isPlaying: Bool = false

    // MARK: - Data
    let videoResult: VideoResult
    let player: YouTubePlayer

    // Plan SC: 타임스탬프 정확도 ± 0.5초 — startTime 기준으로 seekTo
    var currentSegment: TranscriptSegment? {
        guard videoResult.segments.indices.contains(currentSegmentIndex) else { return nil }
        return videoResult.segments[currentSegmentIndex]
    }

    var hasPrevious: Bool { currentSegmentIndex > 0 }
    var hasNext: Bool { currentSegmentIndex < videoResult.segments.count - 1 }

    // MARK: - Init
    init(videoResult: VideoResult, startSegmentIndex: Int = 0) {
        self.videoResult = videoResult
        self.currentSegmentIndex = startSegmentIndex

        // Design Ref: §5 — startTime으로 영상 진입. YouTubePlayerKit은 Int 전달.
        let startTime = videoResult.segments[safe: startSegmentIndex]?.startTimeInt ?? 0
        self.player = YouTubePlayer(
            source: .video(id: videoResult.id),
            configuration: .init(
                autoPlay: true,
                startTime: Measurement(value: Double(startTime), unit: .seconds),
                playInline: true,
                showControls: true
            )
        )
    }

    // MARK: - Navigation
    func goToPrevious() {
        guard hasPrevious else { return }
        currentSegmentIndex -= 1
        seekToCurrent()
    }

    func goToNext() {
        guard hasNext else { return }
        currentSegmentIndex += 1
        seekToCurrent()
    }

    func seekToCurrent() {
        guard let segment = currentSegment else { return }
        Task {
            // Design Ref: §5 — seek(to:allowSeekAhead:) async/await 방식
            try? await player.seek(to: Measurement(value: segment.startTime, unit: .seconds), allowSeekAhead: true)
        }
    }
}

// MARK: - Safe Array Access
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
