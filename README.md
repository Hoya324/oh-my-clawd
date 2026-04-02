<p align="center">
  <img src="docs/assets/icon-preview.png" width="128" alt="Claude HUD Icon" />
</p>

<h1 align="center">Claude HUD</h1>

<p align="center">
  <strong>Claude Code를 위한 상태 표시줄 + 메뉴바 펫</strong>
</p>

<p align="center">
  <a href="README_EN.md">English</a> · 한국어
</p>

<p align="center">
  <a href="https://github.com/Hoya324/claude-hud/releases/latest"><img src="https://img.shields.io/badge/DMG-다운로드-blue?style=flat-square" alt="DMG 다운로드" /></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey?style=flat-square" alt="macOS" />
  <img src="https://img.shields.io/badge/node-%3E%3D18-green?style=flat-square" alt="Node >= 18" />
  <img src="https://img.shields.io/github/license/Hoya324/claude-hud?style=flat-square" alt="License" />
</p>

---

## 미리보기

```
[HUD] | 5h:14%(3h51m) | wk:62%(3d5h) | session:29m | ctx:39% | 53 | agents:2 | opus-4-6
```

## 설치

### DMG 다운로드 (권장)

[최신 릴리스 페이지](https://github.com/Hoya324/claude-hud/releases/latest)에서 `.dmg` 파일을 다운로드하여 설치합니다.

### 수동 설치

```bash
git clone https://github.com/Hoya324/claude-hud.git ~/.claude-hud
~/.claude-hud/install.sh
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

## Claude Pet -- 메뉴바 동반자

macOS 메뉴바에 상주하는 타마고치 스타일의 픽셀아트 펫입니다. Claude Code 활동에 반응하며, 12종의 펫을 수집하고 근육 단계를 키울 수 있습니다.

### 펫 상태

| 상태 | 조건 | 동작 |
|------|------|------|
| 수면 | 활성 세션 없음 | 웅크린 자세, Zzz |
| 걷기 | 일반 사용 중 | 걷기 애니메이션 |
| 달리기 | 도구 호출 50회 이상 | 빠른 달리기, 땀방울 |
| 뚱뚱 | 컨텍스트 >= 70% | 부풀어 오른 몸 |
| 스트레스 | 요청 한도 >= 80% | 떨림, "!" 표시 |
| 피곤 | 세션 > 45분 | 축 처진 자세, 졸린 눈 |
| 협업 | 에이전트 2개 이상 | 함께 걷기 |

### 근육 단계

동시 실행 에이전트 수에 따라 펫이 성장합니다.

| 단계 | 조건 | 효과 |
|------|------|------|
| 일반 | 에이전트 0-1개 | 기본 크기 |
| 버프 | 에이전트 2-3개 | 넓은 어깨, 뚜렷한 근육 |
| 마초 | 에이전트 4개 이상 | 거대한 몸, 작은 머리, 금색 반짝임 |

### 펫 컬렉션 (12종)

| 펫 | 해금 조건 |
|----|-----------|
| 고양이 | 기본 펫 |
| 햄스터 | 총 세션 10회 |
| 병아리 | 총 사용 시간 5시간 |
| 펭귄 | 토큰 50만 사용 |
| 여우 | 에이전트 실행 50회 |
| 토끼 | 동시 세션 3개 이상 |
| 거위 | 총 사용 시간 30시간 |
| 카피바라 | 요청 한도 도달 10회 |
| 나무늘보 | 긴 세션(45분 이상) 20회 |
| 부엉이 | Opus 모델 사용 10시간 |
| 드래곤 | 동시 에이전트 5개 이상 |
| 유니콘 | 다른 모든 펫 해금 |

## 업데이트

메뉴바 팝오버의 **Check for Updates** 버튼을 클릭하면 GitHub Releases에서 최신 버전을 확인합니다. 새 버전이 있으면 다운로드 페이지로 이동합니다.

## 요구사항

- **macOS 13.0+**
- **Node.js >= 18**
- **Claude Code** OAuth 로그인 (요청 한도 데이터 조회용)

## 제거

```bash
~/.claude-hud/install.sh remove
rm -rf ~/.claude-hud
```

펫 앱을 별도로 설치한 경우:

```bash
~/.claude-hud/pet/install.sh remove
```

## 라이선스

MIT
