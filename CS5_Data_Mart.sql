
-- Case Study #5 - Data Mart

/*DATASET https://8weeksqlchallenge.com/case-study-5/ */

-- use data_mart

------------------------- 1. DATA CLEANING STEPS ---------------------------
/*
    WE HAVE 2 WAY TO CLEAN DATA AS REQUIRES
    1. Can create a new view in SQL Sever and use some query to create VIEW as CTE get_date_standard() below
    2. Create new column then you update and set data for column

    NOTE: In SQL Sever can't change position of column
*/

WITH get_date_standard AS (
    SELECT DATEFROMPARTS(year, month, day) AS week_date_standard
        , DATEPART(WEEK, DATEFROMPARTS(year, month, day)) AS week_number 
        , month AS month_number 
        , year AS calendar_year  
        , region, platform, segment, customer_type, transactions, sales
        , ROUND(CAST(sales AS FLOAT)/CAST(transactions AS FLOAT), 2) AS avg_transaction 
        , CASE 
            WHEN segment = 'null' THEN 'Unknow'
            WHEN RIGHT(segment,1) = 1 THEN 'Young Adults'
            WHEN RIGHT(segment,1) = 2 THEN 'Middle Aged'
            WHEN RIGHT(segment,1) = 3 OR RIGHT(segment,1) = 4 THEN 'Retirees'
            END AS age_band 
        , CASE 
            WHEN segment = 'null' THEN 'Unknow'
            WHEN LEFT(segment,1) = 'C' THEN 'Couples'
            WHEN LEFT(segment,1) = 'F' THEN 'Families'
            END AS demographic 
    FROM (
        SELECT  *
            , SUBSTRING(week_date, 1, CHARINDEX('/', week_date) -1) as day
            , SUBSTRING(week_date, (CHARINDEX('/', week_date) + 1), (CHARINDEX('/', week_date)) - 2) AS month
            , CAST(RIGHT(week_date, 2) AS INT) + 2000 AS year
        FROM weekly_sales
    )x
)
SELECT * FROM get_date_standard;


-- Add demographic column 
ALTER TABLE weekly_sales
ADD demographic nvarchar(100);
-- Update data for demographic column 
UPDATE weekly_sales
SET demographic = CASE 
            WHEN segment = 'null' THEN 'Unknow'
            WHEN LEFT(segment,1) = 'C' THEN 'Couples'
            WHEN LEFT(segment,1) = 'F' THEN 'Families'
            END 



-- Add age_band column 
ALTER TABLE weekly_sales
ADD age_band nvarchar(100);

-- Update data for age_band column 
UPDATE weekly_sales
SET age_band = CASE 
            WHEN segment = 'null' THEN 'Unknow'
            WHEN RIGHT(segment,1) = 1 THEN 'Young Adults'
            WHEN RIGHT(segment,1) = 2 THEN 'Middle Aged'
            WHEN RIGHT(segment,1) = 3 OR RIGHT(segment,1) = 4 THEN 'Retirees'
            END 



-- Add week_date_standard column 
ALTER TABLE weekly_sales
ADD week_date_standard nvarchar(100);

-- Add month_standard column 
ALTER TABLE weekly_sales
ADD month_standard INT;

-- Add year_standard column 
ALTER TABLE weekly_sales
ADD year_standard INT;


-- Update data for week_date_standard, month_standard, year_standard column 
UPDATE weekly_sales
SET week_date_standard = t1.week_date_standard
    , year_standard = t1.year
    , month_standard = t1.month
FROM (
    SELECT rn_number, week_date, year, month, day, DATEFROMPARTS(year, month, day) AS week_date_standard
        FROM(
            SELECT  ROW_NUMBER() OVER(ORDER BY SYSDATETIME()) AS rn_number
                    , week_date
                    , SUBSTRING(week_date, 1, CHARINDEX('/', week_date) -1) as day
                    , SUBSTRING(week_date, (CHARINDEX('/', week_date) + 1), 1) AS month
                    , CAST(RIGHT(week_date, 2) AS INT) + 2000 AS year
            FROM weekly_sales
        )x
) t1
JOIN 
    (SELECT ROW_NUMBER() OVER(ORDER BY SYSDATETIME()) AS rn_number, * FROM weekly_sales) weekly_sales 
    ON t1.rn_number = weekly_sales.rn_number;




