import SwiftUI
import Charts

struct RecordView: View {

    @StateObject private var vm = RecordViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showDetail: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 스트릭
                    StreakBanner(streak: vm.currentStreak)

                    // 이번 달 완료율
                    MonthlyProgressCard(
                        yearMonth: vm.currentYearMonth,
                        rate: vm.monthlyCompletionRate,
                        onPrev: { vm.changeMonth(offset: -1) },
                        onNext: { vm.changeMonth(offset: 1) }
                    )

                    // 개인 리포트
                    PersonalReportCard(weekly: vm.weeklyReport, monthly: vm.monthlyReport)

                    // 달력
                    CalendarGrid(
                        yearMonth: vm.currentYearMonth,
                        records: vm.monthlyRecords,
                        onSelect: { vm.selectDate($0) }
                    )

                    // 소요시간 차트
                    TimeChartCard(records: vm.monthlyRecords)

                    // 포디움
                    if !vm.podiumTop3.isEmpty {
                        PodiumCard(entries: vm.podiumTop3)
                    }

                    // 전체 통계
                    StatsCard(vm: vm)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("기록")
            .sheet(item: $vm.selectedRecord) { record in
                DayDetailView(
                    record: record,
                    routineItems: vm.activeRoutineItemNames,
                    onDelete: { vm.deleteRecord(record) }
                )
                .presentationDetents([.medium, .large])
            }
        }
        .onAppear {
            vm.setup(
                recordRepo: RecordRepository(modelContext: modelContext),
                routineRepo: RoutineRepository(modelContext: modelContext)
            )
        }
    }
}

// MARK: - 개인 리포트 카드

struct PersonalReportCard: View {
    let weekly: WeeklyReport
    let monthly: MonthlyReport
    @State private var selectedTab: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Section title
            Text("나의 리포트")
                .font(.headline)

            // Tab picker
            Picker("기간", selection: $selectedTab) {
                Text("이번 주").tag(0)
                Text("이번 달").tag(1)
            }
            .pickerStyle(.segmented)

            if selectedTab == 0 {
                WeeklyReportView(report: weekly)
            } else {
                MonthlyReportView(report: monthly)
            }
        }
        .padding(Spacing.lg)
        .background(AppColor.bgSecond)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - 주간 리포트

struct WeeklyReportView: View {
    let report: WeeklyReport

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("이번 주 요약")
                .font(.subheadline)
                .foregroundStyle(AppColor.labelSec)

            // Stat pills row
            HStack(spacing: Spacing.sm) {
                StatPill(label: "완료율", value: "\(Int(report.completionRate * 100))%")
                StatPill(label: "총", value: "\(report.totalItemsCompleted)개")
                StatPill(label: "최고", value: "\(report.bestDayCount)개/일")
                StatPill(label: "활동일", value: "\(report.activeDays)일")
            }

            // Type breakdown bar
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("유형별 완주율")
                    .font(.caption)
                    .foregroundStyle(AppColor.labelSec)

                // Horizontal stacked bar
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        let total = report.sparkRate + report.flowRate + report.deepRate
                        let sparkW = total > 0 ? report.sparkRate / total : 1.0 / 3.0
                        let flowW  = total > 0 ? report.flowRate  / total : 1.0 / 3.0
                        let deepW  = total > 0 ? report.deepRate  / total : 1.0 / 3.0

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.orange.opacity(0.7))
                            .frame(width: geo.size.width * sparkW, height: 10)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.blue.opacity(0.5))
                            .frame(width: geo.size.width * flowW, height: 10)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.blue.opacity(0.85))
                            .frame(width: geo.size.width * deepW, height: 10)
                    }
                }
                .frame(height: 10)

                // Legend
                HStack(spacing: Spacing.md) {
                    TypeRateLegend(emoji: "⚡", name: "뚝딱", rate: report.sparkRate)
                    TypeRateLegend(emoji: "🔹", name: "착착", rate: report.flowRate)
                    TypeRateLegend(emoji: "🔵", name: "몰입", rate: report.deepRate)
                }
            }
        }
    }
}

// MARK: - 월간 리포트

struct MonthlyReportView: View {
    let report: MonthlyReport

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("이번 달 요약")
                .font(.subheadline)
                .foregroundStyle(AppColor.labelSec)

