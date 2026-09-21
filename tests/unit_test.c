/* Lab 1, core A -- YOUR OWN unit tests for run_fixed() and run_alt().
 *
 * PROPOSAL / DRAFT -- not part of the graded exercise yet. See BRIEF.md for
 * whether this term's core asks for this file.
 *
 * Unlike tests/run_tests.sh, which drives ./sum from the command line, these
 * tests call run_fixed() and run_alt() directly -- no subprocess, no parsing
 * printed output. That is a stronger, more precise check: you are testing the
 * function itself, not "the program printed the right line".
 *
 * One case is done for you, as a model. Write at least THREE MORE per
 * function, covering:
 *   - a small n you can check by hand (n=1, n=2)
 *   - nthreads = 1 (the control: no concurrency to get wrong)
 *   - nthreads > 1, including a case where n does not divide evenly
 *
 * Build and run: make unit-test
 */
#include <criterion/criterion.h>

#include "sum.h"

/* n(n+1)/2, the same check main.c uses, so your expected values are not typed
 * in twice with a chance to make the same mistake both places. */
static long long expected_sum(long long n)
{
    return n * (n + 1) / 2;
}

static long long *make_values(long long n)
{
    long long *v = malloc((size_t)n * sizeof *v);
    for (long long i = 0; i < n; i++) {
        v[i] = i + 1;
    }
    return v;
}

/* ---------------------------------------------------------- run_fixed --- */

/* WORKED EXAMPLE -- the pattern every case below follows: build an array,
 * call run_fixed() directly, assert against expected_sum(). */
Test(fixed, single_element_one_thread)
{
    long long *v = make_values(1);
    cr_assert_eq(run_fixed(v, 1, 1), expected_sum(1));
    free(v);
}

/* TODO: small_n_one_thread -- n=2, nthreads=1 */
Test(fixed, small_n_one_thread)
{
    cr_assert_fail("TODO: write this case -- see the worked example above");
}

/* TODO: uneven_division_multiple_threads -- pick an n that does NOT divide
 * evenly by your thread count. This is exactly the kind of case a slicing
 * bug hides in. */
Test(fixed, uneven_division_multiple_threads)
{
    cr_assert_fail("TODO: write this case -- see the worked example above");
}

/* TODO: at least one more case of your own choosing. Larger n, a different
 * thread count -- whatever you think is worth checking that the three cases
 * above do not already cover. */
Test(fixed, your_own_case)
{
    cr_assert_fail("TODO: write this case -- see the worked example above");
}

/* ------------------------------------------------------------ run_alt --- */

/* TODO: at least THREE cases for run_alt(), same coverage as above:
 * a small n, nthreads=1 as a control, and an uneven division. */
Test(alt, single_element_one_thread)
{
    cr_assert_fail("TODO: write this case -- see the worked example above");
}

Test(alt, small_n_one_thread)
{
    cr_assert_fail("TODO: write this case -- see the worked example above");
}

Test(alt, uneven_division_multiple_threads)
{
    cr_assert_fail("TODO: write this case -- see the worked example above");
}
