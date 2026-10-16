# Replication of Fama and MacBeth (1973)

Group replication of Fama, E. F. and MacBeth, J. D. (1973), "Risk, Return, and Equilibrium: Empirical Tests", *Journal of Political Economy* 81(3), 607–636.

## Repository layout

| Folder | Contents |
|---|---|
| `code/common/` | Data pull, cleaning and the stock-month panel |
| `code/decision1/`, `code/decision2/` | Each with `alternative_A/` and `alternative_B/`, the two versions of the decision |
| `code/final/` | The agreed pipeline that produces Tables 1 to 3 |
| `reviews/`, `decisions/` | Cross-reviews (`decision1_A_review.md`, ...) and decision records (`decision1.md`, `decision2.md`) |
| `output/` | Tables and figures for the report |
| `data/raw/`, `data/processed/` | CRSP extracts and derived data, kept on our own computers and never committed |
| `data/paper/` | Values typed from the paper's tables, for comparison (committed) |

## How to run

Run the scripts in this order from the project folder (open `Data_Methods_Assignment3.Rproj`). The final pipeline
needs only `code/common/` and `code/final/`; the alternative folders are kept to show the two versions of each decision.

| Step | Script | Writes |
|---|---|---|
| 1 | `code/common/01_wrds_pull.R` (needs `config.csv`, copied from `config_example.csv`, and your WRDS password in the Postgres password file, see the script's header) | `data/raw/*.csv` |
| 2 | `code/common/02_stock_month_panel.R` | `stock_month_panel.csv`, `periods.csv`, `available.csv` |
| 3 | `code/common/03_riskless_rate.R` | `riskless_rate.csv` |
| 4 | `code/final/table1_sample.R` (decision 1: rule 1B) | `sample_final.csv`, `output/table1_final.csv` |
| 5 | `code/final/market_index.R` (decision 2: index 2B) | `market_index_2B.csv` |
| 6 | `code/final/table2_portfolio_formation.R` | `portfolios_2B.csv`, `output/portfolio_formation_summary_2B.csv` |
| 7 | `code/final/table2_estimation_statistics.R` | `output/table2_2B.csv` |
| 8 | `code/final/table3_testing_portfolios.R` | `testing_portfolios_2B.csv` |
| 9 | `code/final/table3_regressions.R` | `output/table3_2B.csv`, `output/table3_comparison_2B.csv` (Table 3 beside the paper's) |

`code/run_all.R` sources steps 1 to 9 in this order with `echo = TRUE`, plus the Table 1 check for share codes 10 and
11 (`code/final/table1_share_codes_10_11.R`) after step 4, so one Source reproduces everything.

Files without a folder are in `data/processed/`. Scripts 6 to 9 have an `index_version` switch at the top: set it to
`"2A"` (and run `code/decision2/alternative_A/market_index_2A.R` first) for the robustness check with CRSP's index.

## Data dictionary

All returns are monthly and in decimals (0.0143, not 1.43). `year` and `month` are integers.

**`data/raw/`** (script 01, CRSP through WRDS)

| File | Contents |
|---|---|
| `crsp_msf.csv` | Monthly stock file: `permno`, `date`, price `prc` (negative = bid/ask average), total return `ret`, return without dividends `retx`, volume `vol` |
| `crsp_msenames.csv` | Name history: `permno`, `namedt` to `nameendt`, exchange code `exchcd` (1 = NYSE), share code `shrcd`, `siccd`, `ticker`, `comnam` |
| `crsp_msedelist.csv` | Delistings: `permno`, date `dlstdt`, code `dlstcd` (100 = still trading), delisting return `dlret`, `dlretx`, `nwperm` |
| `crsp_msia.csv` | CRSP's NYSE index: `caldt`, equal-weighted return with dividends `ewretd`, `ewretx`, `vwretd`, issue counts `totcnt` and `usdcnt` |
| `crsp_mcti.csv` | CRSP's 30-day Treasury bill return: `caldt`, `t30ret` |
| `ff_rf.csv` | Fama-French one-month bill return: `date`, `rf` |

**`data/processed/`** (derived)

| File | One row per | Columns |
|---|---|---|
| `stock_month_panel.csv` | NYSE issue and month listed, plus the delisting month | `permno`, `date`, `year`, `month`, `shrcd`, `prc`, `ret`; `has_price` (valid month-end price); `previous_month_price`; `single_month_ret` (the return covers one month only); `dlstcd`, `dlret`; `delisting_month`; `ret_with_delisting` (single-month return, compounded with the delisting return in the delisting month) |
| `periods.csv` | Period (1 to 9) | First and last year of the formation, estimation and testing periods (Table 1) |
| `available.csv` | Period and issue | `period`, `permno`, `shrcd`: issues listed on the NYSE with a valid price in the December before the testing period |
| `riskless_rate.csv` | Month | `year`, `month`, CRSP's `t30ret`, Fama-French `rf` |
| `sample_final.csv` | Period and issue meeting the data requirement | `period`, `permno`; listed months and single-month returns in the estimation and formation periods (`estimation_months`, `formation_months`, `estimation_returns`, `formation_returns`) |
| `market_index_<version>.csv` | Month | `year`, `month`, market return `rm` (2A: CRSP's `ewretd`; 2B: rebuilt from the panel) |
| `portfolios_<version>.csv` | Period and issue | `period`, `permno`, `portfolio` (1 = lowest beta, 20 = highest), formation-period beta `beta_formation` |
| `testing_portfolios_<version>.csv` | Testing month and portfolio | `period`, `year`, `month`, `portfolio`, `n_securities` (issues with a return that month), equal-weighted return `rp`, and the averages of the issues' betas `beta_p`, squared betas `beta_sq_p` and residual standard deviations `s_e_p` |

**`data/paper/`**: `table2_fama_macbeth_1973.csv`, the paper's Table 2 (four estimation periods, 20 portfolios), and `table3_fama_macbeth_1973.csv`, its Table 3 (four panels, ten periods).

