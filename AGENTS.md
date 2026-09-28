# Agent instructions — shared mirror proxy

Read [the goal](GOAL.md) before working here and after
compaction, then [plan.md](plan.md) for the plan
and [progress.md](progress.md) from the bottom for the current checkpoint.
Check `sl status` and `sl diff --stat` against the latest entry before continuing.

- Never use Computer Use directly on `com.openai.codex`, including debugging.
  Use `com.chatgpt-mirror.proxy`. Direct Claude diagnosis is allowed; final tests
  of both real apps must operate through the mirror.
- When more than one monitor is connected, keep every controlled window on the
  secondary monitor: target and proxy. Check placement again after launching.
  Do not interfere with the user's other work.
- One target window; no multi-window ranking, selection, or switching.
- Prefer shared behavior. App-specific exceptions need a recorded failure and
  a reason the shared solution is substantially more complicated.
- Every new feature must be supported by the test app and logged/displayed.
  Choose fixture-first or real-app-first experiments based on what needs proving.
- Keep things simple. Never automatically retry a press after a visual no-op.
  Verify outcomes and restore state; do not send test messages.
- Keep initial connection sizing, periodic AX refresh, stable signing identity,
  bundle ID, and the existing target environment variable/default. Defer
  continuous resizing, capture replacement, file pickers and refresh optimization.
- Build and run relevant checks for each logical commit. Use Sapling and explicit
  paths; do not commit unrelated work or push without a request.

## Progress convention

- Keep [progress.md](progress.md) short, append-only, and continuation-ready;
  newest entries go last. Any engineer should be able to read the plan and log
  and understand what is done and what remains.
- Summarize code changes, experiments, commits, and findings as work happens,
  including mid-task handoffs. Use dated entries and one emoji per action.
- End every entry with a `Next:` block containing concrete next steps.
- Put mutable state (commit hashes, test results, blockers, current environment)
  in the log. Keep settled decisions and intended work in the goal and plan.
- Link detailed evidence in reviews, testing notes, or experiment artifacts;
  do not duplicate long transcripts in the log. Correct earlier findings with
  a new entry rather than rewriting old entries.

## Source map

- `main.swift`: startup, permissions, capture timer, overlay, event monitors.
- `TargetConnection.swift`: app/process/main AX window/capture bounds and queue.
- `AccessibilityBridge.swift`: snapshots, capabilities, hierarchy, identity, setters.
- `InputForwarder.swift`, `MirrorView.swift`: dispatch and incoming gestures.
- `CoordinateMap.swift`, `PointerSample.swift`, `KeyboardSample.swift`: mappings
  and preserved event properties.
- `MenuBridge.swift`: native menu publication and current invocation.
- `mirror-target-app`: deterministic controls, multiline editor, event log and
  dynamic menus. `Tests`: automated checks and the low-level held-key probe.
- `build.swift`: signed app bundle; preserve the existing signing identity.

All proxy source files are under `Sources/AppMirror/`. Current tests and
limitations are documented in [TESTING.md](TESTING.md).
