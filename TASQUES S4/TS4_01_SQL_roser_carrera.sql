
--Tasca S4.01. BigQuery Avançat & Analytics Engineering

--Nivell 1: Entorn i Ingesta Híbrida (Code-First)

--Exercici 1: Consulta sobre Taula no Optimitzada (Diagnòstic)

SELECT t.*
FROM `sprint3_silver.transactions_clean` AS t
INNER JOIN `sprint3-analytics-rcarrera1.sprint3_silver.companies_clean` AS c
ON t.business_id = c.company_id
WHERE t.declined = 0 AND c.country = 'Germany' AND EXTRACT(DATE FROM t.timestamp) = '2022-03-12';


--Exercici 2: Re-arquitectura i Optimització de l'Emmagatzematge (Partition & Cluster)

--Pas 1: Generació de Dades Recents (Mocking Data) 
CREATE OR REPLACE TABLE `sprint3_silver.transactions_recent` AS
SELECT * EXCEPT (timestamp),
TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL CAST(RAND()*50 AS INT64) DAY) AS timestamp
FROM `sprint3_silver.transactions_clean`;

--Pas 2: Creació de la Taula Optimitzada (Partitioning & Clustering) 
CREATE OR REPLACE TABLE `sprint3_gold.fact_transactions_optimized` 
PARTITION BY DATE(timestamp)
CLUSTER BY business_id
OPTIONS (
  description = "Taula particionada per data i dins de cada partició ordenada per codi empresa"
) AS
SELECT * 
FROM `sprint3_silver.transactions_recent`;

--Exercici 3: La Prova del Cotó (Benchmark)

--» Pas 1 (Taula no optimitzada)
SELECT *
FROM  `sprint3_silver.transactions_recent`
WHERE DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);

--» Pas 2 (Taula optimitzada)
SELECT *
FROM  `sprint3_gold.fact_transactions_optimized`
WHERE DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);

--Exercici 4: Smart Caching (Vistes Materialitzades)
--CREACIÓ DE LA VISTA MATERIALITZADA
CREATE MATERIALIZED VIEW `sprint3_gold.mv_daily_sales`  AS (
  SELECT
    DATE (t.timestamp) AS sale_date,
    SUM(t.amount) AS total_amount,
    COUNT (t.transaction_id) AS total_transactions
  FROM
    `sprint3_gold.fact_transactions_optimized` AS t
  WHERE t.declined = 0
  GROUP BY sale_date);

-- CONSULTA
SELECT sale_date, ROUND(total_amount,2), total_transactions
FROM `sprint3_gold.mv_daily_sales`
ORDER BY sale_date;

--Nivell 2: SQL Analític Avançat

--Exercici 1: Perfilat de Clients VIP (Mètriques Agregades amb CTEs)

WITH VIP_Stats AS(
SELECT 
  t.user_id, 
  ROUND(SUM(t.amount),2) AS total_amount, 
  COUNT(t.transaction_id) AS total_transactions,
  ROUND(AVG(t.amount),2) AS average_amount,
  MAX(t.amount) AS max_amount
FROM `sprint3_gold.fact_transactions_optimized` AS t
WHERE t.declined = 0
GROUP BY t.user_id
HAVING total_amount >500
)
SELECT u.user_id, CONCAT(u.name, ' ', u.surname) AS name, u.email, vs.total_transactions,vs.average_amount, vs.max_amount, vs.total_amount
FROM VIP_Stats AS vs
INNER JOIN `sprint3_silver.users_combined` AS u
ON vs.user_id = u.user_id
ORDER BY vs.total_amount DESC;

--Exercici 2: Anàlisi de Tendències (Window Functions sobre Vistes)

WITH amount_previous_day AS (
  SELECT sale_date, ROUND(LAG(total_amount) OVER (ORDER BY sale_date),2) AS amount
  FROM `sprint3_gold.mv_daily_sales`
)
SELECT 
  ds.sale_date, 
  ROUND(ds.total_amount,2) AS current_day, 
  pd.amount AS previous_day,
  ROUND(((ds.total_amount - pd.amount)/pd.amount)*100,2) AS percentage_diff
