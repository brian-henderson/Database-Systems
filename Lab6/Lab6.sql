-- =======================================================================================
-- Brian Henderson
-- Lab 6
-- DUE: 10/13/2016
-- =======================================================================================

-- 1: Displays the name and city of customers who live in any city that makes the most 
--    different kinds of products.
SELECT name, city
FROM customers
WHERE city IN ( SELECT city
                FROM products
                GROUP BY city
                ORDER BY count(*) DESC
                LIMIT 1 
              )
;

-- 2: Display the names of products whose priceUSD is strictly below the average priceUSD,
--    in reverse-alphabetical order.

SELECT name
FROM products
WHERE priceUSD < ( SELECT AVG(priceUSD)
                   FROM products
                 )
ORDER BY name DESC ;
