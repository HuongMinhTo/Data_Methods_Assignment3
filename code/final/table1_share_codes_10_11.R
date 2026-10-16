# Table 1 for ordinary common shares only (share codes 10 and 11): robustness check (Niklas)
#
# Our universe is every issue CRSP lists on the NYSE, whatever its share code (plan, Section 2), because CRSP's count
# of NYSE issues with a valid price comes within five of the paper's "available" count in every period. Later work
# usually keeps only share codes 10 and 11 (ordinary shares of US companies), so the plan reports Table 1 for those
# two codes as a robustness check. The share code is the one in force in the December before each testing period.
#
# Input:  data/processed/available.csv (code/common/02_stock_month_panel.R) and sample_final.csv (Table 1 under the
#         agreed rule 1B, code/final/table1_sample.R)
# Output: output/table1_share_codes_10_11.csv

library(tidyverse)
library(here)

# 1. Read the available securities, with their share code, and the agreed sample
available <- read_csv(here("data", "processed", "available.csv"))
sample_B <- read_csv(here("data", "processed", "sample_final.csv"))

sample_B <- sample_B |>
  inner_join(available |> select(period, permno, shrcd), by = c("period", "permno"))

available |> count(shrcd)    # every available security has a share code

# 2. The paper's counts (Fama and MacBeth, 1973, Table 1)
fm_table1 <- tibble(period = 1:9,
                    fm_available = c(710, 779, 804, 908, 1011, 1053, 1065, 1162, 1261),
                    fm_meeting_requirement = c(435, 576, 607, 704, 751, 802, 856, 858, 845))

# 3. Table 1 for every NYSE issue and for share codes 10 and 11 only, beside the paper's counts
table1_share_codes <- available |>
  group_by(period) |>
  summarise(available = n(),
            available_10_11 = sum(shrcd %in% c(10, 11))) |>
  left_join(sample_B |>
              group_by(period) |>
              summarise(meeting_requirement = n(),
                        meeting_requirement_10_11 = sum(shrcd %in% c(10, 11))),
            by = "period") |>
  left_join(fm_table1, by = "period") |>
  mutate(available_minus_fm = available - fm_available,
         available_10_11_minus_fm = available_10_11 - fm_available,
         meeting_minus_fm = meeting_requirement - fm_meeting_requirement,
         meeting_10_11_minus_fm = meeting_requirement_10_11 - fm_meeting_requirement)

table1_share_codes |>
  select(period, fm_available, available, available_10_11, fm_meeting_requirement, meeting_requirement,
         meeting_requirement_10_11)

# 4. Save
write_csv(table1_share_codes, here("output", "table1_share_codes_10_11.csv"))
