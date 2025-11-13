
SELECT * FROM layoffs;

-- First, making a staging table in case anything goes wrong:

CREATE TABLE layoffs_staging AS
SELECT *
FROM layoffs;


SELECT * FROM layoffs_staging;

-- Duplicate Removal:

-- Since there isn't an id column serving as a unique identifier for each row (i.e primarky key),
-- we'll employ a different method for finding duplicates: Using ROW_NUMBER() and partitioning
-- by all columns in the table

SELECT *,
	ROW_NUMBER() OVER(PARTITION BY company, location, total_laid_off, percentage_laid_off, date, stage,
	country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Converting the above to a CTE (used rather than a subquery for readability) and then filtering for
-- where row_num >= 2, i.e for duplicates

WITH dups AS (SELECT *,
				ROW_NUMBER() OVER(PARTITION BY company, location, total_laid_off, percentage_laid_off, date, stage,
				country, funds_raised_millions) AS row_num
			  FROM layoffs_staging)
SELECT * 
FROM dups
WHERE row_num > 1;

-- Creating another staging table to get rid of these duplicates

CREATE TABLE IF NOT EXISTS public.layoffs_staging2
(
    company text,
    location text,
    industry text,
    total_laid_off double precision,
    percentage_laid_off double precision,
    date text,
    stage text,
    country text,
    funds_raised_millions double precision,
	row_num INT
);


-- Inserting our table with identified duplicates:
INSERT INTO layoffs_staging2
SELECT *,
	ROW_NUMBER() OVER(PARTITION BY company, location, total_laid_off, percentage_laid_off, date, stage,
	country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Deleting duplicate rows:

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- Making sure they're gone:
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;
-- Good to go

-- Getting rid of row_num column as it is now just taking up unnecessary space:
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;





-- Standardizing Data:

-- Trimming company names:

UPDATE layoffs_staging2
SET company = TRIM(company);


-- Looking at industry:

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- Need to fix Crypto (Some industry values for Cryptocurrency, Crypto Currency, and just Crypto)

SELECT *
FROM layoffs_staging2
WHERE industry LIKE '%Crypto%';

-- Since vast majority of values relating to Crypto are simply 'Crypto, We'll replace variations of the name with this

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';


-- Looking at location;

SELECT DISTINCT location 
FROM layoffs_staging2
ORDER BY 1;

-- A few values have differences due to accents, can choose to keep this with or without ther accent, I will unaccent everything
-- For Malmo:

UPDATE layoffs_staging2
SET location = 'Malmo'
WHERE location LIKE 'Malm%';

-- For Dusseldorf:

UPDATE layoffs_staging2 
SET location = 'DusselDorf'
WHERE location = 'Düsseldorf';


-- Now looking at Countries:

SELECT DISTINCT country 
FROM layoffs_staging2
ORDER BY 1;

-- Slight problem with United States, a value has a period at the end

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Next, the date column is currently a text column, need to fix this:

UPDATE layoffs_staging2
SET date = TO_DATE(date, 'MM/DD/YYYY');


ALTER TABLE layoffs_staging2
ALTER COLUMN date TYPE date
USING TO_DATE(date, 'YYYY/MM/DD'); 

-- Note: Should've just ran the ALTER statement and had the format as 'MM/DD/YYYY'



-- Dealing with NULLs:

-- In industry column:

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;

-- For companies such as Airbnb, there are NULLs in the industry column but other instances have a value for 
-- indystry (being Travel). To populate the NULL, doing a self join

SELECT st1.industry, st2.industry
FROM layoffs_staging2 st1
JOIN layoffs_staging2 st2
	ON st1.company = st2.company
	AND st1.location = st2.location -- defensive
WHERE st1.industry IS NULL
AND st2.industry IS NOT NULL; -- Filter basically matches NULL instances with not NULL instances to allow us to know what value to populate with

-- Converting the above into an UPDATE statement:

UPDATE layoffs_staging2 st1
SET industry = st2.industry
FROM layoffs_staging2 st2
WHERE st1.company = st2.company
AND st1.location = st2.location
AND st1.industry IS NULL
AND st2.industry IS NOT NULL;


-- Industry for Bally's Interactive still NULL as there were no other instances with the industry value
SELECT * FROM layoffs_staging2
WHERE industry IS NULL;


-- For the other NULLs, such as in the total_laid_off or percentage_laid_off columns, we can't fill them with the data present as there
-- isn't a column with total employees that we could derive one of the afforementioned values from 



-- Potentially removing rows and columns that don't add any information or value:

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Could get rid of these rows if a subsequent analysis will be heavily dependent on them

-- Data is ready to go




