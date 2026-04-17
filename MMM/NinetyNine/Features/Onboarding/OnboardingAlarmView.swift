import SwiftUI

// 온보딩 전용 간소화 알람 설정
// 자세한 설정은 알람 탭에서 가능
struct OnboardingAlarmView: View {
    let onSetup: () -> Void
    let onSkip: () -> Void

    @State private var selectedHour: Int = 6
    @State private var selectedMinute: Int = 30
    @State private var isAlarmSet: Bool = false
    @State private var showPermissionDenied: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 40) {
                VStack(spacing: 12) {
                    Text("🔔")
                        .font(.system(size: 56))

                    Text("기상 알람을 설정하면\n챌린지가 자동 시작돼요")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("알람을 끄는 순간, 오늘의 99분 챌린지가 시작됩니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // 시간 피커
                DatePicker(
                    "",
                    selection: Binding(
                        get: {
                            Calendar.current.date(
                                bySettingHour: selectedHour,
                                minute: selectedMinute,
                                second: 0,
                                of: Date()
                            ) ?? Date()
                        },
                        set: { date in
                            selectedHour = Calendar.current.component(.hour, from: date)
                            selectedMinute = Calendar.current.component(.minute, from: date)
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxHeight: 150)
                .clipped()

                Text("평일 기상 알람으로 설정됩니다.\n자세한 설정은 알람 탭에서 변경할 수 있어요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button(action: {
                    scheduleAlarm()
                    onSetup()
                }) {
                    Text("설정하기")
                        .font(.headline)
                        .foregroundStyle(Color(.systemBackground))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .alert("알림 권한이 필요해요", isPresented: $showPermissionDenied) {
                    Button("설정 열기") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("나중에", role: .cancel) { onSkip() }
                } message: {
                    Text("기상 알람을 사용하려면 설정 > 99 > 알림을 허용해주세요.")
                }

                Button(action: onSkip) {
                    Text("나중에 설정할게요")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private func scheduleAlarm() {
        Task {
            // 알람 권한 요청
            let granted = await AlarmService.shared.requestPermission()
            guard granted else {
                // 권한 거부 → 설정 앱으로 안내
                await MainActor.run {
                    showPermissionDenied = true
                }
                return
            }

            // 알람 예약
            var config = AlarmConfig.defaultWeekday()
            config.hour = selectedHour
            config.minute = selectedMinute
            AlarmService.shared.scheduleAlarm(config)
            AnalyticsService.shared.log(.alarmSetDuringOnboarding)
        }
    }
}
