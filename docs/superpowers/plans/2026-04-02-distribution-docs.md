# Claude Pet Distribution, Docs & UI Enhancement — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add capybara app icon, DMG packaging, update button, bilingual README, and GitHub Pages docs site.

**Architecture:** Icon generated via Swift script → .icns. DMG built via hdiutil shell script. Update button checks GitHub Releases API from SwiftUI popover. Docs site is hand-crafted static HTML/CSS/JS with i18n, deployed via GitHub Pages.

**Tech Stack:** Swift (icon gen + app changes), Bash (build scripts), HTML/CSS/JS (docs site)

---

## File Structure

### New Files
- `scripts/generate-icon.swift` — Swift CLI that renders 32x32 pixel data to .iconset PNGs
- `scripts/build-dmg.sh` — Compiles app, bundles .app, creates DMG
- `pet/ClaudePet/Sources/UpdateChecker.swift` — GitHub Releases API client
- `README_EN.md` — English README
- `docs/index.html` — Landing page (overwrite existing)
- `docs/docs.html` — Documentation single-page
- `docs/style.css` — Minimal white theme (replaces `docs/assets/style.css`)
- `docs/i18n.js` — Korean/English translation system

### Modified Files
- `pet/ClaudePet/Info.plist` — Add `CFBundleIconFile`
- `pet/ClaudePet/Sources/CollectionView.swift` — Add update button to footer, update state to PetViewModel
- `pet/install.sh` — Add UpdateChecker.swift to compile list, copy .icns to Resources
- `README.md` — Rewrite as Korean version

---

## Task 1: Generate Capybara App Icon

**Files:**
- Create: `scripts/generate-icon.swift`
- Create: `pet/ClaudePet/AppIcon.icns` (generated output)

- [ ] **Step 1: Create icon generator Swift script**

Create `scripts/generate-icon.swift`:

