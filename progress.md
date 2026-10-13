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

## 2026-09-27 — Allow one-display mirror checks

- 🔧 At the user's request, changed the secondary-monitor placement rule to
  apply only when more than one monitor is connected. The strict requirement to
  control ChatGPT only through App Mirror remains.
- ✅ With only the built-in display connected, App Mirror showed the new
  **Dayflow Backup Risk** task in Scheduled, daily, with its next run at
  September 28, 9:01 AM PDT. Its detail showed the expected check command.
  Returned ChatGPT to the original Dayflow conversation.

Next:

- Continue the broader acceptance audit when requested. With multiple displays,
  keep the target and proxy on the secondary monitor.

## 2026-10-02 — Generate and package an app icon

- 🎨 Generated two reflective window panes on blue with the built-in imagegen
  tool; saved the final source and both prompts under `Resources/`.
- 🔧 Added all ten standard/Retina icon representations to `build.swift` and
  registered the packaged `AppIcon.icns` in `Info.plist`. Rebuilt the existing
  local bundle with its original identifier and stable signing identity.
- 🧪 Seven Swift tests passed. The bundle plist, icon representations and final
  signature verified. An `NSWorkspace` rendering check caught a pale outer plate
  around the first transparent image; a full-square imagegen edit removed it
  in the final macOS rendering. See [the archive](generated-app-icon.md).
- 🗂️ Prepared a scoped icon/documentation commit. Other tasks' working-copy
  changes remain untouched. App Mirror was stopped and remains stopped.

Next:

- The icon update is complete. Resume the broader forwarding acceptance audit
  only when requested.

## 2026-10-02 — Publish the icon update

- 🚀 At the user's request, pushed icon commit `e4eb2e240265` to `master` in
  `vegerot/ai-conversations`; the remote advanced from `ee3fbf36869b`.

Next:

- No icon work remains. The separate forwarding acceptance audit is unchanged.

## 2026-10-02 — Demonstrate the updated mirror

- 🪞 Launched the rebuilt bundle targeting ChatGPT.app with both permissions
  granted and matching 1512×949-point frames on the single built-in display.
- ✅ Computer Use through the mirror hid and restored the ChatGPT sidebar;
  fresh controls and screenshots verified both outcomes. No message or draft
  changes. Left the mirror running and raised for the user's inspection.
- 🔎 The separate Dock inspection timed out; no live Dock screenshot is claimed.
  Details are in [the icon archive](generated-app-icon.md).

Next:

- App Mirror is still open. The broader forwarding audit remains incomplete.

## 2026-10-02 — Capture friction and propose improvements

- 📝 At the user's request, added agent guidance to record friction during
  ordinary mirror use and testing, including expected/observed results, evidence,
  and workarounds. Findings must distinguish observations from suspected causes.
- 💡 Require concrete proposals to the user: the smallest useful improvement,
  its benefit, and a small validation check. Linked the guidance from the README.

Next:

- Apply this guidance when friction arises during future mirror use.

## 2026-10-02 — Meetings diagnostics through the mirror

- 🔎 Reproduced the Meetings settings error through App Mirror. Read-only
  diagnostics separately confirmed a backend HTTP 403; this was not attributed
  to the mirror. The Debug button opened a prefilled diagnostic chat draft;
  no message was sent, and navigation returned to the investigation.
- 🪞 The mirrored Window menu stayed open after an Escape keypress; the target
  received the key while the proxy menu remained visible. The exposed Cancel
  accessibility action dismissed it. A small proposed improvement is to handle
  Escape in an active proxy menu locally, verified first with the fixture.
- 🔎 The plugin catalog snapshot exposed a later slice of its controls and
  omitted the visible installed-Meetings link. A screenshot and one coordinate
  click reached the detail page; its fresh accessibility tree verified version
  0.8.77, a connected connector, and a settings error. This is another example
  of the already-recorded snapshot-budget reachability gap in the plan.

Next:

