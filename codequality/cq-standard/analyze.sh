#!/usr/bin/env bash
# Step 3 of 3 - store, diff, verdict. Builds nothing. Runs AFTER the TSan step,
# or the gate would score a report set with no races in it.
#
#   docker run -e CC_URL=... -e CC_PASS_FILE=/run/secrets/cc_pass.json \
#              -v out:/qc-out -v pass.json:/run/secrets/cc_pass.json:ro \
#              IMG bash /etc/cq/analyze.sh
#
#   /qc-out/reports           the target's, always
#   /qc-out/baseline/reports  the baseline's, when the pipeline produced one
set -eu

: "${CC_URL:?CC_URL is required}"
PRODUCT_URL="$CC_URL/$PRODUCT"

run_exists() { CodeChecker cmd runs --url "$PRODUCT_URL" -o json 2>/dev/null | grep -q "\"$1\""; }

# `probe <ref>`: has the server a run for that ref already? Matches the NAME
# only, so a moved branch or a changed checker set still counts as present -
# REFRESH_BASELINE is the manual answer.
if [ "${1:-}" = probe ]; then
    run_exists "$2" && echo 0 || echo 1
    exit 0
fi
# CodeChecker diffs by file path, and the baseline has its own checkout: trim
# each store to the same relative paths or every finding looks net-new.
store()      { CodeChecker store "$1" --name "$2" --url "$PRODUCT_URL" --trim-path-prefix "${3:-$SRC}"; }

# CC_PASS_FILE carries client_autologin so every command re-authenticates:
# a session lasts session_lifetime seconds and a store can outlive that.

# analyze leaves its skipfile here and store would re-apply it to the converted
# sanitizer plists, dropping every race. README.md.
rm -f "$QC/reports/skip_file" "$QC/baseline/reports/skip_file"

CodeChecker parse "$QC/reports" \
    --trim-path-prefix "$SRC" > "$QC/codechecker.txt" 2>/dev/null || true

store "$QC/reports" "$TARGET_REF"
run_exists "$TARGET_REF" \
    || { echo "[cq] target run not stored - findings cannot be measured" >&2; exit 1; }

# No delete step: store REPLACES a run, so storing fresh reports IS the refresh.
if [ -d "$QC/baseline/reports" ]; then
    echo "[cq] storing the baseline this build produced"
    store "$QC/baseline/reports" "$BASELINE_REF" "${BASE_SRC:-/src-baseline}" || true
fi

BASE=no
run_exists "$BASELINE_REF" && BASE=yes \
    || echo "[cq] no baseline run on the server - findings unmeasured" >&2

mkdir -p "$QC/gate"
NEW=unmeasured
[ "$BASE" = yes ] && NEW=$(CodeChecker cmd diff --url "$PRODUCT_URL" \
    -b "$BASELINE_REF" -n "$TARGET_REF" --new -o json 2>/dev/null | python3 -c '
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(0); raise SystemExit
r=d if isinstance(d,list) else d.get("reports",[])
print(sum(1 for x in r if str(x.get("severity","")).upper() in ("HIGH","CRITICAL")
          or x.get("severity") in (40,50)))' 2>/dev/null || echo unmeasured)

COV=$(python3 -c "
import xml.etree.ElementTree as ET
print(round(float(ET.parse('$QC/coverage/cobertura.xml').getroot().get('line-rate'))*100,2))" 2>/dev/null || echo unmeasured)
# total_num_lines is the COVERABLE changed lines; num_changed_lines counts YAML
# and docs too, which would make a config-only commit report 100% from nothing.
read -r DIFF_COV DIFF_STATE <<EOF
$(python3 - "$QC/coverage/diff-cover.json" <<'PY' 2>/dev/null || echo " unmeasured"
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    print(" unmeasured"); raise SystemExit
if not d.get("total_num_lines"):
    print(" nolines")
else:
    print(d["total_percent_covered"], "ok")
PY
)
EOF


# unmeasured is never a pass: a diff with no baseline returns an empty set,
# which is indistinguishable from "no new findings".
STATUS=PASS
[ "$NEW" = unmeasured ] && STATUS=FAIL
[ "$NEW" = unmeasured ] || [ "$NEW" -le "${MAX_NEW_HIGH:-0}" ] || STATUS=FAIL
case "$DIFF_STATE" in
    ok)      awk "BEGIN{exit !($DIFF_COV >= ${MIN_DIFF_COV:-0})}" || STATUS=FAIL ;;
    nolines) ;;   # the diff touches no coverable line - the threshold cannot apply
    *)       STATUS=FAIL ;;
esac

{
echo "======== CODE QUALITY GATE ========="
printf '  product        %s\n'         "$PRODUCT"
printf '  run / baseline %s / %s\n'    "$TARGET_REF" "$BASELINE_REF"
printf '  baseline       %s\n'         "$BASE"
printf '  NET new HIGH   %-8s <= %s\n' "$NEW" "${MAX_NEW_HIGH:-0}"
printf '  new-code cov   %-8s >= %s\n' "${DIFF_COV:-$DIFF_STATE}" "${MIN_DIFF_COV:-0}"
printf '  overall cov    %s\n'         "$COV"
printf '  GATE           %s\n'         "$STATUS"
echo "===================================="
} | tee "$QC/gate/summary.txt"

# One line, for the Jenkins build list and the build page. The banner above is
# for the console and the artifact; a multi-line description renders badly.
printf 'GATE %s  new-high %s/%s  new-cov %s/%s  overall %s  %s vs %s\n' \
    "$STATUS" "$NEW" "${MAX_NEW_HIGH:-0}" "${DIFF_COV:-$DIFF_STATE}" \
    "${MIN_DIFF_COV:-0}" "$COV" "$TARGET_REF" "$BASELINE_REF" \
    | tee "$QC/gate/verdict.txt"
