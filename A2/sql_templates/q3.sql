-- Q3. North and South Connections

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH
TO air_travel, public;
DROP TABLE IF EXISTS q3
CASCADE;

CREATE TABLE q3
(
    outbound VARCHAR(30),
    inbound VARCHAR(30),
    direct INT,
    one_con INT,
    two_con INT,
    earliest timestamp
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step, flights_direct, flights_one_con, flights_two_con, flights_direct_temp, flights_one_con_temp, flights_two_con_temp, earliest_time, flights_con, all_pairs, last_step,
CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW flights_direct_temp
AS
    SELECT Flight.outbound as outbound0, Flight.inbound as inbound1, Flight.s_arv as arrival, dep.city as origin_city, dep.country as origin_country, arr.city as dest_city, arr.country as dest_country
    FROM
        Flight
        Join Airport dep on Flight.outbound = dep.code
        Join Airport arr on Flight.inbound = arr.code
    WHERE ((s_dep - '2020-04-30') <= '24:00:00' and (s_dep - '2020-04-30') >= '00:00:00') and
        ((s_arv - '2020-04-30') <= '24:00:00' and (s_arv - '2020-04-30') >= '00:00:00') and
        (dep.country = 'USA' or
        (dep.country = 'Canada'));

CREATE VIEW flights_one_con_temp
AS
    SELECT Flight.outbound as outbound1, Flight.inbound as inbound2, Flight.s_arv as arrival, origin_city, origin_country, arr.city as dest_city, arr.country as dest_country
    FROM
        Flight
        Join Airport dep on Flight.outbound = dep.code
        Join Airport arr on Flight.inbound = arr.code
        JOIN flights_direct_temp on flights_direct_temp.inbound1 = Flight.outbound
    WHERE ((s_dep - '2020-04-30') <= '24:00:00' and (s_dep - '2020-04-30') >= '00:00:00') and
        ((s_arv - '2020-04-30') <= '24:00:00' and (s_arv - '2020-04-30') >= '00:00:00') and
        (s_dep - arrival >= '00:30:00');

CREATE VIEW flights_two_con_temp
AS
    SELECT Flight.outbound as outbound2, Flight.inbound as inbound3, Flight.s_arv as arrival, origin_city, origin_country, arr.city as dest_city, arr.country as dest_country
    FROM
        Flight
        Join Airport dep on Flight.outbound = dep.code
        Join Airport arr on Flight.inbound = arr.code
        JOIN flights_one_con_temp on flights_one_con_temp.inbound2 = Flight.outbound
    WHERE ((s_dep - '2020-04-30') <= '24:00:00' and (s_dep - '2020-04-30') >= '00:00:00') and
        ((s_arv - '2020-04-30') <= '24:00:00' and (s_arv - '2020-04-30') >= '00:00:00') and
        (s_dep - arrival >= '00:30:00');


CREATE VIEW flights_direct
AS
    SELECT origin_city, dest_city, COUNT(*) as c, MIN(arrival) as m
    FROM
        flights_direct_temp
    WHERE ((origin_country = 'USA' and dest_country = 'Canada') or
        (origin_country = 'Canada' and dest_country = 'USA'))
    GROUP BY origin_city, dest_city;

CREATE VIEW flights_one_con
AS
    SELECT origin_city, dest_city, COUNT(*) as c, MIN(arrival) as m
    FROM
        flights_one_con_temp
    WHERE ((origin_country = 'USA' and dest_country = 'Canada') or
        (origin_country = 'Canada' and dest_country = 'USA'))
    GROUP BY origin_city, dest_city;

CREATE VIEW flights_two_con
AS
    SELECT origin_city, dest_city, COUNT(*) as c, MIN(arrival) as m
    FROM
        flights_two_con_temp
    WHERE ((origin_country = 'USA' and dest_country = 'Canada') or
        (origin_country = 'Canada' and dest_country = 'USA'))
    GROUP BY origin_city, dest_city;

CREATE VIEW earliest_time
AS
    SELECT origin_city, dest_city, MIN(m) as earliest
    FROM
        (                                                                                                                                                                                    SELECT *
            FROM flights_direct
        UNION ALL
            SELECT *
            FROM flights_one_con) as f
    GROUP BY origin_city, dest_city;

CREATE VIEW flights_con
AS
    SELECT earliest_time.origin_city as outbound, earliest_time.dest_city as inbound, flights_direct.c as direct, flights_one_con.c as one_con, flights_two_con.c as two_con, earliest
    FROM
        flights_direct
        FULL OUTER JOIN flights_one_con on (flights_direct.origin_city = flights_one_con.origin_city and flights_direct.dest_city = flights_one_con.dest_city)
        FULL OUTER JOIN flights_two_con on (flights_direct.origin_city = flights_two_con.origin_city and flights_direct.dest_city = flights_two_con.dest_city)
        FULL OUTER JOIN earliest_time on (flights_direct.origin_city = earliest_time.origin_city and flights_direct.dest_city = earliest_time.dest_city)
;

CREATE VIEW all_pairs
AS
    SELECT distinct(a.city) as outbound, b.city as inbound
    FROM
        Airport a, Airport b
    WHERE (a.country = 'USA' and b.country = 'Canada')
        or (b.country = 'USA' and a.country = 'Canada')
;

CREATE VIEW last_step
AS
    SELECT p.outbound, p.inbound,
        (SELECT c
        FROM
            flights_direct
        where p.outbound = origin_city and p.inbound = dest_city) as direct,
        (SELECT c
        FROM
            flights_one_con
        where p.outbound = origin_city and p.inbound = dest_city) as one_con,
        (SELECT c
        FROM
            flights_two_con
        where p.outbound = origin_city and p.inbound = dest_city) as two_con,
        (SELECT earliest
        FROM
            earliest_time
        where p.outbound = origin_city and p.inbound = dest_city
    )
    From

        all_pairs p
;
-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3
select outbound, inbound, COALESCE(direct,0) as direct,
    COALESCE(one_con,0) as one_con,
    COALESCE(two_con,0) as two_con,
    earliest
from last_step;