```swift
import Cocoa

// Capybara pixel art (32x32) — walking pose, facing right, v5 design
let T: UInt32? = nil
let K: UInt32? = 0xFF1A1A1A  // outline/eye
let B: UInt32? = 0xFFA07040  // main body
let D: UInt32? = 0xFF7A5228  // dark shading
let L: UInt32? = 0xFFBA8C54  // lighter body
let X: UInt32? = 0xFF5C3820  // darkest (legs)
let P: UInt32? = 0xFFC4986C  // pale muzzle
let E: UInt32? = 0xFF6B4E30  // ear inner
let N: UInt32? = 0xFF5C3318  // nose
let H: UInt32? = 0xFFC8A468  // forehead highlight

let pixels: [[UInt32?]] = [
[T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
[T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
[T,T,T,T,T,T,K,K,T,T,T,K,K,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
[T,T,T,T,T,K,E,E,K,T,K,E,E,K,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
[T,T,T,T,K,B,B,B,B,K,B,B,B,K,K,K,K,K,K,K,K,K,K,T,T,T,T,T,T,T,T,T],
[T,T,T,K,L,L,H,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T,T,T,T],
[T,T,K,L,L,H,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T,T,T],
[T,T,K,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T,T],
[T,T,K,B,B,K,K,K,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T,T],
[T,K,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T],
[T,K,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T],
[T,T,K,P,P,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T],
[T,T,K,N,P,P,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T],
[T,T,T,K,K,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T],
[T,T,T,T,K,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T],
[T,T,T,T,K,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T],
[T,T,T,T,K,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T],
[T,T,T,T,K,B,B,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,B,K,T,T,T,T,T,T],
[T,T,T,T,T,K,D,D,D,B,B,B,B,B,B,B,B,B,B,B,B,B,D,D,K,T,T,T,T,T,T,T],
[T,T,T,T,T,K,D,D,D,B,B,B,B,B,B,B,B,B,B,B,B,D,D,D,K,T,T,T,T,T,T,T],
[T,T,T,T,T,K,K,D,K,K,B,B,B,B,B,B,B,B,B,K,K,D,K,K,T,T,T,T,T,T,T,T],
[T,T,T,T,T,T,K,X,X,K,T,T,T,T,T,T,T,T,T,K,X,X,K,T,T,T,T,T,T,T,T,T],
[T,T,T,T,T,T,K,X,X,K,T,T,T,T,T,T,T,T,T,K,X,X,K,T,T,T,T,T,T,T,T,T],
[T,T,T,T,T,K,K,K,K,K,K,T,T,T,T,T,T,T,K,K,K,K,K,K,T,T,T,T,T,T,T,T],
[T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
[T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
[T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
[T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
[T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
[T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
[T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
[T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
]

func renderToImage(size: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: size * 4, bitsPerPixel: 32
    )!
    let pixelScale = size / 32
    let data = rep.bitmapData!
    for y in 0..<32 {
        for x in 0..<32 {
            guard let color = pixels[y][x] else { continue }
            let r = UInt8((color >> 16) & 0xFF)
            let g = UInt8((color >> 8) & 0xFF)
            let b = UInt8(color & 0xFF)
            let a = UInt8((color >> 24) & 0xFF)
            for dy in 0..<pixelScale {
                for dx in 0..<pixelScale {
                    let px = x * pixelScale + dx
                    let py = y * pixelScale + dy
                    let offset = (py * size + px) * 4
                    data[offset] = r
                    data[offset + 1] = g
                    data[offset + 2] = b
                    data[offset + 3] = a
                }
            }
        }
    }
    return rep
}

// Generate .iconset directory
let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let projectDir = scriptDir.deletingLastPathComponent()
let iconsetDir = projectDir.appendingPathComponent("pet/ClaudePet/AppIcon.iconset")

try? FileManager.default.removeItem(at: iconsetDir)
try! FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for (name, size) in sizes {
    // Round up to nearest multiple of 32 for clean scaling
    let renderSize = max(size, 32)
    let rep = renderToImage(size: renderSize)
    // If renderSize != size, we need to resize
    let finalRep: NSBitmapImageRep
    if renderSize != size {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .none
        rep.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
        img.unlockFocus()
        finalRep = NSBitmapImageRep(data: img.tiffRepresentation!)!
    } else {
        finalRep = rep
    }
    let pngData = finalRep.representation(using: .png, properties: [:])!
    let filePath = iconsetDir.appendingPathComponent(name)
    try! pngData.write(to: filePath)
    print("  Generated \(name) (\(size)x\(size))")
}

print("Iconset created at \(iconsetDir.path)")
print("Run: iconutil -c icns \(iconsetDir.path)")
```

- [ ] **Step 2: Run the icon generator and create .icns**

```bash
cd /Users/hoyana/Desktop/01_sideproject/claude-hud
swiftc -o /tmp/generate-icon scripts/generate-icon.swift -framework Cocoa && /tmp/generate-icon
iconutil -c icns pet/ClaudePet/AppIcon.iconset -o pet/ClaudePet/AppIcon.icns
rm -rf pet/ClaudePet/AppIcon.iconset /tmp/generate-icon
```

Expected: `pet/ClaudePet/AppIcon.icns` exists and is a valid icon file.

- [ ] **Step 3: Update Info.plist to reference icon**

Add `CFBundleIconFile` key to `pet/ClaudePet/Info.plist`:

```xml
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
```

Insert after the `CFBundleShortVersionString` block (line 14).

- [ ] **Step 4: Update install.sh to copy icon**

In `pet/install.sh`, after the line `cp "$SCRIPT_DIR/ClaudePet/Info.plist" "$APP_BUNDLE/Contents/"`, add:

```bash
if [[ -f "$SCRIPT_DIR/ClaudePet/AppIcon.icns" ]]; then
  cp "$SCRIPT_DIR/ClaudePet/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi
```

- [ ] **Step 5: Commit**

