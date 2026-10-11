# Decision 1B (Huong): listed-month rule
#
# Same inputs as 1A. A month counts if the security is listed on the NYSE, with or
# without a return, from its first month with a price (plan, Section 4).
# Rule: all 60 estimation months and at least 48 formation months (all 48 in period 1).
# Also reports how many securities a 48/36 minimum of returns would remove.
#
# Outputs:
#   output/table1_alternative_B.csv — Table 1 compared with the paper
#   data/processed/sample_alternative_B.csv — eligible securities for Table 2

library(tidyverse)
library(here)

# 1. Read the panel, the calendar and the available securities (code/common/02_stock_month_panel.R)
panel <- read_csv(here("data", "processed", "stock_month_panel.csv"))
periods <- read_csv(here("data", "processed", "periods.csv"))
available <- read_csv(here("data", "processed", "available.csv"))

# 2. Count listed months from each issue's first month with a price (our plan, Section 4).
#    Rows before the first price have no price and no return, so they are not data.
first_price <- panel |>
  filter(has_price) |>
  group_by(permno) |>
  summarise(first_price_date = min(date))

listed_months <- panel |>
  inner_join(first_price, by = "permno") |>
  filter(date >= first_price_date) |>
  distinct(permno, year, month, single_month_ret)

#    For each available security, count its listed months and its single-month returns in the
#    estimation and formation periods
listed_counts <- available |>
  inner_join(periods, by = "period") |>
  left_join(listed_months, by = "permno", relationship = "many-to-many") |>
  group_by(period, permno) |>
  summarise(estimation_months = sum(between(year, estimation_start, estimation_end), na.rm = TRUE),
            formation_months = sum(between(year, formation_start, formation_end), na.rm = TRUE),
            estimation_returns = sum(between(year, estimation_start, estimation_end) & single_month_ret, na.rm = TRUE),
            formation_returns = sum(between(year, formation_start, formation_end) & single_month_ret, na.rm = TRUE),
            .groups = "drop")

# 3. The listed-month rule: all 60 in the estimation period, at least 48 in the formation period
sample_B <- listed_counts |>
  filter(estimation_months == 60, formation_months >= 48)

#    Why the others fail, by period
listed_counts |>
  mutate(fails_on = case_when(estimation_months < 60 & formation_months < 48 ~ "both",
                              estimation_months < 60 ~ "estimation period",
                              formation_months < 48 ~ "formation period",
                              .default = "meets the requirement")) |>
  count(period, fails_on) |>
  pivot_wider(names_from = fails_on, values_from = n, values_fill = 0)

#    How many securities in the 1B sample a minimum of 48 estimation and 36 formation returns would remove
removed_by_min_returns <- sample_B |>
  filter(estimation_returns < 48 | formation_returns < 36) |>
  count(period, name = "removed_by_min_returns")

removed_by_min_returns

# 4. Table 1 under alternative B, beside the paper's counts (Fama and MacBeth 1973, Table 1)
fm_table1 <- tibble(period = 1:9,
                    fm_available = c(710, 779, 804, 908, 1011, 1053, 1065, 1162, 1261),
                    fm_meeting_requirement = c(435, 576, 607, 704, 751, 802, 856, 858, 845))

table1_B <- periods |>
  left_join(available |> count(period, name = "available"), by = "period") |>
  left_join(sample_B |> count(period, name = "meeting_requirement"), by = "period") |>
  left_join(removed_by_min_returns, by = "period") |>
  left_join(fm_table1, by = "period") |>
  mutate(removed_by_min_returns = replace_na(removed_by_min_returns, 0),
         available_minus_fm = available - fm_available,
         meeting_minus_fm = meeting_requirement - fm_meeting_requirement)

table1_B |> select(period, available, fm_available, meeting_requirement, fm_meeting_requirement, meeting_minus_fm,
                   removed_by_min_returns)

# 5. Save the table and the sample
write_csv(table1_B, here("output", "table1_alternative_B.csv"))
write_csv(sample_B, here("data", "processed", "sample_alternative_B.csv"))
