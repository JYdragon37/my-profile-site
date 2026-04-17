import SwiftUI

// MARK: - 루틴 편집 메인 뷰
struct RoutineEditView: View {

    @ObservedObject var vm: SettingsViewModel
    @State private var editingProject: Project?
    @State private var isShowingSaveModal = false
    @State private var isShowingNewVersionForm = false
    @State private var newVersionName = ""
    @State private var newVersionStartDate = Date()

    var body: some View {
        Group {
            if let _ = editingProject {
                ScrollView {
                    VStack(spacing: 0) {
                        // ── 라이브 프리뷰 카드 ─────────────────
                        projectPreviewCard
                            .padding(.horizontal, Spacing.xl)
                            .padding(.top, Spacing.xl)
                            .padding(.bottom, Spacing.xxl)

                        // ── 이름 + 이모지 + 컬러 ──────────────
                        metaSection

                        Divider().padding(.vertical, Spacing.xl)

                        // ── 루틴 항목 ─────────────────────────
                        routineSection

                        // ── 저장 버튼 ─────────────────────────
                        saveButton
                            .padding(.top, Spacing.xxl)
                            .padding(.bottom, Spacing.huge)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("루틴 편집")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            editingProject = vm.activeProject ?? Project.new()
        }
        .confirmationDialog("어떻게 저장할까요?", isPresented: $isShowingSaveModal) {
            Button("현재 루틴 수정") {
                if let p = editingProject { vm.saveRoutine(p, asNewVersion: false) }
            }
            Button("새 버전으로 시작") {
                newVersionName = "\(editingProject?.name ?? "일상습관") v\((vm.activeProject?.version ?? 1) + 1)"
                newVersionStartDate = Date()
                isShowingNewVersionForm = true
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("현재 루틴 수정은 기존 기록에 영향을 주지 않아요.\n새 버전은 새 시작일부터 적용돼요.")
        }
        .sheet(isPresented: $isShowingNewVersionForm) {
            NewVersionFormView(
                name: $newVersionName,
                startDate: $newVersionStartDate,
                colorHex: Binding(
                    get: { editingProject?.colorHex ?? "#4A9EFF" },
                    set: { editingProject?.colorHex = $0 }
                ),
                emoji: Binding(
                    get: { editingProject?.emoji ?? "⚡" },
                    set: { editingProject?.emoji = $0 }
                ),
                onConfirm: {
                    if let p = editingProject {
                        vm.saveNewVersion(p, name: newVersionName, startDate: newVersionStartDate)
                    }
                    isShowingNewVersionForm = false
                },
                onCancel: { isShowingNewVersionForm = false }
            )
        }
    }

    // MARK: - 프리뷰 카드
    private var projectPreviewCard: some View {
        ZStack(alignment: .topTrailing) {
            // 카드 배경
            RoundedRectangle(cornerRadius: 20)
                .fill(themeColor.gradient)

            VStack(alignment: .leading, spacing: 14) {
                // 이모지 + 이름
                HStack(spacing: 10) {
                    Text(editingProject?.emoji ?? "⚡")
                        .font(.system(size: 36))
                    Text(editingProject?.name ?? "일상습관")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Divider().background(.white.opacity(0.3))

                // 세 그룹 미리보기
                VStack(alignment: .leading, spacing: 8) {
                    previewRow(icon: "⚡", label: "뚝딱",
                               items: editingProject?.weekdayRoutine.spark ?? [])
                    previewRow(icon: "🔹", label: "착착",
                               items: editingProject?.weekdayRoutine.flow ?? [])
                    previewRow(icon: "🔵", label: "몰입",
                               items: editingProject?.weekdayRoutine.deep ?? [])
                }
            }
            .padding(20)

            // Preview 배지
            Text("Preview")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.white.opacity(0.2))
                .clipShape(Capsule())
                .rotationEffect(.degrees(35))
                .offset(x: -8, y: 12)
        }
        .frame(maxWidth: .infinity)
        .shadow(color: themeColor.opacity(0.35), radius: 16, y: 6)
    }

    private func previewRow(icon: String, label: String, items: [String]) -> some View {
        HStack(spacing: 8) {
            // 아이콘 + 라벨
            HStack(spacing: 4) {
                Text(icon).font(.caption)
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 26, alignment: .leading)
            }
            // 항목 미리보기
            Text(items.filter { !$0.isEmpty }.prefix(2).joined(separator: " · "))
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
        }
    }

    // MARK: - 메타 섹션 (이름 / 이모지 / 색상)
    private var metaSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxl) {

            // 프로젝트 이름
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("프로젝트 이름", systemImage: "text.cursor")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.labelSec)
                    .padding(.horizontal, Spacing.xl)

                HStack {
                    TextField("일상습관", text: Binding(
                        get: { editingProject?.name ?? "" },
                        set: { editingProject?.name = $0 }
                    ))
                    .font(.body)
                    .padding(Spacing.md)
                    .background(AppColor.bgSecond)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                }
                .padding(.horizontal, Spacing.xl)
            }

            // 이모지 선택
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("프로젝트 이모지", systemImage: "face.smiling")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.labelSec)
                    .padding(.horizontal, Spacing.xl)

