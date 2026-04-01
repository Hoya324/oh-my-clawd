# Claude Pet — Distribution, Docs & UI Enhancement Design

## Overview

Claude Pet 프로젝트에 앱 아이콘, DMG 배포, 문서 사이트, Update 버튼을 추가한다.

## 1. Capybara App Icon

32x32 픽셀아트 카피바라를 앱 아이콘으로 사용한다. 걷는 포즈(Option A), 오른쪽을 향하는 사이드뷰.

### 디자인 사양

- **스타일**: 사이드뷰, 걷는 포즈, 검은 아웃라인, 따뜻한 갈색 톤
- **얼굴 포인트**: 3px 가로 슬릿 눈, 두 개의 귀(원근감), 짙은 갈색 코, 따뜻한 베이지 주둥이, 이마 하이라이트
- **컬러 팔레트**:
  - `#1A1A1A` — outline/eye
  - `#A07040` — main body
  - `#BA8C54` — lighter body
  - `#C8A468` — forehead highlight
  - `#7A5228` — dark shading
  - `#5C3820` — darkest (legs)
  - `#C4986C` — pale muzzle
  - `#5C3318` — nose
  - `#6B4E30` — ear inner

### 아이콘 생성 방식

- Swift 스크립트 `scripts/generate-icon.swift`로 32x32 픽셀 데이터를 여러 사이즈로 렌더링
- 생성 사이즈: 16x16, 32x32, 128x128, 256x256, 512x512
- `iconutil`로 `.iconset` → `.icns` 변환
- 결과물: `pet/ClaudePet/AppIcon.icns`

### 적용 위치

- `.app` 번들의 `Contents/Resources/AppIcon.icns`
- `Info.plist`의 `CFBundleIconFile` → `AppIcon`
- DMG 배경/아이콘

## 2. DMG Packaging

### 빌드 스크립트

`scripts/build-dmg.sh`:

```
1. swiftc로 바이너리 컴파일
2. .app 번들 구조 생성:
   ClaudePet.app/
   ├── Contents/
   │   ├── Info.plist (버전 번호 포함)
   │   ├── MacOS/ClaudePet
   │   └── Resources/AppIcon.icns
3. hdiutil create로 DMG 생성
4. Applications 심볼릭 링크 포함
```

### Info.plist 변경

- `CFBundleShortVersionString`: 버전 번호 (예: `1.0.0`)
- `CFBundleVersion`: 빌드 번호
- `CFBundleIconFile`: `AppIcon`

### DMG 구성

- `ClaudePet.app` — 앱 번들
- `Applications` → `/Applications` 심볼릭 링크
- 파일명: `ClaudePet-{version}-arm64.dmg`

## 3. Update Button

### 위치

`CollectionView.swift`의 `footerSection`에 "Check for Updates" 버튼 추가. HUD 토글과 Quit 버튼 사이에 배치.

### 동작 흐름

1. 버튼 클릭 → 버튼 텍스트 "Checking..." 표시
2. `URLSession`으로 `https://api.github.com/repos/Hoya324/claude-hud/releases/latest` GET 요청
3. 응답의 `tag_name` (예: `v1.0.1`)과 현재 앱 버전 비교
4. 결과에 따라:
   - **새 버전 있음**: "Update Available: v1.0.1" 표시 + 클릭 시 릴리즈 페이지 열기
   - **최신 버전**: "Up to date (v1.0.0)" 표시 (3초 후 원래 텍스트로 복원)
   - **오류**: "Check failed" 표시

### 구현 위치

- `UpdateChecker.swift` 새 파일 — GitHub API 호출 로직
- `CollectionView.swift` — UI 버튼 추가
- `PetViewModel` — 업데이트 상태 관리 (`@Published` 속성 추가)

### 버전 비교

- `Bundle.main.infoDictionary?["CFBundleShortVersionString"]`로 현재 버전 읽기
- semver 문자열 비교 (major.minor.patch)

## 4. README

### 구조

- `README.md` — 한국어 메인 (상단에 `[English](README_EN.md)` 링크)
- `README_EN.md` — 영어 버전

### 내용

1. **프로젝트 소개** — Claude Pet + HUD 한 줄 설명, 카피바라 아이콘 이미지
2. **설치** — DMG 다운로드 링크 (GitHub Releases), 수동 설치 방법
3. **기능** — Pet 시스템, HUD 설명, 스크린샷
4. **펫 목록** — 12종 펫 + 언락 조건 테이블
5. **업데이트** — Check for Updates 버튼 설명
6. **요구사항** — macOS 13.0+, Node.js 18+
7. **라이선스** — MIT

## 5. Documentation Site

### 참고 사이트

[oh-my-harness](https://hoya324.github.io/oh-my-harness/) 구조를 차용하되, 미니멀 화이트 테마로 변경.

### 파일 구조

```
docs/
├── index.html       # 랜딩 페이지
├── docs.html        # 문서 (단일 페이지, 앵커 링크)
├── style.css        # 미니멀 화이트 테마
├── theme.js         # (필요 시) 다크 모드 토글 — 기본은 화이트만
├── i18n.js          # 한/영 번역
└── assets/          # 스크린샷, 아이콘 이미지
```

### 테마

- **배경**: 순수 화이트 (`#FFFFFF`)
- **텍스트**: 다크 그레이 (`#1a1a1a`)
- **악센트 컬러**: 프로젝트 브랜드 cyan (`#06B6D4`)
- **폰트**: Inter (본문), Space Mono (코드), Space Grotesk (헤딩)
- **보더**: `1px solid #e5e7eb` (부드러운 그레이)
- **코드 블록**: 라이트 그레이 배경 (`#f8f9fa`)

### 랜딩 페이지 (index.html)

1. **Hero** — 카피바라 아이콘 + "Claude Pet" 타이틀 + 설명 + DMG 다운로드 CTA
2. **Features** — Pet System, HUD Status Line, Update 기능 소개
3. **Pet Collection** — 12종 펫 그리드 미리보기
4. **Installation** — 3-step 설치 가이드
5. **Footer** — GitHub, License

### 문서 페이지 (docs.html)

왼쪽 사이드바 (260px) + 메인 콘텐츠:

1. **Getting Started** — Installation, Quick Start
2. **Features** — Pet System, Muscle Stages, HUD Status Line
3. **Pet Collection** — 12종 펫 테이블 (이름, 언락 조건, 설명)
4. **Configuration** — HUD 설정, 펫 선택
5. **Update** — DMG 다운로드, Check for Updates 버튼

### i18n

- `data-i18n` 어트리뷰트 기반
- `localStorage`에 언어 설정 저장 (`claude-pet-lang`)
- 네비게이션 바에 언어 전환 드롭다운

### 배포

- GitHub Pages: `Settings > Pages > Source: Deploy from branch > /docs folder`
- URL: `https://hoya324.github.io/claude-hud/`

## 구현 순서

1. 아이콘 생성 스크립트 + `.icns` 파일
2. DMG 빌드 스크립트
3. Update 버튼 (UpdateChecker.swift + CollectionView 수정)
4. README 작성 (한/영)
5. Docs 사이트 (index.html, docs.html, style.css, i18n.js)
