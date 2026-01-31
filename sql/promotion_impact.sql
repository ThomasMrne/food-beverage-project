-- ==============================================================================
-- ÉTAPE 8 : ANALYSES BUSINESS TRANSVERSES
-- ==============================================================================

--1️⃣ Ventes et promotions

--Comparaison ventes avec / sans promotion

WITH tx_flag AS (
  SELECT
    f.transaction_id,
    f.transaction_date,
    f.region,
    f.amount,
    IFF(
      EXISTS (
        SELECT 1
        FROM ANYCOMPANY_LAB.SILVER.PROMOTIONS_CLEAN p
        WHERE p.region = f.region
          AND f.transaction_date BETWEEN p.start_date AND p.end_date
      ),
      'WITH_PROMO',
      'WITHOUT_PROMO'
    ) AS promo_flag
  FROM ANYCOMPANY_LAB.SILVER.FINANCIAL_TRANSACTIONS_CLEAN f
)
SELECT
  promo_flag,
  COUNT(*) AS nb_transactions,
  SUM(amount) AS total_sales,
  AVG(amount) AS avg_transaction_amount
FROM tx_flag
GROUP BY promo_flag;


--Sensibilité des catégories aux promotions
SELECT
  product_category,
  COUNT(*) AS nb_promotions,
  AVG(discount_percentage) AS avg_discount,
  MIN(discount_percentage) AS min_discount,
  MAX(discount_percentage) AS max_discount,
  AVG(DATEDIFF('day', start_date, end_date) + 1) AS avg_duration_days
FROM ANYCOMPANY_LAB.SILVER.PROMOTIONS_CLEAN
GROUP BY product_category
ORDER BY nb_promotions DESC;
