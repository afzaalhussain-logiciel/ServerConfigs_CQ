#!/usr/bin/env bash
# Code-quality build passes, sourced by the Dockerfile and tsan.sh.
# README.md has the reasoning and the measurements behind each choice.
#
#   cq_analyse_memory    address+undefined + compile DB -> static, asan, lsan,
#                        ubsan reports                      tree DELETED
#   cq_measure_coverage  -O0 --coverage -> cobertura, diff-cover
#                                                           tree DELETED
#   cq_build_thread      thread -> builds only; cq_run_thread runs it later
#                                                           tree KEPT, pruned
set -eu

build_jobs() { echo "${JOBS:-$(nproc)}"; }

# -fno-var-tracking-assignments: GCC abandons that pass itself on instrumented
# functions, and under LTO the retry repeats per link. README.md.
SAN_DEBUG='-fno-omit-frame-pointer -g -fno-var-tracking-assignments'

# The baseline needs its own checkout: CodeChecker store hashes the files a
# report references, so the two refs cannot share one tree. README.md.
BASE_SRC=/src-baseline
src_dir()     { echo "${CQ_SRC:-$SRC}"; }
src_dir_for() { [ "$1" = baseline ] && echo "$BASE_SRC" || echo "$SRC"; }

# A rule must be an absolute path, or the closing "-*". A relative rule and the
# old "+*/src/*" form both match nothing once the checkout prefix is
# substituted: the scope empties, and an empty target scope reports a clean
# PASS while an empty baseline scope makes every target finding look new.
require_absolute_rules() {   # require_absolute_rules <skipfile>
    grep -nvE "^([+-]/|[+-]\*\$|#|[[:space:]]*\$)" "$1" || return 0
    echo "[cq] $1: the rules above must be absolute paths under $SRC (or '-*')" >&2
    exit 1
}

repo_provides_targets() {
    [ "${PROFILE:-cpp-cmake}" = cpp-cmake-targets ] && [ -f "$(src_dir)/cmake/CodeChecker.cmake" ]
}

# The output dir is a parameter, not $QC: the repo's cq_* targets bake it in at
# configure time, so each ref needs its own. README.md.
repo_target_flags() {     # repo_target_flags <output-dir> <skipfile>
    # CQ_ANALYZERS is forwarded so cq_analyze runs the manifest's set rather
    # than whatever the repo defaults to - FIXHub's default adds clang-tidy,
    # which the command route never runs, so the two routes disagreed. Spaces
    # become ";" because cmake wants a list; the ";" arrives by expansion and
    # is never re-parsed by the shell.
    local an=""
    if [ -n "${ANALYZERS:-}" ]; then
        an="-DCQ_ANALYZERS=$(printf '%s' "$ANALYZERS" | tr ' ' ';')"
    fi
    echo "-DCQ_OUTPUT_DIR=$1 -DCQ_SKIPFILE=$2 $an" \
         "-DCQ_CTEST_EXCLUDE=${TEST_EXCLUDE:-} -DCQ_BASELINE_REF=$BASELINE_REF"
}

# --verbose, not --output-on-failure: with -fsanitize-recover a reporting test
# still exits 0, and on-failure prints nothing for a passing test.
run_tests() {             # run_tests <build-dir> <log> [runner]
    local b=$1 log=$2 runner=${3:-}
    $runner ctest --test-dir "$b" ${TEST_EXCLUDE:+-E "$TEST_EXCLUDE"} \
            --verbose > "$log" 2>&1 || true
    grep -qE '[0-9]+/[0-9]+ Test +#' "$log" \
        || { echo "[cq] ctest executed no tests in $b - a zero finding count would be vacuous" >&2
             tail -20 "$log" >&2; exit 1; }
    printf '[cq] '
    grep -oE '[0-9]+% tests passed, [0-9]+ tests failed out of [0-9]+' "$log" | tail -1
}

# Strips ctest's line-number prefix, which stops the asan parser matching, and
# normalises the pid, which otherwise lands in the report hash. README.md.
normalise_sanitizer_log() {   # normalise_sanitizer_log <log>
    sed -i -E -e 's/^[0-9]+: //' \
        -e 's/^(WARNING: ThreadSanitizer: .*)[(]pid=[0-9]+[)]/==0==\1(pid=0)/' "$1"
}

