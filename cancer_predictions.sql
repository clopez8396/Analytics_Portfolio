CREATE DATABASE cancer_predictions;
USE cancer_predictions;

SELECT * 
FROM cancer_data;
-- Check for duplicates
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY age, gender, smoking, geneticRisk, physicalActivity, alcoholIntake, CancerHistory, diagnosis) AS row_num
FROM cancer_data
)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;


-- Genetic risk distribution within different age group
SELECT 
    CASE 
        WHEN age < 20 THEN '0-19'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        WHEN age BETWEEN 50 AND 59 THEN '50-59'
        WHEN age BETWEEN 60 AND 69 THEN '60-69'
        ELSE '70+' 
    END as age_group,
    geneticRisk, 
    COUNT(*) as count
FROM cancer_data
GROUP BY age_group, geneticRisk
ORDER BY geneticRisk DESC, count DESC;

-- Average of patients with cancer diagnosis(0= No, 1=Yes)
SELECT diagnosis, AVG(Age) as avg_age
FROM cancer_data
GROUP BY Diagnosis;

-- Distribution of gender with cancer diagnosis
SELECT 
CASE 
	WHEN gender = 1 THEN 'Female'
    ELSE 'Male' 
END AS gender, 
diagnosis, 
COUNT(*) as count
FROM cancer_data
GROUP BY gender, diagnosis
ORDER BY diagnosis DESC, count DESC;

-- Male to Female count of cancer diagnosis
SELECT CASE 
	WHEN gender = 1 THEN 'Female'
    ELSE 'Male' 
END AS gender, 
CASE
	WHEN geneticRisk = 0 THEN 'Low'
    WHEN geneticRisk = 1 THEN 'Medium'
ELSE 'High'
END AS genticRisk,
diagnosis, 
COUNT(*) as count
FROM cancer_data
GROUP BY gender, geneticRisk, diagnosis
ORDER BY diagnosis DESC, count DESC;

-- smoking affects cancer diagnosis?
SELECT  
CASE 
	WHEN smoking = 1 THEN 'Smoker'
    ELSE 'Nonsmoker' 
END AS smoker, 
diagnosis, COUNT(*) as count
FROM cancer_data
GROUP BY smoking, diagnosis
ORDER BY diagnosis DESC, count DESC;

-- Count of paitents with/without cancer diagnosis by gentic risk
SELECT 
CASE
	WHEN geneticRisk = 0 THEN 'Low'
    WHEN geneticRisk = 1 THEN 'Medium'
ELSE 'High'
END AS genticRisk,
diagnosis, COUNT(*) as count
FROM cancer_data
GROUP BY geneticRisk, diagnosis
ORDER BY diagnosis DESC, count DESC;

-- Avg BMI of diagnosis
SELECT diagnosis, ROUND(AVG(bmi),2) as avg_bmi
FROM cancer_data
GROUP BY diagnosis;

-- AVG of physical activity related to cancer diagnosis
SELECT Diagnosis, ROUND(AVG(physicalActivity),2) as avg_physical_activity
FROM cancer_data
GROUP BY diagnosis;

-- alcoholIntake related to cancer diagnosis
SELECT diagnosis, ROUND(AVG(alcoholIntake),2) as avg_alcohol_intake
FROM cancer_data
GROUP BY diagnosis;

-- Avg BMI by level of physical activity grouped by genetic risk level
SELECT 
CASE
	WHEN geneticRisk = 0 THEN 'Low'
    WHEN geneticRisk = 1 THEN 'Medium'
ELSE 'High'
END AS genticRisk, 
       CASE 
           WHEN physicalActivity < 3 THEN 'Low'
           WHEN physicalActivity BETWEEN 3 AND 6 THEN 'Medium'
           ELSE 'High'
       END as physical_activity_level, 
       ROUND(AVG(bmi),2) as avg_bmi
FROM cancer_data
GROUP BY geneticRisk, physical_activity_level
ORDER BY avg_bmi ASC;

