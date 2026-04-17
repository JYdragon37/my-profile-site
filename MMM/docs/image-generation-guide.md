# 99 앱 이미지 생성 가이드라인 v1.0

> 이 파일은 99 앱 홈 화면·알람 화면에 사용되는 배경 이미지를 생성할 때의 기준 문서입니다.
> AI 이미지 생성 도구(Genspark, Midjourney 등)에 프롬프트를 입력하기 전 반드시 숙지하세요.

---

## 앱 컨셉

99 앱은 **동기부여 습관 앱**입니다.
하루 9개의 루틴(뚝딱·착착·몰입)을 199분 안에 완수하는 챌린지를 제공합니다.

> 핵심 감성: 노력, 꾸준함, 실행, 성실, 고요한 긴장감
> 타겟: 매일 최선을 다하는 30대 퍼포머

배경 이미지는 유저가 **"나도 할 수 있다"는 에너지를 느끼게** 해야 합니다.
화려한 성공보다 **과정의 아름다움**을 담는 것이 핵심입니다.

---

## 이미지 타입

| 타입 | 용도 | 규격 | Firebase Storage 경로 |
|------|------|------|----------------------|
| **Zone 배경 이미지** | 홈 화면 풀스크린, 알람 전체화면 | 세로 9:16 | `alarm-images/` |

---

## 공통 규칙

### 기본 생성 원칙

- **모델**: `nano-banana-2` 권장
- **프롬프트**: 영어로 작성
- 기본 1장 생성. 대량 생성 시 **6장 단위**로 끊어서 확인 후 다음 배치
- **아이폰 배경화면에 사용될 수 있는 수준**의 고화질·고품질
- **가로 이미지 금지** — 반드시 세로형 9:16

### 텍스트 절대 금지

이미지 안에 어떤 텍스트도 포함 금지

- letters / numbers / captions / signage / logo / watermark / 한글 / 영문 전부
- 텍스트를 나중에 얹기 좋은 **빈 공간만 확보**

### 톤 기조

- **딥 다크 톤** 기본 유지 — 흰색 텍스트 가독성이 최우선
- 새벽·아침 Zone은 드라마틱한 빛 표현 허용 (단, 텍스트 영역은 어둡게 유지)
- 낮 Zone도 하이키(밝은) 이미지 피하고, **명암 대비 뚜렷**하게

---

## Zone별 스펙

8개 Zone (3시간 단위). 시간대마다 다른 에너지를 담습니다.

| Zone | 시간 | 이름 | 무드 키워드 | 색온도 | 명도 |
|------|------|------|-----------|--------|------|
| 1 | 00–03 | 🌑 Deep Dark | silent effort, solitary discipline | 극냉(deep navy-black) | 극저 |
| 2 | 03–06 | 🌒 First Light | pre-dawn warrior, early bird grit | 냉(navy-indigo) | 저 |
| 3 | 06–09 | 🌅 Rise & Ignite | morning run, explosive start | 중온(warm gold-amber) | 중 |
| 4 | 09–12 | ⚡ Peak Mode | focused hustle, city energy | 중온(bright daylight) | 중고 |
| 5 | 12–15 | ☀️ Recharge | push through, midday grit | 중온(soft blue-white) | 중 |
| 6 | 15–18 | 🌤 Second Wind | afternoon drive, refuse to quit | 중온(amber haze) | 중 |
| 7 | 18–21 | 🌇 Golden Hour | earned rest, quiet satisfaction | 온(deep amber-gold) | 중저 |
| 8 | 21–24 | 🌙 Wind Down | reflect and recover, tomorrow's fuel | 냉(dark navy) | 저 |

---

## Zone별 무드 키워드 (프롬프트용)

