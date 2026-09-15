**Summary.** The interactive terminal UIs in this project — the generic list selector in `pkg/tui/selector.go` and the GraphQL explorer in `pkg/tui/gqlexplorer/` — are keyboard-only. Every action a user can take (moving the cursor, selecting an item, focusing the search field, toggling an endpoint, expanding a dropdown, editing a form field) requires arrow keys, vim motions, tab, enter, or space. Users who reach for the mouse find that clicks do nothing. This work adds mouse support everywhere an action already exists, so a left click behaves as the natural equivalent of the keyboard action for that region.

**User story.** As a user of the selector and the GraphQL explorer, I want to click on a row, a search box, an endpoint, a form field, or a dropdown option and have it respond the same way it would if I had navigated there with the keyboard and pressed enter/space, so that I can drive the UI with either input device.

**Foundation — a reusable mouse-zone layer.** A small mouse/zone facility lives in a new file `pkg/tui/mouse.go` (package `tui`), built on `github.com/lrstanley/bubblezone` (with `github.com/lrstanley/bubblezone v1.0.0` among the module requirements). The rest of the code and the acceptance tests depend on the following being exposed:

1. A `MouseZone` value type obtained from a constructor `NewMouseZone()`. Each call to `NewMouseZone()` must yield a zone whose generated IDs are unique with respect to every other `MouseZone` instance — two independently constructed zones asked for the same logical name (e.g. `"action"`) must produce different ID strings. The constructor must lazily initialize the shared global zone manager exactly once (idempotent across many calls).
2. A method `ID(parts ...string) string` on `MouseZone` that builds a stable namespaced ID for a clickable region. With no parts it returns the zone's bare prefix; with multiple parts it joins them with a `:` separator, so `z.ID("button", "save")` yields an ID whose text contains `button:save`.
3. A method `Mark(id, view string) string` on `MouseZone` that wraps a view fragment with a zone marker for later scanning. Marking must not alter the visible text.
4. A package function `ScanMouseZones(view string) string` that registers all marked regions found in a root view and returns the view with the markers stripped — the returned string must equal the original visible text (markers removed, layout unchanged). A region marked with `Mark(id, "hello")` and then scanned must register a zone whose bounds start at the origin `(0,0)` and, for a single 5-character line, end at `(4,0)` (5 cells on one line).
5. A package function `IsLeftClick(msg tea.MouseMsg) bool` that reports true only for a left-button release: `Button == tea.MouseButtonLeft` and `Action == tea.MouseActionRelease`. A left-button press (not release) must return false, and a right-button release must return false.
6. A package function `Hit(id string, msg tea.MouseMsg) bool` that reports whether the event's coordinates fall inside the named zone's bounds. A click at any cell within the registered bounds is a hit; a click one cell past the end is not.
7. A package function `ZoneBounds(id string) (startX, startY, endX, endY int, ok bool)` returning the stored bounds of a zone, with `ok == false` when the zone is unregistered or zero.
8. A package function `ZonePos(id string, msg tea.MouseMsg) (int, int)` returning the click position relative to the zone's top-left origin (e.g. a click two cells into a zone that starts at `startX` yields relative `(2,0)`). For a click outside the zone bounds it must return `(-1, -1)`.

Dropdown behavior — expand and select as first-class operations. In `pkg/tui/dropdown.go`, `*Dropdown` exposes two exported methods, shared by both the keyboard and mouse paths:

1. `Expand()` — opens the dropdown with its cursor at the currently selected option. When the dropdown has no options, it stays collapsed and nothing changes. For a dropdown created with a selected index of 1, after `Expand()` the `Expanded()` state is true and `Cursor()` is 1. The collapsed-state keyboard handling for enter/space is expressed in terms of `Expand()`.
2. `Select(index int)` — chooses the option at `index` and collapses the dropdown. The index is clamped into range: values below 0 resolve to 0, and values at or beyond the option count resolve to the last option. When there are no options, both selection and cursor reset to 0 and the dropdown collapses. For a three-option dropdown, after `Expand()` followed by `Select(2)`, `Expanded()` is false, `Selected` is 2, and `Value()` is the third option's text.

Selector mouse support (`pkg/tui/selector.go`). The `SelectorModel` has a `MouseZone`, established during `NewSelector`. Within `Update`, a `tea.MouseMsg` is handled ahead of key handling and directed to a mouse handler. A left click:

