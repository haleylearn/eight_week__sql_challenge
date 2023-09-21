/*DATASET https://8weeksqlchallenge.com/case-study-4/ */

-------------A. Customer Nodes Exploration-------------------
-- use data_bank
-- QUESTION 1: How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT(region_id)) AS node_count FROM regions;

-- QUESTION 2: What is the number of nodes per region?
SELECT c.region_id, r.region_name, COUNT(node_id) AS node_count 
FROM customer_nodes c 
JOIN regions r
    ON c.region_id = r.region_id
GROUP BY c.region_id, r.region_name;

-- QUESTION 3: How many customers are allocated to each region?
SELECT c.region_id AS region_id, r.region_name AS region_name, COUNT(customer_id) AS customer_count
FROM customer_nodes c
JOIN regions r
    ON c.region_id = r.region_id
GROUP BY c.region_id, r.region_name;



-- QUESTION 4: How many days on average are customers reallocated to a different node?
SELECT customer_id, AVG(DATEDIFF(DAY, lag_end_date, start_date)) AS avg_day_change_node
FROM (
    SELECT *
    , LAG(node_id) OVER(PARTITION BY customer_id ORDER BY start_date) AS lag_node
    , LAG(end_date) OVER(PARTITION BY customer_id ORDER BY start_date) AS lag_end_date
FROM customer_nodes c1 
) x
WHERE lag_node IS NOT NULL AND node_id <> lag_node
GROUP BY customer_id
ORDER BY customer_id;



-- QUESTION 5: What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
SELECT region_id, reallocation_days, percentile
FROM (
    SELECT region_id, reallocation_days
        , NTILE(100) OVER (PARTITION BY region_id ORDER BY Reallocation_Days) AS percentile
    FROM(
        SELECT region_id
            , DATEDIFF(DAY, start_date,  LAG(end_date) OVER(PARTITION BY region_id ORDER BY start_date)) AS reallocation_days
        FROM customer_nodes
    ) x
    WHERE reallocation_days > 0
) x2
WHERE percentile = 80 OR percentile = 95
GROUP BY region_id, reallocation_days, percentile



-------------------B. Customer Transactions----------------------

-- QUESTION 1: What is the unique count and total amount for each transaction type?
SELECT txn_type, SUM(txn_amount) AS total_amount FROM customer_transactions GROUP BY txn_type;

-- QUESTION 2: What is the average total historical deposit counts and amounts for all customers?
SELECT customer_id, SUM(txn_amount) AS total_deposit_amount, COUNT(txn_type) AS deposit_count FROM customer_transactions WHERE txn_type = 'deposit' GROUP BY customer_id;
SELECT txn_type, SUM(txn_amount) AS total_deposit_amount, COUNT(txn_type) AS deposit_count FROM customer_transactions WHERE txn_type = 'deposit' GROUP BY txn_type;


-- QUESTION 3: For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH get_rank_by_txn_type AS (
    SELECT *
        , MONTH(txn_date) AS 'month_part'
        , ROW_NUMBER() OVER(PARTITION BY customer_id, txn_type, MONTH(txn_date) ORDER BY txn_date) AS rank_by_type
    FROM customer_transactions
)
, get_customer_deposit_more_than_1 AS (
    SELECT customer_id, txn_type, month_part, MAX(rank_by_type) AS rank_by_type
    FROM (
        SELECT customer_id, txn_type
            , MONTH(txn_date) AS 'month_part'
            , ROW_NUMBER() OVER(PARTITION BY customer_id, txn_type, MONTH(txn_date) ORDER BY txn_date) AS rank_by_type
        FROM customer_transactions
    ) x
    GROUP BY customer_id, txn_type, month_part
)
, get_having_purchase_withdraw AS (
    SELECT t2.*
        , CASE WHEN t2.txn_type = 'purchase' AND t2.rank_by_type >= 1 THEN '1' ELSE 0 END AS having_purchase
        , CASE WHEN t2.txn_type = 'withdrawal' AND t2.rank_by_type >= 1 THEN '1' ELSE 0 END AS having_withdrawal
    FROM (
        -- Table with deposit more than 1
        SELECT DISTINCT customer_id AS customer_deposit_more_than_1, month_part
        FROM get_rank_by_txn_type
        WHERE txn_type = 'deposit' AND rank_by_type > 1
    ) t1
    JOIN (
        -- Table all data with groupby with how many purchase or withdrwal of each customer_id
        SELECT customer_id, txn_type, month_part, MAX(rank_by_type) AS rank_by_type 
        FROM get_rank_by_txn_type
        GROUP BY customer_id, txn_type, month_part
    ) t2
        ON t1.customer_deposit_more_than_1 = t2.customer_id AND t1.month_part = t2.month_part AND t2.txn_type <> 'deposit'
)

SELECT month_part, SUM(having_purchase) AS deposit_and_having_purchase, SUM(having_withdrawal) AS deposit_and_having_withdrawal
FROM get_having_purchase_withdraw 
GROUP BY month_part;


-- QUESTION 4: What is the closing balance for each customer at the end of the month?
SELECT month_part, customer_id
    , SUM(
        CASE WHEN txn_type = 'deposit' THEN txn_amount
        ELSE (txn_amount)*(-1)
        END
    ) AS balance
FROM (SELECT customer_id, txn_type, txn_amount, MONTH(txn_date) AS 'month_part' FROM customer_transactions) x
GROUP BY month_part, customer_id
ORDER BY month_part, customer_id;


-- QUESTION 5: What is the percentage of customers who increase their closing balance by more than 5%?
WITH get_current_balance AS (
    SELECT month_part, customer_id
        , SUM(
            CASE WHEN txn_type = 'deposit' THEN txn_amount
            ELSE (txn_amount)*(-1)
            END
        ) AS current_balance
    FROM (SELECT customer_id, txn_type, txn_amount, MONTH(txn_date) AS 'month_part' FROM customer_transactions) x
    GROUP BY month_part, customer_id
)
, get_previous_balance AS (
    SELECT *
        , LAG(current_balance, 1, 0) OVER(PARTITION BY customer_id, customer_id ORDER BY month_part) AS previous_balance
    FROM get_current_balance 
) 
, get_percent_between_current_balance_and_previous_month AS (
    SELECT *
        , CASE 
            WHEN current_balance < 0 OR current_balance = 0 
                THEN 0
            WHEN current_balance > 0 AND previous_balance < 0
                THEN ROUND((CONVERT(FLOAT, (current_balance + previous_balance)) / (previous_balance * (- 1.0))) * 100, 2)
            WHEN current_balance > 0 AND previous_balance > 0
                THEN ROUND((CONVERT(FLOAT, (current_balance - previous_balance)) / (previous_balance)), 2)
            END AS percent_
    FROM get_previous_balance 
    WHERE previous_balance <> 0
)

SELECT 
    (
        CONVERT(FLOAT, (SELECT COUNT(DISTINCT customer_id) FROM get_percent_between_current_balance_and_previous_month WHERE percent_ > 0.05))
        /
        CONVERT(FLOAT, (SELECT COUNT(DISTINCT customer_id) FROM customer_transactions))
    ) * 100 AS 'percent_customer_balance_above_5%'
    



