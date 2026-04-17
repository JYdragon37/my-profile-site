import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct NinetyNineEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Provider
struct NinetyNineProvider: TimelineProvider {
    func placeholder(in context: Context) -> NinetyNineEntry {
        NinetyNineEntry(date: Date(), data: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (NinetyNineEntry) -> Void) {
        completion(NinetyNineEntry(date: Date(), data: WidgetData.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NinetyNineEntry>) -> Void) {
        let entry = NinetyNineEntry(date: Date(), data: WidgetData.load())
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Dot Grid View (shared between Small and Medium)
private struct DotGridView: View {
    let completedCount: Int
    let totalCount: Int

    var body: some View {
        VStack(spacing: 5) {
            ForEach(0..<3) { row in
                HStack(spacing: 5) {
                    ForEach(0..<3) { col in
                        let index = row * 3 + col
                        Circle()
                            .fill(index < completedCount
                                  ? Color.white
                                  : Color.white.opacity(0.25))
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
    }
}

// MARK: - Widget Background
private let widgetBackground = LinearGradient(
    colors: [
        Color(red: 0.1, green: 0.1, blue: 0.22),
        Color(red: 0.08, green: 0.08, blue: 0.18)
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: NinetyNineEntry

    var body: some View {
        ZStack {
            // Background handled by containerBackground below
            VStack(spacing: 6) {
                // Title
                Text("99")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.orange)

                // 3×3 dot grid
                DotGridView(
                    completedCount: entry.data.completedCount,
                    totalCount: entry.data.totalCount
                )

                // Count + Streak row
                HStack(spacing: 8) {
                    Text("\(entry.data.completedCount)/\(entry.data.totalCount)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    if entry.data.streak > 0 {
                        Text("🔥\(entry.data.streak)일")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.orange.opacity(0.9))
                    }
                }
            }
            .padding(12)
        }
        .containerBackground(for: .widget) {
            widgetBackground
        }
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: NinetyNineEntry

    var body: some View {
        HStack(spacing: 0) {
            // Left: dot grid + count
            VStack(spacing: 8) {
                Text("99")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.orange)

                DotGridView(
                    completedCount: entry.data.completedCount,
                    totalCount: entry.data.totalCount
                )

                Text("\(entry.data.completedCount)/\(entry.data.totalCount)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                if entry.data.streak > 0 {
                    Text("🔥\(entry.data.streak)일")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.orange.opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1)
                .padding(.vertical, 14)

            // Right: next incomplete items or completion message
            VStack(alignment: .leading, spacing: 6) {
                if entry.data.isSuccess || entry.data.nextItems.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("오늘 완료! 🎉")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    Spacer()
                } else {
                    Text("다음 항목")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .padding(.bottom, 2)

                    ForEach(Array(entry.data.nextItems.prefix(3).enumerated()), id: \.offset) { _, itemTitle in
                        HStack(alignment: .top, spacing: 5) {
                            Text("○")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.white.opacity(0.5))
                            Text(itemTitle)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .lineLimit(1)
                        }
                    }

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .containerBackground(for: .widget) {
            widgetBackground
        }
    }
}

// MARK: - Widget Entry View
struct NinetyNineWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: NinetyNineEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration
@main
struct NinetyNineWidget: Widget {
    let kind: String = "NinetyNineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NinetyNineProvider()) { entry in
            NinetyNineWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("99 챌린지")
        .description("오늘의 99분 챌린지 진행 상황")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
