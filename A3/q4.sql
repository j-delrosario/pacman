SELECT Site.site_id, max(dive_price) as highest , min(dive_price) as lowest , avg(dive_price) as  average
FROM
    Site JOIN Price On Site.site_id = Price.site_id
GROUP BY Site.site_id;
