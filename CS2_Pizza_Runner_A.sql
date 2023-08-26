/*
DATASET 
USE pizza_runner 
CREATE TABLE runners (
  "runner_id" INTEGER, "registration_date" DATE
);
INSERT INTO runners (
  "runner_id", "registration_date"
) 
VALUES 
  (1, '2021-01-01'), 
  (2, '2021-01-03'), 
  (3, '2021-01-08'), 
  (4, '2021-01-15');
CREATE TABLE customer_orders (
  "order_id" INTEGER, 
  "customer_id" INTEGER, 
  "pizza_id" INTEGER, 
  "exclusions" VARCHAR(4), 
  "extras" VARCHAR(4), 
  "order_time" DATETIME
);
INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', NULL, '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', NULL, NULL, '2020-01-08 21:03:13'),
  ('7', '105', '2', NULL, '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', NULL, NULL, '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', NULL, NULL, '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');
CREATE TABLE runner_orders (
  "order_id" INTEGER, 
  "runner_id" INTEGER, 
  "pickup_time" VARCHAR(19), 
  "distance" VARCHAR(7), 
  "duration" VARCHAR(10), 
  "cancellation" VARCHAR(23)
);
INSERT INTO runner_orders (
  "order_id", "runner_id", "pickup_time", 
  "distance", "duration", "cancellation"
) 
VALUES 
  (
    '1', '1', '2020-01-01 18:15:34', '20km', 
    '32 minutes', ''
  ), 
  (
    '2', '1', '2020-01-01 19:10:54', '20km', 
    '27 minutes', ''
  ), 
  (
    '3', '1', '2020-01-03 00:12:37', '13.4km', 
    '20 mins', NULL
  ), 
  (
    '4', '2', '2020-01-04 13:53:03', '23.4', 
    '40', NULL
  ), 
  (
    '5', '3', '2020-01-08 21:10:57', '10', 
    '15', NULL
  ), 
  (
    '6', '3', NULL, NULL, NULL, 'Restaurant Cancellation'
  ), 
  (
    '7', '2', '2020-01-08 21:30:45', '25km', 
    '25mins', NULL
  ), 
  (
    '8', '2', '2020-01-10 00:15:02', '23.4 km', 
    '15 minute', NULL
  ), 
  (
    '9', '2', NULL, NULL, NULL, 'Customer Cancellation'
  ), 
  (
    '10', '1', '2020-01-11 18:50:20', 
    '10km', '10minutes', NULL
  );
CREATE TABLE pizza_names (
  "pizza_id" INTEGER, "pizza_name" TEXT
);
INSERT INTO pizza_names ("pizza_id", "pizza_name") 
VALUES 
  (1, 'Meatlovers'), 
  (2, 'Vegetarian');
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER, "toppings" TEXT
);
INSERT INTO pizza_recipes ("pizza_id", "toppings") 
VALUES 
  (1, '1, 2, 3, 4, 5, 6, 8, 10'), 
  (2, '4, 6, 7, 9, 11, 12');
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER, "topping_name" TEXT
);
INSERT INTO pizza_toppings ("topping_id", "topping_name") 
VALUES 
  (1, 'Bacon'), 
  (2, 'BBQ Sauce'), 
  (3, 'Beef'), 
  (4, 'Cheese'), 
  (5, 'Chicken'), 
  (6, 'Mushrooms'), 
  (7, 'Onions'), 
  (8, 'Pepperoni'), 
  (9, 'Peppers'), 
  (10, 'Salami'), 
  (11, 'Tomatoes'), 
  (12, 'Tomato Sauce');

*/
-------------------------- A. Pizza Metrics ------------------------------------------

-- QUESTION 1: How many pizzas were ordered?
SELECT COUNT(order_id) AS total_orders FROM customer_orders;

-- QUESTION 2: How many unique customer orders were made?
SELECT COUNT(DISTINCT customer_id) AS cnt_distinct_customer FROM customer_orders;

