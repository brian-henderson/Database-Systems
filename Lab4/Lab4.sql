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