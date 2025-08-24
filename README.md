# Atlantic Hurricanes — Cleaning Walkthrough

This repo shows how I cleaned the messy **Atlantic Hurricanes (Data Cleaning Challenge)** dataset (1920–2020).

## Files
- `data/raw/Hurricanes.csv` – original Kaggle CSV (CC0).
- `sql/hurricanes_cleaning.sql` – end-to-end T-SQL script that builds `Hurricanes_Final`.
- `data/clean/hurricanes_clean.csv` – export of the final view.

## Reproduce
1. Create database `HurricanesDB` and import `data/raw/Hurricanes.csv` into `dbo.Hurricanes`.
2. Run `sql/hurricanes_cleaning.sql`.
3. (Optional) export `Hurricanes_Final` to `data/clean/hurricanes_clean.csv`.

## Notes
- Dates are exported as `YYYY-MM-DD`.
- Text is trimmed and normalized; quotes in `Areas_affected` are CSV-safe.

**Source**  
Valery Liamtsau, *Atlantic Hurricanes (Data Cleaning Challenge)*, Kaggle, CC0 1.0.  
https://www.kaggle.com/datasets/valerylia/atlantic-hurricanes-data-cleaning-challenge
