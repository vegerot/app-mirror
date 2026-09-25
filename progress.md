# Progress

Append-only, newest last. [plan.md](plan.md)
holds the plan; [GOAL.md](GOAL.md) holds the scope and principles. Detailed
evidence lives in reviews, testing notes, and linked conversation archives.

## 2026-09-14 — Imported implementation checkpoint

- 📋 Steps 1–7 exist; step 8, the common acceptance audit, is incomplete.
  [The review](REVIEW-2026-09-14.md) records the fixture and real-app outcomes.
- 🔧 September 14 corrections: native menus (`3ac80b2b2817`), physical function
  keys (`4b0b0856a38f`), main-window capture (`00e0f22f7114`), binary modifier
  logs (`1d4cea11af09`), persistent pointer outcomes (`b5afdf323520`), and the
  acceptance/focus checkpoint (`18abf9aed350`).
- 📝 The earlier menu commit `a159cd1d6699` was Luna-authored despite its Astra
  trailer; public history was not rewritten. See the
  [archive correction](claude-proxy-control-and-sizing.md).
- 🧪 Seven unit tests and both signed builds passed. The fixture and much of
  Claude were checked; ChatGPT paste, long-conversation accessibility reach,
  emoji selection, and native-menu keyboard behavior retain documented gaps.
- 🔍 Native Computer Use reached the background fixture while another app
  remained foreground. App Mirror still activates the target and uses global
  pointer input; background forwarding is not implemented.
- 🖥️ Historical placement: secondary DELL frame `(-197, 982, 2560, 1440)` in
  AppKit coordinates, built-in `(0, 0, 1512, 982)`; target AX origin
  `(-150, -1320)`, mirror `(1000, -1320)`. Rediscover geometry before reuse.
  At that archive checkpoint the proxy and fixture were stopped, drafts cleared,
  and Claude's original model, System appearance, and sidebar restored.

Next:

- Compare one-window background input with the current foreground path,
  measuring target result, foreground app, and physical cursor separately.
- Resolve or document paste and accessibility-budget failures, then complete
  the shared acceptance audit. Follow the plan's experiment order.

## 2026-09-14 — Top-level topic, App Mirror rename, and smoke test

- 📁 `c69af47a648b` moved the app, five conversation writeups, and goal into
  a top-level topic and updated indexes, links, and commands; 149 local links,
  seven tests, and both signed builds passed.
- 🪞 `4c125d23962c` renamed the topic to `app-mirror/`, display name to
  **App Mirror**, and executable/Swift targets to `AppMirror`. The bundle ID
  remains `com.chatgpt-mirror.proxy` with the existing signing identity.
  Historical writeup names remain unchanged.
- 🧪 After clearing path-dependent Swift caches, seven tests, both signed
  builds, and 53 relevant local links passed at the renamed location.
- ✅ A live Computer Use smoke test through App Mirror displayed fixture
  pixels and controls, set the draft to `App Mirror smoke test`, and toggled
  the checkbox on and off. The draft was cleared and checkbox restored to 0.
  This was a fixture smoke test, not a new ChatGPT/Claude acceptance audit.
- 🖥️ Both smoke-test windows were on the secondary display. They were left
  running at the end of the test; inspect current processes before relaunching.

Next:

- Resume the background-input experiment from the previous checkpoint when
  implementation work is requested. The rename does not resolve acceptance gaps.

## 2026-09-14 — Adopt the progress convention

- 📚 Adopted Larklish's `docs/plan.md` progress rules from the available local
  checkout at `~/code/github.com/vegerot/larklish`; the requested
  `~/code/code.byted.org/max.coplan/larklish` path was absent on this Mac.
- 📝 Added this log and durable instructions: append dated action summaries
  as work happens, use one emoji per action, end entries with `Next:`, and read
  from the bottom at startup or after compaction. Moved checkpoint details out
  of the goal and plan; linked the log from the README and testing instructions.
- 📐 Renamed `IMPLEMENTATION_PLAN.md` to `plan.md` and updated live links.
  The plan holds settled constraints and intended work; this log holds mutable
  completion, validation, and handoff state.
- 🔗 Checked local Markdown links in the updated App Mirror documentation;
  all resolve. No app code changed.

Next:

- Keep this log updated during future App Mirror work. These documentation
  changes are uncommitted; the last implementation commit is `4c125d23962c`.

## 2026-09-14 — Commit the plan and progress convention

- 📝 User requested committing the documentation changes under
  `docs(app-mirror): adopt plan and progress conventions`. The commit includes
  the plan rename, progress log, agent instructions, and updated links.
- 🔗 All 58 local documentation links passed validation. No app code changed;
  unrelated Obsidian files and `agent-comparison.md` remain outside this commit.

Next:

- Read this log from the bottom and check the working copy before resuming
  the background-input experiment described in [plan.md](plan.md).

## 2026-09-14 — Fix fixture window ownership on close

- 🔧 Set `window.isReleasedWhenClosed = false` in MirrorTarget so Swift owns
  the window lifetime and the title timer does not access an over-released
  window after closing. Kept the fix to one code line.
- 🧪 The fixture release build and signing passed via `swift build.swift`.
  Live close/quit behavior has not been retested. Changes are uncommitted.

Next:

- Verify closing the rebuilt fixture window no longer crashes.
- Resume the existing background-input experiment when requested.

## 2026-09-14 — Verify fixture close and quit live

