--Brian Henderson
--Lab 3
--DUE: 9/22/2016

--1--
SELECT ordnum, totalUSD
FROM orders;

--2--
SELECT name, city
FROM agents
WHERE name='Smith';

--3--
SELECT pid, name, priceUSD
FROM products
WHERE quantity > 201000;

--4--
SELECT name, city
FROM customers
WHERE city='Duluth';

--5--
SELECT name
FROM agents
WHERE city NOT IN ('New York','Duluth');

--6--
SELECT *
FROM products
WHERE city NOT IN ('Dallas', 'Duluth')
  AND priceUSD >= 1;

--7--
SELECT *
FROM orders
WHERE mon='feb' 
   OR mon='mar';

--8--
SELECT *
FROM orders
WHERE mon='feb' 
  AND totalUSD >= 600;

--9--
SELECT *
FROM orders
WHERE cid='C005';