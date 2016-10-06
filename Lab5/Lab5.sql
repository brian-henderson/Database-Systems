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
  AND o.cid = 'c006' ;
  
-- 2: Shows the ids of products ordered through any agent who makes at least one order for
--    a customer in Kyoto, sorted by PID from highest to lowest. --
SELECT DISTINCT ord2.pid
FROM customers c,
     orders ord1 FULL OUTER JOIN orders ord2 ON ord1.aid = ord2.aid
WHERE c.city = 'Kyoto'
  AND c.cid  = ord1.cid
ORDER BY ord2.pid ;
 
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

-- 5: Shows the names of customers who place at least one order through an agent in their 
--    own city along with those agents names --
SELECT DISTINCT c.name AS "CustomerName" , a.name AS "AgentName"
FROM customers c, 
     agents a, 
     orders o
WHERE o.cid = c.cid 
  AND o.aid = a.aid
  AND c.city = a.city ;

-- 6: Shows the names of customers and agents that reside in the same city --
SELECT c.name AS "CustomerName" , a.name AS "AgentName" , a.city AS "SharedCity"
FROM customers c INNER JOIN agents a ON a.city = c.city ;

-- 7: Shows the name and city of customers who live in the city that makes the fewest different  
--    kinds of products.
SELECT name, city
FROM customers
WHERE city IN ( SELECT city
                FROM products
                GROUP BY city
                ORDER BY COUNT(*) ASC 
                LIMIT 1
              )
;