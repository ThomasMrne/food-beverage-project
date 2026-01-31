-- ==============================================================================
-- ÉTAPE 1 : PRÉPARATION DE L'ENVIRONNEMENT
-- ==============================================================================

--Création de la base de données 
CREATE DATABASE IF NOT EXISTS ANYCOMPANY_LAB;
USE DATABASE ANYCOMPANY_LAB;

--Création des schémas pour séparer les niveaux de maturité de la donnée
CREATE SCHEMA IF NOT EXISTS BRONZE; --données brutes
CREATE SCHEMA IF NOT EXISTS SILVER; --données nettoyées, prêtes pour l'analyse.

--Configuration du Warehouse
CREATE WAREHOUSE IF NOT EXISTS ANYCOMPANY_WH 
WITH 
    WAREHOUSE_SIZE = 'XSMALL' --taille XSMALL pour optimiser les coûts (crédits Snowflake)
    AUTO_SUSPEND = 60         --permet d'arrêter les frais après 1 min d'inactivité
    AUTO_RESUME = TRUE 
    INITIALLY_SUSPENDED = TRUE;

USE WAREHOUSE ANYCOMPANY_WH;

-- ==============================================================================
-- ÉTAPE 2 : CONFIGURATION DES ACCÈS AUX DONNÉES (INGESTION)
-- ==============================================================================

--Création du stage vers le Datalake Amazon S3
CREATE OR REPLACE STAGE BRONZE.S3_STAGE
    URL = 's3://logbrain-datalake/datasets/food-beverage/';

    show integrations;


-- Définition des formats de fichiers pour l'ingestion 
CREATE OR REPLACE FILE FORMAT BRONZE.CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"' -- Gère nativement les guillemets doublés ""
    TRIM_SPACE = TRUE
    NULL_IF = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

-- Spécifique aux product_reviews
CREATE OR REPLACE FILE FORMAT ANYCOMPANY_LAB.BRONZE.CSV_FORMAT_REVIEWS_OK
  TYPE = CSV
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  TRIM_SPACE = TRUE
  NULL_IF = ('NULL','null','')
  EMPTY_FIELD_AS_NULL = TRUE
  ESCAPE_UNENCLOSED_FIELD = NONE
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;


CREATE OR REPLACE FILE FORMAT BRONZE.JSON_FORMAT
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = TRUE; -- Permet de lire les objets JSON dans une liste

-- ==============================================================================
-- ÉTAPE 3 : CRÉATION DES TABLES BRONZE ET CHARGEMENT
-- ==============================================================================

USE SCHEMA BRONZE;

-- 3.1. Création des structures (DDL)
USE SCHEMA ANYCOMPANY_LAB.BRONZE;

-- 1. Données démographiques clients
CREATE OR REPLACE TABLE CUSTOMER_DEMOGRAPHICS (
    customer_id INT,
    name STRING,
    date_of_birth DATE,
    gender STRING,
    region STRING,
    country STRING,
    city STRING,
    marital_status STRING,
    annual_income INT
);

-- 2. Interactions service client
CREATE OR REPLACE TABLE CUSTOMER_SERVICE_INTERACTIONS (
    interaction_id STRING,
    interaction_date DATE,
    interaction_type STRING,
    issue_category STRING,
    description STRING,
    duration_minutes INT,
    resolution_status STRING,
    follow_up_required STRING,
    customer_satisfaction INT
);

-- 3. Transactions financières (Ventes)
CREATE OR REPLACE TABLE FINANCIAL_TRANSACTIONS (
    transaction_id STRING,
    transaction_date DATE,
    transaction_type STRING,
    amount FLOAT,
    payment_method STRING,
    entity STRING,
    region STRING,
    account_code STRING
);

-- 4. Données de promotions
CREATE OR REPLACE TABLE PROMOTIONS_DATA (
    promotion_id STRING,
    product_category STRING,
    promotion_type STRING,
    discount_percentage FLOAT,
    start_date DATE,
    end_date DATE,
    region STRING
);

-- 5. Campagnes Marketing
CREATE OR REPLACE TABLE MARKETING_CAMPAIGNS (
    campaign_id STRING,
    campaign_name STRING,
    campaign_type STRING,
    product_category STRING,
    target_audience STRING,
    start_date DATE,
    end_date DATE,
    region STRING,
    budget FLOAT,
    reach INT,
    conversion_rate FLOAT
);

-- 6. Avis produits 
CREATE OR REPLACE TABLE BRONZE.PRODUCT_REVIEWS_RAW (
    RAW_DATA STRING
);

-- 7. Niveaux de stock (Fichier JSON)
CREATE OR REPLACE TABLE INVENTORY (
    product_id STRING,
    product_category STRING,
    region STRING,
    country STRING,
    warehouse STRING,
    current_stock INT,
    reorder_point INT,
    lead_time INT,
    last_restock_date DATE
);

-- 8. Localisation des magasins (Fichier JSON)
CREATE OR REPLACE TABLE STORE_LOCATIONS (
    store_id STRING,
    store_name STRING,
    store_type STRING,
    region STRING,
    country STRING,
    city STRING,
    address STRING,
    postal_code STRING,
    square_footage FLOAT,
    employee_count INT
);

