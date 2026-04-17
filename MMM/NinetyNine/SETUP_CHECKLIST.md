# 99 앱 — 설정 체크리스트

> 개발 완료 후 이 파일의 항목을 순서대로 완료하면 앱이 작동합니다.
> ✅ = 완료 / ⏳ = 대기 / 🔑 = 키값 필요

---

## 1. Firebase 프로젝트

| 상태 | 항목 | 위치 | 메모 |
|------|------|------|------|
| ⏳ | Firebase 프로젝트 생성 | console.firebase.google.com | 프로젝트명 예: ninety-nine-app |
| ⏳ | iOS 앱 등록 | Firebase Console → 프로젝트 설정 | Bundle ID 결정 필요 |
| 🔑 | GoogleService-Info.plist 다운로드 | Firebase Console → iOS 앱 | Xcode 루트에 추가 (Copy items ✅) |
| ⏳ | Authentication 활성화 | Firebase Console → Authentication | 익명 로그인 + Apple 로그인 ON |
| ⏳ | Cloud Firestore 생성 | Firebase Console → Firestore | 프로덕션 모드, 지역: asia-northeast3 (서울) |
| ⏳ | Firebase Storage 활성화 | Firebase Console → Storage | 기본 버킷 활성화 |
| ⏳ | Analytics 활성화 | 자동 (GoogleService-Info.plist 추가 시) | — |
| ⏳ | Crashlytics 활성화 | Firebase Console → Crashlytics | 앱 첫 실행 후 자동 등록 |
| ⏳ | Remote Config 활성화 | Firebase Console → Remote Config | 기본값 설정 필요 (아래 참고) |

---

## 2. Config.swift 수정 항목

**파일 위치**: `NinetyNine/Core/Config.swift`

| 상태 | 키 | 현재값 (플레이스홀더) | 실제값 찾는 곳 |
|------|----|--------------------|--------------|
| 🔑 | `googleSheetID` | `"YOUR_GOOGLE_SHEET_ID"` | 구글 시트 URL의 `/d/{여기}/edit` |
| 🔑 | `firebaseStorageBucket` | `"YOUR_FIREBASE_STORAGE_BUCKET"` | Firebase Console → Storage → 버킷 이름 (예: `ninety-nine-app.appspot.com`) |

---

## 3. Google Sheets 설정

| 상태 | 항목 | 방법 |
|------|------|------|
| ⏳ | 구글 시트 생성 | sheets.google.com |
| ⏳ | 컬럼 헤더 입력 | `id` / `storage_path` / `quote` / `author` |
| ⏳ | 공개 설정 | 파일 → 공유 → 링크가 있는 모든 사용자 → **뷰어** |
| 🔑 | SHEET_ID 복사 | URL: `https://docs.google.com/spreadsheets/d/{SHEET_ID}/edit` |
| ⏳ | 동기부여 글귀 입력 | 최소 10개 이상 권장 |

**시트 구조 예시**:
```
id | storage_path              | quote                              | author
1  | alarm-images/img_001.jpg  | 작은 것을 매일 하는 사람이 결국 이깁니다 | 익명
2  | alarm-images/img_002.jpg  | 오늘의 나는 어제의 내가 만들었다       | 익명
```

---

## 4. Firebase Storage 이미지

| 상태 | 항목 | 방법 |
|------|------|------|
| ⏳ | `alarm-images/` 폴더 생성 | Firebase Console → Storage → 폴더 추가 |
| ⏳ | 동기부여 이미지 업로드 | 권장: 세로형, 1080×1920px, JPG/WEBP |
| ⏳ | 구글 시트 `storage_path` 컬럼 업데이트 | 예: `alarm-images/img_001.jpg` |

---

## 5. Xcode 프로젝트 설정

| 상태 | 항목 | 위치 |
|------|------|------|
| ⏳ | Bundle ID 설정 | Target → Signing & Capabilities → Bundle Identifier |
| ⏳ | Team 설정 | Target → Signing & Capabilities → Team |
| ⏳ | Background Modes ON | Capabilities → Background Modes |
| ⏳ | └ Audio, AirPlay, and Picture in Picture ✅ | — |
| ⏳ | └ Background fetch ✅ | — |
| ⏳ | Push Notifications ON | Capabilities → Push Notifications |
| ⏳ | Sign in with Apple ON | Capabilities → Sign in with Apple |

---

## 6. Swift Package Manager 패키지

| 상태 | 패키지 | URL | Products |
|------|--------|-----|---------|
| ⏳ | Firebase iOS SDK | `https://github.com/firebase/firebase-ios-sdk` | FirebaseAuth, FirebaseFirestore, FirebaseStorage, FirebaseAnalytics, FirebaseCrashlytics, FirebaseRemoteConfig |
| ⏳ | Kingfisher | `https://github.com/onevcat/Kingfisher` | Kingfisher |

