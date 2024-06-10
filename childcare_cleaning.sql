CREATE DATABASE childcare_center_inspections;
USE childcare_center_inspections;

SELECT *
FROM childcare_center_inspections;

CREATE TABLE childcare_staging
LIKE childcare_center_inspections;

-- INSERT childcare_staging
-- SELECT *
-- FROM childcare_center_inspections;

SELECT *
FROM childcare_staging;

-- Check for duplicates
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY `Center Name`, `Legal Name`, `Building`, `Street`, `Borough`, `ZipCode`, `Phone`, `Permit Number`, 
								`Permit Expiration`, `Status`, `Age Range`,`Maximum Capacity`, `Day Care ID`, `Program Type`, 
                                `Facility Type`, `Child Care Type`, `Building Identification Number`, `URL`, `Date Permitted`,
								`Actual`, `Violation Rate Percent`, `Average Violation Rate Percent`, `Total Educational Workers`, 
								`Average Total Educational Workers`, `Public Health Hazard Violation Rate`, `Average Public Health Hazard Violation Rate`,
								`Critical Violation Rate`, `Average Critical Violation Rate`, `Inspection Date`, `Regulation Summary`, `Violation Category`,
								`Health Code Sub Section`, `Violation Status`, `Inspection Summary Result`) AS row_num
FROM childcare_staging
)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

SELECT * 
FROM childcare_staging 
WHERE `Center Name` = '1332 FULTON  DAY CARE CENTER' AND `Regulation Summary` LIKE 'Fingerprint screening%';

