# Findings

Why the pipeline does what it does, and what was measured to decide it. The
README covers the design and how to deploy it; this file is the evidence.

## Flags that look wrong but are not

- `-fsanitize-recover=address` - without it `halt_on_error=0` is ignored and
  ASan aborts at the first finding. Measured 1 report without, 12 plus 2 leaks
  with.
- `ctest --verbose`, never `--output-on-failure` - with recover a reporting
  test still exits 0, and on-failure prints nothing for a passing test. The
  findings are silently lost and the gate reads clean. Measured 0 vs 10.
- `-fno-var-tracking-assignments` - ASan+UBSan in one TU pushes GCC past
  `--param max-vartrack-size`, and it then recompiles the function without that
  pass. Under LTO codegen runs per link, so one function is re-tracked once per
  executable. Measured on vantage: 19 retries / 1137s -> 0 retries / 418s, same
  166 objects and 61 links. Generated code is unaffected, so findings are not.
  Chosen over `-DVANTAGE_LTO=OFF` (640s) because it needs no repo change.
- `require_instrumentation` - a sanitizer that failed to apply reports nothing,
  which is indistinguishable from a clean run. Each pass proves its runtime
  symbols are linked before any zero count is believed.

## Store-time traps

**Each ref needs its own checkout.** `CodeChecker store` hashes the files a
report references, so storing the target's reports against baseline source
fails with *"source file contents changed"*. The baseline gets a `git worktree`
at `/src-baseline`, and each store passes its own `--trim-path-prefix` so both
land on identical relative paths - CodeChecker diffs by path.

**Each ref needs its own output dir.** On the targets route the repo's `cq_*`
targets bake `CQ_OUTPUT_DIR` in at configure time and ignore any directory
passed later. Hardcoding `$QC` sent the baseline's findings into the target's
reports dir: baseline stored 0, target 3 instead of 31, and net-new silently
read 0 - a false PASS. `repo_target_flags` takes the dir as a parameter.

**The analyze skipfile must not reach the store.** `CodeChecker analyze
--ignore` leaves its skipfile as `reports/skip_file`, and both `parse` and
`store` auto-detect it and re-apply it to the whole directory - including the
report-converter plists. Scoping already happened at analyze time, so the
second pass drops no static report (measured 0 on both repos) and every TSan
one (14 on vantage, 4 on muxer), because TSan attributes a race to the test
that drives it. `analyze.sh` removes the file before storing.

**A skipfile names repo directories, but CodeChecker matches absolute paths.**
The target is checked out at `/src` and the baseline at `/src-baseline`, so a
rule like `+*/src/*` also matches the target's checkout root and pulls in every
directory under it, while the baseline's root has no `/src/` segment and those
same files fall through to the closing `-*`. The two refs were analysed with
different scope, and whatever the repo keeps outside `src/` existed only on the
target side of the diff and scored as net-new. On FIXHub that was the generated
`config/FbeProto` code: 0 plists on the baseline against 12 on the target, 3 of
them HIGH, failing a branch whose own change was clean. Repos whose sources all
sit under a top-level `src/` were unaffected, because `/src-baseline/src/...`
still matches - measured 0 files moving on muxer and vantage.
`anchor-skipfile.awk` rewrites each relative rule against one root, and the
Dockerfile emits a copy per ref, so both get the scope the rules describe.

Both copies come from the TARGET's skipfile, read before the baseline worktree
exists. That is deliberate: the gate is a diff, so both sides need one ruler,
and it is the PR's. A commit that widens scope then re-measures the newly
included code on both refs and the diff stays honest, where per-ref skipfiles
would have scored all of it as new and made widening a self-inflicted failure.
The stored baseline is not re-scoped though, so a PR that materially widens
scope still needs REFRESH=1 until the skipfile is hashed into that decision.

**TSan's pid must be normalised.** report-converter hashes the report message
and TSan puts the pid in it, so the same race hashed differently every run and
every pre-existing race scored net-new forever. `trace_tests.cpp:1854` was
`505ef479` on the target and `b6c02642` on the baseline; normalised, both give
`f17ebd7c`. The hash ignores the path prefix, so `/src` vs `/src-baseline`
needs no rewriting. The `==N==` prefix is only the parser's cue, so a constant
serves.

## Known limitation

report-converter headlines a TSan report at whichever frame its heuristic
picks, which for a thread entry point is libstdc++. On muxer, three distinct
defects - `oe_throttle.cpp:77`, `san_scenarios.cpp:97` and `:98` - all headline
at `std_thread.h:211` and share one report hash. The real sites survive in the
bug path, but the headline is unactionable, triage is all-or-nothing, and if any
one race is ever on the baseline the rest classify as pre-existing. Fixing it
means re-attributing to the first bug-path frame under the source root.
