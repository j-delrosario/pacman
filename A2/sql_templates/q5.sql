-- Q5. Flight Hopping

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5 (
	destination CHAR(3),
	num_flights INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS day CASCADE;
DROP VIEW IF EXISTS n CASCADE;

CREATE VIEW day AS
SELECT day::date as day FROM q5_parameters;
-- can get the given date using: (SELECT day from day)

CREATE VIEW n AS
SELECT n FROM q5_parameters;
-- can get the given number of flights using: (SELECT n from n)
--SELECT day FROM day;
--SELECT n FROM q5_parameters;
-- HINT: You can answer the question by writing one recursive query below, without any more views.
-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q5
(   SELECT destination, num_flights 
	FROM (WITH RECURSIVE flights AS (
		 (SELECT 'YYZ'::text as destination, (SELECT day FROM day)::timestamp as arv, 0 AS num_flights) 
		  UNION ALL
		 (SELECT Flight.inbound as destination, Flight.s_arv as arv, num_flights + 1 as num_flights FROM flights 
		 								  JOIN Flight on flights.destination = Flight.outbound and Flight.s_dep >= arv and Flight.s_dep <= arv + time '24:00:00'
									 WHERE num_flights < (SELECT n from n)))
		  SELECT * FROM flights) as flights_dest
	WHERE (num_flights >= 1)
);