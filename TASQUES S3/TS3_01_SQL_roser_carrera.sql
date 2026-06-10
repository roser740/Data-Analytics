--NIVELL 1: Entorn i Ingesta Híbrida (Code-First)

--Exercici 1: Arquitectura de Dades (Lògica vs. Física)---------------------------------------------

-- CREACIÓ DEL PROJECTE A TRAVÉS DE CLOUD SHELL
gcloud projects create sprint3-analytics-rcarrera1

-- CREACIÓ DEL DATASET BRONZE A TRAVÉS DE UI

-- CREACIÓ DEL DATASET SILVER A TRAVÉS DE SQL
CREATE SCHEMA `sprint3-analytics-rcarrera1.sprint3_silver`
OPTIONS (
  location = 'eu',
  description = 'sprint3 silver'
);

-- CREACIÓ DEL DATASET GOLD A TRAVLES DE CLOUD SHELL
bq mk --location=EU sprint3_gold


--Exercici 2: Ingesta en Capa Bronze (Connexió DDL)---------------------------------------------------

CREATE OR REPLACE EXTERNAL TABLE `sprint3_bronze.transactions_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv'],
  field_delimiter = ';'
);

CREATE OR REPLACE EXTERNAL TABLE `sprint3_bronze.companies_raw` (
  company_id STRING,
  company_name STRING,
  phone STRING,
  email STRING,
  country STRING,
  website STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
  skip_leading_rows = 1
);

CREATE OR REPLACE EXTERNAL TABLE `sprint3_bronze.american_users_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv']
);

CREATE OR REPLACE EXTERNAL TABLE `sprint3_bronze.european_users_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv']
);

CREATE OR REPLACE EXTERNAL TABLE `sprint3_bronze.credit_cards_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv']
);

--Exercici 3: Càrrega de Dades Locals (Upload) --------------------------------------------------------------
-- CREACIÓ MANUAL DE LA TAULA PRODUCTS_RAW

--Exercici 4: Arquitectura i Rendiment. Materialització de Dades (Assistit per IA)---------------------------

--a) Materialització de Dades (Assistit per IA)
CREATE OR REPLACE TABLE
    'sprint3-analytics-rcarrera1'.'sprint3_bronze'.'transactions-raw_native' AS
SELECT
  id, card_id, business_id, timestamp, amount, declined, product_ids, user_id, lat, longitude 
FROM
  'sprint3-analytics-rcarrera1'.'sprint3_bronze'.'transactions-raw;' 

--b) Auditoria de Costos
SELECT id FROM sprint3_bronze.transactions_raw_native
SELECT id FROM sprint3_bronze.transactions_raw

--c) El perill del LIMIT
SELECT * FROM sprint3_bronze.transactions_raw_native
SELECT * FROM sprint3_bronze.transactions_raw_native LIMIT 10


-- Exercici 5: Adaptació de Sintaxi (Reporting)---------------------------------------------------------------
-- El teu cap vol saber quins van ser els 5 dies amb més ingressos de l'any 2021.

SELECT EXTRACT(DATE FROM t.timestamp) AS day, ROUND(SUM(t.amount),2) AS total
FROM `sprint3-analytics-rcarrera1.sprint3_bronze.transactions_raw_native` AS t
WHERE EXTRACT(YEAR FROM t.timestamp)  = 2021
GROUP BY day
ORDER BY total DESC LIMIT 5;


-- Exercici 6: Consultes Complexes-------------------------------------------------------------------------
-- Necessitem un informe que creui dades.
-- Llista el nom, país i data de les transaccions realitzades per empreses que van fer operacions 
-- entre 100 i 200 euros en alguna d'aquestes dates: 29-04-2015, 20-07-2018 o 13-03-2024.

