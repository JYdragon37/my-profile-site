import SwiftUI
import Kingfisher

// MARK: - TodayView (NavigationStack root)
struct TodayView: View {

    @StateObject private var vm = TodayViewModel()
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTab: Int

    @State private var navPath: [NavDestination] = []

    enum NavDestination: Hashable {
        case challenge
        case completion(elapsedSeconds: Int)
    }

    var body: some View {
        NavigationStack(path: $navPath) {
            HomeDashboardView(vm: vm, selectedTab: $selectedTab, navPath: $navPath)
                .navigationDestination(for: NavDestination.self) { dest in
                    switch dest {
                    case .challenge:
                        ChallengeView(vm: vm, navPath: $navPath)
                    case .completion(let elapsed):
                        CompletionView(
                            elapsedSeconds: elapsed,
                            onDismiss: { navPath.removeAll() },
                            recordRepository: vm.recordRepository
                        )
                    }
                }
        }
        .sheet(item: $vm.activeTimerItem) { item in
            TimerPopupView(
                item: item,
                onComplete: {
                    vm.completeItem(item.id)
                    Haptic.success()
                },
                onCancel: {
                    vm.cancelTimerItem()
                }
            )
            .presentationDetents([.medium])
        }
        .onAppear {
            let routineRepo = RoutineRepository(modelContext: modelContext)
            let recordRepo = RecordRepository(modelContext: modelContext)
            vm.setup(routineRepo: routineRepo, recordRepo: recordRepo)
            vm.checkAlreadyCompletedToday()
            // fetchIfNeeded는 NinetyNineApp.task에서 최초 1회 처리 — 중복 호출 제거
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        ) { _ in
            vm.handleForeground()
        }
        // 상태 변화 감지 → 챌린지/완료 화면으로 자동 push
        .onChange(of: vm.stateID) { _, _ in
            syncNavWithState()
        }
        // Feature O: 알람 해제 후 앱 포그라운드 진입 시 챌린지 화면으로 자동 이동
        .onChange(of: vm.shouldNavigateToChallenge) { _, shouldNavigate in
            if shouldNavigate {
                vm.shouldNavigateToChallenge = false
                if !navPath.contains(.challenge) {
                    navPath = [.challenge]
                }
            }
        }
        // 뱃지 달성 팝업 (이미지 저장 포함)
        .fullScreenCover(item: $vm.badgeToastBadge) { badge in
            BadgeEarnedPopupView(badge: badge) {
                vm.showNextBadgeToast()
            }
        }
    }

    private func syncNavWithState() {
        switch vm.state {
        case .inProgress:
            if !navPath.contains(.challenge) {
                navPath = [.challenge]
            }
        case .completed(let elapsed):
            if navPath.isEmpty {
                navPath = [.completion(elapsedSeconds: elapsed)]
            }
        case .failed:
            if !navPath.contains(.challenge) {
                navPath = [.challenge]
            }
        case .beforeStart:
            navPath.removeAll()
        }
    }
}

// MARK: - HomeDashboardView
struct HomeDashboardView: View {
    @ObservedObject var vm: TodayViewModel
    @Binding var selectedTab: Int
    @Binding var navPath: [TodayView.NavDestination]

    @AppStorage("userNickname") private var nickname: String = "친구"
    @AppStorage("currentStreak") private var streak: Int = 0
    @ObservedObject private var motivation = MotivationService.shared

