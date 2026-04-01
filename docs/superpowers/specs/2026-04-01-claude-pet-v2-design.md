# Claude Pet v2 Design Spec

## Overview

Claude Pet v2는 기존 메뉴바 타마고치 고양이를 **12종 펫 컬렉션, 근육 성장 시스템, 조건별 해금, SwiftUI 팝오버 UI, GitHub Pages 도감**으로 확장한다.

## Goals

- AI 사용량(시간, 토큰, 에이전트 등)에 따른 펫 해금으로 수집 재미 제공
- 에이전트 수에 따른 근육 3단계 변화로 시각적 피드백
- 다중 세션 시 해금된 친구 펫 등장
- rate limit 도달 시 macOS 알림
- README 배지 및 GitHub Pages 펫 도감

## Non-Goals

- 상호작용 (먹이주기, 쓰다듬기 등)
- 일일 사용 리포트, 생산성 통계, 목표 설정
- Windows/Linux 지원
- 웹 대시보드

---

## 1. Pet Collection (12종)

| # | Pet | ID | Unlock Condition | Concept |
|---|-----|----|-----------------|---------|
| 1 | Cat | `cat` | 기본 제공 | 메인 펫 |
| 2 | Hamster | `hamster` | 총 세션 10회 | 처음 만나는 친구 |
| 3 | Chick | `chick` | 총 사용시간 5시간 | 작고 귀여운 초반 펫 |
| 4 | Penguin | `penguin` | 총 토큰 50만 사용 | 묵묵한 일꾼 |
| 5 | Fox | `fox` | 에이전트 총 50회 실행 | 영리한 조력자 |
| 6 | Rabbit | `rabbit` | 동시 세션 3개 이상 달성 | 빠른 멀티태스커 |
| 7 | Goose | `goose` | 총 사용시간 30시간 | 시끄러운 베테랑 |
| 8 | Capybara | `capybara` | Rate limit 10회 도달 | 여유로운 대기 마스터 |
| 9 | Sloth | `sloth` | 45분+ 장시간 세션 20회 | 느긋한 장기전 전문가 |
| 10 | Owl | `owl` | Opus 모델 누적 10시간 | 지혜로운 고급 모델 유저 |
| 11 | Dragon | `dragon` | 동시 에이전트 5개 이상 달성 | 전설의 멀티에이전트 |
| 12 | Unicorn | `unicorn` | 모든 펫 해금 | 히든 컬렉터 보상 |

## 2. Muscle System (근육 3단계, 전체 펫 공통)

모든 펫에 에이전트 수 기반 근육 3단계가 적용된다.

| Stage | Condition | Visual Change |
|-------|-----------|---------------|
| **Normal** | 에이전트 0~1 | 기본 외형 |
| **Buff** | 에이전트 2~3 | 체격이 커지고 약간 근육질 |
| **Macho** | 에이전트 4+ | 어이없는 보디빌더 버전, 빛나는 이펙트 |

총 픽셀아트: **12종 x 3단계 x 5프레임 = 180개 애니메이션 프레임**

## 3. Friend System (친구 동물)

다중 세션 시 해금된 펫 중에서 친구 동물이 메뉴바 옆에 등장한다.

- 세션 1개: 메인 펫만 표시
- 세션 2개: 메인 펫 + 해금된 펫 중 1마리
- 세션 3개+: 메인 펫 + 해금된 펫 중 2마리 (메뉴바 공간 제약상 최대 3마리)

친구 펫 선택 우선순위: 가장 최근 해금된 순서.

## 4. Notification

- rate limit 사용량 >= 80% 도달 시 macOS `NSUserNotification` (또는 `UNUserNotificationCenter`) 발송
- 동일 조건으로 5분 내 중복 알림 방지

## 5. Architecture

### Data Flow

```
Claude Code sessions
  |  (hud.mjs writes session-state.json per session)
  v
pet-aggregator.mjs (3-second polling)
  |  Realtime: pet-state.json (current state - agents, sessions, rate limit)
  |  Cumulative: progress.json (total time, tokens, unlock state)
  |  Unlock check: add to unlocked array when condition met
  v
ClaudePet.app (Swift)
  |-- Menu bar icon: selected pet pixel art animation (muscle stage reflected)
  |-- SwiftUI popover: collection grid, unlock progress, pet selection
  |-- macOS notification: rate limit threshold
```

### File Changes

| File | Change |
|------|--------|
| `pet-aggregator.mjs` | 누적 통계 추적, `progress.json` 관리, 해금 조건 판정 로직 |
| `PetStateMachine.swift` | `MuscleStage` enum 추가 (normal/buff/macho), 에이전트 수 기반 판정 |
| `PetStateReader.swift` | `progress.json` 읽기 추가, 해금 상태 & 선택된 펫 로드 |
| `PixelArtRenderer.swift` | 12종 x 3단계 x 5프레임 픽셀아트 렌더링 (기존 고양이 코드 패턴 확장) |
| `StatusMenuController.swift` | NSMenu 제거 → NSPopover + SwiftUI `CollectionView` 호스팅 |
| `AppDelegate.swift` | 알림 권한 요청 추가 |

### New Files

| File | Purpose |
|------|---------|
| `CollectionView.swift` | SwiftUI 팝오버 메인 뷰 — 펫 그리드, 해금 현황, 선택 UI |
| `ProgressTracker.swift` | 해금 조건 정의 (12종별 조건 enum) & 진행률 계산 |
| `NotificationManager.swift` | rate limit macOS 알림 발송 & 중복 방지 |

## 6. Progress Data Schema

