## Add a navigable outline to generated PDF documents

When this tool converts an AsciiDoc file to PDF, the resulting document has no outline (the panel of bookmarks that a PDF reader shows in its sidebar for jumping between sections). For long documents, this leaves no way to navigate by section from the reader chrome, even though the source `.adoc` file has a clear section hierarchy. The conversion goes through headless Chromium via puppeteer, and Chromium does not emit a PDF outline on its own (https://bugs.chromium.org/p/chromium/issues/detail?id=840455 remains unimplemented), so an outline needs to be produced by post-processing the PDF bytes that Chromium returns.

User story: as someone converting a structured AsciiDoc document, I want the
generated PDF to contain a section outline so that my reader's bookmark panel
lets me jump directly to any section, and I want that outline to appear whether
or not a visible table of contents was requested.

The conversion pipeline lives in `lib/converter.js`. Its `convert(processor, inputFile, options, timings, preview)` function renders the document to a temporary HTML file, drives puppeteer to produce PDF bytes via `page.pdf(...)`, and then either writes them to the output file or prints them to stdout. The document model returned by Asciidoctor is available within that function and exposes the parsed section tree (each section has a title, an id, and nested sub-sections) along with document attributes such as `toclevels`.

Acceptance criteria: after `convert(...)` runs for a document that contains
sections, the produced PDF must carry a document outline. Concretely, the PDF
catalog must contain an `Outlines` entry, and that outline must contain one
entry per section that is within the configured depth. Each outline entry must
carry a `Dest` (destination) whose name is the section's id, and a `Title` equal
to the section's title. Nested sections must be represented as children of their
parent entry, and the sibling/parent linkage of the outline entries
(`First`/`Last`/`Next`/`Prev`/`Parent`/`Count`) must be populated so the outline
forms a well-formed tree.

The depth of the outline is governed by the document's `toclevels` attribute,
which defaults to `2` when unset. A section is included only if its nesting
level is within `toclevels`: with the default of `2`, top-level sections and
their immediate sub-sections are included but deeper ones are not; with
`toclevels` of `1` only top-level sections are included; with `toclevels` of `3`
sections up to three levels deep are included. For a document whose top-level
sections are `Section 1`..`Section 4` (with `Section 1` having sub-sections
`1.1`→`1.1.1`→`1.1.1.1`, `Section 2` having `2.1` and `2.2`, `Section 3` having
`3.1`→`3.1.1`, and `Section 4` having `4.1`), the outline must contain 9 section
entries at the default `toclevels` of `2`, 4 entries at `toclevels` `1`, and 11
entries at `toclevels` `3`.

The outline is independent of whether a table of contents is rendered in the document body — it is present when the `toc` attribute is absent, when it is disabled, and when it is set to a value such as `macro`. Chromium only emits the internal `Dests` targets that outline destinations point at when the rendered HTML actually contains links to each section. For the outline destinations to remain resolvable in that case, a (visually hidden) set of section links is present in the rendered HTML regardless of the `toc` setting; the HTML template for the `document` node lives in `lib/document/templates.js`. When a section's destination cannot be resolved to a target present in the PDF's `Dests` (which can happen when an anchor contains an umlaut, per https://bugs.chromium.org/p/chromium/issues/detail?id=985254), a warning is emitted rather than the conversion failing.

Requirements:

1. The produced PDF must carry a PDF outline reflecting the document's section
   hierarchy. This outline is constructed with `pdf-lib` from the PDF bytes
   returned by puppeteer, taking the form of an outline dictionary tree set as
   the catalog's `Outlines`, with the PDF re-serialized to include it.
2. The `toclevels` attribute (default `2`) governs which sections appear in the
   outline, as specified above. A document with no sections within the depth is
   left unchanged.
3. Each outline entry's destination name is the section id (in the PDF this name
   is prefixed with `/`, e.g. a section with id `_section_1` corresponds to a
   `Dest` name of `/_section_1`), and its title is the section title.
4. The outline is generated regardless of the `toc` attribute, and this includes
   the hidden per-section links needed for Chromium to produce the corresponding
   destination targets.
5. When writing to a file, the output path receives the post-processed PDF (the
   one carrying the outline); when writing to stdout, the post-processed PDF is
   printed rather than the pre-processed bytes.
6. A missing section destination in the PDF's `Dests` produces a warning without
   aborting.

Constraints: the outline post-processing is reachable from the `convert(...)` path in `lib/converter.js`, and `lib/document/templates.js` continues to export the `document` template. `pdf-lib` is available as a dependency. Test files remain unmodified.