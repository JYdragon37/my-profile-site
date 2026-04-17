import SwiftUI

struct SettingsView: View {

    @StateObject private var vm = SettingsViewModel()
    @Environment(\.modelContext) private var modelContext
    @AppStorage("userNickname") private var nickname: String = "친구"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true
    @AppStorage("devModeEnabled") private var devModeEnabled: Bool = false
    @State private var versionTapCount: Int = 0

    var body: some View {
        NavigationStack {
            List {
                // 닉네임 섹션
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(.secondarySystemFill))
                                .frame(width: 52, height: 52)
                            Text(String(nickname.prefix(1)))
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("안녕하세요, \(nickname) 👋")
                                .font(.headline)
                            Text("닉네임 변경")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { vm.isShowingNicknameEdit = true }
                }

                // 루틴 섹션
                Section("내 루틴") {
                    NavigationLink("루틴 편집") {
                        RoutineEditView(vm: vm)
                    }
                    NavigationLink("루틴 히스토리") {
                        RoutineHistoryView(vm: vm)
                    }
                }

                // 앱 설정
                Section("앱 설정") {
                    NavigationLink {
                        NotificationSettingsPage()
                    } label: {
                        Label("알림 설정", systemImage: "bell.badge")
                    }
                    NavigationLink("테마") {
                        ThemePickerView()
                    }
                }

                // 기타
                Section("기타") {
                    Button("앱 평가하기") { vm.requestAppReview() }
                    Button("문의하기") { vm.openSupport() }
                    HStack {
                        Text("버전")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        versionTapCount += 1
                        if versionTapCount >= 7 { devModeEnabled = true }
                    }
                }

                // 개발자 모드
                if devModeEnabled {
                    Section(header: Text("개발자 모드"), footer: Text("버전을 7번 탭하면 이 메뉴가 나타납니다.")) {
                        Button("온보딩 화면 다시 보기") {
                            UserDefaults.standard.set(0, forKey: "onboarding_step")
                            UserDefaults.standard.set("", forKey: "onboarding_nickname")
                            UserDefaults.standard.set("", forKey: "onboarding_template")
                            hasCompletedOnboarding = false
                        }
                        .foregroundStyle(.orange)
                        Button("개발자 모드 끄기") {
                            devModeEnabled = false
                            versionTapCount = 0
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("설정")
            .sheet(isPresented: $vm.isShowingNicknameEdit) {
                NicknameEditSheet(nickname: $nickname)
                    .presentationDetents([.height(280)])
            }
        }
        .onAppear {
            vm.setup(modelContext: modelContext)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

// MARK: - 닉네임 편집 시트
struct NicknameEditSheet: View {
    @Binding var nickname: String
    @State private var draft: String = ""
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text("닉네임 변경")
                .font(.headline)
                .padding(.top, 24)

            TextField("닉네임", text: $draft)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .focused($focused)
                .padding(.horizontal, 24)

            Button("저장") {
                let trimmed = draft.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { nickname = trimmed }
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.primary)
            .padding(.bottom, 24)
        }
        .onAppear { draft = nickname; focused = true }
    }
}

// MARK: - 테마 선택
struct ThemePickerView: View {
    @AppStorage("colorSchemePreference") private var preference: String = "system"

    var body: some View {
        List {
            ForEach([("system", "시스템"), ("light", "라이트"), ("dark", "다크")], id: \.0) { id, label in
                HStack {
                    Text(label)
                    Spacer()
                    if preference == id { Image(systemName: "checkmark").foregroundStyle(.blue) }
                }
                .contentShape(Rectangle())
                .onTapGesture { preference = id }
            }
        }
        .navigationTitle("테마")
    }
}
