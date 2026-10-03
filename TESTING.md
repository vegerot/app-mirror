# Shared mirror testing

Checkpoint: **2026-10-02**. Seven automated tests and both signed builds pass.
The common real-app acceptance audit is incomplete. Read [progress.md](progress.md) from the bottom for the current next experiment
and [the review](REVIEW-2026-09-14.md) for the September 14 evidence.

## Build and launch

From the repository root, run sequentially:

```sh
swift test --package-path app-mirror
swift app-mirror/build.swift
swift app-mirror/mirror-target-app/build.swift
```

The existing CGWindowListCreateImage deprecation remains; capture replacement
is deferred. Preserve the signing identity
`Apple Development: ssjvegerot@icloud.com (MV276V5B7J)`.

Quit the existing proxy before choosing a different target. Launch its signed
bundle, not its executable; executable launch previously reported AX denied.

```sh
open --new \
  --env MIRROR_TARGET_BUNDLE_ID=com.anthropic.claudefordesktop \
  --stderr /tmp/claude-mirror-test.log \
  app-mirror/AppMirror.app
```

Use `com.openai.codex` for ChatGPT (also the existing default).
For the fixture:

```sh
open --new --stderr /tmp/fixture-test.log \
  app-mirror/mirror-target-app/MirrorTarget.app
open --new \
  --env MIRROR_TARGET_BUNDLE_ID=com.mirror-target.testapp \
  --stderr /tmp/fixture-mirror-test.log \
  app-mirror/AppMirror.app
```

Pass `--env PROBE_UNTITLED=1` to the fixture launch to test its untitled window.
It reports that mode in the visible log. When more than one monitor is
connected, put target and mirror on the secondary monitor after launch,
checking current display geometry first.

### One-shot resize

Use the rebuilt running proxy; older builds do not handle `SIGUSR1`.
The fixture displays its outer size in its title and logs initial/changed sizes.
Keep the fixture's geometry fixed for this check:

1. Record the target and proxy bounds, then resize only the proxy to a different
   size. Wait through several capture ticks and confirm the mismatch remains.
2. Run `pkill -USR1 -x AppMirror`. Confirm the proxy's outer width and height
   match the target, its top-left corner stays fixed, and the target bounds
   remain unchanged. The proxy log reports both sizes under `MIRROR resize requested`.
3. Resize the proxy again and confirm it stays mismatched until another request.
   This distinguishes a one-shot request from continuous synchronization.
4. With no target window, a request must log `MIRROR resize skipped` without
   changing the proxy size or using stale target bounds.

The [October 2 trial](one-shot-resize.md) verified 760×652 → 880×752, unchanged
target bounds, preserved proxy top-left position, a later independent resize,
and a skipped request after the fixture quit. The separate running-target/no-window
branch was not exercised.

For real-app acceptance use only:

```js
let app = await cua.getApp('com.chatgpt-mirror.proxy');
await app.getAXState();
```

**Never target `com.openai.codex` directly with Computer Use, including debugging.**
Direct Claude/fixture diagnosis must be recorded separately. Use fresh indices,
confirm the target in the mirror title, and restore state without sending messages.

## Focus and observation

The current proxy activates and raises its target and posts pointer/scroll events
to global HID. Keyboard forwarding also activates the target. A secondary
display separates windows but does not isolate input; concurrent user activity
can invalidate a trial. Native Codex CU itself supports background input on macOS,
as verified directly against the fixture. Background forwarding is not yet
implemented in this proxy.

A successful AX return or input-post call is not the test's result. Inspect
target text, selection, state or persistent fixture logs. The target can finish
after the immediate snapshot; periodic refresh and the delayed action refresh
can expose the result later. Do not press a second time just because the first
snapshot still shows the old state. Hover can overwrite the pad's current label;
non-hover outcomes now also remain in the event log.

## Fixture matrix

