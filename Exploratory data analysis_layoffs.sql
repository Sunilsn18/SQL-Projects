
--Exploratory data amalysis


Select * into layoffs_staging2_BKPCleaned from layoffs_staging2;

Select * from layoffs_staging2 order by total_laid_off desc;

Select Max(try_cast(replace(total_laid_off, ',','') as bigint)) as max_tota_laid_off
--,Max(percentage_laid_off) ,Max(try_cast(replace(percentage_laid_off, ',','') as bigint)) as max_percentage_laid_off
from layoffs_staging2;

update layoffs_staging2 
set total_laid_off = null where total_laid_off in
(
Select total_laid_off
from layoffs_staging2 where total_laid_off = 'null');

update layoffs_staging2 
set [date] = null where [date] in
(
Select [date]
from layoffs_staging2 where [date] = 'null');

Select Max(total_laid_off),Max(percentage_laid_off) 
from layoffs_staging2;

/*using cast as the column is nvarchar so to see the correct result need to cast it*/

Select Max(try_cast(replace(total_laid_off, ',','') as bigint)) as max_tota_laid_off,
Max(percentage_laid_off) as max_percentage_laid_off
from layoffs_staging2;

--or i can alter the column data type

alter table layoffs_staging2 alter column total_laid_off int;

Select Max(total_laid_off) as max_tota_laid_off,
Max(percentage_laid_off) as max_percentage_laid_off
from layoffs_staging2;

select * from layoffs_staging2 where percentage_laid_off = '1';

select * from layoffs_staging2 where percentage_laid_off = '1' order by total_laid_off desc;

alter table layoffs_staging2 alter column funds_raised_millions float;

select * from layoffs_staging2 where percentage_laid_off = '1' order by funds_raised_millions desc;

/*To check total load of in each company*/
select company,sum(total_laid_off)
from layoffs_staging2  
group by company
order by 2 desc;

alter table layoffs_staging2 alter column [date] date null;

SELECT [date]
FROM layoffs_staging2
WHERE TRY_CAST([date] AS DATE) IS NULL
  AND [date] IS NOT NULL;

select min([date]),max([date])
from layoffs_staging2;


/*To check total laid of in each industry*/
select industry,sum(total_laid_off)
from layoffs_staging2  
group by industry
order by 2 desc;

/*To check total laid of in each country*/
select country,sum(total_laid_off)
from layoffs_staging2  
group by country
order by 2 desc;

/*To check total laid of in each date*/
select year([date]),sum(total_laid_off)
from layoffs_staging2  
group by year([date])
order by 1 desc;

/*To check total laid of in each stage*/
select stage,sum(total_laid_off)
from layoffs_staging2  
group by stage
order by 1 desc;

/*cheking the total layoffs in month year*/
select convert(varchar(7),[date],120) as month ,sum(total_laid_off)
from layoffs_staging2
where [date]  is not null
group by convert(varchar(7),[date],120)  
order by 1 asc;

/*cheking rolling sum*/

with Rolling_Sum as
(
select convert(varchar(7),[date],120) as month ,sum(total_laid_off) as total_laid_off
from layoffs_staging2
where [date]  is not null
group by convert(varchar(7),[date],120)  
)
select MONTH ,total_laid_off ,sum(total_laid_off) over(order by month)
from Rolling_Sum;

/*Visulizing data on the basis of company and year the total laid off*/
select company,sum(total_laid_off)
from layoffs_staging2  
group by company
order by 2 desc;

select company,year([date]) as [year],sum(total_laid_off) total_laid_off
from layoffs_staging2 
where [date] is not null
group by company,year([date])
order by 3 desc;

/*Giving ranks to the company on the basis of year and how many they laid of, finding the top 5 and year they laid of with total lay offs and rank*/
with company_year (company,years,total_laid_off) as
(
select company,year([date]) as [year],sum(total_laid_off) sumtotal_laid_off
from layoffs_staging2 
where [date] is not null
group by company,year([date])
),
company_year_rank as 
(
select  *, 
DENSE_RANK() over(partition by [years] order by total_laid_off desc) as ranking
from company_year
)
select * 
from company_year_rank
where ranking <= 5;



