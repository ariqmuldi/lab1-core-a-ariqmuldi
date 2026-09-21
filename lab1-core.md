# Lab 1 — the sealed core

**100 marks · due at the end of your period · no AI, none, see `lab1-part-a-public.md` · 1 page**

**At 0:10 read only three things: this page, `BRIEF.md`, and `src/given.c`.**
That is about six minutes of the ten, which leaves four to think and write.
`README.md` and the two forms can wait until after 0:20 — they hold nothing
you need in order to predict.

## The three files

| | |
|---|---|
| `src/given.c` | someone's threaded array sum, with **exactly one defect**. Its header says what they believed; one of those claims is false. **Do not edit it** — it is hashed, and your report compares against it. |
| `src/fixed.c` | **your minimal correction.** |
| `src/alt.c` | **the alternative `BRIEF.md` names.** Not necessarily better; in one core not even correct. |

`src/main.c` is given: it builds the array, checks against `n(n+1)/2`, times each
mode and prints one line. `lost` is `expected - actual`, and a *negative* `lost`
means something was counted twice.

```
./sum given 8 10000001      # also: fixed, alt, or all
mode=given threads=8 n=10000001 expected=50000015000001 actual=9735867234428 lost=40264147765573 correct=no time=0.2473
```

## First move: which kind of wrong is it?

Run it at 1 thread, then twice at 8. Your defect either gives **the wrong
answer** — diagnosed by argument: interleavings, coverage, the one-thread
control — or **the right answer far too slowly**, which only a *timing table*
can find, because every correctness test passes. Deciding which is the most
expensive mistake available to you today.

## What to hand in

| | | marks |
|---|---|---|
| **S1** | `PREDICTION.md`, **pushed by 0:20 on its own commit**, before you compile. Marked on having predicted and on reconciling it in S3.1 — **not on being right.** | 15 |
| **S2** | The diagnosis in `RESULTS.md`: name the mechanism, prove it in the form your brief requires, and argue your fix is minimal — what breaks with less, what it costs with more. | 40 |
| **S3** | Twelve runs — all three modes at 1, 2, 4, 8 threads — pasted and tabulated. Reconcile with S1. Then: which would you ship, **and what measurement would change your mind?** | 30 |
| **S4** | Explain-back, two or three sentences: what was wrong, and what did fixing it cost? | 15 |

Ask for more threads than you have cores. That is deliberate.

## The clock

0:10 read · **0:20 push the prediction** · 0:50 S2 written while the evidence is
in front of you · 1:10 the twelve runs and S3 · 1:20 S4, `make test`, push.

**Still hunting at 0:50? Ask your TA.** It costs you nothing and a hint then is
worth far more than a blank S3. If you never find it, hand in what you ruled out
and how — a well-argued failed diagnosis earns real marks; a blank page does not.

`lab mark = automated mark × oral multiplier`, capped at 100. `make test` runs
exactly the machine-checked part, which is about 47 of the 100.
