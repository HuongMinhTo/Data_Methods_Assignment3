# 01. Pull the CRSP data from WRDS
#
# CRSP data is licensed through WRDS: each of us downloads it with our own WRDS login, and it is never
# committed (data/raw is in .gitignore). The password is not in this file either. It sits in the Postgres
# password file, which R reads automatically:
#   C:\Users\<your user name>\AppData\Roaming\postgresql\pgpass.conf
# containing one line:
#   wrds-pgdata.wharton.upenn.edu:9737:wrds:<wrds_username>:<wrds_password>
# (see the unit page "R - WRDS Connection" under Topic 2). The user name is read from config.csv:
# copy config_example.csv to config.csv and put your own WRDS user name in it (config.csv is git-ignored).
#
# We use CRSP's legacy monthly files (Section 2 of our plan):
#   crsp_a_stock.msf         monthly stock file: month-end price (prc) and total return (ret)
#   crsp_a_stock.msenames    name history: exchange code (exchcd) and share code (shrcd) over time
#   crsp_a_stock.msedelist   delisting file: delisting date, code and return (dlret)
#   crsp_a_indexes.msia      CRSP's NYSE index: equal-weighted return (ewretd) and issue counts
#   crsp_a_indexes.mcti      CRSP's 30-day Treasury bill return (t30ret)
#   ff.factors_monthly       Fama-French one-month bill return (rf), our check for 1935 to 1937

library(tidyverse)
library(DBI)
library(dbplyr)
library(RPostgres)
library(here)

# 1. Connect to the WRDS database
config <- read_csv(here("config.csv"))
wrds_username <- config |> filter(setting == "wrds_username") |> pull(value)

wrds <- dbConnect(Postgres(),
                  host = "wrds-pgdata.wharton.upenn.edu",
                  port = 9737,
                  dbname = "wrds",
                  sslmode = "require",
                  user = wrds_username)

# 2. Every issue listed on the NYSE (exchange code 1) at some time between December 1925 and June 1968
nyse_issues <- tbl(wrds, in_schema("crsp_a_stock", "msenames")) |>
  filter(exchcd == 1, namedt <= "1968-06-30", nameendt >= "1925-12-01") |>
  distinct(permno) |>
  collect()
nrow(nyse_issues)

# 3. The whole name history of those issues, so that we know in which months each one was on the NYSE
msenames <- tbl(wrds, in_schema("crsp_a_stock", "msenames")) |>
  filter(permno %in% !!nyse_issues$permno) |>
  select(permno, namedt, nameendt, exchcd, shrcd, siccd, ticker, comnam) |>
  collect()
nrow(msenames)

# 4. Monthly stock file from December 1925 (CRSP's first month-end prices, which the January 1926 returns
#    start from) to June 1968, the end of the paper's last testing period
msf <- tbl(wrds, in_schema("crsp_a_stock", "msf")) |>
  filter(permno %in% !!nyse_issues$permno, date >= "1925-12-01", date <= "1968-06-30") |>
  select(permno, date, prc, ret, retx, vol) |>
  collect()
nrow(msf)

# 5. Delisting file of the same issues (one row per issue; code 100 means the issue is still trading)
msedelist <- tbl(wrds, in_schema("crsp_a_stock", "msedelist")) |>
  filter(permno %in% !!nyse_issues$permno) |>
  select(permno, dlstdt, dlstcd, dlret, dlretx, nwperm) |>
  collect()
nrow(msedelist)

# 6. CRSP's NYSE index (alternative 2A uses ewretd; totcnt is CRSP's count of NYSE issues with a price)
msia <- tbl(wrds, in_schema("crsp_a_indexes", "msia")) |>
  filter(caldt >= "1925-12-01", caldt <= "1968-06-30") |>
  select(caldt, ewretd, ewretx, vwretd, totcnt, usdcnt) |>
  collect()

# 7. The riskless rate: CRSP's 30-day bill, and the Fama-French one-month bill to compare for 1935 to 1937
mcti <- tbl(wrds, in_schema("crsp_a_indexes", "mcti")) |>
  filter(caldt >= "1925-12-01", caldt <= "1968-06-30") |>
  select(caldt, t30ret) |>
  collect()

ff_rf <- tbl(wrds, in_schema("ff", "factors_monthly")) |>
  filter(date >= "1926-01-01", date <= "1968-06-30") |>
  select(date, rf) |>
  collect()

# 8. Save everything as CSV in data/raw (git-ignored) and note the download date
write_csv(msenames, here("data", "raw", "crsp_msenames.csv"))
write_csv(msf, here("data", "raw", "crsp_msf.csv"))
write_csv(msedelist, here("data", "raw", "crsp_msedelist.csv"))
write_csv(msia, here("data", "raw", "crsp_msia.csv"))
write_csv(mcti, here("data", "raw", "crsp_mcti.csv"))
write_csv(ff_rf, here("data", "raw", "ff_rf.csv"))
today()

dbDisconnect(wrds)
