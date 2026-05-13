-- ============================================================
--  HEALTHCARE_DB  —  Complete Query Portfolio
--  Schema: patients, doctors, departments, diagnoses,
--          outcomes, labs
--  Author : [Hiteshi Aglawe]
--  Purpose: Data Analyst SQL hands on practice
-- ============================================================


-- ============================================================
-- Q1  Detailed Patient Lab History
-- Concept : Multi-table JOIN  |  L-B
-- Business: Full patient profile with diagnosis, doctor,
--           outcome and every lab result in one view.
-- ============================================================
USE HEALTHCARE_DB_V2;

SELECT p.PatientID, p.Name, p.Age, p.Gender, 
d.DiagnosisName, doc.DoctorName, dept.DepartmentName,  
o.OutcomeName, l.TestName, l.Result, l.NormalRange, l.TestDate
FROM patients p
JOIN diagnoses   d    ON p.DiagnosisID   = d.DiagnosisID
JOIN doctors     doc  ON p.DoctorID      = doc.DoctorID
JOIN departments dept ON doc.DepartmentID = dept.DepartmentID
JOIN outcomes    o    ON p.OutcomeID     = o.OutcomeID
JOIN labs        l    ON p.PatientID     = l.PatientID
ORDER BY p.PatientID, l.TestDate, l.TestName;


-- ============================================================
-- Q2  Average Lab Result by Diagnosis
-- Concept : JOIN + GROUP BY + AVG  |  L-B
-- Business: Which diagnosis group shows the highest average
--           biomarker value per test? Drives clinical benchmarks.
-- ============================================================

SELECT d.DiagnosisName,l.TestName,
    ROUND(AVG(l.Result),3) AS AvgResult,
    COUNT(l.LabID)          AS TestCount
FROM patients  p
JOIN diagnoses d ON p.DiagnosisID = d.DiagnosisID
JOIN labs      l ON p.PatientID   = l.PatientID
GROUP BY d.DiagnosisName, l.TestName
ORDER BY d.DiagnosisName, l.TestName;


-- ============================================================
-- Q3  Patients with Abnormal Lab Results
-- Concept : Conditional WHERE + GROUP BY + HAVING  |  Level: Beginner
-- Business: Flag high-risk patients by counting how many of
--           their tests fell outside the clinical normal range.
-- ============================================================

SELECT
    p.PatientID,
    p.Name,
    p.Age,
    d.DiagnosisName,
    COUNT(*) AS AbnormalCount
FROM patients p
JOIN labs      l ON p.PatientID   = l.PatientID
JOIN diagnoses d ON p.DiagnosisID = d.DiagnosisID
WHERE
    (l.TestName = 'Blood Sugar'    AND (l.Result > 140  OR l.Result < 70  )) OR
    (l.TestName = 'Hemoglobin'     AND (l.Result > 17   OR l.Result < 12  )) OR
    (l.TestName = 'Cholesterol'    AND  l.Result > 200                      ) OR
    (l.TestName = 'Blood Pressure' AND (l.Result > 120  OR l.Result < 60  )) OR
    (l.TestName = 'Creatinine'     AND (l.Result > 1.2  OR l.Result < 0.6 )) OR
    (l.TestName = 'Vitamin D'      AND (l.Result > 50   OR l.Result < 20  ))
GROUP BY p.PatientID, p.Name, p.Age, d.DiagnosisName
ORDER BY AbnormalCount DESC;


-- ============================================================
-- Q4  Total Treatment Cost by Diagnosis
-- Concept : JOIN + GROUP BY + SUM + ORDER BY  |  
-- Business: Where is the hospital spending the most money?
--           Identifies cost-heavy disease categories.
-- ============================================================

SELECT
    d.DiagnosisName,
    COUNT(p.PatientID)       AS TotalPatients,
    SUM(p.TreatmentCost)     AS TotalCost,
    ROUND(AVG(p.TreatmentCost), 0) AS AvgCostPerPatient,
    MIN(p.TreatmentCost)     AS MinCost,
    MAX(p.TreatmentCost)     AS MaxCost
