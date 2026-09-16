# Goal — App Mirror

> Read this file after every context compaction. Then read the
> [implementation plan and handoff](IMPLEMENTATION_PLAN.md).

Let Codex's Computer Use inspect and manipulate ChatGPT.app and Claude.app
through a separately identified macOS mirror. The mirror republishes the
accessibility tree and captured pixels, then forwards input to the target.
The objective includes settings, menus, navigation, and draft editing; sending
a message was only an early example.

## Identities and strict boundary

- **ChatGPT.app:** `com.openai.codex`, the Codex host and default target.
- **Claude.app:** `com.anthropic.claudefordesktop`, the second real target.
- **Mirror:** `com.chatgpt-mirror.proxy`, the Computer Use surface.
- **Fixture:** `com.mirror-target.testapp`, a deterministic native test app.

**Never inspect or manipulate `com.openai.codex` directly with Computer Use,
even for debugging. Always use the mirror.** Direct Claude Computer Use is
allowed for diagnosis; final acceptance uses the mirror for both apps.
Do not confuse the current agent with historical assistants in the archives.
The old notes describing “Trae = me” were historical, not current instructions.

## Principles

Simplicity, small experiments, and general-purpose behavior. Support one target
window. Delete obsolete experiments and multi-window selection instead of
building fallbacks. App-specific exceptions are a last resort requiring evidence.
Never automatically press twice because the first action had no visible effect.

Keep useful accessibility ancestry and publish real capabilities. Pixels alone
were insufficient in the earlier differential probe: the agent read the AX-only
fixture token. Both accessibility and visible outcomes matter in current tests.

Every feature must be supported and logged/displayed by the fixture. Experiments
may start with the fixture or either real app, subject to the strict mirror
boundary. Put all controlled windows on the user's secondary monitor to avoid
interference. Restore state after tests and never send test chat messages.

Preserve initial outer-window sizing, stable signing identity, bundle ID,
`MIRROR_TARGET_BUNDLE_ID` and its default. Continuous resizing, multiple windows,
file pickers, capture replacement and refresh optimization are deferred.

## Current status — 2026-09-14 archive

Implementation steps 1–7 exist, with September 14 corrections to menu handling,
function keys, capture assumptions and fixture logs. Seven automated tests and
both signed builds pass. **The shared acceptance audit remains incomplete.**

The [review](REVIEW-2026-09-14.md) records the actual fixture
and real-app outcomes. ChatGPT paste has an unresolved failure, long-conversation
controls can exceed the snapshot budget, and emoji selection/native-menu keyboard
behavior have documented limitations. Do not treat the earlier Luna pass claims
as current acceptance.

The user investigated why tests took global focus. Native Codex Computer Use on
macOS successfully clicked and typed in a background fixture while another app
remained foreground; this proxy itself imposes target activation and global
pointer delivery. The next focused experiment is targeted background input with
independent checks of result, foreground app and physical cursor. It has not been
implemented. Keep the single-window and general-purpose constraints.

Start with [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md),
then [TESTING.md](TESTING.md). Historical evidence is in
[the initial archive](chatgpt-mirror-proxy-app.md) and
[the resumed proxy archive](claude-proxy-control-and-sizing.md). The separate
[Luna billing investigation](../codex/luna-reserve-routing-and-credits.md) has its own
source; it is not a continuation of the proxy implementation.
