# Vim Keyboard Navigation Plan

## Problem Statement
The reader currently lacks keyboard-first navigation between markdown blocks, so users must use mouse/trackpad to move context. We need Vim-like movement that is predictable in preview contexts and does not interfere with editing inputs.

## Goal
Enable Vim-style block navigation in the reader with clear focus behavior, visible selection, and reliable auto-scroll.

## Assumptions
- Scope is reader navigation only, not source editor text editing.
- Initial keymap includes `j` (next block), `k` (previous block), `Enter` (select block), `c` (comment selected block), and `d` (delete toggle on selected block).
- Navigation is active in `Preview` and in `Split` only after click-focus on the reader pane.
- Selection should be visually indicated for both plain and annotation-enabled rendering.
- Block identity uses parsed top-level markdown block order.
- Initial selection is the first visible block in the current viewport.

## Files to Edit
- `Sources/Parchment/ContentView.swift`
- `Sources/Parchment/ReaderView.swift`
- `Sources/Parchment/MarkdownRenderer.swift`
- `Sources/Parchment/AnnotatableBlockView.swift`
- `Tests/ParchmentTests` (add focused navigation tests)

## Plan
1. Write tests first for keyboard navigation and block actions.
Expected outcome: failing tests that encode expected behavior for `j/k`, `Enter`, `c`, `d`, focus gating, and first-visible initial selection.

2. Validate failures and confirm current behavior gap.
Expected outcome: test run clearly demonstrates missing functionality before implementation starts.

3. Introduce navigation and action state in top-level view state.
Expected outcome: `ContentView` owns `selectedBlockIndex`, `selectedBlockIsArmed`, and reader focus state; index resets/clamps when source changes.

4. Add reader key event capture at the `NSScrollView` layer.
Expected outcome: `ReaderScrollContainer` handles `j/k/Enter/c/d` only when reader is focused and no text input is active.

5. Add stable block indexing, first-visible selection bootstrap, and selection wiring in renderer.
Expected outcome: `MarkdownRenderer` exposes block index + selected state, and reader computes first-visible block when focus is obtained.

6. Render selection state and selected-block actions in annotation UI.
Expected outcome: selected block styling is consistent across `BlockView`/`AnnotatableBlockView`, and `c`/`d` trigger comment/delete for selected block.

7. Implement scroll-to-selected behavior in coordinator.
Expected outcome: moving selection via keyboard keeps selected block in viewport with minimal jitter and bounded scrolling.

8. Re-run tests and make them pass.
Expected outcome: previously failing tests pass, validating final behavior end-to-end.

## Architecture Diagram
```text
ContentView
  ├─ viewMode + reader focus state
  ├─ selectedBlockIndex (source of truth)
  └─ passes bindings/callbacks
         |
         v
ReaderView / ReaderScrollContainer (NSViewRepresentable)
  ├─ keyboard capture (j/k/Enter/c/d)
  ├─ movement + selection/action routing
  └─ scroll coordinator (ensure selected block visible)
         |
         v
ReaderContentView
  └─ MarkdownRenderer
      ├─ parsed block list with stable indices
      ├─ selected flag per rendered block
      └─ block geometry reporting
             |
             v
BlockView / AnnotatableBlockView
  └─ visual selected state + existing annotation UI
```

## Risks
- Keypress conflicts with comment composer/text fields.
Mitigation: first-responder checks and explicit focus gating.
- Selection index becoming invalid after markdown edits.
Mitigation: clamp/reset index whenever block count changes.
- Scroll jitter when geometry updates frequently.
Mitigation: ignore no-op targets and debounce repeated scroll requests.
- Visual conflict between selection highlight and annotation deletion/comment accents.
Mitigation: unify highlight layering and keep annotation colors dominant.

## Decision points
- v1 key support: `j`, `k`, `Enter`, `c`, `d`.
- Initial selection: first visible block in viewport.
- Split mode focus rule: keyboard handling only after click-focus on reader pane.
