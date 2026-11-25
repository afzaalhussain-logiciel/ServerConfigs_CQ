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

**A skipfile rule is a repo path, but CodeChecker matches absolute paths.**
Scope used to be written in the "+*/src/*" form, which does not mean "my src
directory" - it means "any path containing /src/". The target is checked out at
/src and the baseline at /src-baseline, so that rule matched the target's
checkout root and pulled in every directory under it, while the baseline's root
has no /src/ segment and those files fell through to the closing "-*". The refs
were analysed with different scope, and whatever a repo keeps outside src/
existed only on the target side of the diff and scored as net-new. On FIXHub
that was the generated config/FbeProto code: 0 baseline plists against 12 on
the target, 3 of them HIGH, failing a branch whose own change was clean. Repos
whose sources all sit under a top-level src/ were unaffected, because
/src-baseline/src/... still matched.

Rules are now written as absolute paths against $SRC - "+/src/src/*",
"-/src/build*/*" - so the target uses the file as it stands and the baseline
needs one substitution of the root. A rule outside the checkout ("-/usr/*")
and the closing "-*" do not start with $SRC and are left alone, which keeps
external scope external. Being explicit also removed the prologue: a rule that
names /src/src cannot reach /src/build/src or /src/3rdparty/*/src, so the
non-overridable excludes for build trees, vendored directories and /usr were
only ever needed to contain the "*/" form. Measured identical scope on muxer
(50) and FIXHub (79) with the prologue gone, on both refs, including synthetic
build-tree, vendor, submodule and nested-test paths.

The cost is that a repo's skipfile names the container's checkout directory, so
moving $SRC means updating every repo. That is the trade for one substitution
instead of a rewriter.

Each ref is scoped by its own skipfile, read from its own checkout. The
alternative - scoping the baseline with the target's rules, so both sides of
the diff share one ruler - only reaches the baseline on the runs that actually
re-analyse it, and in steady state NEED_BASELINE is 0 and the comparison uses
the stored run. That made a stored baseline's scope depend on whichever target
happened to refresh it. Reading each ref's own file makes it a function of that
ref alone, so the stored run is reproducible. The consequence to know: a PR
that widens scope sees the newly included pre-existing code as new until the
baseline is refreshed.

A relative rule, or the old "+*/src/*" form, matches nothing once the checkout
prefix is substituted. An empty target scope reports a clean PASS with no
analysis behind it; an empty baseline scope makes every target finding look
new. `require_absolute_rules` is applied to both refs' files and fails naming
the offending lines.

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