```bash
git add scripts/generate-icon.swift pet/ClaudePet/AppIcon.icns pet/ClaudePet/Info.plist pet/install.sh
git commit -m "feat: add capybara pixel art app icon (.icns)"
```

---

## Task 2: DMG Build Script

**Files:**
- Create: `scripts/build-dmg.sh`

- [ ] **Step 1: Create the DMG build script**

Create `scripts/build-dmg.sh`:

```bash
#!/bin/bash
# Build ClaudePet.app bundle and create distributable DMG
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PET_DIR="$PROJECT_DIR/pet/ClaudePet"
APP_NAME="ClaudePet"
VERSION=$(grep -A1 CFBundleShortVersionString "$PET_DIR/Info.plist" | grep string | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="ClaudePet-${VERSION}-arm64.dmg"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "Building Claude Pet v${VERSION}..."

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Compile
echo "  Compiling Swift..."
cd "$PET_DIR"
swiftc -o "$BUILD_DIR/$APP_NAME" \
  Sources/main.swift \
  Sources/AppDelegate.swift \
  Sources/PetStateReader.swift \
  Sources/PetStateMachine.swift \
  Sources/PetType.swift \
  Sources/ProgressTracker.swift \
  Sources/NotificationManager.swift \
  Sources/PixelArtRenderer.swift \
  Sources/CollectionView.swift \
  Sources/StatusMenuController.swift \
  Sources/UpdateChecker.swift \
  Sources/Sprites/CatSprites.swift \
  Sources/Sprites/HamsterSprites.swift \
  Sources/Sprites/ChickSprites.swift \
  Sources/Sprites/PenguinSprites.swift \
  Sources/Sprites/FoxSprites.swift \
  Sources/Sprites/RabbitSprites.swift \
  Sources/Sprites/GooseSprites.swift \
  Sources/Sprites/CapybaraSprites.swift \
  Sources/Sprites/SlothSprites.swift \
  Sources/Sprites/OwlSprites.swift \
  Sources/Sprites/DragonSprites.swift \
  Sources/Sprites/UnicornSprites.swift \
  -framework Cocoa \
  -framework ServiceManagement \
  -framework SwiftUI \
  -framework UserNotifications \
  -O 2>&1 || { echo -e "${RED}Build failed${NC}"; exit 1; }

# Create .app bundle
echo "  Creating app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$PET_DIR/Info.plist" "$APP_BUNDLE/Contents/"
if [[ -f "$PET_DIR/AppIcon.icns" ]]; then
  cp "$PET_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Create DMG
echo "  Creating DMG..."
DMG_STAGING="$BUILD_DIR/dmg-staging"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create -volname "Claude Pet" \
  -srcfolder "$DMG_STAGING" \
  -ov -format UDZO \
  "$BUILD_DIR/$DMG_NAME" 2>&1

rm -rf "$DMG_STAGING"

echo ""
echo -e "${GREEN}Build complete!${NC}"
echo "  App:  $APP_BUNDLE"
echo "  DMG:  $BUILD_DIR/$DMG_NAME"
echo "  Size: $(du -h "$BUILD_DIR/$DMG_NAME" | cut -f1)"
```

- [ ] **Step 2: Make executable and verify**

```bash
chmod +x scripts/build-dmg.sh
scripts/build-dmg.sh
```

Expected: `build/ClaudePet-1.0.0-arm64.dmg` is created. Open the DMG and verify ClaudePet.app and Applications symlink are present.

- [ ] **Step 3: Add build/ to .gitignore**

Append to `.gitignore`:

```
build/
```

- [ ] **Step 4: Commit**

```bash
git add scripts/build-dmg.sh .gitignore
git commit -m "feat: add DMG build script for distribution"
```

---

## Task 3: Implement UpdateChecker

**Files:**
- Create: `pet/ClaudePet/Sources/UpdateChecker.swift`

- [ ] **Step 1: Create UpdateChecker.swift**

Create `pet/ClaudePet/Sources/UpdateChecker.swift`:

