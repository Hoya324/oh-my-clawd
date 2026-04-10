<p align="center">
  <img src="docs/assets/icon-preview.png" width="128" alt="oh-my-clawd Icon" />
</p>

<p align="center"><em>내 컴퓨터에 침투한 clawd</em></p>

<p align="center">
  <img src="docs/assets/clawd/normal.gif" width="64" alt="Clawd Normal" />
  <img src="docs/assets/clawd/fashion/casual.gif" width="64" alt="캐주얼" />
  <img src="docs/assets/clawd/busy.gif" width="64" alt="Clawd Busy" />
  <img src="docs/assets/clawd/fashion/gentleman.gif" width="64" alt="젠틀맨" />
  <img src="docs/assets/clawd/stressed.gif" width="64" alt="Clawd Stressed" />
  <img src="docs/assets/clawd/fashion/cowboy.gif" width="64" alt="카우보이" />
  <img src="docs/assets/clawd/collab.gif" width="64" alt="Clawd Collab" />
  <img src="docs/assets/clawd/fashion/party.gif" width="64" alt="파티" />
  <img src="docs/assets/clawd/idle.gif" width="64" alt="Clawd Idle" />
</p>

<h1 align="center">oh-my-clawd</h1>

<p align="center">
  <strong>Claude Code를 위한 상태 표시줄 + 메뉴바 다마고치</strong>
</p>

<p align="center">
  <a href="README.md">English</a> · 한국어
</p>

<p align="center">
  <a href="https://github.com/Hoya324/oh-my-clawd/releases/latest/download/OhMyClawd.dmg"><img src="https://img.shields.io/badge/DMG-다운로드-blue?style=flat-square" alt="DMG 다운로드" /></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey?style=flat-square" alt="macOS" />
  <img src="https://img.shields.io/badge/node-%3E%3D18-green?style=flat-square" alt="Node >= 18" />
  <img src="https://img.shields.io/github/license/Hoya324/oh-my-clawd?style=flat-square" alt="License" />
</p>

---

## 미리보기

```
[HUD] | 5h:14%(3h51m) | wk:62%(3d5h) | session:29m | ctx:39% | 53 | agents:2 | opus-4-6
```
<img width="2058" height="670" alt="image" src="https://github.com/user-attachments/assets/3e5326dd-19ec-4985-b7d7-5a11c3fa8e04" />

## 설치

### DMG 다운로드 (권장)

