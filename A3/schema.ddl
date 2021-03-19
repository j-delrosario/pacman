-- Constraints not enforced: Booking group size limited by how many people the monitor is willing to take, Sites limit how many divers during daylight hours,
--                           Sites limit how many divers by the the type of dive, Service being paid for in a booking is actually offered at the dive site,         
--                           Dive monitors aren't allowed more than two dives per 24 hour period, Dive monitors actually have booking privileges with the site they're diving at,  
--                           Rating of a dive monitor can only be done by the lead diver, Ratings can only be done by divers who actually dove at the site/with that monitor                                 
-- Since no triggers or assertions are allowed and psql doesn't support subqueries in row/column checks

DROP SCHEMA IF EXISTS wetworldschema
CASCADE;
CREATE SCHEMA wetworldschema;
SET SEARCH_PATH
to wetworldschema;

CREATE DOMAIN POSINT AS INT NOT NULL CHECK
(value >= 0);
CREATE DOMAIN POSPRICE AS DECIMAL NOT NULL CHECK
(value >= 0);
CREATE DOMAIN TIMEOFDAY AS VARCHAR
(15) NOT NULL CHECK
(value = 'morning' or value = 'afternoon' or value = 'night');
CREATE DOMAIN DIVETYPE AS VARCHAR
(30) NOT NULL CHECK
(value = 'open water' or value = 'cave diving' or value = 'beyond 30 meters');
CREATE DOMAIN FREESERVICE AS VARCHAR
(30) NOT NULL CHECK
(value = 'video of dives' or value = 'snacks' or value = 'hot showers' or value = 'towel service');
CREATE DOMAIN PAIDSERVICE AS VARCHAR
(30) NOT NULL CHECK
(value = 'mask' or value = 'regulator' or value = 'fins' or value = 'wrist-mounted dive computer');
CREATE DOMAIN RATING AS INT NOT NULL CHECK
(value >= 0 and value <= 5);

