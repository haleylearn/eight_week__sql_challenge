--------------------------- B. Runner and Customer Experience ----------------------------

-- QUESTION 1: How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT week_part, COUNT(runner_id) AS cnt_runners
FROM (SELECT runner_id, DATEPART(WEEK, registration_date) AS week_part FROM runners) x
GROUP BY week_part;


-- QUESTION 2: What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT AVG(minute_pickup) AS avg_minute
FROM (
    SELECT r.order_id, DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS minute_pickup
    FROM runner_orders r 
    JOIN (SELECT DISTINCT order_id, order_time FROM customer_orders) c 
        ON r.order_id = c.order_id
    WHERE pickup_time IS NOT NULL
) x;


-- QUESTION 3: Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT r.order_id, total_pizzas, DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS minute_pickup
FROM runner_orders r 
JOIN (SELECT order_id, COUNT(pizza_id) AS total_pizzas, MAX(order_time) AS order_time FROM customer_orders GROUP BY order_id) c 
    ON r.order_id = c.order_id
WHERE pickup_time IS NOT NULL;

---> If total is 1 pizza will take 10 - 22 minutes, Else if from 2 to 3 pizzas will take from  16 - 30 minutes


-- QUESTION 4: What was the average duration travelled for each customer?
WITH get_standard_duration AS (
    SELECT 
        * 
        , CASE 
            WHEN check_space <> 0 THEN SUBSTRING(duration, 0, check_space) 
            WHEN check_space = 0 AND check_m = 0 THEN duration
            WHEN check_space = 0 AND check_m <> 0 THEN SUBSTRING(duration, 0, check_m) 
        END AS standard_duration
    FROM (
        SELECT *
            , CHARINDEX( ' ', duration, 0 ) AS check_space
            , CHARINDEX( 'm', duration, 0 ) AS check_m 
        FROM runner_orders WHERE duration IS NOT NULL
    ) x
)

SELECT x.customer_id, AVG(CAST(standard_duration AS FLOAT)) AS avg_distance_by_customer
FROM get_standard_duration g
JOIN (SELECT DISTINCT(order_id), customer_id FROM customer_orders) x
    ON g.order_id = x.order_id 
GROUP BY x.customer_id;



-- QUESTION 5: What was the difference between the longest and shortest delivery times for all orders?
WITH get_standard_duration AS (
    SELECT 
        * 
        , CASE 
            WHEN check_space <> 0 THEN SUBSTRING(duration, 0, check_space) 
            WHEN check_space = 0 AND check_m = 0 THEN duration
            WHEN check_space = 0 AND check_m <> 0 THEN SUBSTRING(duration, 0, check_m) 
        END AS standard_duration
    FROM (
        SELECT *
            , CHARINDEX( ' ', duration, 0 ) AS check_space
            , CHARINDEX( 'm', duration, 0 ) AS check_m 
        FROM runner_orders WHERE duration IS NOT NULL
    ) x
)
SELECT CAST(MAX(standard_duration) AS FLOAT) - CAST(MIN(standard_duration) AS FLOAT) AS difference_longest_shortest FROM get_standard_duration;


-- QUESTION 6: What was the average speed for each runner for each delivery and do you notice any trend for these values?
WITH get_standard_distance_and_duration AS (
    SELECT 
        *
        , CASE 
            WHEN check_space_duration <> 0 THEN SUBSTRING(duration, 0, check_space_duration) 
            WHEN check_space_duration = 0 AND check_m = 0 THEN duration
            WHEN check_space_duration = 0 AND check_m <> 0 THEN SUBSTRING(duration, 0, check_m) 
        END AS standard_duration
        , CASE 
            WHEN check_space_distance <> 0 THEN SUBSTRING(distance, 0, check_space_distance) 
            WHEN check_space_distance = 0 AND check_k = 0 THEN distance
            WHEN check_space_distance = 0 AND check_k <> 0 THEN SUBSTRING(distance, 0, check_k) 
        END AS standard_distance
    FROM (
        SELECT *
            , CHARINDEX( ' ', duration, 0 ) AS check_space_duration
            , CHARINDEX( 'm', duration, 0 ) AS check_m 
            , CHARINDEX( ' ', distance, 0 ) AS check_space_distance
            , CHARINDEX( 'k', distance, 0 ) AS check_k
        FROM runner_orders WHERE duration IS NOT NULL
    ) x
)

SELECT runner_id, standard_distance, standard_duration
    , ROUND( CAST(standard_distance AS FLOAT) / CAST(standard_duration AS FLOAT), 2 ) AS time_avg
FROM get_standard_distance_and_duration 
ORDER BY runner_id, order_id

/*
On the first order, everyone only takes about 0.6 minutes to complete 1km
With runner_id 1 keep the initial average at 0.63 min/km and increase after lowering then the last order is to hold at 1 minute per 1 km. The trend of the day runs slower than at the beginning
With runner_id 2 also, the initial took only 0.58 min/km better than runner_id 1 to complete 1km, but the following orders suddenly increased and took 1 - 1.5 minutes to complete 1km, 3 times more than the first order
*/


-- QUESTION 7: What is the successful delivery percentage for each runner?
SELECT runner_id, SUM(percent_) AS total_percent
FROM (  
    SELECT runner_id
        , ((1 * 100) / CAST( COUNT(order_id) OVER() AS FLOAT )) AS percent_
    FROM runner_orders
    WHERE pickup_time IS NOT NULL
) x
GROUP BY runner_id
