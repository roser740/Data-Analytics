
-- TASCA S2 01

-- NIVELL1
-- Exercici 1
-- A partir dels documents adjunts (estructura_dades i dades_introduir), importa les dues taules. 
-- Mostra les característiques principals de l'esquema creat i explica les diferents taules i variables que existeixen. 
-- Assegura't d'incloure un diagrama que il·lustri la relació entre les diferents taules i variables.

    -- Creció de la base de dades
    CREATE DATABASE IF NOT EXISTS transactions;
    USE transactions;

    -- Creació de la taula company
    CREATE TABLE IF NOT EXISTS company (
        id VARCHAR(15) PRIMARY KEY,
        company_name VARCHAR(255),
        phone VARCHAR(15),
        email VARCHAR(100),
        country VARCHAR(100),
        website VARCHAR(255)
    );


    -- Creació de la taula transaction
    CREATE TABLE IF NOT EXISTS transaction (
        id VARCHAR(255) PRIMARY KEY,
        credit_card_id VARCHAR(15) REFERENCES credit_card(id),
        company_id VARCHAR(20), 
        user_id INT REFERENCES user(id),
        lat FLOAT,
        longitude FLOAT,
        timestamp TIMESTAMP,
        amount DECIMAL(10, 2),
        declined BOOLEAN,
        FOREIGN KEY (company_id) REFERENCES company(id) 
    );

    -- CÀRREGA DE DADES:   N1-Ex.1__dades_introduir.sql


-- Exercici 2
-- Utilitzant JOIN realitzaràs les següents consultes:

-- Llistat dels països que estan generant vendes.
    USE transactions;

    SELECT DISTINCT c.country
    FROM company AS c
    INNER JOIN transaction AS t ON c.id = t.company_id
    WHERE t.declined = 0
    ORDER BY c.country;

-- Des de quants països es generen les vendes.
    USE transactions;

    SELECT count(DISTINCT c.country) as number_countries
    FROM company AS c
    INNER JOIN transaction AS t ON c.id = t.company_id
    WHERE t.declined = 0;

-- Identifica la companyia amb la mitjana més gran de vendes.
    USE transactions;

    SELECT c.company_name, round(AVG(t.amount),2) AS average_amount
    FROM company as c
    INNER JOIN transaction as t ON c.id = t.company_id
    WHERE t.declined = 0
    GROUP BY c.company_name
    ORDER BY average_amount DESC
    LIMIT 1;

-- Exercici 3
-- Utilitzant només subconsultes (sense utilitzar JOIN):

-- Mostra totes les transaccions realitzades per empreses d'Alemanya.
USE transactions;

SELECT t.*
FROM transaction AS t 
WHERE EXISTS (
	SELECT c2.id
    FROM company AS c2
    WHERE c2.id = t.company_id AND c2.country = "Germany" AND t.declined = 0);

-- Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions.
USE transactions;

SELECT c.*
FROM company AS c
WHERE EXISTS (
	SELECT t1.id
	FROM transaction AS t1 
	WHERE t1.declined = 0 AND t1.company_id = c.id AND t1.amount > (
		SELECT AVG(t2.amount)
		FROM transaction AS t2
		WHERE t2.declined = 0)
	);


-- Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses.
USE transactions;

SELECT c.company_name 
FROM company as c 
WHERE NOT EXISTS (
	SELECT t.company_id
    FROM transaction as t
    WHERE t.company_id = c.id);


-- Exercici 4
-- La teva tasca és dissenyar i crear una taula anomenada "credit_card" que emmagatzemi detalls crucials sobre 
-- les targetes de crèdit. La nova taula ha de ser capaç d'identificar de manera única cada targeta i establir una 
-- relació adequada amb les altres dues taules ("transaction" i "company"). Després de crear la taula serà necessari que 
-- ingressis la informació del document denominat "dades_introduir_credit". Recorda mostrar el diagrama i realitzar una 
-- breu descripció d'aquest.

    USE transactions;

    -- Creamos la tabla credit_card
    CREATE TABLE IF NOT EXISTS credit_card (
        id VARCHAR(15) PRIMARY KEY,
        iban VARCHAR(50),
        pan VARCHAR(20),
        pin VARCHAR(4),
        cvv VARCHAR(3),
        expiring_date VARCHAR(8)
    );

    -- Carregar dades: N1-Ex.4_datos_introducir_credit.sql

    ALTER TABLE transaction
	ADD FOREIGN KEY (credit_card_id)
	REFERENCES credit_card(id);

