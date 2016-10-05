-- =======================================================================================
-- Brian Henderson
-- Lab 5
-- DUE: 10/6/2016
-- =======================================================================================

-- 1: Shows the cities of agents booking an order for a customer whose id is c006 --
SELECT a.city
FROM  agents a,
      orders o
WHERE o.aid = a.aid
  AND o.cid='c006' ;
  
  
-- 3: Shows the names of customers who have never placed an order. (Using a subquery ) --
SELECT name
FROM customers
WHERE cid NOT IN ( SELECT cid
                   FROM orders
                 )
;

-- 4: Shows the names of customers who have never placed an order. (Using an outer join ) --
SELECT c.name
FROM customers c LEFT OUTER JOIN orders o ON c.cid = o.cid
WHERE o.cid is null ;