In xlwings' remote backend, a workbook opened over the Office.js bridge can carry a huge amount of cell data. When a script only needs a workbook's structure — sheet names, tables, pictures, defined names — eagerly transferring every cell value across the async boundary is wasteful and defeats the purpose of the asynchronous (`xw.BookAsync`) API. Today, however, an async book is fetched with all of its values, and if the values happen to be absent a synchronous `.value` read silently returns `None`, hiding the fact that nothing was actually loaded. The goal is to make async books load *lazily* by default — metadata only, no cell values — and to make synchronous value reads on such a book fail loudly with an actionable message instead of returning misleading data.

A workbook fetched lazily is considered an "async book"; a workbook constructed eagerly (for example via `xw.Book(json=...)`, as the xlwings Lite notebook runner does) is a "regular book". The distinction must be observable and controllable through the public `xw.Book`/`xw.Sheet` wrappers as well as the underlying remote implementation.

Acceptance criteria:

1. A book carries a lazy flag that reflects how it was obtained. When the remote backend fetches a book on demand (the internal fetch path used for async access), the resulting book is marked lazy. A book opened eagerly is not lazy. The implementation-level book object exposes this state as a boolean attribute `_lazy` (accessible as `book.impl._lazy` through the public wrapper), defaulting to `False`.

2. When a synchronous `.value` (i.e. the range's `raw_value`) is read on a lazy book whose sheet values have not been loaded, the read raises `xlwings.XlwingsError` rather than returning `None`. The error message must state that the sheet's cell values `haven't been loaded`, identify the sheet by name, and point the user at the async alternatives — reading on demand with `await myrange.get_value()` and loading everything up front with `await book.load(values=True)`. This behavior must be visible both through the remote `Range` and through the public wrapper (`book.sheets[0]["A1"].value`).

3. On a regular (non-lazy) book, synchronous value reads work normally and never raise for this reason.

4. `Book.load()` and `Sheet.load()` accept an optional `values` parameter (`values: bool | None = None`). Given a lazy book and no explicit `values` argument, `load()` performs a metadata-only refresh and must not mark any sheet's values as loaded, so subsequent synchronous reads still raise. Given a regular book and no explicit `values` argument, `load()` performs a full load including values and marks the loaded sheets' values as available. Passing `values=True` forces a full value load regardless of the book's laziness, after which synchronous reads on the affected sheet succeed; passing `values=False` forces metadata-only regardless of the book's eagerness.

5. `Sheet.load(values=True)` marks only that sheet's values as loaded, not the whole book.

6. A metadata-only load must not clobber cell values that were already loaded. If a sheet's values were previously loaded (e.g. via an earlier `load(values=True)`), a later metadata-only `load()` must leave those values intact and readable.

7. The per-sheet "values loaded" state must survive a sheet rename — it must not be keyed on the mutable sheet name, since a sheet can be renamed without a round-trip. The module `xlwings.pro._xlremote` exposes two module-level helpers: `_mark_sheet_values_loaded(sheet_api)` records that a sheet's values are loaded, and `_sheet_values_loaded(sheet_api)` returns whether they are (both take the sheet's api dict). After marking a sheet's values loaded, renaming that sheet must not cause synchronous reads to start raising again.

8. When a script parameter is annotated with `xw.BookAsync`, the book injected for that parameter must be made lazy even though the caller constructs it eagerly (the caller cannot know the annotation). The injected book's `_lazy` becomes `True`, and a synchronous `.value` read inside that script raises `XlwingsError` (message containing `haven't been loaded`). A parameter annotated with the plain `xw.Book` leaves the injected book eager (`_lazy` stays `False`) and synchronous reads inside the script work.

9. The public `xw.Book.load(...)` and `xw.Sheet.load(...)` wrappers forward the `values` argument through to the underlying implementation, so `await book.load(values=True)` makes values readable through the public wrapper.

Interface contract (must hold verbatim):
1. `xw.XlwingsError` is raised for a synchronous value read on a not-yet-loaded lazy book, and the message contains the substring `haven't been loaded`.
2. The implementation book object exposes a boolean `_lazy` attribute (default `False`).
3. `Book.load` / `Sheet.load` (both implementation and public wrapper) accept `values` with default `None`; `values=True` forces values, `values=False`/`None`-on-lazy forces metadata-only, `None`-on-eager forces a full load.
4. `xlwings.pro._xlremote` exposes module-level `_mark_sheet_values_loaded(sheet_api)` and `_sheet_values_loaded(sheet_api)`, both taking a sheet's api dict, to set and query whether that sheet's values are loaded.

Do not modify any test files.
