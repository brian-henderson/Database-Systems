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

-- 3: Display the customer name, pid ordered, and the total for all orders, sorted by 
--    total from low to high.
SELECT c1.name, c2.cid, o.pid, SUM(totalUSD) AS totalUSD
FROM Customers c1, Customers c2, Orders o
WHERE c1.cid = c2.cid
  AND c2.cid = o.cid
GROUP BY c1.name, c2.cid, o.pid
ORDER BY totalUSD ASC ;

-- 4: Display all customer names (in alphabetical order) and their total ordered, and nothing
--    more. Use coalesce to avoid showing NULLs.
SELECT c.name, COALESCE(sum(totalUSD), '0.00') AS sumTotalUSD
FROM Customers c LEFT OUTER JOIN Orders o ON c.cid = o.cid
GROUP BY o.cid, c.name
ORDER BY c.name ASC;