```
Zone 1 (deep_dark):
  silent city streets at 2am, lone figure training in empty gym,
  solitary discipline, pitch-black sky, deep navy tones,
  the work done when no one is watching

Zone 2 (first_light):
  pre-dawn runner on empty road, athlete warming up before sunrise,
  first hints of indigo light on horizon, dark quiet streets,
  the ones who wake before the world

Zone 3 (rise_ignite):
  morning runner at sunrise, explosive start energy, amber and rose light,
  athletic silhouette against dramatic sky, fresh start momentum,
  crisp morning air, powerful beginning

Zone 4 (peak_mode):
  focused worker in bright urban setting, business district at full energy,
  confident daylight, peak performance atmosphere,
  city in full motion, sharp and clear

Zone 5 (recharge):
  midday athlete pushing through fatigue, quiet persistence,
  soft diffused light, determination in stillness,
  the grind continues, steady pace

Zone 6 (second_wind):
  afternoon training session, runner catching second wind,
  warm amber light on empty track, refusing to stop,
  grit in golden-tinted atmosphere

Zone 7 (golden_hour):
  athlete at finish line, sunset over city after a hard day's work,
  earned satisfaction, amber-to-indigo transition,
  quiet pride, reflective achievement

Zone 8 (wind_down):
  solitary figure under night sky, city lights below,
  earned rest, deep navy, tomorrow is another chance,
  peaceful recovery, cozy darkness
```

---

## 레이아웃 원칙

- **상단 1/3**: 충분한 여백 — 닉네임 인사말 + 날씨 + 시간 텍스트 영역
- **낮은 horizon**: 피사체(사람, 도시, 산)는 하단에 배치
- 흰색 텍스트를 얹었을 때 **가독성 확보 필수**
- 피사체는 과하지 않게 — **여백이 압도감**을 만든다

---

## 테마 & 소재 가이드

### 추천 소재 (다양하게 섞기)

| 카테고리 | 소재 예시 |
|---------|---------|
| **달리기·운동** | 새벽 도로 위 러너, 혼자 트랙 도는 선수, 언덕 오르는 등산객 |
| **도시·성실** | 이른 아침 비어있는 도심, 야근 후 새벽 사무실 조명, 빗속 출근길 |
| **자연·극복** | 안개 낀 산 정상, 눈 속 트레일, 폭풍 뒤 맑은 하늘 |
| **고독한 노력** | 혼자 훈련하는 선수, 빈 수영장, 빈 체육관, 인적 없는 도로 |
| **경쟁·스포츠** | 출발선 직전, 마지막 코너, 시합 전 준비 |
| **성공·성취** | 산 정상에 선 사람(뒷모습), 피니시 라인 직전, 새벽빛 속 홀로 걷기 |

### 반드시 피해야 할 소재

| 피해야 할 것 | 이유 |
|------------|------|
| 여러 사람이 웃고 있는 장면 | 소셜 무드 — 혼자 집중하는 앱 감성과 안 맞음 |
| 화려한 파티·축제 | 과한 에너지 — 꾸준함 vs 순간 흥분 |
| 풍경 사진 (사람 없음, 너무 한적) | 동기부여 에너지 부족 |
| 밝고 화사한 봄 꽃 | 목적의식 없는 가벼운 무드 |
| 카메라 직접 보는 사람 | 광고 느낌, 몰입감 깨짐 |

### 인물 사용 시 주의사항

- 얼굴은 최대한 **피하거나 뒷모습·실루엣**으로만
- 특정 인종·성별 편향 없이 다양하게
- 실루엣 위주 — 내가 저 사람이 될 수 있다는 감각

---

## 프롬프트 필수 포함 문구

```
deep dark tone, low-key dramatic lighting, ample negative space in upper third,
low horizon, no text no letters no watermark,
9:16 vertical, documentary DSLR realism, cinematic
```

---

## 컨셉별 프롬프트 예시

### 새벽 러너 (Zone 2 — first_light)

```
A lone runner on an empty Seoul highway bridge at 4am,
the pre-dawn sky deep indigo above, city lights reflecting below,
silhouette against the first faint glow on the horizon,
no people around, absolute solitude, gritty determination,
low horizon, no text no letters no watermark,
9:16 vertical, documentary DSLR realism, cinematic
```

### 도시 새벽 (Zone 3 — rise_ignite)

```
Empty business district street at sunrise in Seoul,
amber and gold morning light cutting between skyscrapers,
long shadows stretching on the wet pavement,
a single figure in athletic gear walking confidently away from camera,
no text no letters no watermark,
9:16 vertical, documentary DSLR realism, dramatic cinematic
```

### 빈 체육관 (Zone 1 — deep_dark)

