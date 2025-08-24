# 🌪️ Atlantic Hurricanes — Cleaning Walkthrough

This project demonstrates how I cleaned the messy **Atlantic Hurricanes (Data Cleaning Challenge)** dataset (1920–2020) and transformed it into a structured, query-ready SQL view.

---

## 📂 Files
- `data/raw/Hurricanes.csv` — original Kaggle CSV (CC0).
- `sql/Hurricanes final clean.sql` — end-to-end T-SQL script that cleans the raw data and builds the `dbo.Hurricanes_Final` view.
- `data/clean/Hurricanes_Final.csv` — optional export of the final cleaned dataset.

---

## 🔄 Reproduce

1. Create a database `HurricanesDB` and import `data/raw/Hurricanes.csv` into `dbo.Hurricanes`.
2. Run:
   ```sql
   sql/Hurricanes final clean.sql
