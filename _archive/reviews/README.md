> **Process scope, 2026-08-19.** Archived records may describe the legacy deep-battery reviewer workflow. Future reviews use the timed platform-first static path in Section 13. Their form-ready answer is not evidence that a local battery ran.

# Archived peer reviews

Closed reviews land here, whole, at Section 13 R11 item 6:
`git mv review_tasks/<name> _archive/reviews/<name>`.

Empty as of 2026-08-18. Three finished reviews are still sitting in `review_tasks/`, which is
gitignored, so until they are moved they exist on one disk with no history.

## Why reviews are one level deeper than tasks

Not tidiness. `.claude/rules/09-task-toml-reference.md` derives its `task.toml` baseline from two
globs, and a flat `_archive/<name>/` for a review would land inside both:

- **column three** counts `_archive/*/work/`, meaning what a submitter **here** shipped. A review's
  `work/` is a copy of **another EC's** submitted bundle, so it must never join that population.
  `_archive/reviews/<name>/work/` does not match `_archive/*/work/`, because `*` does not cross a `/`
- **column two** globs the arriving bundles and legitimately **wants** a reviewed bundle, since an
  arriving bundle is an arriving bundle whoever was sent it. That loop therefore names
  `_archive/reviews/*/download/original` explicitly

That is the same family of error as LEDGER L61 and L72, where a baseline read off `_archive/*/work/`
reported five other submitters' rewrites as one bundle's defects. Here the separation is a path
rather than a rule somebody has to remember.

## Shape

Same as `review_tasks/<name>/`: `task.md`, `task_details.md`, `download/` (both zips plus the frozen
`seed/` and `original/` extracts), `work/`, `answers/review_answer.txt`, and an empty `upload/` that a
review never uses.

**Check the zip sizes before moving.** A review carries two zips where a task carries one, and
`.gitignore` already excludes four `_archive/` zips that crossed GitHub's 100 MB limit. Add any
over-limit zip the same way and let the extracted trees carry the record.
