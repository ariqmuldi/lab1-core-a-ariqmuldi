/* COSC 407/507 Lab 1, core A -- the code you were handed.
 *
 * *** DO NOT EDIT. *** It is hashed by the autograder, and your report has to
 * compare against the code you were handed. Work in fixed.c and alt.c.
 *
 * ---------------------------------------------------------------------------
 * What the author believed, in their own words:
 *
 *   "Several threads add into one shared accumulator, so the update has to be
 *    inside a critical section -- that part is not negotiable. But a single
 *    global mutex would make all the threads queue up behind each other, and
 *    the whole point of using threads is that they do not.
 *
 *    So each thread carries its own mutex, in its own task struct. Every update
 *    of the accumulator is locked, and no thread ever has to wait for another
 *    one, because no two threads are ever using the same lock. Correct, and it
 *    scales."
 *
 * Exactly one of the claims in that paragraph is false.
 * ---------------------------------------------------------------------------
 */
#include <pthread.h>
#include <stdio.h>

#include "sum.h"

/* SHARED between all the threads. `volatile` only stops the optimiser from
 * hoisting the accumulator into a register for the whole loop -- see Part A's
 * race_demo.c. It says nothing about threads. */
static volatile long long total;

typedef struct {
    int             id;
    long long       begin;      /* this thread's slice, [begin, end) */
    long long       end;
    const long long *values;
    pthread_mutex_t lock;       /* this thread's own mutex */
} arg_t;

static void *worker(void *p)
{
    arg_t *a = (arg_t *)p;

    for (long long i = a->begin; i < a->end; i++) {
        pthread_mutex_lock(&a->lock);
        total += a->values[i];
        pthread_mutex_unlock(&a->lock);
    }

    return NULL;
}

long long run_given(const long long *values, long long n, int nthreads)
{
    pthread_t tid[MAX_THREADS];
    arg_t     args[MAX_THREADS];

    total = 0;

    for (int i = 0; i < nthreads; i++) {
        args[i].id     = i;
        args[i].begin  = (long long)i * n / nthreads;
        args[i].end    = (long long)(i + 1) * n / nthreads;
        args[i].values = values;

        if (pthread_mutex_init(&args[i].lock, NULL) != 0) {
            fprintf(stderr, "pthread_mutex_init failed\n");
            return -1;
        }
        if (pthread_create(&tid[i], NULL, worker, &args[i]) != 0) {
            fprintf(stderr, "pthread_create failed\n");
            return -1;
        }
    }

    for (int i = 0; i < nthreads; i++) {
        pthread_join(tid[i], NULL);
    }
    for (int i = 0; i < nthreads; i++) {
        pthread_mutex_destroy(&args[i].lock);
    }

    return total;
}
