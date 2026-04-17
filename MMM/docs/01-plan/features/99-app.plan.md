# 99 App — Plan Document

> 작성일: 2026-04-15
> 단계: Plan
> 다음 단계: `/pdca design 99-app`

---

## Executive Summary

| 항목 | 내용 |
|------|------|
| **Problem** | 기존 Todo 앱은 유연성이 높아 미루기 쉽고, 할 일이 쌓일수록 압도감이 커져 오히려 실행률이 떨어진다 |
| **Solution** | 하루 9개의 고정 루틴을 199분 챌린지로 실행하는 일상습관 설계 앱. 알람 앱을 대체해 기상 즉시 챌린지가 시작된다 |
| **Function UX Effect** | 뚝딱(3초)/착착(3분)/몰입(30분) 3단계 구조로 할 일의 크기를 시각화하고, 완료 시 실제 소요시간을 기록해 개인 기록 갱신 동기를 부여한다 |
| **Core Value** | Todo 앱의 다음 단계 — 유저가 스스로 일상 루틴을 설계하고, 매일 가볍고 꾸준하게 실행하는 건강한 습관 시스템 |

---

## Context Anchor

| 항목 | 내용 |
|------|------|
| **WHY** | 기존 Todo 앱은 실행보다 관리에 집중한다. 미루게 만드는 구조를 깨고, 중요한 것을 먼저 끝내고 나머지 시간을 해방하는 새로운 패러다임이 필요하다 |
| **WHO** | 번아웃 직전의 30대 퍼포머, 집중력 지원이 필요한 크리에이터/학생, Oliver Burkeman 3-3-3 Method 등 생산성 방법론 실천가 |
| **RISK** | 알람 기능 신뢰성 (iOS 백그라운드 제한), 온보딩 완료율 (9개 항목 세팅 허들), Firebase 의존성 증가 |
| **SUCCESS** | D-90 DAU 1,000명 이상, 챌린지 완료율 70% 이상, 알람 설정 전환율 60% 이상, App Store 4.5점 이상 |
| **SCOPE** | iOS 전용 MVP. 안드로이드/웹 제외. 소셜 기능 제외. AI 루틴 추천 제외 (V2) |

---

## 1. 앱 개요

| 항목 | 내용 |
|------|------|
| 앱 이름 | 99 |
| 슬로건 | 할 일 관리의 다음 단계 |
| 서브 슬로건 | 하루 99분으로 인생을 운영한다 |
| 플랫폼 | iOS 17+ |
| 개발 언어 | Swift 5.9 / SwiftUI |
| 수익 모델 | 일회성 구매 $17.99 (한국 ₩24,000) |
| 탭 구조 | 홈 / 알람 / 기록 / 설정 |

---

## 2. 핵심 컨셉

### 3-3-3 구조
```
⚡ 뚝딱  × 3   (3초짜리 마이크로 액션)
🔹 착착  × 3   (3분짜리 짧은 집중)
🔵 몰입  × 3   (30분짜리 딥워크)
─────────────────────────────
총 9개 / 이론 소요시간 99분
```

### 99분 챌린지 (브랜드) / 199분 타이머 (구현)

```
브랜드 약속:   "99분 챌린지"       ← 대외 커뮤니케이션, 마케팅
실제 타이머:   199분 카운트다운     ← 앱 내부 구현

Rationale:
  앱 이름(99) = 9개 액션 = 99분 챌린지
  세 숫자가 하나의 브랜드로 완벽히 수렴.
  199분은 99분의 약속을 현실에서 달성 가능하게 하는 설계.
  (이동시간, 전환 버퍼 +100분 포함)
  유저는 "99분 안에 끝낸다"고 인식 → 내부적으로 199분 제공.

실제 소요시간 기록 → 개인 최고기록 갱신 동기
```

### 알람 → 챌린지 연동
```
기상 알람 해제 → 199분 자동 시작
기존 알람 앱 대체 → 강력한 데일리 진입점
```

---

## 3. 기능 요구사항

### 3-1. 온보딩 (MVP 필수)

