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

-- 5: Shows the names of customers who place at least one order through an agent in their 
--    own city along with those agents names --
SELECT DISTINCT c.name AS "CustomerName" , a.name AS "AgentName"
FROM customers c, agents a, orders o
WHERE o.cid = c.cid 
  AND o.aid = a.aid
  AND c.city = a.city ;


-- 6: Shows the names of customers and agents that reside in the same city --
SELECT c.name AS "CustomerName" , a.name AS "AgentName" , a.city AS "SharedCity"
FROM customers c INNER JOIN agents a ON a.city=c.city ;