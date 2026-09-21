#!/usr/bin/env bash
# COSC 407/507 Lab 1, sealed core -- the checks the autograder runs.
#
#   bash tests/run_tests.sh all       everything (default)
#   bash tests/run_tests.sh fixed     one group at a time
#   bash tests/run_tests.sh score     a running total of the pure-script rows
#                                     only (68 possible) -- see the comment
#                                     above test_score() before reading this
#                                     number as anything more than that
#
# Groups: given (src/given.c unmodified), fixed, alt, speed, report.
#
# This script is IDENTICAL in all four cores. What differs is tests/expect.env,
# which says what your core's given code and alternative are supposed to do.
# Green here is not full marks: most of this lab is the reasoning in RESULTS.md
# and the oral test, and no script can see either.

set -u

WHICH="${1:-all}"
FAILED=0

N=2000001              # deliberately not divisible by 2, 4 or 8
MARGIN=1.3             # a timing claim has to win by this much to count

BIN=""

# expect.env is sourced AFTER those defaults, so a core whose brief names a
# different n (a cache-resident one, say) can override N here.
# shellcheck disable=SC1091
. tests/expect.env

# Threshold for the T3 unit-coverage check below. Set in expect.env per core
# if a different value than this default is wanted.
UNIT_COV_THRESHOLD="${UNIT_COV_THRESHOLD:-70}"

pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; FAILED=1; }
info() { printf '  ....  %s\n' "$1"; }

# Sets BIN, or reports a failure and returns 1. Deliberately NOT written as
# BIN="$(need_bin)": a command substitution runs in a subshell, so a FAILED=1
# set inside it is thrown away and a missing binary would report a silent pass.
need_bin() {
    if [ -x ./sum ];       then BIN=./sum
    elif [ -x ./sum.exe ]; then BIN=./sum.exe
    else
        fail "sum was not built -- run 'make' and fix the compile errors first"
        return 1
    fi
    return 0
}

# field <line> <name>  ->  the value of name= in that output line
field() { printf '%s\n' "$1" | sed -n "s/.*[[:space:]]$2=\([^[:space:]]*\).*/\1/p"; }

# best_of <repeats> <mode>  ->  the fastest time= over that many runs at 4
# threads. One run of a fast thing tells you nothing -- that is Lab 0's whole
# point, and it applies to the autograder too.
best_of() {
    local i out t bestv=""
    for i in $(seq "$1"); do
        out="$("$BIN" "$2" 4 "$N" 2>&1)"
        t="$(field "$out" time)"
        [ -z "$t" ] && continue
        if [ -z "$bestv" ] || awk -v a="$t" -v b="$bestv" 'BEGIN{exit !(a < b)}'; then
            bestv="$t"
        fi
    done
    printf '%s' "$bestv"
}

# ------------------------------------------------------- given unmodified ---
test_given() {
    echo "src/given.c -- must be byte for byte as issued"
    local want have
    if [ ! -f tests/given.sha256 ]; then
        fail "tests/given.sha256 is missing from your repository"
        return
    fi
    want="$(cut -d' ' -f1 tests/given.sha256)"
    have="$(sha256sum src/given.c | cut -d' ' -f1)"
    if [ "$want" = "$have" ]; then
        pass "src/given.c is unmodified"
    else
        fail "src/given.c has been edited. Restore it: 'git checkout src/given.c'."
        info "your report has to compare against the code you were handed, so this"
        info "check is worth its own marks and it is not negotiable"
    fi
}

# ---------------------------------------------------------------- fixed -----
test_fixed() {
    echo "src/fixed.c -- your minimal correction"
    local t out
    need_bin || return

    for t in 1 2 4 8; do
        out="$("$BIN" fixed "$t" "$N" 2>&1)"
        if printf '%s\n' "$out" | grep -q 'correct=yes'; then
            pass "./sum fixed $t $N is exactly correct"
        else
            fail "./sum fixed $t $N must be exactly correct; got: $out"
        fi
    done

    # run the 8-thread case a few more times: correct once is not correct.
    local bad=0 i
    for i in 1 2 3 4 5; do
        out="$("$BIN" fixed 8 "$N" 2>&1)"
        printf '%s\n' "$out" | grep -q 'correct=yes' || bad=1
    done
    if [ "$bad" -eq 0 ]; then
        pass "./sum fixed 8 $N is still correct after five more runs"
    else
        fail "./sum fixed 8 $N is not correct every time -- a fix that works sometimes is not a fix"
    fi
}