| ID | 요구사항 | 우선순위 |
|----|----------|---------|
| OB-01 | 컨셉 슬라이드 4장: ①오늘 할일 남음(공감1) → ②며칠째 쌓임(공감2) → ③서비스 아이덴티티(심플·시간·우선순위) → ④3-3-30 구조 + 99분9초 리빌 + 1**99**분 제한 + "매일 기록으로 남아요" 힌트 한 줄 | P0 |
| OB-02 | 닉네임 입력 (앱 전반 친근하게 활용) | P0 |
| OB-03 | 모드 선택: 모닝 모드(기상 알람 연동, 오전 생산성 추구) / 일반 모드(원할 때 직접 시작, 유동적 스케줄). 닉네임 입력 직후 표시 | P0 |
| OB-04 | 알람 설정 (모닝 모드 선택 시에만 표시) — 기상 알람 해제 시 199분 자동 시작 안내 포함 | P0 |
| OB-05 | 루틴 세팅: 템플릿 1개 제공 (보편적 일상 루틴). 뚝딱/착착/몰입 영역 순서대로 플래시 하이라이트 + 설명 문구 튜토리얼 오버레이 ("딱 3초면 되는 간단한 일을 적어요" 등). 수정 가능 | P0 |
| OB-06 | 평일/주말 루틴 분리 세팅 | P1 |

### 3-2. 알람 탭 (MVP 필수)

| ID | 요구사항 | 우선순위 |
|----|----------|---------|
| AL-01 | 다중 알람 생성/편집/삭제 | P0 |
| AL-02 | 반복 요일 설정 (개별 요일 선택) | P0 |
| AL-03 | 알람 레이블 | P0 |
| AL-04 | 알람음 선택 + 미리듣기 | P0 |
| AL-05 | 볼륨 조절 + 페이드인 | P0 |
| AL-06 | 진동 설정 | P0 |
| AL-07 | 스누즈 (시간/횟수 설정) | P1 |
| AL-08 | 챌린지 자동 시작 ON/OFF (알람별 설정) | P0 |
| AL-09 | 알람 전체화면: Firebase Storage 이미지 + 구글시트 글귀 + 닉네임 | P0 |
| AL-10 | 오늘 탭 상단 알람 상태 표시 | P1 |

### 3-3. 홈 탭 — 대시보드 + 챌린지 (MVP 필수)

#### 3-3-1. 홈 대시보드

| ID | 요구사항 | 우선순위 |
|----|----------|---------|
| HM-01 | 풀스크린 배경 이미지 (Firebase Storage/구글시트 연동, 알람 화면과 동일 소스) | P0 |
| HM-02 | 상단 오버레이: 현재 날씨(기온+날씨상태) + 도시명 (좌상단 작게) / 스트릭 🔥N일 (우상단 작게) | P0 |
| HM-03 | 중앙: 시간대별 인사 ("좋은 아침이에요, 지민" / "오후도 화이팅" / "오늘 수고했어요") + 날짜 + 요일 | P0 |
| HM-04 | 중앙 하단: 동기부여 문구 (구글시트 소스, 이탤릭 작게) | P0 |
| HM-05 | 프로그레스 위젯 ●●●○○○○○○ N/9 — 챌린지 시작 후에만 표시, 탭 시 챌린지 뷰로 이동 | P0 |
| HM-06 | 프로그레스 위젯 길게 누르기 → "오늘의 99를 리셋할까요?" 확인 모달 (취소 / 리셋하기) | P0 |
| HM-07 | 하단 고정 CTA 버튼 1개 — 상태별 라벨 변경 (아래 표 참고) | P0 |
| HM-08 | 날씨 서비스: WeatherKit(기본) + OpenWeatherMap(폴백), dailyverse 구현 재사용 | P0 |

**CTA 버튼 상태별 라벨:**

| 홈 상태 | CTA 라벨 |
|---------|---------|
| 챌린지 미시작 | 오늘의 99 시작하기 |
| 챌린지 진행 중 | 진행 중인 99 보기 |
| 챌린지 부분 종료 | 오늘의 99 이어하기 |
| 9/9 완료 | 오늘 기록 보기 |

#### 3-3-2. 챌린지 실행

