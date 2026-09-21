# COSC 407/507 Lab 1 — the sealed core
#
#   make            build ./sum
#   make test       run the same checks the autograder runs
#   make verify     check that src/given.c is still byte-for-byte as issued
#   make coverage   TA/optional: how much of fixed.c/alt.c the checks exercise
#   make mutation   TA/optional: how good those checks are at catching bugs
#   make clean      remove the binary and everything the two targets above leave behind
#
# coverage and mutation are NOT part of the graded, timed exercise and are not
# mentioned in BRIEF.md on purpose -- make test/make verify are the entire
# automated mark, unchanged by anything below. These two exist for whoever
# maintains this core, to sanity-check that tests/run_tests.sh would actually
# catch a broken fixed.c/alt.c, using a correct fixed.c/alt.c as the
# thing to check it against. Running them against an in-progress student
# submission is harmless but not the point -- do not advertise these to
# students during the lab period; they cost real minutes out of a fixed
#80-minute clock for no rubric marks.
#
# -pthread is not optional: it sets the compile-time flags AND links the
# threading library. Using -lpthread alone works on some systems and silently
# misbehaves on others.

CC      := gcc
CFLAGS  := -std=gnu11 -O2 -Wall -Wextra -Iinclude
LDFLAGS := -pthread

OBJSRC  := src/main.c src/given.c src/fixed.c src/alt.c

.PHONY: all test verify clean coverage mutation mutation-fixed mutation-alt

all: sum

sum: $(OBJSRC) include/sum.h include/timer.h
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJSRC)

test: all
	bash tests/run_tests.sh all

verify:
	bash tests/run_tests.sh given

clean:
	rm -f sum sum.exe
	rm -f *.gcda *.gcno *.bc *.i.bc *.o

# --- Coverage ----------------------------------------------------------
# Only src/fixed.c and src/alt.c are measured: given.c is fixed/hashed and
# main.c is given, so coverage on either would just measure the harness, not
# anyone's work. Runs the fixed+alt checks (not given/speed/report -- those
# do not exercise fixed.c/alt.c any further) against a --coverage build.
COV_CFLAGS := -std=gnu11 -O0 -g -Wall -Wextra -Iinclude --coverage

coverage:
	$(CC) $(COV_CFLAGS) $(LDFLAGS) -o sum $(OBJSRC)
	-bash tests/run_tests.sh fixed
	-bash tests/run_tests.sh alt
	gcovr --root . --filter 'src/fixed\.c' --filter 'src/alt\.c' -s
	rm -f sum *.gcda *.gcno

# --- Mutation ------------------------------------------------------------
# Mutates ONE of fixed.c/alt.c at a time (the other three files -- main.c,
# given.c, and whichever of fixed.c/alt.c is not being mutated -- are compiled
# normally and linked in unchanged), then reruns the matching test group as
# the oracle. A mutant that survives means that check would not have noticed
# that bug -- this is a check on tests/run_tests.sh, not on the reference
# code, and a nonzero survivor count is normal.
#
# Needs clang (not gcc) for LLVM bitcode, and mull-instrument-18/
# mull-runner-18 from the course devcontainer.
#
# IMPORTANT: a mutation of mutex-handling code (or, on core C, the PASSES
# loop) can produce a genuine infinite loop instead of a wrong answer -- same
# as a real bug like that would hang at the terminal. Two things are combined
# to handle this, and neither one alone is sufficient:
#
#   1. TESTKILL below wraps the actual test invocation in a coreutils
#      `timeout --kill-after`, confirmed (by deliberately hanging a mutant by
#      hand) to correctly kill an ordinary hung ./sum within ~4s.
#   2. Empirically, at least one specific mutation on core C's alt.c (an
#      increment-to-decrement swap on the PASSES loop counter) escapes BOTH
#      that wrapper and mull-runner's own --timeout, leaving an orphaned
#      ./sum process behind no matter how those two are tuned. This looks like
#      mull detaching its test subprocess into its own session, which no
#      amount of external process-group timeout wrapping can then reach --
#      only a kill targeted at the binary's exact name works reliably
#      (confirmed: `pkill -9 -x sum`, not `pkill -f`, which was unreliable
#      here). This was investigated at reasonable length and not fully
#      root-caused; treat it as a known limitation of this toolchain rather
#      than something the next person should assume is easy to fix properly.
#
# Given (2), this Makefile does not try to guarantee every mutant completes.
# Instead: MULL_BOUND caps the WHOLE recipe's wall-clock time, and the recipe
# ALWAYS runs `pkill -9 -x sum` immediately after, regardless of whether mull
# finished normally or was stopped by the bound -- so a hung mutant costs you
# up to MULL_BOUND seconds and a "this was likely a real hang" message, never
# an indefinitely stuck terminal or an orphaned process left running.
MCLANG      := clang
MCFLAGS     := -std=gnu11 -O0 -g -grecord-command-line -Iinclude
MULL_INSTR  := mull-instrument-18
MULL_RUN    := mull-runner-18
TESTKILL    := timeout --kill-after=2 8 bash
MULL_TIMEOUT:= 20000
# Overall ceiling on the whole mutation-fixed/mutation-alt recipe. A normal
# run finishes in a few seconds; this exists only as a last-resort backstop --
# see the note above about mull's own process handling.
MULL_BOUND  := 90