-- Update data for week_date_standard column 
-- SET month_standard = t1.month_standard
-- FROM (
--     SELECT DATEPART(MONTH, week_date_standard) AS month_standard
--     FROM weekly_sales
-- ) t1
-- CROSS JOIN weekly_sales;



-- -- Update data for week_date_standard column 
-- UPDATE weekly_sales
-- SET year_standard = t1.year_standard
-- FROM (
--     SELECT DATEPART(YEAR, week_date_standard) + 2000 AS year_standard
--     FROM weekly_sales
-- ) t1



-- Add avg_transaction column 
ALTER TABLE weekly_sales
ADD avg_transaction FLOAT;
-- Add data for avg_transaction column
UPDATE weekly_sales
SET avg_transaction = ROUND(sales / transactions, 2);


------------------------- 2. DATA EXPLORATION ---------------------------

-- QUESTION 1: What day of the week is used for each week_date value?

SELECT week_date_standard, DATENAME(WEEKDAY, week_date_standard) AS weekday_name
FROM (SELECT DISTINCT CAST(week_date_standard AS DATE) AS week_date_standard FROM weekly_sales) x
ORDER BY week_date_standard


-- QUESTION 2: What range of week numbers are missing from the dataset?

-- Get all week number from 1-52
WITH countUp AS
(
    SELECT 1 AS week_number
    UNION ALL
    SELECT week_number + 1
    FROM countUp
    WHERE week_number < 52
)
-------------------------------------------------------------------------------------------------------

/*SOLUTION 1: 
- t1 is all week number from 1-52 and seperate year 2018, 2019, 2020 
- t2 is Get week_number and year_standard based on weekly_sales
THEN using EXCEPT from t1(as below) 
*/ 
-- Get all week_number from 1-52 and seperate year_standard
(SELECT week_number, year_standard FROM countUp c CROSS JOIN (SELECT DISTINCT year_standard FROM weekly_sales) distinct_year_tab)

EXCEPT

-- Get week_number and year_standard based on weekly_sales
(SELECT DISTINCT DATENAME(WEEK, week_date_standard) AS week_number, year_standard FROM weekly_sales)

-------------------------------------------------------------------------------------------------------
/* SOLUTION 2: 
- t1 is all week number from 1-52 and seperate year 2018, 2019, 2020 
- t2 is Get week_number and year_standard based on weekly_sales
THEN using LEFT JOIN from t1(as below) and then get any records have NULL value
 */
-- SELECT t1.year_standard, t1.week_number
-- FROM 
--     -- Get all week number from 1-52 and seperate year 2018, 2019, 2020 
--     (SELECT week_number, year_standard FROM countUp c CROSS JOIN (SELECT DISTINCT year_standard FROM weekly_sales) distinct_year_tab) t1
-- LEFT JOIN 
--     -- Get week_number and year_standard based on weekly_sales
--     (SELECT DISTINCT DATENAME(WEEK, week_date_standard) AS week_number, year_standard FROM weekly_sales) t2
-- ON t1.year_standard = t2.year_standard AND t1.week_number = t2.week_number

-- -- Get all record in t1 but not in t2 
-- WHERE t2.week_number IS NULL AND t2.year_standard IS NULL
-- ORDER BY t1.year_standard, t1.week_number
-------------------------------------------------------------------------------------------------------



-- QUESTION 3: How many total transactions were there for each year in the dataset?
SELECT year_standard, COUNT(sales) AS total_transactions
FROM weekly_sales
GROUP BY year_standard;


-- QUESTION 4: What is the total sales for each region for each month?
SELECT region, month_standard, FORMAT(CAST(SUM(sales) AS MONEY), 'N0') AS total_sales
FROM (
    SELECT region, month_standard, CAST(sales AS FLOAT) AS sales
    FROM weekly_sales
) x
GROUP BY region, month_standard
ORDER BY region, month_standard



-- QUESTION 5: What is the total count of transactions for each platform
SELECT platform, COUNT(platform) AS total_transactions
FROM weekly_sales
GROUP BY platform;



