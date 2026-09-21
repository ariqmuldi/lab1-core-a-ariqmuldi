# Lab 1 results — sealed core

Name:  Ariq Muldi
Student number:  20149347
Lab section:  L01
Core:  A — the letter on BRIEF.md
Machine:  Codespace
Cores:  4 — an integer

## Tools and sources

Tools and sources: Google

> Mandatory, even if it says "none". **No AI in the lab, at all** — see the
> README. Missing declaration: zero until you supply one. False one: misconduct.

## S2 — the defect · 40 marks

Three or more runs of `./sum given` at the `n` your brief names, including one
thread:

```
mode=given threads=1 n=10000001 expected=50000015000001 actual=50000015000001 lost=0 correct=yes time=0.0715
mode=given threads=8 n=10000001 expected=50000015000001 actual=21894253900296 lost=28105761099705 correct=no time=0.1992
mode=given threads=8 n=10000001 expected=50000015000001 actual=20508744662299 lost=29491270337702 correct=no time=0.2096
mode=given threads=8 n=10000001 expected=50000015000001 actual=22881745270272 lost=27118269729729 correct=no time=0.2169
mode=given threads=8 n=10000001 expected=50000015000001 actual=20240055758818 lost=29759959241183 correct=no time=0.1932
```

**S2.1** Name the mechanism: which claim in `given.c`'s header is false, and what
is the machine doing?

The part that is false is when they say "and no thread ever has to wait for another". The reason why this is false is because
of the lost data that happens when incrementing total. It arises from this line of code: total += a->values[i]; This does the
 load, add, store together.

Two threads can load the same value of total add it to its own to some stale copy when it isn't supposed to be stale and then
that thread's contribution is gone

**S2.2** Prove it, in the form your `BRIEF.md` requires.

Lets say:
Thread A gets its lock and then loads a total of 100
Thread B gets its lock and then loads a total of 100
B then gets added a value of 5 in to its total and then unlocks
However for A is still at 100 and then gets added a value of 3 in to its total and then unlocks
The final value of total is 103 here, not 105

Since they are in different mutexes, A was getting a read from when it registers its total to be 100 before B's write existed

**S2.3** Minimality: what breaks if you do less, what it costs if you do more.

What breaks if you do less: The code just breaks because the load, add, store for total is still broken

What it costs if you do more: We need to fix the load, add, store, which means probably putting more logic into a loop, possibly
making the code slower overall

## S3 — the measurement · 30 marks

`./sum all <t> <n>` at 1, 2, 4 and 8 threads. Pasted, not retyped.

```
make
./sum all 1 10000001
./sum all 2 10000001
./sum all 4 10000001
./sum all 8 10000001
gcc -std=gnu11 -O2 -Wall -Wextra -Iinclude -pthread -o sum src/main.c src/given.c src/fixed.c src/alt.c
mode=given threads=1 n=10000001 expected=50000015000001 actual=50000015000001 lost=0 correct=yes time=0.0730
mode=fixed threads=1 n=10000001 expected=50000015000001 actual=50000015000001 lost=0 correct=yes time=0.0048
mode=alt threads=1 n=10000001 expected=50000015000001 actual=50000015000001 lost=0 correct=yes time=0.0845
mode=given threads=2 n=10000001 expected=50000015000001 actual=39855847382212 lost=10144167617789 correct=no time=0.1268
mode=fixed threads=2 n=10000001 expected=50000015000001 actual=50000015000001 lost=0 correct=yes time=0.0038
mode=alt threads=2 n=10000001 expected=50000015000001 actual=50000015000001 lost=0 correct=yes time=0.2223
mode=given threads=4 n=10000001 expected=50000015000001 actual=31310744753244 lost=18689270246757 correct=no time=0.1896
mode=fixed threads=4 n=10000001 expected=50000015000001 actual=50000015000001 lost=0 correct=yes time=0.0025
mode=alt threads=4 n=10000001 expected=50000015000001 actual=50000015000001 lost=0 correct=yes time=0.4356
mode=given threads=8 n=10000001 expected=50000015000001 actual=21506589771955 lost=28493425228046 correct=no time=0.1854
mode=fixed threads=8 n=10000001 expected=50000015000001 actual=50000015000001 lost=0 correct=yes time=0.0031
mode=alt threads=8 n=10000001 expected=50000015000001 actual=50000015000001 lost=0 correct=yes time=0.4278
```

| threads | given: correct? | given: time | fixed: time | alt: time |
|---|---|---|---|---|
| 1 | yes | 0.0730 | 00048 | 0.0845 |
| 2 | no | 0.1268 | 0.0038 | 0.223 |
| 4 | no | 0.1896 | 0.0025 | 0.4356 |
| 8 | no | 0.1854 | 0.0031 | 0.4278 |

**S3.1** Reconcile with `PREDICTION.md`: quote what you predicted, say what
happened, account for the difference. If you were right, say what would have
made you wrong.

P1 predicted correct at 1 thread. P2 predicted wrong at 8 threads. P3 predicted different every run. P4 I had some wrong
predictions here. Fixed was much faster than predicted and alt was also much faster than what I predicted. This might have
something to do with vectorization since it is going through the elements across the threads. For P5, I predicted slowest 
for alt and I was correct for that one. For the things I got right, what would probably have made me wrong was if I didn't 
understand how the mutex would lock the threads, just the concept of it

**S3.2** Which would you ship on this machine, **and what measurement would
change your mind?**

I would ship the fixed.c because the time to complete is much much faster. That time measurement and also the fact that we have lost=0 would make me change my mind

## S4 — explain-back · 15 marks

> Two or three sentences, your own words: someone who has not seen this code
> asks *what was wrong with it, and what did fixing it cost?*

So the reason that code was wrong was because of how the data was overriding each other, or rather, not having the correct updates with each other because of how a thread was locked on its own mutex. Fixing this costed just making some code around, not anything
too major

## Anything you got stuck on

Optional. One or two lines.
