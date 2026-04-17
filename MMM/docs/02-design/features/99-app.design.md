# 99 App — Design Document

> 작성일: 2026-04-15
> 아키텍처: MVVM + Repository (Option C)
> 다음 단계: `/pdca do 99-app`

---

## Context Anchor

| 항목 | 내용 |
|------|------|
| **WHY** | 기존 Todo 앱은 미루게 만든다. 99분 챌린지로 중요한 것을 먼저 끝내고 나머지 시간을 해방하는 새로운 패러다임 |
| **WHO** | 번아웃 직전 30대 퍼포머, 집중력 지원 필요한 크리에이터/학생, 생산성 방법론 실천가 |
| **RISK** | 알람 신뢰성 (iOS 백그라운드), 온보딩 이탈 (9개 세팅 허들), Firebase 의존성 |
| **SUCCESS** | D-90 DAU 1,000명, 챌린지 완료율 70%, 알람 전환율 60%, App Store 4.5점 |
| **SCOPE** | iOS 17+ 전용 MVP. SwiftUI + Firebase + 알람 + 구글시트 연동 |

---

## 1. 아키텍처 개요

### 선택: MVVM + Repository Pattern

```
┌─────────────────────────────────────────────┐
│                  SwiftUI Views               │
│  OnboardingView  TodayView  AlarmView       │
│  RecordView      SettingsView               │
└──────────────────┬──────────────────────────┘
                   │ @StateObject / @ObservedObject
┌──────────────────▼──────────────────────────┐
│                ViewModels                    │
│  OnboardingVM  TodayVM  AlarmVM             │
│  RecordVM      SettingsVM                   │
└──────────────────┬──────────────────────────┘
                   │ Protocol 기반 의존성
┌──────────────────▼──────────────────────────┐
│              Services / Repositories         │
│  UserRepository      AlarmService           │
│  RoutineRepository   MotivationService      │
│  RecordRepository    AnalyticsService       │
└──────────────────┬──────────────────────────┘
                   │
┌──────────┬───────▼───────┬──────────────────┐
│ Firestore │  SwiftData   │  외부 서비스       │
│ (Cloud)   │  (Local)     │  구글시트 CSV      │
│           │              │  Firebase Storage  │
│           │              │  UNNotification   │
└──────────┴───────────────┴──────────────────┘
```

### 핵심 설계 원칙
1. **오프라인 우선**: SwiftData가 항상 Source of Truth, Firestore는 동기화
2. **단방향 데이터 흐름**: View → ViewModel → Repository → DataSource
3. **Protocol 기반**: 각 Service/Repository는 Protocol로 추상화 (테스트 가능)
4. **알람 독립성**: AlarmService는 앱 생명주기와 독립적으로 동작

---

## 2. 프로젝트 구조

