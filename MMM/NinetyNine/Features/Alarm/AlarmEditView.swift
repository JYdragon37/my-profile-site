import SwiftUI

struct AlarmEditView: View {

    @State private var alarm: AlarmConfig
    @State private var isShowingSoundPicker = false
    @Environment(\.dismiss) private var dismiss

    let onSave: (AlarmConfig) -> Void
    let onDelete: (AlarmConfig) -> Void
    let isNew: Bool

    init(alarm: AlarmConfig,
         onSave: @escaping (AlarmConfig) -> Void,
         onDelete: @escaping (AlarmConfig) -> Void) {
        _alarm = State(initialValue: alarm)
        self.onSave = onSave
        self.onDelete = onDelete
        self.isNew = alarm.label == AlarmConfig.defaultWeekday().label && alarm.repeatDays == Weekday.weekdays
    }

    var body: some View {
        NavigationStack {
            Form {
                // 시간 피커
                Section {
                    DatePicker(
                        "시간",
                        selection: timeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxHeight: 180)
                }

                // 반복
                Section("반복") {
                    HStack {
                        ForEach(Weekday.allCases) { day in
                            DayButton(
                                day: day,
                                isSelected: alarm.repeatDays.contains(day)
                            ) {
                                if alarm.repeatDays.contains(day) {
                                    alarm.repeatDays.removeAll { $0 == day }
                                } else {
                                    alarm.repeatDays.append(day)
                                }
                            }
                        }
                    }
                }

                // 레이블
                Section("레이블") {
                    TextField("알람 이름", text: $alarm.label)
                }

                // 알람음 + 볼륨
                Section("알람음") {
                    Button {
                        isShowingSoundPicker = true
                    } label: {
                        HStack {
                            Text("알람음")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(alarm.soundName == "default" ? "기본 알람" : alarm.soundName)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("볼륨")
                            .font(.subheadline)
                        Slider(value: $alarm.volume, in: 0...1)
                    }

                    Toggle("볼륨 서서히 키우기", isOn: $alarm.fadeIn)
                    Toggle("진동", isOn: $alarm.vibration)
                }

                // 스누즈
                Section("스누즈") {
                    Toggle("스누즈 사용", isOn: $alarm.snoozeEnabled)
                    if alarm.snoozeEnabled {
                        Stepper("\(alarm.snoozeDurationMinutes)분", value: $alarm.snoozeDurationMinutes, in: 1...30)
                        Stepper("최대 \(alarm.snoozeMaxCount)회", value: $alarm.snoozeMaxCount, in: 1...5)
                    }
                }

                // 챌린지 연동
                Section {
                    Toggle("챌린지 자동 시작", isOn: $alarm.challengeAutoStart)
                } footer: {
                    Text("알람을 해제하면 오늘의 99분 챌린지가 자동으로 시작됩니다.")
                }

                // 삭제 버튼 (편집 모드에서만)
                if !isNew {
                    Section {
                        Button(role: .destructive) {
                            onDelete(alarm)
                            dismiss()
                        } label: {
                            Text("이 알람 삭제")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "알람 추가" : "알람 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        onSave(alarm)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingSoundPicker) {
                AlarmSoundPickerView(selected: $alarm.soundName)
            }
        }
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: alarm.hour, minute: alarm.minute, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                alarm.hour = Calendar.current.component(.hour, from: date)
                alarm.minute = Calendar.current.component(.minute, from: date)
            }
        )
    }
}

// MARK: - 요일 버튼
struct DayButton: View {
    let day: Weekday
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(day.shortName)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.primary : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? Color(.systemBackground) : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
