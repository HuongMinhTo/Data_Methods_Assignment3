# Table 1 and the agreed sample (Huong)
#
# The agreed rule from decision 1 (decisions/decision1.md): the listed-month rule, 1B. A month counts if
# the security is listed on the NYSE, with or without a return, from its first month with a price.
# A security needs all 60 estimation months and at least 48 formation months (all 48 in period 1).
# Also reports how many securities a 48/36 minimum of returns would remove, as in the decision record.
#
# Output: output/table1_final.csv (Table 1 beside the paper's counts) and
#         data/processed/sample_final.csv (the securities that meet the requirement, the input to Table 2)

library(tidyverse)
library(here)

# 1. Read the panel, the calendar and the available securities (code/common/02_stock_month_panel.R)
panel <- read_csv(here("data", "processed", "stock_month_panel.csv"))
periods <- read_csv(here("data", "processed", "periods.csv"))
available <- read_csv(here("data", "processed", "available.csv"))

#    Duplicated rows would distort the counts (1A review)
stopifnot(nrow(distinct(panel, permno, year, month)) == nrow(panel),
          nrow(distinct(available, period, permno)) == nrow(available),
          nrow(distinct(periods, period)) == nrow(periods))

# 2. Listed months and single-month returns from each issue's first month with a price
first_price <- panel |>
  filter(has_price) |>
  group_by(permno) |>
  summarise(first_price_date = min(date))

listed_months <- panel |>
  inner_join(first_price, by = "permno") |>
  filter(date >= first_price_date) |>
  distinct(permno, year, month, single_month_ret)

counts <- available |>
  inner_join(periods, by = "period") |>
  left_join(listed_months, by = "permno", relationship = "many-to-many") |>
  group_by(period, permno) |>
  summarise(estimation_months = sum(between(year, estimation_start, estimation_end), na.rm = TRUE),
            formation_months = sum(between(year, formation_start, formation_end), na.rm = TRUE),
            estimation_returns = sum(between(year, estimation_start, estimation_end) & single_month_ret, na.rm = TRUE),
            formation_returns = sum(between(year, formation_start, formation_end) & single_month_ret, na.rm = TRUE),
            .groups = "drop")

# 3. The rule: all 60 estimation months, at least 48 formation months
sample_final <- counts |>
  filter(estimation_months == 60, formation_months >= 48)

removed_by_min_returns <- sample_final |>
  filter(estimation_returns < 48 | formation_returns < 36) |>
  count(period, name = "removed_by_min_returns")

# 4. Table 1 beside the paper's counts (Fama and MacBeth 1973, Table 1); zero rather than NA for empty periods
fm_table1 <- tibble(period = 1:9,
                    fm_available = c(710, 779, 804, 908, 1011, 1053, 1065, 1162, 1261),
                    fm_meeting_requirement = c(435, 576, 607, 704, 751, 802, 856, 858, 845))

table1_final <- periods |>
  left_join(available |> count(period, name = "available"), by = "period") |>
  left_join(sample_final |> count(period, name = "meeting_requirement"), by = "period") |>
  left_join(removed_by_min_returns, by = "period") |>
  left_join(fm_table1, by = "period") |>
  mutate(across(c(available, meeting_requirement, removed_by_min_returns), \(x) replace_na(x, 0L)),
         available_minus_fm = available - fm_available,
         meeting_minus_fm = meeting_requirement - fm_meeting_requirement)

table1_final |> select(period, available, fm_available, meeting_requirement, fm_meeting_requirement, meeting_minus_fm,
                       removed_by_min_returns)

# 5. Save the table and the sample
write_csv(table1_final, here("output", "table1_final.csv"))
write_csv(sample_final, here("data", "processed", "sample_final.csv"))
