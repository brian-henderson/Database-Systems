-- =======================================================================================
-- Brian Henderson
-- Lab 4
-- DUE: 9/29/2016
-- =======================================================================================

-- 1: Gets the cities of agents booking an order for a customer whose cid is 'c006' --
SELECT distinct city
FROM agents
WHERE aid IN ( SELECT aid
               FROM orders
               WHERE cid = 'c006'
             )
;

-- 2: Gets the ids of products ordered through any agent	who takes at least one order 
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

-- 3: Gets the ids and names of customers who did not place an order through agent a03 --
SELECT cid, name
FROM customers
WHERE cid IN ( SELECT cid
               FROM orders
               WHERE aid <> 'a03'
             )
;

-- 4: Gets the ids of customers who ordered both product p01 and p07 --
SELECT distinct cid
FROM orders
WHERE pid='p01'
  AND cid IN ( SELECT cid
               FROM orders
               WHERE pid = 'p07'
             )
;


-- 5: Gets the ids of products not ordered by any customers who placed any order through
--    agent a08 in pid order from highest to lowest --	
SELECT distinct pid 
FROM orders
WHERE cid NOT IN ( SELECT cid
                   FROM orders
                   WHERE aid = 'a08'
                 )
ORDER BY pid DESC ;


-- 6: Gets the name, discounts, and city for all customers who place orders through agents 
--    in Dallas or New York --	
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

-- 7: Gets all customers who have the same discount as that of any  customers in 
--    Dallas or London --
SELECT name
FROM customers
WHERE city NOT IN ( 'Dallas' , 'London' ) 
  AND discount IN ( SELECT discount
                    FROM customers
                    WHERE city IN ( 'Dallas' , 'London' )
                  )
;


/* 8: Check Constraints
    
        Check constraints specify data values that are allowed in the coloumns of the table. 
    Check constraints are good because they force user to enter the desired data. The advantage
    of this is that it allows for more accurate data. A good use for a check constraint would
    be if the table is looking for a specfic set of entries.  This ensures that the data is
    streamlined and accurate. A bad use for a check constraint would be if the data entered has
    more acceptable options than what is listed in the check constraint.
    
    Good Example:
    1. Checking gender input data.
        CHECK (gender = 'F' or gender = 'M')
        This is a good use of a check constraint because when entering gender data there are
        only two valid options. 
        

    Bad Example:
    1.  Checking a name input data
        This would be a very bad use of a check constraint because there is a vast set of names
        and would be very difficult, nearly impossible, to check every single name for validity.


        The differences betweent the two examples is that the first example, the good one, has a
    definite set of valid data entries, in this case it is two. The second example, the bad one, 
    has an indefinite number of data entries. It would be nearly impossible to check every name
    entered for validity, but for gender it makes sense because there are only two options and
    having a check constraint makes the data more streamlined and accurate.
*/ 