```
NinetyNine/
├── App/
│   ├── NinetyNineApp.swift          # 앱 진입점, Firebase 초기화
│   ├── AppDelegate.swift            # 알람 백그라운드 처리
│   └── ContentView.swift            # 탭 구조 (TabView)
│
├── Core/
│   ├── Models/                      # 데이터 모델
│   │   ├── UserProfile.swift
│   │   ├── Project.swift
│   │   ├── Routine.swift
│   │   ├── DailyRecord.swift
│   │   ├── AlarmConfig.swift
│   │   └── MotivationContent.swift
│   │
│   ├── Repositories/                # 데이터 레이어
│   │   ├── Protocols/
│   │   │   ├── UserRepositoryProtocol.swift
│   │   │   ├── RoutineRepositoryProtocol.swift
│   │   │   └── RecordRepositoryProtocol.swift
│   │   ├── UserRepository.swift     # Firestore + SwiftData
│   │   ├── RoutineRepository.swift
│   │   └── RecordRepository.swift
│   │
│   └── Services/                    # 비즈니스 로직
│       ├── AlarmService.swift       # UNUserNotificationCenter
│       ├── AudioService.swift       # AVFoundation
│       ├── MotivationService.swift  # 구글시트 + Firebase Storage
│       ├── AnalyticsService.swift   # Firebase Analytics 래핑
│       └── ChallengeTimer.swift     # 199분 타이머 로직
│
├── Features/
│   ├── Onboarding/
│   │   ├── OnboardingView.swift
│   │   ├── OnboardingViewModel.swift
│   │   ├── ConceptSlideView.swift
│   │   ├── NicknameInputView.swift
│   │   ├── AlarmSetupView.swift
│   │   └── RoutineSetupView.swift
│   │
│   ├── Today/
│   │   ├── TodayView.swift
│   │   ├── TodayViewModel.swift
│   │   ├── ChallengeView.swift      # 진행 중 화면
│   │   ├── TimerPopupView.swift     # 착착/몰입 타이머
│   │   ├── CompletionView.swift     # 해방 화면
│   │   └── IncompleteView.swift     # 미완료 화면
│   │
│   ├── Alarm/
│   │   ├── AlarmListView.swift
│   │   ├── AlarmViewModel.swift
│   │   ├── AlarmEditView.swift
│   │   ├── AlarmSoundPickerView.swift
│   │   └── AlarmFullscreenView.swift  # 알람 전체화면
│   │
│   ├── Record/
│   │   ├── RecordView.swift
│   │   ├── RecordViewModel.swift
│   │   ├── CalendarView.swift
│   │   ├── DayDetailView.swift
│   │   ├── ChartView.swift
│   │   └── StatsView.swift
│   │
│   └── Settings/
│       ├── SettingsView.swift
│       ├── SettingsViewModel.swift
│       ├── RoutineEditView.swift
│       ├── RoutineHistoryView.swift
│       └── ItemEditView.swift
│
├── Shared/
│   ├── Components/                  # 재사용 UI 컴포넌트
│   │   ├── RoutineItemRow.swift
│   │   ├── ProgressBar.swift
│   │   ├── CountdownTimerView.swift
│   │   └── StreakBadgeView.swift
│   ├── Extensions/
│   └── Constants.swift              # SHEET_ID, 타이머 설정값 등
│
└── Resources/
    ├── GoogleService-Info.plist
    ├── DefaultMotivation.json       # 오프라인 기본 이미지/글귀
    └── RoutineTemplates.json        # 온보딩 템플릿 데이터
```

---

## 3. 핵심 데이터 모델

```swift
// MARK: - UserProfile
struct UserProfile: Codable {
    var id: String           // Firebase Auth UID
    var nickname: String
    var createdAt: Date
    var activeProjectId: String?
}

// MARK: - Project
struct Project: Codable, Identifiable {
    var id: String
    var name: String         // 기본값: "일상습관"
    var version: Int
    var startDate: Date
    var endDate: Date?
    var weekdayRoutine: Routine
    var weekendRoutine: Routine
}

// MARK: - Routine
struct Routine: Codable {
    var spark: [String]      // 뚝딱 × 3 (3초)
    var flow: [String]       // 착착 × 3 (3분)
    var deep: [String]       // 몰입 × 3 (30분)

    var allItems: [RoutineItem] {
        // spark + flow + deep → RoutineItem 배열 (타입 포함)
    }
}

// MARK: - RoutineItem
struct RoutineItem: Identifiable {
    var id: Int              // 0~8 인덱스
    var title: String
    var type: ItemType       // .spark / .flow / .deep
    var duration: Int        // 초 단위 (3 / 180 / 1800)
}

enum ItemType {
    case spark   // 뚝딱 (3초, 즉시 완료)
    case flow    // 착착 (3분, 타이머)
    case deep    // 몰입 (30분, 타이머)
}

// MARK: - DailyRecord
struct DailyRecord: Codable {
    var date: String         // "YYYY-MM-DD"
    var completedCount: Int  // 0~9
    var elapsedMinutes: Int  // 실제 소요시간
    var isSuccess: Bool      // 9/9 완료 여부
    var itemStatus: [Bool]   // 9개 각 완료 여부
}

// MARK: - AlarmConfig (로컬만, Firestore 미동기)
struct AlarmConfig: Identifiable, Codable {
    var id: UUID
    var label: String
    var hour: Int
    var minute: Int
    var repeatDays: Set<Weekday>
    var soundName: String
    var volume: Float        // 0.0~1.0
    var fadeIn: Bool
    var vibration: Bool
    var snoozeEnabled: Bool
    var snoozeDuration: Int  // 분
    var snoozeMaxCount: Int
    var challengeAutoStart: Bool
    var isEnabled: Bool
}

// MARK: - MotivationContent
struct MotivationContent: Codable {
    var id: Int
    var storagePath: String  // Firebase Storage 경로
    var quote: String
    var author: String
    var cachedImageURL: URL? // 로컬 캐시 URL
}
```

