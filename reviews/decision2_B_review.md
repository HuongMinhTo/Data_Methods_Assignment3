# Review of Decision 2, Alternative B (index rebuilt from the stock file)

Reviewer: Huong. Reviewed on 16 October 2026: pull request #8, branch `decision2-alternative-B` at commit 730d521, that is
`code/decision2/alternative_B/market_index_2B.R` and `output/portfolio_formation_summary_2B.csv`.

**Overall assessment:** The script implements 2B as defined in our plan and reproduces exactly. I found no errors that
affect the results. The index differs from 2A almost only through delisting returns, and the differences carry very
little into Table 2. I recommend carrying 2B forward, with 2A as the robustness check.

**1. Does the code implement the proposed choice?**

Yes. Each month it takes the simple average of `ret_with_delisting` over every NYSE issue in the panel, whether or not it
meets the data requirement. That return is the single-month return, with the CRSP delisting return compounded in the
delisting month, so the index follows the plan (Section 5) and the paper's definition: an equally weighted average of
the returns on all NYSE stocks listed in month t (p. 614). The output has the agreed layout (`year`, `month`, `rm`),
510 months from January 1926 to June 1968, one row per month and no missing values.

**2. What I checked**

- I rebuilt the index independently from the panel, following the plan's definition. It matches the script's output
  exactly in all 510 months (largest difference 0).
- I ran the portfolio formation with the 2B index: `portfolio_formation_summary_2B.csv` reproduces byte for byte.
- The figures in the pull request are right: in the 180 months without a delisting return, 160 match `ewretd` to six
  decimals; in the 330 months with one, the gap averages 0.0004 and is largest in December 1932 (0.0054); the
  correlation with 2A is 0.99997.

**3. Technical or data-handling points**

- In the 20 months without a delisting return that do not match `ewretd`, the gap is small (mean 0.00006, largest
  0.00027). So 2B is CRSP's index plus the delisting returns, with a small extra difference in which issues enter.
- The script reads `market_index_2A.csv` for its checks and the comparison, so it cannot run on its own. That is fine
  for an alternative, but the version in `code/final/` should not need it, since `final/` has to run without the
  alternative folders.

**4. Are the differences plausible?**

Yes. The gap between the two indexes is largest in the 1930s, when most delistings were failures (about 0.001 a month
in affected months), and very small after 1945, as the plan expected. Downstream, the differences are small:

- Table 4 cannot separate the two versions: both match the paper's mean market return of .0143 for 1935 to June 1968,
  and no period differs from the paper by more than 0.0003 a month.
- In Table 2, betas differ by 0.0055 on average between the versions, against about 0.04 from the paper. Most of it is
  in period 1 (0.024, against 0.006 or less in every other period), where delisting returns matter most.
- At most 5% of securities change portfolio between the versions, each by one portfolio.

**Recommendation:** Approve. Carry 2B forward because it follows the paper's definition and uses the same returns as
our portfolios, as Fama and MacBeth do. Report 2A as the robustness check, and remove the dependency on
`market_index_2A.csv` in the final version.