-- REMOVE DUPLICATES
-- Create a 2nd staging table to delete duplicates
 CREATE TABLE `childcare_staging2` (
  `Center Name` text,
  `Legal Name` text,
  `Building` text,
  `Street` text,
  `Borough` text,
  `ZipCode` int DEFAULT NULL,
  `Phone` text,
  `Permit Number` text,
  `Permit Expiration` text,
  `Status` text,
  `Age Range` text,
  `Maximum Capacity` int DEFAULT NULL,
  `Day Care ID` text,
  `Program Type` text,
  `Facility Type` text,
  `Child Care Type` text,
  `Building Identification Number` int DEFAULT NULL,
  `URL` text,
  `Date Permitted` text,
  `Actual` text,
  `Violation Rate Percent` text,
  `Average Violation Rate Percent` text,
  `Total Educational Workers` int DEFAULT NULL,
  `Average Total Educational Workers` double DEFAULT NULL,
  `Public Health Hazard Violation Rate` text,
  `Average Public Health Hazard Violation Rate` text,
  `Critical Violation Rate` text,
  `Average Critical Violation Rate` text,
  `Inspection Date` text,
  `Regulation Summary` text,
  `Violation Category` text,
  `Health Code Sub Section` text,
  `Violation Status` text,
  `Inspection Summary Result` text,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO childcare_staging2
SELECT *,
ROW_NUMBER() OVER(PARTITION BY `Center Name`, `Legal Name`, `Building`, `Street`, `Borough`, `ZipCode`, `Phone`, `Permit Number`, 
								`Permit Expiration`, `Status`, `Age Range`,`Maximum Capacity`, `Day Care ID`, `Program Type`, 
                                `Facility Type`, `Child Care Type`, `Building Identification Number`, `URL`, `Date Permitted`,
								`Actual`, `Violation Rate Percent`, `Average Violation Rate Percent`, `Total Educational Workers`, 
								`Average Total Educational Workers`, `Public Health Hazard Violation Rate`, `Average Public Health Hazard Violation Rate`,
								`Critical Violation Rate`, `Average Critical Violation Rate`, `Inspection Date`, `Regulation Summary`, `Violation Category`,
								`Health Code Sub Section`, `Violation Status`, `Inspection Summary Result`) AS row_num
FROM childcare_staging;

SELECT * 
FROM childcare_staging2;

DELETE
FROM childcare_staging2
WHERE row_num > 1;

-- STANDARDIZE DATA

-- String to Date
SELECT `Permit Expiration`, `Date Permitted`, `Inspection Date`,
		STR_TO_DATE(`Permit Expiration`, '%m/%d/%Y'),
        STR_TO_DATE(`Date Permitted`, '%m/%d/%Y'),
        STR_TO_DATE(`Inspection Date`, '%m/%d/%Y')
FROM childcare_staging2;

UPDATE childcare_staging2
SET `Permit Expiration` = STR_TO_DATE(`Permit Expiration`, '%m/%d/%Y');

UPDATE childcare_staging2
SET `Date Permitted` = STR_TO_DATE(`Date Permitted`, "%m/%d/%Y")
WHERE `Date Permitted` != '';

UPDATE childcare_staging2
SET `Inspection Date` = STR_TO_DATE(`Inspection Date`, "%m/%d/%Y")
WHERE `Inspection Date` != '';


SELECT *
FROM childcare_staging2;

-- Checking for differences in 'Legal Name' and 'Center Name' with same Address
SELECT 
    `Legal Name`, 
    `Center Name`, 
    Address
FROM (
    SELECT 
        `Legal Name`, 
        `Center Name`, 
        CONCAT(`Building`, ' ', `Street`, ' ', `Borough`) AS Address,
        ROW_NUMBER() OVER (PARTITION BY CONCAT(`Building`, ' ', `Street`, ' ', `Borough`) ORDER BY `Legal Name`) AS row_num
    FROM childcare_staging2
) AS T
WHERE T.row_num = 1
AND Address IN (
    SELECT Address
    FROM (
        SELECT CONCAT(`Building`, ' ', `Street`, ' ', `Borough`) AS Address
        FROM childcare_staging2
        GROUP BY Address
        HAVING COUNT(*) = 1
    ) AS DuplicateAddresses
)
ORDER BY `Address`;

-- Fixing Center names
-- Asian american coalition for education, teachers college address, children's house montessori
-- CHANGED HAVING = 1 620 W 42 street

SELECT *
FROM childcare_staging2 
WHERE `Center Name` = 'VIVVI 6, LLC.';

UPDATE childcare_staging2
SET `Building` = '620',
    `Street` = 'WEST 42 STREET'
WHERE `Building` = '620 W' AND `Street` = '42 STREET';

SELECT `Street`,
REPLACE(`Street`, 'CF2', '')
FROM childcare_staging2 
WHERE `Legal Name` LIKE "CHILDREN'S HOUSE%" AND `Street` LIKE '%CF2';

UPDATE childcare_staging2
SET `Street` = REPLACE(`Street`, 'CF2', '')
WHERE `Legal Name` LIKE "CHILDREN'S HOUSE%" AND `Street` LIKE '%CF2';

SELECT `Legal Name`, 
REPLACE(`Legal Name`, ', COLUMBIA UNIVERSITY', ''),
`Center Name`, 
REPLACE(`Center Name`, ', COLUMBIA UNIVERSITY', '')
FROM childcare_staging2
WHERE `Legal Name` LIKE 'TEACHER%' OR `Center Name` LIKE 'TEACHER%';

UPDATE childcare_staging2
SET `Legal Name` = REPLACE(`Legal Name`, ', COLUMBIA UNIVERSITY', ''),
	`Center Name` = REPLACE(`Center Name`, ', COLUMBIA UNIVERSITY', '')
WHERE `Legal Name` LIKE 'TEACHER%' OR `Center Name` LIKE 'TEACHER%';

-- Discrepancies in Center Name or Legal Name
SELECT DISTINCT `Legal Name` ,
		COUNT(*)
FROM childcare_staging2
GROUP BY `Legal Name`
ORDER BY 1
LIMIT 2200;

SELECT 
    `Legal Name`,
    CASE
        WHEN `Legal Name` LIKE '%,INC' THEN REPLACE(`Legal Name`, ',INC', ', INC.')
        WHEN `Legal Name` LIKE '%,LLC' THEN REPLACE(`Legal Name`, ',LLC', ', LLC.')
        WHEN `Legal Name` LIKE '%,PLLC' THEN REPLACE(`Legal Name`, ', PLLC', ', PLLC.')
        WHEN `Legal Name` LIKE '%,LTD' THEN REPLACE(`Legal Name`, ',LTD', ', LTD.')
        WHEN `Legal Name` LIKE '%,CORP' THEN REPLACE(`Legal Name`, ',CORP', ', CORP.')
        ELSE `Legal Name`
    END AS `NEW Legal Name`
FROM childcare_staging2
WHERE `Legal Name` LIKE '%,INC' OR `Legal Name` LIKE '%,LLC' OR `Legal Name` LIKE '%, PLLC' OR `Legal Name` LIKE '%, LTD' OR `Legal Name` LIKE '%, CORP';

UPDATE childcare_staging2 
SET `Legal Name` = CASE
        WHEN `Legal Name` LIKE '%,INC' THEN REPLACE(`Legal Name`, ',INC', ', INC.')
        WHEN `Legal Name` LIKE '%,LLC' THEN REPLACE(`Legal Name`, ',LLC', ', LLC.')
        WHEN `Legal Name` LIKE '%, PLLC' THEN REPLACE(`Legal Name`, ', PLLC', ', PLLC.')
        WHEN `Legal Name` LIKE '%,LTD' THEN REPLACE(`Legal Name`, ',LTD', ', LTD.')
        WHEN `Legal Name` LIKE '%,CORP' THEN REPLACE(`Legal Name`, ',CORP', ', CORP.')
        ELSE `Legal Name`
    END
WHERE `Legal Name` LIKE '%,INC' OR `Legal Name` LIKE '%,LLC' OR `Legal Name` LIKE '%, PLLC' OR `Legal Name` LIKE '%, LTD' OR `Legal Name` LIKE '%, CORP';

-- Double Spaces
SELECT `Legal Name`,
		LENGTH(`Legal Name`),
		REPLACE(`Legal Name`, '  ', ' '),
        LENGTH(REPLACE(`Legal Name`, '  ', ' '))
FROM childcare_staging2
WHERE `Legal Name` LIKE '%  %'
ORDER BY 1;

UPDATE childcare_staging2
SET `Legal Name` = REPLACE(`Legal Name`, '  ', ' ')
WHERE `Legal Name` LIKE '%  %';

SELECT `Legal Name`
FROM childcare_staging2
WHERE `Legal Name` LIKE "% '";

-- Remove '
SELECT `Legal Name`, TRIM(TRAILING " '" FROM `Legal Name`)
FROM childcare_staging2
WHERE `Legal Name` LIKE "% '";

UPDATE childcare_staging2
SET `Legal Name` = TRIM(TRAILING " '" FROM `Legal Name`)
WHERE `Legal Name` LIKE "% '";

-- Remove ""
SELECT *
FROM childcare_staging2
WHERE `Legal Name` LIKE '%ALPHABET CITY CHILD CARE CENTER LLC%';

UPDATE childcare_staging2
SET `Legal Name` = REPLACE(`Legal Name`, "'", '')
WHERE `Legal Name` LIKE '%ALPHABET CITY CHILD CARE CENTER LLC%';

-- RECHECK: Add '.' To the end of LLC, INC, LTD, CORP
 
SELECT DISTINCT `Legal Name`
FROM childcare_staging2
WHERE `Legal Name` LIKE '%.'
ORDER BY 1
LIMIT 2000;
 
SELECT 
    `Legal Name`,
    CASE
        WHEN `Legal Name` REGEXP '(INC|LLC|PLLC|LTD|CORP)$' THEN CONCAT(`Legal Name`, '.')
        ELSE `Legal Name`
    END AS `NEW Legal Name`,
    `Center Name`,
    CASE
        WHEN `Center Name` REGEXP '(INC|LLC|PLLC|LTD|CORP)$' THEN CONCAT(`Center Name`, '.')
        ELSE `Center Name`
    END AS `NEW Center Name`
FROM childcare_staging2
WHERE 
    `Legal Name` != CASE
                        WHEN `Legal Name` REGEXP '(INC|LLC|PLLC|LTD|CORP)$' THEN CONCAT(`Legal Name`, '.')
                        ELSE `Legal Name`
                    END
OR`Center Name` != CASE
                        WHEN `Center Name` REGEXP '(INC|LLC|PLLC|LTD|CORP)$' THEN CONCAT(`Center Name`, '.')
                        ELSE `Center Name`
                    END;

UPDATE childcare_staging2
SET `Legal Name` = CASE
						WHEN `Legal Name` REGEXP '(INC|LLC|PLLC|LTD|CORP)$' THEN CONCAT(`Legal Name`, '.')
						ELSE `Legal Name`
                   END,
    `Center Name` = CASE
                        WHEN `Center Name` REGEXP '(INC|LLC|PLLC|LTD|CORP)$' THEN CONCAT(`Center Name`, '.')
                        ELSE `Center Name`
                   END
WHERE `Legal Name` != CASE
                        WHEN `Legal Name` REGEXP '(INC|LLC|PLLC|LTD|CORP)$' THEN CONCAT(`Legal Name`, '.')
                        ELSE `Legal Name`
                    END
OR `Center Name` != CASE
                        WHEN `Center Name` REGEXP '(INC|LLC|PLLC|LTD|CORP)$' THEN CONCAT(`Center Name`, '.')
                        ELSE `Center Name`
                    END;

SELECT `Center Name`, REPLACE(`Center Name`, '..', '.')
FROM childcare_staging2
WHERE `Center Name` LIKE '%..';

UPDATE childcare_staging2 
SET `Center Name` = REPLACE(`Center Name`, '..', '.')
WHERE `Center Name` LIKE '%..';

SELECT `Center Name`, REPLACE(`Legal Name`, ',INC.', ', INC.')
FROM childcare_staging2
WHERE `Center Name` LIKE '%,INC.';

UPDATE childcare_staging2
SET `Center Name` = REPLACE(`Center Name`, ',INC.', ', INC.')
WHERE `Center Name` LIKE '%,INC.';
    
-- Add space ', ' before abbreviations
SELECT DISTINCT `Legal Name`,
    CASE
        WHEN `Legal Name` REGEXP '( INC| LLC| PLLC| LTD| CORP)\\.$' AND `Legal Name` NOT REGEXP ', (INC|LLC|PLLC|LTD|CORP)\\.$' THEN
            REGEXP_REPLACE(`Legal Name`, '( INC| LLC| PLLC| LTD| CORP)\\.$', ',$1.')
        ELSE `Legal Name`
    END AS `New_Legal_Name`,
    `Center Name`,
    CASE
        WHEN `Center Name` REGEXP '( INC| LLC| PLLC| LTD| CORP)\\.$' AND `Center Name` NOT REGEXP ', (INC|LLC|PLLC|LTD|CORP)\\.$' THEN
            REGEXP_REPLACE(`Center Name`, '( INC| LLC| PLLC| LTD| CORP)\\.$', ',$1.')
        ELSE `Center Name`
    END AS `New_Center_Name`
FROM childcare_staging2
WHERE 
    (`Legal Name` REGEXP '( INC| LLC| PLLC| LTD| CORP)\\.$' AND `Legal Name` NOT REGEXP ',( INC| LLC| PLLC| LTD| CORP)\\.$')
OR
	(`Center Name` REGEXP '( INC| LLC| PLLC| LTD| CORP)\\.$' AND `Center Name` NOT REGEXP ',( INC| LLC| PLLC| LTD| CORP)\\.$');
    
UPDATE childcare_staging2
SET `Legal Name` = CASE
    WHEN `Legal Name` REGEXP '( INC| LLC| PLLC| LTD| CORP)\\.$' AND `Legal Name` NOT REGEXP ', (INC|LLC|PLLC|LTD|CORP)\\.$' THEN
        REGEXP_REPLACE(`Legal Name`, '( INC| LLC| PLLC| LTD| CORP)\\.$', ',$1.')
    ELSE `Legal Name`
END,
`Center Name` = CASE
        WHEN `Center Name` REGEXP '( INC| LLC| PLLC| LTD| CORP)\\.$' AND `Center Name` NOT REGEXP ', (INC|LLC|PLLC|LTD|CORP)\\.$' THEN
            REGEXP_REPLACE(`Center Name`, '( INC| LLC| PLLC| LTD| CORP)\\.$', ',$1.')
        ELSE `Center Name`
    END
WHERE 
    `Legal Name` REGEXP '( INC| LLC| PLLC| LTD| CORP)\\.$' AND `Legal Name` NOT REGEXP ',( INC| LLC| PLLC| LTD| CORP)\\.$'
OR 
	(`Center Name` REGEXP '( INC| LLC| PLLC| LTD| CORP)\\.$' AND `Center Name` NOT REGEXP ',( INC| LLC| PLLC| LTD| CORP)\\.$');
    

-- Change all spacing to Upper(majority were already upper) in `Legal Name` & `Center Name`
SELECT 
    `Legal Name`, `Center Name`, `Street`, UPPER(`Legal Name`), UPPER(`Center Name`), UPPER(`Street`)
FROM 
    childcare_staging2;
    
UPDATE childcare_staging2
SET `Legal Name` = UPPER(`Legal Name`), `Center Name` = UPPER(`Center Name`), `Street` = UPPER(`Street`);


-- CLEANING STREET COLUMN
SELECT DISTINCT(`Street`), TRIM(TRAILING '.' FROM `Street`)
FROM childcare_staging2
WHERE `Street` LIKE '%.'
ORDER BY 1;

UPDATE childcare_staging2
SET `Street` = TRIM(TRAILING '.' FROM `Street`)
WHERE `Street` LIKE '%.';

-- Change street abbreviations     
SELECT 
    `Street`,
    CASE
        WHEN `Street` REGEXP ' AVE$' THEN REGEXP_REPLACE(`Street`, ' AVE$', ' AVENUE')
        WHEN `Street` REGEXP ' ST$' THEN REGEXP_REPLACE(`Street`, ' ST$', ' STREET')
        WHEN `Street` REGEXP ' PL$' THEN REGEXP_REPLACE(`Street`, ' PL$', ' PLACE')
        WHEN `Street` REGEXP ' BLVD$' THEN REGEXP_REPLACE(`Street`, ' BLVD$', ' BOULEVARD')
        WHEN `Street` REGEXP ' PKWY$' THEN REGEXP_REPLACE(`Street`, ' PKWY$', ' PARKWAY')
        WHEN `Street` REGEXP ' RD$' THEN REGEXP_REPLACE(`Street`, ' RD$', ' ROAD')
        WHEN `Street` REGEXP ' DR$' THEN REGEXP_REPLACE(`Street`, ' DR$', ' DRIVE')
        ELSE `Street`
    END AS New_Street
FROM childcare_staging2
WHERE `Street` REGEXP ' (AVE|ST|PL|BLVD|PKWY|RD|DR)$';

UPDATE childcare_staging2
SET `Street` = CASE
        WHEN `Street` REGEXP ' AVE$' THEN REGEXP_REPLACE(`Street`, ' AVE$', ' AVENUE')
        WHEN `Street` REGEXP ' ST$' THEN REGEXP_REPLACE(`Street`, ' ST$', ' STREET')
        WHEN `Street` REGEXP ' PL$' THEN REGEXP_REPLACE(`Street`, ' PL$', ' PLACE')
        WHEN `Street` REGEXP ' BLVD$' THEN REGEXP_REPLACE(`Street`, ' BLVD$', ' BOULEVARD')
        WHEN `Street` REGEXP ' PKWY$' THEN REGEXP_REPLACE(`Street`, ' PKWY$', ' PARKWAY')
        WHEN `Street` REGEXP ' RD$' THEN REGEXP_REPLACE(`Street`, ' RD$', ' ROAD')
        WHEN `Street` REGEXP ' DR$' THEN REGEXP_REPLACE(`Street`, ' DR$', ' DRIVE')
        ELSE `Street`
    END
WHERE `Street` REGEXP ' (AVE|ST|PL|BLVD|PKWY|RD|DR)$';

SELECT 
    `Street`,
    CASE
        WHEN `Street` LIKE 'E %' THEN REPLACE(`Street`, 'E ', 'EAST ')
        WHEN `Street` LIKE 'S %' THEN REPLACE(`Street`, 'S ', 'SOUTH ')
        WHEN `Street` LIKE 'W %' THEN REPLACE(`Street`, 'W ', 'WEST ')
        ELSE `Street`
    END AS new_street
FROM childcare_staging2
WHERE 
    `Street` LIKE 'E %' OR 
    `Street` LIKE 'S %' OR 
    `Street` LIKE 'W %';
    
UPDATE childcare_staging2
SET `Street` = CASE
        WHEN `Street` LIKE 'E %' THEN REPLACE(`Street`, 'E ', 'EAST ')
        WHEN `Street` LIKE 'S %' THEN REPLACE(`Street`, 'S ', 'SOUTH ')
        WHEN `Street` LIKE 'W %' THEN REPLACE(`Street`, 'W ', 'WEST ')
        ELSE `Street`
    END
WHERE 
    `Street` LIKE 'E %' OR 
    `Street` LIKE 'S %' OR 
    `Street` LIKE 'W %';

-- Fix the STREET STREET mistake
SELECT `Street`,
		CONCAT(SUBSTRING_INDEX(`Street`, 'STREET', 1), 'ST',                                          
        SUBSTRING(`Street`, 
                  LENGTH(SUBSTRING_INDEX(`Street`, 'STREET', 1)) + 7) 
    ) AS new_street
FROM childcare_staging2
WHERE `Street` LIKE '%STREET STREET%';
    
UPDATE childcare_staging2
SET `Street` = CONCAT(SUBSTRING_INDEX(`Street`, 'STREET', 1),'ST',                                   
        SUBSTRING(`Street`, 
                  LENGTH(SUBSTRING_INDEX(`Street`, 'STREET', 1)) + 7)
    )
WHERE `Street` LIKE '%STREET STREET%';

-- Find the numbered streets that are spelled out
SELECT `Street`,
	COUNT(*)
FROM childcare_Staging2
WHERE `Street` REGEXP '[A-Z].*(ST |TH |ND |RD )' AND `Street` NOT REGEXP '^(EAST|WEST) '
GROUP BY 1
ORDER BY 1;

-- FIRST - FIFTH AND TENTH
SELECT DISTINCT 
    `Street`,
    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(`Street`, 'FIRST ', '1ST '),
                        'SECOND ', '2ND '),
                    'THIRD ', '3RD '),
                'FOURTH ', '4TH '),
            'FIFTH ', '5TH '),
        'TENTH ', '10TH ') AS words_to_nums
