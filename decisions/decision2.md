# Decision 2: the market index (Table 2)

Agreed by Huong and Niklas on 15 October 2026 (by email), recorded 16 October 2026. Based on the 2A review (Niklas) and
the 2B review (Huong).

## The question

Fama and MacBeth (1973) use Fisher's Arithmetic Index, an equally weighted average of the returns on all NYSE stocks in
month t (Fisher, 1966). The index enters every market-model regression, so it shapes the betas and residual standard
deviations in the formation, estimation and testing periods. The paper does not say which issues count, how missing
prices are handled or whether delisting returns enter.

- **2A, CRSP's published NYSE index (Huong):** CRSP's NYSE equal-weighted return including dividends (`ewretd` in
  `msia`), used as published.
- **2B, the index rebuilt from the stock file (Niklas):** each month, the simple average of the single-month returns of
  every NYSE issue listed that month, including the CRSP delisting return of any issue that leaves the exchange that
  month.

CRSP's index uses an issue only when it has a valid price at the end of both months, and it leaves delisting returns out
(CRSP, 2013; we checked this in Part 2). So, the two versions differ mainly in the delisting returns. Both run through the
same Table 2 code, which has an `index_version` switch, so any difference between `output/table2_2A.csv` and
`output/table2_2B.csv` comes from the index alone.

## Decision

**We carry 2B forward**, and keep 2A as a robustness check. `code/final/market_index.R` builds 2B for the final
pipeline, and the Table 2 and Table 3 scripts in `code/final/` run with `index_version <- "2B"`.

## Expected differences

Before running either alternative, our plan (Section 5) set out these expectations:

- **Size:** Both series are NYSE-only and equally weighted, so the differences should be small.
- **Timing:** Adding delisting returns moves the average most in the 1930s and early 1940s, when most delistings were
  failures, and very little after 1945, when most were mergers.
- **Table 2:** The 1934–38 panel (portfolios formed on 1927–33) should differ most, the 1942–46 panel less and the
  later two little.
- **Table 3:** In panel A, γ̂0t + γ̂1t should be close to Rmt each month, and slightly closer under 2B, whose index
  includes the same delisting returns as the portfolio returns.

The observed results were:

- **Size:** As expected, the differences are small. The two series have a correlation of 0.99997, and their means over
  the 510 months are 0.0139 (2A) and 0.0138 (2B). In the 180 months in which no delisting return enters, they agree to
  six decimals in 160 months. In the other 330 months the average absolute gap is 0.0004, and 2B is lower on average
  (by 0.0002), so the delisting returns pull the average down.
- **Timing:** As expected, the gaps are largest in the 1930s (0.0006 on average, and the largest single gap is 0.0054
  in December 1932) and fall to about 0.0001 from the 1950s on.
- **Table 2:** Over all nine estimation periods the portfolio betas differ by 0.0055 on average. Most of this comes from
  period 1 (1930–34, which the paper does not print), at 0.024. In the four periods the paper prints, the differences
  are 0.0036 (1934–38), 0.0017 (1942–46), 0.0046 (1950–54) and 0.0059 (1958–62). So, unlike our expectation, 1934–38
  does not differ most among the printed panels, although all four differences are about a tenth of the gap between
  either version and the paper (about 0.04). Fewer than 5% of the securities change portfolio under 2B, and none moves
  by more than one portfolio.
- **Table 3:** We report this check with Table 3 (`code/final/table3_regressions.R`).

## Evidence against the paper

Portfolio betas (lowest to highest of the 20 portfolios) and precision ratios in the four periods the paper prints:

| Estimation period | Paper betas | 2A betas | 2B betas | Paper ratio | 2A ratio | 2B ratio |
|---|---|---|---|---|---|---|
| 1934–38 | .322 to 1.458 | 0.311 to 1.514 | 0.310 to 1.514 | 0.234 | 0.233 | 0.233 |
| 1942–46 | .467 to 1.661 | 0.456 to 1.693 | 0.456 to 1.697 | 0.254 | 0.254 | 0.254 |
| 1950–54 | .418 to 1.527 | 0.451 to 1.531 | 0.451 to 1.531 | 0.208 | 0.210 | 0.210 |
| 1958–62 | .626 to 1.388 | 0.636 to 1.436 | 0.636 to 1.437 | 0.208 | 0.209 | 0.208 |

The ratio is s(e_p) / mean s(e_i), averaged over the 20 portfolios.

- **Table 2:** Against the paper's 80 printed portfolio betas, 2A is closer in 40 and 2B in 40, with mean absolute gaps
  of 0.039 and 0.040. The precision ratios of the two versions are within 0.002 of the paper's average in every printed
  period.
- **Table 4 of the paper** prints the mean market return for ten periods. Neither version is more than 0.0003 a month
  away from it in any of them. 2A matches 1935–45 exactly (.0197), but that comes from two misses cancelling out: it is
  0.00025 above the paper in 1935–40 and 0.00023 below it in 1941–45. In 1935–40, where delisting returns move the index
  most, 2B is the closer one (0.00013 below).

So, neither Table 2 nor Table 4 separates the two versions.

## Key review findings

- **2A** (`reviews/decision2_A_review.md`, Niklas): the script implements 2A as planned, its checks pass, and it
  reproduces Huong's portfolio formation output byte for byte. The only property that matters for this decision is
  CRSP's own rule, which leaves delisting returns out of the index.
- **2B** (`reviews/decision2_B_review.md`, Huong): she rebuilt the index independently from the panel and matched the
  script's output in all 510 months, reproduced the 2B portfolio formation summary byte for byte, and confirmed the
  figures in the pull request (160 of 180 months without a delisting return equal to six decimals; a gap of 0.0004 on
  average elsewhere). She found no errors that affect the results and recommended 2B, because it follows the paper's
  definition of the index directly and uses the same returns as our portfolios. Her one request, that the final
  version not depend on `market_index_2A.csv`, is met by `code/final/market_index.R`.

## Reason for the decision

Since neither Table 2 nor Table 4 separates the two versions, the choice rests on how the index is built. Our portfolio
returns include delisting returns (plan, Section 2), and 2B is the version that treats the market the same way, so the
market-model regressions compare like with like. 2B also follows the paper's one-line definition directly (every NYSE
stock, equally weighted) and needs only the stock file. We keep 2A as a robustness check: its Table 2 is in
`output/table2_2A.csv`, and the scripts in `code/final/` run it when `index_version` is set to "2A".

## Carried into the final pipeline (`code/final/`)

- `code/final/market_index.R`: the 2B index, the same steps as `code/decision2/alternative_B/market_index_2B.R` without
  the comparison with 2A, so the final pipeline does not depend on the alternative folders.
- `index_version <- "2B"` in `table2_portfolio_formation.R`, `table2_estimation_statistics.R` and the Table 3 scripts.
- The γ̂0t + γ̂1t ≈ Rmt check, run under both versions and reported with Table 3.
