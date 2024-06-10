-- Data Exploration
SELECT * 
FROM businesses_staging;

-- Count of different type of industries
SELECT 
	`Industry`, 
    COUNT(*) AS count
FROM businesses_staging
GROUP BY `Industry`
ORDER BY count DESC;

-- Percent of Indiviuals to Businesses
SELECT 
    `License Type`, 
    COUNT(`License Type`) AS count,
    ROUND((COUNT(`License Type`) / (SELECT COUNT(*) FROM businesses_staging) * 100)) AS percentage
FROM 
    businesses_staging
GROUP BY 
    `License Type`;
    
-- Industries and License Type
SELECT 
	`License Type`, 
	`Industry`,
    COUNT(*) AS industry_count
FROM businesses_staging
GROUP BY `License Type`, `Industry`;

-- Active Vs Inactive Licenses
SELECT 
    `License Status`, 
    COUNT(`License Status`) AS count,
    ROUND((COUNT(`License Status`) / (SELECT COUNT(*) FROM businesses_staging) * 100)) AS percentage
FROM 
    businesses_staging
GROUP BY 
    `License Status`;
    
-- License Status in each Industry
SELECT 
	`Industry`,
    SUM(`License Status` = 'active') AS active_license,
    SUM(`License Status` = 'inactive') AS inactive_license,
    COUNT(`License Status`) AS total_license_count
FROM businesses_staging
GROUP BY `Industry`
ORDER BY total_license_count DESC;


SELECT 
	YEAR(`License Creation Date`) AS license_by_year,
    COUNT(*) AS license_count
FROM businesses_staging
GROUP BY license_by_year
ORDER BY license_count DESC;


-- Rolling total of active licenses 
WITH Rolling_Total AS
(
SELECT 
	SUBSTR(`License Creation Date`, 1,7) AS `MONTH`, 
	SUM(`License Status` = 'active') AS active_license
FROM businesses_staging
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `MONTH`, active_license
,SUM(active_license) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;

-- How Long the license is vaild for
SELECT 
	`License Creation Date`,
    `License Expiration Date`, 
    CONCAT(
		FLOOR(DATEDIFF(`License Expiration Date`, `License Creation Date`) / 365),
        ' years ',
        FLOOR((DATEDIFF(`License Expiration Date`, `License Creation Date`) % 365) / 30),
        ' months'
	) AS license_validity
FROM businesses_staging;
    
-- Active Licenses by City 
SELECT 
	`Address City`,
    SUM(`License Status` = 'active') AS active_license,
    SUM(`License Status` = 'inactive') AS inactive_license
FROM businesses_staging
GROUP BY `Address City`
ORDER BY active_license DESC;



