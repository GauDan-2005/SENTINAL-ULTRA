**Summary.** The two interactive terminal screens in this project are keyboard only. The shared list picker and the GraphQL explorer both expect arrow keys, vim motions, tab, enter or space for every action, so a user who reaches for the mouse finds that clicking does nothing. Add mouse support to both, so a left click does whatever the keyboard already does for the region under the pointer.

**User story.** As a user of the picker and the GraphQL explorer, I want to click a row, a search box, an endpoint, a form field or a dropdown option and have it react the way it would if I had moved there with the keyboard and pressed enter or space, so that I can drive these screens with either input device.

**A shared mouse zone layer.** Add a reusable click-region facility to the shared TUI package `github.com/xaaha/hulak/pkg/tui`. How the markers are encoded is yours to choose. Both screens and the acceptance tests reach the facility through the surface below, and whatever shared state it needs has to be in place before any region is marked or scanned.

1. `MouseZone`, a value type, built by `NewMouseZone()`. Two zones built separately must never produce the same ID for the same region name, and one zone asked twice for the same name must give the same ID back.

2. `ID(parts ...string) string` on `MouseZone`, which builds the ID of one clickable region. With no parts it returns the zone's own prefix. With several it joins them using a colon, so different parts always give different IDs.

3. `Mark(id, view string) string` on `MouseZone`, which wraps a piece of a view so a later scan can find it. What the user sees must not change.

4. `ScanMouseZones(view string) string`, a package level function rather than a method on a zone, which takes a whole rendered view, records every marked region in it whichever zone marked it, and returns that view with the marks taken out. The text and the layout that come back are exactly what was marked. Each scan replaces what the scan before it recorded, so a region that is no longer drawn stops being clickable.

5. `IsLeftClick(msg tea.MouseMsg) bool`, true only for the release of the left button. A press on its own, a right button release and a wheel event are all false.

6. `Hit(id string, msg tea.MouseMsg) bool`, true when the event landed on a cell inside the named region. One cell past the end of the region is outside it, and a name that was never marked has no hits.

7. `ZoneBounds(id string) (startX, startY, endX, endY int, ok bool)`, the recorded corners of a region. The end coordinates name the last cell the region covers rather than the first cell after it. `ok` is false for a region that was never recorded.

8. `ZonePos(id string, msg tea.MouseMsg) (int, int)`, where the event landed relative to the top left cell of the region, which counts as (0,0). A click outside the region gives back (-1,-1).

**Dropdown.** `Dropdown` in the same package gains two exported methods, which the keyboard path and the mouse path both go through.

- `Expand()` opens the option list with the cursor on the option that is currently selected. A dropdown holding no options stays closed and nothing else about it changes.
- `Select(index int)` picks an option and closes the list. An index below the range resolves to the first option and an index at or past the end resolves to the last one. With no options the selection and the cursor both fall back to zero and the list stays closed.

**The list picker.** `SelectorModel` gets a mouse zone of its own when it is built, and its update path handles `tea.MouseMsg`. A left click on the title and search area focuses the filter input and selects nothing. A left click on one of the visible rows moves the cursor to that row, makes it the selection and confirms it, which ends the picker the way pressing enter does. Its rendered view marks the search area and every visible row, and the string it returns has been through `ScanMouseZones`, so the regions get recorded wherever they land on screen.

**The GraphQL explorer.** `Model` gets a mouse zone when it is built, its update path handles `tea.MouseMsg`, and every view it draws records its regions, including the single stacked panel it falls back to when the terminal is too narrow for two. A click the left panel handles must not also reach the detail form.

- Clicking the search box focuses the left panel, turns typing on and focuses the search input, including when the detail panel held the focus.
- With the endpoint list showing, clicking an endpoint row focuses the left panel, turns typing off, moves the endpoint cursor to that row, and switches endpoints the way pressing enter on that row already does.
- With the operation list showing, clicking an operation row focuses the left panel, turns typing off and moves the cursor to that operation.
- Clicking a row of the detail form hands the event to the form, and when the form takes it the detail panel gets the focus.

**The detail form.** `DetailForm` gains two exported methods.

- `ViewMarked(op *UnifiedOperation, zonePrefix string, mark func(id, view string) string) (string, int)` renders the form and wraps each row with a region ID built from the given prefix and the row's position, using the mark function it was handed. The existing `View(op)` keeps rendering without regions, which is what `ViewMarked` does when the prefix is empty. Marking changes neither the rendered text nor the focused line number that comes back with it.
- `HandleMouse(prefix string, msg tea.MouseMsg) bool` works out which row the click landed on and reports false when it landed on none of them. On a hit it moves the form cursor to that row and focuses it, then acts by row kind, and reports true.

What a hit does depends on the row it landed on. A toggle row flips on or off, and an expandable one also opens, which adds its child rows to the form. A text row switches its argument on and becomes ready for typing. A closed dropdown row switches its argument on, takes focus and opens. A dropdown row that is already open picks the option on the row that was clicked, closes, and leaves the argument on.

**How far a switch reaches.** An argument whose type is an input object is drawn as one row per field, and every one of those rows belongs to the same argument. Switching one of them on or off has to change that row and no other. A row that stands for a whole argument, and the rows of a list argument, still carry the whole group with them. Whether a switch came from a click or from the space key, it reaches the same rows. An argument that is optional starts every row it expands into switched off, including a field that is required in its own right, and that field still reports itself as required.

**Constraints.**

- The verifier runs with no network, so nothing can be downloaded once the tests start.
- The keyboard keeps working, including vim motions, tab, enter, space and filtering, and scroll and drag still reach the list instead of being taken for clicks. The one keyboard behaviour that moves is how far a switch reaches, described above, which the space key now follows too. Everywhere else mouse support is an addition rather than a replacement.