                EmojiPickerRow(
                    selected: Binding(
                        get: { editingProject?.emoji ?? "⚡" },
                        set: { editingProject?.emoji = $0 }
                    )
                )
                .padding(.horizontal, Spacing.xl)
            }

            // 색상 선택
            VStack(alignment: .leading, spacing: Spacing.md) {
                Label("루틴 색상 변경", systemImage: "paintpalette")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.labelSec)
                    .padding(.horizontal, Spacing.xl)

                ColorPickerGrid(
                    selectedHex: Binding(
                        get: { editingProject?.colorHex ?? "#4A9EFF" },
                        set: { editingProject?.colorHex = $0 }
                    )
                )
                .padding(.horizontal, Spacing.xl)
            }
        }
    }

    // MARK: - 루틴 항목 섹션
    private var routineSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxl) {
            routineGroup(type: .spark,
                         items: editingProject?.weekdayRoutine.spark ?? [])
            routineGroup(type: .flow,
                         items: editingProject?.weekdayRoutine.flow ?? [])
            routineGroup(type: .deep,
                         items: editingProject?.weekdayRoutine.deep ?? [])
        }
        .padding(.horizontal, Spacing.xl)
    }

    private func routineGroup(type: ItemType, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Text(type.emoji)
                Text("\(type.displayName) (\(type == .spark ? "3초" : type == .flow ? "3분" : "30분"))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.labelSec)
            }
            RoutineItemsEditor(
                type: type,
                items: items,
                onEdit: { i, val in updateItem(type: type, index: i, value: val) },
                onDelete: { i in deleteItem(type: type, index: i) }
            )
            .padding(Spacing.md)
            .background(AppColor.bgSecond)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
    }

    // MARK: - 저장 버튼
    private var saveButton: some View {
        Button("저장하기") {
            isShowingSaveModal = true
        }
        .font(.headline)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: ButtonHeight.primary)
        .background(themeColor.gradient)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: - 헬퍼
    private var themeColor: Color {
        Color(hex: editingProject?.colorHex ?? "#4A9EFF")
    }

    private func updateItem(type: ItemType, index: Int, value: String) {
        switch type {
        case .spark: editingProject?.weekdayRoutine.spark[index] = value
        case .flow:  editingProject?.weekdayRoutine.flow[index]  = value
        case .deep:  editingProject?.weekdayRoutine.deep[index]  = value
        }
    }

    private func deleteItem(type: ItemType, index: Int) {
        switch type {
        case .spark:
            guard index < (editingProject?.weekdayRoutine.spark.count ?? 0) else { return }
            editingProject?.weekdayRoutine.spark.remove(at: index)
        case .flow:
            guard index < (editingProject?.weekdayRoutine.flow.count ?? 0) else { return }
            editingProject?.weekdayRoutine.flow.remove(at: index)
        case .deep:
            guard index < (editingProject?.weekdayRoutine.deep.count ?? 0) else { return }
            editingProject?.weekdayRoutine.deep.remove(at: index)
        }
    }
}

