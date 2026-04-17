import SwiftUI

struct HabitPauseView: View {

    @State private var pauses: [HabitPause] = []
    @State private var showAddSheet: Bool = false

    private let maxDaysPerMonth = 7

    var body: some View {
        List {
            // Active pause banner
            if let active = HabitPauseService.shared.activePause() {
                Section {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "pause.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("현재 일시정지 중")
                                .font(.headline)
                            Text("\(formatDate(active.startDate)) ~ \(formatDate(active.endDate)) (\(active.daysCount)일)")
                                .font(.subheadline)
                                .foregroundStyle(AppColor.labelSec)
                        }
                        Spacer()
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }

            // Add pause button section
            Section {
                let usedDays = HabitPauseService.shared.pausedDaysThisMonth()
                let remaining = maxDaysPerMonth - usedDays
                Button {
                    showAddSheet = true
                } label: {
                    Label("일시정지 추가", systemImage: "plus.circle")
                }
                .disabled(remaining <= 0)
            } footer: {
                let usedDays = HabitPauseService.shared.pausedDaysThisMonth()
                Text("이달 사용 \(usedDays)/\(maxDaysPerMonth)일")
                    .font(.footnote)
                    .foregroundStyle(AppColor.labelSec)
            }

            // Pause history list
            if !pauses.isEmpty {
                Section("일시정지 내역") {
                    ForEach(pauses) { pause in
                        PauseRow(pause: pause)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            HabitPauseService.shared.removePause(id: pauses[index].id)
                        }
                        pauses.remove(atOffsets: indexSet)
                    }
                }
            }
        }
        .navigationTitle("스트릭 보호")
        .onAppear { loadPauses() }
        .sheet(isPresented: $showAddSheet, onDismiss: { loadPauses() }) {
            AddPauseSheet()
                .presentationDetents([.medium])
        }
    }

    private func loadPauses() {
        pauses = HabitPauseService.shared.loadPauses()
            .sorted { $0.startDate > $1.startDate }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f.string(from: date)
    }
}

// MARK: - Pause Row

private struct PauseRow: View {
    let pause: HabitPause

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(formatDate(pause.startDate)) ~ \(formatDate(pause.endDate))")
                    .font(.subheadline)
                if let reason = pause.reason, !reason.isEmpty {
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(AppColor.labelSec)
                }
            }
            Spacer()
            Text("\(pause.daysCount)일")
                .font(.caption)
                .foregroundStyle(AppColor.labelSec)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(AppColor.bgThird)
                .clipShape(Capsule())
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f.string(from: date)
    }
}

// MARK: - Add Pause Sheet

private struct AddPauseSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var reason: String = ""

    private let maxDaysPerMonth = 7

    private var remainingDays: Int {
        let used = HabitPauseService.shared.pausedDaysThisMonth()
        return max(0, maxDaysPerMonth - used)
    }

    private var maxEndDate: Date {
        Calendar.current.date(byAdding: .day, value: remainingDays - 1, to: startDate) ?? startDate
    }

    private var selectedDays: Int {
        (Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1
    }

    private var isValid: Bool {
        endDate >= startDate && selectedDays >= 1 && selectedDays <= remainingDays
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("기간 설정") {
                    DatePicker("시작일", selection: $startDate, displayedComponents: .date)
                        .onChange(of: startDate) { _, newStart in
                            if endDate < newStart {
                                endDate = newStart
                            }
                            if endDate > maxEndDate {
                                endDate = maxEndDate
                            }
                        }
                    DatePicker(
                        "종료일",
                        selection: $endDate,
                        in: startDate...max(startDate, maxEndDate),
                        displayedComponents: .date
                    )
                }

                Section {
                    HStack {
                        Text("선택 기간")
                        Spacer()
                        Text("\(selectedDays)일")
                            .foregroundStyle(selectedDays > remainingDays ? .red : .secondary)
                    }
                } footer: {
                    Text("이달 남은 일시정지: \(remainingDays)일")
                }

                Section("메모 (선택)") {
                    TextField("사유를 입력하세요 (예: 여행, 병가)", text: $reason)
                }
            }
            .navigationTitle("일시정지 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        let pause = HabitPause(
                            id: UUID(),
                            startDate: Calendar.current.startOfDay(for: startDate),
                            endDate: Calendar.current.startOfDay(for: endDate),
                            reason: reason.isEmpty ? nil : reason
                        )
                        HabitPauseService.shared.addPause(pause)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