-- QUESTION 6: What is the percentage of sales for Retail vs Shopify for each month?
SELECT month_standard, platform
    , FORMAT(CAST(total_sales AS MONEY), 'N0') AS total_sales
    , ROUND(total_sales*100 / SUM(total_sales) OVER(PARTITION BY month_standard), 2) AS percentage_sales
FROM (
    SELECT month_standard
        , platform
        , SUM(CAST(sales AS FLOAT)) AS total_sales
    FROM weekly_sales
    GROUP BY month_standard, platform
) x;



-- QUESTION 7: What is the percentage of sales by demographic for each year in the dataset?
SELECT year_standard, demographic
    , FORMAT(CAST(total_sales AS MONEY), 'N0') AS total_sales
    , ROUND(total_sales*100 / SUM(total_sales) OVER(PARTITION BY year_standard), 2) AS percentage_sales
FROM (
    SELECT year_standard, demographic, SUM(CAST(sales AS FLOAT)) AS total_sales
    FROM weekly_sales
    GROUP BY year_standard, demographic
) x
ORDER BY year_standard, demographic;



-- QUESTION 8: Which age_band and demographic values contribute the most to Retail sales?

-- SOLUTION 1: Using DENSE_RANK to get rank_number for each row
SELECT year_standard, age_band, demographic, total_sales
FROM (
    SELECT year_standard, age_band, demographic, total_sales
    -- Get rank_number for each row
        , DENSE_RANK() OVER(PARTITION BY year_standard ORDER BY total_sales DESC) AS rank_number
    FROM (
        SELECT year_standard, age_band, demographic, SUM(CAST(sales AS FLOAT)) AS total_sales
        FROM weekly_sales
        WHERE platform = 'Retail'
        GROUP BY year_standard, age_band, demographic
    ) x1
) x2
-- Get rank_number is MAX
WHERE x2.rank_number = 1;


-- SOLUTION 2: Using mindset same as join two table to get max row
SELECT * 
FROM (
    SELECT year_standard, age_band, demographic, SUM(CAST(sales AS FLOAT)) AS total_sales
    FROM weekly_sales
    WHERE platform = 'Retail'
    GROUP BY year_standard, age_band, demographic 
) t1
WHERE 2 > (
    SELECT COUNT(DISTINCT t2.total_sales)
    FROM (
        SELECT year_standard, age_band, demographic, SUM(CAST(sales AS FLOAT)) AS total_sales
        FROM weekly_sales
        WHERE platform = 'Retail'
        GROUP BY year_standard, age_band, demographic
    ) t2
    WHERE t2.total_sales >= t1.total_sales AND t1.year_standard = t2.year_standard
);



-- SOLUTION 3: Using MAX() function
SELECT * 
FROM (
        SELECT year_standard, age_band, demographic, SUM(CAST(sales AS FLOAT)) AS total_sales
        FROM weekly_sales
        WHERE platform = 'Retail'
        GROUP BY year_standard, age_band, demographic 
) t1
WHERE t1.total_sales = (
    SELECT MAX(total_sales) AS max_sales
    FROM (
            SELECT year_standard, age_band, demographic, SUM(CAST(sales AS FLOAT)) AS total_sales
            FROM weekly_sales
            WHERE platform = 'Retail'
            GROUP BY year_standard, age_band, demographic 
    ) t2
    WHERE t1.year_standard = t2.year_standard
);



 -- QUESTION 9: Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT year_standard
    , COUNT(CASE WHEN platform='Retail' THEN 1 ELSE NULL END) AS 'count_retail'
    , ROUND(SUM(CASE WHEN platform='Retail' THEN avg_transaction ELSE 0 END), 2) AS 'total_retail_avg'
    , ROUND(
            SUM(CASE WHEN platform = 'Retail' THEN avg_transaction ELSE 0 END) 
            / 
            COUNT(CASE WHEN platform = 'Retail' THEN 1 ELSE NULL END)
            , 2
    ) AS 'avg_retail'

    , ROUND(SUM(CASE WHEN platform='Shopify' THEN avg_transaction ELSE 0 END), 2) AS 'total_shopify_avg'
    , COUNT(CASE WHEN platform='Shopify' THEN 1 ELSE NULL END) AS 'count_shopify'
    , ROUND(
            SUM(CASE WHEN platform = 'Shopify' THEN avg_transaction ELSE 0 END) 
            / 
            COUNT(CASE WHEN platform = 'Shopify' THEN 1 ELSE NULL END)
            , 2
    ) AS 'avg_shopify'
