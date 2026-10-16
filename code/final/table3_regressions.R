# Table 3: the monthly risk-return regressions and their summary (Niklas)
#
# Each month of the testing periods (January 1935 to June 1968, 402 months), the returns of the 20 portfolios are
# regressed on the portfolios' risk measures (Fama and MacBeth, 1973, eq. 10):
#   R_pt = gamma0_t + gamma1_t beta_p + gamma2_t beta_p^2 + gamma3_t s_p(e_i) + eta_pt
# beta_p is the average beta of the securities in portfolio p, beta_p^2 the average of their squared betas and s_p(e_i)
# the average standard deviation of their market-model residuals, all estimated from data before month t
# (testing_portfolios_<version>.csv). The four panels of Table 3 use four versions of the regression:
#   A: beta only;  B: beta and beta squared;  C: beta and s(e);  D: all three
# Table 3 then summarises the monthly coefficients over ten periods: their means, standard deviations, first-order
# serial correlations and t-statistics, the mean of gamma0_t minus the riskless rate (CRSP's 30-day bill,
# code/common/03_riskless_rate.R), and the mean and standard deviation of the monthly adjusted r-squared.
#
# Set index_version to "2A" or "2B" to choose the market index (decision 2). 2B is the agreed version
# (decisions/decision2.md); 2A is the robustness check.
# Input:  data/processed/testing_portfolios_<version>.csv, market_index_<version>.csv, riskless_rate.csv,
#         data/paper/table3_fama_macbeth_1973.csv (Table 3 as printed, typed from the paper)
# Output: output/table3_<version>.csv and output/table3_comparison_<version>.csv

library(tidyverse)
library(here)

index_version <- "2B"

# 1. Read the testing-period portfolios, the market index, the riskless rate and the paper's Table 3
testing_portfolios <- read_csv(here("data", "processed", paste0("testing_portfolios_", index_version, ".csv")))
market_index <- read_csv(here("data", "processed", paste0("market_index_", index_version, ".csv")))
riskless_rate <- read_csv(here("data", "processed", "riskless_rate.csv"))
table3_paper <- read_csv(here("data", "paper", "table3_fama_macbeth_1973.csv"))

stopifnot(nrow(distinct(testing_portfolios, year, month, portfolio)) == 402 * 20)

# 2. The four cross-sectional regressions each month, one for each panel of Table 3
fits <- testing_portfolios |>
  nest_by(year, month) |>
  mutate(fit_A = list(lm(rp ~ beta_p, data = data)),
         fit_B = list(lm(rp ~ beta_p + beta_sq_p, data = data)),
         fit_C = list(lm(rp ~ beta_p + s_e_p, data = data)),
         fit_D = list(lm(rp ~ beta_p + beta_sq_p + s_e_p, data = data)))

# 3. The monthly coefficients and adjusted r-squared of each regression, one row per panel and month, with
#    gamma0 minus the riskless rate of that month
gammas <- bind_rows(
  fits |> summarise(panel = "A",
                    gamma0 = coef(fit_A)[["(Intercept)"]], gamma1 = coef(fit_A)[["beta_p"]],
                    r2 = summary(fit_A)$adj.r.squared, .groups = "drop"),
  fits |> summarise(panel = "B",
                    gamma0 = coef(fit_B)[["(Intercept)"]], gamma1 = coef(fit_B)[["beta_p"]],
                    gamma2 = coef(fit_B)[["beta_sq_p"]],
                    r2 = summary(fit_B)$adj.r.squared, .groups = "drop"),
  fits |> summarise(panel = "C",
                    gamma0 = coef(fit_C)[["(Intercept)"]], gamma1 = coef(fit_C)[["beta_p"]],
                    gamma3 = coef(fit_C)[["s_e_p"]],
                    r2 = summary(fit_C)$adj.r.squared, .groups = "drop"),
  fits |> summarise(panel = "D",
                    gamma0 = coef(fit_D)[["(Intercept)"]], gamma1 = coef(fit_D)[["beta_p"]],
                    gamma2 = coef(fit_D)[["beta_sq_p"]], gamma3 = coef(fit_D)[["s_e_p"]],
                    r2 = summary(fit_D)$adj.r.squared, .groups = "drop")) |>
  inner_join(riskless_rate |> select(year, month, t30ret), by = c("year", "month")) |>
  mutate(gamma0_rf = gamma0 - t30ret)

gammas |> count(panel)    # 402 months in each panel