[최신 릴리스 페이지](https://github.com/Hoya324/oh-my-clawd/releases/latest/download/OhMyClawd.dmg)에서 `.dmg` 파일을 다운로드하여 설치합니다.

### 수동 설치

```bash
git clone https://github.com/Hoya324/oh-my-clawd.git ~/.oh-my-clawd
~/.oh-my-clawd/install.sh
```

설치 후 **Claude Code를 재시작**하세요.

## HUD 상태 표시줄

| 세그먼트 | 설명 | 색상 로직 |
|----------|------|-----------|
| `5h:14%` | 5시간 요청 한도 사용률 | 초록 < 70% < 노랑 < 90% < 빨강 |
| `(3h51m)` | 5시간 한도 초기화까지 남은 시간 | 흐린색 |
| `wk:62%` | 주간 요청 한도 사용률 | 위와 동일 |
| `session:29m` | 현재 세션 지속 시간 | 초록 < 30분 < 노랑 < 60분 < 빨강 |
| `ctx:39%` | 컨텍스트 윈도우 사용률 | 초록 < 70% < 노랑 < 85% < 빨강 |
| `53` | 세션 내 총 도구 호출 횟수 | -- |
| `agents:2` | 현재 실행 중인 에이전트 수 | 청록색 |
| `opus-4-6` | 활성 모델 | 흐린색 |

## Clawd — 메뉴바 동반자

macOS 메뉴바에 상주하는 다마고치 스타일의 32x32 픽셀아트 캐릭터입니다.
Claude Code의 공식 마스코트인 **Clawd**(#D97757)가 Claude Code 활동에 실시간으로 반응합니다.

> 8가지 상태 | 3단계 활동 레벨 | 14종 액세서리 | 10가지 바디 컬러

### Clawd 상태

| 상태 | | 한국어 | 조건 |
|------|--|--------|------|
| Sleeping | <img src="docs/assets/clawd/idle.gif" width="32"> | 자고 있어요... | 활성 세션 없음 |
| Waking up | <img src="docs/assets/clawd/wakeup.gif" width="32"> | 깨어나는 중! | idle→active 전환 |
| Walking | <img src="docs/assets/clawd/normal.gif" width="32"> | 신나게 걷는 중 | 기본 활성 상태 |
| Working hard | <img src="docs/assets/clawd/busy.gif" width="32"> | 열심히 일하는 중! | 도구 호출 50회 이상 |
| Bloated | <img src="docs/assets/clawd/bloated.gif" width="32"> | 컨텍스트가 가득... | 컨텍스트 70% 이상 |
| Stressed | <img src="docs/assets/clawd/stressed.gif" width="32"> | 레이트 리밋 경고! | 요청 한도 80% 이상 |
| Tired | <img src="docs/assets/clawd/tired.gif" width="32"> | 피곤해요... | 45분 이상 세션 |
| Collab | <img src="docs/assets/clawd/collab.gif" width="32"> | 함께 일하는 중! | 에이전트 2개 이상 |

### 활동 레벨

동시 실행 에이전트 수에 따라 Clawd의 활동 레벨이 달라집니다.

| 레벨 | 조건 | 설명 |
|------|------|------|
| Normal (보통) | 에이전트 0-1개 | 기본 상태 |
| Glowing (빛나는 중) | 에이전트 2-3개 | 발광 효과 |
| Supercharged! (슈퍼차지!) | 에이전트 4개 이상 | 최대 에너지 |

### 액세서리 컬렉션 (14종)

Claude Code 사용 실적에 따라 Clawd에게 착용시킬 액세서리를 해금할 수 있습니다.
모자, 안경, 바지를 자유롭게 조합하여 나만의 Clawd를 꾸며보세요!

#### 모자 (5종)

| 액세서리 | | 해금 조건 |
|----------|--|-----------|
| 캡모자 (Cap) | <img src="docs/assets/clawd/acc-cap.gif" width="32"> | 세션 10회 |
| 꼬깔모자 (Party Hat) | <img src="docs/assets/clawd/acc-partyhat.gif" width="32"> | 총 사용 시간 5시간 |
| 산타모자 (Santa Hat) | <img src="docs/assets/clawd/acc-santahat.gif" width="32"> | 토큰 50만 사용 |
| 실크햇 (Silk Hat) | <img src="docs/assets/clawd/acc-silkhat.gif" width="32"> | 에이전트 실행 50회 |
| 카우보이모자 (Cowboy Hat) | <img src="docs/assets/clawd/acc-cowboyhat.gif" width="32"> | 총 사용 시간 30시간 |

#### 안경 (4종)

| 액세서리 | | 해금 조건 |
|----------|--|-----------|
| 뿔테안경 (Horn-rimmed) | <img src="docs/assets/clawd/acc-hornrimmed.gif" width="32"> | 동시 세션 3개 이상 |
| 선글라스 (Sunglasses) | <img src="docs/assets/clawd/acc-sunglasses.gif" width="32"> | 요청 한도 도달 10회 |
| 둥근안경 (Round Glasses) | <img src="docs/assets/clawd/acc-roundglasses.gif" width="32"> | 긴 세션(45분+) 20회 |
| 별안경 (Star Glasses) | <img src="docs/assets/clawd/acc-starglasses.gif" width="32"> | Opus 모델 사용 10시간 |

#### 바지 (5종)

| 액세서리 | | 해금 조건 |
|----------|--|-----------|
| 청바지 (Jeans) | <img src="docs/assets/clawd/acc-jeans.gif" width="32"> | 총 사용 시간 15시간 |
| 반바지 (Shorts) | <img src="docs/assets/clawd/acc-shorts.gif" width="32"> | 세션 100회 |
| 정장바지 (Slacks) | <img src="docs/assets/clawd/acc-slacks.gif" width="32"> | 토큰 100만 사용 |
| 운동바지 (Joggers) | <img src="docs/assets/clawd/acc-joggers.gif" width="32"> | 에이전트 실행 100회 |
| 카고바지 (Cargo Pants) | <img src="docs/assets/clawd/acc-cargo.gif" width="32"> | 총 사용 시간 50시간 |

### Clawd 패션쇼

모자 + 안경 + 바지를 자유롭게 조합하면 나만의 스타일이 완성됩니다.

<p align="center">
  <img src="docs/assets/clawd/fashion/casual.gif" width="64" alt="캐주얼" />
  <img src="docs/assets/clawd/fashion/gentleman.gif" width="64" alt="젠틀맨" />
  <img src="docs/assets/clawd/fashion/cowboy.gif" width="64" alt="카우보이" />
  <img src="docs/assets/clawd/fashion/party.gif" width="64" alt="파티" />
  <img src="docs/assets/clawd/fashion/santa.gif" width="64" alt="산타" />
  <img src="docs/assets/clawd/fashion/nerd.gif" width="64" alt="너드" />
  <img src="docs/assets/clawd/fashion/sporty.gif" width="64" alt="스포티" />
</p>

<p align="center">
  <sub>캐주얼 · 젠틀맨 · 카우보이 · 파티 · 산타 · 너드 · 스포티</sub>
</p>

> 총 **5 x 4 x 5 = 100가지** 이상의 조합이 가능합니다. (미착용 포함 시 더 많아요!)

### 바디 컬러 변경

컬러 가챠 티켓을 사용하여 Clawd의 바디 컬러를 변경할 수 있습니다. 10가지 컬러 중 랜덤으로 획득!

| 컬러 | 이름 |
|------|------|
| 🟤 Terracotta | 테라코타 (기본) |
| 🔵 Blue | 파란색 |
| 🔴 Red | 빨간색 |
| 🟢 Green | 초록색 |
| 🟣 Purple | 보라색 |
| 🟡 Gold | 골드 |
| 🩷 Pink | 분홍색 |
| 🔷 Navy | 네이비 |
| 🟩 Mint | 민트 |
| 🟠 Coral | 코랄 |

## 업데이트

메뉴바 팝오버의 **Check for Updates** 버튼을 클릭하면 GitHub Releases에서 최신 버전을 확인합니다. 새 버전이 있으면 다운로드 페이지로 이동합니다.

## 요구사항

- **macOS 13.0+**
- **Node.js >= 18**
- **Claude Code** OAuth 로그인 (요청 한도 데이터 조회용)

## 제거

```bash
~/.oh-my-clawd/install.sh remove
rm -rf ~/.oh-my-clawd
```

oh-my-clawd 앱을 별도로 설치한 경우:

```bash
~/.oh-my-clawd/pet/install.sh remove
```

## 라이선스

MIT

---

이 프로젝트는 MIT 라이센스를 따릅니다. 단, Clawd 캐릭터 디자인의 저작권은 [Anthropic](https://anthropic.com)에 있습니다. 본 프로젝트는 비상업적 팬 프로젝트이며, 상업적 용도로 사용할 수 없고, 사용할 생각도 없습니다. 저작권 관련 문제가 발생할 경우 즉시 삭제하겠습니다. 살려주세요.