    @State private var showResetConfirm = false
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        backgroundView
            .overlay { gradientOverlay }
            .overlay(alignment: .topLeading) {
                greetingHeader
                    .padding(.top, 60)
                    .padding(.horizontal, 24)
            }
            // 문구를 화면 중앙(y: 0.52)에 배치 - dailyverse 패턴
            .overlay {
                GeometryReader { geo in
                    quoteCenter
                        .padding(.horizontal, max(geo.size.width * 0.1, 32))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .position(x: geo.size.width / 2,
                                  y: geo.size.height * 0.43)
                }
            }
            .overlay(alignment: .bottom) {
                bottomCTA
                    .padding(.bottom, 48)
                    .padding(.horizontal, Spacing.xl)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onReceive(timer) { _ in currentTime = Date() }
            .confirmationDialog("오늘의 99를 리셋할까요?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("리셋하기", role: .destructive) { vm.resetTodayChallenge() }
                Button("취소", role: .cancel) {}
            } message: {
                Text("현재까지의 기록이 삭제됩니다.")
            }
    }

    // MARK: - Background (Kingfisher 디스크 캐시 — 재실행 시 즉시 표시)
    private var backgroundView: some View {
        Group {
            if let url = motivation.current.imageURL {
                KFImage(url)
                    .placeholder { fallbackGradient }   // 캐시 없을 때만 그라디언트
                    .fade(duration: 0.25)               // 부드러운 전환
                    .resizable()
                    .scaledToFill()
            } else {
                fallbackGradient
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
    }

    private var fallbackGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.15, blue: 0.3),
                Color(red: 0.05, green: 0.1, blue: 0.2)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Gradient Overlay (상단 + 하단)
    private var gradientOverlay: some View {
        VStack(spacing: 0) {
            // 상단 어둡게
            LinearGradient(
                colors: [Color.black.opacity(0.6), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 200)
            Spacer()
            // 하단 어둡게
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.75)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 320)
        }
        .ignoresSafeArea()
    }

