-- Q2. Refunds!
-- For domestic flights (flights within the same country), a 35% refund is given for a departure delay of 4 hours or more, and a 50% refund for 10 hours or more. For international flights 
-- (flights between different countries), a 35% refund is given for a departure delay of 7hours or more, and a 50% refund for 12 hours or more.However, if the pilots manage to make up time 
-- during the flight and have an arrival delay that is at mosthalfof the departure delay, then no refund is provided, regardless of how many hours the delay was.For every airline and year
--  that the airline had flights which required refunds, return thetotalrefund moneygiven in that particular year in each seat class.  This means there should be at most three records per 
-- airline-year combination (you should not include a seat class if no one booked it for any refunded flight).  The yearof a flight comes from its scheduled departure date.
-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH
TO air_travel, public;
DROP TABLE IF EXISTS q2
CASCADE;

CREATE TABLE q2
(
    airline CHAR(2),
    name VARCHAR(50),
    year CHAR(4),
    seat_class seat_class,
    refund REAL
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step, international_35, international_50,
domestic_35, domestic_50, not_counted, temp_50, temp_35,
discounts_50, discounts_35, final_35, final_50
CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW international_35
AS
    SELECT id as flight_id, airline
    FROM
        Flight
        Join Departure on Flight.id = Departure.flight_id
        Join Airport dep on dep.code = outbound
        Join Airport arr on arr.code = inbound
    WHERE (datetime - s_dep) >= '7:00:00' and (datetime - s_dep) < '12:00:00' and dep.country != arr.country;

CREATE VIEW international_50
AS
    SELECT id as flight_id, airline
    FROM
        Flight
        Join Departure on Flight.id = Departure.flight_id
        Join Airport dep on dep.code = outbound
        Join Airport arr on arr.code = inbound
    WHERE (datetime - s_dep) >= '12:00:00' and dep.country != arr.country;

CREATE VIEW domestic_35
AS
    SELECT id as flight_id, airline
    FROM
        Flight
        Join Departure on Flight.id = Departure.flight_id
        Join Airport dep on dep.code = outbound
        Join Airport arr on arr.code = inbound
    WHERE (datetime - s_dep) >= '4:00:00' and (datetime - s_dep) < '10:00:00' and dep.country = arr.country;

CREATE VIEW domestic_50
AS
    SELECT id as flight_id, airline
    FROM
        Flight
        Join Departure on Flight.id = Departure.flight_id
        Join Airport dep on dep.code = outbound
        Join Airport arr on arr.code = inbound
    WHERE (datetime - s_dep) >= '10:00:00' and dep.country = arr.country;

CREATE VIEW not_counted
AS
    SELECT id as flight_id, airline
    FROM
        Flight
        Join Departure on Flight.id = Departure.flight_id
        Join Airport dep on dep.code = outbound
        Join Airport arr on arr.code = inbound
        Join Arrival on Flight.id = Arrival.flight_id
    WHERE Departure.datetime > s_dep and (Departure.datetime - s_dep)/2 > (Arrival.datetime - s_arv);

CREATE VIEW temp_50
AS
            (
                SELECT *
        FROM international_50
        )
    UNION
        (SELECT *
        FROM domestic_50);


CREATE VIEW temp_35
AS
            (
                SELECT *
        FROM international_35
        )
    UNION
        (SELECT *
        FROM domestic_35);

CREATE VIEW discounts_50
AS
            (
                SELECT *
        FROM temp_50
        )
    EXCEPT
        (SELECT *
        FROM not_counted);

CREATE VIEW discounts_35
AS
            (
                SELECT *
        FROM temp_35
        )
    EXCEPT
        (SELECT *
        FROM not_counted);


CREATE VIEW final_50
AS
    SELECT Flight.airline, name, SUBSTRING(cast(s_dep as TEXT),0,5) as year, seat_class, sum(price)*.5 as refund
    FROM
        Booking Join Flight On Booking.flight_id = Flight.id
        Join
        discounts_50 on Booking.flight_id = discounts_50.flight_id
        Join Airline on code = Flight.airline

    group by Flight.airline, name, year, seat_class;


CREATE VIEW final_35
AS
    SELECT Flight.airline, name, SUBSTRING(cast(s_dep as TEXT),0,5) as year, seat_class, sum(price)*.35 as refund
    FROM
        Booking Join Flight On Booking.flight_id = Flight.id
        Join
        discounts_35 on Booking.flight_id = discounts_35.flight_id
        Join Airline on code = Flight.airline

    group by Flight.airline, name, year, seat_class;
-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2
(
SELECT *
from final_50
)
Union
(SELECT *
from final_35);