FROM childcare_staging2
WHERE `Street` REGEXP '[A-Z].*(ST |TH |ND |RD )' AND `Street` NOT REGEXP '^(EAST|WEST)';

UPDATE childcare_staging2
SET `Street` = REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(`Street`, 'FIRST ', '1ST '),
                                    'SECOND ', '2ND '),
                                'THIRD ', '3RD '),
                            'FOURTH ', '4TH '),
                        'FIFTH ', '5TH '),
                    'TENTH ', '10TH ')
WHERE `Street` REGEXP '[A-Z].*(ST |TH |ND |RD )' AND `Street` NOT REGEXP '^(EAST|WEST)';


-- Some numbered streets have st, th, nd, rd and some don't
SELECT `Street`,
	COUNT(*)
FROM childcare_staging
WHERE `Street` REGEXP '[0-9].+(ST |TH |ND |RD )\\b'
GROUP BY `Street`
ORDER BY 1;

SELECT `Street`,
	COUNT(*)
FROM childcare_staging2
WHERE `Street` REGEXP '[0-9]' AND `Street` NOT REGEXP '[0-9]+(ST|ND|RD|TH)\\b'
GROUP BY `Street`
ORDER BY 1;
    
-- Total Number of numbered streets with or without suffix
SELECT 
    SUM(CASE 
            WHEN `Street` REGEXP '[0-9]+(ST|ND|RD|TH)\\b' THEN 1 
            ELSE 0 
        END) AS count_with_suffixes,
    SUM(CASE 
            WHEN `Street` REGEXP '[0-9]' AND `Street` NOT REGEXP '[0-9]+(ST|ND|RD|TH)\\b' THEN 1 
            ELSE 0 
        END) AS count_without_suffixes,
    COUNT(*) AS total
