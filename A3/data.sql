INSERT INTO DIVER
VALUES
    (1, 'bob', 'bob@gmail.com', 'NAUI', '1998-08-09 16:05', '4113601974804222'),
    (2, 'tom', 'tom@gmail.com', 'CMAS', '1992-01-29 16:05', '4506252200423752'),
    (3, 'joe', 'joe@gmail.com', 'PADI', '1994-02-18 16:05', '4598986605832831'),
    (4, 'dog', 'dog@gmail.com', 'NAUI', '1990-09-01 16:05', '4558914732304266');
INSERT INTO Monitor
VALUES
    (1, 30, 20, 10),
    (2, 10, 4, 2);
INSERT INTO Site
VALUES
    (1, 10, 5),
    (2, 20, 10),
    (3, 2, 1);
INSERT INTO SiteDiveCapacity
VALUES
    (1,
        'night', 30),
    (1, 'cave diving', 4);
Insert Into Price
VALUES
    (1, 1, 'morning', 'open water', '50'),
    (1, 1, 'afternoon',
        'cave diving', '20');
Insert Into BookingPrivilege
VALUES
    (1, 1);
Insert Into Booking
VALUES
    (1, 1, 1, 1, 'open water', '2020-03-30 16:05', 'morning'),
    (1, 2, 2, 1, 'open water', '2020-03-31 16:05', 'morning');

Insert Into BookedService
VALUES
    (1, 'mask'),
    (1, 'hot showers');
Insert Into DiverToBooking
Values
    (1, 1);
Insert Into MonitorRating
VALUES
    (1, 1, 5),
    (1, 2, 4);
Insert Into SiteRating
VALUES
    (1, 1, 5);

INSERT Into FreeService
VALUES
    (1, 'snacks'),
    (1, 'hot showers');

Insert Into PaidService
VALUES
    (1, 'mask'),
    (1, 'fins');
