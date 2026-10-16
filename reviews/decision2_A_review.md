# Review of Decision 2, Alternative A (CRSP's published NYSE index)

Reviewer: Niklas. Reviewed on 15 October 2026: branch `decision2-alternative-A` at commit c2211e1, that is
`code/decision2/alternative_A/market_index_2A.R` (pull request #6, which I approved on GitHub that day and Huong merged).
Written up here on 16 October so that both alternatives of decision 2 have a review file.

**Overall assessment:** The script does what our plan says for 2A, and I found no technical or data-handling problems.
It is short and easy to follow, and its checks cover the things that could go wrong with this file (the calendar, one
row per month and missing returns). The one thing that sets 2A apart from 2B is CRSP's own rule for the index, which
leaves delisting returns out. That is a property of the published series rather than of the code, and it is what
decision 2 is about.

**1. Does the code implement the planned choice?**

Yes. The plan (Section 5) defines 2A as CRSP's NYSE equal-weighted return including dividends, `ewretd` in `msia`, used
as published. The script takes exactly that column, renames it `rm`, keeps January 1926 to June 1968 and saves it with
year and month in the layout we agreed for both index files. It drops December 1925, which has no return because it is
CRSP's first month-end, and the comment says why.

**2. Technical and data-handling points**

I ran the script after scripts 01 to 03 in my own clone, and then Huong's portfolio formation script under 2A. The
formation summary I got, `output/portfolio_formation_summary_2A.csv`, has the same checksum as the file Huong committed,
so the index it reads is the same as hers. The index itself has 510 months, with returns from -0.3128 to 0.6681 and a
mean of 0.0139, and all four `stopifnot()` checks pass.

A few smaller points, none of which changes a number:

- CRSP's count of issues in the index (`totcnt`) runs from 506 to 1,270, so the series has no AMEX issues after July
  1962, unlike CRSP's all-exchange index (plan, Section 5). The script prints this, which I think is a useful check to
  keep.
- The script reads `riskless_rate.csv` only to check that the index covers the same months, so it has to run after
  `code/common/03_riskless_rate.R`. That just needs to be in the run order in the README.
- CRSP's index only uses an issue when it has a price at the end of both months, and it leaves delisting returns out
  (CRSP, 2013). We confirmed this in Part 2 by rebuilding the index with and without delisting returns. So, 2A is a
  clean, documented series, but it does not treat delistings the way our portfolio returns do.

**3. Are the differences plausible?**

Yes. Against the rebuilt index (2B), the correlation is 0.99997. In the 180 months in which no delisting return enters
2B, the two agree to six decimals in 160, and the rest differ by at most 0.00027, which probably comes from a few
issues that one universe has and the other does not. In the 330 months with a delisting return, the average gap is 0.0004 and it is
largest in the 1930s, when most delistings were failures. Both versions are also within 0.0003 a month of the mean
market return in each of the ten periods of the paper's Table 4. So, 2A is a reasonable stand-in for Fisher's index, and
the differences from 2B are the size and timing we expected from the delisting returns.

**Recommendation:** Accept 2A as a correct implementation of the planned alternative. For the choice between 2A and
2B, see `decisions/decision2.md`.
