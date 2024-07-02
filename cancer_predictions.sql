CREATE DATABASE cancer_predictions;
USE cancer_predictions;

SELECT * FROM cancer_data;
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

-- Create derived columns
-- Age Group
ALTER TABLE cancer_data
ADD COLUMN age_group VARCHAR(10) AFTER age;

UPDATE cancer_data
SET age_group = 
    CASE 
        WHEN age < 20 THEN '0-19'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        WHEN age BETWEEN 50 AND 59 THEN '50-59'
        WHEN age BETWEEN 60 AND 69 THEN '60-69'
        ELSE '70+'
    END;

-- Gender 
ALTER TABLE cancer_data
ADD COLUMN gender_label VARCHAR(6) AFTER gender;

UPDATE cancer_data
SET gender_label = 
    CASE 
        WHEN gender = 1 THEN 'Female'
        ELSE 'Male'
    END;

-- Smoking
ALTER TABLE cancer_data
ADD COLUMN smoking_status VARCHAR(3) AFTER smoking;

UPDATE cancer_data
SET smoking_status = 
    CASE 
        WHEN smoking = 1 THEN 'Yes'
        ELSE 'No'
    END;

-- Genetic Risk
ALTER TABLE cancer_data
ADD COLUMN genetic_risk VARCHAR(6) AFTER geneticRisk;

UPDATE cancer_data
SET genetic_risk = 
    CASE 
        WHEN geneticRisk = 0 THEN 'Low'
        WHEN geneticRisk = 1 THEN 'Medium'
        ELSE 'High'
    END;

-- Cancer History
ALTER TABLE cancer_data
ADD COLUMN cancer_history VARCHAR(3) AFTER cancerHistory;

UPDATE cancer_data
SET cancer_history = 
    CASE 
        WHEN cancerHistory = 1 THEN 'Yes'
        ELSE 'No'
    END;

-- Diagnosis
ALTER TABLE cancer_data
ADD COLUMN diagnosis_status VARCHAR(10) AFTER Diagnosis;

UPDATE cancer_data
SET diagnosis_status = 
    CASE 
        WHEN Diagnosis = 1 THEN 'Cancer'
        ELSE 'No Cancer'
    END;



-- Genetic risk distribution within different age group
SELECT 
    age_group,
    genetic_risk, 
    COUNT(*) as count
FROM cancer_data
GROUP BY age_group, genetic_risk
ORDER BY count DESC, genetic_risk DESC;

-- Average of patients with cancer diagnosis(0= No, 1=Yes)
SELECT diagnosis, AVG(Age) as avg_age
FROM cancer_data
GROUP BY Diagnosis;

-- Distribution of gender with cancer diagnosis
SELECT 
gender_label, 
diagnosis_status, 
COUNT(*) as count
FROM cancer_data
GROUP BY gender_label, diagnosis_status
ORDER BY count DESC, diagnosis_status DESC;

-- Male to Female count of cancer diagnosis
SELECT 
	gender_label, 
	genetic_risk,
	diagnosis_status, 
COUNT(*) as count
FROM cancer_data
GROUP BY gender_label, genetic_risk, diagnosis_status
ORDER BY count DESC, diagnosis_status DESC;

-- smoking affects cancer diagnosis?
SELECT  
smoking_status, 
diagnosis_status, COUNT(*) as count
FROM cancer_data
GROUP BY smoking_status, diagnosis_status
ORDER BY count DESC, diagnosis_status DESC;

-- Count of paitents with/without cancer diagnosis by gentic risk
SELECT 
	genetic_risk,
	diagnosis_status, COUNT(*) as count
FROM cancer_data
GROUP BY genetic_risk, diagnosis_status
ORDER BY count DESC, diagnosis_status DESC;

-- Avg BMI of diagnosis
SELECT 
	diagnosis_status, 
    ROUND(AVG(bmi),2) as avg_bmi
FROM cancer_data
GROUP BY diagnosis_status;

-- AVG of physical activity related to cancer diagnosis
SELECT 
	diagnosis_status, 
	ROUND(AVG(physicalActivity),2) as avg_physical_activity
FROM cancer_data
GROUP BY diagnosis_status;

-- alcoholIntake related to cancer diagnosis
SELECT 
	diagnosis_status, 
    ROUND(AVG(alcoholIntake),2) as avg_alcohol_intake
FROM cancer_data
GROUP BY diagnosis_status;

-- Avg BMI by level of physical activity grouped by genetic risk level
SELECT 
	genetic_risk, 
	CASE 
		WHEN physicalActivity < 3 THEN 'Low'
		WHEN physicalActivity BETWEEN 3 AND 6 THEN 'Medium'
		ELSE 'High'
       END as physical_activity_level, 
       ROUND(AVG(bmi),2) as avg_bmi
FROM cancer_data
GROUP BY genetic_risk, physical_activity_level
ORDER BY avg_bmi ASC;

-- Cancer diagnosis rate fro different age groups
SELECT 
	age_group, 
	genetic_Risk,
    SUM(diagnosis) as cancer_cases, 
    COUNT(*) as total_cases, 
    ROUND((SUM(diagnosis) / COUNT(*)) * 100, 2) as cancer_rate
FROM cancer_data
GROUP BY age_group, genetic_risk;

-- Cancer rate of patients grouped by gentisk risk and cancer history
SELECT 
	genetic_risk,
	cancer_history, 
	SUM(diagnosis) as cancer_cases, 
	COUNT(*) as total_cases, 
	ROUND((SUM(diagnosis) / COUNT(*)) * 100, 2) as cancer_rate
FROM cancer_data
GROUP BY genetic_risk, cancer_history
ORDER BY cancer_rate DESC;


-- Correlation between smokers/nonsmokers and alcohol intake with cancer diagnosis
SELECT 
	smoking_status, 
       CASE 
           WHEN alcoholIntake < 1 THEN '0-0.9'
           WHEN alcoholIntake BETWEEN 1 AND 2 THEN '1-2'
           WHEN alcoholIntake BETWEEN 2 AND 3 THEN '2-3'
           WHEN alcoholIntake BETWEEN 3 AND 4 THEN '3-4'
           ELSE '4-5'
       END as alcohol_intake_range, 
       diagnosis_status, 
       COUNT(*) as count
FROM cancer_data
GROUP BY smoking_status, alcohol_intake_range, diagnosis_status
ORDER BY count DESC, diagnosis_status DESC;

-- relation between physical activity, bmi, diagnosis between genders
SELECT 
	gender_label, 
	CASE 
		WHEN physicalActivity < 3 THEN 'Low'
		WHEN physicalActivity BETWEEN 3 AND 6 THEN 'Medium'
		ELSE 'High'
	END as physical_activity_level, 
	ROUND(AVG(bmi),2) as avg_bmi, 
	diagnosis_status, 
	COUNT(*) as count
FROM cancer_data
GROUP BY gender_label, physical_activity_level, diagnosis_status
ORDER BY count DESC, diagnosis_status DESC;

-- Which age group(s) has higher than avg cancer rate
SELECT age_group, cancer_rate
FROM (
    SELECT 
        age_group, 
        (SUM(diagnosis) / COUNT(*)) * 100 as cancer_rate
    FROM cancer_data
    GROUP BY age_group
) AS cancer_age_rate
WHERE cancer_rate > (
    SELECT (SUM(diagnosis) / COUNT(*)) * 100
    FROM cancer_data)
ORDER BY cancer_rate DESC;