-- Exercici 5
-- El departament de Recursos Humans ha identificat un error en el número de compte associat a la targeta de crèdit 
-- amb ID CcU-2938. La informació que ha de mostrar-se per a aquest registre és: TR323456312213576817699999. 
-- Recorda mostrar que el canvi es va realitzar.
 USE transactions;

UPDATE credit_card
SET iban = 'TR323456312213576817699999'
WHERE id = 'CcU-2938';

SELECT *
FROM credit_card
WHERE id = 'CcU-2938'

-- Exercici 6
-- En la taula "transaction" ingressa una nova transacció amb la següent informació:
 USE transactions;
INSERT INTO company (id) VALUES ('b-9999');

INSERT INTO credit_card (id) VALUES ('CcU-9999');

INSERT INTO transaction 
(id, credit_card_id, company_id, user_id, lat, longitude, timestamp, amount, declined) 
VALUES 
('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', '9999', '829.999 ', '-117.999 ', CURRENT_TIMESTAMP(), '111.11 ', '0');

SELECT *
FROM transaction
WHERE id ='108B1D1D-5B23-A76C-55EF-C568E49A99DD';



-- Exercici 7
-- Des de recursos humans et sol·liciten eliminar la columna "pan" de la taula credit_card. Recorda mostrar el canvi 
-- realitzat.
USE transactions;

SELECT * FROM credit_card;

ALTER TABLE credit_card DROP COLUMN pan;

SELECT * FROM credit_card;



-- Exercici 8
-- Descarrega els arxius CSV que trobaràs a l'apartat de recursos:

-- american_users.csv
-- european_users.csv
-- companies.csv
-- credit_cards.csv
-- transactions.csv
-- Estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui, almenys 4 taules de les quals 
-- puguis realitzar les següents consultes:

CREATE DATABASE IF NOT EXISTS vendes;
USE vendes;

CREATE TABLE IF NOT EXISTS users(
	id INT PRIMARY KEY,
    name VARCHAR (255),
    surname VARCHAR (255),
    phone VARCHAR (20),
    email VARCHAR (100),
    birth_date VARCHAR (20),
    country VARCHAR (100),
    city VARCHAR (100),
    postal_code VARCHAR (20),
    address VARCHAR (100),
    signup_date DATE,
    user_segment VARCHAR (20),
    income_band VARCHAR (20)
);

LOAD DATA INFILE 'C:\\dades\\N1_Ex8__american_users.csv' 
INTO TABLE users FIELDS TERMINATED BY ',' ENCLOSED BY '"'  LINES TERMINATED BY '\n'  
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:\\dades\\N1-Ex.8__european_users.csv' 
INTO TABLE users FIELDS TERMINATED BY ',' ENCLOSED BY '"'  LINES TERMINATED BY '\n'  
IGNORE 1 ROWS;

CREATE TABLE IF NOT EXISTS companies (
	company_id VARCHAR (20) PRIMARY KEY,
    company_name VARCHAR (255),
    phone VARCHAR (20),
    email VARCHAR (100),
    country VARCHAR (100),
    website VARCHAR (255),
    merchant_category VARCHAR (20),
    merchant_price_position VARCHAR (20)
);

LOAD DATA INFILE 'C:\\dades\\N1-Ex.8__companies.csv' 
INTO TABLE companies FIELDS TERMINATED BY ',' ENCLOSED BY '"'  LINES TERMINATED BY '\n'  
IGNORE 1 ROWS;

CREATE TABLE IF NOT EXISTS credit_cards (
	id VARCHAR(20) PRIMARY KEY,
    user_id INT REFERENCES users(id),
    iban VARCHAR (50),
    pan VARCHAR(20),
    pin VARCHAR(4),
    cvv VARCHAR(4),
    track1 VARCHAR(100),
    track2 VARCHAR(100),
    expiring_date VARCHAR(8),
    card_type VARCHAR(20),
    card_renewal_flat BOOLEAN
);

LOAD DATA INFILE 'C:\\dades\\N1-Ex.8__credit_cards.csv' 
INTO TABLE credit_cards FIELDS TERMINATED BY ',' ENCLOSED BY '"'  LINES TERMINATED BY '\n'  
IGNORE 1 ROWS;

