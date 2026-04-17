import SwiftUI
import FirebaseCore
import SwiftData

@main
struct NinetyNineApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LocalUserProfile.self,
            LocalProject.self,
            LocalDailyRecord.self,
            LocalAlarmConfig.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            ModelContextProvider.setup(with: container)
            return container
        } catch {
            // MARK: - 스키마 마이그레이션 실패 처리
            // WARNING: 아래 스토어 삭제 코드는 개발/테스트 빌드에서만 실행됩니다.
            // 프로덕션 배포 전에 VersionedSchema + MigrationPlan 으로 교체하세요.
            // 참고: https://developer.apple.com/documentation/swiftdata/migratingyourswiftdatamodelautomatically
            #if DEBUG
            let storeURL = config.url
            let shmURL = storeURL.appendingPathExtension("shm")
            let walURL = storeURL.appendingPathExtension("wal")
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: shmURL)
            try? FileManager.default.removeItem(at: walURL)
            do {
                let freshContainer = try ModelContainer(for: schema, configurations: [config])
                ModelContextProvider.setup(with: freshContainer)
                return freshContainer
            } catch {
                fatalError("SwiftData ModelContainer 생성 실패: \(error)")
            }
            #else
            // 프로덕션: 데이터 삭제 금지 — fatalError로 크래시 리포트 수집 후 VersionedSchema 마이그레이션 적용
            fatalError("SwiftData ModelContainer 생성 실패 (프로덕션). 스키마 마이그레이션을 구현하세요: \(error)")
            #endif
        }
    }()

    @AppStorage("colorSchemePreference") private var colorSchemePreference: String = "system"

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil  // "system" → SwiftUI 기본 동작
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .modelContainer(sharedModelContainer)
            .preferredColorScheme(preferredColorScheme)
            .task {
                // 앱 시작 즉시 현재 배경 이미지 프리페치 → 홈화면 버퍼 제거
                MotivationService.shared.prefetchCurrentImage()
                await MotivationService.shared.fetchIfNeeded()
            }
        }
    }
}
