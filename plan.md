# App Mirror implementation plan

Read [GOAL.md](GOAL.md) for scope and settled principles, then
[progress.md](progress.md) from the bottom for completed work, evidence,
blockers, and the next experiment. Compare the working copy with the latest
entry before continuing. Follow the progress convention in [AGENTS.md](AGENTS.md).

## Constraints

- One target window: the AX main window is authoritative. Look up its capture
  ID using the first layer-zero record with those exact bounds; do not rank,
  choose a nearest window, switch windows, or fall back to a different surface.
- Prefer shared behavior. An app-specific exception needs experimental evidence
  and a reason a shared solution would be substantially more complicated.
- **Never target `com.openai.codex` directly with Computer Use, even for
  debugging.** Use `com.chatgpt-mirror.proxy`. Direct Claude diagnosis is allowed;
  final real-app acceptance must use the mirror.
- When more than one monitor is connected, put every controlled target, mirror
  and fixture window on the secondary monitor. This does not isolate global
  mouse or keyboard input.
- Every new feature needs fixture support and visible/logged outcomes. Verify
  the target result; an acknowledged action is not proof it worked. Never
  automatically repeat a press after a visual no-op.
- Preserve initial outer-window sizing only, the stable signing identity and
  bundle ID, periodic refresh, `MIRROR_TARGET_BUNDLE_ID`, and its existing
  `com.openai.codex` default.
- Defer multiple windows, file pickers, continuous resizing, capture-engine
  replacement, refresh optimization and a configuration framework.
- Use scoped Sapling commits with model attribution. Preserve unrelated files
  and other tasks' commits. Do not push without a request.

## Implementation order

1. Remove obsolete experiments and window selection.
2. Extract shared target, accessibility, input, and menu components.
3. Use one shared press policy.
4. Preserve accessibility capabilities and identity.
5. Preserve pointer and scroll properties.
6. Preserve keyboard semantics.
7. Publish dynamic native menus.
8. Complete the common fixture and real-app acceptance audit.

Completion and corrections are recorded in [progress.md](progress.md).

## Remaining experiments, in order

1. **Investigate background forwarding with one target window.** Native Codex
   CU clicked and typed in the fixture while ChatGPT stayed foreground; our
   proxy imposes activation and global HID input. Compare process/window-directed
   mouse, scroll and keyboard delivery with the existing path. Read the focused
   iFurySt/Cua/Peekaboo source pointers in the review, but do not import their
   multi-window/fallback machinery. Measure target outcomes, actual foreground
   application and hardware cursor independently. Start with the fixture.
2. **Repeat and diagnose ChatGPT paste in a controlled interval.** The last
   paste timed out and inserted restored clipboard text while the user was
   multitasking. No isolated repeat completed. Read the actual draft after a
   timeout before retrying. Do not assume the existing 100 ms key-down and
   150 ms Command-V delays solve this; earlier clipboard rewrite experiments
   also caused CU conflict errors.
3. **Keep important controls reachable in long conversations.** ChatGPT's
   current conversation composer fell outside the snapshot budget; its new-chat
   composer was reachable. Add a representative fixture before changing traversal.
4. **Complete the common audit.** Repeat the applicable matrix on the final
   build in both real apps through the mirror. ChatGPT settings/popups/scroll/drag
   still need checking. Resolve or accurately record emoji-selection behavior,
   native menu keyboard limitations and unavailable hover/repeat CU operations.
5. **Update documentation and archive the result.** Record versions, initial
   sizing, outcomes and restoration. Do not convert unit metadata checks or
   historical smoke tests into a claim of full acceptance.

Background forwarding is a proposed next experiment, **not implemented**.
