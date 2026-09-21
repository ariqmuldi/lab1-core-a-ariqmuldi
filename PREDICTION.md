# Prediction sheet — push by 0:20, before you compile

> Marked on **having predicted** and on reconciling it in S3.1 — **not on being
> right.** A confident wrong prediction you then explain is full marks. A blank
> page is none. A page timestamped after your first run is worse than none.
>
> Read `src/given.c` and `BRIEF.md`. Run nothing.

Cores:  4 — from PREP.md
Lab 0 spread:  28.5 — the percentage, from PREP.md

> **P1.** `./sum given` on **one** thread — right answer? Yes/no, one sentence why.

mode=given threads=1 n=10000001 expected=50000015000001 actual=50000015000001 lost=0 correct=yes time=0.0715

This is right answer since it is only one thread, there is nothing else to interleave with regarding total so no updates get lost

> **P2.** On **8** threads — right answer? If not, how much of the total does it
> lose: a rounding error, a few percent, or most of it? Commit to a number.

mode=given threads=8 n=10000001 expected=50000015000001 actual=21894253900296 lost=28105761099705 correct=no time=0.1992

This is not the right answer. It loses 56% of the total

> **P3.** Three runs at 8 threads — **identical** answers, or different? Think
> about this one before you write it; it is the most useful line on the page.

mode=given threads=8 n=10000001 expected=50000015000001 actual=20508744662299 lost=29491270337702 correct=no time=0.2096
mode=given threads=8 n=10000001 expected=50000015000001 actual=22881745270272 lost=27118269729729 correct=no time=0.2169
mode=given threads=8 n=10000001 expected=50000015000001 actual=20240055758818 lost=29759959241183 correct=no time=0.1932

For each of the run, you can see that it is different everytime.

> **P4.** Seconds, before measuring. Orders of magnitude are what matter.

| | 1 thread | 8 threads |
|---|---|---|
| `given` | 0.0715 | 0.1992 |
| `fixed` | 0.02 | 0.01 |
| `alt` | 0.07 | 5 |

> **P5.** Fastest and slowest at 8 threads? If you expect any of them to get
> **slower** as threads are added, say which and why.

I think the slow because for alt, in the BRIEF.md, it says that it is "one single mutex, shared by every thread", meaning it would do more waiting
