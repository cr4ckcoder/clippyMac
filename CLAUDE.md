# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

ClippyMac is a native macOS menu bar app that gives Windows-style clipboard
history (like ⊞Win+V). Press **⌘⇧V** to pop up recent clipboard items near the
cursor; clicking one pastes it into the previously active app. Pure Swift +
AppKit/SwiftUI, no external dependencies, built with Swift Package Manager.

## Commands

```bash
swift build              # compile (debug)
swift run                # compile and launch in the foreground (useful for iterating; Ctrl+C to stop)
swift build -c release   # optimized build

./scripts/build-app.sh [debug|release]   # build + package into build/ClippyMac.app, ad-hoc codesigned
open build/ClippyMac.app                 # launch the packaged app
```

There is no test target yet. To sanity-check clipboard capture without
opening the UI, run the packaged app, then `echo "text" | pbcopy` and inspect
`~/Library/Application Support/ClippyMac/history.json` — it should show the
new entry prepended.

When rebuilding the app bundle, kill any previously running instance first
(`pkill ClippyMac`) since macOS won't hot-swap the menu bar item.

## Architecture

Everything lives in `Sources/ClippyMac/`, one file per responsibility, wired
together in `AppDelegate`:

- **`ClipboardManager`** — polls `NSPasteboard.general.changeCount` on a
  0.5s `Timer` (there's no native pasteboard-change notification on macOS).
  Owns the in-memory history (`@Published`, capped at 50 items) and persists
  it as JSON to `~/Library/Application Support/ClippyMac/history.json`. Has
  an `isInternalWrite` guard so that writing a selected item back to the
  pasteboard (to prep it for paste) doesn't get re-captured as a new history
  entry.
- **`HotKeyManager`** — registers the global ⌘⇧V shortcut through the
  **Carbon** Event Manager (`RegisterEventHotKey`), not `NSEvent` global
  monitors. This is deliberate: Carbon hotkeys work without Input
  Monitoring/Accessibility permission, whereas `NSEvent.addGlobalMonitorForEvents`
  would require it. The Carbon callback must be a non-capturing
  `@convention(c)` function (`hotKeyCEventHandler`), so instance dispatch goes
  through a static `registry` dictionary keyed by hotkey ID, resolved via the
  `userData` pointer passed to `InstallEventHandler`.
- **`HistoryPanelController`** — owns a borderless, non-activating `NSPanel`
  (`KeyablePanel`) that hosts the SwiftUI `HistoryView` via `NSHostingView`.
  `KeyablePanel` overrides `canBecomeKey` (normally false for
  `.nonactivatingPanel`) so it can still receive Escape-to-close. The panel
  positions itself near the mouse cursor, clamped to the active screen's
  visible frame, and auto-hides on `didResignKeyNotification`.
- **`PasteSimulator`** — posts a synthetic ⌘V via `CGEvent` into the
  frontmost app. This is the one feature that needs **Accessibility**
  permission (`AXIsProcessTrusted`); if not granted, it triggers the system
  prompt instead of pasting.
- **`StatusBarController`** — the `NSStatusItem` menu bar icon and its menu
  (show history, clear, quit). The app runs with `LSUIElement = true` (set in
  `Resources/Info.plist`), so it has no Dock icon and never becomes the
  active app in the usual sense — `NSApp.setActivationPolicy(.accessory)` is
  set in `AppDelegate.applicationDidFinishLaunching`.

### Selection flow (why the delays exist)

`HistoryPanelController.select(_:onSelect:)` does, in order: hide the panel →
copy the item to the pasteboard → reactivate the previously frontmost app →
wait ~150ms → simulate ⌘V. The delay is necessary because reactivating the
target app is asynchronous; posting the paste keystroke too early can land it
in the wrong (still-transitioning) app.

### Packaging

`swift build` alone produces a bare Mach-O binary, not something macOS
treats as an app (no bundle ID, no permission persistence). `scripts/build-app.sh`
assembles `build/ClippyMac.app` by hand (`Contents/MacOS` + copied
`Resources/Info.plist`) and ad-hoc codesigns it (`codesign --sign -`) so that
Accessibility permission grants survive rebuilds instead of resetting every
time the binary changes. There is no `.xcodeproj`; everything is driven by
`Package.swift`.