| ID | 요구사항 | 우선순위 |
|----|----------|---------|
| CH-01 | CTA 탭 → 챌린지 뷰 진입 (199분 카운트다운 시작 or 재진입) | P0 |
| CH-02 | 뚝딱 항목 탭 → 즉시 완료 체크 | P0 |
| CH-03 | 착착 항목 탭 → 3분 타이머 팝업 | P0 |
| CH-04 | 몰입 항목 탭 → 30분 타이머 팝업 | P0 |
| CH-05 | 진행률 표시 (N/9) + 199분 카운트다운 상단 고정 | P0 |
| CH-06 | "종료·기록" 버튼 → 실제 소요시간 저장 | P0 |
| CH-07 | 9/9 완료 → 해방 화면 (소요시간 분·초 + 개인 포디움 순위 — "오늘 개인 2위예요 🥈") | P0 |
| CH-08 | 199분 초과 → 미완료 화면 (따뜻한 톤 + 닉네임) | P0 |
| CH-09 | 직접 종료 → 확인 모달 (계속하기 / 기록하기) | P0 |
| CH-10 | 요일 자동 감지 → 평일/주말 루틴 자동 전환 | P0 |

### 3-4. 기록 탭 (MVP 필수)

| ID | 요구사항 | 우선순위 |
|----|----------|---------|
| RC-01 | 월별 달력 뷰 (완료/미완료/미실시 시각화) | P0 |
| RC-02 | 날짜별 상세 기록 (완료 항목, 소요시간) | P0 |
| RC-03 | 소요시간 막대 그래프 (주간) | P0 |
| RC-04 | 완료율 그래프 전환 | P1 |
| RC-05 | 스트릭 (연속 달성 일수) | P0 |
| RC-06 | 개인 최고기록 / 전체 평균 (분·초 단위) | P0 |
| RC-07 | 개인 포디움 — 9/9 완료 + 199분 이내 기록 중 Top 3를 금·은·동 순위로 표시 (날짜 + 소요시간 분·초) | P0 |
| RC-08 | 유형별 완료율 (뚝딱/착착/몰입 각각) | P1 |
| RC-09 | 전체 통계 (총 완료 횟수, 최장 스트릭 등) | P1 |

### 3-5. 설정 탭 (MVP 필수)

| ID | 요구사항 | 우선순위 |
|----|----------|---------|
| ST-01 | 닉네임 변경 | P0 |
| ST-02 | 루틴 편집 — 항목별 텍스트 편집, 평일/주말 탭 전환 | P0 |
| ST-02a | 이모지 자동 생성: 항목 입력 필드 옆 ✨ 버튼 탭 → Claude API로 항목 텍스트 전송 → 이모지 1개 반환 → 텍스트 끝에 추가 (기존 이모지 있으면 교체). 섹션 하단 "✨ 전체 자동 생성" 버튼으로 9개 일괄 처리 가능. 처리 중 스피너 표시 | P0 |
| ST-03 | 저장 시 선택 모달: "현재 루틴 수정" (덮어쓰기) / "새 버전으로 시작" | P0 |
| ST-04 | 새 버전 생성: 루틴 이름 입력 + 시작일 선택 (오늘~미래). 시작일에 따라 이전 루틴 endDate 자동 설정 (startDate - 1일). 미래 예약 시 scheduled 상태로 생성 | P0 |
| ST-05 | 루틴 상태 3가지: active(현재 활성) / scheduled(미래 예약) / completed(종료). 날짜 기반 자동 판별 | P0 |
| ST-06 | 미래 예약 루틴: 동시 1개만 허용. 예약 편집(시작일·내용 수정) / 예약 취소(이전 루틴 endDate nil 복원) 가능 | P0 |
| ST-07 | 루틴 자동 전환: 앱 실행 시 오늘 날짜 ≥ scheduled.startDate 이면 active로 자동 승격, 이전 루틴 completed 처리 | P0 |
| ST-08 | 루틴 히스토리: 상태별(active / scheduled / completed) 표시. completed 항목에 기간 + 완료율(%) 표시 | P0 |
| ST-09 | 루틴 삭제 불가 — 아카이브(히스토리에서 숨김)만 허용. 기록 탭 통계 보호 | P1 |
| ST-10 | 챌린지 완료 알림 설정 | P1 |
| ST-11 | 테마 (라이트/다크) | P2 |

### 3-6. 데이터 관리 (MVP 필수)