            VStack(spacing: Spacing.sm) {
                StatRow(label: "완료율", value: "\(Int(report.completionRate * 100))%")
                StatRow(label: "현재 스트릭", value: "\(report.currentStreak)일")
                StatRow(label: "최장 스트릭", value: "\(report.longestStreak)일")
                StatRow(label: "9/9 완료", value: "\(report.totalChallengesCompleted)회")
                StatRow(label: "이달 최고기록", value: personalBestDisplay)
            }
        }
    }

    private var personalBestDisplay: String {
        guard let sec = report.personalBestSeconds, sec > 0 else { return "-" }
        let m = sec / 60
        let s = sec % 60
        return s > 0 ? "\(m)분 \(s)초" : "\(m)분"
    }
}

// MARK: - 서브 컴포넌트

struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppColor.labelSec)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(AppColor.bgThird)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
    }
}

struct TypeRateLegend: View {
    let emoji: String
    let name: String
    let rate: Double

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(emoji)
                .font(.caption2)
            Text("\(name) \(Int(rate * 100))%")
                .font(.caption2)
                .foregroundStyle(AppColor.labelSec)
        }
    }
}

// MARK: - 스트릭 배너
struct StreakBanner: View {
    let streak: Int
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text("🔥")
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(streak > 0 ? "\(streak)일 연속 중" : "오늘부터 시작해요")
                    .font(.headline)
                if streak > 0 {
                    Text("계속 유지해봐요!")
                        .font(.caption)
                        .foregroundStyle(AppColor.labelSec)
                }
            }
            Spacer()
        }
        .padding(Spacing.lg)
        .cardStyle()
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - 이번 달 완료율
struct MonthlyProgressCard: View {
    let yearMonth: String
    let rate: Double
    let onPrev: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: onPrev) { Image(systemName: "chevron.left") }
                Spacer()
                Text(displayMonth)
                    .font(.headline)
                Spacer()
                Button(action: onNext) { Image(systemName: "chevron.right") }
            }

            HStack {
                Text("이번 달 완료율")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(rate * 100))%")
                    .font(.headline)
            }
            ProgressView(value: rate)
                .tint(.primary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }

    private var displayMonth: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월"
        return f.string(from: yearMonth.toYearMonthDate() ?? Date())
    }
}

// MARK: - 달력 그리드
struct CalendarGrid: View {
    let yearMonth: String
    let records: [DailyRecord]
    let onSelect: (String) -> Void

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["월", "화", "수", "목", "금", "토", "일"]

