# Agent instructions — shared mirror proxy

Read [the goal](GOAL.md) before working here and after
compaction, then [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) for the exact
checkpoint and next experiment.

- Never use Computer Use directly on `com.openai.codex`, including debugging.
  Use `com.chatgpt-mirror.proxy`. Direct Claude diagnosis is allowed; final tests
  of both real apps must operate through the mirror.
- Keep every controlled window on the secondary monitor: target and proxy.
  Check placement again after launching. Do not interfere with the user's
  primary-monitor work.
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