| Area | Current evidence |
| --- | --- |
| Identity | Both Same label buttons report their own parent group; delayed Replacement resolves to version 1. |
| Capabilities | Disabled action stays disabled; Read-only field is not writable; text inputs expose supported setters. |
| Checkbox | Toggle state changes and restores. |
| Scroll | Left and Right regions move independently and restore to rows 0–6. |
| Pointer | Middle button 2, double-click count 2, down/drag/up order, release coordinates and context action verified through the mirror. |
| Hover | Pad displays hover, but dedicated hover-only generation is unavailable in this CU interface; no isolated CU pass claimed. |
| Keyboard | Left retains physical code 123/down/up; Shift-Left replacement works; standard Edit menu provides Select All/Paste. |
| Unicode | Multiline paste, selection of an emoji, ASCII replacement and clearing pass in the fixture. CU Unicode typeText produced no text even directly against the fixture in the diagnostic trial. |
| Repeat | Event metadata is preserved by a unit test; the existing low-level probe did not establish synthetic repeat delivery to the mirror. |
| Menus | Disabled/enabled Count, dynamic titles, one invocation per click/closed-menu shortcut, nested action, AX Cancel and post-menu typing pass. |
| Window pop-up | `Fixture time` changed 2:45 → 6:00 → 2:45 AM through the mirror; the picker value, visible result and event log agreed. The first build failed with `AXProxy: stale 6:00 AM`; pressing the captured menu item directly fixed it. |
| Open-menu keyboard | Previous pass claim withdrawn: Down/Return/Escape do not reliably operate CU AX-opened menus even on the native fixture. Synthetic navigation was removed. |
| Capture/lifecycle | Untitled window pixels and controls work; exiting target removes stale controls; outer frames initially match at 880×752. |

Modifier fields display `mods=0b…` for keyboard, flags changes and pointer input.
The visible log retains recent events; stderr can provide the longer sequence.

Seven tests in `Tests/AppMirrorTests/ForwardingTests.swift` cover:
coordinate mapping, pointer fields/order, key release/repeat metadata, native
menu modifiers, menu lifecycle/reset, physical function-key versus text
classification, and capture correspondence without a title/arbitrary fallback.
They do not substitute for visible end-to-end tests.

`Tests/held-key.swift` sends low-level input only to the proxy for sequences
CU cannot generate. Its previous Shift/down/up/Shift-release observation and
unverified repeat are injection-probe evidence, not CU acceptance.

## Real-app matrix at archive

Versions: ChatGPT **26.903.71938**, Claude **1.52386.3**.

| Area | ChatGPT through mirror | Claude through mirror |
| --- | --- | --- |
| Initial sizing | 1237×824 target and proxy. | 939×729 target and proxy. |
| Native menu | Sidebar toggle verified; disabled menu entries exposed. | Hide/Show Sidebar action and refreshed title verified. |
| Ordinary draft editing | Set `alpha beta`, select/replace → `alpha gamma`, clear. | Same sequence passed. |
| Unicode multiline paste | Failed trial: timeout followed by restored clipboard text; cleared without sending. Isolated repeat not completed. | Exact `Unicode 世界 🌍\nPaste audit` received. |
| Emoji replacement | Pending. | Removed a following newline; a direct diagnostic was also wrong but differed, so cause remains unresolved. |
| Popup | Scheduled task Time changed 6:00 → 6:15 → 6:00 AM through the mirror; the Scheduled view and saved TOML agreed at each step. | Model popup opened/cancelled, model unchanged. |
| Settings | Pending on final build. | Shortcut opens; search set/clear; Light/System appearance changes and restores. |
| Scrolling | Pending on final build. | Lower General settings reached; top restored. |
| Gestures | Pending on final build. | Sidebar drag 288 → 331 → 288. |
| Snapshot limits | Long active-conversation composer absent; new-chat composer reachable. | Important tested controls reachable. |

No test message was sent. Claude was restored to home with empty draft, original
model, System appearance and original sidebar width. ChatGPT's test draft was
cleared; user steering subsequently changed its selected page. The proxy and
fixture are stopped for the archive.

## Open issues and next validation

- Compare targeted background delivery with the current global path, using one
  window and logging foreground app/cursor independently from the target result.
- Reproduce the ChatGPT clipboard handoff under controlled input. A timeout can
  follow either successful paste or wrong clipboard content; inspect before
  retrying. The current delays do not establish reliability, and earlier
  pasteboard snapshot/rewrite experiments caused CU conflict errors.
- Add a long-content fixture before addressing snapshot-budget reachability.
- Resolve or accurately delimit emoji selection, native-menu keyboard control,
  hover-only CU and synthetic repeat behavior.
- Finish the same applicable matrix on both real apps after any forwarding
  changes. No app-specific press exception is currently justified or installed.