---

## 4. 서비스 레이어 설계

### 4-1. ChallengeTimer
```swift
class ChallengeTimer: ObservableObject {
    static let totalSeconds = 199 * 60  // 내부: 199분
    static let brandName = "99분 챌린지" // 외부: 99분

    @Published var remainingSeconds: Int = totalSeconds
    @Published var isRunning: Bool = false
    @Published var startedAt: Date?

    func start()     // 타이머 시작
    func pause()     // 일시정지 (배경 전환 시)
    func resume()    // 재개
    func stop() -> Int  // 종료 → 실제 소요시간(분) 반환
}
```

### 4-2. AlarmService
```swift
class AlarmService {
    // 알람 예약 (UNUserNotificationCenter)
    func scheduleAlarm(_ config: AlarmConfig)
    func cancelAlarm(_ id: UUID)
    func cancelAllAlarms()

    // 알람 해제 처리
    func handleAlarmDismissed(_ alarmId: UUID) {
        // challengeAutoStart가 true면 → ChallengeTimer.start()
        // AnalyticsService.log("alarm_dismissed")
    }

    // 권한 요청
    func requestPermission() async -> Bool
}
```

### 4-3. MotivationService
```swift
class MotivationService: ObservableObject {
    @Published var contents: [MotivationContent] = []
    @Published var current: MotivationContent?

    // 앱 시작 시 구글시트 CSV fetch → 파싱 → 캐시
    func fetchAndCache() async
    // Firebase Storage URL 조합 → Kingfisher로 이미지 프리로드
    func preloadImages()
    // 다음 콘텐츠 (순서대로 or 랜덤)
    func next() -> MotivationContent
}
```

### 4-4. EmojiSuggestionService
```swift
class EmojiSuggestionService {
    private let client = AnthropicClient(apiKey: /* Info.plist */)

    // 단일 항목 → 이모지 1개
    func suggestEmoji(for text: String) async throws -> String {
        let prompt = """
        다음 할 일 텍스트에 가장 잘 어울리는 이모지를 딱 1개만 반환해.
        이모지 외에 다른 텍스트, 설명, 공백 없이 이모지만:
        \(text)
        """
        // claude-haiku-4-5, max_tokens: 10
        // 응답에서 첫 번째 이모지 문자 추출
    }

    // 9개 일괄 처리 — 병렬 async let
    func suggestEmojis(for items: [String]) async -> [String: String] {
        // items 배열 → [텍스트: 이모지] 딕셔너리 반환
        // 실패한 항목은 빈 문자열로 폴백
    }

    // 텍스트 끝 이모지 교체 유틸
    static func applyEmoji(_ emoji: String, to text: String) -> String {
        // 기존 텍스트 끝 이모지 제거 후 새 이모지 추가
        // "물 마시기 💧" + "🥤" → "물 마시기 🥤"
    }
}
```

### 4-5. AnalyticsService
```swift
class AnalyticsService {
    func log(_ event: AnalyticsEvent)
}

enum AnalyticsEvent {
    case onboardingCompleted
    case alarmSetDuringOnboarding
    case challengeStarted
    case challengeCompleted(elapsedMinutes: Int, streak: Int)
    case challengeFailed(completedCount: Int, reason: String)
    case alarmDismissed
    case alarmSnoozed(count: Int)
    case streakAchieved(days: Int)
    case routineEdited
}
```

### 4-5. UserRepository
```swift
class UserRepository: UserRepositoryProtocol {
    // Firestore 우선, 실패 시 SwiftData 폴백
    func getProfile() async throws -> UserProfile
    func saveProfile(_ profile: UserProfile) async throws
    func getActiveProject() async throws -> Project?
    func saveProject(_ project: Project) async throws
    func getDailyRecord(date: String) async throws -> DailyRecord?
    func saveDailyRecord(_ record: DailyRecord) async throws
    func getRecords(month: String) async throws -> [DailyRecord]
}
```