```swift
import Foundation

enum UpdateStatus: Equatable {
    case idle
    case checking
    case upToDate(String)       // current version
    case available(String)      // new version tag
    case failed
}

struct UpdateChecker {
    private static let repoOwner = "Hoya324"
    private static let repoName = "claude-hud"
    private static let releasesURL = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
    static let releasePageURL = "https://github.com/\(repoOwner)/\(repoName)/releases/latest"

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    static func check(completion: @escaping (UpdateStatus) -> Void) {
        guard let url = URL(string: releasesURL) else {
            completion(.failed)
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else {
                DispatchQueue.main.async { completion(.failed) }
                return
            }

            let remoteVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
            let current = Self.currentVersion

            DispatchQueue.main.async {
                if compareVersions(remoteVersion, isNewerThan: current) {
                    completion(.available(tagName))
                } else {
                    completion(.upToDate(current))
                }
            }
        }.resume()
    }

    private static func compareVersions(_ remote: String, isNewerThan local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(r.count, l.count) {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv > lv { return true }
            if rv < lv { return false }
        }
        return false
    }
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd /Users/hoyana/Desktop/01_sideproject/claude-hud/pet/ClaudePet
swiftc -typecheck Sources/UpdateChecker.swift -framework Foundation
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add pet/ClaudePet/Sources/UpdateChecker.swift
git commit -m "feat: add UpdateChecker for GitHub Releases API"
```

---

## Task 4: Add Update Button to Popover

**Files:**
- Modify: `pet/ClaudePet/Sources/CollectionView.swift` (PetViewModel + footerSection)
- Modify: `pet/install.sh` (add UpdateChecker.swift to compile list)

- [ ] **Step 1: Add update state to PetViewModel**

In `pet/ClaudePet/Sources/CollectionView.swift`, add to `PetViewModel` class (after the `isHudEnabled` property, around line 22):

```swift
    @Published var updateStatus: UpdateStatus = .idle
```

Add a method after `toggleHud()`:

```swift
    func checkForUpdates() {
        updateStatus = .checking
        UpdateChecker.check { [weak self] status in
            self?.updateStatus = status
            if case .upToDate = status {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self?.updateStatus = .idle
                }
            }
        }
    }

    func openReleasePage() {
        if let url = URL(string: UpdateChecker.releasePageURL) {
            NSWorkspace.shared.open(url)
        }
    }
```

- [ ] **Step 2: Add update button to footerSection**

In `CollectionView.swift`, replace the `footerSection` computed property (lines 264-292) with:

```swift
    // MARK: - Footer
    private var footerSection: some View {
        VStack(spacing: 6) {
            HStack {
                Text("HUD")
                    .font(.system(size: 11, weight: .medium))
                Spacer()
                Button(action: { viewModel.toggleHud() }) {
                    Text(viewModel.isHudEnabled ? "ON" : "OFF")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(viewModel.isHudEnabled ? .green : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(viewModel.isHudEnabled ? Color.green.opacity(0.15) : Color.secondary.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
            }
            updateButton
            Button("Quit Claude Pet") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var updateButton: some View {
        Button(action: {
            if case .available = viewModel.updateStatus {
                viewModel.openReleasePage()
            } else {
                viewModel.checkForUpdates()
            }
        }) {
            HStack {
                switch viewModel.updateStatus {
                case .idle:
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 10))
                    Text("Check for Updates")
                case .checking:
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 12, height: 12)
                    Text("Checking...")
                case .upToDate(let version):
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                    Text("Up to date (v\(version))")
                case .available(let version):
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.cyan)
                    Text("Update Available: \(version)")
                case .failed:
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    Text("Check failed")
                }
                Spacer()
            }
            .font(.system(size: 11))
            .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
    }
```

- [ ] **Step 3: Update install.sh compile list**