# A sanitizer that failed to apply reports nothing, which looks exactly like a
# clean run - so prove the runtime is linked before trusting a zero count.
require_instrumentation() {   # require_instrumentation <build-dir> <sym>...
    local b=$1; shift
    local syms="$b/.syms"
    find "$b" -type f -perm -u+x -exec nm -D {} + 2>/dev/null > "$syms" || true
    local s
    for s in "$@"; do
        grep -q "$s" "$syms" \
            || { echo "[cq] $s absent - sanitizer did not apply; a zero finding count would be meaningless" >&2
                 exit 1; }
    done
    rm -f "$syms"
    echo "[cq] instrumentation verified ($*)"
}

# ---- static analysis + ASan + LSan + UBSan, from one compile ----------------
cq_analyse_memory() {     # cq_analyse_memory <reports-dir> <skipfile>
    local reports=$1 skip=$2
    local src; src="$(src_dir)"
    local b="$src/build" tgt=""
    # /qc-out/reports -> /qc-out ; /qc-out/baseline/reports -> /qc-out/baseline
    local outdir; outdir="$(dirname "$reports")"
    local log="$outdir/san-address+undefined.log"
    mkdir -p "$reports" "$outdir"
    if repo_provides_targets; then tgt="$(repo_target_flags "$outdir" "$skip")"; fi

    # address+undefined is a supported pair; thread is rejected alongside
    # address, and coverage needs -O0, so those two stay separate.
    cmake -S "$src" -B "$b" ${CONFIGURE_FLAGS} ${SANITIZER_FLAGS} ${tgt} \
          -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
          -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined -fsanitize-recover=address $SAN_DEBUG -O1" \
          -DCMAKE_C_FLAGS="-fsanitize=address,undefined -fsanitize-recover=address $SAN_DEBUG -O1" \
          -DCMAKE_EXE_LINKER_FLAGS="-fsanitize=address,undefined"
    cmake --build "$b" -j"$(build_jobs)"
    test -f "$b/compile_commands.json" \
        || { echo "[cq] no compile_commands.json - the repo contract is not met" >&2; exit 1; }

    if repo_provides_targets; then
        cmake --build "$b" --target cq_analyze
        cmake --build "$b" --target cq_sanitize
    else
        # A sanitized compile DB yields the same findings as a plain one.
        CodeChecker analyze "$b/compile_commands.json" -o "$reports" \
            --analyzers ${ANALYZERS} --ignore "$skip" \
            --clean --no-missing-checker-error || true

        require_instrumentation "$b" __asan_ __ubsan_
        export ASAN_OPTIONS="detect_leaks=1:halt_on_error=0:print_stacktrace=1"
        export UBSAN_OPTIONS="print_stacktrace=1:halt_on_error=0"
        run_tests "$b" "$log"
        normalise_sanitizer_log "$log"
        # One parser per sanitizer; asan is not lsan.
        local t
        for t in asan lsan ubsan; do
            report-converter -t "$t" -o "$reports" "$log" || true
        done
    fi
    rm -rf "$b"
    echo "[cq] memory pass done, build tree removed -> $reports"
}

