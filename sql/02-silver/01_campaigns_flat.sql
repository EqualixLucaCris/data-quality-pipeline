CREATE OR REPLACE TABLE campaigns_flat AS
SELECT
    c.campaign_id,
    c.name,
    c.active,
    exported_at
FROM campaigns,
UNNEST(campaigns) AS t(c);
