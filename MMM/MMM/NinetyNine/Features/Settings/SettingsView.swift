import SwiftUI

struct SettingsView: View {

    @StateObject private var vm = SettingsViewModel()
    @Environment(\.modelContext) private var modelContext
    @AppStorage("userNickname") private var nickname: String = "친구"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true

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
                    NavigationLink {
                        HabitPauseView()
                    } label: {
                        Label("스트릭 보호", systemImage: "pause.circle")
                    }
                }

                // 기타
                Section("기타") {
                    Button("앱 평가하기") { vm.requestAppReview() }
                    Button("문의하기") { vm.openSupport() }
                    HStack {
                        Text("버전")
                        Spacer()
                        Text(appVersion).foregroundStyle(.secondary)
                    }
                }

                // 개발자 도구 (DEBUG 빌드에서만 표시)
                #if DEBUG
                Section {
                    NavigationLink {
                        DevToolsView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    } label: {
                        Label("개발자 도구", systemImage: "hammer.fill")
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("개발자")
                } footer: {
                    Text("DEBUG 빌드에서만 표시됩니다.")
                }
                #endif
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

// MARK: - 개발자 도구 (DEBUG only)
#if DEBUG
struct DevToolsView: View {
    @Binding var hasCompletedOnboarding: Bool
    @AppStorage("userNickname") private var nickname: String = "친구"
    @AppStorage("currentStreak") private var streak: Int = 0
    @State private var showResetConfirm = false
    @State private var showOnboardingResetConfirm = false

    var body: some View {
        List {
            // 온보딩
            Section("온보딩") {
                Button {
                    showOnboardingResetConfirm = true
                } label: {
                    Label("온보딩 다시 보기", systemImage: "arrow.counterclockwise")
                }
                .foregroundStyle(.orange)
                .confirmationDialog("온보딩을 다시 시작할까요?", isPresented: $showOnboardingResetConfirm, titleVisibility: .visible) {
                    Button("다시 보기", role: .destructive) { resetOnboarding() }
                    Button("취소", role: .cancel) {}
                } message: {
                    Text("닉네임·루틴 설정부터 다시 시작됩니다.")
                }
            }

            // 상태 초기화
            Section("상태 초기화") {
                Button {
                    streak = 0
                    Haptic.success()
                } label: {
                    Label("스트릭 초기화", systemImage: "flame.slash")
                }
                .foregroundStyle(.red)

                Button {
                    UserDefaults.standard.removeObject(forKey: "motivation_locked_image_id")
                    UserDefaults.standard.removeObject(forKey: "motivation_image_lock_zone")
                    UserDefaults.standard.removeObject(forKey: "motivation_locked_quote_id")
                    UserDefaults.standard.removeObject(forKey: "motivation_quote_lock_expiry")
                    Haptic.success()
                } label: {
                    Label("동기부여 콘텐츠 잠금 해제", systemImage: "arrow.clockwise")
                }
                .foregroundStyle(.blue)

                Button {
                    UserDefaults.standard.removeObject(forKey: "com.ninetynine.badges")
                    BadgeService.shared.badges = Badge.allDefinitions
                    Haptic.success()
                } label: {
                    Label("뱃지 초기화", systemImage: "medal.slash")
                }
                .foregroundStyle(.red)
            }

            // 빌드 정보
            Section("빌드 정보") {
                infoRow("Bundle ID",    Bundle.main.bundleIdentifier ?? "-")
                infoRow("버전",         Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-")
                infoRow("빌드",         Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-")
                infoRow("닉네임",       nickname)
                infoRow("스트릭",       "\(streak)일")
                infoRow("온보딩 완료",  hasCompletedOnboarding ? "true" : "false")
            }
        }
        .navigationTitle("개발자 도구")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func resetOnboarding() {
        UserDefaults.standard.set(0,  forKey: "onboarding_step")
        UserDefaults.standard.set("", forKey: "onboarding_nickname")
        UserDefaults.standard.set("", forKey: "onboarding_template")
        hasCompletedOnboarding = false
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption.monospaced()).foregroundStyle(.primary)
        }
        .font(.subheadline)
    }
}
#endif

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
