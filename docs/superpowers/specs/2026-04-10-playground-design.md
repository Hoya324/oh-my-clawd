# Clawd Playground Design Spec

## Overview

기존 팝오버 패널(280x520pt) 안에 Clawd가 자유롭게 돌아다니는 미니홈피 스타일 플레이그라운드 섹션을 추가한다. 픽셀 잔디 배경 위에서 Clawd가 랜덤으로 걸어다니고, 클릭 시 다양한 반응을 보여준다. 주간 세션이 만료되면 RIP 유령 상태로 전환된다.

## 1. 플레이그라운드 영역

### 위치 & 크기
- **위치**: Stats 섹션 아래, 악세서리 섹션 위
- **크기**: ~260 x 120pt (팝오버 폭에 맞춤)
- **접기/펴기**: 커스텀 헤더("Playground" + chevron)로 토글. 기본 상태는 펼침

### 배경
- 하단 ~20pt: 픽셀 느낌의 잔디 패턴 (2-3색 초록 픽셀). Swift 코드에서 직접 그림 (이미지 파일 X)
- 상단: 어두운 배경 (팝오버 테마에 맞춤)
- 전체적으로 oh-my-clawd 픽셀아트 컨셉과 통일

### Clawd 표시
- 기존 PixelArtRenderer로 렌더링된 NSImage를 그대로 사용
- 악세서리, 바디컬러, 이펙트(glow/supercharge) 모두 자동 적용
- 크기: 64x64pt (32px * 2x 스케일)

## 2. 이동 시스템

### 랜덤 워킹
- 2~5초 간격으로 새 목표 지점(x좌표)을 잔디 영역 내에서 랜덤 선택
- SwiftUI `.animation(.easeInOut)` 으로 부드럽게 이동
- 이동 속도는 거리에 비례 (먼 거리일수록 조금 더 오래 걸림)

### 방향 전환
- 목표 지점이 현재 위치보다 오른쪽이면 기본 방향
- 왼쪽이면 스프라이트 수평 반전 (`.scaleEffect(x: -1)`)

### 애니메이션 상태
- **이동 중**: normal 상태 프레임 루프 재생 (걷기 느낌)
- **정지 시**: normal 상태 첫 번째 프레임 고정 (서있는 느낌). idle(수면/Zzz) 상태는 사용하지 않음 — 플레이그라운드에서는 항상 깨어있는 상태

### 이동 범위
- 잔디 영역 위를 좌우로만 이동
- Clawd 발(64pt 이미지의 하단)이 잔디 상단에 닿는 y좌표에 고정. 캐릭터 몸통은 잔디 위 공간에 표시됨
- 좌우 padding을 두어 캐릭터가 잘리지 않게 처리

## 3. 클릭 인터랙션

### 랜덤 반응 (가중치 기반)
| 반응 | 가중치 | 설명 |
|------|--------|------|
| 점프 + 하트 | 40% | 기존 interaction 스프라이트(점프 6프레임) 재생 + 하트가 위로 떠오르며 페이드아웃 |
| 갸우뚱 + ? | 30% | tilt idle motion 재생 + "?" 말풍선이 머리 위에 표시 |
| 웨이브 | 20% | wave idle motion 재생 |
| 스트레칭 | 10% | stretch idle motion 재생 |

### 이펙트 표현
- 하트/? 등은 SwiftUI Text + opacity 애니메이션으로 표현
- 캐릭터 현재 위치 기준으로 머리 위에 정확히 표시 (캐릭터 이동에 따라가야 함)
- 약 1초간 떠올랐다 사라짐

### 쿨다운
- 반응 재생 중에는 추가 클릭 무시
- 애니메이션 완료 후 다시 반응 가능

## 4. RIP 유령 상태

### 트리거
- 주간 세션 사용량 100% (weekly rate limit 만료)
- 기존 PetStateMachine의 세션 데이터를 활용하여 판단

### 표현
- Clawd가 반투명 (opacity 0.5)
- 잔디 위를 걷지 않고, 공중에서 느리게 좌우 부유
- "RIP" 텍스트가 머리 위에 상시 표시
- 부유 모션: 위아래로 살짝 흔들리며 (sin wave) 좌우 느리게 이동

### 클릭 반응
- 일반 반응 대신, 잠깐 멈췄다가 (약 1초 정지) 다시 움직임

### 복구
- 주간 세션이 리셋되면 자동으로 normal 상태 복귀
- 유령 → normal 전환 시 opacity 애니메이션으로 자연스럽게

## 5. 접기/펴기 시스템

### 플레이그라운드 섹션
- "Playground" 헤더 + chevron 아이콘
- 접으면 헤더 한 줄만 표시

### 악세서리 섹션
- 기존 Hats/Glasses/Pants 각각을 하나의 "Accessories" 그룹으로 묶음
- 접기/펴기 가능한 단일 섹션으로 변경

### 상태 저장
- 접기/펴기 상태를 UserDefaults에 저장
- 팝오버를 닫았다 열어도 상태 유지

### 스크롤
- 전체 팝오버는 기존 ScrollView 유지
- 플레이그라운드 펼침 시 스크롤로 악세서리 접근 가능

## 6. 기술 구현 방향

### 아키텍처
- SwiftUI Canvas/ZStack 기반
- 기존 PixelArtRenderer 파이프라인 100% 재사용
- 새로운 `PlaygroundView.swift` 파일 생성

### 상태 관리
- `ClawdViewModel`에 플레이그라운드 관련 @Published 속성 추가:
  - `playgroundX: CGFloat` (현재 x 위치)
  - `playgroundTargetX: CGFloat` (목표 x 위치)
  - `isMoving: Bool`
  - `facingRight: Bool`
  - `isGhostMode: Bool`
  - `currentInteraction: PlaygroundInteraction?`
- 이동 타이머는 PlaygroundView 내에서 관리

### 유령 모드 판정
- 기존 weekly rate limit 데이터 활용
- `weeklyUsagePercent >= 100` 일 때 ghost mode 활성화