FROM weekly_sales
GROUP BY year_standard;




------------------------- 3. BEFORE AND AFTER ANALYSIS ---------------------------
-- QUESTION 1: What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

/*
-- SOLUTION 1: 
Step 1: Create separate variable to hole the date before and after 2020-06-15 and the total sales before and after 2020-06-15
Step 2: SET value for variable by logic using week_date_standard >= @end_date_before_4 AND week_date_standard < @start_date_4
*/
DECLARE @start_date_4 DATE = '2020-06-15';
DECLARE @end_date_before_4 DATE = DATEADD(WEEK, -4, @start_date_4);
DECLARE @end_date_after_4 DATE = DATEADD(WEEK, 4, @start_date_4);
DECLARE @total_sales_before_4 FLOAT;
DECLARE @total_sales_after_4 FLOAT;


-- Get total sales before baseline
SET @total_sales_before_4 = ( 
                                SELECT SUM(CAST(sales AS FLOAT))
                                FROM weekly_sales
                                WHERE week_date_standard >= @end_date_before_4 AND week_date_standard < @start_date_4
                            );  

-- Get total sales after baseline
SET @total_sales_after_4 = ( 
                                SELECT SUM(CAST(sales AS FLOAT))
                                FROM weekly_sales
                                WHERE week_date_standard > @start_date_4 AND week_date_standard <= @end_date_after_4
                            ); 

-- Calculate total_growth by @total_sales_after_4 - @total_sales_before_4
SELECT FORMAT(CAST((@total_sales_after_4 - @total_sales_before_4) AS MONEY), 'N0') AS total_growth;

-- Calculate percentage_sales before and after baseline by (@total_sales_after_4 - @total_sales_before_4) / (@total_sales_before_4) * 100
SELECT ROUND((@total_sales_after_4 - @total_sales_before_4) / (@total_sales_before_4) * 100, 2) AS percentage_sales;



/*
-- SOLUTION 2: Solve this problem by using week_number with logic the week_number of DATENAME(WEEK, '2020-06-15') - DATENAME(WEEK, week_date_standard) 
with by range from -4 to 4 and don't include week_number is 0
*/
WITH get_total_sales_before AS (
    SELECT SUM(CAST(sales AS FLOAT)) AS get_total_sales_before_4
    FROM (
        SELECT week_date_standard, sales
        , DATENAME(WEEK, week_date_standard) w1, DATENAME(WEEK, '2020-06-15') w2
        , CAST(DATENAME(WEEK, week_date_standard) AS INT)  - CAST(DATENAME(WEEK, '2020-06-15') AS INT) sub
        FROM weekly_sales
        WHERE year_standard = 2020
    ) x
    WHERE sub >= -4 AND sub < 0
)
, get_total_sales_after AS (
    SELECT SUM(CAST(sales AS FLOAT)) AS get_total_sales_after_4
    FROM (
        SELECT week_date_standard, sales
        , DATENAME(WEEK, week_date_standard) w1, DATENAME(WEEK, '2020-06-15') w2
        , CAST(DATENAME(WEEK, week_date_standard) AS INT)  - CAST(DATENAME(WEEK, '2020-06-15') AS INT) sub
        FROM weekly_sales
        WHERE year_standard = 2020
    ) x
    WHERE sub > 0 AND sub <=4 
)

-- SELECT * FROM get_total_sales_after;
-- SELECT * FROM get_total_sales_after;


/*SOLUTION 3: Using SUM AND CASE WHEN to get total sales*/
SELECT year_standard
    , SUM( CASE WHEN sub >= -4 AND sub < 0 THEN CAST(sales AS FLOAT) ELSE 0 END ) AS sales_before_4_week
    , SUM( CASE WHEN sub > 0 AND sub <= 4  THEN CAST(sales AS FLOAT) ELSE 0 END ) AS sales_after_4_week
