# Review of Decision 1, Alternative B (listed-month rule)

Reviewer: Niklas. Reviewed on 11 October 2026: branch `decision1-alternative-B` at commit f5e2577, that is
`code/decision1/alternative_B/table1_listed_month_rule.R` and `output/table1_alternative_B.csv`.

**Overall assessment:** The script is clear, it uses the shared panel, periods and available securities, and it
reproduces its saved table exactly. It differs from the rule in our plan in one step: it counts listed months from each
issue's first CRSP row, while the plan counts them from the issue's first month with a price. That only changes period
1, where the count would be 406 instead of 413. The plan also says we report how many securities a minimum of 48 and 36
returns would remove, and that count is not in the script yet. With those two changes I'd approve it.

**1. What I checked**

I ran the script on the shared data after scripts 01 and 02, and it reproduces `output/table1_alternative_B.csv` byte
for byte. It reads `available.csv`, `periods.csv` and the panel, so the available row is the same as under 1A in all
nine periods and the two alternatives differ only in the rule. The windows are right: all 60 estimation months and at
least 48 formation months (so all 48 in period 1), with inclusive year bounds. No minimum number of returns is imposed,
as the plan says. The panel has no duplicate issue-months (470,807 rows, all distinct), so counting panel rows counts
months. I can also confirm that every security in 1A's sample is in 1B's sample in every period (an `anti_join`
returns no rows).

**2. Where the count starts**

The plan defines 1B like this: "From the security's first month with a price, a month counts if CRSP has a record for
it while it is listed on the NYSE, whether or not the month has a return." The script counts every panel row
(`panel |> distinct(permno, year, month)`), including the rows CRSP has for an issue before its first price. Those rows
have no price and no return, and no later return covers them either, because the first return after a first price only
reaches back to that price. That is why we put the start into the plan: many issues have rows without a price before
their first price, and counting them would treat months before the stock traded as data.

In periods 2 to 9 this makes no difference. In period 1 it adds seven securities. Each of them has between 1 and 17
months without a price at the start of 1926 or 1927, so counted from its first price it is listed in only 31 to 47 of
the 48 formation months, and period 1 needs all 48:

| permno | first CRSP row | first price | formation months from first price |
|---|---|---|---|
| 11797 | Jan 1926 | Feb 1926 | 47 |
| 12757 | Dec 1925 | Mar 1926 | 46 |
| 16117 | Dec 1925 | Mar 1926 | 46 |
| 15632 | Dec 1925 | Jun 1926 | 43 |
| 13696 | Jan 1926 | Oct 1926 | 39 |
| 26972 | Jan 1926 | Jan 1927 | 36 |
| 13899 | Jan 1926 | Jun 1927 | 31 |

Five of the seven would also fail the 48 and 36 minimum in point 3, so they are among the securities with the fewest
returns in period 1.

What I'd change: start each issue at its first month with a price. Something like this, and then use `listed_months` in
step 2 instead of `panel |> distinct(permno, year, month)`:

```r
# Count listed months from each issue's first month with a price (our plan, Section 4)
first_price <- panel |>
  filter(has_price) |>
  group_by(permno) |>
  summarise(first_price_date = min(date))

listed_months <- panel |>
  inner_join(first_price, by = "permno") |>
  filter(date >= first_price_date) |>
  distinct(permno, year, month)
```

With that change I get 406, 580, 606, 709, 755, 811, 861, 864 and 848.

**3. The 48 and 36 minimum**

The plan says: "We will also report how many securities a minimum of 48 returns in the estimation period and 36 in the
formation period would remove." That count isn't in the script yet. It needs one more count of `single_month_ret` in
each window, the same way the 1A script counts returns. With the start fixed I get 5, 4, 2, 2, 2, 0, 1, 0 and 0 (10
instead of 5 in period 1 with the current start).

**4. Period 1 against the paper**

Counted from the first price, only 406 of the 710 available issues are listed in all 48 months of 1926 to 1929, so no
listed-month count can go above 406 in period 1. That leaves 1B 29 below the paper's 435. I also tried two looser
readings of "data for at least four years". A minimum of 48 and 36 returns gives 434 in period 1, and a return in each
of the five estimation years and in at least four formation years gives 438. Both get close in period 1 but overshoot
the paper in every later period, by 5 to 58 securities. So, I think the period-1 gap comes from the data, or from a
sample difference we can't see. None of the readings we tried fits all nine periods. That also covers the question left open in point
4 of the 1A review. I'd record it as a finding in the decision record and compare the two rules on periods 2 to 9,
where 1B is within 1 to 9 securities of the paper and 1A is between 0 and 55 below it.

**5. Pull request**

There is no pull request for `decision1-alternative-B` yet. Our plan has every alternative reach `main` through a pull
request the other person approves, so could you open one once the two changes are in? I'll approve it there. The 1A
review is on the same branch, so it reaches `main` together with 1B, which is fine.

**Recommendation:** Approve after the changes in points 2 and 3. Table 1 under 1B should then read 406, 580, 606, 709,
755, 811, 861, 864 and 848. I agree that we carry 1B forward, and Huong writes the decision record
(`decisions/decision1.md`), as in our plan.
