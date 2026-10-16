# Market index for the final pipeline: decision 2B, the NYSE index rebuilt from the stock file
#
# Decision 2 (decisions/decision2.md) carries 2B forward. These are the same steps as
# code/decision2/alternative_B/market_index_2B.R without its comparison with CRSP's published index, so the final
# pipeline does not depend on the alternative folders. Each month, the index is the simple average of the
# single-month returns of every NYSE issue listed that month, with the CRSP delisting return of any issue that leaves
# the exchange that month (ret_with_delisting in the panel).
#
# Input:  data/processed/stock_month_panel.csv (code/common/02_stock_month_panel.R)
# Output: data/processed/market_index_2B.csv, one row per month, January 1926 to June 1968, with year, month and rm
#
# For the robustness check with CRSP's published index (2A), run code/decision2/alternative_A/market_index_2A.R and set
# index_version to "2A" in the Table 2 and Table 3 scripts.

library(tidyverse)
library(here)

# 1. Read the panel
panel <- read_csv(here("data", "processed", "stock_month_panel.csv"))

# 2. Equal-weighted average of the returns that enter, month by month
market_index <- panel |>
  filter(!is.na(ret_with_delisting)) |>
  group_by(year, month) |>
  summarise(rm = mean(ret_with_delisting),
            issues = n(),
            .groups = "drop") |>
  arrange(year, month)

# 3. Checks: 510 months (January 1926 to June 1968), one row per month
stopifnot(nrow(market_index) == 510, nrow(distinct(market_index, year, month)) == 510)

summary(market_index$rm)
summary(market_index$issues)

# 4. Save (data/processed is git-ignored)
write_csv(market_index |> select(year, month, rm), here("data", "processed", "market_index_2B.csv"))