FROM childcare_staging2
WHERE `Street` REGEXP '[0-9]';

-- Small differences in Streets
SELECT DISTINCT `Street` 
FROM childcare_staging2 
WHERE `Street` LIKE '%.%';

SELECT  `Street`,
		REPLACE(`Street`, 'ST ', 'ST. ')
FROM childcare_staging2
WHERE `Street` LIKE 'ST %';

UPDATE childcare_staging2
SET `Street` = REPLACE(`Street`, 'ST ', 'ST. ')
WHERE `Street` LIKE 'ST %';

SELECT `Street`,
		REPLACE(`Street`, 'E. ', 'EAST ')
FROM childcare_staging2
WHERE `Street` = 'E. 53RD STREET';

UPDATE childcare_staging2
SET `Street` = REPLACE(`Street`, 'E. ', 'EAST ')
WHERE `Street` = 'E. 53RD STREET';

SELECT `Street`,
		TRIM(TRAILING ')' FROM REPLACE(REPLACE(`Street`, 'ST. JOHN''S LANE (AKA ', ''), 'ST', 'STREET'))
FROM childcare_staging2 
WHERE `Street` LIKE '%1 YORK ST%';

UPDATE childcare_staging2
SET `Street` = TRIM(TRAILING ')' FROM REPLACE(REPLACE(`Street`, 'ST. JOHN''S LANE (AKA ', ''), 'ST', 'STREET'))
WHERE `Street` LIKE '%1 YORK ST%';

