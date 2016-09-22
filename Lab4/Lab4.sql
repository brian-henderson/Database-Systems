-- ==================================================================================
-- Brian Henderson
-- Lab 4
-- DUE: 9/29/2016
-- ==================================================================================

-- 1: Get the cities of agents booking an order for a customer whose cid is 'c006' --
SELECT distinct city
FROM agents
WHERE aid in ( SELECT aid
               FROM orders
               WHERE cid = 'c006'
             )
;

-- 2: Get the ids of products ordered through any agent	who	takes at least one order 
--    from a customer in Kyoto, sorted by pid from highest to lowest --
SELECT distinct pid
FROM orders
WHERE aid in ( SELECT aid
			   FROM orders
			   WHERE cid in ( SELECT cid
			   				  FROM customers
			   				  WHERE city = 'Kyoto'
             				) 
             )
ORDER BY pid DESC ;