CREATE TABLE IF NOT EXISTS transactions(
	id VARCHAR(255) PRIMARY KEY,
    card_id VARCHAR(20) REFERENCES credit_cards(id),
    business_id VARCHAR(20) REFERENCES companies(company_id),
    timestamp TIMESTAMP,
    amount DECIMAL(10,2),
    declined BOOLEAN,
    product_ids VARCHAR(50),
    user_id INT REFERENCES users(id),
    lat FLOAT,
    longitude FLOAT,
    discount_amount DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    shipping_amount DECIMAL(10,2),
    channel VARCHAR(20),
    campaign_id VARCHAR(20),
    device_type VARCHAR(20),
    is_international BOOLEAN,
    decline_reason VARCHAR(50),
    distance_km DECIMAL(10,2),
	FOREIGN KEY (card_id) REFERENCES credit_cards(id),
	FOREIGN KEY (business_id) REFERENCES companies(company_id),
	FOREIGN KEY (user_id) REFERENCES users(id) 
);

LOAD DATA INFILE 'C:\\dades\\N1-Ex.8__transactions.csv' 
INTO TABLE transactions FIELDS TERMINATED BY ';' ENCLOSED BY '"'  LINES TERMINATED BY '\n'  
IGNORE 1 ROWS;




-- Exercici 9
-- Realitza una subconsulta que mostri tots els usuaris amb més de 80 transaccions utilitzant almenys 2 taules.
    USE vendes;

    SELECT u.id, u.name, u.surname
    FROM users as u
    WHERE EXISTS (
        SELECT t.user_id 
        FROM transactions AS t
        WHERE t.user_id = u.id AND t.declined = 0
	    GROUP BY t.user_id
        HAVING count(t.id) >80);

-- Exercici 10
-- Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, 
-- utilitza almenys 2 taules.
    USE vendes;

    SELECT cc.iban, ROUND(AVG(t.amount),2) AS average_amount
    FROM transactions as t
    INNER JOIN credit_cards as cc ON t.card_id = cc.id
    INNER JOIN companies as c ON t.business_id = c.company_id
    WHERE t.declined = 0 AND c.company_name = "Donec Ltd"
    GROUP BY cc.iban
    ORDER BY cc.iban;

-- Nivell 2
-- Exercici 1
-- Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes. 
-- Mostra la data de cada transacció juntament amb el total de les vendes.
    USE Vendes;

    SELECT DATE(t.timestamp) AS day, SUM(t.amount) AS total_amount
    FROM transactions AS t
    WHERE t.declined = 0
    GROUP BY day
    ORDER BY total_amount DESC
    LIMIT 5;


-- Exercici 2
-- Presenta el nom, telèfon, país, data i amount, d'aquelles empreses que van realitzar transaccions 
-- amb un valor comprès entre 350 i 400 euros i en alguna d'aquestes dates: 29 d'abril del 2015, 
-- 20 de juliol del 2018 i 13 de març del 2024. Ordena els resultats de major a menor quantitat.
    USE Vendes;

    SELECT c.company_name, c.phone, c.country, DATE(t.timestamp) AS day, t.amount
    FROM transactions AS t
    INNER JOIN companies AS c ON t.business_id = c.company_id
    WHERE (t.declined = 0) AND (t.amount BETWEEN 350 AND 400) AND (DATE(t.timestamp) IN ('2015-04-29','2018-07-20','2024-03-13'))
    ORDER BY t.amount DESC;



-- Exercici 3
-- Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat operativa que es requereixi,
-- per la qual cosa et demanen la informació sobre la quantitat de transaccions que realitzen les empreses, 
-- però el departament de recursos humans és exigent i vol un llistat de les empreses on especifiquis si tenen 
-- igual o més de 400 transaccions o menys.
    USE Vendes;

    SELECT c.company_name, COUNT(t.id) AS num_transactions, 
    IF (COUNT(t.id) >= 400, "Igual o més de 400", "Menys de 400") AS classification
    FROM transactions AS t
    INNER JOIN companies AS c ON t.business_id = c.company_id
    WHERE t.declined = 0
    GROUP BY c.company_name
    ORDER BY c.company_name;


-- Exercici 4
-- Elimina de la taula transaction el registre amb ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de dades.

    USE vendes;

    SELECT * 
    FROM transactions
    WHERE id = "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD";

    DELETE FROM transactions

