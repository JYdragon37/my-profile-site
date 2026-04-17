import SwiftUI
import Charts

// MARK: - 기록 탭 메인
struct RecordView: View {

    @StateObject private var vm = RecordViewModel()
    @ObservedObject private var badgeService = BadgeService.shared
    @Environment(\.modelContext) private var modelContext
    @State private var detailTab: Int = 0   // 0=통계 1=차트 2=뱃지

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // ── 월 네비게이션 + 요약 ─────────────────
                    monthHeader

                    // ── 뱃지 진행 카드 ───────────────────────
                    BadgeProgressCard(
                        badges: badgeService.badges,
                        nextProgress: vm.nextBadgeProgress
                    )
                    .padding(.horizontal, 20)

                    // ── 달력 (핵심) ──────────────────────────
                    CalendarGrid(
                        yearMonth: vm.currentYearMonth,
                        records: vm.monthlyRecords,
                        onSelect: { vm.selectDate($0) }
                    )

                    // ── 하단 상세 탭 ─────────────────────────
                    detailSection
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

    // MARK: - 월 헤더 + 요약 바
    private var monthHeader: some View {
        VStack(spacing: 12) {
            // 월 네비게이션
            HStack {
                Button { vm.changeMonth(offset: -1) } label: {
                    Image(systemName: "chevron.left").font(.subheadline.weight(.semibold))
                }
                Spacer()
                Text(displayMonth)
                    .font(.headline)
                Spacer()
                Button { vm.changeMonth(offset: 1) } label: {
                    Image(systemName: "chevron.right").font(.subheadline.weight(.semibold))
                }
            }
            .padding(.horizontal, 20)

            // 요약 바: 스트릭 · 완료율 · 9/9 횟수
            HStack(spacing: 0) {
                summaryCell(value: "\(vm.currentStreak)일", label: "연속", icon: "🔥")
                Divider().frame(height: 28)
                summaryCell(value: "\(Int(vm.monthlyCompletionRate * 100))%", label: "이달 완료율", icon: nil)
                Divider().frame(height: 28)
                summaryCell(value: "\(vm.totalCompleted)회", label: "9/9 완료", icon: nil)
            }
            .padding(.vertical, 12)
            .background(AppColor.bgSecond)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .padding(.horizontal, 20)
        }
    }

