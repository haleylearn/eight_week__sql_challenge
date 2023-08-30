/* DATASET https://8weeksqlchallenge.com/case-study-3/ */
-- use foodie_fi


-- QUESTION 1: How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS customer_count 
FROM subscriptions;



-- QUESTION 2: What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT 
    YEAR(start_date) AS year_
    , MONTH(start_date) AS month_
    , COUNT(DISTINCT customer_id) AS customer_count
FROM subscriptions 
WHERE plan_id = (SELECT plan_id FROM plans WHERE plan_name =  'trial')
GROUP BY MONTH(start_date), YEAR(start_date);



-- QUESTION 3: What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT
    plan_name,
    start_date,
    COUNT(*) AS event_count
FROM
    subscriptions s 
JOIN plans p 
    ON s.plan_id = p.plan_id
WHERE
    YEAR(start_date) = 2020
GROUP BY
    plan_name, start_date
ORDER BY
    plan_name, start_date;



-- QUESTION 3: What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
DECLARE @customerTotalCount FLOAT;
DECLARE @customerChurnCount FLOAT;

SELECT @customerTotalCount = COUNT(DISTINCT customer_id) FROM subscriptions;

SELECT @customerChurnCount = COUNT(DISTINCT customer_id) 
FROM 
    subscriptions 
WHERE 
    plan_id = (SELECT plan_id FROM plans WHERE plan_name = 'churn');

--Get percentage by formula @customerChurnCount / @customerTotalCount 
SELECT ROUND(@customerChurnCount / @customerTotalCount, 1) AS percentage_churn_customer;



-- QUESTION 5: How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
-- DECLARE two varibale to get customer churn after using trial AND total customer 
DECLARE @customerChurnAfterTrialCount FLOAT;
DECLARE @customerTotal FLOAT;

-- Get table with customer_id who get trial first
WITH get_who_get_trial AS (
    SELECT DISTINCT customer_id, start_date, 'trial' AS plan_name
    FROM subscriptions s
    WHERE plan_id = (SELECT plan_id FROM plans WHERE plan_name = 'trial') 
)
-- Get table and set value for @customerChurnAfterTrialCount count customer churn after using trial by logic date diff is 7 day, because Customers can sign up to an initial 7 day free trial 
SELECT @customerChurnAfterTrialCount = COUNT(s.customer_id)
FROM get_who_get_trial g
JOIN subscriptions s 
    ON g.customer_id = s.customer_id AND DATEDIFF(DAY, g.start_date, s.start_date) = 7 AND plan_id = 4;

-- Set value for @customerTotal
SELECT @customerTotal = COUNT(DISTINCT customer_id) FROM subscriptions;

-- Get percentage_churn_after_trial by using formula @customerChurnAfterTrialCount / @customerTotal
SELECT ROUND(@customerChurnAfterTrialCount / @customerTotal, 1) AS percentage_churn_after_trial;



-- QUESTION 6: What is the number and percentage of customer plans after their initial free trial?
DECLARE @customerAfterTrialCount FLOAT;
DECLARE @customerTotal_ FLOAT;

-- Get table with customer_id who get trial first
WITH get_who_get_trial AS (
    SELECT DISTINCT customer_id, start_date, 'trial' AS plan_name
    FROM subscriptions s
    WHERE plan_id = (SELECT plan_id FROM plans WHERE plan_name = 'trial') 
)

-- Get table with who get trial and then using plans by other churn, it's mean plan_id <> 4 and the day after is 7
SELECT @customerAfterTrialCount = COUNT(s.customer_id)
FROM get_who_get_trial g
JOIN subscriptions s 
    ON g.customer_id = s.customer_id AND DATEDIFF(DAY, g.start_date, s.start_date) = 7 AND plan_id <> 4;

-- Set value for @customerTotal
SELECT @customerTotal_ = COUNT(DISTINCT customer_id) FROM subscriptions;

-- Get percentage customer using plans after trial @customerAfterTrialCount / @customerTotal_
SELECT @customerAfterTrialCount / @customerTotal_;



-- QUESTION 7: What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH get_data_at_day AS (
    -- Get table with data at the date 2020-12-31
    SELECT * FROM subscriptions WHERE start_date = '2020-12-31'
)
, total_customer_count AS (
    -- Get total customer_id at the date 2020-12-31
    SELECT COUNT(customer_id) AS customer_count FROM get_data_at_day 
)
SELECT p.plan_id, plan_name
    , COUNT(customer_id) AS customer_count
    , ROUND(CAST(COUNT(customer_id) AS FLOAT) / CAST(SUM(t.customer_count) AS FLOAT), 2) AS percentage_
