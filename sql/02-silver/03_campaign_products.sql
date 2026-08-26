CREATE OR REPLACE TABLE campaign_products AS
SELECT
    c.campaign_id,
    p.product_code,
    p.discount_pct
FROM campaigns,
UNNEST(campaigns) AS t(c),
UNNEST(c.products) AS u(p);
