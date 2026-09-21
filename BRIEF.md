# Sealed core **A**

Read `lab1-core.md` first. Other sections were given a different core.

```sh
make
./sum given 1 10000001     # always start with one thread
./sum given 8 10000001     # twice
```

**The alternative** (`src/alt.c`): **one single mutex, shared by every thread**,
locked and unlocked once per element, around the update of the shared total. It
is correct, and on any machine you will run it on it is a bad idea. Writing it
lets you say exactly how bad and exactly why — because *"the smallest region
that must be protected"* and *"the cheapest way to protect it"* are different
questions with different answers.

**Your four questions, for this core**

- **S2.1 mechanism.** Which claim in the header is false, and what is the machine
  doing? `total += values[i]` is one line of C and more than one operation.
- **S2.2 proof.** An interleaving of **two** threads, as two columns of steps,
  that loses an update. Then: why the loss changes between runs, and why one
  thread never shows it.
- **S2.3 minimality.** The smallest region that must be inside the critical
  section, **and** how many times your `fixed` enters it. Justify both numbers.
- **S3.2 ship it.** `fixed` and `alt` are both correct. Which ships, and what
  measurement would change your mind? No second half, half the marks.

**One question you may get in the oral.** *Show me the two lines that can
interleave badly, and walk me through one interleaving that gives the wrong
answer.*