    // MARK: - Greeting Header (상단 좌측)
    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 인사말 + 스트릭
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: timeIcon)
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
                    .frame(width: 30, alignment: .leading)  // 고정 너비로 텍스트 밀림 방지

                Text(greeting)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.75)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)  // 가용 너비 내에서 wrap

                if streak > 0 {
                    StreakBadge(streak: streak)
                        .padding(.top, 4)
                        .fixedSize()  // 뱃지 크기 고정
                }
            }

            // 날짜 + 날씨 — 단일 Text로 합쳐 오버플로우 방지
            Text(dateWeatherString)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.leading, 38)  // 아이콘 너비(30) + 간격(8)에 맞춤
        }
        .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 2)
    }

    private var dateWeatherString: String {
        var parts = [dateTimeString]
        let w = vm.weather
        if w.temperature > 0 || !w.cityName.isEmpty {
            parts.append("·")
            if !w.cityName.isEmpty { parts.append(w.cityName) }
            if w.temperature > 0   { parts.append("\(w.temperature)°") }
            if !w.conditionKo.isEmpty { parts.append(w.conditionKo) }
        }
        return parts.joined(separator: "  ")
    }

    // MARK: - Quote Center (화면 중앙 배치)
    private var quoteCenter: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("\u{201C}\(motivation.current.quote.quote)\u{201D}")
                .font(.custom("Georgia-BoldItalic", size: 24))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.85), radius: 8, x: 0, y: 3)

            if !motivation.current.quote.author.isEmpty {
                Text("— \(motivation.current.quote.author)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Bottom CTA
    private var bottomCTA: some View {
        VStack(spacing: 16) {
            // 완료 상태: 오늘 기록 표시
            if case .completed(let elapsed) = vm.state {
                VStack(spacing: 4) {
                    let m = elapsed / 60
                    let s = elapsed % 60
                    let timeStr = s > 0 ? "\(m)분 \(s)초" : "\(m)분"
                    Text(timeStr)
                        .font(.system(size: 32, weight: .thin, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                    Text("오늘의 기록")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.bottom, Spacing.sm)
                .transition(.opacity)
            }

            // 프로그레스 위젯
            if showProgressWidget {
                ProgressDotsWidget(
                    completed: progressCompletedCount,
                    total: vm.routine.isEmpty ? 9 : vm.routine.count
                )
                .onLongPressGesture {
                    Haptic.heavy()
                    showResetConfirm = true
                }
            }

            // CTA 버튼: 오렌지 그라디언트 통일 스타일
            Button(ctaLabel) {
                Haptic.medium()
                handleCTA()
            }
            .font(.headline)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: ButtonHeight.primary)
            .background(
                LinearGradient(
                    colors: {
                        if case .completed = vm.state {
                            return [Color(red: 1.0, green: 0.84, blue: 0.3),
                                    Color(red: 0.95, green: 0.70, blue: 0.15)]
                        } else {
                            return [Color(red: 1.0, green: 0.55, blue: 0.0),
                                    Color(red: 0.95, green: 0.38, blue: 0.0)]
                        }
                    }(),
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .shadow(color: AppColor.accent.opacity(0.35), radius: 10, x: 0, y: 4)

            // 기록 초기화 버튼: 실수로 종료하거나 완료 후 다시 시작할 때
            // 의도치 않은 탭을 방지하기 위해 패딩을 늘리고 위치를 CTA와 분리
            if case .beforeStart = vm.state {} else {
                Button("기록 초기화 (삭제됨)") {
                    Haptic.warning()
                    showResetConfirm = true
                }
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.38))
                .padding(.top, Spacing.lg)
            }
        }
    }

    // MARK: - Helpers
    private var timeIcon: String {
        let h = Calendar.current.component(.hour, from: currentTime)
        switch h {
        case 5..<12:  return "sun.rise.fill"
        case 12..<17: return "sun.max.fill"
        case 17..<20: return "sun.set.fill"
        default:      return "moon.stars.fill"
        }
    }

    private var greeting: String {
        // 구글 시트 greetings 탭에서 zone 기반 동적 인사말 사용
        let gr = motivation.current.greeting
        return gr.display(for: nickname)
    }

    // DateFormatter 생성 비용이 크므로 static으로 캐시
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "M월 d일 EEE"
        return df
    }()

    private static let timeFormatter: DateFormatter = {
        let tf = DateFormatter()
        tf.locale = Locale(identifier: "en_US_POSIX")
        tf.dateFormat = "h:mm a"
        return tf
    }()

    private var dateTimeString: String {
        let dateStr = Self.dateFormatter.string(from: currentTime)
        return "\(dateStr)  \(Self.timeFormatter.string(from: currentTime))"
    }

    // MARK: - Computed (기존 유지)

    private var ctaLabel: String {
        switch vm.state {
        case .beforeStart:  return "오늘의 99 시작하기"
        case .inProgress:   return "진행 중인 99 보기"
        case .failed:       return "오늘의 99 이어하기"
        case .completed:    return "오늘 기록 보기"
        }
    }

    private var showProgressWidget: Bool {
        switch vm.state {
        case .beforeStart: return false
        default:           return true
        }
    }

    private var progressCompletedCount: Int {
        switch vm.state {
        case .beforeStart:
            return 0
        case .inProgress, .failed:
            return vm.completedItems.count
        case .completed:
            return vm.routine.isEmpty ? 9 : vm.routine.count
        }
    }

    private func handleCTA() {
        switch vm.state {
        case .beforeStart:
            vm.startChallenge()
            navPath = [.challenge]
        case .inProgress, .failed:
            navPath = [.challenge]
        case .completed(let elapsed):
            selectedTab = 2
            _ = elapsed
        }
    }
}

// MARK: - WeatherBadge
struct WeatherBadge: View {
    let weather: WeatherData

    var body: some View {
        HStack(spacing: 4) {
            Text(conditionEmoji)
            Text("\(weather.conditionKo) \(weather.temperature)°")
            Text("·")
                .foregroundStyle(.white.opacity(0.5))
            Text(weather.cityName)
        }
        .font(.caption)
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var conditionEmoji: String {
        switch weather.conditionKo {
        case "맑음", "구름 조금":    return "☀️"
        case "흐림", "구름 많음":    return "☁️"
        case "비", "이슬비", "뇌우": return "🌧️"
        case "눈":                   return "❄️"
        case "안개", "박무":         return "🌫️"
        default:                     return "🌤️"
        }
    }
}

// MARK: - StreakBadge
struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Text("🔥")
            Text("\(streak)일")
        }
        .font(.caption)
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - ProgressDotsWidget
struct ProgressDotsWidget: View {
    let completed: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i < completed ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 10, height: 10)
                    .animation(.spring(duration: 0.3), value: completed)
            }
            Text("\(completed) / \(total)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.leading, 4)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.xl)
    }
}

