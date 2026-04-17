# 99 — 할 일 관리의 다음 단계

> 하루 99분으로 인생을 운영한다

## 시작하기 전에 — 필수 설정

### 1. Firebase 설정
```
1. console.firebase.google.com → 새 프로젝트 생성
2. iOS 앱 추가 → Bundle ID: com.yourname.ninetynine
3. GoogleService-Info.plist 다운로드
4. Xcode 프로젝트 루트에 추가 (Copy items 체크)
```

### 2. Config.swift 수정
```swift
// NinetyNine/Core/Config.swift

static let googleSheetID = "YOUR_GOOGLE_SHEET_ID"
static let firebaseStorageBucket = "YOUR_PROJECT_ID.appspot.com"
```

### 3. Google Sheets 설정
```
1. 구글 시트 생성
   컬럼: id | storage_path | quote | author

2. 공개 설정
   파일 → 공유 → 링크가 있는 모든 사용자 (뷰어)

3. SHEET_ID 복사
   URL: https://docs.google.com/spreadsheets/d/{SHEET_ID}/edit
```

### 4. Firebase Storage 이미지 업로드
```
Firebase Console → Storage
→ alarm-images/ 폴더 생성
→ 동기부여 이미지 업로드
→ 구글 시트에 경로 기록 (예: alarm-images/img_001.jpg)
```

### 5. Swift Package Manager 패키지 추가
```
Xcode → File → Add Package Dependencies

Firebase iOS SDK:
  https://github.com/firebase/firebase-ios-sdk
  Products: FirebaseAuth, FirebaseFirestore, FirebaseStorage,
            FirebaseAnalytics, FirebaseCrashlytics, FirebaseRemoteConfig

Kingfisher (이미지 캐싱):
  https://github.com/onevcat/Kingfisher
```

### 6. Xcode Capabilities 설정
```
Target → Signing & Capabilities:
  ✅ Background Modes
     - Audio, AirPlay, and Picture in Picture
     - Background fetch
  ✅ Push Notifications
  ✅ Sign in with Apple
```

---

## 프로젝트 구조

```
NinetyNine/
├── App/              앱 진입점, AppDelegate, ContentView
├── Core/
│   ├── Config.swift  ← 키값 여기만 수정
│   ├── Models/       데이터 모델 (Firestore + SwiftData)
│   ├── Repositories/ 데이터 레이어
│   └── Services/     비즈니스 로직
├── Features/
│   ├── Onboarding/   온보딩 플로우
│   ├── Today/        99분 챌린지
│   ├── Alarm/        기상 알람
│   ├── Record/       기록 & 통계
│   └── Settings/     설정 & 루틴 편집
├── Shared/           공용 컴포넌트
└── Resources/        JSON 템플릿, plist 템플릿
```

## 개발 모듈 순서

| 모듈 | 내용 | 상태 |
|------|------|------|
| Module 1 | Firebase 기반 + Models + Repositories | ✅ 완료 |
| Module 2 | 온보딩 전체 플로우 | ⏳ 대기 |
| Module 3 | 알람 + 구글시트 + 이미지 | ⏳ 대기 |
| Module 4 | 99분 챌린지 실행 | ⏳ 대기 |
| Module 5 | 기록 + 설정 | ⏳ 대기 |
| Module 6 | QA + App Store 제출 | ⏳ 대기 |
