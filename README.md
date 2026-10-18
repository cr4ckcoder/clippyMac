# ClippyMac

A free, open-source clipboard history app for macOS. Press **⌘⇧V** anywhere to
pick from things you recently copied, the same idea as Windows' **Win+V**.

ClippyMac lives in the menu bar, stays out of the Dock, and keeps history on
your Mac only.

## Download

Grab the latest build from
[Releases](https://github.com/cr4ckcoder/clippyMac/releases/latest):

1. Download `ClippyMac-1.0.0.zip` and unzip it.
2. Move `ClippyMac.app` to `/Applications`.
3. Open it once with **Right-click → Open** (the app is ad-hoc signed, so
   Gatekeeper will warn on first launch).
4. When you paste from history the first time, grant **Accessibility** access
   so ClippyMac can send ⌘V into the app you were using:
   **System Settings → Privacy & Security → Accessibility**.

Requires **macOS 13 Ventura** or later. The prebuilt zip is **Apple Silicon**
(M1 and later). Intel Macs can build from source.

## Features

- Global **⌘⇧V** popup near the cursor
- Last **50** clipboard items (text and images)
- **Pin** items so they stay at the top
- Menu bar icon with show / clear / quit
- History saved locally at
  `~/Library/Application Support/ClippyMac/history.json`
- Native Swift + AppKit/SwiftUI, no third-party dependencies

## Usage

1. Copy text or an image as usual.
2. Press **⌘⇧V** (or click the menu bar icon → **Show History**).
3. Click an item to paste it into the app you were just using.
4. Hover an item and click the pin to keep it.

Clearing history removes recent items only. Pinned items stay.

## Privacy

Clipboard contents never leave your Mac. There is no network access, no
analytics, and no account.

## Build from source

You need Xcode Command Line Tools (Swift 5.9+).

```bash
git clone https://github.com/cr4ckcoder/clippyMac.git
cd clippyMac
./scripts/build-app.sh release
open build/ClippyMac.app
```

Development loop:

```bash
swift build
swift run
```

Kill a running instance before rebuilding (`pkill ClippyMac`). macOS will not
hot-swap the menu bar item.

## How it works

- `ClipboardManager` polls `NSPasteboard.general` every 0.5s and keeps the
  last 50 items.
- `HotKeyManager` registers ⌘⇧V through the Carbon Event Manager, so the
  shortcut works without Accessibility permission.
- `HistoryPanelController` shows a floating panel near the cursor.
- Selecting an item writes it back to the pasteboard, reactivates the previous
  app, then `PasteSimulator` posts a synthetic ⌘V (this step needs
  Accessibility).

## License

[MIT](LICENSE)