# ---- coverage ---------------------------------------------------------------
cq_measure_coverage() {
    local src; src="$(src_dir)"
    local b="$src/build-cov" tgt=""
    mkdir -p "$QC/coverage"
    if repo_provides_targets; then
        tgt="$(repo_target_flags "$QC" /etc/cq/skipfile.txt)"
        # -DCQ_COVERAGE=ON instruments the targets the repo listed, PRIVATE;
        # global coverage flags here would silently widen that scope.
        cmake -S "$src" -B "$b" ${CONFIGURE_FLAGS} ${tgt} -DCQ_COVERAGE=ON -DCMAKE_BUILD_TYPE=Debug
    else
        cmake -S "$src" -B "$b" ${CONFIGURE_FLAGS} -DCMAKE_BUILD_TYPE=Debug \
              -DCMAKE_CXX_FLAGS="-g -O0 -fno-inline --coverage" \
              -DCMAKE_C_FLAGS="-g -O0 -fno-inline --coverage" \
              -DCMAKE_EXE_LINKER_FLAGS="--coverage"
    fi
    cmake --build "$b" -j"$(build_jobs)"

    ctest --test-dir "$b" ${TEST_EXCLUDE:+-E "$TEST_EXCLUDE"} \
          --output-junit "$QC/ctest-junit.xml" --output-on-failure || true
    ctest --test-dir "$b" -N > "$QC/tests-registered.txt" 2>&1 || true

    if repo_provides_targets; then
        cmake --build "$b" --target cq_coverage
        cmake --build "$b" --target cq_coverage_diff || true
    else
        # No .gcda means the tests never ran; 0% would be a false measurement.
        test "$(find "$b" -name '*.gcda' | wc -l)" -gt 0 \
            || { echo "[cq] no .gcda - tests did not run; coverage would be a false 0%" >&2; exit 1; }

        # Build trees and tests are platform policy; vendored paths are repo
        # knowledge and arrive in COVERAGE_EXCLUDE (cq.yaml: coverage_exclude).
        local ex=(--exclude '.*/build.*/.*' --exclude '.*/tests?/.*')
        # set -f: these are regexes, and an unquoted expansion globs them.
        set -f
        local _p
        for _p in ${COVERAGE_EXCLUDE:-}; do ex+=(--exclude "$_p"); done
        set +f
        # ignore-parse-errors: gcov emits 'branch N taken -1' for inlined code
        # and gcovr treats it as fatal, writing no report at all.
        gcovr --root "$src" "${ex[@]}" \
              --merge-mode-functions=separate --gcov-ignore-parse-errors=negative_hits.warn \
              --xml "$QC/coverage/cobertura.xml" --txt "$QC/coverage/coverage.txt" "$b" || true
        test -s "$QC/coverage/cobertura.xml" \
            || { echo "[cq] gcovr produced no cobertura.xml - coverage is BROKEN, not 0%" >&2; exit 1; }
        cd "$src"
        diff-cover "$QC/coverage/cobertura.xml" --compare-branch "$BASELINE_REF" \
            --format json:"$QC/coverage/diff-cover.json",html:"$QC/coverage/diff-cover.html" || true
    fi
    python3 /etc/cq/mk-newcode-cobertura.py \
        "$QC/coverage/diff-cover.json" "$QC/coverage/cobertura-newcode.xml" || true
    rm -rf "$b"
    echo "[cq] coverage pass done, build tree removed -> $QC/coverage"
}

# ---- TSan: built here, executed later by cq_run_thread ----------------------
cq_build_thread() {       # cq_build_thread <tag> <skipfile>
    # Separate statements: bash expands every word of `local` before running it,
    # so $tag on the same line would still be unset under set -u.
    local tag=$1 skip=$2
    local src; src="$(src_dir)"
    local b="$src/build-tsan-$tag" tgt=""
    # Baked in at configure time, so the tag has to pick the directory here.
    local outdir; [ "$tag" = baseline ] && outdir="$QC/baseline" || outdir="$QC"
    mkdir -p "$outdir"
    if repo_provides_targets; then tgt="$(repo_target_flags "$outdir" "$skip")"; fi
    cmake -S "$src" -B "$b" ${CONFIGURE_FLAGS} ${SANITIZER_FLAGS} ${tgt} \
          -DCMAKE_BUILD_TYPE=Debug \
          -DCMAKE_CXX_FLAGS="-fsanitize=thread $SAN_DEBUG -O1" \
          -DCMAKE_C_FLAGS="-fsanitize=thread $SAN_DEBUG -O1" \
          -DCMAKE_EXE_LINKER_FLAGS="-fsanitize=thread"
    cmake --build "$b" -j"$(build_jobs)"
    require_instrumentation "$b" __tsan_

    # Nothing later needs the objects: ctest runs the executables and
    # cq_sanitize relinks nothing. Measured 814MB -> ~200MB.
    find "$b" -name '*.o' -delete
    echo "[cq] thread tree kept for the run step ($(du -sh "$b" | cut -f1)) -> $b"
}
