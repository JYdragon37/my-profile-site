# 99 앱 이미지 생성 가이드라인 v2.0

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

### v2 핵심 방향 전환

> **"인물 중심 이미지" → "공간 중심, 분위기 중심 이미지"**

2차 결과물 기준 (`first_light_riverside_pre_dawn_v2`, `peak_mode_urban_momentum_seoul_v2` 등)이
더 잘 나온 이유 3가지:

1. **인물이 주인공이 아닌 분위기의 일부** — "운동하는 사람"이 아닌 "운동의 공기가 남아있는 공간"
2. **딥다크 유지하되 Zone마다 밝기 차등** — 전 Zone 암흑톤이 아니라 시간대별로 살아있는 공기감
3. **앱 배경으로서 실용적** — 상단 여백 충분, 흰 텍스트 얹기 쉬움, 시선 분산 없음

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

### 톤 기조 (v2 업데이트)

- 딥 다크 톤을 기본으로 하되, **모든 Zone을 지나치게 어둡게 만들지 않는다**
- 시간대에 따라 밝기와 공기감을 조정해 **전체 세트가 밸런스 있게** 느껴지도록 한다
- 새벽·밤 Zone은 더 깊고 조용하게
- 아침·낮 Zone은 더 선명하고 breathable하게
- 오후·골든아워는 따뜻하지만 여전히 텍스트 가독성을 해치지 않게

---

## Zone별 스펙

8개 Zone (3시간 단위). 시간대마다 다른 에너지를 담습니다.

| Zone | 시간 | 이름 | 무드 키워드 | 색온도 | 명도 |
|------|------|------|-----------|--------|------|
| 1 | 00–03 | 🌑 Deep Dark | silent effort, solitary discipline | 극냉(deep navy-black) | 극저 |
| 2 | 03–06 | 🌒 First Light | pre-dawn discipline, cool quiet | 냉(navy-indigo) | 저 |
| 3 | 06–09 | 🌅 Rise & Ignite | morning energy, explosive start | 중온(warm gold-amber) | 중 |
| 4 | 09–12 | ⚡ Peak Mode | focused hustle, city momentum | 중온(bright daylight) | 중고 |
| 5 | 12–15 | ☀️ Recharge | steady persistence, breathable | 중온(soft blue-white) | 중 |
| 6 | 15–18 | 🌤 Second Wind | renewed grit, warm afternoon | 중온(amber haze) | 중 |
| 7 | 18–21 | 🌇 Golden Hour | earned rest, quiet satisfaction | 온(deep amber-gold) | 중저 |
| 8 | 21–24 | 🌙 Wind Down | recovery, tomorrow's fuel | 냉(dark navy) | 저 |

---

## Zone별 프롬프트 문구 (v2)