> Xcode → File → Add Package Dependencies → URL 입력

---

## 7. Firebase Remote Config 기본값

| 상태 | 키 | 기본값 | 설명 |
|------|----|---------|----|
| ⏳ | `challenge_brand_name` | `99분 챌린지` | 챌린지 브랜드명 |
| ⏳ | `timer_total_seconds` | `11940` | 199분 = 199 × 60 |
| ⏳ | `motivation_fetch_interval_hours` | `24` | 구글시트 fetch 주기 |
| ⏳ | `onboarding_slide2_title` | `할 일에는 크기가 있어요` | A/B 테스트용 |

---

## 8. Apple Developer 계정

| 상태 | 항목 | 위치 |
|------|------|------|
| ⏳ | Apple Developer 계정 등록 | developer.apple.com ($99/년) |
| ⏳ | App Store Connect 앱 생성 | appstoreconnect.apple.com |
| ⏳ | 앱 이름: `99` | App Store Connect |
| ⏳ | Bundle ID 등록 | developer.apple.com → Identifiers |
| ⏳ | Sign in with Apple 설정 | developer.apple.com → Identifiers → Capabilities |

---

## 9. App Store 출시 준비

| 상태 | 항목 | 비고 |
|------|------|------|
| ⏳ | 앱 스크린샷 준비 | 6.7" (iPhone 15 Pro Max), 6.1", iPad Pro |
| ⏳ | 앱 아이콘 제작 | 1024×1024px |
| ⏳ | 앱 설명 작성 (국문/영문) | — |
| ⏳ | 키워드 설정 | 3-3-3 Method, 루틴, 습관, 알람, 생산성 |
| ⏳ | 개인정보처리방침 URL | 필수 (Firebase 사용 시) |

---

## 진행 중인 개발 모듈

| 모듈 | 내용 | 상태 |
|------|------|------|
| Module 1 | Firebase 기반 + Models + Repositories | ✅ 완료 |
| Module 2 | 온보딩 전체 플로우 | ✅ 완료 |
| Module 3 | 알람 + 구글시트 + 이미지 | ✅ 완료 |
| Module 4 | 99분 챌린지 실행 | ✅ 완료 |
| Module 5 | 기록 + 설정 | ✅ 완료 |
| Module 6 | QA + App Store 제출 | ✅ 완료 (QA_CHECKLIST.md 참고) |

---

---

## Module 3 — 알람 전용 추가 메모

| 상태 | 항목 | 비고 |
|------|------|------|
| ⏳ | Info.plist 권한 키 추가 | `NSUserNotificationUsageDescription` → "기상 알람을 설정하기 위해 알림 권한이 필요합니다" |
| ⏳ | 알람음 에셋 추가 | `Resources/Sounds/` 폴더에 `.caf` 또는 `.wav` 형식으로 추가 |
| ⏳ | 구글시트 최소 데이터 입력 | 알람 화면 테스트 전 최소 3행 이상 글귀 입력 필요 |
| ⏳ | Firebase Storage 이미지 최소 업로드 | 알람 화면 테스트 전 최소 3장 이상 이미지 업로드 필요 |
| ⏳ | Kingfisher SPM 추가 | `https://github.com/onevcat/Kingfisher` (Module 3 구현 전 추가) |

**알람 테스트 시 주의사항**:
- 실기기(iPhone)에서만 알람 정상 동작 (시뮬레이터 알람 소리 미지원)
- 테스트 시 알람 시간을 현재 시간 + 1분으로 설정 후 확인
- 백그라운드 → 잠금화면 상태에서 반드시 검증 필요

---

## Module 5 — 출시 전 추가 설정

| 상태 | 항목 | 비고 |
|------|------|------|
| ⏳ | 지원 이메일 주소 설정 | `SettingsViewModel.swift` → `openSupport()` 함수 내 이메일 주소 입력 |
| ⏳ | 개인정보처리방침 URL 준비 | App Store 심사 필수. Firebase 사용 시 의무 |
| ⏳ | Charts 프레임워크 확인 | iOS 16+ 내장, 별도 설치 불필요 |

---

## 더블체크 후 수정 완료 목록 (2026-04-15)

| 파일 | 수정 내용 |
|------|----------|
| `Routine.swift` | spark.durationSeconds 버그 수정 (`Config.flowTimerSeconds == 0 ? 3 : 3` → `return 3`) |
| `OnboardingViewModel.swift` | AuthHelper.currentUID: UUID 매번 새로 생성 → UserDefaults 캐싱으로 고정 |
| `ModelContextProvider.swift` | 중복 ModelContainer 생성 제거 → NinetyNineApp의 container 공유 구조로 변경 |
| `NinetyNineApp.swift` | `.onAppear`에서 `ModelContextProvider.setup()` 호출 추가 |
| `AppDelegate.swift` | 알람 해제 처리: challengeAutoStart 파라미터 전달 + SNOOZE 액션 분기 추가 |
| `TodayViewModel.swift` | currentStreak(): UserDefaults 읽기 전용 → 비동기로 실제 계산 후 캐싱 |
| `MotivationService.swift` | preloadImages(): 완전 주석 → URLSession 기본 프리로드 + Kingfisher TODO 명확화 |