# 4. The ten periods of Table 3 (the data end in June 1968)
table3_periods <- tribble(
  ~period, ~first_year, ~last_year,
  "1935-6/68", 1935, 1968,
  "1935-45", 1935, 1945,
  "1946-55", 1946, 1955,
  "1956-6/68", 1956, 1968,
  "1935-40", 1935, 1940,
  "1941-45", 1941, 1945,
  "1946-50", 1946, 1950,
  "1951-55", 1951, 1955,
  "1956-60", 1956, 1960,
  "1961-6/68", 1961, 1968
)

# 5. Table 3: the summary statistics of the monthly coefficients in each period. As in the paper, the serial
#    correlation of gamma1 is computed about its sample mean (rhoM) and the others about a mean of zero (rho0), and
#    t = mean / (standard deviation / square root of the number of months).
table3 <- gammas |>
  cross_join(table3_periods) |>
  filter(between(year, first_year, last_year)) |>
  mutate(period = factor(period, levels = table3_periods$period)) |>
  arrange(panel, period, year, month) |>
  group_by(panel, period) |>
  summarise(months = n(),
            mean_gamma0 = mean(gamma0),
            mean_gamma1 = mean(gamma1),
            mean_gamma2 = mean(gamma2),
            mean_gamma3 = mean(gamma3),
            mean_gamma0_rf = mean(gamma0_rf),
            sd_gamma0 = sd(gamma0),
            sd_gamma1 = sd(gamma1),
            sd_gamma2 = sd(gamma2),
            sd_gamma3 = sd(gamma3),
            rho0_gamma0_rf = sum(gamma0_rf * lag(gamma0_rf), na.rm = TRUE) / sum(gamma0_rf^2),
            rhoM_gamma1 = sum((gamma1 - mean(gamma1)) * (lag(gamma1) - mean(gamma1)), na.rm = TRUE) /
              sum((gamma1 - mean(gamma1))^2),
            rho0_gamma2 = sum(gamma2 * lag(gamma2), na.rm = TRUE) / sum(gamma2^2),
            rho0_gamma3 = sum(gamma3 * lag(gamma3), na.rm = TRUE) / sum(gamma3^2),
            t_gamma0 = mean(gamma0) / (sd(gamma0) / sqrt(n())),
            t_gamma1 = mean(gamma1) / (sd(gamma1) / sqrt(n())),
            t_gamma2 = mean(gamma2) / (sd(gamma2) / sqrt(n())),
            t_gamma3 = mean(gamma3) / (sd(gamma3) / sqrt(n())),
            t_gamma0_rf = mean(gamma0_rf) / (sd(gamma0_rf) / sqrt(n())),
            mean_r2 = mean(r2),
            sd_r2 = sd(r2),
            .groups = "drop") |>
  mutate(period = as.character(period))

table3 |> select(panel, period, months, mean_gamma0, mean_gamma1, mean_gamma2, mean_gamma3, t_gamma1, mean_r2) |>
  print(n = 40)

# 6. Comparison with the paper: every statistic the paper prints, beside ours
comparison <- table3 |>
  pivot_longer(-c(panel, period, months), names_to = "statistic", values_to = "replication") |>
  inner_join(table3_paper |>
               pivot_longer(-c(panel, period, months), names_to = "statistic", values_to = "paper") |>
               rename(months_paper = months),
             by = c("panel", "period", "statistic")) |>
  filter(!is.na(paper)) |>
  mutate(difference = replication - paper)

stopifnot(all(comparison$months == comparison$months_paper))

#    The tests over the whole period 1935-6/68, on which the paper's conclusions rest
comparison |>
  filter(period == "1935-6/68", str_detect(statistic, "mean_gamma|t_gamma")) |>
  select(panel, statistic, replication, paper) |>
  print(n = 40)

#    Average absolute gap to the paper over the ten periods, by statistic and panel
comparison |>
  group_by(panel, statistic) |>
  summarise(mean_abs_difference = mean(abs(difference)), .groups = "drop") |>
  pivot_wider(names_from = panel, values_from = mean_abs_difference) |>
  print(n = 25)

# 7. The check from our plan (Section 5): in panel A, gamma0 + gamma1 should be close to the market return each
#    month, because the portfolios' average beta is close to one and their average return close to the index
gammas |>
  filter(panel == "A") |>
  inner_join(market_index, by = c("year", "month")) |>
  summarise(months = n(),
            mean_gap = mean(gamma0 + gamma1 - rm),
            mean_abs_gap = mean(abs(gamma0 + gamma1 - rm)),
            correlation = cor(gamma0 + gamma1, rm))

# 8. Save
write_csv(table3, here("output", paste0("table3_", index_version, ".csv")))
write_csv(comparison, here("output", paste0("table3_comparison_", index_version, ".csv")))