SELECT `Street`,
		REPLACE(`Street`, '108', '108 STREET')
FROM childcare_staging2 
WHERE `Street` = '108';

UPDATE childcare_staging2
SET `Street` = REPLACE(`Street`, '108', '108 STREET')
WHERE `Street` = '108';

-- For consistency, I will remove all the ST, TH, ND, RD from numbers

SELECT 
    DISTINCT `Street`,
    CASE 
        WHEN `Street` REGEXP '[0-9]ST\\b' THEN REPLACE(`Street`, 'ST', '')
        WHEN `Street` REGEXP '[0-9]TH\\b' THEN REPLACE(`Street`, 'TH', '')
        WHEN `Street` REGEXP '[0-9]ND\\b' THEN REPLACE(`Street`, 'ND', '')
        WHEN `Street` REGEXP '[0-9]RD\\b' THEN REPLACE(`Street`, 'RD', '')
        ELSE `Street`
    END AS new_street
FROM childcare_staging2
WHERE 
    `Street` REGEXP '[0-9](ST|TH|ND|RD)\\b';
    
UPDATE childcare_staging2
SET `Street` = CASE 
        WHEN `Street` REGEXP '[0-9]ST\\b' THEN REPLACE(`Street`, 'ST', '')
        WHEN `Street` REGEXP '[0-9]TH\\b' THEN REPLACE(`Street`, 'TH', '')
        WHEN `Street` REGEXP '[0-9]ND\\b' THEN REPLACE(`Street`, 'ND', '')
        WHEN `Street` REGEXP '[0-9]RD\\b' THEN REPLACE(`Street`, 'RD', '')
        ELSE `Street`
    END