# ------------------------------------------------------------------ alt -----
test_alt() {
    echo "src/alt.c -- $ALT_LABEL"
    local out
    need_bin || return

    out="$("$BIN" alt 4 "$N" 2>&1)"
    if [ "$ALT_CORRECT" = yes ]; then
        if printf '%s\n' "$out" | grep -q 'correct=yes'; then
            pass "./sum alt 4 $N is correct, as your brief says it should be"
        else
            fail "./sum alt 4 $N should be correct; got: $out"
        fi
    else
        if printf '%s\n' "$out" | grep -q 'correct=no'; then
            pass "./sum alt 4 $N is still WRONG -- which is the point your brief makes"
        else
            fail "./sum alt 4 $N came out correct. Re-read your brief: this alternative"
            fail "is supposed to leave the defect in place. Got: $out"
        fi
    fi
}

# ---------------------------------------------------------------- speed -----
test_speed() {
    echo "the measurement your brief asks for"
    local out ta tb a b ratio
    need_bin || return

    if [ "$SPEED_CHECK" = none ]; then
        out="$("$BIN" all 4 "$N" 2>&1)"
        info "no timing claim is auto-checked for this core; the numbers are:"
        printf '%s\n' "$out" | sed 's/^/        /'
        pass "timings recorded (the marks for the measurement are in RESULTS.md)"
        return
    fi

    a="${SPEED_CHECK%%_faster_than_*}"
    b="${SPEED_CHECK##*_faster_than_}"

    # best of three, each side. One run of a fast thing tells you nothing --
    # that is Lab 0's whole point, and it applies to the autograder too.
    ta="$(best_of 3 "$a")"
    tb="$(best_of 3 "$b")"

    if [ -z "$ta" ] || [ -z "$tb" ]; then
        fail "could not read the timings back out of ./sum -- is it printing the whole line?"
        return
    fi

    ratio="$(awk -v x="$ta" -v y="$tb" 'BEGIN{ if (x > 0) printf "%.1f", y / x; else print "inf" }')"
    if awk -v x="$ta" -v y="$tb" -v m="$MARGIN" 'BEGIN{ exit !(y > x * m) }'; then
        pass "at 4 threads, $a ($ta s) beats $b ($tb s) by ${ratio}x"
    else
        fail "at 4 threads, $a ($ta s) should be clearly faster than $b ($tb s)"
        info "if your $a is correct but not faster, you have fixed the answer without"
        info "fixing the mechanism -- which is exactly what RESULTS.md asks you to notice"
    fi
}

