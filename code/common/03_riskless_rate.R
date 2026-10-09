# 03. The riskless rate for Table 3: CRSP's 30-day Treasury bill return
#
# Section 2 of our plan: the riskless rate is CRSP's 30-day bill return (t30ret in mcti). CRSP recommends
# that series only for the years after 1937 (CRSP, 2013), so for 1935 to 1937 we compare it with the
# Fama-French one-month bill return (rf). Output: data/processed/riskless_rate.csv, one row per month,
# January 1926 to June 1968.

library(tidyverse)
library(here)

# 1. Read the two bill series saved by script 01
mcti <- read_csv(here("data", "raw", "crsp_mcti.csv"))
ff_rf <- read_csv(here("data", "raw", "ff_rf.csv"))

# 2. Put them side by side by calendar month (CRSP dates are month ends, Fama-French dates the first day)
riskless_rate <- mcti |>
  mutate(year = year(caldt), month = month(caldt)) |>
  select(year, month, t30ret) |>
  left_join(ff_rf |> mutate(year = year(date), month = month(date)) |> select(year, month, rf),
            by = c("year", "month")) |>
  filter(year >= 1926)

nrow(riskless_rate)    # 510 months, January 1926 to June 1968

# 3. Compare the two series, 1935 to 1937 against the other years
riskless_rate |>
  mutate(years = if_else(year >= 1935 & year <= 1937, "1935 to 1937", "other years")) |>
  group_by(years) |>
  summarise(months = n(),
            mean_t30ret = mean(t30ret, na.rm = TRUE),
            mean_rf = mean(rf, na.rm = TRUE),
            mean_abs_difference = mean(abs(t30ret - rf), na.rm = TRUE),
            correlation = cor(t30ret, rf, use = "complete.obs"))

riskless_rate |>
  filter(year >= 1935, year <= 1937) |>
  print(n = 36)

# 4. Save
write_csv(riskless_rate, here("data", "processed", "riskless_rate.csv"))