In `pet/install.sh`, add `Sources/UpdateChecker.swift \` to the `swiftc` command, after `Sources/StatusMenuController.swift \` (line 53):

```bash
  Sources/UpdateChecker.swift \
```

- [ ] **Step 4: Update popover height in StatusMenuController**

In `pet/ClaudePet/Sources/StatusMenuController.swift`, change `height: 440` to `height: 470` to accommodate the new button:

```swift
        popover.contentSize = NSSize(width: 280, height: 470)
```

- [ ] **Step 5: Verify full app compiles**

```bash
cd /Users/hoyana/Desktop/01_sideproject/claude-hud
./pet/install.sh
```

Expected: App builds and installs. Click the menu bar icon and verify the "Check for Updates" button is visible in the footer.

- [ ] **Step 6: Commit**

```bash
git add pet/ClaudePet/Sources/CollectionView.swift pet/ClaudePet/Sources/UpdateChecker.swift pet/install.sh pet/ClaudePet/Sources/StatusMenuController.swift
git commit -m "feat: add Check for Updates button to popover"
```

---

## Task 5: Write Bilingual README

**Files:**
- Modify: `README.md` (rewrite as Korean)
- Create: `README_EN.md` (English version)

- [ ] **Step 1: Rewrite README.md in Korean**

Overwrite `README.md` with Korean content. Include:
- Language toggle link at top: `[English](README_EN.md)`
- Project title with capybara emoji concept
- Feature highlights (HUD + Pet)
- Installation section (DMG download from Releases + manual install)
- Pet collection table (12 pets)
- Update section
- Requirements
- License

The README should reference the DMG download from GitHub Releases:

```markdown
<p align="center">
  <img src="docs/assets/icon-preview.png" width="128" alt="Claude Pet" />
</p>

<h1 align="center">Claude HUD</h1>

<p align="center">
  <strong>Claude Code를 위한 상태 표시줄 + 메뉴바 펫</strong><br/>
  Rate Limit · 세션 시간 · 컨텍스트 사용량 · 도구 호출 · 에이전트 · 모델 정보
</p>

<p align="center">
  <a href="README_EN.md">English</a> · 한국어
</p>

<p align="center">
  <a href="https://github.com/Hoya324/claude-hud/releases/latest"><img src="https://img.shields.io/badge/download-DMG-blue?style=for-the-badge" alt="Download DMG" /></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey?style=flat-square" alt="macOS" />
  <img src="https://img.shields.io/badge/node-%3E%3D18-green?style=flat-square" alt="Node >= 18" />
  <img src="https://img.shields.io/github/license/Hoya324/claude-hud?style=flat-square" alt="License" />
</p>

---

## 미리보기

```
[HUD] | 5h:14%(3h51m) | wk:62%(3d5h) | session:29m | ctx:39% | 🔧53 | agents:2 | opus-4-6
```

## 설치

### DMG 다운로드 (권장)

