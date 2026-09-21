/* Lab 1, core A -- YOUR MINIMAL CORRECTION.
 *
 * run_fixed() must be exactly correct at 1, 2, 4 and 8 threads, every time.
 *
 * "Minimal" hides two questions -- which REGION must be protected, and how
 * OFTEN you pay to protect it. They do not have the same answer. BRIEF.md S2.3.
 *
 * Copy anything you like out of given.c. Do not edit it.
 */
#include <pthread.h>
#include <stdio.h>

#include "sum.h"

/* TODO: whatever shared state your correction needs. */

/* TODO: the per-thread task struct. What does a thread own here, and what does
 *       it share? Write it down before you write the struct. */

/* TODO: the worker. */

long long run_fixed(const long long *values, long long n, int nthreads)
{
    /* TODO: create the threads, join them, and return the total.
     *
     * Remember the two things given.c also has to do and does correctly:
     * initialise whatever you are locking with before any thread can reach it,
     * and destroy it after every thread has been joined. */
    (void)values;
    (void)n;
    (void)nthreads;
    return -1;
}