FROM (
    SELECT week_date_standard, sales, year_standard
    , DATENAME(WEEK, week_date_standard) w1, DATENAME(WEEK, '2020-06-15') w2
    , CAST(DATENAME(WEEK, week_date_standard) AS INT)  - CAST(DATENAME(WEEK, '2020-06-15') AS INT) sub
    FROM weekly_sales
    WHERE year_standard = 2020
) x
GROUP BY year_standard;



-- QUESTION 2: What about the entire 12 weeks before and after?
DECLARE @start_date_12 DATE = '2020-06-15';
DECLARE @end_date_before_12 DATE = DATEADD(WEEK, -12, @start_date_12);
DECLARE @end_date_after_12 DATE = DATEADD(WEEK, 12, @start_date_12);
DECLARE @total_sales_before_12 FLOAT;
DECLARE @total_sales_after_12 FLOAT;

-- Get total sales before baseline
SET @total_sales_before_12 = ( 
                                SELECT SUM(CAST(sales AS FLOAT))
                                FROM weekly_sales
                                WHERE week_date_standard >= @end_date_before_12 AND week_date_standard < @start_date_12
                            );  

-- Get total sales after baseline
SET @total_sales_after_12 = ( 
                                SELECT SUM(CAST(sales AS FLOAT))
                                FROM weekly_sales
                                WHERE week_date_standard > @start_date_12 AND week_date_standard <= @end_date_after_12
                            ); 


-- Calculate total_growth by @total_sales_after_12 - @total_sales_before_12
SELECT FORMAT(CAST((@total_sales_after_12 - @total_sales_before_12) AS MONEY), 'N0') AS total_growth;

-- Calculate percentage_sales before and after baseline by (@total_sales_after_12 - @total_sales_before_12) / (@total_sales_before_12) * 100
SELECT ROUND((@total_sales_after_12 - @total_sales_before_12) / (@total_sales_before_12) * 100, 2) AS percentage_sales;



-- QUESTION 3: How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
SELECT year_standard
    , SUM( CASE WHEN sub >= -4 AND sub < 0 THEN CAST(sales AS FLOAT) ELSE 0 END ) AS sales_before_4_week
    , SUM( CASE WHEN sub > 0 AND sub <= 4  THEN CAST(sales AS FLOAT) ELSE 0 END ) AS sales_after_4_week
    , SUM( CASE WHEN sub >= -12 AND sub < 0 THEN CAST(sales AS FLOAT) ELSE 0 END ) AS sales_before_12_week
    , SUM( CASE WHEN sub > 0 AND sub <= 12  THEN CAST(sales AS FLOAT) ELSE 0 END ) AS sales_after_12_week
FROM (
    SELECT week_date_standard, sales, year_standard
    , DATENAME(WEEK, week_date_standard) w1, DATENAME(WEEK, '2020-06-15') w2
    , CAST(DATENAME(WEEK, week_date_standard) AS INT)  - CAST(DATENAME(WEEK, '2020-06-15') AS INT) sub
    FROM weekly_sales
) x
GROUP BY year_standard;



-- QUESTION 4: Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
SELECT *, sales_after_12_week - sales_before_12_week AS sub_sales
FROM (
    SELECT region
        , SUM( CASE WHEN sub >= -12 AND sub < 0 THEN CAST(sales AS FLOAT) ELSE 0 END ) AS sales_before_12_week
        , SUM( CASE WHEN sub > 0 AND sub <= 12  THEN CAST(sales AS FLOAT) ELSE 0 END ) AS sales_after_12_week
    FROM (
        SELECT week_date_standard, sales, year_standard, region
        , DATENAME(WEEK, week_date_standard) w1, DATENAME(WEEK, '2020-06-15') w2
        , CAST(DATENAME(WEEK, week_date_standard) AS INT)  - CAST(DATENAME(WEEK, '2020-06-15') AS INT) sub
        FROM weekly_sales
        WHERE year_standard = 2020
    ) x1
    GROUP BY region
) x2
ORDER BY sales_after_12_week - sales_before_12_week;