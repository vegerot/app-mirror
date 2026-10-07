---
aliases: [app-mirror]
---

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

[Computer Use engines and a ChatGPT wrapper](computer-use-engines-and-chatgpt-wrapper.md) continues the desktop-automation discussion with installed-helper inspection, public reverse-engineering projects, dated star counts, and local comparisons of iFurySt, Cua, and Peekaboo.
It separates semantic Accessibility actions, process-directed input, and physical cursor movement; no wrapper was built and a supported companion panel remained a proposal, with no GUI reliability tests run.

[ChatGPT Mirror proxy app](chatgpt-mirror-proxy-app.md) then actually builds that proposed mirror, in a later session with a different assistant: a small macOS app (`com.chatgpt-mirror.proxy`) that captures ChatGPT.app's window and forwards clicks/keystrokes into it via `CGEvent.postToPid`.
Forwarding was verified end-to-end with synthetic events, and a stable-identity signing fix stopped per-launch TCC re-prompts; later continuations proved Codex is AX-tree-driven and completed a Codex-owned audit of settings, menus, text editing, popup selection, scrolling, disabled controls, and pointer dragging.
The remaining mismatch is presentation-only but prevents strict direct-control equivalence: after a final self-resize drag, Codex's RPCs and final response complete in the backend while ChatGPT's renderer can remain on a stale tool card.
A later portability probe retargeted the unchanged binary to Claude.app and verified mirrored pixels, AX controls, semantic sidebar activation, and composer value setting; it also showed that transparent ordinary clicks and a target-neutral configuration/adapter boundary are still needed before calling the proxy general-purpose.

[Claude control and shared proxy refactor](claude-proxy-control-and-sizing.md) continues the portability probe with live Computer Use tests and initial outer-window sizing, then removes multi-window experiments and extracts shared target, accessibility, input and menu components.
Its September 14 Astra review corrects Luna's unsupported menu claims, preserves physical function keys, simplifies capture correspondence, and adds binary modifier and persistent outcome logs; seven tests pass, but the combined acceptance audit remains incomplete.
The [handoff plan](plan.md) records clipboard and snapshot-budget gaps and a proposed background-input experiment: native Codex CU operated the fixture without taking foreground focus, while the proxy itself still activates the target and uses global pointer input. All ChatGPT Computer Use remains strictly through the mirror.

[ChatGPT Mirror simplicity review](chatgpt-mirror-simplicity-review.md) revisits the implementation at 847 lines and attributes much of its complexity to maintaining another representation of the UI.
The conversation verified one supported native task-list read and acknowledged that operation-specific interfaces do not satisfy full transparency; no proxy code changed.
Across the wrapper proposal, implementation, and review, a successful operation proves only that operation, and an alternative with narrower coverage must not be presented as an equivalent replacement.

[ChatGPT Mirror focus transfer](chatgpt-mirror-focus-transfer.md) follows the review with a source-grounded explanation for the acceptance audit's visible focus change.
Computer Use addresses the mirror's republished accessibility tree, but the forwarding layer deliberately activates and raises the target before injecting HID pointer, keyboard, and scroll events, then never restores mirror focus.
This makes the target controllable but leaves the proxy not focus-transparent; the documented shared acceptance audit remains pending rather than being an automated test suite.

[MirrorTarget window-close crash](mirror-target-close-crash.md) follows the smoke test with a one-line window ownership fix.
Shelving and rebuilding reproduced the exact timer crash; restoring the fix kept the process alive after closure and allowed Quit to exit without a new crash report. Together with the earlier acceptance corrections, this demonstrates why controlled before/after behavior matters more than a successful build alone.

[Generated App Mirror icon](generated-app-icon.md) adds a two-window design and
reproducible icon packaging. Inspecting the macOS-rendered icon exposed a pale
outer plate around the first transparent design; full-square artwork fixed the
actual app appearance while preserving signing and forwarding behavior.
A follow-up adds guidance to record friction during mirror use and propose improvements.

[One-shot proxy resize](one-shot-resize.md) adds an agent-invokable `SIGUSR1`
command using the existing sizing path. Live fixture measurements verify matching
outer dimensions, unchanged target bounds, preserved proxy position, and no
continuous synchronization; the icon and broader forwarding audit are unchanged.
The follow-up clarifies that launching the app does not automatically expose
its output: this test explicitly captured and read stderr, not stdout.

[MirrorTarget feature experiment](mirror-target-feature-experiment.md) exercises
the native fixture directly through Computer Use, covering its menus, controls,
text entry, scrolling, and pointer events. It found that a stale accessibility
element ID needed a state refresh, a context-menu choice needed Return to run,
and reported scroll position did not always match visible movement; Quit remained
untested. This complements the proxy audits by recording concrete fixture
behavior and keeping tool limitations distinct from app behavior.

## 🗃️ Live table

Renders in Obsidian.

![[topic.base]]