// MARK: - 이모지 선택 행
private struct EmojiPickerRow: View {
    @Binding var selected: String

    private let presets = ["⚡","🔥","🎯","💪","🌱","📚","🏃","🧘","✍️","🎨","💡","🎵","🏆","❤️","🌟","🧩","🚀","☀️"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(presets, id: \.self) { emoji in
                    Button {
                        selected = emoji
                        Haptic.tap()
                    } label: {
                        Text(emoji)
                            .font(.system(size: 26))
                            .frame(width: 44, height: 44)
                            .background(selected == emoji
                                        ? AppColor.accent.opacity(0.15)
                                        : AppColor.bgSecond)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.sm)
                                    .stroke(selected == emoji ? AppColor.accent : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - 색상 팔레트 그리드 (레퍼런스 이미지 동일 구성)
struct ColorPickerGrid: View {
    @Binding var selectedHex: String

    private let palette: [[String]] = [
        ["#F44336", "#E91E8C", "#FF6D00", "#FFC107", "#4CAF50"],
        ["#2E7D32", "#2196F3", "#7C4DFF", "#9C27B0", "#880E4F"],
        ["#F48FB1", "#CE93D8", "#FFAB91", "#FFF176", "#A5D6A7"],
        ["#4A9EFF", "#B39DDB", "#CE93D8"],
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(palette.indices, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(palette[row], id: \.self) { hex in
                        colorDot(hex: hex)
                    }
                    if row == palette.count - 1 { Spacer() }
                }
            }
        }
    }

    private func colorDot(hex: String) -> some View {
        let isSelected = selectedHex.lowercased() == hex.lowercased()
        return Button {
            selectedHex = hex
            Haptic.tap()
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 42, height: 42)
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 42, height: 42)
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - 새 버전 폼 시트 (색상/이모지/오늘 버튼 포함)
struct NewVersionFormView: View {
    @Binding var name: String
    @Binding var startDate: Date
    @Binding var colorHex: String
    @Binding var emoji: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xxl) {

                    // 미니 프리뷰 카드
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: colorHex).gradient)
                        .frame(height: 80)
                        .overlay(
                            HStack(spacing: 10) {
                                Text(emoji).font(.system(size: 28))
                                Text(name.isEmpty ? "새 버전" : name)
                                    .font(.title3.bold())
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Spacer()
                                Text("Preview")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 20)
                        )
                        .padding(.horizontal, Spacing.xl)

                    // 이름
                    fieldSection(title: "버전 이름") {
                        TextField("예: 일상습관 v2", text: $name)
                            .padding(Spacing.md)
                            .background(AppColor.bgSecond)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    }

                    // 이모지
                    fieldSection(title: "이모지") {
                        EmojiPickerRow(selected: $emoji)
                    }

                    // 색상
                    fieldSection(title: "루틴 색상") {
                        ColorPickerGrid(selectedHex: $colorHex)
                    }

                    // 시작일 — "오늘" 퀵버튼
                    fieldSection(title: "시작일") {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                DatePicker(
                                    "",
                                    selection: $startDate,
                                    in: Calendar.current.startOfDay(for: Date())...,
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                Spacer()
                                Button("오늘") {
                                    startDate = Date()
                                    Haptic.tap()
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(hex: colorHex))
                                .clipShape(Capsule())
                            }
                            Text("오늘 바로 시작해도 좋아요!")
                                .font(.caption)
                                .foregroundStyle(AppColor.labelSec)
                        }
                        .padding(Spacing.md)
                        .background(AppColor.bgSecond)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    }
                }
                .padding(.top, Spacing.xxl)
                .padding(.bottom, Spacing.huge)
            }
            .navigationTitle("새 버전 시작")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소", action: onCancel) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("확인", action: onConfirm)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func fieldSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.labelSec)
                .padding(.horizontal, Spacing.xl)
            content()
                .padding(.horizontal, Spacing.xl)
        }
    }
}

