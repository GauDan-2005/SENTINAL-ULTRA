`statrs` gives Rust users a solid set of probability distributions and statistical functions, but it is thin on classical hypothesis testing. People doing everyday inference in Rust keep dropping down to Python and scipy for the most common significance tests, and there is a standing request for a native Mann-Whitney U test (see https://users.rust-lang.org/t/mann-whitney-u-test/95005). Grow the public `statrs::stats_tests` module into a hypothesis testing toolkit people can actually use, by adding six tests: a Pearson chi-square goodness of fit test, a one-way ANOVA F-test, a Mann-Whitney U test, a one-sample t-test, a skewness test, and an Anderson-Darling goodness of fit test. Each one returns the test statistic together with its p-value.

The tests that take `f64` samples need a shared way of handling `NaN` input, so `statrs::stats_tests` also gains a public enum:

```rust
pub enum NaNPolicy {
    Propogate,
    Emit,
    Error,
}
```

Under `Propogate` a sample containing `NaN` still gives a successful result, with `NaN` for both the statistic and the p-value. Under `Emit` the `NaN` values are dropped and everything downstream sees only what is left, so filtering can shrink a sample below the size that test requires. Under `Error` the call fails with that test's own NaN error variant. The pre-existing `Alternative` enum, with `TwoSided`, `Less` and `Greater`, picks the tail on the tests that offer one. Both enums are reachable as `statrs::stats_tests::{Alternative, NaNPolicy}`.

Pearson's chi-square goodness of fit test:

```rust
pub fn chisquare(
    f_obs: &[usize],
    f_exp: Option<&[f64]>,
    ddof: Option<usize>,
) -> Result<(f64, f64), ChiSquareTestError>
```

`f_obs` holds the observed counts per category. When `f_exp` is `None` the expected frequencies are equal across the categories, and when it is supplied it is used as given. `ddof` defaults to zero and reduces the degrees of freedom, which start at one less than the number of categories. `ChiSquareTestError` carries `FObsInvalid` when `f_obs` does not have more than one category, `FExpInvalid` when a supplied `f_exp` does not match the length and the total of `f_obs`, and `DdofInvalid` when `ddof` is `f_obs.len() - 1` or larger, so with six categories four is the largest value accepted. An input that breaks more than one of those reports them in the order listed here.

One-way ANOVA F-test:

```rust
pub fn f_oneway(
    samples: Vec<Vec<f64>>,
    nan_policy: NaNPolicy,
) -> Result<(f64, f64), FOneWayTestError>
```

`samples` is the collection of groups being compared. Fewer than two groups is `NotEnoughSamples` whatever the groups hold, so it outranks the NaN rules. `SampleContainsNaN` follows, for `NaN` data under the `Error` policy.

The last two rules read whatever data survives an `Emit` filter, and they have an order of their own. `SampleTooSmall` comes first, when any group is empty or when no group holds at least two values. `SampleContainsSameConstants` follows, and one such group is enough on its own: if any group longer than one value repeats a single value throughout, the call fails even when every other group varies. Filtering can decide which of the two a caller sees, since dropping every value out of a group makes it empty rather than constant.

Mann-Whitney U test:

```rust
pub fn mannwhitneyu<T: PartialOrd + Clone>(
    x: &[T],
    y: &[T],
    method: MannWhitneyUMethod,
    alternative: Alternative,
) -> Result<(f64, f64), MannWhitneyUError>
```

It returns the U statistic for `x` and the p-value for the requested alternative. `MannWhitneyUMethod` offers `Exact` for the exact p-value, `AsymptoticInclContinuityCorrection` and `AsymptoticExclContinuityCorrection` for the normal approximation with and without a continuity correction, and `Automatic`, which chooses between them. Ties are counted across the two samples pooled together, not within either one.

`Automatic` takes the exact route unless both samples hold more than eight values, and the continuity corrected approximation when both are larger than that or when the pooled data has ties. So a pairing like nine values against five still goes the exact route, because only one of the two samples is over the threshold. That size threshold belongs to `Automatic` alone: asking for `Exact` outright carries no size limit and has to give the exact answer at any size.

`MannWhitneyUError` carries `SampleTooSmall` when either sample is empty, `UncomparableData` when a pair of input values cannot be ordered against each other, and `ExactMethodWithTiesInData` when `Exact` is asked for on data that has ties. Those three are reported in that order, so an empty sample is named even when the other sample also holds unorderable values. This function takes no NaN policy, because `T` is generic and need not have a `NaN` at all.

One-sample t-test:

```rust
pub fn ttest_onesample(
    a: Vec<f64>,
    popmean: f64,
    alternative: Alternative,
    nan_policy: NaNPolicy,
) -> Result<(f64, f64), TTestOneSampleError>
```

It compares the sample `a` against the population mean `popmean` and returns the t statistic and the p-value for the requested alternative. `TTestOneSampleError` carries `SampleTooSmall` when fewer than two values are left to work with and `SampleContainsNaN` for a `NaN` under the `Error` policy.

Skewness test:

```rust
pub fn skewtest(
    a: Vec<f64>,
    alternative: Alternative,
    nan_policy: NaNPolicy,
) -> Result<(f64, f64), SkewTestError>
```

It asks whether the skew of `a` differs from the skew of a normal distribution and returns the z score and the p-value for the requested alternative. The sample needs at least eight observations once any `NaN` filtering has happened, and a shorter one is `SampleTooSmall`. `SkewTestError` also carries `SampleContainsNaN` for a `NaN` under the `Error` policy.

Anderson-Darling goodness of fit test:

```rust
pub fn anderson_darling<T: ContinuousCDF<f64, f64>>(
    a: Vec<f64>,
    dist: &T,
    nan_policy: NaNPolicy,
) -> Result<(f64, f64), AndersonDarlingError>
```

It asks how well the sample `a` matches the fully specified continuous distribution `dist`, using the Anderson-Darling A squared statistic over the sorted sample. The value returned is the unadjusted A squared. The p-value is read from a small sample adjusted form of it, which multiplies A squared by `1.0 + 0.75/n + 2.25/n.powi(2)` for a sample of `n` observations, and then takes the branch below that the adjusted value `z` falls in:

```rust
z >= 0.6   =>  (1.2937 - 5.709 * z + 0.0186 * z.powi(2)).exp()
z >= 0.34  =>  (0.9177 - 4.279 * z - 1.38 * z.powi(2)).exp()
z >= 0.2   =>  1.0 - (-8.318 + 42.796 * z - 59.938 * z.powi(2)).exp()
otherwise  =>  1.0 - (-13.436 + 101.14 * z - 223.73 * z.powi(2)).exp()
```

`AndersonDarlingError` carries `SampleTooSmall` when no observation is left once any `NaN` handling has happened, and `SampleContainsNaN` for a `NaN` under the `Error` policy. The `NaN` rules are checked before the sample size, so `Emit` can empty a sample and turn it into `SampleTooSmall`.

The correctness standard is scipy. On the same inputs each function has to agree with its counterpart in `scipy.stats` on both the returned statistic and the returned p-value, to within an absolute difference of 1e-9. The counterparts are `scipy.stats.chisquare`, `f_oneway`, `mannwhitneyu`, `skewtest`, and `ttest_1samp` for the one-sample t-test. Anderson-Darling is the exception: scipy's version estimates the distribution parameters from the sample and returns critical values instead of a p-value, so it is specified above on its own terms rather than by parity. Options scipy offers that this work does not need are simply unsupported, such as permutation based p-values. An exact Mann-Whitney p-value on tied data is an error here rather than a silent fallback.

Two edges depart from scipy on purpose, and an implementation has to follow the behaviour described here rather than scipy on them. A sample whose skew is exactly zero is degenerate for the skewness transform, so `skewtest` returns an ordinary finite statistic and p-value there instead of a zero z score. And `chisquare` compares the total of a supplied `f_exp` against the total of `f_obs` as whole numbers, so a total that overshoots by a fraction is accepted while one that undershoots into the next whole number down is `FExpInvalid`.

Each of the six tests lives at its own path under `statrs::stats_tests`, named for the function it provides, and exports that function together with its error enum. `mannwhitneyu` exports `MannWhitneyUMethod` from the same path. `Alternative` and `NaNPolicy` are reachable directly from `statrs::stats_tests`. Every error enum implements `Display` and `std::error::Error`, and derives `Debug` and `PartialEq`, so a caller can compare a returned error against a specific variant.
