<div align="center">

<img src="assets/icon-1024.png" width="120" alt="Winkle" />

# Winkle

**Rest your eyes, without even thinking about it.**

A free, privacy-first macOS menu bar app that automates the 20-20-20 rule — so you actually stick to it.

<a href="#features">Features</a> •
<a href="#install">Install</a> •
<a href="#privacy-first">Privacy</a> •
<a href="#contributing">Contributing</a>

[![Platform](https://img.shields.io/badge/macOS-13%2B-blue)](https://github.com/julesvbertolino/winkle)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub release](https://img.shields.io/github/release/julesvbertolino/winkle.svg)](https://github.com/julesvbertolino/winkle/releases)

</div>

---

Staring at a screen all day is hard on your eyes. Optometrists recommend the **20-20-20 rule**: every 20 minutes, look at something about 20 feet (6 m) away for 20 seconds. It genuinely works — the problem is nobody remembers to do it.

Winkle does the remembering for you. It lives in your menu bar, quietly tracks your *real* screen time, and gently nudges you to look away at the right moment. Then it gets out of your way. No accounts, no tracking, nothing ever leaves your Mac.

---

## Features

### 👀 It knows when you're actually working

Winkle only counts time when you're really using your keyboard or mouse. Step away for a coffee and it notices your eyes are already resting — the timer quietly resets. No guilt, no breaks you didn't need.

### 🎥 It never interrupts at the wrong moment

On a video call, watching something fullscreen, or in Do Not Disturb? Winkle steps aside automatically. You can also whitelist any app, or suspend it by hand for an hour, two, or until you switch it back on.

### 🫧 A break that feels calm, not naggy

When it's time, a soft periwinkle overlay drifts in with a gentle countdown. A 20-second pre-alert lets you finish your sentence first. Snooze for 5 minutes as often as you like, or skip it entirely — your call. Prefer discipline? Strict mode makes the break unskippable.

### ⚙️ Your rhythm, your rules

Pick a preset — **Balanced** (20 min), **Intense** (15 min) or **Relaxed** (30 min) — or set your own. Overlay, notification, or both. Light or dark. Français or English. Launch at login. All optional, all yours.

---

## Privacy First

Your habits are yours. Winkle is built so none of them ever leave your machine.

- ✅ 100% on-device — no servers, no accounts, no analytics
- ✅ Activity detection reads only *idle time*, never your keystrokes
- ✅ Camera detection reads a status flag, never the video feed
- ✅ Fully open source — read every line right here

Don't take my word for it — check the code yourself.

---

## Install

1. Download the latest `.dmg` from the [Releases page](../../releases/latest).
2. Open it and drag **Winkle** into **Applications**.
3. First launch: **right-click the app → Open** (Winkle is signed but not yet Apple-notarized, so macOS asks for confirmation once).

Winkle then lives in your menu bar — no Dock icon. A short onboarding helps you pick your rhythm.

Requires **macOS 13 or later** · universal (Apple Silicon + Intel).

## Build from source

No dependencies — just clone and run:

```bash
make open   # build and launch Winkle.app (full experience)
make dmg    # build a shareable .dmg
make run    # bare binary for quick dev (no notifications / login item)
```

Swift 5.9+ · SwiftUI · macOS 13+.

<details>
<summary>How the code is organized</summary>

| File | Role |
|---|---|
| `BreakEngine.swift` | The cycle's state machine (active / natural rest / suspended, and the break itself) |
| `ActivityMonitor.swift` | Keyboard & mouse idle time via CGEventSource |
| `SuspensionMonitor.swift` | The "never interrupt" rules: calls, fullscreen, whitelist, Focus |
| `OverlayController.swift` | Per-screen break overlays, fade in/out |
| `Views/` | Overlay, settings, onboarding, shared style |

</details>

---

## Contributing

Feedback, bugs and ideas are very welcome.

**Found a bug?** [Open an issue](../../issues/new) with what happened, what you expected, how to reproduce it, and your macOS version.

**Have an idea?** [Open an issue](../../issues/new) describing the feature and why it'd help.

**Want to code?**

1. Fork the repo
2. Create a branch: `git checkout -b feature/your-feature`
3. Make your change and test it
4. Open a pull request

I'll review PRs as soon as I can — please keep them focused.

---

## License

MIT — fork it, change it, ship it however you want. If Winkle helps your eyes, you can [buy me a coffee ☕](https://buymeacoffee.com/julesbertolino).

See [LICENSE](LICENSE) for details.
