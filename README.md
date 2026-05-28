# World Layoffs – SQL Data Cleaning Project

## Overview
This project uses **SQL Server** to clean and prepare a real-world layoffs dataset imported from a CSV file into a `world_layoffs` database.  
The goal is to remove duplicates, standardize values, fix nulls and bad formats, and produce a clean staging table ready for analysis.

---

## Data Flow

1. **Raw import**
   - CSV imported into table: `layoffs`
   - Raw data kept unchanged for reference

2. **Staging tables**
   - `layoffs_staging` created as a copy of `layoffs`:
     ```sql
     SELECT * INTO layoffs_staging FROM layoffs;
     ```
   - `layoffs_staging2` created with an added `rownum` column for duplicate handling:
     ```sql
     SELECT * INTO layoffs_staging2
     FROM (
         SELECT *,
             ROW_NUMBER() OVER (
                 PARTITION BY company, [location], industry,
                              total_laid_off, percentage_laid_off, [date],
                              stage, country, funds_raised_millions
                 ORDER BY company
             ) AS rownum
         FROM layoffs_staging
     ) AS t;
     ```

---

## Data Cleaning Steps

### 1. Removing Duplicates
- Duplicates identified using `ROW_NUMBER()` over key business columns.
- Rows with `rownum > 1` are treated as duplicates and removed:

```sql
WITH duplicateCte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company, [location], industry,
                            total_laid_off, percentage_laid_off, [date],
                            stage, country, funds_raised_millions
               ORDER BY company
           ) AS rownum
    FROM layoffs_staging
)
DELETE FROM duplicateCte
WHERE rownum > 1;
```

---

### 2. Standardizing Data

**a. Trimming whitespace in text columns**

```sql
-- Company names
UPDATE layoffs_staging2
SET company = TRIM(company);
```

**b. Normalizing industry values (e.g. Crypto variants → `Crypto`)**

```sql
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
```

**c. Cleaning country names (removing trailing dots)**

```sql
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';
```

**d. Converting date strings to proper `DATE` type**

```sql
-- Preview conversion
SELECT [date], TRY_CONVERT(date, [date], 101)
FROM layoffs_staging2
ORDER BY 1;

-- Update only convertible values
UPDATE layoffs_staging2
SET [date] = TRY_CONVERT(date, [date], 101)
WHERE TRY_CONVERT(date, [date], 101) IS NOT NULL;

-- Change column type to DATE
ALTER TABLE layoffs_staging2
ALTER COLUMN [date] DATE;
```

---

### 3. Handling NULLs and 'null' String Values

**a. Converting string `'null'` to actual NULL in `industry`**

```sql
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = 'null';
```

**b. Inferring missing industry from other rows of the same company (self join)**

```sql
UPDATE t1
SET t1.industry = t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;
```

This fills in missing `industry` values when another row for the same company has a valid industry.

---

### 4. Removing Unusable Rows

Some rows cannot be used for analysis if key metrics are missing or non-fixable.

Example: removing rows where `percentage_laid_off` is unusable:

```sql
DELETE FROM layoffs_staging2
WHERE percentage_laid_off = 'null'
  AND percentage_laid_off IS NULL;
```

(Adjust this condition based on your final schema and data types.)

You can optionally drop helper columns like `rownum` after cleaning:

```sql
-- ALTER TABLE layoffs_staging2 DROP COLUMN rownum;
```

---

## Key SQL Concepts Used

- `SELECT INTO` to create staging tables
- Common Table Expressions (**CTE**) with `ROW_NUMBER()` for duplicate detection
- String cleaning with `TRIM()` and `TRIM(... FROM ...)`
- Standardizing categorical values using `UPDATE ... WHERE ... LIKE`
- Date conversion with `TRY_CONVERT` and altering column data types
- Handling `NULL` vs `'null'` string values
- Self join to populate missing values from related rows
- Targeted `DELETE` to remove non-analysable records

---

## How to Use This Project

1. Create a SQL Server database, e.g.:
   ```sql
   CREATE DATABASE world_layoffs;
   USE world_layoffs;
   ```
2. Import the CSV into a table named `layoffs` using SSMS Import Wizard.
3. Run the SQL script from this repository to:
   - Create staging tables
   - Clean and standardize the data
4. Use `layoffs_staging2` as the cleaned dataset for analysis and reporting.

---

## Future Improvements

- Add constraints and proper data types for all columns.
- Create views for analysis (e.g., layoffs by year, country, industry).
- Export cleaned data for use in Power BI/Tableau dashboards.