// MARK: - ChallengeView
struct ChallengeView: View {
    @ObservedObject var vm: TodayViewModel
    @Binding var navPath: [TodayView.NavDestination]
    @ObservedObject private var motivation = MotivationService.shared

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // 카운트다운 헤더 (고정)
                TimerHeaderView(timer: vm.challengeTimer, motivation: motivation.current)

                // 루틴 목록 — 남은 공간을 균등하게 활용
                ScrollView {
                    RoutinePreviewList(
                        items: vm.routine,
                        completedItems: vm.completedItems,
                        onTap: { item in
                            Haptic.tap()
                            vm.tapItem(item)
                        }
                    )
                    .padding(.top, Spacing.xl)
                    .padding(.bottom, Spacing.huge)
                }
            }

            // Feature C: 첫 번째 spark 항목 완료 시 플로팅 토스트
            if vm.showFirstSparkToast {
                FirstSparkToast()
                    .padding(.top, Spacing.lg)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .zIndex(1)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: vm.stateID) { _, _ in
            if case .completed(let elapsed) = vm.state {
                navPath = [.completion(elapsedSeconds: elapsed)]
            } else if case .failed = vm.state {
                navPath.removeAll()
            }
        }
        // 그룹 완료 마일스톤 팝업 (전체화면 confetti)
        .overlay {
            if let milestone = vm.milestoneToShow {
                MilestoneCelebrationView(
                    type: milestone,
                    completedGroupCount: vm.completedGroupCount,
                    onDismiss: { vm.dismissMilestone() }
                )
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: vm.milestoneToShow != nil)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: vm.showFirstSparkToast)
    }
}

// MARK: - Feature C: 첫 번째 spark 완료 토스트
struct FirstSparkToast: View {
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text("시작했어요! 🌟")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.72))
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 3)
        )
    }
}


// MARK: - 카운트다운 헤더
struct TimerHeaderView: View {
    @ObservedObject var timer: ChallengeTimer
    var motivation: MotivationContent

    // Pulse animation state
    @State private var isPulsing: Bool = false

    /// < 30분 구간 여부
    private var isUnder30Min: Bool { timer.remainingSeconds < 30 * 60 }
    /// < 60분 구간 여부
    private var isUnder60Min: Bool { timer.remainingSeconds < 60 * 60 }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            // 브랜드 레이블
            Text("99분 챌린지")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppColor.labelSec)
                .padding(.top, Spacing.huge)

            // 타이머
            Text(timer.remainingFormatted)
                .font(.system(size: 48, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(timerTextColor)
                .contentTransition(.numericText())
                .animation(.linear(duration: 1), value: timer.remainingFormatted)
                .scaleEffect(isPulsing ? 1.06 : 1.0)
                .animation(
                    isUnder30Min
                        ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true)
                        : .default,
                    value: isPulsing
                )

            // 진척도 바
            ProgressView(value: timer.progress)
                .tint(timerColor)
                .animation(.linear(duration: 1), value: timer.progress)
                .padding(.horizontal, Spacing.xl)

            // 동기부여 문구 - 폰트 크게
            VStack(spacing: 4) {
                Text("\u{201C}\(motivation.quote.quote)\u{201D}")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColor.labelSec)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                if !motivation.quote.author.isEmpty {
                    Text("— \(motivation.quote.author)")
                        .font(.caption)
                        .foregroundStyle(AppColor.labelTer)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.sm)
        }
        .background(AppColor.bg)
        .onChange(of: isUnder30Min) { _, nowUnder30 in
            if nowUnder30 {
                isPulsing = true
            } else {
                isPulsing = false
            }
        }
        .onAppear {
            if isUnder30Min { isPulsing = true }
        }
    }

    /// 타이머 텍스트 색상: < 30min → red, < 60min → orange, 그 외 기본
    private var timerTextColor: Color {
        if isUnder30Min { return AppColor.warning }
        if isUnder60Min { return AppColor.accent }
        return AppColor.primary
    }

    private var timerColor: Color {
        switch timer.progress {
        case 0..<0.5:  return AppColor.success
        case 0.5..<0.8: return AppColor.accent
        default:        return AppColor.warning
        }
    }
}