-- QUESTION 3: How many successful orders were delivered by each runner?
SELECT COUNT(*) AS total_success
FROM runner_orders
WHERE cancellation IS NULL OR cancellation LIKE '' OR cancellation LIKE 'null';

-- QUESTION 4: How many of each type of pizza was delivered?
SELECT c.pizza_id, p.pizza_name, COUNT(c.pizza_id) AS total_type_pizza
FROM customer_orders c
JOIN pizza_names p
    ON c.pizza_id = p.pizza_id
GROUP BY c.pizza_id, p.pizza_name;

-- QUESTION 5: How many Vegetarian and Meatlovers were ordered by each customer?
SELECT c.customer_id, p.pizza_name, COUNT(c.pizza_id) AS total_orders
FROM customer_orders c
JOIN pizza_names p 
  ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id, p.pizza_name;

-- QUESTION 6: What was the maximum number of pizzas delivered in a single order?
WITH total_orders AS (
  SELECT order_id, COUNT(pizza_id) AS total_orders
  FROM customer_orders
  GROUP BY order_id
)
SELECT * FROM total_orders WHERE total_orders = (SELECT MAX(total_orders) FROM total_orders);

-- QUESTION 7: For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
WITH get_first_order_by_each_pizza AS (
  SELECT * FROM 
  (
    SELECT order_id, customer_id, pizza_id, order_time
      , ISNULL(extras, '' ) AS extras
      , ISNULL(exclusions, '' ) AS exclusions
      , ROW_NUMBER() OVER(PARTITION BY customer_id, pizza_id ORDER BY order_time) AS rank_
    FROM customer_orders
  ) x
  WHERE rank_ = 1
)
, get_pizza_change AS (
  SELECT c.customer_id, COUNT(c.pizza_id) AS cnt_pizza_change
  FROM (
    SELECT order_id
      ,customer_id
      ,pizza_id
      ,order_time
      ,ISNULL(extras, '') AS extras
      ,ISNULL(exclusions, '') AS exclusions
    FROM customer_orders
    ) c
  JOIN get_first_order_by_each_pizza g ON c.customer_id = g.customer_id
    AND c.pizza_id = g.pizza_id
    AND c.order_time > g.order_time
  WHERE c.exclusions <> g.exclusions OR c.extras <> g.extras
  GROUP BY c.customer_id
)
, get_pizza_no_change AS (
  SELECT c.customer_id, COUNT(c.pizza_id) AS cnt_pizza_no_change
  FROM (
    SELECT order_id
      ,customer_id
      ,pizza_id
      ,order_time
      ,ISNULL(extras, '') AS extras
      ,ISNULL(exclusions, '') AS exclusions
    FROM customer_orders
    ) c
  JOIN get_first_order_by_each_pizza g ON c.customer_id = g.customer_id
    AND c.pizza_id = g.pizza_id
    AND c.order_time > g.order_time
  WHERE c.exclusions = g.exclusions AND c.extras = g.extras
  GROUP BY c.customer_id
)
-- SELECT * FROM get_pizza_change
-- SELECT * FROM get_pizza_no_change


-- QUESTION 8: How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(*) AS total_both_exclusions_extras
FROM customer_orders
WHERE exclusions IS NOT NULL AND exclusions <> '' AND extras IS NOT NULL AND extras <> ''
  
-- QUESTION 9: What was the total volume of pizzas ordered for each hour of the day?
SELECT hour_part, COUNT(pizza_id) AS quantity
FROM (
  SELECT pizza_id, DATEPART(HOUR, order_time) AS hour_part
  FROM customer_orders
) x
GROUP BY hour_part
ORDER BY COUNT(pizza_id) DESC, hour_part ASC


-- QUESTION 10: What was the volume of orders for each day of the week?
SELECT week_day, COUNT(pizza_id) AS quantity
FROM (
  SELECT pizza_id, DATENAME(WEEKDAY, order_time) AS week_day
  FROM customer_orders
) x
GROUP BY week_day
ORDER BY COUNT(pizza_id) DESC, week_day ASC

