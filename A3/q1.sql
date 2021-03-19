SELECT dive_type, count(Price.site_id)
FROM Price
    Join Site on Site.site_id = Price.site_id
WHERE Site.site_id in (select site_id
from BookingPrivilege Join Monitor on Monitor.monitor_id = 
    BookingPrivilege.monitor_id)
group by dive_type; 