[최신 릴리즈](https://github.com/Hoya324/claude-hud/releases/latest)에서 DMG 파일을 다운로드하고, `ClaudePet.app`을 Applications 폴더로 드래그하세요.

### 수동 설치

```bash
git clone https://github.com/Hoya324/claude-hud.git ~/.claude-hud
~/.claude-hud/install.sh          # HUD 상태 표시줄
~/.claude-hud/pet/install.sh      # Claude Pet 메뉴바 앱
```

Claude Code를 **재시작**하세요.

## HUD 상태 표시줄

| 항목 | 설명 | 색상 |
|------|------|------|
| `5h:14%` | 5시간 Rate Limit 사용량 | 초록 < 70% < 노랑 < 90% < 빨강 |
| `wk:62%` | 주간 Rate Limit 사용량 | 동일 |
| `session:29m` | 현재 세션 지속 시간 | 초록 < 30분 < 노랑 < 60분 < 빨강 |
| `ctx:39%` | 컨텍스트 윈도우 사용량 | 초록 < 70% < 노랑 < 85% < 빨강 |
| `🔧53` | 세션 내 도구 호출 횟수 | — |
| `agents:2` | 현재 실행 중인 에이전트 | 시안 |
| `opus-4-6` | 활성 모델 | 흐리게 |

## Claude Pet — 메뉴바 동반자

타마고치 스타일의 픽셀아트 펫이 메뉴바에 살며, Claude Code 활동에 반응합니다.

### 펫 상태

| 상태 | 조건 | 행동 |
|------|------|------|
| 수면 | 활성 세션 없음 | Zzz와 함께 웅크림 |
| 걷기 | 일반 사용 | 행복한 걷기 |
| 달리기 | 도구 50회 이상 | 빠른 달리기 |
| 뚱뚱 | 컨텍스트 >= 70% | 부풀어 오른 몸 |
| 스트레스 | Rate Limit >= 80% | "!"와 함께 떨림 |
| 피곤 | 세션 > 45분 | 축 처진 눈 |
| 협업 | 에이전트 2개 이상 | 팀 걷기 |

### 근육 단계

| 단계 | 조건 | 효과 |
|------|------|------|
| 일반 | 에이전트 0-1 | 표준 크기 |
| 버프 | 에이전트 2-3 | 넓은 어깨, 근육 |
| 마초 | 에이전트 4+ | 거대한 몸, 작은 머리, 금빛 반짝임 |

### 펫 컬렉션 (12종)

| 펫 | 언락 조건 |
|----|-----------|
| 고양이 | 기본 펫 |
| 햄스터 | 총 10회 세션 |
| 병아리 | 총 5시간 사용 |
| 펭귄 | 500K 토큰 사용 |
| 여우 | 에이전트 50회 실행 |
| 토끼 | 동시 3개 이상 세션 |
| 거위 | 총 30시간 사용 |
| 카피바라 | Rate Limit 10회 도달 |
| 나무늘보 | 긴 세션(45분+) 20회 |
| 올빼미 | Opus 모델 10시간 |
| 드래곤 | 동시 5개 이상 에이전트 |
| 유니콘 | 모든 펫 언락 |

### 업데이트

앱 팝오버의 **Check for Updates** 버튼으로 최신 버전을 확인할 수 있습니다.

## 요구사항

- **macOS 13.0+**
- **Node.js >= 18** (HUD 및 aggregator)
- **Claude Code** OAuth 로그인

## 제거

```bash
~/.claude-hud/pet/install.sh remove   # Pet 제거
~/.claude-hud/install.sh remove        # HUD 제거
rm -rf ~/.claude-hud
```

## 라이선스

MIT
```

- [ ] **Step 2: Create README_EN.md**

Create `README_EN.md` with the English version. Same structure as above but in English. Language toggle at top: `English · [한국어](README.md)`.

Use the same content structure but translated:
- "A lightweight status line + menu bar pet for Claude Code"
- Installation via DMG download
- HUD table
- Pet states / muscles / collection tables
- Update section
- Requirements / License

- [ ] **Step 3: Commit**

```bash
git add README.md README_EN.md
git commit -m "docs: rewrite README as bilingual Korean/English"
```

---

## Task 6: Docs Site — CSS & i18n Infrastructure

**Files:**
- Create: `docs/style.css`
- Create: `docs/i18n.js`

- [ ] **Step 1: Create minimal white theme CSS**

Create `docs/style.css` — a clean white theme with cyan accent. Should include:
- Google Fonts: Inter (body), Space Grotesk (headings), Space Mono (code)
- CSS variables for colors: `--bg: #FFFFFF`, `--text: #1a1a1a`, `--accent: #06B6D4`, `--border: #e5e7eb`, `--code-bg: #f8f9fa`, `--muted: #6b7280`
- Fixed navbar with glassmorphism (white backdrop-filter blur)
- Hero section with gradient text using accent color
- Feature cards, tables, code blocks
- Responsive sidebar for docs page (260px fixed, hidden on mobile)
- Language switcher dropdown in navbar
- Smooth scroll, scroll-spy active link highlighting
- Sections: `.hero`, `.features`, `.feature-card`, `.pet-grid`, `.sidebar`, `.doc-content`
- Total approx 800-1000 lines

Key styling decisions:
- Border-radius: 8px (softer than oh-my-harness's 2-4px)
- Borders: solid (not dashed) — `1px solid var(--border)`
- Box shadows instead of outlines for cards
- White background with very subtle gray (#fafafa) for alternating sections

- [ ] **Step 2: Create i18n.js**

Create `docs/i18n.js` with:
- `translations` object with `en` and `ko` keys
- `applyTranslations()` function that finds all `[data-i18n]` and `[data-i18n-html]` elements
- Language switcher logic: reads from / writes to `localStorage('claude-pet-lang')`
- Auto-detect browser language on first visit
- Cover all text content for both index.html and docs.html

Structure:

```javascript
const translations = {
  en: {
    // Navbar
    'nav.docs': 'Docs',
    'nav.features': 'Features',
    'nav.collection': 'Collection',
    'nav.github': 'GitHub',
    // Hero
    'hero.title': 'Claude HUD',
    'hero.subtitle': 'A lightweight status line + menu bar pet for Claude Code',
    'hero.cta': 'Download DMG',
    'hero.docs': 'Read Docs',
    // ... all other translations
  },
  ko: {
    'nav.docs': '문서',
    'nav.features': '기능',
    'nav.collection': '컬렉션',
    'nav.github': 'GitHub',
    'hero.title': 'Claude HUD',
    'hero.subtitle': 'Claude Code를 위한 상태 표시줄 + 메뉴바 펫',
    'hero.cta': 'DMG 다운로드',
    'hero.docs': '문서 보기',
    // ... all other translations
  }
};

let currentLang = localStorage.getItem('claude-pet-lang') || (navigator.language.startsWith('ko') ? 'ko' : 'en');

function applyTranslations() {
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (translations[currentLang][key]) el.textContent = translations[currentLang][key];
  });
  document.querySelectorAll('[data-i18n-html]').forEach(el => {
    const key = el.getAttribute('data-i18n-html');
    if (translations[currentLang][key]) el.innerHTML = translations[currentLang][key];
  });
}

function setLang(lang) {
  currentLang = lang;
  localStorage.setItem('claude-pet-lang', lang);
  applyTranslations();
  document.querySelectorAll('.lang-option').forEach(el => {
    el.classList.toggle('active', el.dataset.lang === lang);
  });
}

document.addEventListener('DOMContentLoaded', () => {
  applyTranslations();
});
```

- [ ] **Step 3: Remove old docs/assets/ directory**

```bash
rm -rf docs/assets/
```

(The new `docs/style.css` replaces `docs/assets/style.css`.)

- [ ] **Step 4: Commit**

```bash
git add docs/style.css docs/i18n.js
git rm -r docs/assets/ 2>/dev/null || true
git commit -m "feat: add docs site CSS (white theme) and i18n system"
```

---

## Task 7: Docs Site — Landing Page

**Files:**
- Modify: `docs/index.html` (complete rewrite)

- [ ] **Step 1: Rewrite index.html**

Rewrite `docs/index.html` as the landing page. Structure (referencing oh-my-harness layout):

1. **Fixed navbar**: logo (left), nav links (Docs, Features, GitHub), language switcher (right)
2. **Hero section**: capybara icon canvas, "Claude HUD" title (gradient text), subtitle, DMG download CTA button + "Read Docs" button, stats row (12 Pets, 7 States, 3 Muscles, HUD)
3. **Features section**: 3-column grid of feature cards:
   - HUD Status Line (rate limits, session, context)
   - Pet System (12 pets, muscle stages, emotions)
   - Auto Updates (GitHub Releases, check for updates)
4. **Pet Collection preview**: 4x3 grid showing all 12 pet names with canvas pixel art (reuse the pixel rendering from the brainstorm)
5. **Installation section**: 3-step cards (Download DMG → Drag to Applications → Launch)
6. **Footer**: GitHub link, license, "Hoya324"

All text elements use `data-i18n` attributes for i18n.

Include the capybara pixel art as an inline canvas rendered via JS (same pixel data as the icon generator).

- [ ] **Step 2: Verify page renders**

```bash
open docs/index.html
```

Expected: Page renders in browser with white theme, all sections visible, language switcher works.

- [ ] **Step 3: Commit**

```bash
git add docs/index.html
git commit -m "feat: add docs landing page with white theme"
```

---

## Task 8: Docs Site — Documentation Page

**Files:**
- Create: `docs/docs.html`

- [ ] **Step 1: Create docs.html**

Create `docs/docs.html` — single-page documentation with left sidebar. Structure:

**Sidebar (260px fixed):**
- Header: "Claude HUD" + version
- Collapsible sections:
  1. Getting Started: Installation, Quick Start
  2. Features: Pet System, Muscle Stages, HUD Status Line
  3. Pet Collection: full table
  4. Configuration: HUD settings, Pet selection
  5. Update: DMG download, Check for Updates

**Main content (all sections on one page with anchor IDs):**

1. `#installation` — DMG download + manual install instructions
2. `#quick-start` — 3-step getting started
3. `#pet-system` — How the pet system works, emotional states table
4. `#muscle-stages` — Normal/Buff/Macho table
5. `#hud` — HUD segments table, color coding
6. `#pet-collection` — Full 12-pet table with unlock conditions
7. `#configuration` — HUD toggle, pet selection
8. `#update` — How updates work, DMG download, Check for Updates button

Include scroll-spy script at bottom to highlight active sidebar link.

All text elements use `data-i18n` or `data-i18n-html` attributes.

- [ ] **Step 2: Update i18n.js with docs page translations**

Add all `docs.*` translation keys to `docs/i18n.js` for the new documentation content.

- [ ] **Step 3: Verify page renders**

```bash
open docs/docs.html
```

Expected: Sidebar navigation works, anchor links scroll to sections, language switcher toggles between Korean/English.

- [ ] **Step 4: Commit**

```bash
git add docs/docs.html docs/i18n.js
git commit -m "feat: add docs page with sidebar navigation and i18n"
```

---

## Task 9: Generate Icon Preview for Docs

**Files:**
- Create: `docs/assets/icon-preview.png` (generated)

- [ ] **Step 1: Generate a 256x256 PNG preview of the capybara icon**

Use the icon generator to produce a preview PNG for the README and docs:

```bash
mkdir -p docs/assets
# Extract the 256x256 from the iconset, or re-generate
swiftc -o /tmp/generate-icon scripts/generate-icon.swift -framework Cocoa && /tmp/generate-icon
cp pet/ClaudePet/AppIcon.iconset/icon_256x256.png docs/assets/icon-preview.png
iconutil -c icns pet/ClaudePet/AppIcon.iconset -o pet/ClaudePet/AppIcon.icns
rm -rf pet/ClaudePet/AppIcon.iconset /tmp/generate-icon
```

- [ ] **Step 2: Commit**

```bash
git add docs/assets/icon-preview.png
git commit -m "docs: add capybara icon preview image"
```

---

## Task 10: Final Verification & Cleanup

- [ ] **Step 1: Full build test**

```bash
cd /Users/hoyana/Desktop/01_sideproject/claude-hud
scripts/build-dmg.sh
```

Expected: DMG builds successfully with icon.

- [ ] **Step 2: Verify docs site locally**

```bash
cd docs && python3 -m http.server 8080
# Open http://localhost:8080
```

Expected: Landing page and docs page render correctly. i18n language switching works.

- [ ] **Step 3: Verify all new/modified files are committed**

```bash
git status
git log --oneline -10
```

Expected: Clean working tree, all tasks committed.
