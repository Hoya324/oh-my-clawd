<p align="center">
  <img src="docs/assets/icon-preview.png" width="128" alt="oh-my-clawd Icon" />
</p>

<p align="center"><em>내 컴퓨터에 침투한 clawd</em></p>

<h1 align="center">oh-my-clawd</h1>

<p align="center">
  <strong>Claude Code를 위한 상태 표시줄 + 메뉴바 Clawd</strong>
</p>

<p align="center">
  <a href="README_EN.md">English</a> · 한국어
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

macOS 메뉴바에 상주하는 타마고치 스타일의 픽셀아트 캐릭터입니다. Claude Code의 공식 마스코트인 Clawd(#D97757)가 Claude Code 활동에 반응하며, 9종의 액세서리를 수집하고 3단계의 활동 레벨을 확인할 수 있습니다.

### Clawd 상태

| 상태 | 한국어 | 조건 |
|------|--------|------|
| idle | 자고 있어요... | 활성 세션 없음 |
| wakeUp | 깨어나는 중! | 수면에서 전환 시 |
| normal | 신나게 걷는 중 | 기본 활성 상태 |
| busy | 열심히 일하는 중! | 도구 호출 50회 이상 |
| bloated | 컨텍스트가 가득... | 컨텍스트 70% 이상 |
| stressed | 레이트 리밋 경고! | 요청 한도 80% 이상 |
| tired | 피곤해요... | 45분 이상 세션 |
| collab | 함께 일하는 중! | 에이전트 2개 이상 |

### 활동 레벨

동시 실행 에이전트 수에 따라 Clawd의 활동 레벨이 달라집니다.

| 레벨 | 조건 | 설명 |
|------|------|------|
| Normal (보통) | 에이전트 0-1개 | 기본 상태 |
| Glowing (빛나는 중) | 에이전트 2-3개 | 발광 효과 |
| Supercharged! (슈퍼차지!) | 에이전트 4개 이상 | 최대 에너지 |

### 액세서리 컬렉션 (9종)

Claude Code 사용 실적에 따라 Clawd에게 착용시킬 액세서리를 해금할 수 있습니다.

**모자 (5종)**

| 액세서리 | 해금 조건 |
|----------|-----------|
| 캡모자 (Cap) | 세션 10회 |
| 꼬깔모자 (Party Hat) | 총 사용 시간 5시간 |
| 산타모자 (Santa Hat) | 토큰 50만 사용 |
| 실크햇 (Silk Hat) | 에이전트 실행 50회 |
| 카우보이모자 (Cowboy Hat) | 총 사용 시간 30시간 |

**안경 (4종)**

| 액세서리 | 해금 조건 |
|----------|-----------|
| 뿔테안경 (Horn-rimmed) | 동시 세션 3개 이상 |
| 선글라스 (Sunglasses) | 요청 한도 도달 10회 |
| 둥근안경 (Round Glasses) | 긴 세션(45분+) 20회 |
| 별안경 (Star Glasses) | Opus 모델 사용 10시간 |

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

## 라이센스

이 프로젝트는 MIT 라이센스를 따릅니다. 단, Clawd 캐릭터 디자인의 저작권은 [Anthropic](https://anthropic.com)에 있습니다. 본 프로젝트는 비상업적 팬 프로젝트이며, 상업적 용도로 사용할 수 없고, 사용할 생각도 없습니다. 저작권 관련 문제가 발생할 경우 즉시 삭제하겠습니다. 살려주세요.