WHERE 
    `Street` REGEXP '[0-9](ST|TH|ND|RD)\\b';

SELECT COUNT(DISTINCT `Street`)
FROM childcare_staging2;

SELECT 
	`Street`,
    COUNT(*)
FROM childcare_staging2
GROUP BY `Street`
ORDER BY `Street`
LIMIT 1500;

SELECT * 
FROM childcare_staging2
WHERE `Street` LIKE 'WEST 97%';

SELECT `Street`, REPLACE(`Street`, ', SUITE 1D', '')
FROM childcare_staging2
WHERE `Street` LIKE 'WEST 97%';

UPDATE childcare_staging2 
SET `Street` = REPLACE(`Street`, ', SUITE 1D', '')
WHERE `Street` LIKE 'WEST 97%';

-- Streets with errors
-- cross bay, guy r., newel, St Marks, st johns, UNION TURNPIKE NULL LEWIS BOULEVARD, walker street, west 97, weststreet
SELECT * 
FROM childcare_staging2
WHERE `Street` LIKE '%GUY%';
-- Remove building number from 'Street' column and place into 'Building' column
SELECT 
	`Street`,
    COUNT(*)
FROM childcare_staging2
WHERE `Street` LIKE '%-%'
GROUP BY `Street`;

SELECT 
    SUBSTRING_INDEX(`Street`, ' ', 1) AS Building,
    TRIM(SUBSTRING(`Street`, LENGTH(SUBSTRING_INDEX(`Street`, ' ', 1)) + 1)) AS Street
