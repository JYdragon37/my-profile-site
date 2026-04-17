import SwiftUI
import UserNotifications

// MARK: - 알림 설정 공유 컨텐츠
// 온보딩 마지막 페이지 + 설정 탭 양쪽에서 재사용
struct NotificationSettingsContent: View {

    // MARK: - 공유 설정값 (AppStorage)
    @AppStorage("notificationEnabled")       var notificationEnabled: Bool = false
    @AppStorage("reminderEnabled")           var reminderEnabled: Bool = false
    @AppStorage("reminderHour")              var reminderHour: Int = 12
    @AppStorage("reminderMinute")            var reminderMinute: Int = 0
    @AppStorage("reminderSkipOnCompletion")  var reminderSkipOnCompletion: Bool = false

    @State private var showPermissionDeniedAlert = false
    @State private var reminderTime: Date = Date()

    var body: some View {
        VStack(spacing: 0) {
            // ── 앱 알림 ────────────────────────────────
            notificationRow(
                icon: "🔔",
                title: "앱 알림",
                description: "매일의 실천을 놓치지 않도록, 실천의 힘을 키워줄\n동기부여 알림을 보내드릴게요.",
                isOn: Binding(
                    get: { notificationEnabled },
                    set: { newValue in
                        if newValue {
                            Task { await requestAndToggle() }
                        } else {
                            notificationEnabled = false
                            cancelAllReminders()
                        }
                    }
                )
            )

            Divider()

            // ── 습관 리마인더 ───────────────────────────
            VStack(alignment: .leading, spacing: 0) {
                notificationRow(
                    icon: "⏰",
                    title: "습관 리마인더",
                    description: "습관을 지속할 수 있도록 원하는 시간에 알려드릴게요.",
                    isOn: Binding(
                        get: { reminderEnabled },
                        set: { newValue in
                            reminderEnabled = newValue
                            if newValue { scheduleReminder() } else { cancelReminder() }
                        }
                    )
                )
                .disabled(!notificationEnabled)
                .opacity(notificationEnabled ? 1 : 0.45)

                if reminderEnabled && notificationEnabled {
                    VStack(spacing: 0) {
                        Divider().padding(.leading, 20)

                        // 리마인더 시간
                        HStack {
                            Text("리마인더 시간")
                                .font(.body)
                            Spacer()
                            DatePicker(
                                "",
                                selection: $reminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .onChange(of: reminderTime) { _, newTime in
                                reminderHour   = Calendar.current.component(.hour,   from: newTime)
                                reminderMinute = Calendar.current.component(.minute, from: newTime)
                                scheduleReminder()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)

                        Divider().padding(.leading, 20)

                        // 체크한 날 알림 끄기
                        HStack {
                            Text("습관을 체크한 날은 알림 끄기")
                                .font(.body)
                            Spacer()
                            Toggle("", isOn: $reminderSkipOnCompletion)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.2), value: reminderEnabled)
                }
            }
        }
        .onAppear {
            syncReminderTime()
            syncPermissionState()
        }
        .alert("알림 권한이 꺼져 있어요", isPresented: $showPermissionDeniedAlert) {
            Button("설정 열기") { openAppSettings() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("iPhone 설정 > 99 > 알림에서 권한을 허용해주세요.")
        }
    }

    // MARK: - 알림 행 공통 레이아웃
    private func notificationRow(
        icon: String,
        title: String,
        description: String,
        isOn: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(icon)
                Text(title)
                    .font(.body.weight(.medium))
                Spacer()
                Toggle("", isOn: isOn).labelsHidden()
            }
            Text(description)
                .font(.subheadline)
                .foregroundStyle(AppColor.labelSec)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    // MARK: - 권한 요청
    private func requestAndToggle() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            await MainActor.run { notificationEnabled = granted }
        case .authorized, .provisional, .ephemeral:
            await MainActor.run { notificationEnabled = true }
        case .denied:
            await MainActor.run { showPermissionDeniedAlert = true }
        @unknown default:
            break
        }
    }

    // MARK: - 리마인더 예약
    func scheduleReminder() {
        let content = UNMutableNotificationContent()
        content.title = "99분 챌린지"
        content.body = "오늘의 루틴을 시작할 시간이에요! 지금 바로 시작해봐요 💪"
        content.sound = .default
        content.interruptionLevel = .active

        var components = DateComponents()
        components.hour   = reminderHour
        components.minute = reminderMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "habit_daily_reminder",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["habit_daily_reminder"])
    }

    func cancelAllReminders() {
        cancelReminder()
        reminderEnabled = false
    }

    // MARK: - 권한 상태 동기화 (앱 복귀 시)
    func syncPermissionState() {
        Task {
            let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            await MainActor.run {
                if status != .authorized && status != .provisional {
                    notificationEnabled = false
                    reminderEnabled     = false
                }
            }
        }
    }

    private func syncReminderTime() {
        var comps        = DateComponents()
        comps.hour       = reminderHour
        comps.minute     = reminderMinute
        reminderTime     = Calendar.current.date(from: comps) ?? Date()
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - 설정 탭에서 단독으로 쓰는 NavigationView 래퍼
struct NotificationSettingsPage: View {

    @StateObject private var content = NotificationSettingsContentVM()

    var body: some View {
        List {
            Section {
                NotificationSettingsContent()
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }

            Section(footer: Text("권한이 거부된 경우 iPhone 설정 > 99 > 알림에서 직접 허용할 수 있어요.")) {
                Button("알림 권한 상태 확인") {
                    Task {
                        let status = await UNUserNotificationCenter.current()
                            .notificationSettings().authorizationStatus
                        content.statusMessage = statusLabel(status)
                        content.showStatus = true
                    }
                }
                .foregroundStyle(AppColor.accent)
            }
        }
        .navigationTitle("알림 설정")
        .alert("알림 권한 상태", isPresented: $content.showStatus) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(content.statusMessage)
        }
    }

    private func statusLabel(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized:   return "✅ 허용됨"
        case .denied:       return "❌ 거부됨 — 설정에서 변경해주세요"
        case .notDetermined: return "⏳ 아직 요청 안 함"
        case .provisional:  return "🔕 임시 허용 (조용한 알림)"
        case .ephemeral:    return "⚡ 임시 허용"
        @unknown default:   return "알 수 없음"
        }
    }
}

// 상태 보관용 간단 VM (ObservableObject 필요)
private final class NotificationSettingsContentVM: ObservableObject {
    @Published var statusMessage = ""
    @Published var showStatus = false
}