---

## 5. 화면별 ViewModel 설계

### TodayViewModel (핵심)
```swift
class TodayViewModel: ObservableObject {
    @Published var routine: [RoutineItem] = []
    @Published var completedItems: Set<Int> = []
    @Published var challengeState: ChallengeState = .beforeStart

    let timer: ChallengeTimer
    let repository: UserRepositoryProtocol
    let analytics: AnalyticsService

    enum ChallengeState {
        case beforeStart
        case inProgress
        case completed(elapsedMinutes: Int)
        case failed(completedCount: Int, reason: FailReason)
    }

    enum FailReason { case timeout, manualStop }

    func startChallenge()
    func completeItem(_ index: Int)
    func stopChallenge()  // 종료·기록
    func loadTodayRoutine()  // 요일 감지 → 평일/주말 자동 선택
}
```

---

## 6. 탭 구조 및 네비게이션

```swift
// ContentView.swift
TabView {
    TodayView()
        .tabItem { Label("오늘", systemImage: "checkmark.circle") }

    AlarmView()
        .tabItem { Label("알람", systemImage: "alarm") }

    RecordView()
        .tabItem { Label("기록", systemImage: "chart.bar") }

    SettingsView()
        .tabItem { Label("설정", systemImage: "gearshape") }
}

// 알람 전체화면 (별도 window scene or fullScreenCover)
// 온보딩 (첫 실행 시 sheet로 오버레이)
```

---

## 7. Firebase 연동 설계

### 인증 흐름
```
앱 첫 실행
  → Firebase Anonymous Auth 자동 로그인
  → Firestore에 UserProfile 생성
  → 이후 "Apple로 로그인" 시 익명 → 실계정 연결 (데이터 보존)
```

### Firestore 보안 규칙
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;

      match /projects/{projectId} {
        allow read, write: if request.auth.uid == userId;
      }
      match /records/{date} {
        allow read, write: if request.auth.uid == userId;
      }
    }
  }
}
```

### 오프라인 동기화 전략
```
읽기:  SwiftData 먼저 → 백그라운드에서 Firestore 동기화
쓰기:  SwiftData 즉시 저장 → Firestore 비동기 업로드
충돌:  최신 타임스탬프 기준 (서버 우선)
알람:  SwiftData만 (Firestore 미동기, 기기 종속)
```

---

## 8. 알람 전체화면 구현 전략

```
iOS 알람 전체화면 구현 방식:

1. UNUserNotificationCenter로 알람 예약
2. 알람 발동 시 → UNNotificationContent에 커스텀 카테고리
3. NotificationServiceExtension (선택) or
   앱이 foreground 진입 시 AlarmFullscreenView를 fullScreenCover로 표시
4. 백그라운드 오디오: AVAudioSession + Background Audio Mode
5. 잠금화면 표시: UNNotificationContent의 attachments로 이미지 포함

핵심:
- MotivationService.current → 이미지 + 글귀 표시
- UserProfile.nickname → "준비됐나요, {닉네임}?"
- 슬라이드 제스처로 알람 해제 → ChallengeTimer 시작
```

---

## 9. 구글시트 연동 설계

```
Constants.swift:
  static let sheetId = "YOUR_SHEET_ID"
  static let sheetCSVURL = "https://docs.google.com/spreadsheets/d/\(sheetId)/export?format=csv&gid=0"

MotivationService.fetchAndCache():
  1. URLSession으로 CSV fetch
  2. CSV 파싱 → [MotivationContent] 생성
  3. storagePath → Firebase Storage Download URL 조합
  4. Kingfisher로 이미지 프리로드 + 로컬 캐시
  5. UserDefaults에 콘텐츠 메타데이터 저장 (오프라인 대응)
  6. 실패 시 → DefaultMotivation.json (번들 내장) 사용
```

---

## 10. Remote Config 설계

```swift
// 앱 시작 시 fetch
RemoteConfig.remoteConfig().fetchAndActivate()