`~/.claude/pet/progress.json`:

```json
{
  "stats": {
    "totalSessions": 142,
    "totalTimeMinutes": 4820,
    "totalTokens": 2350000,
    "totalAgentRuns": 312,
    "maxConcurrentSessions": 4,
    "maxConcurrentAgents": 6,
    "rateLimitHits": 15,
    "longSessions": 28,
    "opusTimeMinutes": 890
  },
  "unlocked": ["cat", "hamster", "chick", "penguin"],
  "selectedPet": "cat",
  "unlockedAt": {
    "cat": "2026-03-15T10:00:00Z",
    "hamster": "2026-03-16T14:30:00Z"
  }
}
```

### Stat Tracking Rules

- `totalSessions`: 새로운 세션이 감지될 때마다 +1 (session-state.json의 고유 PID 기준)
- `totalTimeMinutes`: 활성 세션의 duration 합산, 1분 단위 반올림
- `totalTokens`: 각 세션의 context window usage에서 추출
- `totalAgentRuns`: 에이전트가 시작될 때마다 +1
- `maxConcurrentSessions`: 동시 활성 세션 수의 역대 최고치
- `maxConcurrentAgents`: 동시 활성 에이전트 수의 역대 최고치
- `rateLimitHits`: rate limit >= 80% 감지 횟수
- `longSessions`: 45분 이상 지속된 세션 횟수
- `opusTimeMinutes`: model 필드가 opus인 세션의 누적 시간

## 7. SwiftUI Popover UI

```
+-------------------------------+
|  [Cat pixel art]  Macho!      |  <- 현재 펫 + 근육 상태 (애니메이션)
|  Sessions: 3  Agents: 5       |  <- 실시간 현황
+-------------------------------+
|  +-----+ +-----+ +-----+     |
|  | Cat | | Ham | |Chick|     |  <- 해금된 펫: 실제 픽셀아트
|  +-----+ +-----+ +-----+     |     (선택된 펫은 테두리 하이라이트)
|  +-----+ +-----+ +-----+     |
|  |/////| |/////| |/////|     |  <- 잠긴 펫: 어두운 실루엣
|  +-----+ +-----+ +-----+     |
|  +-----+ +-----+ +-----+     |
|  |/////| |/////| |/////|     |
|  +-----+ +-----+ +-----+     |
+-------------------------------+
|  Fox - 32/50 agent runs       |  <- 다음 해금까지 프로그레스
|  [==============------] 64%   |
+-------------------------------+
|  Quit                         |
+-------------------------------+
```

- 해금된 펫 클릭 → 메인 펫으로 선택 (`progress.json`의 `selectedPet` 업데이트)
- 잠긴 펫 hover → 해금 조건 툴팁 표시
- "다음 해금" 섹션: 가장 진행률이 높은 잠긴 펫 1개 표시

## 8. README Badge

GitHub Pages에서 SVG를 서빙하여 README에 삽입:

```markdown
![My Claude Pet](https://username.github.io/claude-hud/pet-badge.svg)
```

SVG 내용:
- 선택된 메인 펫 픽셀아트 (CSS 애니메이션으로 프레임 순환)
- 근육 단계 반영
- 해금된 친구 펫들 나란히 표시
- 하단에 총 사용 통계 텍스트 (해금 수/12, 총 사용시간)

배지 SVG는 사용자가 수동으로 `progress.json`에서 생성하는 CLI 스크립트로 제공:
```bash
node pet/generate-badge.mjs > docs/pet-badge.svg
```

## 9. GitHub Pages Documentation

`docs/` 폴더 기반 GitHub Pages 사이트:

```
docs/
├── index.html              <- 메인 페이지 (소개, 설치 가이드, 스크린샷)
├── collection.html         <- 펫 도감 (전체 12종)
├── assets/
│   ├── style.css           <- 사이트 스타일
│   └── pets/               <- 각 펫 프리뷰 이미지 (SVG or PNG)
│       ├── cat-normal.svg
│       ├── cat-buff.svg
│       ├── cat-macho.svg
│       ├── hamster-normal.svg
│       └── ...
└── pet-badge.svg           <- README용 배지
```

### Collection Page (펫 도감)

각 펫 카드:
- **Normal / Buff / Macho** 3단계 픽셀아트를 나란히 비교 (CSS 애니메이션)
- 해금 조건 설명
- 펫 컨셉 한줄 설명

페이지 스타일: 다크 테마, 픽셀아트에 어울리는 레트로 게임 UI 느낌.

## 10. Visual Style Guide

gitanimals를 참고하되 독자적 스타일:

- **렌더링**: Core Graphics 기반 16x16 픽셀 그리드 (기존 v1 방식 유지)
- **색상 팔레트**: 기존 Cyan/Dark Cyan 기반에 각 동물별 고유 색상 추가
  - 따뜻한 톤 위주 (베이지, 살구색, 갈색 등)
  - gitanimals의 정확한 색상 코드는 사용하지 않음
- **애니메이션**: 프레임 기반 (5프레임/상태), Core Graphics 래스터화
- **차별점**: gitanimals는 SVG 벡터 + 기하학적 도형, Claude Pet은 16x16 도트 픽셀아트 + 레트로 게임 감성

## Technical Constraints

- macOS 13.0+ (SwiftUI 팝오버 지원)
- SwiftUI와 AppKit 혼합: NSHostingView로 SwiftUI를 NSPopover에 호스팅
- 빌드: swiftc로 직접 컴파일 (Xcode 프로젝트 없이 유지)
- progress.json 원자적 쓰기 (기존 pet-state.json과 동일 패턴)
