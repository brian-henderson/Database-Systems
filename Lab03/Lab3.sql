-- Brian Henderson
-- Lab 3
-- DUE: 9/22/2016

-- 1: List the order number and total dollars of all orders	--
SELECT ordnum, totalUSD
FROM orders;

-- 2: List the name and city of agents named Smith --
SELECT name, city
FROM agents
WHERE name = 'Smith';

-- 3: List the id, name, and priceUSD of products with quantity more than 201,000 --
SELECT pid, name, priceUSD
FROM products
WHERE quantity > 201000;

-- 4: List the names and cites of customers in Duluth --
SELECT name, city
FROM customers
WHERE city = 'Duluth';

-- 5: List the names of agents not in New York and not in Duluth --
SELECT name
FROM agents
WHERE city NOT IN ('New York','Duluth');

-- 6: List all data for products in neither Dallas nor Duluth that cost US$1 or more --
SELECT *
FROM products
WHERE city NOT IN ('Dallas', 'Duluth')
  AND priceUSD >= 1;

-- 7: List all data for orders in February or March --
SELECT *
FROM orders
WHERE mon = 'feb' 
   OR mon = 'mar';

-- 8: List all data for orders in February of US$600 or more --
SELECT *
FROM orders
WHERE mon = 'feb' 
  AND totalUSD >= 600;

-- 9: List all orders from the customer whose cid is C005 --
SELECT *   
FROM orders         
WHERE cid = 'C005';   