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
static volatile long long total;
static pthread_mutex_t lock;

/* TODO: the per-thread task struct. What does a thread own here, and what does
 *       it share? Write it down before you write the struct. */
typedef struct {
    int             id;
    long long       begin;      /* this thread's slice, [begin, end) */
    long long       end;
    const long long *values;
} arg_t;

/* TODO: the worker. */
static void *worker(void *p)
{
    arg_t *a = (arg_t *)p;
    long long sum = 0;

    for (long long i = a->begin; i < a->end; i++) {
        sum += a->values[i];
    }

    pthread_mutex_lock(&lock);
    total += sum;
    pthread_mutex_unlock(&lock);

    return NULL;
}

long long run_fixed(const long long *values, long long n, int nthreads)
{
    pthread_t tid[MAX_THREADS];
    arg_t     args[MAX_THREADS];

    total = 0;

    if (pthread_mutex_init(&lock, NULL) != 0) {
        fprintf(stderr, "pthread_mutex_init failed\n");
        return -1;
    }

    for (int i = 0; i < nthreads; i++) {
        args[i].id     = i;
        args[i].begin  = (long long)i * n / nthreads;
        args[i].end    = (long long)(i + 1) * n / nthreads;
        args[i].values = values;

        if (pthread_create(&tid[i], NULL, worker, &args[i]) != 0) {
            fprintf(stderr, "pthread_create failed\n");
            return -1;
        }
    }

    for (int i = 0; i < nthreads; i++) {
        pthread_join(tid[i], NULL);
    }
    
    pthread_mutex_destroy(&lock);
    

    return total;
}