FROM childcare_staging2
WHERE `Street` LIKE '%-%';
    
UPDATE childcare_staging2
SET `Building` = SUBSTRING_INDEX(`Street`, ' ', 1),
    `Street` = TRIM(SUBSTRING(`Street`, LENGTH(SUBSTRING_INDEX(`Street`, ' ', 1)) + 1))
WHERE `Street` LIKE '%-%';

-- Double building number
SELECT `Street`, 
		REPLACE(`Street`, '240-08 ', '')
FROM childcare_staging2
WHERE `Street` = '240-08 135 AVENUE';

UPDATE childcare_staging2
SET `Street` = REPLACE(`Street`, '240-08 ', '')
WHERE `Street` = '240-08 135 AVENUE';

-- Crossbay 
SELECT `Street`,
		REPLACE(`Street`, 'CROSSBAY', 'CROSS BAY')
FROM childcare_staging2
WHERE `Street` = 'CROSSBAY BOULEVARD';

UPDATE childcare_staging2
SET `Street` = REPLACE(`Street`, 'CROSSBAY', 'CROSS BAY')
WHERE `Street` = 'CROSSBAY BOULEVARD';

-- GUY R. BREWER
SELECT `Street`,
		REPLACE(`Street`, 'GUY R. ', 'GUY R ')
