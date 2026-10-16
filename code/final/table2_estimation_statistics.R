# Table 2: estimation-period statistics of the 20 portfolios (Niklas)
#
# For each period, the portfolios formed in code/final/table2_portfolio_formation.R are followed through the
# 5-year estimation period (Fama and MacBeth, 1973, Table 2 and the text that describes it):
#   - beta of each security from the market model on raw returns (eq. 8) over the estimation months; the
#     portfolio beta is the average of its securities' betas, and mean s(e_i) the average of their residual
#     standard deviations, as in the paper
#   - the portfolio's monthly return is the equal-weighted average of its securities' single-month returns
#     (a security without a return that month is left out of the average, plan, Section 2); its regression
#     on the market gives r(Rp, Rm)^2, s(Rp) and s(e_p)
#   - s(beta_p) = s(e_p) / (sqrt(n) s(Rm)) with n = 60 months, the paper's formula
# The paper reports four estimation periods (1934-38, 1942-46, 1950-54, 1958-62: periods 2, 4, 6 and 8);
# all nine are computed and saved, and those four are printed beside the paper's values.
#
# Set index_version to "2A" or "2B" to choose the market index (decision 2). 2B is the agreed version
# (decisions/decision2.md); 2A is the robustness check.
# Input:  data/processed/portfolios_<version>.csv, periods.csv, stock_month_panel.csv, market_index_<version>.csv,
#         data/paper/table2_fama_macbeth_1973.csv (Table 2 as printed, typed from the paper)
# Output: output/table2_<version>.csv

library(tidyverse)
library(here)

index_version <- "2B"

# 1. Read the portfolios, the calendar, the panel, the market index and the paper's Table 2
portfolios <- read_csv(here("data", "processed", paste0("portfolios_", index_version, ".csv")))
periods <- read_csv(here("data", "processed", "periods.csv"))
panel <- read_csv(here("data", "processed", "stock_month_panel.csv"))
market_index <- read_csv(here("data", "processed", paste0("market_index_", index_version, ".csv")))
table2_paper <- read_csv(here("data", "paper", "table2_fama_macbeth_1973.csv"))

stopifnot(nrow(distinct(portfolios, period, permno)) == nrow(portfolios))

# 2. Single-month returns of each security in its estimation period, with the market return
estimation_returns <- portfolios |>
  inner_join(periods |> select(period, estimation_start, estimation_end), by = "period") |>
  inner_join(panel |> filter(single_month_ret) |> select(permno, year, month, ret, delisting_month),
             by = "permno", relationship = "many-to-many") |>
  filter(between(year, estimation_start, estimation_end)) |>
  inner_join(market_index, by = c("year", "month"))

#    Most securities have all 60 returns (1B requires 60 listed months, not 60 returns); a delisting month
#    cannot fall inside an estimation period, so none of these returns should be a delisting return
estimation_returns |> count(period, permno) |> count(period, all_60_returns = n == 60) |>
  pivot_wider(names_from = all_60_returns, values_from = n, values_fill = 0)
estimation_returns |> count(delisting_month)

# 3. Market model for each security: beta, and the standard deviation of its residuals, s(e_i)
security_betas <- estimation_returns |>
  group_by(period, portfolio, permno) |>
  mutate(beta_i = cov(ret, rm) / var(rm),
         alpha_i = mean(ret) - beta_i * mean(rm),
         residual = ret - alpha_i - beta_i * rm) |>
  summarise(n_returns = n(),
            beta_i = first(beta_i),
            s_ei = sqrt(sum(residual^2) / (n_returns - 2)),
            .groups = "drop")

#    Portfolio beta and mean s(e_i): averages over the securities in the portfolio
portfolio_averages <- security_betas |>
  group_by(period, portfolio) |>
  summarise(securities = n(),
            beta = mean(beta_i),
            mean_s_ei = mean(s_ei),
            .groups = "drop")

# 4. Monthly portfolio returns (equal-weighted) and their market-model regression
portfolio_returns <- estimation_returns |>
  group_by(period, portfolio, year, month, rm) |>
  summarise(rp = mean(ret), securities_with_return = n(), .groups = "drop")

portfolio_regressions <- portfolio_returns |>
  group_by(period, portfolio) |>
  mutate(beta_rp = cov(rp, rm) / var(rm),
         alpha_rp = mean(rp) - beta_rp * mean(rm),
         residual = rp - alpha_rp - beta_rp * rm) |>
  summarise(months = n(),
            beta_portfolio_regression = first(beta_rp),
            r2 = cor(rp, rm)^2,
            s_rp = sd(rp),
            s_ep = sqrt(sum(residual^2) / (months - 2)),
            s_rm = sd(rm),
            .groups = "drop")

stopifnot(all(portfolio_regressions$months == 60))

# 5. Table 2 for all nine periods: s(beta_p) from the paper's formula, and the ratio s(e_p) / mean s(e_i)
table2 <- periods |>
  transmute(period, estimation_period = paste0(estimation_start, "-", str_sub(estimation_end, 3, 4))) |>
  inner_join(portfolio_averages, by = "period") |>
  inner_join(portfolio_regressions, by = c("period", "portfolio")) |>
  mutate(se_beta = s_ep / (sqrt(months) * s_rm),
         ratio = s_ep / mean_s_ei) |>
  select(period, estimation_period, portfolio, securities, beta, se_beta, r2, s_rp, s_ep, mean_s_ei, ratio,
         beta_portfolio_regression)

#    The portfolio beta (average of the securities' betas) and the slope of the portfolio regression agree
#    exactly when every security has all 60 returns; the gap elsewhere is small
table2 |> summarise(max_gap = max(abs(beta - beta_portfolio_regression)))

# 6. The four periods of the paper, beside its values
comparison <- table2 |>
  select(-beta_portfolio_regression) |>
  inner_join(table2_paper |> rename_with(~ paste0("fm_", .x), -c(estimation_period, portfolio)),
             by = c("estimation_period", "portfolio"))

comparison |>
  select(estimation_period, portfolio, securities, beta, fm_beta, r2, fm_r2, s_rp, fm_s_rp, s_ep, fm_s_ep, mean_s_ei, fm_mean_s_ei) |>
  print(n = 80)

#    Average absolute gap to the paper, by period and statistic
comparison |>
  group_by(estimation_period) |>
  summarise(beta = mean(abs(beta - fm_beta)),
            se_beta = mean(abs(se_beta - fm_se_beta)),
            r2 = mean(abs(r2 - fm_r2)),
            s_rp = mean(abs(s_rp - fm_s_rp)),
            s_ep = mean(abs(s_ep - fm_s_ep)),
            mean_s_ei = mean(abs(mean_s_ei - fm_mean_s_ei)),
            ratio = mean(abs(ratio - fm_ratio)))

#    Betas rise from portfolio 1 to 20 in every period; "inversions" counts the adjacent portfolios whose
#    order flips in the estimation period (the paper's four periods show none)
table2 |> group_by(period) |> summarise(beta_p1 = first(beta), beta_p20 = last(beta), inversions = sum(diff(beta) < 0))

# 7. Save
write_csv(table2, here("output", paste0("table2_", index_version, ".csv")))
