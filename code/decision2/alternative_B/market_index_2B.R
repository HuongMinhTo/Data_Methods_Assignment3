# Decision 2B (Niklas): the NYSE index rebuilt from the stock file
#
# The paper's market return is Fisher's Arithmetic Index: the equally weighted average of the returns on
# all NYSE stocks in month t. We rebuild it from the stock-month panel (plan, Section 5): each month, the
# simple average of the single-month returns of every NYSE issue listed that month, whether or not it
# meets the data requirement, with the CRSP delisting return of any issue that leaves the exchange that
# month (compounded with its regular return where both exist). That return is ret_with_delisting in the
# panel, which is missing for months without a single-month return, so those drop out of the average.
#
# Input:  data/processed/stock_month_panel.csv (code/common/02_stock_month_panel.R)
#         data/processed/market_index_2A.csv (code/decision2/alternative_A/market_index_2A.R), for the comparison
# Output: data/processed/market_index_2B.csv, one row per month, January 1926 to June 1968,
#         with year, month and rm (monthly return in decimals), the same layout as market_index_2A.csv

library(tidyverse)
library(here)

# 1. Read the panel and CRSP's published index
panel <- read_csv(here("data", "processed", "stock_month_panel.csv"))
market_index_2A <- read_csv(here("data", "processed", "market_index_2A.csv"))

# 2. Equal-weighted average of the returns that enter, month by month
market_index_2B <- panel |>
  filter(!is.na(ret_with_delisting)) |>
  group_by(year, month) |>
  summarise(rm = mean(ret_with_delisting),
            issues = n(),
            delisting_returns = sum(delisting_month),
            .groups = "drop") |>
  arrange(year, month)

# 3. Checks: 510 months, one row per month, the same months as the published index
stopifnot(nrow(market_index_2B) == 510,
          nrow(distinct(market_index_2B, year, month)) == 510,
          nrow(anti_join(market_index_2A, market_index_2B, by = c("year", "month"))) == 0)

summary(market_index_2B$rm)
summary(market_index_2B$issues)

# 4. How far the rebuilt index is from CRSP's published one. The two should agree in months without a
#    delisting return and differ by the delisting returns elsewhere (plan, Section 5).
comparison <- market_index_2B |>
  inner_join(market_index_2A |> rename(rm_2A = rm), by = c("year", "month")) |>
  mutate(difference = rm - rm_2A)

comparison |>
  mutate(decade = paste0(floor(year / 10) * 10, "s")) |>
  group_by(decade) |>
  summarise(months = n(),
            months_with_delisting_return = sum(delisting_returns > 0),
            months_equal_to_6_decimals = sum(abs(difference) < 0.0000005),
            mean_abs_difference = mean(abs(difference)),
            max_abs_difference = max(abs(difference)))

#    The month that moves most
comparison |> slice_max(abs(difference), n = 5)

# 5. Save (data/processed is git-ignored)
write_csv(market_index_2B |> select(year, month, rm), here("data", "processed", "market_index_2B.csv"))
