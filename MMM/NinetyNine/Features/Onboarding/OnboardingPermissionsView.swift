import SwiftUI

// MARK: - 온보딩 마지막 단계: 권한 설정
// 레퍼런스 이미지 스타일: 다크 배경, 프리뷰 카드, 뒤로/다음 버튼
struct OnboardingPermissionsView: View {

    let projectName: String
    let projectEmoji: String
    let projectColorHex: String
    let routineSummary: (spark: String, flow: String, deep: String)
    let onNext: () -> Void
    let onBack: () -> Void

    @StateObject private var settings = OnboardingPermissionsSettings()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // ── 프리뷰 카드 ─────────────────────
                    previewCard
                        .padding(.top, 80) // 상단 내비 버튼 공간

                    // ── 알림 설정 컨텐츠 ────────────────
                    notificationBlock
                        .background(Color(white: 0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    // 하단 버튼 공간 확보
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
            }

            // ── 하단 버튼 고정 ─────────────────────────
            VStack {
                Spacer()
                bottomButtons
                    .padding(.bottom, 36)
                    .padding(.horizontal, 20)
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0), Color.black],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: 140)
                        .allowsHitTesting(false),
                        alignment: .bottom
                    )
            }
        }
    }

    // MARK: - 프리뷰 카드
    private var previewCard: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: projectColorHex).gradient)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Text(projectEmoji).font(.system(size: 32))
                    Text(projectName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Divider().background(.white.opacity(0.3))

                VStack(alignment: .leading, spacing: 8) {
                    summaryRow(icon: "⚡", label: "뚝딱", text: routineSummary.spark)
                    summaryRow(icon: "🔹", label: "착착", text: routineSummary.flow)
                    summaryRow(icon: "🔵", label: "몰입", text: routineSummary.deep)
                }
            }
            .padding(20)

            Text("Preview")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 9).padding(.vertical, 3)
                .background(.white.opacity(0.2))
                .clipShape(Capsule())
                .rotationEffect(.degrees(35))
                .offset(x: -8, y: 12)
        }
    }

    private func summaryRow(icon: String, label: String, text: String) -> some View {
        HStack(spacing: 8) {
            Text(icon).font(.caption)
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 24, alignment: .leading)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
        }
    }

    // MARK: - 알림 블록
    private var notificationBlock: some View {
        VStack(spacing: 0) {
            // 앱 알림
            permissionRow(
                icon: "🔔",
                title: "앱 알림",
                subtitle: "매일의 실천을 놓치지 않도록,\n동기부여 알림을 보내드릴게요.",
                isOn: Binding(
                    get: { settings.notificationEnabled },
                    set: { newValue in
                        if newValue {
                            Task { await settings.requestAndToggle() }
                        } else {
                            settings.notificationEnabled = false
                        }
                    }
                )
            )

            Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)

            // 습관 리마인더
            VStack(alignment: .leading, spacing: 0) {
                permissionRow(
                    icon: "⏰",
                    title: "습관 리마인더",
                    subtitle: "습관을 지속할 수 있도록 원하는 시간에 알려드릴게요.",
                    isOn: Binding(
                        get: { settings.reminderEnabled },
                        set: { settings.reminderEnabled = $0 }
                    )
                )
                .disabled(!settings.notificationEnabled)
                .opacity(settings.notificationEnabled ? 1 : 0.4)

                if settings.reminderEnabled && settings.notificationEnabled {
                    VStack(spacing: 0) {
                        Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)

                        HStack {
                            Text("리마인더 시간")
                                .foregroundStyle(.white)
                            Spacer()
                            DatePicker("", selection: $settings.reminderTime,
                                       displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .colorScheme(.dark)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)

                        Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)

                        HStack {
                            Text("습관을 체크한 날은 알림 끄기")
                                .foregroundStyle(.white)
                            Spacer()
                            Toggle("", isOn: $settings.skipOnCompletion)
                                .labelsHidden()
                                .tint(Color(hex: projectColorHex))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.2), value: settings.reminderEnabled)
                }
            }
        }
    }

    private func permissionRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(icon)
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                Spacer()
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(Color(hex: projectColorHex))
            }
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.5))
                .lineSpacing(3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    // MARK: - 뒤로 / 다음 버튼
    private var bottomButtons: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Text("뒤로")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(white: 0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 28))
            }

            Button(action: {
                // 설정값 저장 후 진행
                settings.saveToAppStorage()
                onNext()
            }) {
                Text("다음")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: projectColorHex))
                    .clipShape(RoundedRectangle(cornerRadius: 28))
            }
        }
    }
}

// MARK: - 온보딩 전용 설정 상태 (AppStorage에 직접 쓰지 않고 확인 후 저장)
@MainActor
private final class OnboardingPermissionsSettings: ObservableObject {
    @Published var notificationEnabled = false
    @Published var reminderEnabled = false
    @Published var reminderTime = {
        var c = DateComponents(); c.hour = 12; c.minute = 0
        return Calendar.current.date(from: c) ?? Date()
    }()
    @Published var skipOnCompletion = false

    func requestAndToggle() async {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        switch status {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            notificationEnabled = granted
        case .authorized, .provisional, .ephemeral:
            notificationEnabled = true
        default:
            notificationEnabled = false
        }
    }

    func saveToAppStorage() {
        UserDefaults.standard.set(notificationEnabled,  forKey: "notificationEnabled")
        UserDefaults.standard.set(reminderEnabled,      forKey: "reminderEnabled")
        UserDefaults.standard.set(skipOnCompletion,     forKey: "reminderSkipOnCompletion")
        let h = Calendar.current.component(.hour,   from: reminderTime)
        let m = Calendar.current.component(.minute, from: reminderTime)
        UserDefaults.standard.set(h, forKey: "reminderHour")
        UserDefaults.standard.set(m, forKey: "reminderMinute")

        // 리마인더 예약
        if reminderEnabled && notificationEnabled {
            scheduleReminder(hour: h, minute: m)
        }
    }

    private func scheduleReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "99분 챌린지"
        content.body  = "오늘의 루틴을 시작할 시간이에요! 💪"
        content.sound = .default
        var comps = DateComponents()
        comps.hour = hour; comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "habit_daily_reminder", content: content, trigger: trigger)
        )
    }
}