FROM patients  p
JOIN diagnoses d ON p.DiagnosisID = d.DiagnosisID
GROUP BY d.DiagnosisName
ORDER BY TotalCost DESC;


-- ============================================================
-- Q5  Patient Count by Diagnosis
-- Concept : GROUP BY + COUNT + ORDER BY  |  
-- Business: Disease prevalence ranking — which conditions
--           are most common in the patient population?
-- ============================================================

SELECT
    d.DiagnosisName,
    COUNT(*)                                      AS TotalPatients,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS PctOfTotal
FROM patients  p
JOIN diagnoses d ON p.DiagnosisID = d.DiagnosisID
GROUP BY d.DiagnosisName
ORDER BY TotalPatients DESC;


-- ============================================================
-- Q6  High-Risk Patients  (Age + Outcome Filter)
-- Concept : Multi-condition WHERE + JOINs  |  
-- Business: Find elderly male patients who did NOT recover —
--           priority list for post-discharge follow-up.
-- ============================================================

SELECT
    p.PatientID,
    p.Name,
    p.Age,
    p.Gender,
    d.DiagnosisName,
    doc.DoctorName,
    o.OutcomeName,
    p.TreatmentCost
FROM patients  p
JOIN diagnoses  d   ON p.DiagnosisID  = d.DiagnosisID
JOIN doctors    doc ON p.DoctorID     = doc.DoctorID
JOIN outcomes   o   ON p.OutcomeID    = o.OutcomeID
WHERE p.Age >= 70
  AND o.OutcomeName != 'Recovered'
  AND p.Gender = 'M'
ORDER BY p.Age DESC;


-- ============================================================
-- Q7  Lab Trends Over Time per Patient
-- Concept : JOIN + ORDER BY date  |  
-- Business: Track how a specific patient's biomarkers changed
--           across test sessions during their hospital stay.
-- ============================================================

SELECT
    p.PatientID,
    p.Name,
    d.DiagnosisName,
    l.TestName,
    l.Result,
    l.NormalRange,
    l.TestDate
FROM labs      l
JOIN patients  p ON l.PatientID   = p.PatientID
JOIN diagnoses d ON p.DiagnosisID = d.DiagnosisID
WHERE p.PatientID BETWEEN 1 AND 10
ORDER BY p.PatientID, l.TestName, l.TestDate;


-- ============================================================
-- Q8a  Outcome Distribution by Diagnosis  (GROUP BY)
-- Concept : JOIN + GROUP BY + COUNT  |  
-- Business: Which diagnoses lead most often to death or
--           complications? Supports mortality risk analysis.
-- ============================================================

SELECT
    d.DiagnosisName,
    o.OutcomeName,
    COUNT(*) AS OutcomeCount
FROM patients  p
JOIN diagnoses d ON p.DiagnosisID = d.DiagnosisID
JOIN outcomes  o ON p.OutcomeID   = o.OutcomeID
GROUP BY d.DiagnosisName, o.OutcomeName
ORDER BY d.DiagnosisName, o.OutcomeName;


-- ============================================================
-- Q8b  Outcome Distribution by Diagnosis  (Window Function)
-- Concept : COUNT() OVER (PARTITION BY)  | 
-- Business: Same result as Q8a but using a window function —
--           demonstrates awareness of alternative approaches.
-- ============================================================

SELECT DISTINCT
    d.DiagnosisName,
    o.OutcomeName,
    COUNT(*) OVER (PARTITION BY d.DiagnosisName, o.OutcomeName) AS OutcomeCount
FROM patients  p
JOIN diagnoses d ON p.DiagnosisID = d.DiagnosisID
JOIN outcomes  o ON p.OutcomeID   = o.OutcomeID
ORDER BY d.DiagnosisName, o.OutcomeName;

