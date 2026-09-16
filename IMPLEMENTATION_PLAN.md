# Shared proxy implementation plan

Checkpoint: **2026-09-14, archived after the focus investigation.**
Implementation steps 1–7 exist, with the corrections below. **Step 8 is
incomplete.** Read [the review and evidence](REVIEW-2026-09-14.md) and
[testing instructions](TESTING.md) before resuming.

## Constraints

- One target window: the AX main window is authoritative. Look up its capture
  ID using the first layer-zero record with those exact bounds; do not rank,
  choose a nearest window, switch windows, or fall back to a different surface.
- Prefer shared behavior. An app-specific exception needs experimental evidence
  and a reason a shared solution would be substantially more complicated.
- **Never target `com.openai.codex` directly with Computer Use, even for
  debugging.** Use `com.chatgpt-mirror.proxy`. Direct Claude diagnosis is allowed;
  final real-app acceptance must use the mirror.
- Put every controlled target, mirror and fixture window on the secondary
  monitor. This does not isolate global mouse or keyboard input.
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

## Ordered implementation and corrections

| Step | Original commit | Current status |
| --- | --- | --- |
| 1. Remove experiments/window selection | `4279071cf015` | Sidebar experiment, label searches, ranking and nearest-window matching removed. |
| 2. Extract shared components | `74229c295d97` | TargetConnection, AX, input, menus and coordinates extracted; exit clears controls and queued work. |
| 3. Shared press policy | `109914c446ff` | One pointer press for in-window controls; AXPress for mirrored native menu-bar commands; no bundle-specific press exception. |
| 4. AX capabilities and identity | `8be58d64c6cd` | Supported operations, writable values/selections, live enabled state and parent-context resolution implemented; long-conversation reachability still needs work. |
| 5. Pointer and scroll forwarding | `5f764d26f4ae` | Buttons, modifiers, click count, hover, dragging and positioned scroll implemented; current transport uses shared/global input. |
| 6. Keyboard semantics | `a9c2239060be` | Down/up/flags/repeat preserved; September 14 fixed function keys being mistaken for Unicode text. Clipboard handoff still has a failing ChatGPT trial. |
| 7. Dynamic native menus | `a159cd1d6699` | Refresh/actions work; synthetic keyboard navigation was removed after its pass claim failed review. AX-opened menu keyboard control remains unverified; item clicks and AX Cancel work. |
| 8. Shared acceptance audit | — | Fixture and much of Claude tested; ChatGPT matrix and failure investigation remain incomplete. |

The menu commit was **Luna-authored despite its Astra trailer**. September 11
commits are public; the [archive](claude-proxy-control-and-sizing.md) records
the correction without rewriting public history.

September 14 Astra commits:

- `3ac80b2b2817`: remove synthetic menu navigation; nested fixture and lifecycle test.
- `4b0b0856a38f`: physical function keys; fixture Edit menu and regression test.
- `00e0f22f7114`: main-window capture lookup, untitled fixture, stale-surface cleanup,
  and removal of the unsupported bulk-AX fallback.
- `1d4cea11af09`: binary modifier logs.
- `b5afdf323520`: persistent pointer outcomes; retain the original press policy
  after a controlled context-menu comparison.
- `18abf9aed350`: review, partial audit and background-input findings.

## Next experiments, in order

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

## Environment and restart

At this checkpoint the secondary DELL U2723QE has AppKit frame
`(-197, 982, 2560, 1440)`; the built-in display is `(0, 0, 1512, 982)`.
Secondary AX top-left y is `-1440`. Tests used target `(-150, -1320)` and
mirror `(1000, -1320)`. Rediscover display geometry before reuse and reposition
after launching; the proxy centers itself on startup.

Launch the signed bundle with an explicit target using TESTING.md. Direct
executable launch previously reported AX permission denied. Temporary
`/tmp/review-*-mirror.log`, `/tmp/review-fixture.log`, and the placement helper
may disappear; durable findings are in the review.

The archive stops the proxy and fixture. Claude was last verified at home with
an empty draft, original model/System appearance and 288-point sidebar. The
ChatGPT test draft was cleared; subsequent user messages returned the UI to this
task, so fetch fresh state rather than assuming a selected page.
