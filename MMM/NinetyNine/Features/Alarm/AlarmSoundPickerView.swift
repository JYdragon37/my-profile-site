import SwiftUI
import AVFoundation

struct AlarmSoundPickerView: View {

    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss
    @State private var previewPlayer: AVAudioPlayer?

    let sounds: [(id: String, name: String)] = [
        ("default",    "기본 알람"),
        ("chime",      "차임"),
        ("radar",      "레이더"),
        ("xylophone",  "실로폰"),
        ("bell",       "벨"),
        ("silent",     "무음 (진동만)"),
    ]

    var body: some View {
        NavigationStack {
            List(sounds, id: \.id) { sound in
                Button {
                    selected = sound.id
                    previewSound(sound.id)
                } label: {
                    HStack {
                        Text(sound.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selected == sound.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                        if sound.id != "silent" {
                            Button {
                                previewSound(sound.id)
                            } label: {
                                Image(systemName: "play.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("알람음")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        previewPlayer?.stop()
                        dismiss()
                    }
                }
            }
        }
    }

    private func previewSound(_ soundID: String) {
        previewPlayer?.stop()
        guard soundID != "silent" else { return }
        let name = soundID == "default" ? "alarm_default" : soundID
        guard let url = Bundle.main.url(forResource: name, withExtension: "caf")
                     ?? Bundle.main.url(forResource: name, withExtension: "wav")
        else { return }
        previewPlayer = try? AVAudioPlayer(contentsOf: url)
        previewPlayer?.play()
    }
}