-- ============================================================
-- Q9  Patient Risk Tier  (CASE WHEN)
-- Concept : CASE WHEN + multi-table JOIN + subquery  |  
-- Business: Classify every patient into High / Medium / Low
--           risk based on age, diagnosis, and abnormal lab count.
--           Powers triage dashboards and discharge planning.
-- ============================================================

WITH AbnormalCounts AS (
    SELECT  p.PatientID, COUNT(*) AS AbnormalLabCount
    FROM patients p
    JOIN labs l ON p.PatientID = l.PatientID
    WHERE
        (l.TestName = 'Blood Sugar'    AND (l.Result > 140  OR l.Result < 70 )) OR
        (l.TestName = 'Hemoglobin'     AND (l.Result > 17   OR l.Result < 12 )) OR
        (l.TestName = 'Cholesterol'    AND  l.Result > 200) OR
        (l.TestName = 'Blood Pressure' AND (l.Result > 120  OR l.Result < 60 )) OR
        (l.TestName = 'Creatinine'     AND (l.Result > 1.2  OR l.Result < 0.6)) OR
        (l.TestName = 'Vitamin D'      AND (l.Result > 50   OR l.Result < 20 ))
    GROUP BY p.PatientID
),
FinalData AS (
    SELECT p.PatientID, p.Name, p.Age, p.Gender, d.DiagnosisName, o.OutcomeName,COALESCE(ac.AbnormalLabCount, 0) AS AbnormalLabCount,
        CASE
            WHEN p.Age >= 60
                 AND o.OutcomeName IN ('Complicated','Deceased')
                 AND COALESCE(ac.AbnormalLabCount, 0) >= 3
                THEN 'High Risk'
            WHEN p.Age >= 45
                 OR COALESCE(ac.AbnormalLabCount, 0) >= 2
                 OR o.OutcomeName = 'Complicated'
                THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS RiskTier

    FROM patients  p
    JOIN diagnoses d  ON p.DiagnosisID = d.DiagnosisID
    JOIN outcomes  o  ON p.OutcomeID   = o.OutcomeID
    Left JOIN AbnormalCounts ac ON p.PatientID = ac.PatientID
)
SELECT * FROM FinalData order by RiskTier; -- sorded alphabetically
--ORDER BY
  --  CASE
    --    WHEN RiskTier = 'High Risk'   THEN 1  -- sorted degree/ number wise
      --  WHEN RiskTier = 'Medium Risk' THEN 2
        --ELSE 3
    --END,
   -- Age DESC;


-- ============================================================
-- Q10  Doctor Performance Summary
-- Concept : JOIN + GROUP BY + Multiple Aggregates  |  
-- Business: Which doctors handle the most patients, generate
--           the most revenue, and have the best recovery rates?
--           Used for performance reviews and resource planning.
-- ============================================================
SELECT doc.DoctorID, doc.DoctorName, doc.Specialty, dept.DepartmentName, doc.ExperienceYears,
    COUNT(p.PatientID)                                             AS TotalPatients, 
    SUM(p.TreatmentCost)                                           AS TotalRevenueGenerated, 
    ROUND(AVG(p.TreatmentCost), 0)                                 AS AvgCostPerPatient,     
    COUNT(CASE WHEN p.OutcomeID = 1 THEN 1 END) AS Recovered,
    COUNT(CASE WHEN p.OutcomeID = 2 THEN 1 END) AS Complicated,
    COUNT(CASE WHEN p.OutcomeID = 3 THEN 1 END) AS Deceased,
--OR--    SUM(CASE WHEN p.OutcomeID = 1   THEN 1 ELSE 0 END) AS Recovered,
--OR--    SUM(CASE WHEN o.OutcomeName = 'Complicated' THEN 1 ELSE 0 END) AS Complicated,
--OR--    SUM(CASE WHEN o.OutcomeName = 'Deceased'    THEN 1 ELSE 0 END) AS Deceased,    
    ROUND(SUM(CASE WHEN o.OutcomeName = 'Recovered' THEN 1.0 ELSE 0 END) / COUNT(p.PatientID) * 100, 1) AS RecoveryRatePercent