### Firebase Auth 연결 시 추가 작업 (TODO)
```
1. OnboardingViewModel.swift → AuthHelper.currentUID 주석 해제
   (import FirebaseAuth + Auth.auth().currentUser?.uid)

2. 지원 이메일 설정:
   SettingsViewModel.swift → openSupport() 함수 내 이메일 주소 입력
   예: UIApplication.shared.open(URL(string: "mailto:support@your-domain.com")!)
```

---

## 토스 기준 UX 개선 완료 목록 (2026-04-15)

| 파일 | 개선 내용 |
|------|----------|
| `DesignSystem.swift` (신규) | 색상/여백/타이포/햅틱/버튼 스타일 통합 디자인 시스템 |
| `TodayView.swift` | CTA 버튼 위치 개선 (하단→상단 고정), safeAreaInset, 완료 시 opacity 애니메이션 |
| `TimerHeaderView` | contentTransition(.numericText()) 숫자 애니메이션 추가 |
| `RoutineItemRow` | 완료 상태: 취소선 제거 → opacity 감소 + 색상 변경으로 개선 |
| `TimerPopupView.swift` | 10초 전 햅틱, 완료 시 success 햅틱, contentTransition 애니메이션 |
| `CompletionView.swift` | 스프링 애니메이션 강화, 컨페티 레이어, 순차 등장 애니메이션, 햅틱 |
| `IncompleteView.swift` | warning 햅틱, 미완료 항목 카드 스타일 |
| `AlarmListView.swift` | EmptyStateView 통일, 알람 행 토스 스타일 리디자인, 활성/비활성 시각 구분 |
| `OnboardingView.swift` | 슬라이드 전환 애니메이션, 로딩 단계 메시지, 재시도 버튼 추가 |

### V2 출시 전 추가 권장 (앱 심사 전)
- [ ] 모든 주요 버튼에 Haptic.tap() 추가 (AlarmEdit, Settings 저장 버튼 등)
- [ ] AccessibilityLabel 추가 (이모지, 아이콘 버튼)
- [ ] 알람 삭제 시 확인 다이얼로그 추가
- [ ] 닉네임 최대 10자 제한 추가

---

## 유저 여정 버그 수정 목록 (2026-04-15)

| 파일 | 수정 내용 | 이전 문제 |
|------|----------|----------|
| `ChallengeTimer.swift` | Timer → Date 기반 계산으로 전면 교체. `RunLoop.common`으로 스크롤 중에도 작동. 앱 재시작 시 복원 로직 추가 | 백그라운드에서 타이머 멈춤 |
| `TodayViewModel.swift` | `handleForeground()` 추가, `checkAlreadyCompletedToday()` 추가, 자정 기준 recordDate 로직 | 포그라운드 복귀 시 타이머 비동기화 |
| `TodayView.swift` | `UIApplication.willEnterForegroundNotification` 수신 → 타이머 재동기화 | 백그라운드 복귀 시 타이머 부정확 |
| `OnboardingViewModel.swift` | @AppStorage로 진행 단계·닉네임 영속 저장. 앱 재시작 시 진행 위치 복원 | 온보딩 중 앱 종료 시 처음부터 |
| `OnboardingAlarmView.swift` | 알람 예약 코드 주석 해제. 권한 거부 시 설정앱으로 안내 alert 추가 | 알람이 실제로 예약되지 않음 |
| `RoutineSetupView.swift` | 9개 미만 입력 시 시작 버튼 비활성화 + 진행 카운터 표시 | 빈 루틴으로 챌린지 시작 가능 |
| `AlarmService.swift` | iOS 최대 64개 제한 확인 후 초과 시 경고 노티피케이션 발송 | 10개+ 알람 시 일부 무음 |
| `AppDelegate.swift` | `alarmLimitExceeded` 노티피케이션 이름 추가 | — |

### 아직 해결 안 된 P1 이슈 (Firebase 연결 후 처리)
- [ ] Firebase Anonymous Auth 실제 구현 → 기기 변경 시 데이터 복원 가능
- [ ] 오프라인 기록 → 온라인 복귀 시 자동 동기화 (Firestore offline persistence 활성화)
- [ ] 루틴 편집 중 앱 종료 시 임시 저장 (AutoSave)

*마지막 업데이트: 2026-04-15 (유저 여정 버그 수정 완료)*