SELECT c.company_name, c.country, EXTRACT(DATE FROM t.timestamp) AS day
FROM `sprint3_bronze.transactions_raw_native` as t
INNER JOIN `sprint3_bronze.companies_raw`as c ON t.business_id = c.company_id
WHERE (t.amount BETWEEN 100 AND 200) AND (EXTRACT(DATE FROM t.timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13'))
ORDER BY c.company_name;

--Nivell 2: Neteja i Transformació (ELT)

--Exercici 1: Neteja de Productes (Data Quality)------------------------------------------------------------
CREATE OR REPLACE TABLE `sprint3_silver.products_clean` AS
SELECT
  id AS product_id,
  product_name AS name,
  CAST(REPLACE(warehouse_id, 'WH-', '') AS INT64) AS warehouse_id,
  price, colour, weight, category, brand, cost, launch_date
FROM `sprint3_bronze.products_raw`;



--Exercici 2: Creació de Transaccions Netes (Capa Silver)----------------------------------------------------


CREATE OR REPLACE TABLE `sprint3_silver.transactions_clean` AS
SELECT
  id AS transaction_id,
  card_id,
  business_id,
  SAFE_CAST(timestamp AS TIMESTAMP) AS timestamp,
  IFNULL(SAFE_CAST(amount AS FLOAT64), 0.0) AS amount,
  declined,
  ARRAY(
    SELECT SAFE_CAST(p_id AS INT64) 
    FROM UNNEST(SPLIT(product_ids, ',')) AS p_id
  ) AS product_ids,
  user_id,
  IFNULL(SAFE_CAST(lat AS FLOAT64),0.0) AS lat,
  IFNULL(SAFE_CAST(longitude AS FLOAT64),0.0) AS longitude,
FROM `sprint3_bronze.transactions_raw`;


--Exercici 3: Unificació d'Usuaris (UNION)---------------------------------------------------------------------

CREATE OR REPLACE TABLE `sprint3_silver.users_combined` AS
SELECT
  id AS user_id,
  'USA' AS origin,
  name, surname, phone, email, birth_date, country, city, postal_code, address
FROM `sprint3_bronze.american_users_raw`
UNION ALL
SELECT
  id AS user_id,
  'EU' AS origin,
  name, surname, phone, email, birth_date, country, city, postal_code, address
FROM `sprint3_bronze.european_users_raw`;

--Exercici 4: Materialització de Companyies i Targetes de Crèdit----------------------------------------------------
CREATE OR REPLACE TABLE `sprint3_silver.companies_clean` AS
SELECT *
FROM `sprint3_bronze.companies_raw`;

CREATE OR REPLACE TABLE `sprint3_silver.credit_cards_clean` AS
SELECT
  id AS card_id, user_id, iban, pan, pin, cvv, track1, track2, expiring_date
FROM `sprint3_bronze.credit_cards_raw`;


-- NIVELL 3

-- Exercici 1: La Vista de Màrqueting (Lògica de Negoci)
-- Màrqueting necessita segmentar els clients corporatius, però no saben fer JOINs. 
-- La teva tasca és deixar-los la informació preparada.

CREATE OR REPLACE VIEW `sprint3_gold.v_marketing_kpis` AS
  SELECT c.company_name, c.phone, c.country, ROUND(AVG(t.amount),2) AS avg_amount, 
          CASE WHEN AVG(t.amount) > 260 THEN 'Premium' ELSE 'Standard' END AS client_tier
  FROM `sprint3_silver.companies_clean` AS c
  INNER JOIN `sprint3_silver.transactions_clean` AS t ON c.company_id = t.business_id
  GROUP BY c.company_name, c.phone, c.country;


SELECT *
FROM `sprint3_gold.v_marketing_kpis`
ORDER BY client_tier, avg_amount DESC;


--Exercici 2: Rànquing de Productes (La Potència dels Arrays)

CREATE OR REPLACE TABLE `sprint3_gold.product_sales_ranking` AS
WITH product_sales AS (
  SELECT transaction_id, product_id
  FROM `sprint3_silver.transactions_clean`,
  UNNEST(product_ids) AS product_id
)
SELECT p.product_id, p.name, p.price, p.colour, COUNT(ps.transaction_id) AS total_sold
FROM `sprint3_silver.products_clean` as p
LEFT JOIN product_sales as ps ON ps.product_id = p.product_id
GROUP BY p.product_id, p.name, p.price, p.colour;



--Exercici 3: Exportació de Resultats

SELECT *
FROM `sprint3_gold.product_sales_ranking`
ORDER BY total_sold DESC;