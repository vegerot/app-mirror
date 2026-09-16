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