```
Zone 1 (deep_dark):
  A quiet midnight training space, empty indoor gym, climbing wall, or disciplined athletic environment,
  deep navy-black shadows with restrained practical light,
  silent effort, solitary discipline, the work done when no one is watching,
  environment-first composition, no prominent person,
  if any person appears, only a tiny distant silhouette,
  balanced dark tone with visible detail, no crushed blacks

Zone 2 (first_light):
  A nearly empty riverside road, bridge, or urban path in Seoul before dawn,
  indigo sky softening toward pale blue, cool air, wet pavement, early discipline before the city wakes,
  calm focus, quiet momentum, environment-first composition,
  no prominent person, or only one tiny distant runner silhouette

Zone 3 (rise_ignite):
  Sunrise over an urban running path, bridge, or city edge,
  amber and rose light, crisp air, dramatic sky, fresh beginning with purpose,
  energizing but not high-key, brighter than night scenes while preserving text readability,
  environment-first composition, no prominent person, only a tiny distant silhouette if needed

Zone 4 (peak_mode):
  A modern Seoul business district in late morning,
  sharp daylight through glass towers, crosswalks, architecture, focus and momentum through the city itself,
  balanced contrast, clear and refined atmosphere,
  people if present should be very small and anonymous,
  environment-first composition, no hero subject

Zone 5 (recharge):
  A quiet midday field, stadium edge, training ground, or calm athletic environment,
  soft diffused blue-white light, persistence, steady effort, breathable stillness,
  balanced tone, not overly dark and not too bright,
  prefer no person, or one tiny distant athlete only

Zone 6 (second_wind):
  An empty running track, hillside road, or training route in late afternoon,
  warm amber light, renewed energy after fatigue, subtle haze, quiet grit,
  balanced warmth and shadow, motivational through atmosphere rather than a subject,
  no prominent person, only a tiny distant silhouette if needed

Zone 7 (golden_hour):
  An empty running track, riverside path, or athletic field at sunset,
  deep amber-gold light shifting into dusky blue, long shadows, earned rest, calm pride,
  balanced warm tone, reflective rather than triumphant,
  prefer no person, or one tiny distant silhouette near the lower frame

Zone 8 (wind_down):
  A quiet rooftop, city overlook, or riverside night view in Seoul,
  deep navy sky, soft city lights, peaceful recovery, reset for tomorrow,
  night atmosphere with visible city detail, not excessively dark,
  prefer no visible person, or one tiny distant silhouette at the edge of the frame
```

---

## 레이아웃 원칙

- **상단 1/3**: 충분한 여백 — 닉네임 인사말 + 날씨 + 시간 텍스트 영역
- **낮은 horizon**: 피사체(공간, 도시, 산)는 하단에 배치
- 흰색 텍스트를 얹었을 때 **가독성 확보 필수**
- **환경이 주인공** — 공간과 분위기가 화면 주도권을 가진다

---

## 테마 & 소재 가이드

### 추천 소재 (환경·공간 중심)

| 카테고리 | 소재 예시 |
|---------|---------|
| **운동 공간** | 새벽의 빈 체육관, 아무도 없는 수영장, 이른 아침 빈 트랙 |
| **도시·성실** | 새벽 비어있는 도심 거리, 이른 아침 한강변, 빗속 출근길 |
| **자연·극복** | 안개 낀 산 능선, 눈 속 트레일, 폭풍 뒤 맑아진 하늘 |
| **고요한 긴장감** | 출발선 직전의 빈 트랙, 경기 전 텅 빈 경기장 |
| **성취의 공간** | 정상 직전 능선, 일몰 직후 비어있는 운동장, 혼자만 있는 새벽 루프탑 |

### 반드시 피해야 할 소재

| 피해야 할 것 | 이유 |
|------------|------|
| 여러 사람이 웃고 있는 장면 | 소셜 무드 — 혼자 집중하는 앱과 안 맞음 |
| 화려한 파티·축제 | 과한 에너지 — 꾸준함 vs 순간 흥분 |
| 인물이 주인공인 영웅 포즈 | 광고 컷 느낌, 몰입감 깨짐 |
| 밝고 화사한 봄 꽃 | 목적의식 없는 가벼운 무드 |
| 카메라 직접 보는 사람 | 광고 느낌, 시선 분산 |
| 전체 화면을 어둡게 깔아버린 이미지 | 낮 Zone에서 앱 분위기 단조로워짐 |

### 인물 사용 시 주의사항 (v2 업데이트)

- 인물은 **주인공처럼 보이지 않게** 할 것
- 가능하면 **인물이 없는 장면 우선**
- 인물이 등장하더라도 **아주 작고 멀게, 익명적으로**
- 얼굴 강조, 정면 응시, 영웅적 포즈, 광고 컷 같은 구도 **금지**
- 뒷모습·실루엣 위주 — **환경과 분위기가 중심**

---

## 프롬프트 필수 포함 문구 (v2)