mutation: mutation-fixed mutation-alt

mutation-fixed: src/fixed.c include/sum.h include/timer.h
	@bash -c '$(CC) $(CFLAGS) $(LDFLAGS) -o sum $(OBJSRC) && bash tests/run_tests.sh fixed' >/dev/null 2>&1 || \
	  { echo "SKIPPING mutation-fixed: your fixed.c does not pass 'make test' (fixed group) yet."; \
	    echo "Mutation testing only means something once the real code passes --"; \
	    echo "get 'bash tests/run_tests.sh fixed' green first, then rerun this."; \
	    rm -f sum; exit 1; }
	rm -f sum
	$(CC) $(CFLAGS) -Iinclude -c src/main.c  -o main.o
	$(CC) $(CFLAGS) -Iinclude -c src/given.c -o given.o
	$(CC) $(CFLAGS) -Iinclude -c src/alt.c   -o alt.o
	$(MCLANG) $(MCFLAGS) -c -emit-llvm src/fixed.c -o fixed.bc
	$(MULL_INSTR) fixed.bc -o fixed.i.bc
	$(MCLANG) $(LDFLAGS) fixed.i.bc main.o given.o alt.o -o sum
	@timeout $(MULL_BOUND) $(MULL_RUN) --timeout $(MULL_TIMEOUT) --test-program bash ./sum -- -c "$(TESTKILL) tests/run_tests.sh fixed"; \
	  rc=$$?; \
	  pkill -9 -x sum >/dev/null 2>&1; \
	  if [ $$rc -eq 124 ]; then \
	    echo "mutation-fixed: stopped after ${MULL_BOUND}s -- one mutant likely produced a"; \
	    echo "genuine infinite loop that this tool could not cleanly interrupt (this is a"; \
	    echo "known limitation, not a sign your fixed.c is wrong). Any mutation score above"; \
	    echo "is partial. Any test binaries that mutant left running have been cleaned up."; \
	  fi
	rm -f sum *.o *.bc *.i.bc

mutation-alt: src/alt.c include/sum.h include/timer.h
	@bash -c '$(CC) $(CFLAGS) $(LDFLAGS) -o sum $(OBJSRC) && bash tests/run_tests.sh alt' >/dev/null 2>&1 || \
	  { echo "SKIPPING mutation-alt: your alt.c does not pass 'make test' (alt group) yet."; \
	    echo "Mutation testing only means something once the real code passes --"; \
	    echo "get 'bash tests/run_tests.sh alt' green first, then rerun this."; \
	    rm -f sum; exit 1; }
	rm -f sum
	$(CC) $(CFLAGS) -Iinclude -c src/main.c  -o main.o
	$(CC) $(CFLAGS) -Iinclude -c src/given.c -o given.o
	$(CC) $(CFLAGS) -Iinclude -c src/fixed.c -o fixed.o
	$(MCLANG) $(MCFLAGS) -c -emit-llvm src/alt.c -o alt.bc
	$(MULL_INSTR) alt.bc -o alt.i.bc
	$(MCLANG) $(LDFLAGS) alt.i.bc main.o given.o fixed.o -o sum
	@timeout $(MULL_BOUND) $(MULL_RUN) --timeout $(MULL_TIMEOUT) --test-program bash ./sum -- -c "$(TESTKILL) tests/run_tests.sh alt"; \
	  rc=$$?; \
	  pkill -9 -x sum >/dev/null 2>&1; \
	  if [ $$rc -eq 124 ]; then \
	    echo "mutation-alt: stopped after ${MULL_BOUND}s -- one mutant likely produced a"; \
	    echo "genuine infinite loop that this tool could not cleanly interrupt (this is a"; \
	    echo "known limitation, not a sign your alt.c is wrong). Any mutation score above"; \
	    echo "is partial. Any test binaries that mutant left running have been cleaned up."; \
	  fi
	rm -f sum *.o *.bc *.i.bc

# --- Unit tests (T1/T2 of the rubric) ---------------------------------
# tests/unit_test.c, if present, calls run_fixed()/run_alt() directly -- no
# subprocess, no output-parsing -- which is a stronger check than the
# black-box checks above. This is here for whoever is evaluating whether to
# add it to the rubric; it is NOT wired into `test` and BRIEF.md does not
# mention it. Needs libcriterion-dev, already in the course devcontainer.
UNIT_COV_CFLAGS := -std=gnu11 -O0 -g -Wall -Wextra -Iinclude --coverage

.PHONY: unit-test unit-coverage

unit-test: tests/unit_test.c src/fixed.c src/alt.c include/sum.h
	$(CC) $(CFLAGS) $(LDFLAGS) -o unit_test tests/unit_test.c src/fixed.c src/alt.c -lcriterion
	./unit_test --verbose
	rm -f unit_test

unit-coverage: tests/unit_test.c src/fixed.c src/alt.c include/sum.h
	$(CC) $(UNIT_COV_CFLAGS) $(LDFLAGS) -o unit_test_cov tests/unit_test.c src/fixed.c src/alt.c -lcriterion
	./unit_test_cov
	gcovr --root . --filter 'src/fixed\.c' --filter 'src/alt\.c' -s
	rm -f unit_test_cov *.gcda *.gcno
