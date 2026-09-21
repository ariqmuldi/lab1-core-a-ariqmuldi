/* COSC 407/507 -- wall-clock timer used by every lab this term.
 *
 * now_seconds() returns a monotonic wall-clock reading in seconds. Monotonic
 * matters: the wall clock can jump backwards when the system clock is adjusted,
 * and a negative interval in a timing table is a bug you will be asked about.
 *
 * Always time an interval as (now_seconds() - t0), never an absolute value.
 */
#ifndef COSC407_TIMER_H
#define COSC407_TIMER_H

#include <time.h>

static inline double now_seconds(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + 1e-9 * (double)ts.tv_nsec;
}

#endif /* COSC407_TIMER_H */
