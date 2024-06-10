CREATE DATABASE operating_businesses;
USE operating_businesses;

-- CREATE STAGING TABLE FOR DATA CLEANING
SELECT *
FROM businesses_staging;

CREATE TABLE businesses_staging
LIKE businesses;

-- INSERT businesses_staging
-- SELECT * 
-- FROM businesses;

-- CHECK FOR DUPLICATES
SELECT `DCA License Number`, COUNT(*) AS count_of_duplicates
FROM businesses_staging
GROUP BY `DCA License Number`
HAVING COUNT(*) > 1;
-- No duplicates to remove

-- STANDARDIZE DATA    
	-- Trimming(None required)    
SELECT *
FROM businesses_staging
WHERE `Business Name` != TRIM(`Business Name`);

	-- Capitalization 
SELECT `Business Name`, UPPER(`Business Name`)
FROM businesses_staging;

UPDATE businesses_staging 
SET `Business Name` = UPPER(`Business Name`);

UPDATE businesses_staging 
SET `Business Name 2` = UPPER(`Business Name 2`);

UPDATE businesses_staging 
SET `Address City` = UPPER(`Address City`);

	-- Format Phone Number
    
SELECT 
	`Contact Phone Number`, 
CONCAT(
	SUBSTR(`Contact Phone Number`, 1,3), '-', 
    SUBSTR(`Contact Phone Number`, 4,3), '-', 
    SUBSTR(`Contact Phone Number`, 7,4)
)
FROM businesses_staging
WHERE `Contact Phone Number` NOT LIKE '%-%' AND `Contact Phone Number` != '';

UPDATE businesses_staging
SET `Contact Phone Number` = CONCAT(
	SUBSTR(`Contact Phone Number`, 1,3), '-', 
    SUBSTR(`Contact Phone Number`, 4,3), '-', 
    SUBSTR(`Contact Phone Number`, 7,4)
)
WHERE `Contact Phone Number` NOT LIKE '%-%' AND `Contact Phone Number` != '';

	-- Data Type Conversion(Dates) 
SELECT `License Expiration Date`, STR_TO_DATE(`License Expiration Date`, '%m/%d/%Y')
FROM businesses_staging;

UPDATE businesses_staging
SET `License Expiration Date` = STR_TO_DATE(`License Expiration Date`, '%m/%d/%Y');

SELECT `License Creation Date`, STR_TO_DATE(`License Creation Date`, '%m/%d/%Y')
FROM businesses_staging;

UPDATE businesses_staging
SET `License Creation Date` = STR_TO_DATE(`License Creation Date`, '%m/%d/%Y');

-- NULLS AND BLANKS

SELECT `Address Borough`, `Borough Code`
FROM businesses_staging
WHERE `Borough Code` = '' AND `Address Borough` != '';
-- No missing borough codes 
-- No blanks can be filled using known data from dataset

-- SPELL CHECK
SELECT DISTINCT(`Address City`), `Address State`
FROM businesses_staging
ORDER BY `Address City`;

-- Hts, long is city, massapeaqua, pk, vlg, newyork, ny, whit plains
SELECT `Address City`
FROM businesses_staging
WHERE `Address City` LIKE '% HTS%';

UPDATE businesses_staging
SET `Address City` = REPLACE(`Address City`, ' HTS', ' HEIGHTS')
WHERE `Address City` LIKE '% HTS%';

SELECT `Address City`
FROM businesses_staging
WHERE `Address City` Like 'LONG IS%';

UPDATE businesses_staging
SET `Address City` = 'LONG ISLAND CITY'
WHERE `Address City` LIKE 'LONG IS%';

SELECT `Address City`
FROM businesses_staging 
WHERE `Address City` = 'MASSAPEAQUA';

UPDATE businesses_staging
SET `Address City` = 'MASSAPEQUA'
WHERE `Address City` = 'MASSAPEAQUA';

SELECT `Address City`
FROM businesses_staging
WHERE `Address City` LIKE '% PK';

UPDATE businesses_staging
SET `Address City` = 'MASSAPEQUA PARK'
WHERE `Address City` LIKE '% PK';

SELECT `Address City`
FROM businesses_staging
WHERE `Address City` LIKE '% VLG';

UPDATE businesses_staging
SET `Address City` = REPLACE(`Address City`, ' VLG', ' VILLAGE')
WHERE `Address City` LIKE '% VLG%';

SELECT `Address City`
FROM businesses_staging
WHERE `Address City` = 'NEWYORK' OR `Address City` = 'NY';

UPDATE businesses_staging
SET `Address City` = 'NEW YORK'
WHERE `Address City` = 'NEWYORK' OR `Address City` = 'NY';

SELECT `Address City`
FROM businesses_staging
WHERE `Address City` = 'WHIT PLAINS';

UPDATE businesses_staging
SET `Address City` = 'WHITE PLAINS'
WHERE `Address City` = 'WHIT PLAINS';
