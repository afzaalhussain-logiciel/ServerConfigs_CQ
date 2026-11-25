# Step 1 of 3 - build and analyse, in ONE image.
#
# Three trees, not five: address+undefined share a compile, thread cannot
# (the compiler rejects address+thread) and coverage cannot (it wants
# -O0 -fno-inline, and a sanitizer abort destroys the .gcda).
#
# Trees A and B are deleted in the SAME RUN that built them. A delete in a
# later layer leaves the bytes in the earlier one and the image does not
# shrink at all - which is what keeps this image small.
#
# Tree C (thread) survives: TSan calls personality(ADDR_NO_RANDOMIZE) and
# cannot execute during a build, so step 2 runs it with seccomp relaxed.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Baked in so no later step can disagree with the build about what it analysed.
# Only the publish target and the credential are supplied at run time.
ARG REPO_URL
ARG TARGET_REF
ARG BASELINE_REF=main
ARG NEED_BASELINE=0
ARG JOBS
ARG ANALYZERS="clangsa cppcheck"
ARG CONFIGURE_FLAGS=""
ARG SANITIZER_FLAGS=""
ARG TEST_EXCLUDE=""
ARG COVERAGE_EXCLUDE=""
ARG PREPARE=""
ARG SKIPFILE=""
ARG PRODUCT=""
ARG PROFILE=cpp-cmake
ARG MAX_NEW_HIGH=0
ARG MIN_DIFF_COV=0

ENV SRC=/src QC=/qc-out \
    TARGET_REF=${TARGET_REF} BASELINE_REF=${BASELINE_REF} NEED_BASELINE=${NEED_BASELINE} \
    JOBS=${JOBS} ANALYZERS=${ANALYZERS} \
    CONFIGURE_FLAGS=${CONFIGURE_FLAGS} SANITIZER_FLAGS=${SANITIZER_FLAGS} \
    TEST_EXCLUDE=${TEST_EXCLUDE} COVERAGE_EXCLUDE=${COVERAGE_EXCLUDE} \
    PREPARE=${PREPARE} SKIPFILE=${SKIPFILE} \
    PRODUCT=${PRODUCT} MAX_NEW_HIGH=${MAX_NEW_HIGH} MIN_DIFF_COV=${MIN_DIFF_COV} PROFILE=${PROFILE}

COPY stages.sh  /etc/cq/stages.sh
COPY tsan.sh    /etc/cq/tsan.sh
COPY analyze.sh /etc/cq/analyze.sh
COPY skipfile-default.txt /etc/cq/skipfile-default.txt
COPY mk-newcode-cobertura.py   /etc/cq/mk-newcode-cobertura.py

RUN --mount=type=ssh <<'BASH'
set -eux
mkdir -p -m 0700 /root/.ssh
ssh-keyscan github.com >> /root/.ssh/known_hosts 2>/dev/null

# Only the refs this build needs; a full clone drags in every branch.
fetch_ref() {
    git fetch -q --no-tags origin "+refs/heads/$1:$2" 2>/tmp/f.err && return 0
    git fetch -q --no-tags origin "+refs/tags/$1:$2"  2>>/tmp/f.err && return 0
    grep -qiE 'permission denied|could not read' /tmp/f.err \
        && echo "[cq] cannot authenticate to origin:" >&2 \
        || echo "[cq] ref not found on origin: $1" >&2
    sed 's/^/[cq]   /' /tmp/f.err >&2
    return 1
}
git init -q "$SRC" && cd "$SRC" && git remote add origin "$REPO_URL"
fetch_ref "$TARGET_REF" refs/heads/cq-target
# diff-cover compares against this by name, and the baseline checkout below
# needs it too, so it is fetched even when the server already has the run.
fetch_ref "$BASELINE_REF" "refs/heads/$BASELINE_REF" || true
git checkout -q --detach refs/heads/cq-target
git submodule update --init --recursive --depth 1 --jobs 1
git log -1 --oneline
BASH

