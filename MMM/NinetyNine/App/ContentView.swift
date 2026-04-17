import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var activeAlarmID: String?
    @State private var alarmChallengeAutoStart: Bool = false
    @State private var isShowingAlarmFullscreen: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(selectedTab: $selectedTab)
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }
                .tag(0)

            AlarmListView()
                .tabItem {
                    Label("알람", systemImage: "alarm.fill")
                }
                .tag(1)

            RecordView()
                .tabItem {
                    Label("기록", systemImage: "chart.bar.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.primary)
        // 알람 해제 시 전체화면 뷰 표시
        .onReceive(NotificationCenter.default.publisher(for: .alarmDismissed)) { notification in
            guard let userInfo = notification.userInfo else { return }
            activeAlarmID = userInfo["alarmID"] as? String
            alarmChallengeAutoStart = userInfo["challengeAutoStart"] as? Bool ?? false
            isShowingAlarmFullscreen = true
        }
        .fullScreenCover(isPresented: $isShowingAlarmFullscreen) {
            if let alarmID = activeAlarmID {
                AlarmFullscreenView(
                    alarmID: alarmID,
                    challengeAutoStart: alarmChallengeAutoStart,
                    onDismiss: {
                        isShowingAlarmFullscreen = false
                        activeAlarmID = nil
                    }
                )
            }
        }
    }
}
