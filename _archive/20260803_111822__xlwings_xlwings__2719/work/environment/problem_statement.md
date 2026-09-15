Reading a cell value off a book that came from the async API can silently hand back `None`, and there is no way to tell that apart from a cell that really is empty. The waste runs the other way too: `load()` pulls every cell back down even when a script only wants sheet names, tables, pictures or defined names.

Make the async path lazy on purpose, and make it honest when a value is not available yet.

A book fetched on demand is an "async book". A book built eagerly, for example `xw.Book(json=...)` the way the xlwings Lite notebook runner does it, is a "regular book". The difference has to be visible through the public `xw.Book` and `xw.Sheet` wrappers as well as the remote implementation.

1. The backend's asynchronous on-demand book fetch produces an async book. A book opened eagerly is a regular book, and nothing about how regular books behave today may change.

2. Reading a cell value synchronously on an async book whose sheet values have not been loaded raises `xlwings.XlwingsError` instead of returning `None`. Someone hitting this is usually mid-script, so the error has to be recoverable without opening the documentation. It has to make clear which sheet is involved, and it has to point at an awaitable way to get the value instead. Either real route counts, the range's own async read or a load that brings values in, and naming one of them is enough. This holds both on the remote range object and through the public wrapper, so `book.sheets[0]["A1"].value` raises as well.

3. On a regular book, synchronous value reads keep working and never raise for this reason.

4. `Book.load()` and `Sheet.load()` take an optional `values` argument. Called with no argument, an async book gets a metadata-only refresh, so reads on sheets whose values have not been loaded still raise, while a regular book gets a full load including values, exactly as it does today. `values=True` loads values whatever kind of book it is, after which the affected sheet reads normally. `values=False` stays metadata-only whatever kind of book it is, so a book that already had values keeps the ones it had rather than picking up fresh ones.

5. `Sheet.load(values=True)` affects that one sheet. The other sheets in the book are left as they were.

6. A metadata-only load must not throw away values that are already there. If a sheet's values were loaded earlier, a later bare `load()` leaves them readable.

7. Renaming a sheet must not change whether synchronous value reads on that sheet succeed or raise.

8. A script parameter annotated `xw.BookAsync` gets an async book, even though the caller builds the book eagerly and cannot know about the annotation. A synchronous `.value` read inside such a script therefore raises. A parameter annotated with the plain `xw.Book` is left alone and reads inside that script work.

9. The public `xw.Book.load(...)` and `xw.Sheet.load(...)` wrappers pass `values` through to the implementation, so `await book.load(values=True)` and `await sheet.load(values=True)` make values readable through the wrapper.

10. The book parameter's annotation may be written as optional. `Optional[xw.BookAsync]`, `xw.BookAsync | None` and `Union[xw.BookAsync, None]` all mean the same async book that the bare annotation means, and the optional spellings of the plain `xw.Book` stay regular. A script written that way has to work end to end, so the book still reaches the parameter, the script still hands that book back to its caller, and the script list the host reads still reports the async choice.

11. The host decides what the workbook holds, so a load can turn up a sheet the book has never seen before. A metadata-only load has to bring such a sheet in usable rather than half built. On a regular book it reads as empty. On an async book it raises the same not-loaded error any other unloaded sheet raises, and reads normally once its values have been loaded.

12. Skipping the cell payload is the whole point, so a metadata-only load has to say so in the request instead of pulling everything down and hiding it locally. The on-demand fetch and both load methods pass a boolean `lazy` option to `getBookData`, true when cell values are not wanted and false when they are.

13. Loading every sheet's values is still more than most scripts want, so `Book.load` also takes a list of sheet names in place of a plain yes or no. Only the sheets named get their cell values. Every other sheet keeps the values and the loaded state it already had, and no sheet drops out of the book just because it was not named. An empty list asks for nothing at all, the same as `False`. The request names the sheets it wants through the same `include` option a single sheet load already uses, so the host never sends cell values for a sheet nobody asked for.

14. A name in that list that the book does not have is worth catching rather than passing on to the host. It raises `xlwings.XlwingsError` and the message says which name was wrong.

Everything the library already does has to keep working. In particular the existing script argument binding, the deprecated `lazy=` argument on `@script` and its validation, and the existing `xw.BookAsync` annotation handling are all covered by the current test suite and must still pass unchanged.