// MARK: - 루틴 목록 (공용)
struct RoutinePreviewList: View {
    let items: [RoutineItem]
    let completedItems: Set<Int>
    var onTap: ((RoutineItem) -> Void)?

    var body: some View {
        VStack(spacing: Spacing.md) {
            ForEach([ItemType.spark, .flow, .deep], id: \.self) { type in
                let typeItems = items.filter { $0.type == type }
                if !typeItems.isEmpty {
                    RoutineGroupSection(
                        type: type,
                        items: typeItems,
                        completedItems: completedItems,
                        onTap: onTap
                    )
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
    }
}

struct RoutineGroupSection: View {
    let type: ItemType
    let items: [RoutineItem]
    let completedItems: Set<Int>
    var onTap: ((RoutineItem) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // 섹션 헤더
            HStack(spacing: Spacing.xs) {
                Text(type.emoji)
                    .font(.body)
                Text(type.displayName)
                    .font(.headline)
                Text(durationLabel)
                    .bodySecondary()
            }

            // 항목들
            VStack(spacing: Spacing.xs) {
                ForEach(items) { item in
                    RoutineItemRow(
                        item: item,
                        isCompleted: completedItems.contains(item.id),
                        onTap: onTap != nil ? { onTap?(item) } : nil
                    )
                }
            }
        }
    }

    private var durationLabel: String {
        switch type {
        case .spark: return "3초"
        case .flow:  return "3분"
        case .deep:  return "30분"
        }
    }
}

struct RoutineItemRow: View {
    let item: RoutineItem
    let isCompleted: Bool
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: Spacing.md) {
                // 체크 아이콘
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? AppColor.success : AppColor.labelSec)
                    .animation(.spring(duration: 0.25), value: isCompleted)

                // 항목명
                Text(item.title)
                    .font(.subheadline)
                    .foregroundStyle(isCompleted ? AppColor.labelSec : AppColor.primary)

                Spacer()

                // 시간 뱃지 (미완료 + 타이머 필요한 항목)
                if !isCompleted && !item.isInstant {
                    Text(item.type == .flow ? "3분" : "30분")
                        .font(.caption)
                        .foregroundStyle(AppColor.labelSec)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(AppColor.bgThird)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(AppColor.bgSecond)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .opacity(isCompleted ? 0.55 : 1.0)
            .animation(.easeOut(duration: 0.2), value: isCompleted)
        }
        .buttonStyle(.plain)
        .disabled(isCompleted || onTap == nil)
    }
}

// MARK: - 진행률
struct ProgressSection: View {
    let completed: Int
    let total: Int

    var body: some View {
        HStack {
            Text("\(completed)/\(total) 완료")
                .bodySecondary()
            Spacer()
            ProgressView(value: Double(completed), total: Double(total))
                .frame(width: 120)
                .tint(AppColor.primary)
                .animation(.spring(), value: completed)
        }
        .padding(.horizontal, Spacing.xl)
    }
}
