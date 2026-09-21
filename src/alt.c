/* Lab 1, core A -- THE ALTERNATIVE named in BRIEF.md.
 *
 * Correct, and expected to look bad. Do not try to make it fast: it is
 * evidence, not a submission.
 */
#include <pthread.h>
#include <stdio.h>

#include "sum.h"

/* TODO: the alternative described in BRIEF.md, §"The alternative". */
static volatile long long total;
static pthread_mutex_t lock;

typedef struct {
    int             id;
    long long       begin;      /* this thread's slice, [begin, end) */
    long long       end;
    const long long *values;
} arg_t;

static void *worker(void *p)
{
    arg_t *a = (arg_t *)p;

    for (long long i = a->begin; i < a->end; i++) {
        pthread_mutex_lock(&lock);
        total += a->values[i];
        pthread_mutex_unlock(&lock);
    }

    return NULL;

}

long long run_alt(const long long *values, long long n, int nthreads)
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