-- A diver.
CREATE TABLE Diver
(
    diver_id INT PRIMARY KEY,
    -- The name of the diver.
    diver_name VARCHAR(50) NOT NULL,
    -- The email of the diver.
    email VARCHAR(30) NOT NULL,
    -- Certification type of the diver
    certification VARCHAR(4) NOT NULL CHECK (certification = 'NAUI' or certification = 'CMAS' or certification = 'PADI'),
    -- Date of birth of the diver
    birthdate TIMESTAMP NOT NULL CHECK (age(birthdate) > '16 years'
    ::interval),
  -- Credit card information for the diver,
  cc VARCHAR
    (50) NOT NULL
);

    -- A dive monitor
    CREATE TABLE Monitor
    (
        monitor_id INT PRIMARY KEY,
        -- Max group size for open water dives 
        monitor_capacity_open_water POSINT,
        -- Max group size for cave dives
        monitor_capacity_cave POSINT,
        -- Max group size for dives beyond 30 meters
        monitor_capacity_beyond_30 POSINT
    );


    -- A dive site
    CREATE TABLE Site
    (
        site_id INT PRIMARY KEY,
        -- Max divers allowed on site during the morning
        site_capacity_morning POSINT,
        -- Max divers allowed on site during the afternoon
        site_capacity_afternoon POSINT
    );
    -- Price a monitor charges for a specific dive at a site
    CREATE TABLE Price
    (
        monitor_id INT REFERENCES Monitor(monitor_id),
        -- Site for the dive
        site_id INT REFERENCES Site(site_id),
        -- Time of day for the dive
        time_of_day TIMEOFDAY,
        -- Type of the dive
        dive_type DIVETYPE,
        -- Price for the dive
        dive_price POSPRICE,
        -- Only one price per dive site/type/time of day per monitor
        PRIMARY KEY (monitor_id, site_id, time_of_day, dive_type)
    );


    -- Site where a monitor has booking privileges
    CREATE TABLE BookingPrivilege
    (
        -- Monitor who has the booking privilege
        monitor_id INT NOT NULL,
        -- Site where the monitor has booking privileges
        site_id INT NOT NULL,
        -- Can't have a monitor having booking privilege multiple times with the same site
        PRIMARY KEY (monitor_id, site_id)
    );

    -- Max divers allowed on a site in a given dive type
    CREATE TABLE SiteDiveCapacity
    (
        site_id INT REFERENCES Site(site_id),
        -- Type of the dive
        restricted_dive_type VARCHAR(30) NOT NULL CHECK (restricted_dive_type = 'night' or restricted_dive_type = 'cave diving' or restricted_dive_type = 'beyond 30 meters'),
        -- Max divers allowed at one time for the above type of dive
        dive_capacity POSINT,
        -- One one capacity per site per dive type
        PRIMARY KEY (site_id, restricted_dive_type)
    );

    -- Booking information for a dive
    CREATE TABLE Booking
    (
        booking_id INT PRIMARY KEY,
        -- Monitor for the dive
        monitor_id INT REFERENCES Monitor(monitor_id),
        -- Lead diver for the dive
        diver_id INT REFERENCES Diver(diver_id),
        -- Site of the dive
        site_id INT REFERENCES Site(site_id),
        -- Type of the dive
        dive_type DIVETYPE,
        -- Date of the dive
        dive_date DATE NOT NULL
        -- Time of day of the dive
        time_of_day TIMEOFDAY,
    -- How many divers are participating
    group_size POSINT,
    -- Credit card information for the booking
    cc VARCHAR
        (50) NOT NULL,
    -- Cannot book more than one dive on the same day at the same time
    UNIQUE
        (diver_id, dive_date, time_of_day)
);

        -- Diver participating in a booked dive
        CREATE TABLE DiverToBooking
        (
            -- Diver participating
            diver_id INT REFERENCES Diver(diver_id),
            -- Booking of the dive
            booking_id INT REFERENCES Booking(booking_id),
            -- Diver can't be double (or more) booked per dive
            PRIMARY KEY (diver_id, booking_id)
        );

        -- Free service a site offers
        CREATE TABLE FreeService
        (
            site_id INT REFERENCES Site(site_id),
            -- Type of service offered
            free_service FREESERVICE,
            -- Site can't have multiple copies of the same service
            PRIMARY KEY (site_id, free_service)
        );

        -- Paid service a site offers
        CREATE TABLE PaidService
        (
            site_id INT REFERENCES Site(site_id),
            -- Type of service offered
            paid_service PAIDSERVICE,
            -- Price of the service
            service_price POSPRICE,
            -- Site can't charge different rates for the same service
            PRIMARY KEY (site_id, paid_service)
        );

        -- Services booked for a dive
        CREATE TABLE BookedService
        (
            booking_id INT REFERENCES Booking(booking_id),
            -- Type of service booked
            paid_service PAIDSERVICE,
            -- Can't book multiple copies of the same service
            PRIMARY KEY (booking_id, paid_service)
        );

        -- Rating of a dive site by a diver
        CREATE TABLE SiteRating
        (
            -- Diver giving the rating
            diver_id INT REFERENCES Diver(diver_id),
            -- Dive site being rated
            site_id INT REFERENCES Site(site_id),
            -- Rating on a scale of 0 to 5
            rating RATING,
            -- Can't have different ratings for the same site
            PRIMARY KEY (diver_id, site_id)
        );

        -- Rating of a monitor by a lead diver
        CREATE TABLE MonitorRating
        (
            -- Lead diver giving the rating
            diver_id INT REFERENCES Diver(diver_id),
            -- Dive monitor being rated
            monitor_id INT REFERENCES Monitor(monitor_id),
            -- Rating on a scale of 0 to 5
            rating RATING,
            -- Can't have different ratings for the same monitor
            PRIMARY KEY (diver_id, monitor_id)
        );
