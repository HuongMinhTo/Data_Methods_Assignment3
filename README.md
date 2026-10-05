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

