--------------------------- C. Ingredient Optimisation ----------------------------
-- use pizza_runner

-- QUESTION 1: What are the standard ingredients for each pizza?
SELECT * FROM pizza_recipes;



-- QUESTION 2: What was the most commonly added extra?
SELECT topping, COUNT(topping) AS commonly_added_extra
FROM (
    SELECT
    -- Using TRIM to remove space on LEFT and RIGHT of string
        extras, TRIM(value) AS topping 
    FROM (
            SELECT extras 
            FROM customer_orders 
            WHERE extras IS NOT NULL AND extras <> ''
        ) x
    -- Using STRING_SPLIT to string split after ','
    CROSS APPLY STRING_SPLIT(extras, ',')
) x2
GROUP BY topping;



-- QUESTION 3: What was the most common exclusion?
SELECT topping, COUNT(topping) AS commonly_exclusion
FROM (
    SELECT
    -- Using TRIM to remove space on LEFT and RIGHT of string
        exclusions, TRIM(value) AS topping 
    FROM (
            SELECT exclusions 
            FROM customer_orders 
            WHERE exclusions IS NOT NULL AND exclusions <> ''
        ) x
    -- Using STRING_SPLIT to string split after ','
    CROSS APPLY STRING_SPLIT(exclusions, ',')
) x2
GROUP BY topping;



/*
QUESTION 4: Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
*/
WITH get_text_extras AS (
    SELECT  order_id, customer_id, pizza_id
    , STRING_AGG(p.topping_name, ', ') AS extras
    FROM (
        SELECT distinct order_id, customer_id, pizza_id
            , TRIM(t1.value) AS value_extras
        FROM customer_orders 
        CROSS APPLY STRING_SPLIT(extras, ',') t1
    ) x1
    LEFT JOIN pizza_toppings p 
    ON x1.value_extras = p.topping_id
    GROUP BY order_id, customer_id, pizza_id
    HAVING STRING_AGG(p.topping_name, ', ') IS NOT NULL
)
, get_text_exclusions AS (
    SELECT  order_id, customer_id, pizza_id
    , STRING_AGG(p.topping_name, ', ') AS exclusions
    FROM (
        SELECT distinct order_id, customer_id, pizza_id
            , TRIM(t1.value) AS value_exclusions
        FROM customer_orders 
        CROSS APPLY STRING_SPLIT(exclusions, ',') t1
    ) x1
    LEFT JOIN pizza_toppings p 
    ON x1.value_exclusions = p.topping_id
    GROUP BY order_id, customer_id, pizza_id
    HAVING STRING_AGG(p.topping_name, ', ') IS NOT NULL
)

SELECT c.order_id, c.customer_id, c.pizza_id, c.exclusions, c.extras
    , CASE 
        WHEN exclu_t.exclusions IS NOT NULL AND extras_t.extras IS NOT NULL THEN CONCAT(p.pizza_name, ' - Exclude ' ,exclu_t.exclusions, ' - Extra ', extras_t.extras)
        WHEN exclu_t.exclusions IS NOT NULL AND extras_t.extras IS NULL THEN CONCAT(p.pizza_name, ' - Exclude ' ,exclu_t.exclusions) 
        WHEN exclu_t.exclusions IS NULL AND extras_t.extras IS NOT NULL THEN CONCAT(p.pizza_name, ' - Extra ' , extras_t.extras)
        WHEN exclu_t.exclusions IS NULL AND extras_t.extras IS NULL THEN p.pizza_name
        END AS generate_item_order
FROM customer_orders c
LEFT JOIN get_text_extras extras_t
    ON c.order_id = extras_t.order_id AND c.customer_id = extras_t.customer_id AND c.pizza_id = extras_t.pizza_id
LEFT JOIN get_text_exclusions exclu_t
    ON c.order_id = exclu_t.order_id AND c.customer_id = exclu_t.customer_id AND c.pizza_id = exclu_t.pizza_id
JOIN pizza_names p 
    ON c.pizza_id = p.pizza_id



-- QUESTION 5: Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- PAUSE because dont have data to test this

-- QUESTION 6: What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
SELECT value_extras, COUNT(value_extras) AS cnt_ingredient
FROM (
    SELECT TRIM(t1.value) AS value_extras
    FROM customer_orders 
    CROSS APPLY STRING_SPLIT(extras, ',') t1
) x
WHERE value_extras <> ''
GROUP BY value_extras
ORDER BY COUNT(value_extras) DESC