/* Lab 1 sealed core -- shared declarations. GIVEN; nothing to change.
 *
 * Three implementations of one job: sum values[0..n) with nthreads threads and
 * return the total. Same signature for all three on purpose -- the shape of the
 * answer is not a hint about the shape of the defect.
 *
 *   run_given   src/given.c   the code you were handed. DO NOT EDIT: hashed.
 *   run_fixed   src/fixed.c   your minimal correction.
 *   run_alt     src/alt.c     the alternative named in BRIEF.md.
 */
#ifndef COSC407_SUM_H
#define COSC407_SUM_H

#define MAX_THREADS 64

long long run_given(const long long *values, long long n, int nthreads);
long long run_fixed(const long long *values, long long n, int nthreads);
long long run_alt  (const long long *values, long long n, int nthreads);

#endif /* COSC407_SUM_H */