# --------------------------------------------------------------- report -----
# section <file> <heading-prefix> : the body of one '## ' section with fenced
# code blocks, block quotes, table rows and the bold prompt lines removed, so
# that a word count means "words the student wrote".
section() {
    awk -v h="$2" '
        $0 ~ "^## " h { inside = 1; next }
        /^## /        { inside = 0 }
        inside        { print }
    ' "$1" | awk '
        /^```/    { fence = !fence; next }
        fence     { next }
        /^>/      { next }
        /^\|/     { next }
        /^\*\*/   { next }
        /REPLACE/ { next }
                  { print }
    '
}

words() { grep -oE '[A-Za-z]+' | wc -l; }

need_words() {   # need_words <min> <got> <what>
    if [ "$2" -ge "$1" ]; then
        pass "$3 is written ($2 words)"
    else
        fail "$3 is too short ($2 words, expected at least $1)"
    fi
}

test_report_prediction() {
    if [ ! -f PREDICTION.md ]; then
        fail "PREDICTION.md is missing. It is due at 0:20, before you compile anything."
        return
    fi
    if grep -q 'REPLACE THIS LINE' PREDICTION.md; then
        fail "PREDICTION.md still contains a 'REPLACE THIS LINE' placeholder"
    else
        pass "no placeholders left in PREDICTION.md"
    fi
    local w
    w="$(sed '/^>/d;/^\*\*/d;/^#/d;/^|/d' PREDICTION.md | words)"
    need_words 55 "$w" "the prediction sheet"
}

test_report_results_other() {
    if [ ! -f RESULTS.md ]; then
        fail "RESULTS.md is missing"
        return
    fi
    if grep -q 'REPLACE THIS LINE' RESULTS.md; then
        fail "RESULTS.md still contains a 'REPLACE THIS LINE' placeholder"
    else
        pass "no placeholders left in RESULTS.md"
    fi
    local disc
    disc="$(sed -n 's/^[Tt]ools and sources:[[:space:]]*//p' RESULTS.md | head -1)"
    if [ -n "$disc" ] && ! printf '%s' "$disc" | grep -q 'REPLACE'; then
        pass "the tools-and-sources disclosure is filled in"
    else
        fail "RESULTS.md must state your tools and sources, or say explicitly you used none"
    fi
    if grep -qiE '^[[:space:]]*[Cc]ores:[[:space:]]*[0-9]+' RESULTS.md; then
        pass "the machine's core count is recorded"
    else
        fail "RESULTS.md must record how many cores this machine has -- a timing without a machine is not a measurement"
    fi
    local w
    w="$(section RESULTS.md 'S2' | words)"; need_words 80 "$w" "the S2 diagnosis"
    w="$(section RESULTS.md 'S3' | words)"; need_words 90 "$w" "the S3 attribution"
}

test_report_given3() {
    [ -f RESULTS.md ] || { fail "RESULTS.md is missing"; return; }
    local ng
    ng="$(awk '/^## S2/{f=1;next} /^## /{f=0} f' RESULTS.md | grep -c 'mode=given')"
    if [ "$ng" -ge 3 ]; then
        pass "S2 pastes $ng runs of the code you were handed"
    else
        fail "S2 must paste at least 3 runs of ./sum given (found $ng)"
    fi
}

test_report_twelve() {
    [ -f RESULTS.md ] || { fail "RESULTS.md is missing"; return; }
    local nm
    nm="$(awk '/^## S3/{f=1;next} /^## /{f=0} f' RESULTS.md | grep -c 'mode=')"
    if [ "$nm" -ge 12 ]; then
        pass "S3 pastes $nm timed runs"
    else
        fail "S3 must paste all twelve runs -- given, fixed and alt at 1, 2, 4 and 8 threads (found $nm)"
    fi
}

test_report_explainback() {
    [ -f RESULTS.md ] || { fail "RESULTS.md is missing"; return; }
    local w
    w="$(section RESULTS.md 'S4' | words)"; need_words 25 "$w" "the explain-back answer"
}

test_report() {
    echo "PREDICTION.md and RESULTS.md"
    test_report_prediction
    test_report_results_other
    test_report_given3
    test_report_twelve
    test_report_explainback
}

# ---------------------------------------------------------------------------
# T1-T4 of the rubric (Part 2, testing). Not wired into the `all` group above
# and not run by `make test` -- graded separately, by the `unit-testing` job
# in .github/workflows/autograde.yml.

test_unit() {
    if [ ! -f tests/unit_test.c ]; then
        fail "tests/unit_test.c does not exist"
        return
    fi
    nf="$(grep -c 'Test(fixed,' tests/unit_test.c)"
    na="$(grep -c 'Test(alt,'   tests/unit_test.c)"
    if [ "$nf" -ge 3 ]; then
        pass "tests/unit_test.c has $nf cases for run_fixed"
    else
        fail "tests/unit_test.c needs at least 3 cases for run_fixed (found $nf)"
    fi
    if [ "$na" -ge 3 ]; then
        pass "tests/unit_test.c has $na cases for run_alt"
    else
        fail "tests/unit_test.c needs at least 3 cases for run_alt (found $na)"
    fi

    if make unit-test >/tmp/unit_test.out 2>&1; then
        pass "make unit-test -- all of your own cases pass"
    else
        fail "make unit-test -- at least one of your own cases fails or does not compile"
        tail -20 /tmp/unit_test.out
    fi
}

test_unitcov() {
    if ! make unit-coverage >/tmp/unit_cov.out 2>&1; then
        fail "make unit-coverage did not run -- fix tests/unit_test.c first"
        tail -20 /tmp/unit_cov.out
        return
    fi
    pct="$(grep -oE '^lines: *[0-9]+(\.[0-9]+)?' /tmp/unit_cov.out | grep -oE '[0-9]+(\.[0-9]+)?')"
    if [ -z "$pct" ]; then
        fail "could not read a coverage percentage from make unit-coverage's output"
        return
    fi
    # Integer comparison is enough here; a fractional percent either side of
    # the threshold is not worth the extra complexity of float comparison.
    pct_i="${pct%.*}"
    if [ "$pct_i" -ge "$UNIT_COV_THRESHOLD" ]; then
        pass "make unit-coverage: ${pct}% (threshold ${UNIT_COV_THRESHOLD}%)"
    else
        fail "make unit-coverage: ${pct}%, below the ${UNIT_COV_THRESHOLD}% threshold"
    fi
}

test_mutationcheck() {
    # Pass/fail on whether mutation testing RAN and reported something --
    # deliberately not on the mutation score itself. Two reasons, found while
    # building this: (1) one specific mutation on core C's alt.c can hit this
    # tool's own time bound rather than completing, through no fault of the
    # student's code; (2) core B's alt.c is SUPPOSED to fail most mutations,
    # so no single numeric threshold applies to every core. A partial/bounded
    # run is treated as a pass -- see the "stopped after" message it prints
    # when that happens.
    ok=1
    for target in mutation-fixed mutation-alt; do
        make "$target" >"/tmp/mutation_$target.out" 2>&1
        if grep -q "^SKIPPING $target" "/tmp/mutation_$target.out"; then
            fail "$target: skipped -- your fixed.c/alt.c does not pass make test yet"
            ok=0
        elif grep -qE "Mutation score|stopped after" "/tmp/mutation_$target.out"; then
            pass "$target ran and reported a result"
        else
            fail "$target did not produce a recognizable result"
            tail -20 "/tmp/mutation_$target.out"
            ok=0
        fi
    done
    [ "$ok" -eq 1 ]
}
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# `score` -- a running total against ONLY the rows lab1-rubric.md itself
# calls pure script rows (not the two it calls "mixed": the measurement and
# table-complete rows, where a script can confirm presence but not whether
# it's actually correct -- those are left out of this number on purpose, not
# missed by accident). 18 from Part 1 + 50 from Part 2 = 68 possible.
#
# This is NOT the lab mark. It is the ~68% of it a script can ever see. The
# other ~32 (S1's P1-P3/P4, S2.1/S2.2/S2.3, S3.1/S3.2, S4's "names wrong +
# cost") plus the oral multiplier are not computed here, and cannot be --
# they require reading prose and judging quality, which nothing on this page
# does. Treat a high number here as "the mechanical parts are in order", not
# as a grade.
#
# Runs each row's checks in its own subshell so one row's local variables
# and FAILED state never leak into the next row's count -- each row is
# scored purely on whether ITS OWN checks all passed, independent of every
# other row.
row() {   # row <label> <marks> <function...>
    local label="$1" marks="$2" rc; shift 2
    if ( FAILED=0; "$@" >/dev/null 2>&1; rc=$?; [ "$rc" -eq 0 ] && [ "$FAILED" -eq 0 ] ); then
        printf '  %3d / %-3d  %s\n' "$marks" "$marks" "$label"
        SCORE=$((SCORE + marks))
    else
        printf '  %3d / %-3d  %s\n' 0 "$marks" "$label"
    fi
    POSSIBLE=$((POSSIBLE + marks))
}

test_score() {
    SCORE=0
    POSSIBLE=0

    # Build once, quietly, so every row below sees a consistent ./sum.
    make >/dev/null 2>&1

    echo "Part 1 -- sealed core (script-checked rows only)"
    row "PREDICTION.md present, no placeholder, written"   2  test_report_prediction
    row "given.c unmodified"                                2  test_given
    row "3+ given runs pasted"                              2  test_report_given3
    row "fixed exactly correct, all 9 runs"                 6  test_fixed
    row "twelve runs pasted"                                2  test_report_twelve
    row "alt behaves as brief says"                         2  test_alt
    row "explain-back present"                              2  test_report_explainback
    echo
    echo "Part 2 -- testing"
    row "T1: 3+ cases each for run_fixed/run_alt"          10  test_unit_count
    row "T2: make unit-test -- all cases pass"             10  test_unit_pass
    row "T3: unit-coverage >= threshold"                   15  test_unitcov
    row "T4: mutation-fixed and mutation-alt both ran"     15  test_mutationcheck
    echo
    echo "Script-checked score: $SCORE / $POSSIBLE"
    echo "This is not the lab mark -- see the comment at the top of this section."

    if ! grep -q 'REPLACE' RESULTS.md 2>/dev/null; then
        disc="$(sed -n 's/^[Tt]ools and sources:[[:space:]]*//p' RESULTS.md 2>/dev/null | head -1)"
        if [ -z "$disc" ] || printf '%s' "$disc" | grep -q 'REPLACE'; then
            echo "NOTE: no tools-and-sources disclosure -- this is an automatic zero for"
            echo "the whole lab per lab1-rubric.md, regardless of the number above."
        fi
    fi
}

# test_unit() bundles T1 and T2's criteria together (it was written before
# scoring needed to tell them apart). These two give `row` a way to check
# each one alone, without changing test_unit()'s own output above.
test_unit_count() {
    [ -f tests/unit_test.c ] || { fail "tests/unit_test.c does not exist"; return; }
    local nf na
    nf="$(grep -c 'Test(fixed,' tests/unit_test.c)"
    na="$(grep -c 'Test(alt,'   tests/unit_test.c)"
    [ "$nf" -ge 3 ] && [ "$na" -ge 3 ]
}

test_unit_pass() {
    make unit-test >/dev/null 2>&1
}
# ---------------------------------------------------------------------------

case "$WHICH" in
    given)  test_given ;;
    fixed)  test_fixed ;;
    alt)    test_alt ;;
    speed)  test_speed ;;
    report) test_report ;;
    unit)          test_unit ;;
    unitcov)       test_unitcov ;;
    mutationcheck) test_mutationcheck ;;
    score)  test_score; exit 0 ;;
    all)    test_given; echo; test_fixed; echo; test_alt; echo
            test_speed; echo; test_report ;;
    *)      echo "usage: $0 [all|given|fixed|alt|speed|report|unit|unitcov|mutationcheck|score]" >&2; exit 2 ;;
esac

echo
if [ "$FAILED" -eq 0 ]; then
    echo "all checks passed for: $WHICH"
else
    echo "there are failures above for: $WHICH"
fi
exit "$FAILED"
