

DROP VIEW IF EXISTS monitor_ratings,monitor_use_dive_sites,site_ratings;

CREATE VIEW monitor_ratings
AS
    SELECT monitor_id, avg(rating) as avg_monitor_rating
    FROM MonitorRating

    group by monitor_id;


Create View monitor_use_dive_sites_ratings
AS
    Select site_id, Booking.monitor_id as monitor_id
    FROM
        monitor_ratings join Booking on 
    monitor_ratings.monitor_id = 
    Booking.monitor_id
;

Create VIEW site_ratings
AS
    SELECT monitor_id, avg(SiteRating.rating) as avg_site_rating
    FROM
        SiteRating Join monitor_use_dive_sites_ratings On 
SiteRating.site_id = monitor_use_dive_sites_ratings.site_id
    group by
(monitor_id);

Create View selected_monitors
As
    SELECT monitor_id
    From monitor_ratings Join site_ratings ON
    monitor_ratings.monitor_id = site_ratings.monitor_id;

Select monitor_id, dive_price
FROM selected_monitors Natural Join Price    ;
