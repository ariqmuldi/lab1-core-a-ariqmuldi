/* Lab 1 sealed core -- the driver. GIVEN and complete. No marks in this file,
 * and nothing here to change; skim it and move on.
 *
 *   ./sum given 8 10000001        the code you were handed
 *   ./sum fixed 8 10000001        your correction
 *   ./sum alt   8 10000001        the alternative in BRIEF.md
 *   ./sum all   8 10000001        all three, in that order
 *
 * It builds the array, checks against n(n+1)/2 (computed a different way, so
 * the check is real), times each mode and prints one fixed-format line that
 * your report pastes and the autograder reads. `lost` is expected - actual;
 * a NEGATIVE lost means something was counted twice, which is a different bug.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "timer.h"
#include "sum.h"

typedef long long (*runner_t)(const long long *, long long, int);

static void one_run(const char *name, runner_t fn, const long long *values,
                    long long n, int nthreads, long long expected)
{
    double t0 = now_seconds();
    long long actual = fn(values, n, nthreads);
    double elapsed = now_seconds() - t0;

    printf("mode=%s threads=%d n=%lld expected=%lld actual=%lld lost=%lld "
           "correct=%s time=%.4f\n",
           name, nthreads, n, expected, actual, expected - actual,
           (actual == expected) ? "yes" : "no", elapsed);
    fflush(stdout);
}

int main(int argc, char **argv)
{
    if (argc < 4) {
        fprintf(stderr, "usage: %s <given|fixed|alt|all> <nthreads> <n>\n", argv[0]);
        return 1;
    }

    const char *mode = argv[1];
    int  nthreads    = (int)strtol(argv[2], NULL, 10);
    long long n      = strtoll(argv[3], NULL, 10);

    if (nthreads < 1 || nthreads > MAX_THREADS || n < 1) {
        fprintf(stderr, "bad arguments: 1 <= nthreads <= %d, n >= 1\n", MAX_THREADS);
        return 1;
    }

    long long *a = malloc((size_t)n * sizeof *a);
    if (a == NULL) {
        fprintf(stderr, "not enough memory for %lld elements\n", n);
        return 1;
    }
    for (long long i = 0; i < n; i++) {
        a[i] = i + 1;
    }

    /* 1 + 2 + ... + n, computed a completely different way, so that this is a
     * real check on the parallel sum rather than the same code run twice. */
    long long expected = n * (n + 1) / 2;

    int unknown = 0;
    if      (strcmp(mode, "given") == 0) one_run("given", run_given, a, n, nthreads, expected);
    else if (strcmp(mode, "fixed") == 0) one_run("fixed", run_fixed, a, n, nthreads, expected);
    else if (strcmp(mode, "alt")   == 0) one_run("alt",   run_alt,   a, n, nthreads, expected);
    else if (strcmp(mode, "all")   == 0) {
        one_run("given", run_given, a, n, nthreads, expected);
        one_run("fixed", run_fixed, a, n, nthreads, expected);
        one_run("alt",   run_alt,   a, n, nthreads, expected);
    } else {
        fprintf(stderr, "unknown mode '%s'\n", mode);
        unknown = 1;
    }

    free(a);
    return unknown;
}
