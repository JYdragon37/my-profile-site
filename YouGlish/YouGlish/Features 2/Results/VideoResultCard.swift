import SwiftUI

// Design Ref: §2.1 — 검색 결과 카드: 썸네일 + 제목 + 해당 구간 텍스트
struct VideoResultCard: View {
    let result: VideoResult
    let query: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 썸네일
            AsyncImage(url: result.thumbnailURL_URL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(.systemGray5)
            }
            .frame(width: 120, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                // 영상 제목
                Text(result.title)
                    .font(.subheadline).fontWeight(.medium)
                    .lineLimit(2)

                // 채널명
                Text(result.channelName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // 첫 번째 구간 미리보기
                if let first = result.segments.first {
                    Text(highlightedText(first.text, keyword: query))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }

                // 구간 수 배지
                if result.segments.count > 1 {
                    Text("\(result.segments.count)개 구간")
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    // 검색어 하이라이트 (AttributedString)
    private func highlightedText(_ text: String, keyword: String) -> AttributedString {
        var attr = AttributedString(text)
        let lower = text.lowercased()
        let lowerKw = keyword.lowercased()
        var range = lower.startIndex..<lower.endIndex
        while let found = lower.range(of: lowerKw, range: range) {
            if let attrRange = Range(found, in: attr) {
                attr[attrRange].foregroundColor = .blue
                attr[attrRange].font = .caption.bold()
            }
            range = found.upperBound..<lower.endIndex
        }
        return attr
    }
}
