-- ==============================================================================
-- ÉTAPE 7 : ANALYSES EXPLORATOIRES DESCRIPTIVES
-- ==============================================================================

--1️⃣ Analyse de l’évolution des ventes dans le temps

--Ventes totales par mois
SELECT
  DATE_TRUNC('month', transaction_date) AS month,
  COUNT(*) AS nb_transactions,
  SUM(amount) AS total_sales,
  AVG(amount) AS avg_transaction_amount
FROM ANYCOMPANY_LAB.SILVER.FINANCIAL_TRANSACTIONS_CLEAN
GROUP BY 1
ORDER BY 1;

--Évolution cumulative du chiffre d’affaires
SELECT
  month,
  chiffre_affaires,
  SUM(chiffre_affaires) OVER (ORDER BY month) AS chiffre_affaires_cumule
FROM (
  SELECT
    DATE_TRUNC('month', transaction_date) AS month,
    SUM(amount) AS chiffre_affaires
  FROM ANYCOMPANY_LAB.SILVER.FINANCIAL_TRANSACTIONS_CLEAN
  GROUP BY 1
) t
ORDER BY month;


--Comparaison par trimestre
SELECT
  DATE_TRUNC('quarter', transaction_date) AS quarter,
  SUM(amount) AS total_sales,
  COUNT(*) AS nb_transactions
FROM ANYCOMPANY_LAB.SILVER.FINANCIAL_TRANSACTIONS_CLEAN
GROUP BY 1
ORDER BY 1;


--2️⃣ Performance par produit, catégorie et région

--Performance par catégorie produit (à partir des avis)
SELECT
  product_category,
  COUNT(*) AS nb_reviews,
  AVG(rating) AS avg_rating
FROM ANYCOMPANY_LAB.SILVER.PRODUCT_REVIEWS_CLEAN
GROUP BY product_category
ORDER BY avg_rating DESC;

--Performance des ventes par région
SELECT
  region,
  SUM(amount) AS total_sales,
  COUNT(*) AS nb_transactions,
  AVG(amount) AS avg_transaction
FROM ANYCOMPANY_LAB.SILVER.FINANCIAL_TRANSACTIONS_CLEAN
GROUP BY region
ORDER BY total_sales DESC;