FROM plans p 
LEFT JOIN get_data_at_day g 
    ON p.plan_id = g.plan_id
CROSS APPLY total_customer_count t
GROUP BY p.plan_id, plan_name
ORDER BY p.plan_id



-- QUESTION 8: How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT customer_id) AS customer_upgrade_annual_count
FROM subscriptions s 
JOIN plans p 
    ON s.plan_id = p.plan_id
WHERE YEAR(start_date) = 2020 AND plan_name = 'pro annual'



-- QUESSTION 9: How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
SELECT AVG(date_diff) AS avg_date_get_anual
FROM (
    SELECT t1.customer_id
        , t1.start_date AS 'start_date'
        , t2.start_date AS 'date_get_annual'
        , DATEDIFF(DAY, t1.start_date, t2.start_date) AS date_diff
    FROM (SELECT customer_id, MIN(start_date) AS 'start_date'  FROM subscriptions GROUP BY customer_id, plan_id) t1
    JOIN subscriptions t2
        ON t1.customer_id = t2.customer_id AND t1.start_date < t2.start_date
    JOIN (SELECT plan_id FROM plans WHERE plan_name = 'pro annual') t3
        ON t2.plan_id = t3.plan_id
) x



-- QUESTION 10: Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
SELECT 
    COUNT(CASE WHEN date_diff >= 0 AND date_diff <= 30 THEN 1 ELSE NULL END) AS '0-30 days'
    , COUNT(CASE WHEN date_diff > 30 AND date_diff <= 60 THEN 1 ELSE NULL END) AS '31-60 days'
    , COUNT(CASE WHEN date_diff > 60 AND date_diff <= 90 THEN 1 ELSE NULL END) AS '60-90 days'
    , COUNT(CASE WHEN date_diff > 90 AND date_diff <= 120 THEN 1 ELSE NULL END) AS '90-120 days'
    , COUNT(CASE WHEN date_diff > 120 AND date_diff <= 150 THEN 1 ELSE NULL END) AS '120-150 days'
    , COUNT(CASE WHEN date_diff > 180 AND date_diff <= 210 THEN 1 ELSE NULL END) AS '180-210 days'
    , COUNT(CASE WHEN date_diff > 210 AND date_diff <= 240 THEN 1 ELSE NULL END) AS '210-240 days'
    , COUNT(CASE WHEN date_diff > 240 AND date_diff <= 270 THEN 1 ELSE NULL END) AS '240-270 days'
    , COUNT(CASE WHEN date_diff > 270 AND date_diff <= 300 THEN 1 ELSE NULL END) AS '270-300 days'
    , COUNT(CASE WHEN date_diff > 300 AND date_diff <= 330 THEN 1 ELSE NULL END) AS '300-340 days'
    , COUNT(CASE WHEN date_diff > 330 AND date_diff <= 360 THEN 1 ELSE NULL END) AS '340-370 days'
FROM (
    SELECT t1.customer_id
        , t1.start_date AS 'start_date'
        , t2.start_date AS 'date_get_annual'
        , DATEDIFF(DAY, t1.start_date, t2.start_date) AS date_diff
    FROM (SELECT customer_id, MIN(start_date) AS 'start_date'  FROM subscriptions GROUP BY customer_id, plan_id) t1
    JOIN subscriptions t2
        ON t1.customer_id = t2.customer_id AND t1.start_date < t2.start_date
    JOIN (SELECT plan_id FROM plans WHERE plan_name = 'pro annual') t3
        ON t2.plan_id = t3.plan_id
) x



-- QUESTION 11: How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
SELECT COUNT(t1.customer_id) AS customer_downgraded_pro_to_basic
FROM ( 
    SELECT customer_id, start_date AS 'start_date_pro_monthly'
    FROM subscriptions s 
    JOIN  plans p 
        ON s.plan_id = p.plan_id AND p.plan_name = 'pro monthly'
) t1
JOIN (
    SELECT customer_id, start_date AS 'start_date_basic_monthly'
    FROM subscriptions s 
    JOIN  plans p 
        ON s.plan_id = p.plan_id AND p.plan_name = 'basic monthly'
) t2
    ON t1.customer_id = t2.customer_id AND DATEDIFF(DAY, t1.start_date_pro_monthly, t2. start_date_basic_monthly) < 0