| ID | 요구사항 | 우선순위 |
|----|----------|---------|
| DT-01 | Firebase Anonymous Auth → Apple Sign-in 전환 | P0 |
| DT-02 | Firestore 유저 데이터 동기화 (루틴, 기록) | P0 |
| DT-03 | 구글시트 CSV fetch → 로컬 캐시 (이미지 메타) | P0 |
| DT-04 | Firebase Storage 이미지 CDN 서빙 + Kingfisher 캐싱 | P0 |
| DT-05 | Firebase Analytics 이벤트 트래킹 | P0 |
| DT-06 | Firebase Crashlytics 크래시 모니터링 | P0 |
| DT-07 | Firebase Remote Config A/B 테스트 | P1 |

---

## 4. 비기능 요구사항

| 항목 | 요구사항 |
|------|----------|
| 알람 신뢰성 | 앱 종료 상태에서도 알람 100% 발동 |
| 오프라인 지원 | 로컬 캐시로 알람 이미지/루틴/기록 오프라인 작동 |
| 앱 시작 시간 | Cold start 2초 이내 |
| iOS 버전 | iOS 17+ (SwiftData, SwiftUI 최신 API 활용) |
| 접근성 | WCAG AA (Dynamic Type, VoiceOver 기본 지원) |
| 개인정보 | 닉네임 외 개인정보 미수집, 익명 인증 우선 |

---

## 5. 데이터 모델

```
Firestore: users/{userId}
  ├─ nickname: String
  ├─ createdAt: Timestamp
  │
  ├─ projects/{projectId}
  │    ├─ name: String          ("일상습관 v2")
  │    ├─ version: Int
  │    ├─ startDate: Timestamp
  │    ├─ endDate: Timestamp?   (nil = active or scheduled)
  │    ├─ endDateSetBy: String? ("auto" | "manual" | nil)
  │    │                        auto = 다음 버전 생성 시 자동 설정 → 예약 취소 시 nil 복원
  │    │                        manual = 사용자 직접 설정 → 취소해도 유지
  │    ├─ status: String        파생값 — 코드에서 계산
  │    │                        startDate > today → "scheduled"
  │    │                        endDate < today  → "completed"
  │    │                        else             → "active"
  │    ├─ weekdayRoutine
  │    │    ├─ spark: [String × 3]   (뚝딱)
  │    │    ├─ flow:  [String × 3]   (착착)
  │    │    └─ deep:  [String × 3]   (몰입)
  │    └─ weekendRoutine
  │         ├─ spark: [String × 3]
  │         ├─ flow:  [String × 3]
  │         └─ deep:  [String × 3]
  │
  └─ records/{YYYY-MM-DD}
       ├─ completedCount: Int     (0~9)
       ├─ elapsedSeconds: Int     (실제 소요시간 — 초 단위, 표시 시 분·초로 변환)
       ├─ isSuccess: Bool         (9/9 완료 여부)
       └─ itemStatus: [Bool × 9] (각 항목 완료)
       ※ 포디움 집계 조건: isSuccess == true && elapsedSeconds <= 199×60

Local (SwiftData):
  - 위 Firestore 구조 미러링 (오프라인 캐시)
  - AlarmConfig (알람 설정, Firestore 미동기)
  - MotivationContent (구글시트 캐시)
```

---

## 6. Firebase Analytics 이벤트

| 이벤트 | 파라미터 | 목적 |
|--------|----------|------|
| `onboarding_completed` | - | 온보딩 완료율 |
| `alarm_set_during_onboarding` | - | 알람 전환율 |
| `challenge_started` | - | 일일 활성 측정 |
| `challenge_completed` | elapsed_minutes, streak | 완료 패턴 |
| `challenge_failed` | completed_count, reason | 이탈 패턴 |
| `alarm_dismissed` | - | 알람→챌린지 전환율 |
| `alarm_snoozed` | snooze_count | 스누즈 패턴 |
| `streak_achieved` | streak_days (7/14/21/30) | 리텐션 마일스톤 |
| `routine_edited` | - | 루틴 커스터마이징 빈도 |
| `emoji_generated` | item_type (spark/flow/deep), batch (true/false) | 이모지 생성 기능 사용률 |

---

## 7. 성공 기준

