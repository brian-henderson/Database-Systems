-- =======================================================================================
-- Brian Henderson
-- Lab 4
-- DUE: 9/29/2016
-- =======================================================================================

-- 1: Get the cities of agents booking an order for a customer whose cid is 'c006' --
SELECT distinct city
FROM agents
WHERE aid IN ( SELECT aid
               FROM orders
               WHERE cid = 'c006'
             )
;

-- 2: Get the ids of products ordered through any agent	who	takes at least one order 
--    from a customer in Kyoto, sorted by pid from highest to lowest --
SELECT distinct pid
FROM orders
WHERE aid IN ( SELECT aid
               FROM orders
               WHERE cid in ( SELECT cid
                              FROM customers
                              WHERE city = 'Kyoto'
                            ) 
             )
ORDER BY pid DESC ;

-- 3: Gets the ids and names of customers who did not place	an order through agent a03 --
SELECT cid, name
FROM customers
WHERE cid IN ( SELECT cid
               FROM orders
               WHERE aid <> 'a03'
             )
;

-- 5: Gets the ids of products not ordered by any customers who placed any order through
--    agent a08 in pid order from highest to lowest. --	

SELECT distinct pid 
FROM orders
WHERE cid NOT IN ( SELECT cid
                   FROM orders
                   WHERE aid='a08'
                 )
ORDER BY pid DESC ;


-- 6: Gets the name, discounts, and city for all customers who place orders through agents 
--    in Dallas or New York.	
SELECT name, discount, city
FROM customers
WHERE cid IN ( SELECT cid
               FROM orders
               WHERE aid IN ( SELECT aid
                              FROM agents
                              WHERE city IN ( 'Dallas' , 'New York' )
                            ) 
             )
;