-- Exercici 5
-- La secció de màrqueting desitja tenir accés a informació específica per a realitzar anàlisi i 
-- estratègies efectives. S'ha sol·licitat crear una vista que proporcioni detalls clau sobre les companyies 
-- i les seves transaccions. Serà necessària que creïs una vista anomenada VistaMarketing que contingui la 
-- següent informació: Nom de la companyia. Telèfon de contacte. País de residència. Mitjana de compra realitzat 
-- per cada companyia. Presenta la vista creada, ordenant les dades de major a menor mitjana de compra.

	USE Vendes;

    CREATE VIEW VistaMarketing AS
	    SELECT c.company_name, c.phone, c.country, round(AVG(t.amount),2) AS average_amount
        FROM transactions AS t
        INNER JOIN companies AS c ON t.business_id = c.company_id
        WHERE t.declined = 0
        GROUP BY c.company_name, c.phone, c.country
        ORDER BY average_amount DESC;
    
    SELECT * FROM vendes.vistamarketing;  

-- Nivell 3
-- Exercici 1
-- Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les tres 
-- últimes transaccions han estat declinades aleshores és inactiu, si almenys una no és rebutjada 
-- leshores és actiu. Partint d’aquesta taula respon:
-- 👉 Quantes targetes estan actives?

USE vendes;

CREATE TABLE credit_card_status (
    card_id VARCHAR(20) PRIMARY KEY,
    active BOOLEAN,
    FOREIGN KEY (card_id) REFERENCES credit_cards(id) ON DELETE CASCADE
);

INSERT INTO credit_card_status (card_id, active)
WITH 
transactions_1 AS (
    SELECT card_id, declined, ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS num_rank
    FROM transactions),
transactions_2 AS (
    SELECT card_id, declined
    FROM transactions_1
    WHERE num_rank <= 3)
SELECT card_id, IF(SUM(declined) = 3, 0, 1) AS active
FROM transactions_2
GROUP BY card_id;


SELECT count(card_id) AS number_active_cards
FROM credit_card_status
WHERE active = 1;


-- Exercici 2
-- Crea una taula amb la qual puguem unir les dades de l'arxiu de products.csv amb la base de dades 
-- creada (ja que fins ara no podíem fer-ho), tenint en compte que des de transaction tens product_ids. 
-- Genera la següent consulta:
-- 👉 Necessitem conèixer el nombre de vegades que s'ha venut cada producte.
USE vendes;

CREATE TABLE IF NOT EXISTS products(
	id INT PRIMARY KEY,
    product_name VARCHAR(100),
    price DECIMAL (10,2),
    colour VARCHAR(20),
    weight DECIMAL (5,2),
    warehouse_id VARCHAR(20),
    category VARCHAR(20),
    brand VARCHAR(20),
    cost DECIMAL (10,2),
    launch_date DATE
);



LOAD DATA INFILE 'C:\\dades\\N1-Ex.8__products.csv' 
INTO TABLE products FIELDS TERMINATED BY ',' ENCLOSED BY '"'  LINES TERMINATED BY '\n'  
IGNORE 1 ROWS
(id, product_name, @temp_price, colour, weight, warehouse_id, category, brand, @temp_cost, launch_date)
SET 
	price = REPLACE (@temp_price, '$', ''),
	cost = REPLACE (@temp_cost, '$', '');


CREATE TABLE IF NOT EXISTS transaction_products (
    id_transaction VARCHAR(255),
    id_product INT,
    PRIMARY KEY (id_transaction, id_product),
    FOREIGN KEY (id_transaction) REFERENCES transactions(id) ON DELETE CASCADE,
    FOREIGN KEY (id_product) REFERENCES products(id) ON DELETE CASCADE
);



INSERT INTO transaction_products (id_transaction, id_product)
SELECT t.id, p.product_id
FROM transactions AS t
CROSS JOIN JSON_TABLE(
    CONCAT('["', REPLACE(t.product_ids, ',', '","'), '"]'),
    "$[*]" COLUMNS (product_id INT PATH "$")
) AS p;


SELECT * FROM transaction_products
ORDER BY id_transaction;

SELECT p.id, p.product_name, COUNT(tp.id_transaction) as num_sales
FROM products AS p
INNER JOIN transaction_products AS tp ON p.id = tp.id_product
INNER JOIN transactions AS t ON tp.id_transaction = t.id
WHERE t.declined = 0
GROUP BY p.id, p.product_name;