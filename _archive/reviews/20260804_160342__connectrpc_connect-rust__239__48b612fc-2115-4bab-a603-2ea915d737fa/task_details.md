# Reviewer page evidence - 20260804_160342__connectrpc_connect-rust__239

Received as a complete page paste on 2026-08-19. Reviewer task UID: `48b612fc-2115-4bab-a603-2ea915d737fa`.

## Platform task data

```text
Original Directory Name: 20260804_160342__connectrpc_connect-rust__239
Category: implementation
Difficulty: hard
Task Tags: protobuf, code-generation, decode-limits, error-handling, rust, descriptor-set
Languages: Rust, YAML
Source PR: https://github.com/connectrpc/connect-rust/pull/239
Base commit: 8b3c3b05d3b54af547477a9e3b3a77d62f68e229
```

The page metadata named `connect-rust`, `Apache-2.0`, the same source URL and base commit, a verifier timeout of 300 seconds, agent timeout of 1800 seconds, and environment CPU, memory, storage and network settings. The page did not display an environment operating system field.

## Artifacts and state

- Seed download: `ad572a7a-e077-4db5-b198-c10438377046_submission.zip`
- Submitted download: `8dc1922a-5dd5-4816-a273-cd91f063b0f7_submission_2026-08-18T19_40_06.421Z.zip`
- Submitted re-upload shown on the page: `ad572a7a-e077-4db5-b198-c10438377046.zip`, timestamp 2026-08-19 01:10:10.
- No maximum-revisions dialog appeared.
- No rebuttal comments appeared in the supplied complete page.

## Submitter answer and claims reviewed

The submitter selected Fixable. Their issue list said the original instruction exposed implementation helpers, a crate version, a manual conversion approach and exact behavior. They said the original tests missed public paths, called a private helper, and contained unused `connectrpc` fixture hunks. They also reported cleaning Windows Zone.Identifier files and git metadata.

The Files Changed section says instruction.md and environment/problem_statement.md were rewritten, tests/tests.patch was rebuilt with public Config, plugin CLI, reflection and generate coverage, git metadata was scrubbed, solution/solve.sh became forward-only, tests/test.sh now gates reward on cargo exit status, tests/config.json was updated to 20 fail-to-pass and 2 pass-to-pass ids, and task.toml was updated for timeouts, license, difficulty explanation and legacy difficulty fields. PR additions were NA.

The Comments for Reviewer say the current zip keeps instruction.md and tests.patch unchanged, test.sh now requires a zero cargo exit, config.json parses stdout only, fail-to-pass remains 20, solve.sh is forward-only and golden.patch remains tied to PR 239. They also report a local airgapped oracle reward of 1 and a NOP reward of 0.

## Prior reviewer feedback

The page displayed an 2026-08-18 note that solution/solve.sh had previously fallen back to a reverse apply after a forward apply failed. It requested a forward-only implementation and 0755 modes for solution/solve.sh and tests/test.sh. The current submitted solve.sh was checked directly during this review.

## Evaluation evidence

- Page headline: All checks have passed.
- Difficulty: PASS HARD. `codex-gpt-5-5` scored 1 of 4 runs.
- Agentic Judge: OK.
- Oracle: PASS 3 of 3. NOP: PASS 0 of 1 as expected.
- Quality panel: one remaining instruction disclosure finding. It identified the prompt's exact wording `well-formed` as wording the tests assert.
- Difficulty checks run and difficulty checks remaining appeared blank.
- Last counted submission version: `38523be0-ca0a-4e4c-94e1-72d3cdfd8e4d`.
- Last difficulty result: `hard`.
