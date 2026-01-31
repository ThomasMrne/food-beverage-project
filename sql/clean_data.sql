-- ==============================================================================
-- ÉTAPE 5 : NETTOYAGE DES DONNÉES
-- PASSAGE DU SCHÉMA BRONZE AU SCHÉMA SILVER
-- OBJECTIF : Garantir l'intégrité, la cohérence et la qualité des données.
-- ==============================================================================

USE DATABASE ANYCOMPANY_LAB;
USE SCHEMA SILVER;


-- 1. ANALYSE CLIENTS : CUSTOMER_DEMOGRAPHICS_CLEAN
-- Dédoublonnage par ID client pour éviter de fausser les stats sur le panier moyen et les segments de revenus.
 
CREATE OR REPLACE TABLE SILVER.CUSTOMER_DEMOGRAPHICS_CLEAN AS
SELECT DISTINCT
    customer_id,
    UPPER(name) AS name, -- Harmonisation en majuscules
    date_of_birth,
    gender,
    region,
    country,
    city,
    annual_income
FROM ANYCOMPANY_LAB.BRONZE.CUSTOMER_DEMOGRAPHICS
WHERE customer_id IS NOT NULL;


-- 2. ANALYSE FINANCIÈRE : FINANCIAL_TRANSACTIONS_CLEAN
-- Application de la règle de valeur absolue sur les montants.
-- Suppression des transactions sans montant (donnée inexploitable).

CREATE OR REPLACE TABLE SILVER.FINANCIAL_TRANSACTIONS_CLEAN AS
SELECT 
    transaction_id,
    transaction_date,
    UPPER(transaction_type) AS transaction_type,
    ABS(amount) AS amount, -- Règle de qualité : Valeurs positives
    payment_method,
    region
FROM ANYCOMPANY_LAB.BRONZE.FINANCIAL_TRANSACTIONS
WHERE transaction_id IS NOT NULL 
  AND amount IS NOT NULL;
  

-- 3. ANALYSE PRODUITS : PRODUCT_REVIEWS_CLEAN
CREATE OR REPLACE TABLE ANYCOMPANY_LAB.SILVER.PRODUCT_REVIEWS_CLEAN AS
WITH parsed AS (
  SELECT
    TRY_TO_NUMBER(SPLIT_PART($1, '\t', 1))                 AS review_id,
    NULLIF(SPLIT_PART($1, '\t', 2), '')                    AS product_id,
    NULLIF(SPLIT_PART($1, '\t', 3), '')                    AS reviewer_id,
    NULLIF(SPLIT_PART($1, '\t', 4), '')                    AS reviewer_name,
    TRY_TO_NUMBER(SPLIT_PART($1, '\t', 7))                 AS rating,
    TO_DATE(TRY_TO_TIMESTAMP_NTZ(SPLIT_PART($1, '\t', 8)))  AS review_date,
    NULLIF(SPLIT_PART($1, '\t', 9), '')                    AS review_title,
    NULLIF(SPLIT_PART($1, '\t',10), '')                    AS review_text,
    NULLIF(TRIM(SPLIT_PART($1, '\t',11)), '')              AS product_category
  FROM ANYCOMPANY_LAB.BRONZE.PRODUCT_REVIEWS_RAW
  WHERE TRY_TO_NUMBER(SPLIT_PART($1, '\t', 1)) IS NOT NULL
),
dedup AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY review_id
      ORDER BY
        IFF(product_category IS NOT NULL, 1, 0) DESC,
        LENGTH(COALESCE(review_text, '')) DESC,
        review_date DESC
    ) AS rn
  FROM parsed
  WHERE rating BETWEEN 1 AND 5
)
SELECT
  review_id,
  product_id,
  reviewer_id,
  reviewer_name,
  rating,
  review_date,
  review_title,
  review_text,
  product_category
FROM dedup
WHERE rn = 1;


-- 4. ANALYSE MARKETING : PROMOTIONS_CLEAN & CAMPAIGNS_CLEAN
-- On s'assure de la cohérence temporelle (fin > début).

CREATE OR REPLACE TABLE SILVER.PROMOTIONS_CLEAN AS
SELECT 
    promotion_id,
    product_category,
    promotion_type,
    discount_percentage,
    start_date,
    end_date,
    region