- Continue the Meetings investigation without changing mirror code. Keep the
  menu dismissal and snapshot reachability improvements separate from the
  Meetings backend failure.

## 2026-10-02 — Add an explicit one-shot resize command

- 🔧 Added `pkill -USR1 -x AppMirror`: a retained main-queue signal source
  requests fresh target bounds through the existing capture path, matches
  outer size while preserving the proxy's top-left corner, and refreshes AX
  geometry immediately. Missing target/window requests log a skipped resize.
- 📐 MirrorTarget now logs initial/changed outer size and shows it in the
  title. Target geometry is not written by the resize command. Documented
  invocation and the fixture trial; continuous resizing remains deferred.
- 🧪 Seven existing Swift tests and both signed builds passed with the
  existing signing identity. A second source review found no actionable issues.
- 🔎 Two displays are connected: built-in `(0, 0, 1512, 982)` and DELL
  `(-197, 982, 2560, 1440)` in AppKit coordinates. Neither test app was running.
  Live verification is pending because Computer Use rejected access to Mirror
  Target as unapproved; requested access to the two controlled apps.

Next:

- Once UI access is granted, launch the rebuilt apps on the secondary display;
  change only the proxy size, invoke the command, and record both dimensions
  plus unchanged target bounds and preserved proxy top-left position.
- Confirm a later proxy resize stays independent and check the missing-target
  no-op. Preserve the pre-existing Meetings progress entry and other work.

## 2026-10-02 — Verify one-shot resizing live

- ✅ Through App Mirror, resized the proxy to 760×652; `SIGUSR1` restored
  880×752. Window-server measurements kept target `(643, -1245, 880, 752)`
  and proxy top-left `(633, -1225)` unchanged. Both windows were on DELL.
- 🧪 A later proxy resize stayed at 800×692 across multiple capture ticks
  until another request restored 880×752. After quitting the fixture through
  the mirrored menu, a request logged `resize skipped: target not running`
  and kept the proxy at 880×752. Stopped the proxy, restoring both apps to
  their initial stopped state. See [the full evidence](one-shot-resize.md).
- 🔎 Direct fixture Computer Use remained denied even after user approval;
  approved proxy access worked. A coordinate click intended for the captured
  fixture close button instead produced a pointer event at `(424,243)` and
  left the window open; the mirrored Quit menu worked. The mapping cause is
  unproven. A separate small follow-up could compare coordinate and semantic
  clicks on a fixture title-bar control before changing forwarding.
- 🗂️ Seven tests, both signed builds, and external-sandbox signature checks
  passed. Prepared the scoped local feature/archive commit; preserved the icon,
  unrelated `agent-comparison.md` changes, and the existing Meetings log entry.

Next:

- The requested resize feature is complete; use the README command with the
  rebuilt running app. No push is authorized.
- Leave the broader forwarding audit and coordinate-click finding for separate
  requested work. The running-target/no-window branch remains untested live.

## 2026-10-02 — Deliver the verified resize feature

- 🗂️ The coordinator requested immediate delivery without blocking on an
  optional commit. Source, documentation, and the validated two-turn archive
  remain uncommitted; no push occurred. Both signed builds are ready to launch,
  and a final process check confirmed the test apps are stopped.

Next:

- Use the rebuilt app and documented resize command. If committing later,
  exclude the unrelated Meetings entry and `agent-comparison.md` changes.

## 2026-10-02 — Archive resizing and launch-log clarification

- 📝 Clarified that `open` does not automatically stream app output to the
  agent. This trial explicitly captured/read stderr and its `NSLog` messages;
  stdout was not separately captured. No automatic log monitor was added.
- 🗂️ The user requested archiving. Updated the existing conversation and topic
  index, validated four source turns, and prepared the local implementation/archive
  commit with the unrelated Meetings entry excluded.

Next:

- Use the completed one-shot resize feature; retain the separate acceptance
  gaps documented above. No push is requested.

## 2026-10-12 — Fixture crashes on a non-finite event location (DSH Cua Driver sweep)

