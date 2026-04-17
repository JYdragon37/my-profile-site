import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0
    // @Published observe — 앱 콜드스타트 시 NotificationCenter 타이밍 경쟁 없이 안전하게 수신
    @ObservedObject private var alarmService = AlarmService.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(selectedTab: $selectedTab)
                .tabItem { Label("홈",  systemImage: "house.fill") }.tag(0)
            AlarmListView()
                .tabItem { Label("알람", systemImage: "alarm.fill") }.tag(1)
            RecordView()
                .tabItem { Label("기록", systemImage: "chart.bar.fill") }.tag(2)
            SettingsView()
                .tabItem { Label("설정", systemImage: "gearshape.fill") }.tag(3)
        }
        .tint(.primary)
        // pendingAlarm이 set되는 순간 fullScreenCover 자동 표시
        .fullScreenCover(item: $alarmService.pendingAlarm) { alarm in
            AlarmFullscreenView(
                alarmID: alarm.id,
                challengeAutoStart: alarm.challengeAutoStart,
                onDismiss: { alarmService.pendingAlarm = nil }
            )
        }
    }
}
