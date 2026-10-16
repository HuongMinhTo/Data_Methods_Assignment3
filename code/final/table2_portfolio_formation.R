# Table 2: portfolio formation (Huong)
#
# For each period, estimate formation-period betas and form 20 portfolios (Fama and MacBeth, 1973, p. 615).
#   - Sample: sample_final.csv (code/final/table1_sample.R, decision 1)
#   - Beta: market model on raw returns (eq. 8), from all single-month returns in the formation period
#   - Portfolios: ranked on beta (1 lowest, 20 highest; ties by permno). Middle 18 get int(N/20);
#     the remainder is split between 1 and 20, with 20 taking the extra one when N is odd.
#
# Set index_version to "2A" or "2B" to choose the market index (decision 2).
# Output: data/processed/portfolios_<version>.csv (period, permno, portfolio, beta_formation) and
#         output/portfolio_formation_summary_<version>.csv (size and formation betas of each portfolio)

library(tidyverse)
library(here)

index_version <- "2B"

# 1. Read the sample, the calendar, the panel and the market index
sample_final <- read_csv(here("data", "processed", "sample_final.csv"))
periods <- read_csv(here("data", "processed", "periods.csv"))
panel <- read_csv(here("data", "processed", "stock_month_panel.csv"))
market_index <- read_csv(here("data", "processed", paste0("market_index_", index_version, ".csv")))

stopifnot(nrow(distinct(sample_final, period, permno)) == nrow(sample_final),
          nrow(distinct(market_index, year, month)) == nrow(market_index))

# 2. Single-month returns of each security in its formation period, with the market return
formation_returns <- sample_final |>
  select(period, permno) |>
  inner_join(periods |> select(period, formation_start, formation_end), by = "period") |>
  inner_join(panel |> filter(single_month_ret) |> select(permno, year, month, ret),
             by = "permno", relationship = "many-to-many") |>
  filter(between(year, formation_start, formation_end)) |>
  inner_join(market_index, by = c("year", "month"))

# 3. Formation-period beta of each security (OLS slope: cov(R_i, R_m) / var(R_m))
betas <- formation_returns |>
  group_by(period, permno) |>
  summarise(n_returns = n(),
            beta_formation = cov(ret, rm) / var(rm),
            .groups = "drop")

stopifnot(nrow(betas) == nrow(sample_final), !anyNA(betas$beta_formation))

#    Securities with short formation histories (kept, as 1B sets no minimum)
betas |> count(period, short_history = n_returns < 24) |> filter(short_history)

# 4. Rank on beta and form the 20 portfolios with the paper's sizes
portfolio_sizes <- function(n) {
  q <- n %/% 20
  remainder <- n - 20 * q
  c(q + remainder %/% 2, rep(q, 18), q + remainder - remainder %/% 2)
}

portfolios <- betas |>
  arrange(period, beta_formation, permno) |>
  group_by(period) |>
  mutate(portfolio = rep(1:20, times = portfolio_sizes(n()))) |>
  ungroup()

#    Checks: every security in exactly one portfolio, sizes as in the paper, betas rising across portfolios
sizes <- portfolios |> count(period, portfolio)
stopifnot(nrow(portfolios) == nrow(sample_final),
          all(sizes |> group_by(period) |> summarise(ok = all(n == portfolio_sizes(sum(n)))) |> pull(ok)),
          all(portfolios |> group_by(period, portfolio) |> summarise(lo = min(beta_formation), hi = max(beta_formation), .groups = "drop") |>
                group_by(period) |> summarise(ok = all(lead(lo, default = Inf) >= hi)) |> pull(ok)))

# 5. Summary of each portfolio: number of securities and formation betas
summary_table <- portfolios |>
  group_by(period, portfolio) |>
  summarise(securities = n(),
            mean_beta_formation = mean(beta_formation),
            min_beta_formation = min(beta_formation),
            max_beta_formation = max(beta_formation),
            .groups = "drop")

summary_table |>
  group_by(period) |>
  summarise(size_p1 = first(securities), size_p20 = last(securities),
            mean_beta_p1 = first(mean_beta_formation), mean_beta_p20 = last(mean_beta_formation),
            securities = sum(securities))

# 6. Save the portfolios (git-ignored) and the summary
write_csv(portfolios |> select(period, permno, portfolio, beta_formation),
          here("data", "processed", paste0("portfolios_", index_version, ".csv")))
write_csv(summary_table, here("output", paste0("portfolio_formation_summary_", index_version, ".csv")))
