--------------------------- D. Pricing and Ratings ----------------------------
-- use pizza_runner

/* QUESTION 1: If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
- how much money has Pizza Runner made so far if there are no delivery fees?*/
SELECT c.pizza_id
    , p.pizza_name
    , COUNT(c.pizza_id) AS cnt_pizza
    , SUM( 
        CASE 
            WHEN p.pizza_name = 'Vegetarian' THEN 10
            WHEN p.pizza_name = 'Meatlovers' THEN 12
            ELSE 0
        END
    ) AS total_money
FROM customer_orders c 
JOIN pizza_names p 
    ON c.pizza_id = p.pizza_id
GROUP BY c.pizza_id, p.pizza_name;



-- QUESTION 2: What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra
SELECT order_id, pizza_id, customer_id, pizza_name, extras
    , SUM( 
            CASE 
                WHEN pizza_name = 'Vegetarian' AND cnt_topping <> 0 THEN 10 + cnt_topping
                WHEN pizza_name = 'Vegetarian' AND cnt_topping = 0 THEN 10
                WHEN pizza_name = 'Meatlovers' AND cnt_topping <> 0 THEN 12 + cnt_topping
                WHEN pizza_name = 'Meatlovers' AND cnt_topping = 0 THEN 12
                ELSE 0
            END
        ) AS total_money
FROM (
    -- Get table and count topping of each pizza
    SELECT c.order_id, c.pizza_id, c.customer_id, p.pizza_name
        , CASE WHEN extras IS NULL THEN '' ELSE extras END AS extras
        , CASE 
            WHEN LEN(REPLACE(extras,', ','')) IS NOT NULL THEN LEN(REPLACE(extras,', ','')) 
            ELSE 0
            END AS cnt_topping
    FROM customer_orders c 
    JOIN pizza_names p 
        ON c.pizza_id = p.pizza_id
) x
GROUP BY order_id, pizza_id, customer_id, pizza_name, extras;



/* QUESTION 3: If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled 
- how much money does Pizza Runner have left over after these deliveries?
*/
WITH get_standard_distance AS (
    SELECT 
        order_id
        , CASE 
            WHEN check_space_distance <> 0 THEN SUBSTRING(distance, 0, check_space_distance) 
            WHEN check_space_distance = 0 AND check_k = 0 THEN distance
            WHEN check_space_distance = 0 AND check_k <> 0 THEN SUBSTRING(distance, 0, check_k) 
        END AS standard_distance
    FROM (
        SELECT order_id, distance
            , CHARINDEX( ' ', distance, 0 ) AS check_space_distance
            , CHARINDEX( 'k', distance, 0 ) AS check_k
        FROM runner_orders WHERE duration IS NOT NULL
    ) x
)
SELECT c.order_id, customer_id, c.pizza_id, standard_distance
    , CASE 
        WHEN LEN(REPLACE(extras,', ','')) IS NOT NULL THEN LEN(REPLACE(extras,', ','')) 
        ELSE 0
        END AS cnt_topping
    , CAST(standard_distance AS FLOAT) * 0.3 AS fee_delivery
    , CASE 
        WHEN p.pizza_name = 'Vegetarian' THEN 10 - (CAST(standard_distance AS FLOAT) * 0.3)
        WHEN p.pizza_name = 'Meatlovers' THEN 12 - (CAST(standard_distance AS FLOAT) * 0.3)
        END AS after_fee_delivery
FROM customer_orders c
JOIN get_standard_distance g
    ON c.order_id = g.order_id
JOIN pizza_names p 
    ON c.pizza_id = p.pizza_id


