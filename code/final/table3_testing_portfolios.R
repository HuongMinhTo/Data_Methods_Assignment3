# Table 3: testing-period portfolio panel (Huong)
#
# For each month of the testing periods (January 1935 to June 1968), the returns and regressors of the
# 20 portfolios that enter the cross-sectional regressions of eq. (10) (Fama and MacBeth, 1973, pp. 615-616).
#   - Betas and s(e_i): market model on raw returns from single-month returns, re-estimated each January
#     on an expanding window from the start of the estimation period to the December before
#   - Each month uses the securities with a return that month: rp is their equal-weighted return
#     (delisting returns included), beta_p, beta_sq_p and s_e_p the averages of their beta_i, beta_i^2
#     and s(e_i). A security drops out after its delisting month.
#
# Set index_version to "2A" or "2B" to choose the market index (decision 2).
# Output: data/processed/testing_portfolios_<version>.csv
#         (period, year, month, portfolio, n_securities, rp, beta_p, beta_sq_p, s_e_p)

library(tidyverse)
library(here)

index_version <- "2B"

# 1. Read the portfolios, the calendar, the panel and the market index
portfolios <- read_csv(here("data", "processed", paste0("portfolios_", index_version, ".csv")))
periods <- read_csv(here("data", "processed", "periods.csv"))
panel <- read_csv(here("data", "processed", "stock_month_panel.csv"))
market_index <- read_csv(here("data", "processed", paste0("market_index_", index_version, ".csv")))

stopifnot(nrow(distinct(portfolios, period, permno)) == nrow(portfolios),
          nrow(distinct(panel, permno, year, month)) == nrow(panel))

# 2. Each test year of each period, with its expanding estimation window (testing period 9 ends in June 1968)
test_years <- periods |>
  rowwise() |>
  reframe(period, estimation_start, test_year = testing_start:testing_end)

# 3. Beta_i and s(e_i) for every security and test year, from single-month returns in its window
returns <- panel |>
  filter(single_month_ret) |>
  select(permno, year, month, ret) |>
  inner_join(market_index, by = c("year", "month"))

security_estimates <- portfolios |>
  select(period, permno, portfolio) |>
  inner_join(test_years, by = "period", relationship = "many-to-many") |>
  inner_join(returns, by = "permno", relationship = "many-to-many") |>
  filter(year >= estimation_start, year < test_year) |>
  group_by(period, test_year, permno, portfolio) |>
  mutate(beta_i = cov(ret, rm) / var(rm),
         residual = ret - (mean(ret) - beta_i * mean(rm)) - beta_i * rm) |>
  summarise(beta_i = first(beta_i),
            s_e_i = sqrt(sum(residual^2) / (n() - 2)),
            .groups = "drop")

stopifnot(!anyNA(security_estimates$beta_i), !anyNA(security_estimates$s_e_i))

# 4. Monthly portfolio returns and regressors over the securities with a return that month
testing_returns <- portfolios |>
  select(period, permno) |>
  inner_join(periods |> select(period, testing_start, testing_end), by = "period") |>
  inner_join(panel |> filter(!is.na(ret_with_delisting)) |> select(permno, year, month, ret_with_delisting),
             by = "permno", relationship = "many-to-many") |>
  filter(between(year, testing_start, testing_end), year * 100 + month <= 196806)

testing_portfolios <- testing_returns |>
  inner_join(security_estimates, by = c("period", "permno", "year" = "test_year")) |>
  group_by(period, year, month, portfolio) |>
  summarise(n_securities = n(),
            rp = mean(ret_with_delisting),
            beta_p = mean(beta_i),
            beta_sq_p = mean(beta_i^2),
            s_e_p = mean(s_e_i),
            .groups = "drop") |>
  arrange(year, month, portfolio)

# 5. Checks: 402 months x 20 portfolios, no gaps, no missing values
stopifnot(nrow(testing_portfolios) == 402 * 20,
          nrow(distinct(testing_portfolios, year, month)) == 402,
          all(count(testing_portfolios, year, month)$n == 20),
          !anyNA(testing_portfolios))

testing_portfolios |>
  group_by(period) |>
  summarise(months = n_distinct(year * 100 + month),
            min_securities = min(n_securities),
            mean_beta_p1 = mean(beta_p[portfolio == 1]),
            mean_beta_p20 = mean(beta_p[portfolio == 20]),
            mean_rp = mean(rp))

# 6. Save (data/processed is git-ignored)
write_csv(testing_portfolios, here("data", "processed", paste0("testing_portfolios_", index_version, ".csv")))
