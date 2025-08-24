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
---

##  This script will:

- Normalize messy text, whitespace, and quotes.  
- Parse and standardize dates into `StartDate` and `EndDate`.  
- Convert wind speeds into both **mph** and **km/h**.  
- Normalize pressure into both **hPa** and **inHg**.  
- Convert damage estimates (million/billion/k) into numeric USD.  
- Derive **DurationDays** and Saffir-Simpson **Category**.  
---

## 📊 Before vs. After

**Raw data (sample)**  
![Raw sample](images/Raw%20sample.png)

**Cleaned data (sample)**  
![Cleaned sample](images/Cleaned%20sample.png)
---

## 📝 Notes
- Dates are exported as `YYYY-MM-DD`.  
- `DurationDays` = difference between `StartDate` and `EndDate`.  
- Wind speeds and pressures are standardized for consistent analysis.  
- Damage text like *“Unknown”*, *“Minimal”*, etc. are set to `NULL`.  
- If opening the CSV in Excel, use **Delimited → Comma** import (not Fixed Width).  
---

## 📖 Source
Valery Liamtsau, *Atlantic Hurricanes (Data Cleaning Challenge)*, Kaggle, CC0 1.0.  
[https://www.kaggle.com/datasets/valerylia/atlantic-hurricanes-data-cleaning-challenge](https://www.kaggle.com/datasets/valerylia/atlantic-hurricanes-data-cleaning-challenge)
