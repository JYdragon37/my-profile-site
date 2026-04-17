import SwiftUI

struct AlarmListView: View {
    @StateObject private var vm = AlarmViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                // 배경: 매우 어두운 딥 다크
                Color(red: 0.06, green: 0.06, blue: 0.10)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if vm.alarms.isEmpty {
                        AlarmEmptyState { vm.openEdit() }
                    } else {
                        alarmList
                    }
                }
            }
            .navigationTitle("알람")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(
                Color(red: 0.06, green: 0.06, blue: 0.10).opacity(0.9),
                for: .navigationBar
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptic.tap()
                        vm.openEdit()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !vm.alarms.isEmpty { addAlarmButton }
            }
            .sheet(isPresented: $vm.isShowingEdit, onDismiss: { vm.loadAlarms() }) {
                if let alarm = vm.editingAlarm {
                    AlarmEditView(
                        alarm: alarm,
                        onSave: { vm.saveAlarm($0) },
                        onDelete: { vm.deleteAlarm($0) }
                    )
                }
            }
        }
        .onAppear { vm.setup(modelContext: modelContext) }
    }

    // MARK: - 알람 리스트
    private var alarmList: some View {
        List {
            ForEach(vm.alarms) { alarm in
                AlarmCardRow(
                    alarm: alarm,
                    onToggle: {
                        Haptic.select()
                        vm.toggleAlarm(alarm)
                    },
                    onEdit: {
                        Haptic.tap()
                        vm.openEdit(alarm: alarm)
                    }
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        vm.deleteAlarm(alarm)
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - 하단 추가 버튼
    private var addAlarmButton: some View {
        Button {
            Haptic.tap()
            vm.openEdit()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("새 알람 추가")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(
                        colors: [AppColor.accent, AppColor.accent.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.huge)
        }
    }
}

// MARK: - AlarmCardRow
struct AlarmCardRow: View {
    let alarm: AlarmConfig
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Left info zone — tap anywhere here to edit
            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 4) {
                    // 시간: 얇은 폰트, 큰 크기
                    Text(alarm.timeString)
                        .font(.system(size: 48, weight: .thin, design: .default))
                        .monospacedDigit()
                        .foregroundStyle(alarm.isEnabled ? .white : Color.white.opacity(0.35))

                    HStack(spacing: 6) {
                        Text(alarm.repeatDaysString)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))

                        if alarm.challengeAutoStart {
                            HStack(spacing: 3) {
                                Image(systemName: "bolt.fill")
                                    .font(.caption2)
                                Text("챌린지 자동시작")
                                    .font(.caption2)
                            }
                            .foregroundStyle(AppColor.accent)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(AppColor.accent.opacity(0.15))
                            )
                        }
                    }

                    if !alarm.label.isEmpty {
                        Text(alarm.label)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Right toggle zone — independent, does not trigger edit
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(AppColor.accent)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .opacity(alarm.isEnabled ? 1.0 : 0.55)
    }
}

// MARK: - 빈 상태
struct AlarmEmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()
            Image(systemName: "alarm")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(.white.opacity(0.3))
            VStack(spacing: Spacing.sm) {
                Text("아직 알람이 없어요")
                    .font(.title3).fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text("알람을 설정하면 기상과 동시에\n챌린지가 자동으로 시작돼요")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            Button {
                onAdd()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("첫 알람 추가하기")
                }
                .frame(maxWidth: 240)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(
                            colors: [AppColor.accent, AppColor.accent.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )
                .foregroundStyle(.white)
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, Spacing.xxxl)
    }
}