FROM doctors doc
JOIN departments dept ON doc.DepartmentID  = dept.DepartmentID
LEFT JOIN patients   p    ON doc.DoctorID      = p.DoctorID
LEFT JOIN outcomes   o    ON p.OutcomeID       = o.OutcomeID
GROUP BY doc.DoctorID, doc.DoctorName, doc.Specialty, dept.DepartmentName, doc.ExperienceYears
ORDER BY RecoveryRatePercent DESC;
--ORDER BY TotalRevenueGenerated DESC;


-- ============================================================
-- Q11  Department-wise Cost & Outcome Analysis
-- Concept : JOIN + GROUP BY + CASE WHEN aggregation  | 
-- Business: Compare cost efficiency and patient outcomes
--           across hospital departments.
-- ============================================================

SELECT dept.DepartmentName, COUNT(distinct doc.DoctorID)TotalDoctors, COUNT(p.PatientID)TotalPatients,
    SUM(p.TreatmentCost)TotalCost,  ROUND(AVG(p.TreatmentCost), 0)AvgCost,
    ROUND( SUM(CASE WHEN o.OutcomeName = 'Recovered' THEN 1.0 ELSE 0 END) / COUNT(p.PatientID) * 100, 1 )  AS RecoveryRatePercent,
    ROUND(SUM(CASE WHEN o.OutcomeName = 'Deceased' THEN 1.0 ELSE 0 END)  / COUNT(p.PatientID) * 100, 1)  AS MortalityRatePercent
FROM departments dept
JOIN doctors     doc  ON dept.DepartmentID = doc.DepartmentID
JOIN patients    p    ON doc.DoctorID      = p.DoctorID
JOIN outcomes    o    ON p.OutcomeID       = o.OutcomeID
GROUP BY dept.DepartmentName
ORDER BY RecoveryRatePercent DESC;


-- ============================================================
-- Q12  Monthly Admission Trends
-- Concept : DATE functions + GROUP BY + Window Function  
-- Business: How many patients were admitted each month?
--           Month-over-month growth helps capacity planning.
-- ============================================================

WITH MonthlyAdmissions AS (
    SELECT CONVERT(VARCHAR(7), AdmissionDate, 120)AdmissionMonth, COUNT(*)TotalAdmissions, SUM(TreatmentCost)MonthlyRevenue,
           ROUND(AVG(TreatmentCost), 0) MontlyAvgCost
    FROM patients
    GROUP BY CONVERT(VARCHAR(7), AdmissionDate, 120)
 )
SELECT AdmissionMonth, TotalAdmissions, MonthlyRevenue, MontlyAvgCost,
    LAG(TotalAdmissions) OVER (ORDER BY AdmissionMonth) AS PrevMonthAdmissions,
    TotalAdmissions - LAG(TotalAdmissions) OVER (ORDER BY AdmissionMonth) AS MoMChange,
    SUM(TotalAdmissions) OVER (ORDER BY AdmissionMonth)       AS CumulativeAdmissions
FROM MonthlyAdmissions
ORDER BY AdmissionMonth;


-- ============================================================
-- Q13  Average Length of Stay by Diagnosis
-- Concept : DATEDIFF + GROUP BY + ORDER BY  |  
-- Business: Which conditions keep patients hospitalised longest?
--           Helps in bed management and staffing decisions.
-- ============================================================

SELECT
    d.DiagnosisName,
    COUNT(p.PatientID)                                             AS TotalPatients,
    AVG(DATEDIFF(DAY, p.AdmissionDate, p.DischargeDate))           AS AvgLengthOfStayDays,
    MIN(DATEDIFF(DAY,  p.AdmissionDate, p.DischargeDate))          AS MinStay,
    MAX(DATEDIFF(DAY,  p.AdmissionDate, p.DischargeDate))          AS MaxStay,
    ROUND(AVG(p.TreatmentCost), 2)                                 AS AvgCost