// MARK: - 루틴 항목 편집기 (기존 유지)
struct RoutineItemsEditor: View {
    let type: ItemType
    let items: [String]
    let onEdit: (Int, String) -> Void
    var onDelete: ((Int) -> Void)? = nil
    @State private var loadingIndex: Int? = nil

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                HStack {
                    Text("\(i + 1).")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    TextField("항목 입력", text: Binding(
                        get: { items[i] },
                        set: { onEdit(i, $0) }
                    ))
                    if let del = onDelete {
                        Button { del(i) } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, Spacing.xs)
            }

            Button {
                Task { await suggestAllEmojis() }
            } label: {
                HStack(spacing: 4) {
                    if loadingIndex == -1 {
                        ProgressView().scaleEffect(0.7).frame(width: 14, height: 14)
                    } else {
                        Text("✨").font(.caption)
                    }
                    Text("이모지 자동 생성")
                }
                .font(.caption)
                .foregroundStyle(AppColor.accent)
            }
            .buttonStyle(.plain)
            .disabled(loadingIndex != nil)
            .padding(.top, Spacing.sm)
        }
    }

    private func suggestAllEmojis() async {
        loadingIndex = -1
        let emojis = await EmojiSuggestionService.shared.suggestEmojis(for: items)
        for (i, emoji) in emojis {
            let updated = EmojiSuggestionService.applyEmoji(emoji, to: items[i])
            onEdit(i, updated)
        }
        loadingIndex = nil
    }
}

// MARK: - 루틴 히스토리
struct RoutineHistoryView: View {
    @ObservedObject var vm: SettingsViewModel

    var body: some View {
        List(vm.projects) { project in
            HStack(spacing: Spacing.md) {
                // 컬러 도트
                Circle()
                    .fill(Color(hex: project.colorHex))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(project.emoji) \(project.name) v\(project.version)")
                            .font(.headline)
                        statusBadge(for: project)
                        Spacer()
                    }
                    Text(dateRangeString(project))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if project.status == .completed {
                        let rate = vm.completionRate(for: project)
                        Text("완료율 \(Int(rate * 100))%")
                            .font(.caption)
                            .foregroundStyle(AppColor.labelSec)
                    }

                    if project.status == .scheduled {
                        HStack(spacing: Spacing.sm) {
                            Button("편집") {}
                                .font(.caption).foregroundStyle(AppColor.accent).buttonStyle(.plain)
                            Button("예약 취소") { vm.cancelScheduledVersion(project) }
                                .font(.caption).foregroundStyle(AppColor.warning).buttonStyle(.plain)
                        }
                        .padding(.top, Spacing.xs)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("루틴 히스토리")
        .onAppear { vm.loadProjects() }
    }

    @ViewBuilder
    private func statusBadge(for project: Project) -> some View {
        switch project.status {
        case .active:
            Text("● 활성").font(.caption).foregroundStyle(.green)
        case .scheduled:
            Text("⏰ 예약").font(.caption).foregroundStyle(.orange)
        case .completed:
            EmptyView()
        }
    }

    private func dateRangeString(_ project: Project) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy. M. d"
        let start = f.string(from: project.startDate)
        if let end = project.endDate { return "\(start) ~ \(f.string(from: end))" }
        return "\(start) ~ 현재"
    }
}

// MARK: - Color(hex:) 확장
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r, g, b: UInt64
        switch h.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0x4A, 0x9E, 0xFF)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
