# Run the final replication in order: CRSP data -> stock-month panel -> Tables 1, 2 and 3
# Open Data_Methods_Assignment3.Rproj in RStudio first, so that here() points at the repository folder, and create
# config.csv from config_example.csv with your WRDS user name (the password stays in your own pgpass file).
# echo = TRUE makes each script print its code and its results in the console.
#
# This runs code/common/ and code/final/ only, which reproduce the agreed Tables 1 to 3 (decision 1: 1B,
# decision 2: 2B). The alternative implementations are listed at the end.

library(here)

# Common replication
source(here("code", "common", "01_wrds_pull.R"), echo = TRUE)                  # CRSP files and bill rates from WRDS
source(here("code", "common", "02_stock_month_panel.R"), echo = TRUE)          # stock-month panel, periods, available issues
source(here("code", "common", "03_riskless_rate.R"), echo = TRUE)              # 30-day bill return

# Final replication
source(here("code", "final", "table1_sample.R"), echo = TRUE)                  # Table 1 and the agreed sample (1B)
source(here("code", "final", "table1_share_codes_10_11.R"), echo = TRUE)       # Table 1 for share codes 10 and 11
source(here("code", "final", "market_index.R"), echo = TRUE)                   # market index (2B)
source(here("code", "final", "table2_portfolio_formation.R"), echo = TRUE)     # formation betas and the 20 portfolios
source(here("code", "final", "table2_estimation_statistics.R"), echo = TRUE)   # Table 2
source(here("code", "final", "table3_testing_portfolios.R"), echo = TRUE)      # testing-period portfolio panel
source(here("code", "final", "table3_regressions.R"), echo = TRUE)             # Table 3

# The alternatives behind decisions 1 and 2 (not needed for the agreed tables):
# source(here("code", "decision1", "alternative_A", "table1_complete_return_rule.R"), echo = TRUE)
# source(here("code", "decision1", "alternative_B", "table1_listed_month_rule.R"), echo = TRUE)
# source(here("code", "decision2", "alternative_A", "market_index_2A.R"), echo = TRUE)
# source(here("code", "decision2", "alternative_B", "market_index_2B.R"), echo = TRUE)
# For 2A as a robustness check, run market_index_2A.R and set index_version <- "2A" in the Table 2 and 3 scripts.
