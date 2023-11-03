/*
Case Study #6 - Clique Bait: https://8weeksqlchallenge.com/case-study-6/

CREATE DATABASE clique_bait
INSERT INTO events
  ("visit_id", "cookie_id", "page_id", "event_type", "sequence_number", "event_time")
VALUES
('ce9658', '423f8d', '2', '1', '1', '2020-01-12 04:24:28.405909'),
  ('ac98c1', 'eecf24', '2', '1', '1', '2020-03-23 10:20:55.620551'),
  ('cbc891', 'd56286', '2', '1', '1', '2020-04-23 12:16:59.661749'),
  ('f73e19', '72b87a', '2', '1', '1', '2020-04-13 18:15:32.018253'),
  ('79aa04', '411419', '2', '1', '1', '2020-03-17 05:31:59.234137'),
  ('7b0a2b', '30f0db', '2', '1', '1', '2020-03-08 22:25:14.149037'),
  .................................................................
  ('355a6a', '87a4ba', '13', '3', '19', '2020-03-18 22:45:54.984666');
*/


------------------------------- DIGITAL ANALYSIS ----------------------------------------

-- QUESTION 1: How many users are there?
SELECT COUNT(DISTINCT user_id) AS cnt_user FROM users


-- QUESTION 2: How many cookies does each user have on average?
SELECT avg(cnt_cookie_each_user) AS avg_cookie_each_user
FROM (
    SELECT user_id, COUNT(DISTINCT cookie_id) AS cnt_cookie_each_user
    FROM users
    GROUP BY user_id
) x;


-- QUESTION 3: What is the unique number of visits by all users per month?
SELECT month, COUNT(DISTINCT user_id) AS total_user_visit
FROM (SELECT user_id, cookie_id FROM users) v
JOIN (SELECT visit_id, cookie_id, DATEPART(MONTH, event_time) AS 'Month' FROM events) e
    ON v.cookie_id = e.cookie_id
GROUP BY month;


-- QUESTION 4: What is the number of events for each event type?
SELECT e1.event_type, event_name, COUNT(e1.event_type) AS cnt_events
FROM events e1 
JOIN event_identifier e2
    ON e1.event_type = e2.event_type
GROUP BY e1.event_type, event_name;


-- QUESTION 5: What is the percentage of visits which have a purchase event?
SELECT (
    ROUND(
        (
            CAST((SELECT COUNT(DISTINCT visit_id) * 100 FROM events WHERE event_type = 3) AS FLOAT) 
            /
            CAST((SELECT COUNT(DISTINCT visit_id) FROM events) AS FLOAT)
        )
        , 2
    )
) AS percentage_purchase;


-- QUESTION 6: What is the percentage of visits which view the checkout page but do not have a purchase event?
SELECT (
    ROUND(
        (
            CAST((SELECT COUNT(DISTINCT visit_id) AS cnt_visit_not_purchase
                    FROM events 
                    WHERE event_type = 2 AND visit_id NOT IN (SELECT DISTINCT visit_id FROM events WHERE event_type = 3)) AS FLOAT) 
            /
            CAST((SELECT COUNT(DISTINCT visit_id) FROM events) AS FLOAT)
        )
        , 2
    )
) AS percentage_checkout_not_purchase;


-- QUESTION 7: What are the top 3 pages by number of views?
SELECT e.page_id, page_name, COUNT(e.page_id) AS cnt_view
FROM (SELECT * FROM events WHERE event_type = 1) e
JOIN page_hierarchy p 
    ON e.page_id = p.page_id
GROUP BY e.page_id, page_name
ORDER BY COUNT(e.page_id) DESC;


-- QUESTION 8: What is the number of views and cart adds for each product category?
SELECT p.product_category
    , SUM(type_view) AS cnt_view
    , SUM(type_add_cart) AS cnt_add_cart
FROM (
    -- Get table only two type is view or add to cart
    SELECT visit_id, cookie_id, page_id
        , CASE WHEN event_type = 1 THEN 1 ELSE 0 END AS type_view
        , CASE WHEN event_type = 2 THEN 1 ELSE 0 END AS type_add_cart
    FROM events 
    WHERE event_type = 1 OR event_type = 2
) x
JOIN page_hierarchy p 
    ON x.page_id = p.page_id
GROUP BY 
    p.product_category;


-- QUESTION 9: What are the top 3 products by purchases?
SELECT TOP 3 
    p.product_id
    , p.product_category
    , COUNT(p.product_id) AS cnt_purchase
FROM (
    -- Get all record when have event type is 3 (purchase) and 2 (add to cart)
    SELECT *
    FROM events 
    WHERE visit_id 
        IN (SELECT DISTINCT visit_id FROM events WHERE event_type = 3) 
        AND event_type = 2
) x
JOIN page_hierarchy p 
    ON p.page_id = x.page_id
GROUP BY 
    p.product_id, p.product_category
ORDER BY 
    COUNT(p.product_id) DESC;



-----------------------------  PRODUCT FUNNEL ANALYSIS ------------------------------
-- QUESTION: Using a single SQL query - create a new output table which has the following details:

