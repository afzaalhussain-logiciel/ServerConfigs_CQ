#!/usr/bin/env bash
# Step 2 of 3 - execute TSan, for whichever trees the build kept. Needs a
# relaxed seccomp profile, which is the whole reason this step is not part of
# the docker build. README.md.
#
#   docker run --rm --security-opt seccomp=unconfined -v out:/qc-out IMG \
#       bash /etc/cq/tsan.sh
set -eu
. /etc/cq/stages.sh

cq_run_thread() {          # cq_run_thread <tag> <reports-dir>
    local tag=$1 reports=$2
    local src; src="$(src_dir_for "$tag")"
    local b="$src/build-tsan-$tag" log
    [ -d "$b" ] || { echo "[cq] no TSan tree for $tag - skipping"; return 0; }
    mkdir -p "$reports"
    # The directory the tree was configured with, so both routes agree per ref.
    log="$(dirname "$reports")/san-thread-$tag.log"

    # TSan dies under ASLR. Measured: 10/10 starts with setarch, 0-2/10 without.
    local runner=""
    setarch -R true 2>/dev/null && runner="setarch -R" || {
        echo "[cq] thread: cannot disable ASLR - this step needs --security-opt seccomp=unconfined" >&2
        exit 1; }

    if CQ_SRC="$src" repo_provides_targets; then
        $runner cmake --build "$b" --target cq_sanitize
    else
        export TSAN_OPTIONS="halt_on_error=0"
        run_tests "$b" "$log" "$runner"
        normalise_sanitizer_log "$log"
        report-converter -t tsan -o "$reports" "$log" || true
    fi
    echo "[cq] thread ($tag) done -> $reports"
}

cq_run_thread target "$QC/reports"
cq_run_thread baseline "$QC/baseline/reports"
echo "[cq] tsan step complete -> $QC"
