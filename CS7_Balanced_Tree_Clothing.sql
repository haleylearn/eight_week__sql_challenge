/*
Case Study #7 - Balanced Tree Clothing Co.: https://8weeksqlchallenge.com/case-study-7/

CREATE DATABASE balanced_tree
*/



------------------------------- High Level Sales Analysis -------------------------
-- QUESTION 1: What was the total quantity sold for all products?
SELECT s.prod_id, p.product_name, SUM(qty) AS qty_sales
FROM sales s 
JOIN product_details p 
    ON s.prod_id = p.product_id
GROUP BY s.prod_id, p.product_name
ORDER BY SUM(qty) DESC;


-- QUESTION 2: What is the total generated revenue for all products before discounts?
SELECT FORMAT(SUM(qty * price), 'N0') AS amount_sales_before_discount
FROM sales;


-- QUESTION 3: What was the total discount amount for all products?
SELECT ROUND(SUM(price - (price * (CAST(discount AS FLOAT) / 100))), 2)  AS amount_of_discount
FROM sales;



------------------------------- Transaction Analysis -------------------------
-- QUESTION 1: How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) AS cnt_transactions
FROM sales;


-- QUESTION 2: What is the average unique products purchased in each transaction?
SELECT AVG(unique_product_count) AS average_unique_products
FROM (
    SELECT txn_id, COUNT(DISTINCT prod_id) AS unique_product_count
    FROM sales
    GROUP BY txn_id
) AS unique_product_counts;


-- QUESTION 3: What are the 25th, 50th and 75th percentile values for the revenue per transaction?
SELECT 
    DISTINCT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue) OVER () AS revenue_25th_percentile
    , PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY revenue) OVER () AS revenue_50th_percentile
    , PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue) OVER () AS revenue_75th_percentile
FROM (
    SELECT qty * price * (1 - discount / 100) AS revenue
    FROM sales
) x;


-- QUESTION 4: What is the average discount value per transaction?
SELECT
    txn_id,
    AVG(discount) AS average_discount
FROM sales
GROUP BY txn_id;


-- QUESTION 5: What is the percentage split of all transactions for members vs non-members?
SELECT
    CASE
        WHEN member = 't' THEN 'Member'
        ELSE 'Non-Member'
    END AS membership_type,
    COUNT(*) AS transaction_count,
    ROUND((COUNT(*) * 100 / (SELECT COUNT(*) FROM sales)), 2) AS percentage
FROM sales
GROUP BY member;


-- QUESTION 6: What is the average revenue for member transactions and non-member transactions?
SELECT
    CASE
        WHEN member = 't' THEN 'Member'
        ELSE 'Non-Member'
    END AS membership_type,
    SUM(qty * price * (1 - discount / 100)) AS revenue,
    ROUND((SUM(qty * price * (1 - discount / 100)) * 100 / (SELECT COUNT(*) FROM sales)), 2) AS average_revenue
FROM sales
GROUP BY member;



------------------------------- Product Analysis -------------------------
-- QUESTION 1: What are the top 3 products by total revenue before discount?
SELECT DISTINCT prod_id, revenue
FROM (
    SELECT prod_id
    , qty * price AS revenue
    , DENSE_RANK() OVER(ORDER BY qty * price DESC) AS rnk FROM sales 
) x
WHERE rnk <= 3;
