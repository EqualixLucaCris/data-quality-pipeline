CREATE OR REPLACE TABLE campaign_countries AS
SELECT
    c.campaign_id,
    country
FROM campaigns,
UNNEST(campaigns) AS t(c),
UNNEST(c.countries) AS u(country);
