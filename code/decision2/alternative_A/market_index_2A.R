# Decision 2A (Huong): CRSP's published NYSE index
#
# The market return is CRSP's NYSE equal-weighted return including dividends (ewretd in msia),
# used as published (plan, Section 5). It stands in for Fisher's Arithmetic Index.
#
# Input:  data/raw/crsp_msia.csv (code/common/01_wrds_pull.R)
# Output: data/processed/market_index_2A.csv, one row per month, January 1926 to June 1968,
#         with year, month and rm (monthly return in decimals), the same months as riskless_rate.csv

library(tidyverse)
library(here)

# 1. Read CRSP's NYSE index and the riskless rate (for the calendar check)
msia <- read_csv(here("data", "raw", "crsp_msia.csv"))
riskless_rate <- read_csv(here("data", "processed", "riskless_rate.csv"))

# 2. Year, month and rm. December 1925 has no return (CRSP's first month-end prices), so it is dropped.
market_index_2A <- msia |>
  mutate(year = as.integer(year(caldt)), month = as.integer(month(caldt))) |>
  filter(year >= 1926, year * 100 + month <= 196806) |>
  transmute(year, month, rm = ewretd) |>
  arrange(year, month)

# 3. Checks: 510 months, one row per month, no missing returns, the same months as riskless_rate.csv
stopifnot(nrow(market_index_2A) == 510,
          nrow(distinct(market_index_2A, year, month)) == 510,
          !anyNA(market_index_2A$rm),
          nrow(anti_join(riskless_rate, market_index_2A, by = c("year", "month"))) == 0)

summary(market_index_2A$rm)

#    CRSP's count of NYSE issues stays below 1,300, so the index has no AMEX issues after July 1962
msia |> filter(year(caldt) >= 1926) |> summarise(min_issues = min(totcnt), max_issues = max(totcnt))

# 4. Save (data/processed is git-ignored)
write_csv(market_index_2A, here("data", "processed", "market_index_2A.csv"))
