# 02. Build the stock-month panel and the calendar of the nine periods
#
# Input: the CRSP files saved by script 01 (data/raw). Output, in data/processed (git-ignored):
#   stock_month_panel.csv   one row per issue and month while the issue is listed on the NYSE, including the
#                           month in which it delists
#   periods.csv             the nine periods of Table 1
#   available.csv           the securities available in each period (the same under both alternatives of decision 1)
#
# The choices we fixed in advance (Section 2 of our plan):
#   - the universe is every issue CRSP lists on the NYSE in that month (exchange code 1 in the name history),
#     whatever its share code; shrcd is kept for the robustness check with codes 10 and 11 only
#   - a return counts only if it covers a single month, that is, CRSP also has a price at the end of the
#     previous month; after a month without a price, CRSP's next return spans both months
#   - a stock that delists contributes its CRSP delisting return in the month of its delisting date,
#     compounded with that month's single-month return where both exist
# Months without a price or a return stay in the panel, because alternative 1B counts listed months,
# return or not.

library(tidyverse)
library(here)

# 1. Read the CRSP files saved by script 01
msf <- read_csv(here("data", "raw", "crsp_msf.csv"))
msenames <- read_csv(here("data", "raw", "crsp_msenames.csv"))
msedelist <- read_csv(here("data", "raw", "crsp_msedelist.csv"))

# 2. Prices and single-month returns. CRSP marks a bid/ask average with a minus sign, so any price other
#    than zero or missing is a valid month-end price. A return is a single-month return if the issue also
#    has a valid price at the end of the previous calendar month.
msf <- msf |>
  mutate(year = year(date),
         month = month(date),
         has_price = !is.na(prc) & prc != 0) |>
  arrange(permno, date) |>
  group_by(permno) |>
  mutate(months_since_previous_row = (year * 12 + month) - lag(year * 12 + month),
         previous_month_price = lag(has_price, default = FALSE) & months_since_previous_row == 1,
         single_month_ret = !is.na(ret) & previous_month_price) |>
  ungroup()

msf |> count(months_since_previous_row)    # 1 for every row except each issue's first: CRSP has a row for every month

# 3. Keep the months in which the issue is listed on the NYSE: the month-end date falls inside one of its
#    name records with exchange code 1. The share code comes from that record.
nyse_names <- msenames |>
  filter(exchcd == 1) |>
  select(permno, namedt, nameendt, shrcd)

panel <- msf |>
  inner_join(nyse_names, by = "permno", relationship = "many-to-many") |>
  filter(date >= namedt, date <= nameendt) |>
  select(permno, date, year, month, shrcd, prc, ret, has_price, previous_month_price, single_month_ret)

# 4. Delistings from the NYSE between January 1926 and June 1968: the delisting date falls inside one of
#    the issue's NYSE name records. Code 100 means the issue is still trading.
nyse_delistings <- msedelist |>
  filter(dlstcd != 100, dlstdt >= ymd("1926-01-01"), dlstdt <= ymd("1968-06-30")) |>
  inner_join(nyse_names, by = "permno", relationship = "many-to-many") |>
  filter(dlstdt >= namedt, dlstdt <= nameendt) |>
  distinct(permno, .keep_all = TRUE) |>
  transmute(permno, year = year(dlstdt), month = month(dlstdt), dlstcd, dlret)

nrow(nyse_delistings)
nyse_delistings |> count(has_delisting_return = !is.na(dlret))    # without one, the stock just drops out, which can bias returns upwards (Shumway, 1997)

# 5. The month of each delisting. Most stocks stop trading during that month, so its CRSP row (no price,
#    no return) falls after the end of the NYSE name record and step 3 left it out. We add it back.
delisting_rows <- msf |>
  semi_join(nyse_delistings, by = c("permno", "year", "month")) |>
  anti_join(panel, by = c("permno", "year", "month")) |>
  select(permno, date, year, month, prc, ret, has_price, previous_month_price, single_month_ret)

nrow(delisting_rows)

# 6. The return that enters portfolio averages and the index. The delisting return goes in the month of
#    the delisting: compounded with that month's single-month return where both exist, alone otherwise.
#    Like any other return, it counts only if it covers a single month (the previous month has a price).
panel <- panel |>
  bind_rows(delisting_rows) |>
  left_join(nyse_delistings, by = c("permno", "year", "month")) |>
  arrange(permno, year, month) |>
  group_by(permno) |>
  fill(shrcd) |>
  ungroup() |>
  mutate(delisting_month = !is.na(dlstcd),
         ret_with_delisting = case_when(single_month_ret & !is.na(dlret) ~ (1 + ret) * (1 + dlret) - 1,
                                        previous_month_price & !is.na(dlret) ~ dlret,
                                        single_month_ret ~ ret))

panel |> count(permno, year, month) |> filter(n > 1)    # no issue should appear twice in a month

panel |>
  filter(delisting_month) |>
  count(has_delisting_return = !is.na(dlret), used = !is.na(ret_with_delisting))    # used FALSE: no delisting return, or one spanning several months

glimpse(panel)

# 7. The calendar of the nine periods (Table 1 of the paper). The last testing period ends in June 1968.
periods <- tribble(
  ~period, ~formation_start, ~formation_end, ~estimation_start, ~estimation_end, ~testing_start, ~testing_end,
  1, 1926, 1929, 1930, 1934, 1935, 1938,
  2, 1927, 1933, 1934, 1938, 1939, 1942,
  3, 1931, 1937, 1938, 1942, 1943, 1946,
  4, 1935, 1941, 1942, 1946, 1947, 1950,
  5, 1939, 1945, 1946, 1950, 1951, 1954,
  6, 1943, 1949, 1950, 1954, 1955, 1958,
  7, 1947, 1953, 1954, 1958, 1959, 1962,
  8, 1951, 1957, 1958, 1962, 1963, 1966,
  9, 1955, 1961, 1962, 1966, 1967, 1968
)

# 8. The securities available in each period: listed on the NYSE with a valid price at the end of the
#    month before the testing period starts (December of the last estimation year), which is how CRSP's
#    NYSE index counts issues
available <- panel |>
  filter(has_price, month == 12) |>
  inner_join(periods |> select(period, estimation_end), by = c("year" = "estimation_end")) |>
  select(period, permno, shrcd)

available |> count(period)

# 9. Save the panel, the calendar and the available securities
write_csv(panel, here("data", "processed", "stock_month_panel.csv"))
write_csv(periods, here("data", "processed", "periods.csv"))
write_csv(available, here("data", "processed", "available.csv"))