- 🧪 Restarted the old fixture process (39676) into the rebuilt app (50478).
  Clicked its native close button with Computer Use; the subsequent AX read
  timed out because no window remained. Confirmed the same process was alive
  afterward and Core Graphics reported no on-screen windows for it, well past
  the 0.2-second title timer interval.
- ✅ Sent Command-Q to that process and confirmed it exited. No new MirrorTarget
  crash report appeared in the user or system DiagnosticReports directories;
  checked at 17:57:47 local time. Fixture is now stopped.
- 🖥️ The rebuilt app centered on the primary display. Computer Use title-bar
  drags did not move it to the secondary display; closed it promptly after
  those failed attempts. This was direct fixture testing, not a proxy audit.

Next:

- Commit the ownership fix and validation log when requested.
- Resume the existing background-input experiment when requested.


## 2026-09-14 — Reproduce baseline and restore verified fix

- 🧪 Shelved only the ownership fix and this log as `mirror-window-close-repro`,
  rebuilt the original fixture, and reproduced the exact `objc_retain + 16`
  / timer closure #4 + 304 crash in PID 54796 at 17:58:53 local time.
- ✅ Unshelved the changes, rebuilt and signed, then verified fixed PID 56365
  survived native window closure and checks five seconds apart with no visible
  windows. Command-Q exited it; no crash report for that PID appeared.
- 🗂️ Recorded evidence and turn summaries in
  [the conversation archive](mirror-target-close-crash.md), updated the topic
  index, and prepared the requested scoped commit. The fixed bundle is restored
  and the fixture is stopped. Display placement limitations remain documented.

Next:

- Resume the existing background-input experiment when requested.

## 2026-09-14 — Revisit the original goal and visual-only alternative

- 🔎 User clarified that built-in Computer Use must remain unchanged. Reviewed
  the implementation and earlier simplicity discussion; replacing Computer Use
  with custom tools would not meet that constraint.
- 📐 Current production Swift sources total 1,443 lines, including comments:
  AccessibilityBridge is 558 and MenuBridge is 203. Tree snapshots, identity
  reconstruction, proxy views and refresh scheduling account for much of the
  design's complexity. Removing them remains a proposal, not a verified change.
- 🧠 The original archive's AX-only-token observation does not by itself prove
  that screenshot-and-coordinate operation is impossible. The installed CU
  interface exposes both screenshots and coordinate actions. Claude's own CU
  still requires separate verification; earlier Claude-target tests used Codex.
- 🧪 Built a temporary 58-line pixel-only test window under
  `/tmp/app-mirror-pixel-probe`. It exited before creating a window because
  NSScreen reported fewer than two displays. No visual-input trial completed;
  no production code, built bundle, goal or implementation plan changed.

Next:

- If pursuing this alternative, test screenshot reading, coordinate clicks,
  typing and scrolling under the actual built-in controller, then real-app
  menus and popups. A single captured window can omit native menu surfaces.
- Decide from those outcomes whether to remove tree replication, retain a
  small menu bridge, or keep semantic forwarding. Preserve existing acceptance
  coverage until a smaller implementation proves the required workflows.

## 2026-09-24 — Press transient window menus semantically

- 🔎 The Codex scheduler exposed a `6:00 AM` menu entry through App Mirror,
  but the first mirrored click saved `2:45 AM`. Source inspection found that
  window menu items were pressed through a global pointer click after raising
  the target and resolving the item again. The menu was absent from the mirrored
  window capture, so the click receipt could not establish which item was selected.
  The focus-changing pointer path is a plausible cause, not yet an isolated one.
  A later click used an index after the menu had closed; that was stale-index
  use by the controller, separate from the forwarding problem.
- 🔧 Window `AXMenuItem` nodes that advertise `AXPress` now use that action
  directly, without raising the target or moving the pointer. Added a
  `Fixture time` pop-up with visible and logged selection results.
- 🧪 All seven Swift tests and both signed builds passed. `NSScreen` reported
  only the built-in display, so no live fixture or real-app acceptance was run;
  the user's manually corrected 6 AM automation was not touched. The user agreed
  to defer the live check while only one display is connected.

Next:

- With a secondary display, select `6:00 AM` in `Fixture time` through App
  Mirror and confirm the target result and event log, then repeat with a benign
  real-app menu without changing the user's schedule.

## 2026-09-24 — Verify the window-menu fix live

- 🔎 The first live fixture attempt exposed `6:00 AM`, but two presses logged
  `AXProxy: stale 6:00 AM` and the picker stayed at `2:45 AM`. The main-window
  path lookup could not resolve the transient menu item. The proxy now presses
  the AX element retained by the current snapshot, avoiding that lookup.
- ✅ Through the rebuilt signed proxy, `Fixture time` changed `2:45 → 6:00 →
  2:45 AM`. Both transitions matched the picker value, result label and fixture
  event log. The proxy logged `menu AXPress ... -> success`.
- ✅ Through the same proxy, the real `Rebuild Codex CLI` task changed `6:00 →
  6:15 → 6:00 AM`. The Scheduled view and tracked automation rule matched both
  changes. The final rule is daily at 6:00 AM. Restored the test-only
  `updated_at` change; reopening Scheduled still showed 6:00 AM.
- 🧪 Seven Swift tests and the signed proxy build passed after the code change.
  The fixture build had passed before the live trial. Quit the fixture and
  proxy, and returned ChatGPT to the original task view.

Next:

- Continue the broader ChatGPT and Claude acceptance audit when requested;
  this window-menu selection issue is verified in the fixture and Codex task.