-- Cancer diagnosis rate fro different age groups
SELECT 
    CASE 
        WHEN Age < 20 THEN '0-19'
        WHEN Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN Age BETWEEN 40 AND 49 THEN '40-49'
        WHEN Age BETWEEN 50 AND 59 THEN '50-59'
        WHEN Age BETWEEN 60 AND 69 THEN '60-69'
        ELSE '70+' 
    END as age_group, 
CASE
	WHEN geneticRisk = 0 THEN 'Low'
    WHEN geneticRisk = 1 THEN 'Medium'
ELSE 'High'
END AS genticRisk,
    SUM(diagnosis) as cancer_cases, 
    COUNT(*) as total_cases, 
    ROUND((SUM(diagnosis) / COUNT(*)) * 100, 2) as cancer_rate
FROM cancer_data
GROUP BY age_group, geneticRisk;

-- Cancer rate of patients grouped by gentisk risk and cancer history
SELECT 
CASE
	WHEN geneticRisk = 0 THEN 'Low'
    WHEN geneticRisk = 1 THEN 'Medium'
ELSE 'High'
END AS genticRisk,
       cancerHistory, 
       SUM(Diagnosis) as cancer_cases, 
       COUNT(*) as total_cases, 
       ROUND((SUM(Diagnosis) / COUNT(*)) * 100, 2) as cancer_rate
FROM cancer_data
GROUP BY geneticRisk, cancerHistory
ORDER BY cancer_rate DESC;


-- Correlation between smokers/nonsmokers and alcohol intake with cancer diagnosis
SELECT 
CASE 
	WHEN smoking = 1 THEN 'Smoker'
    ELSE 'Nonsmoker' 
END AS smoker, 
       CASE 
           WHEN alcoholIntake < 1 THEN '0-0.9'
           WHEN alcoholIntake BETWEEN 1 AND 2 THEN '1-2'
           WHEN alcoholIntake BETWEEN 2 AND 3 THEN '2-3'
           WHEN alcoholIntake BETWEEN 3 AND 4 THEN '3-4'
           ELSE '4-5'
       END as alcohol_intake_range, 
       diagnosis, 
       COUNT(*) as count
FROM cancer_data
GROUP BY smoking, alcohol_intake_range, diagnosis
ORDER BY diagnosis DESC, count DESC;

-- relation between physical activity, bmi, diagnosis between genders
SELECT 
CASE 
	WHEN gender = 1 THEN 'Female'
    ELSE 'Male' 
END AS gender, 
       CASE 
           WHEN physicalActivity < 3 THEN 'Low'
           WHEN physicalActivity BETWEEN 3 AND 6 THEN 'Medium'
           ELSE 'High'
       END as physical_activity_level, 
       ROUND(AVG(bmi),2) as avg_bmi, 
       diagnosis, 
       COUNT(*) as count
FROM cancer_data
GROUP BY gender, physical_activity_level, diagnosis
ORDER BY diagnosis DESC, count DESC;

-- Which age group(s) has higher than avg cancer rate
SELECT age_group, cancer_rate
FROM (
    SELECT 
        CASE 
            WHEN Age < 20 THEN '0-19'
            WHEN Age BETWEEN 20 AND 29 THEN '20-29'
            WHEN Age BETWEEN 30 AND 39 THEN '30-39'
            WHEN Age BETWEEN 40 AND 49 THEN '40-49'
            WHEN Age BETWEEN 50 AND 59 THEN '50-59'
            WHEN Age BETWEEN 60 AND 69 THEN '60-69'
            ELSE '70+' 
        END as age_group, 
        (SUM(diagnosis) / COUNT(*)) * 100 as cancer_rate
    FROM cancer_data
    GROUP BY age_group
) AS cancer_age_rate
WHERE cancer_rate > (
    SELECT (SUM(diagnosis) / COUNT(*)) * 100
    FROM cancer_data)
ORDER BY cancer_rate DESC;