- If the click lands in the search/title zone, focus the text input and consume the event (no selection).
- If the click lands on a filtered item row, move the cursor to that item's index, sync the viewport, select the current item, set `Selected` to that item's value, and return `tea.Quit` (the click both selects and confirms). Clicking the row for `item2` in a three-item list must set `Cursor` to 1, set `Selected` to `"item2"`, and produce a non-nil quit command.
- Non-click mouse events (scroll, drag) must still be forwarded to the text input and viewport, and the viewport must re-sync if the filter value changed.

The rendered view marks the title/search region and each visible item row with zone IDs, and the final view string passes through `ScanMouseZones` so the zones register. Item zones have stable per-index IDs, and the search region has its own zone ID. `RunSelector` starts its Bubble Tea program with `tea.WithMouseCellMotion()`, so that mouse events reach the real selector flows — without this, click behavior works only in isolation and never reaches users.

GraphQL explorer mouse support (`pkg/tui/gqlexplorer/model.go`). The `Model` owns a `tui.MouseZone` created in `NewModel`. `Update` handles `tea.MouseMsg` through a mouse handler in which a left click resolves against the left panel and the detail form:

- Clicking the search zone focuses the left panel (panel number 1), enables typing mode, syncs search focus and the viewport.
- In endpoint mode, clicking an endpoint row focuses the left panel, disables typing, moves `endpointCursor` to the clicked index, and toggles that endpoint's active state (add if inactive, remove if active) — except that when the current search is a negated endpoint search, the active set is replaced with all currently filtered endpoints. Badge cache and filter must be refreshed afterward. Clicking the second endpoint row must set `endpointCursor` to 1, leave the clicked endpoint toggled off, focus the left panel, and turn typing off.
- In operation mode, clicking an operation row focuses the left panel, disables typing, syncs search focus, and moves `cursor` to that operation's index. Clicking the second operation row must set `cursor` to 1, focus the left panel (`LeftFocused()` true), and leave typing off.
- Clicking a detail-form item routes to the detail form's mouse handler; if handled, focus the detail panel, sync search focus and viewport. Clicking a detail text-input item must focus the detail panel, put the detail cursor on that item, and focus that item's text input for editing.
- Clicking the search input while the detail panel is focused must move focus back to the left panel, enable typing, and focus the search input.

Per-index zone IDs are needed for operations and endpoints, along with a detail-mouse prefix and a search zone ID derived from the model's `MouseZone`. The detail form's zones must carry the model's detail prefix, which requires rendering through a marked-view path. Both top-level `View()` return paths must pass through `tui.ScanMouseZones` so that all zones register. Non-click mouse events must reach the search input and the focused viewport.

Detail-form mouse support (`pkg/tui/gqlexplorer/formitem.go`). The `DetailForm` exposes:

1. `itemZoneID(prefix string, index int) string` producing IDs of the form `<prefix>:item:<index>`.
2. `ViewMarked(op, zonePrefix string, mark func(id, view string) string) (string, int)` — a rendering path that wraps each form item's view with its item zone ID (using the supplied `mark` callback) when a non-empty prefix is given, while the existing `View(op)` continues to render without zone marks (behaving as if called with an empty prefix and an identity mark). Marking must not change the rendered text or the reported focused-line number.
3. `HandleMouse(prefix string, msg tea.MouseMsg) bool` — locates which item zone the click hit; if none, returns false. When an item is hit, it sets the form cursor to that item, focuses the current item, and then acts per item kind:
   - Toggle items: apply the space-key action; for argument (non-field) toggles, propagate enabled state to the argument; for expandable items, toggle expansion (inserting/removing child rows). Clicking an expandable field must move the cursor to it, turn its toggle on, and insert its child field so the form's item count grows accordingly (e.g. a two-item form becomes three).
   - Text-input items: mark the argument enabled (for non-field items), focus the input for editing, and sync list rows for list-valued arguments. Clicking a text-input argument must put the cursor on it, enter editing (input focused), and enable the argument.
   - Dropdown items: a first click on a collapsed dropdown enables the argument (for non-field items), focuses and expands the dropdown, and consumes the event. A subsequent click on the expanded list selects the option at the clicked relative row (via the dropdown's `Select`), keeping the click's relative Y within `[0, len(options))` (out-of-range clicks are ignored but still consumed); it then focuses the dropdown, enables the argument, and syncs list rows as needed. Clicking to expand a status dropdown then clicking two rows down must collapse it with the third option selected (its `Value()`) and the argument enabled.

Each successful item hit consumes the event by returning true.

Constraints:

- Do not modify any test files.
- Add `github.com/lrstanley/bubblezone v1.0.0` as the mouse-zone dependency; keep the rest of the module graph consistent.
- Mouse handling must be purely additive — all existing keyboard, vim-motion, tab/enter/space, and filtering behavior must continue to work unchanged.