    private func summaryCell(value: String, label: String, icon: String?) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                if let icon { Text(icon).font(.subheadline) }
                Text(value).font(.system(size: 18, weight: .bold, design: .rounded))
            }
            Text(label).font(.caption2).foregroundStyle(AppColor.labelSec)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 하단 탭 섹션
    private var detailSection: some View {
        VStack(spacing: 0) {
            Picker("", selection: $detailTab) {
                Text("통계").tag(0)
                Text("차트").tag(1)
                Text("뱃지").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            switch detailTab {
            case 0: statsTab
            case 1: chartTab
            default: badgeTab
            }
        }
    }

    // ── 통계 탭 ────────────────────────────────────────
    private var statsTab: some View {
        VStack(spacing: 16) {
            // 전체 통계
            VStack(alignment: .leading, spacing: 12) {
                Text("전체 기록").font(.headline).padding(.horizontal, 20)
                VStack(spacing: 8) {
                    statRow("총 챌린지 완료", "\(vm.totalCompleted)회")
                    statRow("나의 최고기록",  vm.personalBestDisplay)
                    statRow("전체 평균",      vm.averageDisplay)
                    statRow("현재 스트릭",    "\(vm.currentStreak)일")
                    statRow("최장 스트릭",    "\(vm.longestStreak)일")
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
            .background(AppColor.bgSecond)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .padding(.horizontal, 20)

            // 유형별 완료율
            VStack(alignment: .leading, spacing: 12) {
                Text("유형별 완료율").font(.headline).padding(.horizontal, 20)
                VStack(spacing: 10) {
                    TypeRateRow(type: .spark, rate: vm.sparkCompletionRate)
                    TypeRateRow(type: .flow,  rate: vm.flowCompletionRate)
                    TypeRateRow(type: .deep,  rate: vm.deepCompletionRate)
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
            .background(AppColor.bgSecond)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .padding(.horizontal, 20)
        }
    }

    // ── 차트/포디움 탭 ──────────────────────────────────
    private var chartTab: some View {
        VStack(spacing: 16) {
            TimeChartCard(records: vm.monthlyRecords)
            if !vm.podiumTop3.isEmpty {
                PodiumCard(entries: vm.podiumTop3)
            }
        }
    }

    // ── 뱃지 탭 ────────────────────────────────────────
    private var badgeTab: some View {
        BadgeCollectionView(badges: badgeService.badges)
            .padding(.horizontal, 20)
    }

    // MARK: - 헬퍼
    private var displayMonth: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월"
        return f.string(from: vm.currentYearMonth.toYearMonthDate() ?? Date())
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - 뱃지 진행 카드
struct BadgeProgressCard: View {
    let badges: [Badge]
    let nextProgress: BadgeNextProgress?

    private var earnedBadges: [Badge] { badges.filter { $0.isEarned } }

    var body: some View {
        VStack(spacing: 12) {
            // 헤더
            HStack {
                Text("나의 뱃지")
                    .font(.headline)
                Spacer()
                Text("\(earnedBadges.count) / \(badges.count) 달성")
                    .font(.caption)
                    .foregroundStyle(AppColor.labelSec)
            }

            // 달성 뱃지 (최근 4개) + 화살표 + 다음 뱃지
            HStack(spacing: 10) {
                // 달성 뱃지 미니 그리드 (최대 4개, 원형)
                HStack(spacing: 6) {
                    ForEach(earnedBadges.suffix(4)) { badge in
                        Text(badge.emoji)
                            .font(.system(size: 22))
                            .frame(width: 38, height: 38)
                            .background(AppColor.bgThird)
                            .clipShape(Circle())
                    }
                    // 빈 자리 채우기 (최소 1개 이상 표시)
                    if earnedBadges.isEmpty {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(AppColor.labelTer)
                            .frame(width: 38, height: 38)
                            .background(AppColor.bgThird)
                            .clipShape(Circle())
                    }
                }

                Image(systemName: "arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColor.labelSec)

                // 다음 뱃지 스포트라이트
                if let next = nextProgress {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(next.badge.emoji)
                                .font(.system(size: 22))
                                .opacity(0.4)
                                .grayscale(1)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(next.badge.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppColor.labelSec)
                                Text(next.progressText)
                                    .font(.caption2)
                                    .foregroundStyle(AppColor.labelTer)
                            }
                        }
                        // 진행 바
                        if next.required > 1 {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(AppColor.bgThird)
                                        .frame(height: 5)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(AppColor.accent.opacity(0.6))
                                        .frame(width: geo.size.width * next.progress, height: 5)
                                }
                            }
                            .frame(height: 5)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("모든 뱃지 달성! 🏆")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColor.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(Spacing.lg)
        .background(AppColor.bgSecond)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
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
            HStack {
                ForEach(weekdays, id: \.self) { d in
                    Text(d).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(calendarDays, id: \.self) { dayKey in
                    if dayKey.isEmpty {
                        Color.clear.frame(height: 36)
                    } else {
                        let isPaused = dayKey.toDate().map { HabitPauseService.shared.isPaused(date: $0) } ?? false
                        CalendarCell(
                            dateKey: dayKey,
                            record: records.first { $0.date == dayKey },
                            isPaused: isPaused
                        ) { onSelect(dayKey) }
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
        let offset = firstWeekday == 1 ? 6 : firstWeekday - 2
        var days = Array(repeating: "", count: offset)
        for day in range { days.append("\(yearMonth)-\(String(format: "%02d", day))") }
        return days
    }
}

struct CalendarCell: View {
    let dateKey: String
    let record: DailyRecord?
    var isPaused: Bool = false
    let onTap: () -> Void

    var day: String { String(dateKey.suffix(2)) }
    var isToday: Bool { dateKey == Date().recordKey }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle().fill(cellColor).frame(width: 36, height: 36)
                if isPaused && record?.isSuccess != true {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabel))
                } else {
                    Text(day.hasPrefix("0") ? String(day.dropFirst()) : day)
                        .font(.caption)
                        .fontWeight(isToday ? .bold : .regular)
                        .foregroundStyle(textColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var cellColor: Color {
        if isPaused && record?.isSuccess != true { return Color(.systemGray5) }
        if let r = record { return r.isSuccess ? .primary : Color(.tertiarySystemFill) }
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
            Text("소요시간").font(.headline)
            if records.filter({ $0.isSuccess }).isEmpty {
                Text("완료된 기록이 없어요")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Chart(records.filter { $0.isSuccess }, id: \.date) { r in
                    BarMark(
                        x: .value("날짜", String(r.date.suffix(5))),
                        y: .value("분", r.elapsedSeconds / 60)
                    )
                    .foregroundStyle(Color.primary).cornerRadius(4)
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

// MARK: - 포디움
struct PodiumCard: View {
    let entries: [PodiumEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🏆 나의 포디움").font(.headline)
            Text("9/9 완료 + 199분 이내 기록 Top 3")
                .font(.caption).foregroundStyle(AppColor.labelSec)
            VStack(spacing: 8) {
                ForEach(entries) { e in
                    HStack {
                        Text(e.medal).font(.title3).frame(width: 32)
                        Text(e.display).font(.headline)
                            .fontWeight(e.rank == 1 ? .bold : .semibold)
                        Spacer()
                        Text(e.dateDisplay).font(.caption).foregroundStyle(AppColor.labelSec)
                    }
                    if e.rank < entries.count { Divider() }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }
}

// MARK: - 유형별 완료율 행
struct TypeRateRow: View {
    let type: ItemType; let rate: Double
    var body: some View {
        HStack(spacing: 12) {
            Text(type.emoji + " " + type.displayName)
                .font(.subheadline).frame(width: 70, alignment: .leading)
            ProgressView(value: rate).tint(.primary)
            Text("\(Int(rate * 100))%")
                .font(.caption).foregroundStyle(.secondary).frame(width: 32, alignment: .trailing)
        }
    }
}

// MARK: - 뱃지 컬렉션
struct BadgeCollectionView: View {
    let badges: [Badge]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            let earned = badges.filter { $0.isEarned }.count
            Text("\(earned)/\(badges.count) 획득")
                .font(.caption).foregroundStyle(AppColor.labelSec)
            LazyVGrid(columns: columns, spacing: Spacing.md) {
                ForEach(badges) { BadgeCellView(badge: $0) }
            }
        }
        .padding(Spacing.lg)
        .background(AppColor.bgSecond)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}

struct BadgeCellView: View {
    let badge: Badge
    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(badge.emoji)
                .font(.system(size: 32))
                .grayscale(badge.isEarned ? 0 : 1)
                .opacity(badge.isEarned ? 1.0 : 0.35)
            Text(badge.isEarned ? badge.title : "?")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(badge.isEarned ? AppColor.primary : AppColor.labelSec)
                .lineLimit(2).multilineTextAlignment(.center)
            if badge.isEarned, let date = badge.earnedAt {
                Text(earnedText(date))
                    .font(.system(size: 9)).foregroundStyle(AppColor.labelTer)
            } else {
                Text(" ").font(.system(size: 9))
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, Spacing.xs)
    }
    private func earnedText(_ date: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "ko_KR"); f.dateFormat = "M/d"
        return f.string(from: date)
    }
}

// MARK: - 날짜 상세
struct DayDetailView: View {
    let record: DailyRecord
    let routineItems: [String]
    var onDelete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text(displayDate).font(.headline)
                    Text(record.isSuccess ? "완료 ✅" : "미완료")
                        .font(.subheadline)
                        .foregroundStyle(record.isSuccess ? .green : .secondary)
                }
                Spacer()
                Text(record.elapsedDisplay).font(.title2).fontWeight(.thin)
                Button { showDeleteConfirm = true } label: {
                    Image(systemName: "trash").foregroundStyle(.red)
                }
                .padding(.leading, 12)
            }
            .padding(.horizontal, 20).padding(.top, 20)
            .confirmationDialog("이 기록을 삭제할까요?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("삭제", role: .destructive) { onDelete?(); dismiss() }
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                ForEach(0..<min(record.itemStatus.count, 9), id: \.self) { i in
                    HStack {
                        Image(systemName: record.itemStatus[i] ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(record.itemStatus[i] ? .green : .secondary)
                        Text(typeLabel(for: i)).font(.caption).foregroundStyle(.secondary)
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
        let f = DateFormatter(); f.locale = Locale(identifier: "ko_KR"); f.dateFormat = "M월 d일 EEEE"
        return f.string(from: record.date.toDate() ?? Date())
    }
    private func typeLabel(for i: Int) -> String {
        switch i { case 0..<3: return "⚡ 뚝딱"; case 3..<6: return "🔹 착착"; default: return "🔵 몰입" }
    }
}

// MARK: - DailyRecord Identifiable
extension DailyRecord: Identifiable { public var id: String { date } }
