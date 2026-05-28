
/*First dropping the table if allready present*/
--drop table layoffs;

/*imported the data from CSV to sql in table layoff and verifying the data loaded
  And creating a staging table to store all the data and keeping raw data in layoffs table*/
select * into layoffs_staging from layoffs;

select * from layoffs_staging ;

/*Data cleaning strategy*/
-- 1.Removing duplicates
-- 2.Standardizing the data - Fixing data issues
-- 3.Fixing the Null values and blank values data
-- 4.Removing the columns and rows not required for the analysis or not relevant and cannot be predicted having many null values for the main analysis 

-- 1.Removing duplicates
/*Checking for the duplicate data in the table*/
with duplicateCte As
(
select *,
ROW_NUMBER() over
(partition by 
company,[location],industry,total_laid_off,percentage_laid_off,[date],stage,country,funds_raised_millions order by company) as rownum
from layoffs_staging
)
select * from duplicateCte where rownum >1;

/*Deleting the duplicate data*/
with duplicateCte As
(
select *,
ROW_NUMBER() over
(partition by 
company,[location],industry,total_laid_off,percentage_laid_off,[date],stage,country,funds_raised_millions order by company) as rownum
from layoffs_staging
)
delete from duplicateCte where rownum >1


/*dropping the table and Creating to store rownumber column in the table and perform all the cleaning on this table*/
--drop table layoffs_staging2 

select * into layoffs_staging2 from (select *,
ROW_NUMBER() over
(partition by 
company,[location],industry,total_laid_off,percentage_laid_off,[date],stage,country,funds_raised_millions order by company) as rownum
from layoffs_staging) as t;


-- 2.Standardizing the data - Fixing data issues

/*Checking for white spaces in starting and ending of the column values and checking after triming*/
/*Updating after triming the column data*/

select company, trim(company) from layoffs_staging2;

update layoffs_staging2 
set company = trim(company);

select * from layoffs_staging2 where industry like 'Crypto%';

update layoffs_staging2 
set industry = 'Crypto' 
where industry like 'Crypto%';

/*triming the trailing places in the values*/

select distinct country , trim(trailing '.'from country)from layoffs_staging2 order by 1;

update layoffs_staging2 
set country = trim(trailing '.'from country) 
where country like 'United States%';

/*Correcting the date format*/

select [date],* from layoffs_staging2 order by 1;

select [date] ,try_CONVERT(date, [date], 101) from layoffs_staging2 order by 1;

UPDATE layoffs_staging2 
SET [date] = TRY_CONVERT(date, [date], 101) 
WHERE TRY_CONVERT(date, [date], 101) IS NOT NULL ;

/*changing the datatype of the column to date*/
alter table layoffs_staging2 
alter column [date] date;

-- 3.Fixing the Null values and blank values data
/*Checking for the null and blank values*/

select * from layoffs_staging2 where total_laid_off = 'null';

/*Both the main analysis column are null and cannot be fixed*/
select * from layoffs_staging2 where total_laid_off = 'null' and percentage_laid_off = 'null';

select * from layoffs_staging2 where percentage_laid_off = 'null';


select distinct industry from layoffs_staging2;

select * from layoffs_staging2 where industry = 'null' or industry is null;

select * from layoffs_staging2 where company = 'Airbnb';

/*Checking and updating the blanks and 'null' string values to Null*/

select * from layoffs_staging2 where industry is null;

update layoffs_staging2 
set industry = null 
where industry = 'null';

/*selecting the company which have industry as null and value present so that we can populate the value if the
company is same then it belongs to the same industry*/

select t1.industry,t2.industry
from layoffs_staging2 t1 
join layoffs_staging2 t2
on t1.company = t2.company
where t1.industry is null and t2.industry is not null;

UPDATE t1
SET t1.industry = t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;


  select * from layoffs_staging2;

-- 4.Removing the columns and rows not required for the analysis or not relevant and cannot be predicted having many null values for the main analysis 

/*The values that cannot be fixxed or used for analysis*/

select * from layoffs_staging2 where percentage_laid_off = 'null' and 
percentage_laid_off is null;

/*Removing these values from above query*/
Delete from layoffs_staging2 where percentage_laid_off = 'null' and 
percentage_laid_off is null;


--alter table layoffs_staging2 drop column rownum;