-- 9. Logistique et expédition
CREATE OR REPLACE TABLE LOGISTICS_AND_SHIPPING (
    shipment_id STRING,
    order_id STRING,
    ship_date DATE,
    estimated_delivery DATE,
    shipping_method STRING,
    status STRING,
    shipping_cost FLOAT,
    destination_region STRING,
    destination_country STRING,
    carrier STRING
);

-- 10. Informations fournisseurs
CREATE OR REPLACE TABLE SUPPLIER_INFORMATION (
    supplier_id STRING,
    supplier_name STRING,
    product_category STRING,
    region STRING,
    country STRING,
    city STRING,
    lead_time INT,
    reliability_score FLOAT,
    quality_rating STRING
);

-- 11. Dossiers employés
CREATE OR REPLACE TABLE EMPLOYEE_RECORDS (
    employee_id STRING,
    name STRING,
    date_of_birth DATE,
    hire_date DATE,
    department STRING,
    job_title STRING,
    salary FLOAT,
    region STRING,
    country STRING,
    email STRING
);

-- 3.2. Chargement des données (DML)

-- 3.2.1. CHARGEMENT DES FICHIERS CSV
-- On utilise le format CSV_FORMAT défini précédemment.
-- L'option ON_ERROR = 'CONTINUE' est appliquée pour garantir que le processus ne s'arrête pas en cas de ligne isolée corrompue.

-- Chargement des données démographiques clients
COPY INTO CUSTOMER_DEMOGRAPHICS 
FROM @S3_STAGE/customer_demographics.csv 
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT) 
ON_ERROR = 'CONTINUE'FORCE = TRUE;

-- Chargement des interactions service client
COPY INTO CUSTOMER_SERVICE_INTERACTIONS 
FROM @S3_STAGE/customer_service_interactions.csv 
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT) 
ON_ERROR = 'CONTINUE'FORCE = TRUE;

-- Chargement des transactions financières
COPY INTO FINANCIAL_TRANSACTIONS 
FROM @S3_STAGE/financial_transactions.csv 
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT) 
ON_ERROR = 'CONTINUE'FORCE = TRUE;

-- Chargement des promotions
COPY INTO PROMOTIONS_DATA 
FROM @S3_STAGE/promotions-data.csv 
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT) 
ON_ERROR = 'CONTINUE'FORCE = TRUE;

-- Chargement des campagnes marketing
COPY INTO MARKETING_CAMPAIGNS 
FROM @S3_STAGE/marketing_campaigns.csv 
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT) 
ON_ERROR = 'CONTINUE'FORCE = TRUE;

-- Chargement des avis produits 
COPY INTO BRONZE.PRODUCT_REVIEWS_RAW
FROM @ANYCOMPANY_LAB.BRONZE.S3_STAGE/product_reviews.csv
FILE_FORMAT = (
    TYPE = 'CSV'
    FIELD_DELIMITER = 'NONE' 
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
)
FORCE = TRUE;

-- Chargement de la logistique
COPY INTO LOGISTICS_AND_SHIPPING 
FROM @S3_STAGE/logistics_and_shipping.csv 
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT) 
ON_ERROR = 'CONTINUE'FORCE = TRUE;

-- Chargement des fournisseurs
COPY INTO SUPPLIER_INFORMATION 
FROM @S3_STAGE/supplier_information.csv 
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT) 
ON_ERROR = 'CONTINUE'FORCE = TRUE;

-- Chargement des employés
COPY INTO EMPLOYEE_RECORDS 
FROM @S3_STAGE/employee_records.csv 
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT) 
ON_ERROR = 'CONTINUE'FORCE = TRUE;


-- 3.2.2. CHARGEMENT DES FICHIERS JSON
-- Utilisation de FORCE = TRUE pour garantir le rechargement complet même si les fichiers ont déjà été vus par Snowflake.

-- Chargement des inventaires
COPY INTO INVENTORY 
FROM (
    SELECT 
        $1:product_id::STRING,
        $1:product_category::STRING,
        $1:region::STRING,
        $1:country::STRING,
        $1:warehouse::STRING,
        $1:current_stock::INT,
        $1:reorder_point::INT,
        $1:lead_time::INT,
        $1:last_restock_date::DATE 
    FROM @S3_STAGE/inventory.json
) 
FILE_FORMAT = (FORMAT_NAME = JSON_FORMAT) 
ON_ERROR = 'CONTINUE'FORCE = TRUE;

-- Chargement des localisations magasins
COPY INTO STORE_LOCATIONS 
FROM (
    SELECT 
        $1:store_id::STRING,
        $1:store_name::STRING,
        $1:store_type::STRING,
        $1:region::STRING,
        $1:country::STRING,
        $1:city::STRING,
        $1:address::STRING,
        $1:postal_code::STRING,
        $1:square_footage::FLOAT,
        $1:employee_count::INT 
    FROM @S3_STAGE/store_locations.json
) 
FILE_FORMAT = (FORMAT_NAME = JSON_FORMAT) 
ON_ERROR = 'CONTINUE'FORCE = TRUE;