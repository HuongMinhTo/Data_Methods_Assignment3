# Decision point 1, alternative A (Niklas): the complete-return rule
#
# Fama and MacBeth (1973) require a security that is available in the first month of a testing period to
# have data for all five years of the estimation period and for at least four years of the portfolio
# formation period. Under alternative A a month counts as data only if it has a single-month return
# (script 02 in code/common), so a security needs all 60 single-month returns in the estimation period
# and at least 48 in the formation period. In period 1 the formation period (1926 to 1929) has only 48
# months, so it needs all 48.
#
# Output: output/table1_alternative_A.csv, Table 1 under alternative A beside the paper's counts, and
# data/processed/sample_alternative_A.csv, the securities that meet the requirement (the input to Table 2).

library(tidyverse)
library(here)

# 1. Read the panel, the calendar and the available securities (code/common/02_stock_month_panel.R)
panel <- read_csv(here("data", "processed", "stock_month_panel.csv"))
periods <- read_csv(here("data", "processed", "periods.csv"))
available <- read_csv(here("data", "processed", "available.csv"))

# 2. For each available security, count its single-month returns in the estimation and formation periods
return_counts <- available |>
  inner_join(periods, by = "period") |>
  left_join(panel |> filter(single_month_ret) |> select(permno, year),
            by = "permno", relationship = "many-to-many") |>
  group_by(period, permno) |>
  summarise(estimation_returns = sum(between(year, estimation_start, estimation_end), na.rm = TRUE),
            formation_returns = sum(between(year, formation_start, formation_end), na.rm = TRUE),
            .groups = "drop")

# 3. The complete-return rule: all 60 in the estimation period, at least 48 in the formation period
sample_A <- return_counts |>
  filter(estimation_returns == 60, formation_returns >= 48)

#    Why the others fail, by period
return_counts |>
  mutate(fails_on = case_when(estimation_returns < 60 & formation_returns < 48 ~ "both",
                              estimation_returns < 60 ~ "estimation period",
                              formation_returns < 48 ~ "formation period",
                              .default = "meets the requirement")) |>
  count(period, fails_on) |>
  pivot_wider(names_from = fails_on, values_from = n, values_fill = 0)

# 4. Table 1 under alternative A, beside the paper's counts (Fama and MacBeth 1973, Table 1)
fm_table1 <- tibble(period = 1:9,
                    fm_available = c(710, 779, 804, 908, 1011, 1053, 1065, 1162, 1261),
                    fm_meeting_requirement = c(435, 576, 607, 704, 751, 802, 856, 858, 845))

table1_A <- periods |>
  left_join(available |> count(period, name = "available"), by = "period") |>
  left_join(sample_A |> count(period, name = "meeting_requirement"), by = "period") |>
  left_join(fm_table1, by = "period") |>
  mutate(available_minus_fm = available - fm_available,
         meeting_minus_fm = meeting_requirement - fm_meeting_requirement)

table1_A |> select(period, available, fm_available, meeting_requirement, fm_meeting_requirement, meeting_minus_fm)

# 5. Save the table and the sample
write_csv(table1_A, here("output", "table1_alternative_A.csv"))
write_csv(sample_A, here("data", "processed", "sample_alternative_A.csv"))
