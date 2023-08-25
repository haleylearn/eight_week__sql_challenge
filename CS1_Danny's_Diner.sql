
-- Case Study #1 - Danny's Diner : https://8weeksqlchallenge.com/case-study-1/

/*
    CREATE database dannys_diner 

    CREATE TABLE sales (
    "customer_id" VARCHAR(1),
    "order_date" DATE,
    "product_id" INTEGER
    );

    INSERT INTO sales
    ("customer_id", "order_date", "product_id")
    VALUES
    ('A', '2021-01-01', '1'),
    ('A', '2021-01-01', '2'),
    ('A', '2021-01-07', '2'),
    ('A', '2021-01-10', '3'),
    ('A', '2021-01-11', '3'),
    ('A', '2021-01-11', '3'),
    ('B', '2021-01-01', '2'),
    ('B', '2021-01-02', '2'),
    ('B', '2021-01-04', '1'),
    ('B', '2021-01-11', '1'),
    ('B', '2021-01-16', '3'),
    ('B', '2021-02-01', '3'),
    ('C', '2021-01-01', '3'),
    ('C', '2021-01-01', '3'),
    ('C', '2021-01-07', '3');

    CREATE TABLE menu (
    "product_id" INTEGER,
    "product_name" VARCHAR(5),
    "price" INTEGER
    );

    INSERT INTO menu
    ("product_id", "product_name", "price")
    VALUES
    ('1', 'sushi', '10'),
    ('2', 'curry', '15'),
    ('3', 'ramen', '12');
    

    CREATE TABLE members (
    "customer_id" VARCHAR(1),
    "join_date" DATE
    );

    INSERT INTO members
    ("customer_id", "join_date")
    VALUES
    ('A', '2021-01-07'),
    ('B', '2021-01-09');
*/

-- QUESTION 1: What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) AS total_amount
FROM sales s 
JOIN menu m 
    ON s.product_id = m.product_id
GROUP BY customer_id


-- QUESTION 2: How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS cnt_date_visited
FROM sales 
GROUP BY customer_id

-- QUESION 3: What was the first item from the menu purchased by each customer?
SELECT customer_id, MIN(order_date), MIN(product_id)
FROM sales 
GROUP BY customer_id


-- QUESTION 4: What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_id, COUNT(customer_id) AS cnt_quantity_product
FROM sales 
GROUP BY product_id
ORDER BY COUNT(customer_id) DESC


-- QUESTION 5: Which item was the most popular for each customer?
SELECT customer_id, product_id, cnt_quantity_product
FROM 
(
    SELECT *, MAX(cnt_quantity_product) OVER(PARTITION BY customer_id ORDER BY cnt_quantity_product DESC) AS get_max
    FROM (
        SELECT customer_id, product_id, COUNT(product_id) AS cnt_quantity_product
        FROM sales 
        GROUP BY customer_id, product_id
    ) t1
) t2
WHERE get_max = cnt_quantity_product


-- QUESRION 6: Which item was purchased first by the customer after they became a member?
SELECT customer_id, order_date, product_id AS first_product_order
FROM (
-- Get table with sales after join_date
    SELECT s.customer_id, s.product_id, s.order_date
        , ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY order_date) AS rank_
    FROM sales s 
    JOIN members m 
        ON s.customer_id = m.customer_id AND DATEDIFF(DAY,  m.join_date, s.order_date) > 0
) x
WHERE rank_ = 1


-- QUESRION 7: Which item was purchased just before the customer became a member?
SELECT customer_id, order_date, product_id AS first_product_order
FROM(
    -- Get table with sales before join_date
    SELECT s.customer_id, s.order_date, s.product_id, m.join_date
        , ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY order_date) AS rank_
    FROM sales s 
    JOIN members m 
        ON s.customer_id = m.customer_id AND DATEDIFF(DAY,  m.join_date, s.order_date) < 0
) x
WHERE rank_= 1


-- QUESTION 8: What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, SUM(price) AS total_amount
FROM sales s 
JOIN members m 
    ON s.customer_id = m.customer_id AND DATEDIFF(DAY,  m.join_date, s.order_date) > 0
JOIN menu e
    ON e.product_id = s.product_id
GROUP BY s.customer_id


-- QUESTION 9: If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, SUM(total_points) AS total_points
FROM (
    SELECT customer_id
        , CASE 
            WHEN product_name = 'sushi' THEN (price * 20) 
            WHEN product_name <> 'sushi' THEN (price * 10)
            END AS total_points
    FROM sales s
    JOIN menu m 
        ON s.product_id = m.product_id
) x
GROUP BY customer_id


/*
QUESTION 10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
- how many points do customer A and B have at the end of January?
*/

SELECT customer_id, SUM(total_points) AS total_points
FROM (
    SELECT s.customer_id
        , CASE 
            WHEN DATEPART(week, s.order_date) = 1 THEN price * 20 
            ELSE price * 10 
            END 
            AS total_points
    FROM members e 
    JOIN sales s 
        ON e.customer_id = s.customer_id
    JOIN menu m 
        ON s.product_id = m.product_id
    WHERE DATEPART(MONTH, s.order_date) = '01' -- Get all sales from January
) x
GROUP BY customer_id
