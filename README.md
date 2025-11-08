Auto Clicker by kmDEV
================================

A lightweight macOS auto‑clicker built with SwiftUI. This fork focuses on a crisp “Liquid Glass” UI, keyboard‑driven workflow, and a simple overlay picker for capturing screen coordinates.

- macOS 13+
- SwiftUI + AppKit interop
- Zero third‑party dependencies

Features
--------

- Glass UI that blends with translucent macOS windows
- Add points via a full‑screen overlay picker
- Optional starting point (runs once before the first loop)
- Infinite or fixed loops with fractional delays
- Keyboard shortcuts for power‑users (fully configurable)
- Live status with Pause/Resume and Stop

Default Hotkeys
---------------

- Start / Pause: Enter
- Stop: Delete (Backspace)
- Add Point: = (also accepts +)
- Clear Points: x

You can customize these in the app: Settings tab → Hotkeys.

Building
--------

1. Open `AutoClicker.xcodeproj` in Xcode 15+
2. Select the AutoClicker target and run. The app will request Accessibility permission on first Start.

If you need to re‑prompt: click the Accessibility pill in the top‑right of the window.

Usage
-----

1. Set `Delay (s)` and `Loops (0 = ∞)`.
2. Use “Add Point” to pick one or more target locations.
3. Optionally set a “Starting Point” (runs once before the first loop to activate a window).
4. Press Enter to Start. Use Enter to Pause/Resume, Delete to Stop.

Notes:
- When a text box is focused, click anywhere on the window to dismiss focus so hotkeys work.
- “Add Point” accepts + or =. The Settings screen lets you change keys.

Settings → Hotkeys
------------------

- Start / Pause
- Stop
- Add Point
- Clear Points

Click “Record” then press a single key. “Reset” restores the default. The Add Point key accepts + (Shift + =) automatically when you set it to `=`.

Code Structure
--------------

- `AutoClicker/RootView.swift` — Main UI. Glass sections for Controls, Starting Point, Points, and a footer. Includes a glass tab bar for Clicks and Settings.
- `AutoClicker/Hotkeys.swift` — HotkeySettings model, mapping helpers, and HotkeysSettingsView.
- `AutoClicker/AutoClickerApp.swift` — App entry, menu commands wired to the model and hotkeys.
- `AutoClicker/ClickerModel.swift` — Engine that performs the clicks using CGEvent.
- `AutoClicker/OverlayPicker.swift` — Full‑screen overlay to capture coordinates.

Accessibility Permission
------------------------

The app uses the macOS Accessibility API to generate clicks. On first Start you will be prompted to grant permission in System Settings → Privacy & Security → Accessibility. You can re‑check and prompt again by clicking the status pill.

Contributing
------------

- Keep changes focused and consistent with the existing style.
- Prefer small, composable views and clear naming.
- UI polish is welcome—especially glass‑styled primitives.

License
-------

MIT