    var body: some View {
        VStack(spacing: 8) {
            // 요일 헤더
            HStack {
                ForEach(weekdays, id: \.self) { d in
                    Text(d).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
            }
            // 날짜 그리드
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(calendarDays, id: \.self) { dayKey in
                    if dayKey.isEmpty {
                        Color.clear.frame(height: 36)
                    } else {
                        CalendarCell(dateKey: dayKey, record: records.first { $0.date == dayKey }) {
                            onSelect(dayKey)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var calendarDays: [String] {
        guard let date = yearMonth.toYearMonthDate() else { return [] }
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)!
        let firstWeekday = calendar.component(.weekday, from: date)
        // 월요일 시작 (월=2, 일=1)
        let offset = firstWeekday == 1 ? 6 : firstWeekday - 2
        var days = Array(repeating: "", count: offset)
        for day in range {
            let dayStr = String(format: "%02d", day)
            days.append("\(yearMonth)-\(dayStr)")
        }
        return days
    }
}

struct CalendarCell: View {
    let dateKey: String
    let record: DailyRecord?
    let onTap: () -> Void

    var day: String { String(dateKey.suffix(2)) }
    var isToday: Bool { dateKey == Date().recordKey }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(cellColor)
                    .frame(width: 36, height: 36)
                Text(day.hasPrefix("0") ? String(day.dropFirst()) : day)
                    .font(.caption)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(textColor)
            }
        }
        .buttonStyle(.plain)
    }

    private var cellColor: Color {
        if let r = record {
            return r.isSuccess ? .primary : Color(.tertiarySystemFill)
        }
        return isToday ? Color(.secondarySystemFill) : .clear
    }

    private var textColor: Color {
        if record?.isSuccess == true { return Color(.systemBackground) }
        return isToday ? .primary : .secondary
    }
}

// MARK: - 소요시간 차트
struct TimeChartCard: View {
    let records: [DailyRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("소요시간")
                .font(.headline)

            if records.filter({ $0.isSuccess }).isEmpty {
                Text("완료된 기록이 없어요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                // Charts 프레임워크 사용 (iOS 16+)
                Chart(records.filter { $0.isSuccess }, id: \.date) { record in
                    BarMark(
                        x: .value("날짜", String(record.date.suffix(5))),
                        y: .value("분", record.elapsedSeconds / 60)
                    )
                    .foregroundStyle(Color.primary)
                    .cornerRadius(4)
                }
                .frame(height: 120)
                .chartYAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }
}

// MARK: - 포디움 Top 3
struct PodiumCard: View {
    let entries: [PodiumEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🏆 나의 포디움")
                .font(.headline)

            Text("9/9 완료 + 199분 이내 기록 Top 3")
                .font(.caption)
                .foregroundStyle(AppColor.labelSec)

            VStack(spacing: 8) {
                ForEach(entries) { entry in
                    HStack {
                        Text(entry.medal)
                            .font(.title3)
                            .frame(width: 32)
                        Text(entry.display)
                            .font(.headline)
                            .fontWeight(entry.rank == 1 ? .bold : .semibold)
                        Spacer()
                        Text(entry.dateDisplay)
                            .font(.caption)
                            .foregroundStyle(AppColor.labelSec)
                    }
                    if entry.rank < entries.count {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }
}

// MARK: - 전체 통계
struct StatsCard: View {
    @ObservedObject var vm: RecordViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("나의 기록")
                .font(.headline)

            VStack(spacing: 10) {
                StatRow(label: "총 챌린지 완료",  value: "\(vm.totalCompleted)회")
                StatRow(label: "나의 최고",       value: vm.personalBestDisplay)
                StatRow(label: "전체 평균",       value: vm.averageDisplay)
                StatRow(label: "현재 스트릭",     value: "\(vm.currentStreak)일")
                StatRow(label: "최장 스트릭",     value: "\(vm.longestStreak)일")
            }

            Divider()

            Text("유형별 완료율")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                TypeRateRow(type: .spark, rate: vm.sparkCompletionRate)
                TypeRateRow(type: .flow,  rate: vm.flowCompletionRate)
                TypeRateRow(type: .deep,  rate: vm.deepCompletionRate)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }
}

struct StatRow: View {
    let label: String; let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

struct TypeRateRow: View {
    let type: ItemType; let rate: Double
    var body: some View {
        HStack(spacing: 12) {
            Text(type.emoji + " " + type.displayName)
                .font(.subheadline)
                .frame(width: 70, alignment: .leading)
            ProgressView(value: rate)
                .tint(.primary)
            Text("\(Int(rate * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
    }
}

// MARK: - 날짜 상세
struct DayDetailView: View {
    let record: DailyRecord
    let routineItems: [String]  // 추가: 9개 항목 이름 배열 (없으면 빈 배열)
    var onDelete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(spacing: 20) {
            // 헤더
            HStack {
                VStack(alignment: .leading) {
                    Text(displayDate)
                        .font(.headline)
                    Text(record.isSuccess ? "완료 ✅" : "미완료")
                        .font(.subheadline)
                        .foregroundStyle(record.isSuccess ? .green : .secondary)
                }
                Spacer()
                Text(record.elapsedDisplay)
                    .font(.title2)
                    .fontWeight(.thin)
                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .padding(.leading, 12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .confirmationDialog("이 기록을 삭제할까요?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("삭제", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
            }

            Divider()

            // 항목별 상태 (인덱스 기반)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(0..<min(record.itemStatus.count, 9), id: \.self) { i in
                    HStack {
                        Image(systemName: record.itemStatus[i] ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(record.itemStatus[i] ? .green : .secondary)
                        Text(typeLabel(for: i))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(i < routineItems.count ? routineItems[i] : "항목 \(i + 1)")
                            .font(.subheadline)
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    private var displayDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 EEEE"
        return f.string(from: record.date.toDate() ?? Date())
    }

    private func typeLabel(for index: Int) -> String {
        switch index {
        case 0..<3: return "⚡ 뚝딱"
        case 3..<6: return "🔹 착착"
        default:    return "🔵 몰입"
        }
    }
}

// MARK: - DailyRecord Identifiable
extension DailyRecord: Identifiable {
    public var id: String { date }
}

extension String {
    /// "yyyy-MM-dd" 형식의 날짜 문자열을 Date로 변환
    func toDate(format: String = "yyyy-MM-dd") -> Date? {
        let f = DateFormatter()
        f.dateFormat = format
        return f.date(from: self)
    }

    /// "yyyy-MM" 형식의 연월 문자열을 Date로 변환 (월별 통계용)
    func toYearMonthDate() -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f.date(from: self)
    }
}
