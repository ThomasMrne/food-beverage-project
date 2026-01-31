-- 2️⃣ Marketing et performance commerciale

--Lien campagnes ↔ ventes
SELECT
  m.campaign_id,
  m.campaign_name,
  m.campaign_type,
  m.start_date,
  m.budget,
  m.reach,
  m.conversion_rate,
  COUNT(f.transaction_id) AS nb_transactions_during_campaign,
  SUM(f.amount) AS total_sales_during_campaign
FROM ANYCOMPANY_LAB.SILVER.MARKETING_CAMPAIGNS_CLEAN m
LEFT JOIN ANYCOMPANY_LAB.SILVER.FINANCIAL_TRANSACTIONS_CLEAN f
  ON f.transaction_date >= m.start_date
GROUP BY
  m.campaign_id,
  m.campaign_name,
  m.campaign_type,
  m.start_date,
  m.budget,
  m.reach,
  m.conversion_rate
ORDER BY total_sales_during_campaign DESC;


--Identification des campagnes les plus efficaces
WITH campaign_sales AS (
  SELECT
    m.campaign_id,
    m.campaign_name,
    m.campaign_type,
    m.start_date,
    m.budget,
    SUM(f.amount) AS total_sales_after_campaign
  FROM ANYCOMPANY_LAB.SILVER.MARKETING_CAMPAIGNS_CLEAN m
  LEFT JOIN ANYCOMPANY_LAB.SILVER.FINANCIAL_TRANSACTIONS_CLEAN f
    ON f.transaction_date >= m.start_date
  GROUP BY
    m.campaign_id,
    m.campaign_name,
    m.campaign_type,
    m.start_date,
    m.budget
)
SELECT
  campaign_id,
  campaign_name,
  campaign_type,
  start_date,
  budget,
  total_sales_after_campaign,
  ROUND(total_sales_after_campaign / NULLIF(budget, 0), 2) AS roi_estimated
FROM campaign_sales
ORDER BY roi_estimated DESC;