// 활용 키값
"onboarding_slide2_title"    // 온보딩 문구 A/B
"challenge_brand_name"       // "99분 챌린지" (변경 가능)
"timer_total_seconds"        // 199 * 60 (실험용)
"motivation_fetch_interval"  // 구글시트 fetch 주기 (시간)
"streak_milestone_days"      // [7, 14, 21, 30]
```

---

## 11. 구현 가이드

### 11.1 의존성 (Swift Package Manager)
```
Firebase iOS SDK
  - FirebaseAuth
  - FirebaseFirestore
  - FirebaseStorage
  - FirebaseAnalytics
  - FirebaseCrashlytics
  - FirebaseRemoteConfig

Kingfisher (이미지 캐싱)

Anthropic Swift SDK (이모지 자동 생성)
  - URL: https://github.com/anthropics/anthropic-sdk-swift
  - 용도: 루틴 항목 텍스트 → 이모지 1개 생성
  - 모델: claude-haiku-4-5 (빠르고 저렴, 단순 태스크에 최적)
  - API Key: Info.plist ANTHROPIC_API_KEY (RingDiary 키 재사용 가능)
```

### 11.2 Xcode Capabilities
```
✅ Background Modes
   - Audio, AirPlay, and Picture in Picture
   - Background fetch
   - Remote notifications

✅ Push Notifications
✅ Sign in with Apple
✅ In-App Purchase (V2 준비)
```

### 11.3 Session Guide (구현 순서)

```
Module 1 — 기반 (Sprint 1, ~2주)
  - Firebase 초기화 + Auth (익명 로그인)
  - Core Models (UserProfile, Project, Routine, DailyRecord)
  - SwiftData 로컬 저장소
  - UserRepository (Firestore + SwiftData)
  - Constants, AppDelegate 기본 구조

Module 2 — 온보딩 (Sprint 2, ~2주)
  - OnboardingView (4 슬라이드 + 닉네임 + 알람 + 루틴 세팅)
  - RoutineTemplates.json 데이터
  - OnboardingViewModel
  - 온보딩 완료 후 ContentView(TabView) 전환

Module 3 — 알람 (Sprint 3, ~2주)
  - AlarmService (UNUserNotificationCenter + AVFoundation)
  - AlarmConfig 모델 + SwiftData 저장
  - AlarmListView, AlarmEditView, AlarmSoundPickerView
  - MotivationService (구글시트 fetch + Kingfisher)
  - AlarmFullscreenView (이미지 + 글귀 + 닉네임)

Module 4 — 챌린지 (Sprint 4, ~2주)
  - ChallengeTimer (199분 카운트다운)
  - TodayView (시작 전 / 진행 중 / 완료 / 미완료)
  - TimerPopupView (착착 3분 / 몰입 30분)
  - CompletionView + IncompleteView
  - DailyRecord 저장 + Analytics 이벤트

Module 5 — 기록 + 설정 (Sprint 5, ~2주)
  - RecordView (달력 + 그래프 + 통계)
  - SettingsView (닉네임 + 루틴 편집 + 버전 관리)
  - Remote Config 연동
  - Analytics 전체 이벤트 완성

Module 6 — QA + 출시 (Sprint 6, ~1주)
  - Crashlytics 테스트
  - 알람 신뢰성 QA (백그라운드, 잠금화면, 재부팅 후)
  - App Store 심사 제출
```

---

## 12. 테스트 전략

```
Unit Test:
  - Repository 로직 (Protocol Mock 사용)
  - ChallengeTimer 상태 전환
  - MotivationService CSV 파싱

Integration Test:
  - Firestore 읽기/쓰기 (Firebase Emulator)
  - 알람 예약/취소 플로우

수동 QA (필수):
  - 알람: 앱 종료 상태, 잠금화면, 재부팅 후 발동 확인
  - 오프라인: 네트워크 차단 후 앱 기능 정상 동작
  - 온보딩: 처음부터 끝까지 완주
```

---

## 13. 참고 문서

- Plan: `docs/01-plan/features/99-app.plan.md`
- 와이어프레임: `docs/99-app-wireframe.md`

---

*Design 완료: 2026-04-15*
*다음: `/pdca do 99-app --scope module-1` 으로 기반 구현 시작*