```
balanced cinematic tone appropriate to the time zone, low-key dramatic lighting,
ample negative space in upper third, low horizon, environment-first composition,
no prominent person, and if a person appears, keep them very small, distant, and secondary,
no text no letters no numbers no logo no watermark,
9:16 vertical, documentary DSLR realism, cinematic
```

---

## 마스터 프롬프트 템플릿 (v2 기본형)

매번 이 템플릿을 기본으로 사용하고 `[ZONE MOOD]` 부분을 교체하세요.

```
Create a premium smartphone wallpaper for a motivational habit app.
Show a realistic, cinematic scene that expresses [ZONE MOOD] through environment
and atmosphere rather than through a prominent person.

Environment-first composition, low horizon, ample negative space in the upper third
for white UI text.
Do not make any person the main subject. Prefer no visible person.
If a person appears, keep them very small, distant, anonymous, and secondary,
preferably silhouette or back view only.
No face emphasis, no eye contact, no posed hero shot, no ad-like framing.

Use a balanced cinematic tone appropriate to the time zone, with realistic light,
subtle contrast, and documentary DSLR realism.
Keep the image immersive, motivational, and refined, suitable for an iPhone wallpaper.
No text, no letters, no numbers, no logo, no watermark.
9:16 vertical.
```

---

## 컨셉별 프롬프트 예시 (v2)

### 빈 체육관 (Zone 1 — deep_dark)

```
Create a premium smartphone wallpaper for a motivational habit app.
Show a realistic, cinematic scene that expresses silent midnight discipline
through environment and atmosphere rather than through a prominent person.

A quiet midnight training space — empty indoor gym or climbing wall,
deep navy-black shadows with restrained practical light,
the work done when no one is watching, visible detail without crushed blacks.

Environment-first composition, low horizon, ample negative space in the upper third.
Prefer no visible person. If any person appears, only a tiny distant silhouette.
No face emphasis, no posed hero shot.

Balanced dark cinematic tone, realistic light, documentary DSLR realism.
No text, no letters, no numbers, no logo, no watermark. 9:16 vertical.
```

### 한강변 새벽 (Zone 2 — first_light)

```
Create a premium smartphone wallpaper for a motivational habit app.
Show a realistic, cinematic scene that expresses pre-dawn urban discipline
through environment and atmosphere rather than through a prominent person.

A nearly empty riverside road or bridge path along the Han River in Seoul before dawn,
indigo sky softening toward pale blue, cool air, wet pavement,
early discipline before the city wakes, calm quiet momentum.

Environment-first composition, low horizon, ample negative space in the upper third.
Prefer no visible person, or only one tiny distant runner silhouette.
No face emphasis, no posed hero shot.

Balanced dark cinematic tone appropriate to pre-dawn, documentary DSLR realism.
No text, no letters, no numbers, no logo, no watermark. 9:16 vertical.
```

### 서울 도심 아침 (Zone 4 — peak_mode)

```
Create a premium smartphone wallpaper for a motivational habit app.
Show a realistic, cinematic scene that expresses focused urban momentum
through environment and atmosphere rather than through a prominent person.

A modern Seoul business district in late morning,
sharp daylight through glass towers, crosswalks and architecture conveying
focus and momentum through the city itself, balanced contrast, clear refined atmosphere.

Environment-first composition, low horizon, ample negative space in the upper third.
People if present should be very small and anonymous. No hero subject.
No face emphasis, no ad-like framing.

Balanced bright cinematic tone appropriate to late morning, documentary DSLR realism.
No text, no letters, no numbers, no logo, no watermark. 9:16 vertical.
```

### 황금빛 트랙 (Zone 7 — golden_hour)

