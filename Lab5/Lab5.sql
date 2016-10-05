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