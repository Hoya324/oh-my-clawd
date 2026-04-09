# Claude Pet Skills Design — pet-redesign & pet-add

## Overview

Claude Pet 프로젝트에 두 개의 스킬을 추가한다:

1. **`pet-redesign`** — 기존 펫의 픽셀아트 디자인 퀄리티를 향상시키는 스킬
2. **`pet-add`** — 새로운 펫을 추가하는 스킬

두 스킬 모두 프로젝트 로컬 `.claude/skills/`에 설치된다.

---

## 공통 사항

### 그리드 사이즈 변경: 16×16 → 32×32

- 모든 펫 스프라이트를 32×32 그리드로 전환
- 픽셀 수 4배 증가 (256 → 1,024)로 정교한 디테일 표현 가능
- 메뉴바 표시: 32×32px (1x 스케일) — 기존과 동일한 표시 크기
- `PixelArtRenderer`의 그리드 사이즈 및 스케일 팩터 수정 필요

### 픽셀아트 품질 기준 (7원칙)

Claude가 스프라이트를 생성/개선할 때 따라야 하는 기준:

1. **실루엣 명확성** — 배경 없이도 캐릭터 형태가 즉시 인식되어야 함
2. **서브픽셀 디테일** — 32×32 해상도를 활용한 색상 그라데이션, 눈 하이라이트, 음영 표현
3. **색상 팔레트 일관성** — 펫당 주요 3-4색 + 보조 2색 이내, 기존 글로벌 팔레트(`CLR_*`) 활용
4. **애니메이션 원칙** — 스쿼시 & 스트레치, 무게감 표현, 2-4프레임으로 자연스러운 루프
5. **상태 구분** — 각 상태(idle, busy, stressed 등)가 스프라이트만으로 명확히 구분
6. **근육 단계 차이** — normal→buff→macho 진행이 점진적이면서도 뚜렷한 변화
7. **캐릭터성** — 해당 동물의 특징적 실루엣과 포즈가 살아있어야 함

### 브라우저 프리뷰 시스템

두 스킬 모두 브라우저에서 픽셀아트를 렌더링하여 시각적 확인 후 코드에 반영한다.

**프리뷰 기능:**
- 스프라이트의 `[[[UInt32?]]]` 데이터를 HTML Canvas로 렌더링
- 8x~16x 스케일로 확대 표시, `nil` 픽셀은 체커보드 배경
- 프레임 배열을 `setInterval`로 순차 재생하여 애니메이션 표현
- 상태(7개) / 근육 단계(3개) 전환 버튼
- 사용자 승인 후 코드 반영

---

## Skill 1: `pet-redesign`

### 목적

기존 12마리 펫의 픽셀아트를 32×32로 업그레이드하고, 디자인 퀄리티를 향상시킨다. 픽셀아트 품질과 애니메이션 모두 개선한다.

### 트리거

사용자가 기존 펫의 디자인 개선을 요청할 때.

### 워크플로우

```
1. 펫 목록 표시 → 사용자가 대상 펫 선택
2. 현재 스프라이트 파일 전체 읽기 ({PetName}Sprites.swift)
3. Claude가 7가지 품질 기준에 따라 분석
   - 실루엣 명확성, 서브픽셀 디테일, 색상 일관성 등
4. 32×32로 전체 21개 시퀀스 리디자인 (3 근육 × 7 상태)
5. 브라우저에서 Before/After 비교 프리뷰
   - 상태별 애니메이션 재생
   - 근육 단계별 비교
6. 사용자 승인
7. {PetName}Sprites.swift 코드 반영
```

### Claude 주도 방식

- Claude가 현재 스프라이트를 분석하고 문제점을 스스로 도출
- 개선 방향을 자율적으로 결정 (사용자에게 일일이 묻지 않음)
- 7가지 품질 기준을 내재화하여 일관된 퀄리티 보장
- 사용자는 최종 프리뷰에서만 승인/수정 요청

### 수정 대상 파일

- `pet/ClaudePet/Sources/Sprites/{PetName}Sprites.swift` — 스프라이트 데이터 전체 교체

---

## Skill 2: `pet-add`

### 목적

새로운 펫을 추가한다. 기존 펫과 겹치지 않는 unlock 조건, 테마 컬러, 디자인을 자동으로 결정하며, 품질은 기존 펫 이상을 보장한다.

### 트리거

사용자가 새 펫 추가를 요청할 때.

### 워크플로우

```
1. 사용자가 펫 이름(동물 종류) 입력
2. 기존 펫 자동 스캔
   - PetType.swift: 기존 case, displayName, unlockCondition
   - ProgressTracker.swift: 기존 stats 필드
   - 각 Sprites.swift: 기존 테마 컬러
3. Claude가 자동 결정 (중복 검증 포함)
   - displayName
   - unlock 조건: 기존 펫이 사용하지 않는 stat 조합
   - 테마 컬러: 기존 펫과 겹치지 않는 팔레트
   - 캐릭터 컨셉: 포즈, 특징적 실루엣
4. 32×32 스프라이트 생성 (3 근육 × 7 상태 × 2~4 프레임)
   - 7가지 품질 기준 적용
5. 브라우저에서 프리뷰
   - 전 상태/근육 단계 애니메이션 재생
   - unlock 조건 요약 표시
   - 기존 펫과의 차별점 표시
6. 사용자 승인
7. 코드 자동 반영 (4개 파일)
```

### 자동 중복 검증 규칙

| 항목 | 검증 방법 |
|------|-----------|
| **unlock 조건** | PetType.swift에서 기존 펫들의 `unlockCondition` 파싱 → 동일 stat + 유사 임계값 사용 금지 |
| **컬러 팔레트** | 기존 스프라이트 파일의 주요 색상 추출 → 새 펫의 메인 컬러가 기존과 동일하지 않도록 보장 |
| **동물 종류** | PetType enum의 case 목록과 겹치지 않는지 확인 |

### 수정 대상 파일 (4개)

1. **`pet/ClaudePet/Sources/Sprites/{PetName}Sprites.swift`** — 새로 생성 (약 5000줄, 21개 시퀀스 @ 32×32)
2. **`pet/ClaudePet/Sources/PetType.swift`** — enum case 추가, displayName, unlockCondition 추가
3. **`pet/ClaudePet/Sources/PixelArtRenderer.swift`** — `spriteProvider(for:)` switch에 새 case 추가
4. **`pet/ClaudePet/Sources/ProgressTracker.swift`** — 새 unlock 조건에 필요한 stat 필드가 없으면 추가

---

## 스킬 설치 위치

프로젝트 로컬: `.claude/skills/`

```
.claude/skills/
├── pet-redesign.md
└── pet-add.md
```

---

## 스프라이트 데이터 구조 (32×32)

기존과 동일한 인터페이스 유지:

```swift
// 타입: [[[UInt32?]]]
// [프레임][행 32개][열 32개]
// nil = 투명, UInt32 = ARGB 색상값

private let petNormalIdle: [[[UInt32?]]] = [
    [ // Frame 0
        [T,T,T,...,T],  // 32 columns
        // ... 32 rows
    ],
    [ // Frame 1
        // ...
    ],
]
```

### 기존 펫과의 호환성

- SpriteProvider 프로토콜 인터페이스 변경 없음
- PixelArtRenderer의 그리드 사이즈 상수와 스케일 팩터만 변경
- 기존 16×16 펫은 pet-redesign 스킬로 순차적 업그레이드