WITH cte AS (
    SELECT p.page_id, i.event_name, p.product_id, p.product_category, p.page_name
    FROM
        events e
    JOIN
        page_hierarchy p ON e.page_id = p.page_id
    JOIN 
        event_identifier i ON e.event_type = i.event_type
    WHERE event_name = 'Page View' OR event_name = 'Add to Cart' OR event_name = 'Purchase' 
)

SELECT product_id
    , product_category
    , page_name
    , SUM(CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END) AS views
    , SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_adds
    , MAX(t_purchase.cnt_purchase) AS purchases
    , SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) - MAX(t_purchase.cnt_purchase) AS abandoned
FROM cte
JOIN   
    (
        -- Get table and count about page_id have purchase
        SELECT page_id, COUNT(page_id) AS cnt_purchase
        FROM events 
        WHERE visit_id 
            IN (SELECT DISTINCT visit_id FROM events WHERE event_type = 3) 
            AND event_type = 2
        GROUP BY page_id
    ) t_purchase
        ON cte.page_id = t_purchase.page_id
GROUP BY
    product_id, product_category, page_name;


-- QUESTION: What is the average conversion rate from view to cart add?
SELECT 
    COUNT(CASE WHEN event_type = 1 THEN 1 ELSE NULL END) AS cnt_type_view
    , COUNT(CASE WHEN event_type = 2 THEN 1 ELSE NULL END) AS cnt_type_cart_adds
    , ROUND(
        (
            CAST(COUNT(CASE WHEN event_type = 2 THEN 1 ELSE NULL END) * 100 AS FLOAT) /
            CAST(COUNT(CASE WHEN event_type = 1 THEN 1 ELSE NULL END) AS FLOAT)
        ), 2
    ) AS conversion_rate_view_to_cart_adds
FROM events;



-----------------------------  CAMPAIGN ANALYSIS ------------------------------
-- QUESTION: Generate a table that has 1 single row for every unique visit_id record and has the following columns:

WITH countUp AS (
    -- GET TABLE WITH MAX OF PRODUCT IS 8
    SELECT 1 AS n 
    UNION ALL
    SELECT n+1 
    FROM countUp
    WHERE n<8
)
, each_product_each_campaign AS (
    -- GET EACH PRODUCT WILL HAVE ONLY CAMPAIGN
    SELECT campaign_id, n AS product_id, campaign_name, start_date, end_date
    FROM (
            SELECT *, LEFT(products, 1) AS min, RIGHT(products, 1) AS max 
            FROM campaign_identifier) c
    JOIN countUp u 
        ON u.n <= c.max AND u.n >= c.min
    WHERE products = '6-8'
)
SELECT visit_id
    , campaign_name
    , MIN(event_time) AS earliest_time
    , COUNT(CASE WHEN event_type = 2 THEN 1 ELSE NULL END) AS cnt_view
    , COUNT(CASE WHEN event_type = 2 THEN 1 ELSE NULL END) AS cnt_cart_adds
    , CASE WHEN COUNT(CASE WHEN event_type = 3 THEN 1 ELSE NULL END) > 0 THEN 1 ELSE 0 END AS flag_purchase
    , COUNT(CASE WHEN event_type = 4 THEN 1 ELSE NULL END) AS cnt_impression
    , COUNT(CASE WHEN event_type = 5 THEN 1 ELSE NULL END) AS cnt_click
    , STRING_AGG(CASE WHEN event_type = 2 THEN product_id END, ',') AS concat_product
FROM  (
    SELECT e.visit_id, e.event_time, e.event_type, p.product_id, c.campaign_name
    FROM events e
    JOIN page_hierarchy p 
        ON e.page_id = p.page_id
    LEFT JOIN each_product_each_campaign c 
        ON c.product_id = p.product_id 
        AND e.event_time BETWEEN c.start_date AND c.end_date
) x
WHERE visit_id = '009e0e'
GROUP BY visit_id, campaign_name
ORDER BY visit_id, campaign_name;

-------------------------------- TESTING --------------------------------
-- SELECT e.visit_id
--     , MIN(event_time) AS earliest_time
--     , COUNT(CASE WHEN event_type = 2 THEN 1 ELSE NULL END) AS cnt_view
--     , COUNT(CASE WHEN event_type = 2 THEN 1 ELSE NULL END) AS cnt_cart_adds
--     , CASE WHEN COUNT(CASE WHEN event_type = 3 THEN 1 ELSE NULL END) > 0 THEN 1 ELSE 0 END AS flag_purchase
--     , COUNT(CASE WHEN event_type = 4 THEN 1 ELSE NULL END) AS cnt_impression
--     , COUNT(CASE WHEN event_type = 5 THEN 1 ELSE NULL END) AS cnt_click
--     , STRING_AGG(CASE WHEN event_type = 2 THEN p.product_id END, ',') AS concat_product
-- FROM events e
-- JOIN page_hierarchy p ON e.page_id = p.page_id
-- WHERE visit_id = '009e0e'
-- GROUP BY e.visit_id;


 
