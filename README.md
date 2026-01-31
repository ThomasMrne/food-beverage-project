# 🥗 AnyCompany Food & Beverage - Modern Data Architecture Lab

> **Projet Data Engineering & Analytics avec Snowflake**
> *Transformation de données brutes multi-sources en un Data Product Marketing unifié.*

---

## Contexte du Projet

**AnyCompany Food & Beverage** cherche à piloter sa stratégie marketing par la donnée pour contrer une baisse de parts de marché.
Ce projet met en place un **Data Warehouse complet sur Snowflake** pour :
1.  Centraliser les données dispersées (CSV, JSON, S3).
2.  Assurer la qualité et la cohérence des données (Nettoyage Silver).
3.  Fournir une vue 360° pour le Marketing (Data Product Analytics).

---

## 🏗 Architecture Technique (Medallion)

Le projet suit une architecture en 3 couches :

### 1. 🥉 BRONZE (Raw Ingestion)
* **Source :** Datalake Amazon S3 (`s3://logbrain-datalake`).
* **Volumétrie :** 11 tables ingérées.
* **Technicité :**
    * Gestion des formats **JSON** semi-structurés (`INVENTORY`, `STORE_LOCATIONS`).
    * Parsing manuel complexe pour les fichiers non-standards (`PRODUCT_REVIEWS` via `SPLIT_PART`).
    * Utilisation de `External Stages` et `File Formats`.

### 2. 🥈 SILVER (Quality & Cleansing)
* **Nettoyage :** Déduplication, standardisation (UPPER, TRIM), typage fort.
* **Règles Métier :**
    * Correction des stocks négatifs (`GREATEST(0)`).
    * Validation des dates (Fin > Début).
    * Gestion des doublons sur les clés primaires.
* **Tables Clés :** `FINANCIAL_TRANSACTIONS_CLEAN`, `CUSTOMER_DEMOGRAPHICS_CLEAN`, `MARKETING_CAMPAIGNS_CLEAN`.

### 3. 🥇 ANALYTICS (Data Product)
* **Agrégation :** Création de vues métiers mensuelles (Ventes, Promos, Marketing).
* **Enrichissement :** Segmentation client (`Age Segment`, `Income Segment`).
* **Data Product Final (`MARKETING_DATAPRODUCT`) :**
    * Table unique regroupant Ventes, Marketing et Promotions.
    * **Feature Engineering :** Calcul de la variation mois par mois (`SALES_DELTA_MOM`) et valeurs décalées (`LAG`).

---

## 📂 Structure du Code SQL

* **Étape 1-2 :** Setup Warehouse & Ingestion S3.
* **Étape 3 :** DDL Bronze & Chargement (`COPY INTO`).
* **Étape 4 :** Audit et Vérification des volumes.
* **Étape 5 :** Transformation Silver (Nettoyage SQL).
* **Étape 6-8 :** Analyses exploratoires et transverses (KPIs, ROI Marketing, Logistique).
* **Étape 9 :** Création du schéma Analytics et du `MARKETING_DATAPRODUCT`.

---

## 📊 Aperçu du Data Product

Le produit final **`ANALYTICS.MARKETING_DATAPRODUCT`** est prêt pour la consommation BI/ML :

| Colonne | Description |
| :--- | :--- |
| `MONTH` | Granularité temporelle |
| `REGION` | Granularité géographique |
| `TOTAL_SALES` | Chiffre d'affaires mensuel |
| `AVG_BASKET` | Panier moyen |
| `TOTAL_BUDGET` | Dépenses marketing |
| `SALES_PREV_MONTH` | Ventes du mois M-1 (Lag feature) |
| `SALES_DELTA_MOM` | Croissance vs mois précédent |

---

## 🛠 Comment exécuter ce projet ?

1.  **Prérequis :** Compte Snowflake avec droits `SYSADMIN` ou `ACCOUNTADMIN`.
2.  **Exécution :** Lancer le script SQL complet dans une Worksheet Snowflake.
3.  **Visualisation :** Connecter l'application Streamlit (fournie dans `/streamlit`) pour visualiser les KPIs.

---
*Auteur : Thomas, Linh, Jeff, Irmeline, Milaine