FROM patients  p
JOIN diagnoses d ON p.DiagnosisID = d.DiagnosisID
GROUP BY d.DiagnosisName
ORDER BY AvgLengthOfStayDays DESC;


---- for practice purpose, changed few max stay values in patients2 table, as b4 the max stay and avg values were same---- ----
select * from patients2; 
SELECT
    d.DiagnosisName,
    COUNT(pp.PatientID)                                             AS TotalPatients,
    AVG(DATEDIFF(DAY, pp.AdmissionDate, pp.DischargeDate))           AS AvgLengthOfStayDays,
    MIN(DATEDIFF(DAY,  pp.AdmissionDate, pp.DischargeDate))          AS MinStay,
    MAX(DATEDIFF(DAY,  pp.AdmissionDate, pp.DischargeDate))          AS MaxStay,
    ROUND(AVG(pp.TreatmentCost), 2)                                 AS AvgCost
FROM patients2  pp
JOIN diagnoses d ON pp.DiagnosisID = d.DiagnosisID
GROUP BY d.DiagnosisName
ORDER BY AvgLengthOfStayDays DESC;


-- ============================================================
-- Q14  Running Total of Revenue Over Time
-- Concept : SUM() OVER (ORDER BY) — Cumulative window  |  
-- Business: Track cumulative hospital revenue across the year
--           to monitor financial targets and seasonal patterns.
-- ============================================================

WITH DailyRevenue AS (
    SELECT
        AdmissionDate,
        SUM(TreatmentCost) AS DailyRevenue
    FROM patients
    GROUP BY AdmissionDate
)
SELECT
    AdmissionDate,
    DailyRevenue,
    SUM(DailyRevenue) OVER (ORDER BY AdmissionDate)              AS CumulativeRevenue,
    AVG(DailyRevenue) OVER (
        ORDER BY AdmissionDate
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)                AS Rolling7DayAvgRevenue
FROM DailyRevenue
ORDER BY AdmissionDate;


-- ============================================================
-- Q15  Top 3 Costliest Patients per Diagnosis
-- Concept : ROW_NUMBER() OVER (PARTITION BY)  |  
-- Business: Identify the highest-spend patients within each
--           disease group for insurance and billing review.
-- ============================================================

WITH RankedPatients AS (
    SELECT p.PatientID,  p.Name,  p.Age, d.DiagnosisName,  o.OutcomeName,  p.TreatmentCost,
        ROW_NUMBER() OVER (
            PARTITION BY d.DiagnosisName
            ORDER BY p.TreatmentCost DESC
        ) AS CostRank
    FROM patients  p
    JOIN diagnoses d ON p.DiagnosisID = d.DiagnosisID
    JOIN outcomes  o ON p.OutcomeID   = o.OutcomeID
)
SELECT DiagnosisName, CostRank, PatientID, Name, Age, OutcomeName, TreatmentCost
FROM RankedPatients
WHERE CostRank <= 3
ORDER BY DiagnosisName;
---- or --- its same-------
--ORDER BY DiagnosisName, CostRank;


-- ============================================================
-- Q16  Lab Result Trend per Patient  (LEAD & LAG)
-- Concept : LAG() OVER (PARTITION BY)  |  
-- Business: For each patient's blood sugar readings, show how
--           results changed between consecutive test sessions.
--           Flags improving vs deteriorating patients.
-- ============================================================

SELECT  p.PatientID, p.Name, d.DiagnosisName, l.TestName, l.TestDate, l.Result AS CurrentResult,
    LAG(l.Result) OVER ( PARTITION BY p.PatientID, l.TestName ORDER BY l.TestDate )  AS PreviousResult,
    ROUND(l.Result - LAG(l.Result) OVER ( PARTITION BY p.PatientID, l.TestName ORDER BY l.TestDate), 2)    AS Change,
    CASE
       WHEN l.Result > LAG(l.Result) OVER (
                PARTITION BY p.PatientID, l.TestName ORDER BY l.TestDate) THEN 'Worsening'
        WHEN l.Result < LAG(l.Result) OVER (
                PARTITION BY p.PatientID, l.TestName ORDER BY l.TestDate) THEN 'Improving'
        ELSE 'Stable'
    END AS Trend