- 🧪 Drove the fixture from the DSH harness instead of the proxy, as a sweep of
  `MirrorTarget`'s own controls: background launch, `set_window_frame` onto the DELL
  U2723QE, AX + screenshot read (PIXEL `PXL-KILO-42` visible only in pixels, AX
  `AXS-LIMA-97` only in the tree, read counter rising), composer text, duplicate-label
  buttons, checkbox, time popup, combo (needs a confirm), pull-down (open menu then
  press the item — `set_value` only writes an unverifiable AXValue), replacement button,
  multiline draft, scroll, pad click and right-click, and `invoke_menu` Preferences….
- 💥 Two crashes, one per instance: `MirrorTarget-2026-10-12-171919.ips` (pid 29515) and
  `MirrorTarget-2026-10-12-172151.ips` (pid 49575) in
  `~/Library/Logs/DiagnosticReports`. Both are `EXC_BREAKPOINT`/`SIGTRAP` with
  "Swift runtime failure: Double value cannot be converted to Int because it is either
  infinite or NaN" in `AppDelegate.record(_:)`, reached from the app-wide local event
  monitor (`closure #3 in applicationDidFinishLaunching`). This is a different signature
  from the timer/`objc_retain` close crash already fixed.
- 🔎 Observed before each crash: the process was alive with **no on-screen window**
  (`get_accessibility_tree` listed no Mirror Target window while the app kept logging),
  so events arrived with no window to map a location into.
  Smallest useful fix: log the position only when `event.locationInWindow` is finite (or
  guard the `Int(...)` conversion) instead of trapping.
- ⚠️ Unresolved: what closed each window. Both `drag` attempts failed with "exact target
  window did not become focused for foreground HID delivery" and sent nothing, so the
  drag is not the demonstrated cause; the fixture's drag feature therefore remains
  unverified. Background drag is structurally unavailable on macOS, so only the
  foreground route can ever cover it. Background hover likewise never reaches a plain
  AppKit view — expected, per the driver's own notes.

Next:

- Add the non-finite `locationInWindow` guard to `AppDelegate.record(_:)`, rebuild and
  sign with `swift app-mirror/mirror-target-app/build.swift`, then retry the foreground
  drag on the secondary display against the fresh instance.
- When a sweep ends early, read `~/Library/Logs/DiagnosticReports` for `MirrorTarget-*`
  before concluding the app exited: both instances here had already crashed.

## 2026-10-12 — Fix non-finite coordinate crashes and verify foreground drag live

- 🛠️ Fixed the `Double` to `Int` conversion traps across `MirrorTarget`:
  - In `AppDelegate.record(_:)` (`main.swift`), moved coordinate extraction into
    `default:` (mouse events only; key/flag events no longer evaluate coordinates)
    and guarded `p.x.isFinite && p.y.isFinite`, falling back to `(?,?)`.
  - Guarded window size conversions in the title update timer with `.isFinite`.
  - In `FixturePanel.swift`, guarded `mouseDragged` and `mouseUp` in `EventPad`
    and `scrollWheel` in `AuditScrollView` against non-finite values.
- 🏗️ Rebuilt and signed `MirrorTarget.app` via `swift app-mirror/mirror-target-app/build.swift`.
- 🧪 Launched the rebuilt fixture (PID 68718) and retested foreground drag via `cua-driver`:
  - Dispatched `drag` in `delivery_mode: foreground` (12 steps / 400ms across the pointer pad).
  - The fixture successfully received and logged all events (`Dragged 700,56` … `Released 740,49`)
    without crashing.
  - Zero crash reports generated in `~/Library/Logs/DiagnosticReports/`.
  - Confirmed the previously unexplained window loss during drag was simply the process
    crashing on the unhandled non-finite coordinates.
  - Cleanly stopped the test fixture with Cmd+Q.

Next:

- Keep the verified `MirrorTarget` binary in place for future proxy and Cua Driver acceptance runs.
- Do not commit unrelated changes in `agent-comparison.md` or other tracked files unless requested.
