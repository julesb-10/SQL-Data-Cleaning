# Layoffs Data Cleaning Project (SQL)

This project focuses on cleaning and standardizing a dataset of global tech layoffs using PostgreSQL. The goal was to take a raw CSV extract, identify inconsistencies, remove duplicates, standardize formats, handle missing values, and prepare the dataset for downstream analysis. I wanted to Include a brief, simple project on my GitHub focusing just on a crucial aspect of data analysis and engineering, being data cleaning. Other projects of mine also have some more advanced cleaning.

The full cleaning process was done exclusively with SQL, following a typical data-cleaning workflow: staging → deduplication → standardization → type fixes → NULL handling → validation.

---

## Project Overview

The dataset contained company-level layoff records with fields such as:

- company
- location
- industry
- total_laid_off
- percentage_laid_off
- date
- stage
- country
- funds_raised_millions

Issues included duplicate entries, inconsistent naming conventions, incorrect text formatting, messy location data, dates stored as text, and missing values.

This project demonstrates practical SQL data-cleaning techniques used in real-world ETL pipelines and analytics engineering work.

---

## Key Steps Performed

### 1. Created Staging Tables

A staging table (`layoffs_staging`) was created to preserve the raw data.  
A second staging table (`layoffs_staging2`) was used for deduplication and cleaning.

---

### 2. Duplicate Removal

Because the dataset had no primary key, duplicates were identified using:

- `ROW_NUMBER()`
- Partitioned by all columns defining a unique layoff record

Rows with `row_num > 1` were deleted, leaving only unique entries.

---

### 3. Standardizing Text Fields

#### Company Names
Trimmed extra whitespace using `TRIM()`.

#### Industries
Collapsed variations such as `Cryptocurrency`, `Crypto Currency`, and others into a single standardized label: `Crypto`.

#### Locations
Standardized accented or inconsistent spellings, for example:
- Malmö → Malmo
- Düsseldorf → DusselDorf

#### Countries
Removed punctuation issues such as `"United States."` → `"United States"`.

---

## 4. Fixing the Date Column

The date field was originally stored as text (`MM/DD/YYYY`).  
It was converted into a proper `date` type using `TO_DATE()` and an `ALTER TABLE` statement.

This ensures correct ordering, filtering, and time-based analysis.

---

## 5. Handling Missing Values (NULLs)

### Industry
Some companies had NULL industries in certain rows but valid industries in others.  
A self-join was used to populate missing values from matching rows with the same company and location:

```sql
UPDATE layoffs_staging2 st1
SET industry = st2.industry
FROM layoffs_staging2 st2
WHERE st1.company = st2.company
  AND st1.location = st2.location
  AND st1.industry IS NULL
  AND st2.industry IS NOT NULL;
```

## 6. Optional Filtering

Rows containing no meaningful layoff information (both total_laid_off and percentage_laid_off NULL) were identified.
These may optionally be removed depending on future analytical needs.


## Final Status

After cleaning, the dataset is:

Deduplicated

Standardized

Locations and industries normalized

Date values properly typed

Missing values filled where possible

Ready for analysis, BI dashboards, or feature engineering

## Skills Demonstrated

Window functions with ROW_NUMBER()

Self-joins for NULL imputation

Text cleaning and standardization

Date conversion and type casting

Use of staging tables for safe transformations

Structured SQL cleaning workflow

Defensive SQL practices and quality control
