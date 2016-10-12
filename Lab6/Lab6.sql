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

-- 3: Displays the customer name, pid ordered, and the total for all orders, sorted by 
--    total from low to high.
SELECT c1.name, c2.cid, o.pid, SUM(totalUSD) AS totalUSD
FROM Customers c1, Customers c2, Orders o
WHERE c1.cid = c2.cid
  AND c2.cid = o.cid
GROUP BY c1.name, c2.cid, o.pid
ORDER BY totalUSD ASC ;

-- 4: Displays all customer names (in alphabetical order) and their total ordered, and
--    nothing more.
SELECT c.name, COALESCE(sum(totalUSD), '0.00') AS sumTotalUSD
FROM Customers c LEFT OUTER JOIN Orders o ON c.cid = o.cid
GROUP BY o.cid, c.name
ORDER BY c.name ASC;

-- 5: Displays the names of all customers who bought products from agents based in New York
--    along with the names of the products they ordered, and the names of the agents who sold it to them.
SELECT c.name AS "Customer", p.name AS "Product", a.name AS "Agent"
FROM Customers c, Agents a, Products p, Orders o
WHERE a.city = 'New York'
  AND o.cid  = c.cid
  AND o.aid  = a.aid
  AND o.pid  = p.pid ;

-- 6: Write a query to check the accuracy of the dollars column in the Orders table. This means calculating
--    Orders.totalUSD from data in other tables and comparing those values to the values in Orders.totalUSD. 
--    Display all rows in Orders where Orders.totalUSD is incorrect, if any.
DROP VIEW IF EXISTS checkDollars ;
CREATE VIEW checkDollars
AS
SELECT o.ordnum, c.discount, p.priceUSD, o.qty, 
       ((o.qty * p.priceUSD) - (o.qty * p.priceUSD * (c.discount/100))) AS viewCheckDollars_totalUSD
FROM Customers c, Orders o, Products p
WHERE o.cid = c.cid
  AND o.pid = p.pid ;

SELECT o.*, v.viewCheckDollars_totalUSD AS "CorrectTotalUSD" 
FROM Orders o, checkDollars v -- v represents the view
WHERE v.ordnum = o.ordnum
  AND v.viewCheckDollars_totalUSD != o.totalUSD ;