FROM childcare_staging2
WHERE `Street` LIKE 'GUY R. %';

UPDATE childcare_staging2
SET `Street` = REPLACE(`Street`, 'GUY R. ', 'GUY R ')
WHERE `Street` LIKE 'GUY R. %';

SELECT `Street`,
		REPLACE(`Street`, 'GUY ', 'GUY R ')
FROM childcare_staging2
WHERE `Street` LIKE 'GUY BREWER%';

UPDATE childcare_staging2
SET `Street` = REPLACE(`Street`, 'GUY ', 'GUY R ')
WHERE `Street` LIKE 'GUY BREWER%';

-- NEWEL -> NEWELL
SELECT `Street`,
		REPLACE(`Street`, 'NEWEL ', 'NEWELL ')
FROM childcare_staging2
WHERE `Street` LIKE 'NEWEL %';

UPDATE childcare_staging2
SET `Street` = REPLACE(`Street`, 'NEWEL ', 'NEWELL ')
WHERE `Street` LIKE 'NEWEL %';

-- ST. MARKS, ST MARK'S -> ST MARKS
SELECT `Street`,
		REPLACE(REPLACE(`Street`, 
			'ST. MARKS ', 'ST MARKS '),
			"ST MARK'S ", 'ST MARKS ')
FROM childcare_staging2
WHERE `Street` LIKE "ST. MARKS%" OR `Street` LIKE "ST MARK'S%";

UPDATE childcare_staging2
SET `Street` = REPLACE(REPLACE(`Street`, 
			'ST. MARKS ', 'ST MARKS '),
			"ST MARK'S ", 'ST MARKS ')
WHERE `Street` LIKE "ST. MARKS%" OR `Street` LIKE "ST MARK'S%";

-- ST. JOHNS -> ST. JOHN'S
SELECT `Street`,
		REPLACE(`Street`, 'ST. JOHNS ', "ST. JOHN'S ")
FROM childcare_staging2
WHERE `Street` LIKE 'ST. JOHNS%';

UPDATE childcare_staging2
SET `Street` = REPLACE(`Street`, 'ST. JOHNS ', "ST. JOHN'S ")
WHERE `Street` LIKE 'ST. JOHNS%';

-- NULL LEWIS BOULEVARD
SELECT `Street`,
		REPLACE(`Street`, ' NULL LEWIS BOULEVARD', '')
FROM childcare_staging2
WHERE `Street` LIKE '%NULL LEWIS BOULEVARD';

UPDATE childcare_staging2
SET `Street` = REPLACE(`Street`, ' NULL LEWIS BOULEVARD', '')
WHERE `Street` LIKE '%NULL LEWIS BOULEVARD';

SELECT `Street`,
		REPLACE(`Street`, 'WESTREET ', 'WEST ')
FROM childcare_staging2
WHERE `Street` LIKE 'WESTREET%';

UPDATE childcare_staging2
SET `Street` = REPLACE(`Street`, 'WESTREET ', 'WEST ')
WHERE `Street` LIKE 'WESTREET%';

SELECT `Street`,
		REPLACE(`Street`, '91ST', '91 STREET')
FROM childcare_staging2
WHERE `Street` = '91ST';

UPDATE childcare_staging2
SET `Street` = REPLACE(`Street`, '91ST', '91 STREET')
WHERE `Street` = '91ST';

-- Streets with double space
SELECT 
	`Street`,
    LENGTH(`Street`) AS st_len,
    REPLACE(`Street`, '  ', ' ') AS new_st,
    LENGTH(REPLACE(`Street`, '  ', ' ')) AS new_st_len
FROM childcare_staging2
WHERE `Street` LIKE '%  %';

UPDATE childcare_staging2
SET `Street` = REPLACE(`Street`, '  ', ' ')
WHERE `Street` LIKE '%  %';

-- Remove added Row Num column
ALTER TABLE childcare_staging2
DROP COLUMN row_num;