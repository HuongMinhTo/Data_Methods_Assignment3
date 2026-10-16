# Decision 1: the data-availability requirement (Table 1)

11 October 2026; expected differences added 15 October 2026. Based on the 1A review (Huong) and the 1B review (Niklas).

## The question

Fama and MacBeth (1973, p. 617) require a security available in the first month of a testing period to have "data" for all 5 years of the estimation period and at least 4 years of the formation period. The paper does not say what counts as data when a security is listed but has no return in a month.

- **1A, complete-return rule (Niklas):** a month counts only if it has a single-month return.
- **1B, listed-month rule (Huong):** a month counts if the security is listed on the NYSE, with or without a return, from its first month with a price.

Both start from the same panel and `available.csv`, so they differ only in the rule.

## Decision

**We carry 1B forward.** Its sample (`data/processed/sample_alternative_B.csv`) is the input to Table 2.

## Expected differences

Before running either alternative, our plan (Section 4) set out these expectations:

- **Security counts:** The “available” row is identical under both rules. Since 1B can only add securities, its count must equal or exceed 1A’s.
- **Timing of differences:** Months without returns cluster in 1926–1934. The rules should therefore differ most in periods 1–3, whose formation and estimation windows cover those years, and much less from period 4 onwards.
- **Comparison with the paper:** Comparing both rules with the paper’s counts for periods 1–3 (435, 576 and 607) should indicate which interpretation is closer to Fama and MacBeth.
- **Potential effects on betas:** Securities retained only under 1B are likely to be thinly traded, so their betas may be understated and noisier (Dimson, 1979). This could move them across portfolio cut-offs, particularly in Table 2’s first panel (1934–1938).

The observed results were:

- **Additional securities:** Relative to 1A, 1B adds 130, 59, 18, 23, 11, 9, 19, 23 and 24 securities in periods 1–9, respectively.
- **Periods 1–3:** The gap is largest in periods 1 and 2 (130 and 59), as expected, and there the 1B counts (406 and 580) are much closer to the paper’s (435 and 576) than the 1A counts (276 and 521). Period 3’s gap (18) is smaller than in periods 4, 7, 8 and 9, so the expected pattern holds for periods 1 and 2 only. 1B is still closer to the paper in period 3 (606 against 607; 1A 588).
- **Period 4 onwards:** The gap is much smaller than in periods 1 and 2 but stays at 9 to 24 securities rather than falling below period 3’s. Most of these securities (94 of 109 in periods 4 to 9) have at least one month without a return inside their window; the other 15 lose only their first month with a price, which never has a return.

## Evidence

Securities meeting the requirement:

| Period     | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   | 9   |
|------------|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| Paper      | 435 | 576 | 607 | 704 | 751 | 802 | 856 | 858 | 845 |
| 1A         | 276 | 521 | 588 | 686 | 744 | 802 | 842 | 841 | 824 |
| 1B         | 406 | 580 | 606 | 709 | 755 | 811 | 861 | 864 | 848 |
| 1B − paper | −29 | +4  | −1  | +5  | +4  | +9  | +5  | +6  | +3  |

- In periods 2 to 9, 1B is within 1 to 9 securities of the paper. 1A is 0 to 55 below it.
- Every security in 1A's sample is also in 1B's sample. 1A is therefore a strict lower bound: one missing CRSP return removes a security. Counting any non-missing return instead of single-month returns changes 1A by at most 4 securities per period, so the gap comes from returns missing in CRSP, not from the single-month filter.
- Counting `ret_with_delisting` instead of `single_month_ret` gives the same 1A sample. The two series differ only in delisting months, and an available security is still listed at the start of its testing period.

## Period 1

1B is 29 below the paper in period 1. Counted from the first price, only 406 of the 710 available securities are listed in all 48 months of 1926 to 1929, so no listed-month rule can go higher. Looser readings of "data for at least four years" get close in period 1 (434 and 438) but overshoot the paper by 5 to 58 securities in every later period. No rule we tried matches the paper in all nine periods, so we keep 1B and report the period-1 shortfall as a finding. Its most likely cause, which we cannot test, is that today’s CRSP has fewer complete 1926–1929 histories than the 1973 version.

## Checks reported with 1B

A minimum of 48 estimation returns and 36 formation returns would remove 5, 4, 2, 2, 2, 0, 1, 0 and 0 securities from 1B's sample. We report this, but do not apply it.

## Carried into the final pipeline (`code/final/`)

- The 1B rule, counted from each security's first month with a price.
- Checks that the panel has one row per `(permno, year, month)`, `available.csv` one row per `(period, permno)`, and `periods.csv` one row per period.
- Zero instead of `NA` in Table 1 when a period has no eligible securities.
- A stated return series for each use: single-month returns to estimate betas, and the delisting-adjusted return (`ret_with_delisting`) for portfolio returns in the testing periods, as in the common panel.