FROM `sprint3_gold.mv_daily_sales` AS ds
INNER JOIN amount_previous_day AS pd ON pd.sale_date = ds.sale_date
ORDER BY ds.sale_date;

--Exercici 3: Totals Acumulats (Running Totals sobre Vistes)
SELECT 
  sale_date, 
  ROUND(total_amount,2) AS current_day, 
  ROUND(SUM(total_amount) OVER (
        PARTITION BY EXTRACT(YEAR FROM sale_date) 
        ORDER BY sale_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),2) AS accumulated_amount 
FROM `sprint3_gold.mv_daily_sales`
ORDER BY sale_date;

--Exercici 4: Fidelització i Valor del Client (Filtratge Avançat)

WITH
purchase_rank AS (
  SELECT user_id, DATE(timestamp) as date, amount, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY timestamp) AS num_rank
  FROM `sprint3_gold.fact_transactions_optimized`
  WHERE declined = 0
  QUALIFY num_rank <=3
),
purchase_average AS(
  SELECT user_id, ROUND(AVG(amount),2) AS average
  FROM purchase_rank
  GROUP BY user_id
)
SELECT u.user_id, CONCAT(u.name, ' ', u.surname) AS name, u.email, pr.date AS date3rd, pr.amount AS amount3rd, pa.average
FROM purchase_rank AS pr
INNER JOIN `sprint3_silver.users_combined` AS u USING (user_id)
INNER JOIN purchase_average AS pa USING (user_id)
WHERE pr.num_rank = 3
ORDER BY pa.average DESC;

-- Nivell 3: Analytics Engineering (Arrays & Automatització)
--Exercici 1: Desanidament i Aplanament de Dades (Unnesting)
CREATE OR REPLACE TABLE `sprint3_gold.dim_transactions_flat` AS
SELECT  
  t.transaction_id, 
  t.timestamp, 
  t.amount AS total_ticket, 
  p.product_id AS product_sku, 
  p.name AS product_name, 
  p.price AS product_price
FROM `sprint3_gold.fact_transactions_optimized` AS t
CROSS JOIN UNNEST(t.product_ids) AS product_id
INNER JOIN`sprint3_silver.products_clean` as p ON product_id = p.product_id
WHERE t.declined = 0
ORDER BY t.transaction_id;

--Exercici 2: El Rànquing de Vendes (Agregació Simple)
SELECT product_name, COUNT (*) AS Quantity
FROM `sprint3_gold.dim_transactions_flat`
GROUP BY product_name
ORDER BY Quantity DESC LIMIT 5;

--Exercici 3: Automatització del Pipeline i Visualització
--» 1. User Defined Functions (UDF)
CREATE OR REPLACE FUNCTION `sprint3_gold.calculate_tax`(amount FLOAT64, tax FLOAT64)
RETURNS FLOAT64
AS (
  ROUND (amount + (amount * tax)/100 ,2)
);

--» 2. Integració i Orquestració:
CREATE OR REPLACE TABLE `sprint3_gold.dim_transactions_flat` AS
SELECT  
  t.transaction_id, 
  t.timestamp, 
  t.amount AS total_ticket, 
  p.product_id AS product_sku, 
  p.name AS product_name, 
  p.price AS product_price,
  `sprint3_gold.calculate_tax`(p.price, 21) AS product_price_tax_inc
FROM `sprint3_gold.fact_transactions_optimized` AS t
CROSS JOIN UNNEST(t.product_ids) AS product_id
INNER JOIN`sprint3_silver.products_clean` as p ON product_id = p.product_id
WHERE declined = 0
ORDER BY t.transaction_id;


--» 3. Visualització (BI): Connecta Looker Studio a la teva taula dim_transactions_flat i crea un Dashboard: "Monitor de Rendiment de Vendes"







