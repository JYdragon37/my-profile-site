import SwiftUI

struct NicknameInputView: View {
    @Binding var nickname: String
    let onNext: () -> Void
    @FocusState private var isFocused: Bool

    var isValid: Bool {
        !nickname.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 40) {
                VStack(spacing: 16) {
                    Text("마지막으로,")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    Text("이름을 알려주세요 😊")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("뭐라고 불러드릴까요?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // 닉네임 입력
                VStack(spacing: 8) {
                    TextField("닉네임 입력", text: $nickname)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit { if isValid { onNext() } }

                    Text("앱 곳곳에서 이름으로 불러드릴게요")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button("다음", action: onNext)
                .buttonStyle(PrimaryButtonStyle(isEnabled: isValid))
                .disabled(!isValid)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
        }
        .onAppear { isFocused = true }
    }
}