```
Create a premium smartphone wallpaper for a motivational habit app.
Show a realistic, cinematic scene that expresses earned rest and quiet satisfaction
through environment and atmosphere rather than through a prominent person.

An empty running track or riverside athletic path at sunset,
deep amber-gold light shifting into dusky blue, long shadows, earned calm pride,
reflective rather than triumphant, the beauty of completion.

Environment-first composition, low horizon, ample negative space in the upper third.
Prefer no visible person, or one tiny distant silhouette near the lower frame.
No face emphasis, no posed hero shot.

Balanced warm cinematic tone, documentary DSLR realism.
No text, no letters, no numbers, no logo, no watermark. 9:16 vertical.
```

### 서울 야경 (Zone 8 — wind_down)

```
Create a premium smartphone wallpaper for a motivational habit app.
Show a realistic, cinematic scene that expresses peaceful recovery and reset
through environment and atmosphere rather than through a prominent person.

A quiet rooftop or city overlook in Seoul at night,
deep navy sky above, soft city lights below, Han River visible,
peaceful recovery, tomorrow is another chance, not excessively dark.

Environment-first composition, low horizon, ample negative space in the upper third.
Prefer no visible person, or one tiny distant silhouette at the edge of the frame.
No face emphasis, no posed hero shot.

Balanced night cinematic tone with visible city detail, documentary DSLR realism.
No text, no letters, no numbers, no logo, no watermark. 9:16 vertical.
```

---

## 체크리스트

### 생성 전

| # | 항목 |
|---|------|
| ☐ | 모델 확인, 프롬프트 영어 작성 |
| ☐ | 9:16 세로형 설정 |
| ☐ | 마스터 템플릿 기본형 사용 |
| ☐ | 해당 Zone 무드 문구 삽입 |
| ☐ | `no text no letters no numbers no logo no watermark` 포함 |

### 생성 후 검수

| # | 항목 |
|---|------|
| ✅ | 9:16 세로형 |
| ✅ | 상단 1/3에 충분한 여백 (텍스트 영역) |
| ✅ | 이미지 안에 텍스트·숫자·로고 전혀 없음 |
| ✅ | 시간대에 맞는 밝기와 공기감 (낮 Zone이 지나치게 어둡지 않음) |
| ✅ | 흰색 텍스트 얹었을 때 가독성 확보 |
| ✅ | **환경과 공간이 주인공** (인물이 화면 주도권 갖지 않음) |
| ✅ | 인물 있다면 아주 작고 멀게, 실루엣·뒷모습만 |
| ✅ | 동기부여 에너지 — 보고 나서 "하고 싶다" 느낌 |
| ✅ | 너무 AI스럽지 않고 실사적 |
| ✅ | 이전 컷과 소재·시간대·톤 충분히 다름 |

---

## 파일명 규칙

```
{zone_name}_{concept}_{descriptor}.jpg

예시:
  rise_ignite_seoul_bridge_dawn.jpg
  deep_dark_empty_gym_midnight.jpg
  golden_hour_track_sunset.jpg
  peak_mode_seoul_downtown_morning.jpg
  wind_down_hanriver_night_overlook.jpg
```

**Zone 이름 값:**
`deep_dark` / `first_light` / `rise_ignite` / `peak_mode` /
`recharge` / `second_wind` / `golden_hour` / `wind_down`

---

## Firebase Storage 업로드

1. `alarm-images/` 폴더에 업로드
2. Google Sheets에 경로 + 글귀 입력:

```
id | storage_path                                   | quote                          | author
1  | alarm-images/first_light_hanriver_dawn.jpg     | 세상이 잠든 시간에 내일이 만들어진다 | 99
2  | alarm-images/deep_dark_empty_gym_midnight.jpg  | 아무도 없을 때 하는 것이 진짜다    | 99
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

*최종 업데이트: 2026-04-17 | v2.0*
*v1.0 → v2.0: 인물 중심 → 공간·분위기 중심, 마스터 템플릿 추가, Zone별 밝기 차등 원칙 반영*
*이 가이드는 99 앱 전용입니다. DailyVerse 가이드(dailyverse/docs/image-generation-guide.md)를 참고해 제작됨*
