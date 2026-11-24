# 🪞 App Mirror

A macOS app that mirrors a target app’s window and forwards input, with ChatGPT and Claude as the current real-app targets.

Formerly ChatGPT Mirror. The app and executable are now `AppMirror`; the bundle ID remains `com.chatgpt-mirror.proxy` to preserve its existing signing and permissions identity. Historical conversations retain the name used at the time.

## Development

Start with [AGENTS.md](AGENTS.md), [the goal](GOAL.md), and [the implementation plan](plan.md).
Read [progress.md](progress.md) from the bottom for the latest checkpoint and next action.
See [TESTING.md](TESTING.md) for build and test commands and [the September 14 review](REVIEW-2026-09-14.md) for acceptance gaps.

When using or testing the mirror, record friction and unexpected behavior and
propose concrete improvements to the user. Follow the
[friction and improvement guidance](AGENTS.md#friction-and-improvement-proposals).

The app icon uses two reflective window panes on a blue background. Its full-square
source artwork is [Resources/AppIcon.png](Resources/AppIcon.png); the
[generation prompt](Resources/AppIcon-prompt.txt) records the built-in imagegen
request. `build.swift` uses macOS `sips` and `iconutil` to generate all standard
and Retina sizes, then includes `AppIcon.icns` in the signed app bundle.

## Resize to the target

With the rebuilt App Mirror running, an agent can match its outer window size
to the target's current outer window size with one command:

```sh
pkill -USR1 -x AppMirror
```

The request runs immediately on the app's main queue and preserves the proxy's
top-left corner. It does not change the target's geometry or enable continuous
resizing. Each invocation reads fresh target bounds and refreshes the proxy's
accessibility geometry. The app logs `MIRROR resize requested` with target/proxy
sizes in points, or `MIRROR resize skipped` if the target window is unavailable.
The command sends a request; inspect the window or log to confirm the result.
Rebuild and relaunch an older App Mirror before using the command: older builds
do not handle this signal.

## Conversations

The conversation notes about this project are in the `ai-conversations` archive, folder `app-mirror/`. This project lived there until 2026-11-24.
