# Lab 1 — sealed core

**Read `lab1-core.md`, then `BRIEF.md`.** All 100 marks are here (50 sealed-core, 50 testing -- see below). Due at the end
of your lab period; no late submission.

**No AI in the lab. None** — not the C, not the prose, not "explain this error",
not the toolchain. Documentation, the textbooks, the notes and your TA are fine.
Declare what you used in `RESULTS.md` even if it is "none".

```sh
make
./sum given 1 10000001    # modes: given, fixed, alt, all
make test                 # what the autograder runs
make verify               # just the "given.c is unmodified" check
```

| | |
|---|---|
| `BRIEF.md` | your core. Different in each section. |
| `PREDICTION.md` | **push by 0:20**, on its own commit, before you compile |
| `RESULTS.md` | most of the marks |
| `src/given.c` | **do not edit** — hashed by the autograder |
| `src/fixed.c`, `src/alt.c` | you write these |
| `src/main.c`, `include/` | given and complete |
| `tests/` | the autograder's checks; identical in all four cores |

```sh
git add PREDICTION.md && git commit -m "prediction" && git push   # 0:20
make test
git add -A && git commit -m "Lab 1 core" && git push              # by 1:20
```

## Coverage, mutation, and unit testing — 50% of your grade

`tests/unit_test.c` is worth 50 of your 100 marks, split across four checks
(see `lab1-rubric.md`'s T1–T4). It doesn't replace the sealed-core work
above — it's graded in addition to it, on the same repo, same push.

Run these before you push — they're the exact commands the autograder runs:

```sh
bash tests/run_tests.sh unit           # T1 (3+ cases each) + T2 (all pass)     -- 20 marks
bash tests/run_tests.sh unitcov        # T3 (coverage vs. the threshold below)   -- 15 marks
bash tests/run_tests.sh mutationcheck  # T4 (mutation-fixed and mutation-alt ran) -- 15 marks
```

Or run the underlying `make` targets directly while you're writing tests,
though these three don't by themselves confirm what's graded (e.g. `make
unit-test` passing isn't enough for T1 on its own, since T1 also requires at
least 3 cases per function):

```sh
make coverage        # how much of fixed.c/alt.c the CLI checks above exercise
make unit-test        # run YOUR OWN tests/unit_test.c directly against fixed.c/alt.c
make unit-coverage     # how much of fixed.c/alt.c YOUR OWN unit tests exercise
make mutation         # how good the checks above actually are at catching bugs
```

A few things worth knowing before you write these:

- `tests/unit_test.c` has one worked example per function already, as a
  model — the rest are `TODO` stubs that fail on purpose until you write
  them. You need at least 3 cases each for `run_fixed` and `run_alt` (T1).
- `make coverage` measures the existing black-box checks (`run_tests.sh`);
  `make unit-coverage` measures only your own `tests/unit_test.c` — they're
  answering different questions and will report different numbers. T3 is
  graded on `unit-coverage`, not `coverage`.
- `make mutation` needs `fixed.c`/`alt.c` to already pass `make test` first —
  it skips cleanly with a message if they don't. Get your sealed-core fix
  working before attempting T4.
- `make mutation` can occasionally take up to ~90 seconds and print a
  "stopped after Ns" message on one specific mutation this toolchain can't
  always interrupt cleanly, on any core. That still counts as T4 passing —
  it's a known toolchain limitation, not a sign your code is wrong.