# The repo owns its scope in a single first-match-wins skipfile.
#
# ssh: PREPARE may fetch a dependency the repo does not vendor, and the
# baseline's prepare already runs with the agent mounted - without it here the
# same hook authenticates for one ref and not the other.
RUN --mount=type=ssh <<'BASH'
set -eux
mkdir -p "$QC"
if [ -n "${SKIPFILE:-}" ] && [ -f "$SRC/$SKIPFILE" ]; then
    echo "[cq] skipfile: $SKIPFILE (repo)"
    cp "$SRC/$SKIPFILE" /etc/cq/skipfile.txt
else
    echo "[cq] skipfile: platform default (repo ships none)"
    cp /etc/cq/skipfile-default.txt /etc/cq/skipfile.txt
fi
. /etc/cq/stages.sh
require_absolute_rules /etc/cq/skipfile.txt
cd "$SRC"
[ -n "${PREPARE:-}" ] && { echo "[cq] prepare: $PREPARE"; eval "$PREPARE"; } || echo "[cq] prepare: (none)"
BASH

# Target: tree A, then tree B, then tree C. One RUN per tree so each delete
# lands in the layer that created the files.
RUN <<'BASH'
set -eux
. /etc/cq/stages.sh
cq_analyse_memory "$QC/reports" /etc/cq/skipfile.txt
BASH

RUN <<'BASH'
set -eux
. /etc/cq/stages.sh
cq_measure_coverage
BASH

RUN <<'BASH'
set -eux
. /etc/cq/stages.sh
cq_build_thread target /etc/cq/skipfile.txt
BASH

# Baseline, only when the server has no run for it or a refresh was asked for.
# Coverage is skipped: changed-line coverage is a property of the diff, and the
# monolithic design already treated the baseline this way.
#
# Needs the ssh mount: a fresh worktree has no submodule checkouts, so
# `submodule update` clones them, and without the key that fails with
# "Permission denied (publickey)". The clone layer's known_hosts persists.
RUN --mount=type=ssh <<'BASH'
set -eux
if [ "${NEED_BASELINE:-0}" != 1 ]; then
    echo "[cq] baseline already stored - not analysing ${BASELINE_REF}"
    exit 0
fi
. /etc/cq/stages.sh

# Its OWN checkout, not a checkout of $SRC. Both refs are stored after the
# build (TSan forces that), and CodeChecker store hashes the files a report
# references - so if $SRC held the baseline, storing the TARGET's reports would
# fail with "source file contents changed". A worktree shares the object store,
# so this costs a source tree (~11MB), not a clone.
git -C "$SRC" worktree add -q --detach "$BASE_SRC" "refs/heads/${BASELINE_REF}"
cd "$BASE_SRC"
git submodule update --init --recursive --depth 1 --jobs 1
echo "[cq] baseline ${BASELINE_REF} at $(git rev-parse --short HEAD) in $BASE_SRC"
[ -n "${PREPARE:-}" ] && eval "$PREPARE" || true
export CQ_SRC="$BASE_SRC"
# The baseline's OWN scope, from its own checkout, so a stored baseline run is
# a function of the baseline ref alone and not of whichever target refreshed
# it. Rules are written against $SRC, so only the checkout prefix is
# substituted; a rule outside it ("-/usr/*") and the closing "-*" stay put.
if [ -n "${SKIPFILE:-}" ] && [ -f "$BASE_SRC/$SKIPFILE" ]; then
    base_sf="$BASE_SRC/$SKIPFILE"
else
    base_sf=/etc/cq/skipfile.txt
    echo "[cq] baseline ${BASELINE_REF} ships no skipfile - using the target's"
fi
require_absolute_rules "$base_sf"
sed -E "s|^([+-])$SRC/|\1$BASE_SRC/|" "$base_sf" > /etc/cq/skipfile-baseline.txt
cq_analyse_memory "$QC/baseline/reports" /etc/cq/skipfile-baseline.txt
cq_build_thread baseline /etc/cq/skipfile-baseline.txt
BASH

CMD ["bash", "/etc/cq/tsan.sh"]