FROM ANYCOMPANY_LAB.BRONZE.PROMOTIONS_DATA
WHERE start_date <= end_date; -- Règle d'intégrité temporelle

CREATE OR REPLACE TABLE ANYCOMPANY_LAB.SILVER.MARKETING_CAMPAIGNS_CLEAN AS
SELECT *
FROM (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY campaign_id
           ORDER BY start_date DESC
         ) AS rn
  FROM ANYCOMPANY_LAB.BRONZE.MARKETING_CAMPAIGNS
)
WHERE rn = 1;

-- 5. ANALYSE LOGISTIQUE : INVENTORY_CLEAN & LOGISTICS_CLEAN
-- Correction des stocks négatifs et calculs de délais.

CREATE OR REPLACE TABLE SILVER.INVENTORY_CLEAN AS
SELECT 
    product_id,
    product_category,
    warehouse,
    GREATEST(current_stock, 0) AS current_stock, -- Correction des stocks négatifs
    reorder_point,
    last_restock_date
FROM ANYCOMPANY_LAB.BRONZE.INVENTORY;

CREATE OR REPLACE TABLE ANYCOMPANY_LAB.SILVER.LOGISTICS_AND_SHIPPING_CLEAN AS
SELECT *
FROM (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY shipment_id
           ORDER BY ship_date DESC
         ) AS rn
  FROM ANYCOMPANY_LAB.BRONZE.LOGISTICS_AND_SHIPPING
)
WHERE rn = 1;


-- 6. ANALYSE RH ET FOURNISSEURS : EMPLOYEE_CLEAN & SUPPLIER_CLEAN

--Une étape de déduplication a été appliquée afin de garantir une granularité 1 ligne = 1 employé.
CREATE OR REPLACE TABLE ANYCOMPANY_LAB.SILVER.EMPLOYEE_RECORDS_CLEAN AS
SELECT
  employee_id,
  name,
  hire_date,
  department,
  salary,
  email
FROM (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY employee_id
           ORDER BY hire_date DESC
         ) AS rn
  FROM ANYCOMPANY_LAB.BRONZE.EMPLOYEE_RECORDS
)
WHERE rn = 1;

CREATE OR REPLACE TABLE ANYCOMPANY_LAB.SILVER.SUPPLIER_INFORMATION_CLEAN AS
SELECT *
FROM (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY supplier_id
           ORDER BY reliability_score DESC
         ) AS rn
  FROM ANYCOMPANY_LAB.BRONZE.SUPPLIER_INFORMATION
)
WHERE rn = 1;

-- 7. SERVICE CLIENT : INTERACTIONS_CLEAN
--L’analyse de qualité a mis en évidence 3 identifiants d’interaction dupliqués.Ces doublons correspondent à des lignes strictement identiques.Une étape de déduplication a été appliquée en conservant une seule occurrence par INTERACTION_ID afin de garantir l’unicité de la clé primaire.

CREATE OR REPLACE TABLE ANYCOMPANY_LAB.SILVER.CUSTOMER_SERVICE_INTERACTIONS_CLEAN AS
SELECT
  interaction_id,
  interaction_date,
  interaction_type,
  issue_category,
  customer_satisfaction
FROM (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY interaction_id
           ORDER BY interaction_date
         ) AS rn
  FROM ANYCOMPANY_LAB.BRONZE.CUSTOMER_SERVICE_INTERACTIONS
)
WHERE rn = 1;


-- 8. SERVICE CLIENT : INTERACTIONS_CLEAN
-- Harmonisation géographique et sécurisation des métriques.On s'assure que les surfaces et les effectifs sont des valeurs physiques cohérentes

CREATE OR REPLACE TABLE SILVER.STORE_LOCATIONS_CLEAN AS
SELECT 
    store_id,
    TRIM(store_name) AS store_name, -- Suppression des espaces parasites
    UPPER(store_type) AS store_type, -- Standardisation du type de magasin
    region,
    UPPER(country) AS country, -- Harmonisation pour les jointures internationales
    UPPER(city) AS city,       -- Harmonisation pour les analyses locales
    address,
    postal_code,
    ABS(square_footage) AS square_footage, 
    GREATEST(employee_count, 0) AS employee_count 
FROM ANYCOMPANY_LAB.BRONZE.STORE_LOCATIONS
WHERE store_id IS NOT NULL;