```
Empty boxing gym at 2am, single overhead light illuminating a punching bag,
dark navy shadows, sweat on the floor, quiet intensity,
no people visible, the work that happens in silence,
no text no letters no watermark,
9:16 vertical, documentary DSLR realism
```

### 산 정상 뒷모습 (Zone 4 — peak_mode)

```
A lone hiker standing at the peak of a mountain, view from behind,
looking out over an endless sea of clouds below,
bright morning light, small figure against vast sky,
achievement without audience, no text no letters no watermark,
9:16 vertical, documentary DSLR realism, wide angle
```

### 황금빛 피니시 (Zone 7 — golden_hour)

```
An empty running track at golden hour, long shadows across the lanes,
sun setting low behind the city skyline,
the quiet after effort, warm amber light,
no people, a sense of completion and earned rest,
no text no letters no watermark,
9:16 vertical, documentary DSLR realism, cinematic
```

### 야간 도시 (Zone 8 — wind_down)

```
Aerial view of city lights at night in Seoul, Han River visible,
deep navy sky, countless tiny lights below,
a single figure on a rooftop looking out (silhouette),
reflective quiet, tomorrow I'll try again,
no text no letters no watermark,
9:16 vertical, documentary DSLR realism
```

---

## 체크리스트

### 생성 전

| # | 항목 |
|---|------|
| ☐ | 모델 확인, 프롬프트 영어 작성 |
| ☐ | 9:16 세로형 설정 |
| ☐ | 해당 Zone 무드·색온도 반영 |
| ☐ | 상단 1/3 여백 확보 지시 포함 |
| ☐ | `no text no letters no watermark` 포함 |

### 생성 후 검수

| # | 항목 |
|---|------|
| ✅ | 9:16 세로형 |
| ✅ | 상단 1/3에 충분한 여백 (텍스트 영역) |
| ✅ | 이미지 안에 텍스트 전혀 없음 |
| ✅ | 딥 다크 톤 유지 (낮 Zone도 어두운 기조) |
| ✅ | 흰색 텍스트 얹었을 때 가독성 확보 |
| ✅ | 동기부여 에너지 — 보고 나서 "하고 싶다" 느낌 |
| ✅ | 너무 AI스럽지 않고 실사적 |
| ✅ | 이전 컷과 소재·시간대·톤 충분히 다름 |
| ✅ | 얼굴 노출 없음 (뒷모습·실루엣만) |

---

## 파일명 규칙

```
{zone_name}_{concept}_{descriptor}.jpg

예시:
  rise_ignite_runner_seoul_bridge_dawn.jpg
  deep_dark_gym_solo_training.jpg
  golden_hour_track_empty_sunset.jpg
  peak_mode_mountain_summit_silhouette.jpg
  wind_down_city_rooftop_night.jpg
```

**Zone 이름 값:**
`deep_dark` / `first_light` / `rise_ignite` / `peak_mode` /
`recharge` / `second_wind` / `golden_hour` / `wind_down`

---

## Firebase Storage 업로드

1. `alarm-images/` 폴더에 업로드
2. Google Sheets에 경로 + 글귀 입력:

```
id | storage_path                              | quote                          | author
1  | alarm-images/rise_ignite_runner_dawn.jpg  | 남보다 한 발 먼저 시작했어요      | 99
2  | alarm-images/deep_dark_gym_solo.jpg       | 아무도 없을 때 하는 것이 진짜다    | 99
```

---

## 추천 글귀 (이미지와 함께 시트에 입력)

| Zone | 글귀 예시 |
|------|---------|
| deep_dark | "아무도 없을 때 하는 것이 진짜다" |
| first_light | "세상이 잠든 시간에 내일이 만들어진다" |
| rise_ignite | "오늘 아침을 연 사람이 하루를 완성한다" |
| peak_mode | "집중하는 사람이 결국 이긴다" |
| recharge | "지치지 않는 게 아니라, 멈추지 않는 거다" |
| second_wind | "포기하지 않으면 아직 게임은 끝나지 않았다" |
| golden_hour | "수고한 오늘, 내일의 연료가 됐다" |
| wind_down | "잘 쉬는 것도 실력이다" |

---

*최종 업데이트: 2026-04-17 | v1.0*
*이 가이드는 99 앱 전용입니다. DailyVerse 가이드(dailyverse/docs/image-generation-guide.md)를 참고해 제작됨*