FROM labs      l
JOIN patients  p ON l.PatientID   = p.PatientID
JOIN diagnoses d ON p.DiagnosisID = d.DiagnosisID
WHERE l.TestName = 'Blood Sugar'
ORDER BY p.PatientID, l.TestDate;

------------or --- dont include l.testName in every LAG function, still results same------
SELECT  p.PatientID, p.Name, d.DiagnosisName, l.TestName, l.TestDate, l.Result AS CurrentResult,
    LAG(l.Result) OVER ( PARTITION BY p.PatientID  ORDER BY l.TestDate )  AS PreviousResult,
    ROUND(l.Result - LAG(l.Result) OVER ( PARTITION BY p.PatientID ORDER BY l.TestDate), 2)    AS Change,
    CASE
       WHEN l.Result > LAG(l.Result) OVER (
                PARTITION BY p.PatientID oRDER BY l.TestDate) THEN 'Worsening'
        WHEN l.Result < LAG(l.Result) OVER (
                PARTITION BY p.PatientID ORDER BY l.TestDate) THEN 'Improving'
        ELSE 'Stable'
    END AS Trend
FROM labs      l
JOIN patients  p ON l.PatientID   = p.PatientID
JOIN diagnoses d ON p.DiagnosisID = d.DiagnosisID
WHERE l.TestName = 'Blood Sugar'
ORDER BY p.PatientID, l.TestDate;



-- ============================================================
-- Q17  Patient Cost Percentile Ranking  (NTILE & PERCENT_RANK)
-- Concept : NTILE + PERCENT_RANK window functions  | 
-- Business: Segment patients into cost quartiles and find each
--           patient's relative cost rank across the full dataset.
--           Used for insurance tier classification.
-- ============================================================

SELECT p.PatientID, p.Name, p.Age, d.DiagnosisName, p.TreatmentCost, NTILE(4) OVER (ORDER BY p.TreatmentCost)  AS CostQuartile,
    ROUND( PERCENT_RANK() OVER (ORDER BY p.TreatmentCost) * 100, 1)  AS CostPercentile,
    CASE NTILE(4) OVER (ORDER BY p.TreatmentCost)
        WHEN 1 THEN 'Low Cost (Q1)'
        WHEN 2 THEN 'Below Average (Q2)'
        WHEN 3 THEN 'Above Average (Q3)'
        WHEN 4 THEN 'High Cost (Q4)'
    END AS CostSegment
FROM patients  p
JOIN diagnoses d ON p.DiagnosisID = d.DiagnosisID
ORDER BY p.TreatmentCost DESC;


-- ============================================================
-- Q18  Subquery — Patients Treated by Experienced Doctors
-- Concept : Subquery (IN) + Scalar subquery  |  
-- Business: Find patients treated by doctors with above-average
--           experience. Are outcomes better with senior doctors?
-- ============================================================

SELECT p.PatientID, p.Name, p.Age, d.DiagnosisName, doc.DoctorName, doc.ExperienceYears, o.OutcomeName,  p.TreatmentCost,
 -- Scalar subquery: show the avg experience inline for reference
(SELECT ROUND(AVG(ExperienceYears), 1) FROM doctors) AS AvgDoctorExperience
FROM patients  p
JOIN diagnoses d   ON p.DiagnosisID = d.DiagnosisID
JOIN doctors   doc ON p.DoctorID    = doc.DoctorID
JOIN outcomes  o   ON p.OutcomeID   = o.OutcomeID
WHERE p.DoctorID IN (
    SELECT DoctorID
    FROM doctors
    WHERE ExperienceYears > (SELECT AVG(ExperienceYears) FROM doctors)
)
ORDER BY doc.ExperienceYears DESC, p.TreatmentCost DESC;

