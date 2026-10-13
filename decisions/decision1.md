# Decision 1: the data-availability requirement (Table 1)

11 October 2026. Based on the 1A review (Huong) and the 1B review (Niklas).

## The question

Fama and MacBeth (1973, p. 617) require a security available in the first month of a testing period to have "data" for all 5 years of the estimation period and at least 4 years of the formation period. The paper does not say what counts as data when a security is listed but has no return in a month.

- **1A, complete-return rule (Niklas):** a month counts only if it has a single-month return.
- **1B, listed-month rule (Huong):** a month counts if the security is listed on the NYSE, with or without a return, from its first month with a price.

Both start from the same panel and `available.csv`, so they differ only in the rule.

## Decision

**We carry 1B forward.** Its sample (`data/processed/sample_alternative_B.csv`) is the input to Table 2.

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