| 지표 | 목표 | 측정 방법 |
|------|------|-----------|
| 온보딩 완료율 | 70% 이상 | Analytics: onboarding_completed |
| 알람 설정 전환율 | 60% 이상 | Analytics: alarm_set_during_onboarding |
| D-7 리텐션 | 50% 이상 | Firebase Analytics |
| D-30 리텐션 | 30% 이상 | Firebase Analytics |
| 챌린지 완료율 | 70% 이상 | records.isSuccess |
| App Store 평점 | 4.5점 이상 | App Store Connect |
| D-90 DAU | 1,000명 이상 | Firebase Analytics |

---

## 8. 리스크 분석

| 리스크 | 심각도 | 대응 |
|--------|--------|------|
| iOS 백그라운드 알람 미발동 | 높음 | UNUserNotificationCenter + AVAudioSession Background Mode + Crashlytics 즉시 감지 |
| 온보딩 이탈 (9개 항목 세팅 부담) | 높음 | 직업별 템플릿 제공, 나중에 수정 가능 강조 |
| Firebase 비용 초과 | 중간 | Firestore 읽기 캐싱, 무료 한도 모니터링 |
| App Store 심사 거절 (알람 앱 분류) | 중간 | "Productivity" 카테고리, 알람 기능 명확히 설명 |
| 구글시트 CSV 접근 불가 (오프라인) | 낮음 | 로컬 캐시 필수, 기본 이미지 번들 포함 |

---

## 9. 개발 로드맵

### Phase 1 — MVP (출시 목표)
```
Sprint 1 (2주)
  - Firebase 프로젝트 설정 + Auth
  - Firestore 데이터 모델 구현
  - SwiftData 로컬 캐시 레이어

Sprint 2 (2주)
  - 온보딩 플로우 (슬라이드 + 닉네임 + 알람 + 루틴 세팅)
  - 루틴 템플릿 데이터

Sprint 3 (2주)
  - 알람 탭 (UNUserNotificationCenter + AVFoundation)
  - 알람 전체화면 (이미지 + 글귀 + 닉네임)
  - 구글시트 CSV fetch + Kingfisher 캐싱

Sprint 4 (2주)
  - 오늘 탭 (챌린지 실행 전체 플로우)
  - 199분 타이머 + 뚝딱/착착/몰입 타이머 팝업
  - 완료/미완료/직접종료 화면

Sprint 5 (2주)
  - 기록 탭 (달력 + 그래프 + 통계)
  - 설정 탭 (루틴 편집 + 닉네임)
  - Firebase Analytics 이벤트 연동

Sprint 6 (1주)
  - QA + 버그 수정
  - App Store 심사 제출
```

### Phase 2 — 고도화 (출시 후)
```
- Remote Config A/B 테스트
- 루틴 히스토리 버전 관리
- 유형별 완료율 상세 통계
- 다크모드
- iOS 홈화면 위젯
```

### Phase 3 — 확장
```
- AI 루틴 추천 (Claude API)
- Apple Watch 연동
- Android 포팅 (React Native or Flutter)
```

---

## 10. 외부 설정 체크리스트

```
Firebase
□ Firebase 프로젝트 생성
□ iOS 앱 등록 → GoogleService-Info.plist → Xcode 추가
□ Authentication 활성화 (익명, Apple)
□ Cloud Firestore 생성 (프로덕션 모드)
□ Firebase Storage 버킷 활성화
□ Crashlytics 활성화

구글 시트
□ 시트 생성 (id / storage_path / quote / author 컬럼)
□ 공개 설정 (링크가 있는 모든 사용자 - 뷰어)
□ SHEET_ID → 앱 Config 파일 입력

Firebase Storage
□ alarm-images/ 폴더에 동기부여 이미지 업로드
□ 구글 시트에 storage_path + 글귀 입력

Apple
□ Apple Developer 계정 ($99/년)
□ App Store Connect 앱 생성
□ Sign in with Apple 설정
□ App Store 스크린샷 준비 (6.7" + 6.1" + iPad)
```

---

## 11. 참고 문서

- 와이어프레임: `docs/99-app-wireframe.md`
- 기획 가이드: `docs/ios-app-planning-guide.md`

---

*Plan 완료: 2026-04-15*
*다음: `/pdca design 99-app`*
