# 🏥 Healthcare Data Analytics — End-to-End Learning Project

> A hands-on data analytics learning journey built around a real-world healthcare dataset —
> covering SQL, Excel, Python (Pandas · NumPy · Scikit-learn) and a deployed ML prediction app with 4 different Machine learing models.
> Here is the Link for the project's output recording -
> <img width="2084" height="888" alt="model_comparison" src="https://github.com/user-attachments/assets/dfc69aba-0416-419c-8f02-3bd4aa55f0ad" />

---

## 👤 About This Project

This project documents my **self-driven learning journey** into data analytics, built around a single coherent healthcare dataset that I designed, populated, and analysed across three tools — SQL, Excel, and Python. Rather than following isolated tutorials, every tool was applied to the same dataset, so each layer of learning built directly on the previous one.

**Learning path followed:**
```
Excel (data profiling & pivot analysis)
    ↓
SQL (structured querying, 18 queries)
    ↓
Python (Pandas EDA + NumPy + Scikit-learn ML model + Streamlit app)
```

---

## 📁 Repository Structure

```
healthcare-analytics/
│
├── 📂 SQL/
│   ├── healthcare_db_v2.sql          # Full schema + seed data (6 tables, 12,000+ rows)
│   └── healthcare_queries_v2.sql     # 18 analyst queries (Beginner → Advanced)
│
├── 📂 Excel/
│   └── healthcare_db_v2.xlsx         # All 6 tables as formatted sheets with pivot analysis
│
├── 📂 Python/
│   ├── Risk-Model.ipynb              # v1 — EDA + Logistic Regression + model saved as pkl
│   ├── Risk_Model2.ipynb             # v2 — 4 ML models + visualisations + model export
│   ├── risk_model_app.py             # Production Streamlit app (loads pre-trained models)
│   ├── 📂 models/                    # Pre-trained model files saved from Risk_Model2.ipynb
│   │   ├── rf_model.pkl              # Random Forest
│   │   ├── knn_model.pkl             # K-Nearest Neighbours
│   │   ├── dt_model.pkl              # Decision Tree
│   │   ├── nb_model.pkl              # Naive Bayes
│   │   ├── scaler.pkl                # StandardScaler (fitted on training data)
│   │   ├── label_encoder_diagnosis.pkl
│   │   └── model_metadata.pkl        # Accuracy, AUC, confusion matrix, ROC data for all 4 models
│   ├── Patients.csv                  # 1,000 patient records
│   ├── Doctors.csv                   # 20 doctors with performance metrics
│   ├── Departments.csv               # 9 hospital departments
│   ├── Diagnoses.csv                 # 10 disease categories
│   ├── Outcomes.csv                  # 3 outcome types
│   └── Labs.csv                      # 11,147 lab test records (time-series)
│
└── README.md
```

---

## 🗄️ The Dataset

A synthetic but clinically realistic hospital dataset designed from scratch to support multi-tool analysis.

### Schema (6 tables, relational design)

```
departments ──< doctors ──< patients >── diagnoses
                                │
                            outcomes
                                │
                              labs  (time-series: 3–11 tests per patient)
```

| Table | Rows | Key columns |
|---|---|---|
| `patients` | 1,000 | PatientID, Age, Gender, DiagnosisID, DoctorID, AdmissionDate, DischargeDate, OutcomeID, TreatmentCost |
| `labs` | 11,147 | LabID, PatientID, TestName, Result, NormalRange, **TestDate** |
| `doctors` | 20 | DoctorID, DoctorName, Specialty, DepartmentID, ExperienceYears |
| `departments` | 9 | DepartmentID, DepartmentName |
| `diagnoses` | 10 | DiagnosisID, DiagnosisName |
| `outcomes` | 3 | OutcomeID, OutcomeName (Recovered / Complicated / Deceased) |

**Lab tests tracked:** Blood Sugar · Blood Pressure · Hemoglobin · Cholesterol · Creatinine · Vitamin D

**Design decisions made:**
- Labs table was given a `TestDate` column so time-series trend queries are actually meaningful
- Lab results are skewed by diagnosis (e.g. Kidney Disease patients have elevated Creatinine, Diabetic patients have high Blood Sugar) — not purely random
- Each patient has 3–11 lab records spread across their admission stay, enabling genuine trend analysis
- `DoctorID` was added as a foreign key in `patients` to enable doctor performance analysis

---

## 🗃️ Part 1 — SQL (Microsoft SQL Server)

**File:** `healthcare_queries_v2.sql`

18 queries written progressively from beginner to advanced, each with a business context comment explaining *why* that query would be run in a real hospital analytics team.

### Query Index

| # | Query | SQL Concepts Used | Business Question |
|---|---|---|---|
| Q1 | Patient Lab History | 5-table JOIN | Full patient profile with doctor, diagnosis, labs in one view |
| Q2 | Avg Lab by Diagnosis | JOIN + GROUP BY + AVG | Which disease group has highest average biomarker? |
| Q3 | Abnormal Lab Patients | Conditional WHERE + HAVING | Which patients have the most out-of-range test results? |
| Q4 | Treatment Cost by Diagnosis | SUM + MIN + MAX + AVG | Where is the hospital spending the most? |
| Q5 | Disease Prevalence | COUNT + Window % of total | Which conditions are most common? |
| Q6 | High-Risk Patient Filter | Multi-condition WHERE | Elderly male patients who did not recover |
| Q7 | Lab Trends Over Time | JOIN + ORDER BY date | How do biomarkers change during hospital stay? |
| Q8a | Outcome Distribution | GROUP BY + COUNT | Which diagnoses lead most often to death? |
| Q8b | Outcome Distribution (alt) | COUNT() OVER (PARTITION BY) | Same result, window function approach |
| Q9 | Patient Risk Tier | CASE WHEN + CTE + LEFT JOIN | Classify patients: High / Medium / Low risk |
| Q10 | Doctor Performance | Multi-aggregate + CASE WHEN | Recovery rate, revenue, patient load per doctor |
| Q11 | Department Analysis | GROUP BY + conditional agg | Cost efficiency and mortality rate by department |
| Q12 | Monthly Admission Trends | DATE functions + LAG + cumulative | Month-over-month admissions and revenue growth |
| Q13 | Length of Stay by Diagnosis | DATEDIFF + GROUP BY | Which conditions keep patients longest? |
| Q14 | Running Revenue Total | SUM OVER + 7-day rolling AVG | Cumulative revenue and smoothed daily trends |
| Q15 | Top 3 Costliest per Diagnosis | ROW_NUMBER() OVER (PARTITION BY) | Highest-spend patients per disease group |
| Q16 | Lab Result Trend (LAG) | LAG() OVER (PARTITION BY) | Is each patient's Blood Sugar improving or worsening? |
| Q17 | Cost Percentile Ranking | NTILE + PERCENT_RANK | Segment patients into cost quartiles for billing |
| Q18 | Experienced Doctor Patients | Nested subquery + scalar subquery | Do senior doctors achieve better outcomes? |

### SQL Concepts Covered

```
Beginner          →  SELECT, WHERE, GROUP BY, HAVING, ORDER BY, multi-table JOINs
Intermediate      →  CASE WHEN, CTEs (WITH), DATEDIFF, DATE_FORMAT
Window Functions  →  ROW_NUMBER, RANK, LAG, LEAD, SUM OVER, AVG OVER,
                     NTILE, PERCENT_RANK, COUNT OVER (PARTITION BY)
Subqueries        →  Correlated subqueries, scalar subqueries, IN (subquery)
```

### Notable Query: Q9 — Patient Risk Tier (CASE WHEN + CTE chain)

```sql
WITH AbnormalCounts AS (
    SELECT p.PatientID, COUNT(*) AS AbnormalLabCount
    FROM patients p
    JOIN labs l ON p.PatientID = l.PatientID
    WHERE
        (l.TestName = 'Blood Sugar'    AND (l.Result > 140 OR l.Result < 70)) OR
        (l.TestName = 'Creatinine'     AND (l.Result > 1.2 OR l.Result < 0.6)) OR
        -- ... other thresholds
    GROUP BY p.PatientID
)
SELECT p.Name, p.Age,
    CASE
        WHEN p.Age >= 60 AND o.OutcomeName IN ('Complicated','Deceased')
             AND COALESCE(ac.AbnormalLabCount, 0) >= 3 THEN 'High Risk'
        WHEN p.Age >= 45 OR COALESCE(ac.AbnormalLabCount, 0) >= 2  THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS RiskTier
FROM patients p
LEFT JOIN AbnormalCounts ac ON p.PatientID = ac.PatientID
...
```

---

## 📊 Part 2 — Excel

**File:** `healthcare_db_v2.xlsx`

All 6 database tables exported into a formatted Excel workbook, used for data verification, pivot analysis, and presenting results to non-technical stakeholders.

### Workbook Structure

| Sheet | Contents |
|---|---|
| 📋 Overview | Table index, row counts, schema relationships diagram |
| 👥 Patients | 1,000 rows · TreatmentCost formatted as currency · auto-filter |
| 👨‍⚕️ Doctors | 20 rows · includes performance metrics (total patients, revenue, avg cost) |
| 🏥 Departments | 9 hospital departments |
| 🦠 Diagnoses | 10 disease categories |
| ✅ Outcomes | 3 outcome types |
| 🧪 Labs | 11,147 rows · TestDate column · Result to 1 decimal · auto-filter |
------
| 📋 DA | Formula index — all 12 analysis queries documented with exact formula used | — |
| 📋 DA_on_Patients | Main analysis sheet — 1,000 rows with 10 computed columns applied live | 1,000 |
| 📊 patient-pivot1 | Pivot: patient count, total cost, total age — grouped by outcome | — |
| 📊 patient-pivot2 | Pivot: individual treatment cost per patient — filtered by age 20–23 | — |


## 🔬 Data Analysis — Formula Index (`DA` sheet)

The `DA` sheet acts as a personal query log — 12 analysis operations, each documented with the business question, the sheet it was applied to, and the exact Excel formula. All formulas were then applied live across all 1,000 rows in the `DA_on_Patients` sheet, producing **10 new computed columns** alongside the original patient data. Also few Excel functions on Doctors, Diagnoses and Department table/sheet.

### 1. Lookup & Join Operations — VLOOKUP across sheets
### 2. Date Calculation — DATEDIF
### 3. Lab Test Flag — IF + VLOOKUP combined
### 4. Risk Flag — IF + OR
### 5. Patient Severity Score — Nested IF (3 levels deep)
### 6. Cost Ranking — RANK.EQ and RANK.AVG
### 7. Patient Count per Diagnosis — COUNTIF (cross-sheet)
### 8. Revenue per Doctor — SUMIF + SUMIF/COUNTIF (cross-sheet)
### 9. Weighted Risk Score with SUMPRODUCT 
### 10. Doctor's Name with the most experience using INDEX MATCH (INDEX + MATCH)
### Pivot 1 — `patient-pivot1`: Outcome Summary
### Pivot 2 — `patient-pivot2`: Young Patient Cost Breakdown


---

## 🐍 Part 3 — Python (Jupyter + Streamlit)

**Files:** `Risk-Model.ipynb` · `Risk_Model2.ipynb` · `risk_model_app.py` · `models/`

An end-to-end machine learning pipeline that takes the same healthcare dataset from SQL/Excel, trains multiple **Patient Risk Prediction models**, and deploys them as a production-ready interactive web app.

---

### v1 — Logistic Regression (`Risk-Model.ipynb`)

The first notebook established the full pipeline: data loading, merging, feature engineering, model training, evaluation, and saving the model as a `.pkl` file.

#### Features used (4)
`Age` · `LengthOfStay` · `TreatmentCost` · `AbnormalLabCount`

#### Steps
**Step 1 — Load & Merge Data** — 6 CSVs loaded and joined using Pandas (equivalent to SQL multi-table JOINs)

**Step 2 — Feature Engineering**
- `LengthOfStay` — calculated from AdmissionDate / DischargeDate (equivalent to SQL `DATEDIFF`)
- `HighRisk` flag — built using `np.where()` (equivalent to SQL `CASE WHEN`)
- `AbnormalLabCount` — per-patient count of out-of-range lab results

**Step 3 — Model Training** — Logistic Regression via Scikit-learn with 80/20 train/test split

**Step 4 — Model Evaluation** — Accuracy score, classification report, confusion matrix, ROC curve

**Step 5 — Save Model**
```python
import joblib
joblib.dump(model, 'Risk_Model.pkl')
```

---

### v2 — Four ML Models (`Risk_Model2.ipynb`)

The second notebook expanded the feature set and trained four classification models, each followed by dedicated visualisations, before saving all trained models for use by the Streamlit app.

#### Extended feature set (7)
`Age` · `LengthOfStay` · `TreatmentCost` · `AbnormalLabCount` · `GenderEncoded` · `DiagnosisEncoded` 

#### Models trained & results

| Model | Accuracy | Key visualisation |
|---|---|---|
| Random Forest | 75.0% | Feature importance bar chart |
| KNN | 81.0% 🏆 | K vs CV Accuracy curve (best k selected via cross-validation) |
| Decision Tree | 70.0% | Full tree diagram (max_depth=6) |
| Naive Bayes | 77.5% | Predicted probability distribution |

Each model produced: **Confusion Matrix** · **ROC Curve** · **model-specific plot**

#### KNN — best k selection via cross-validation
Rather than guessing k, the notebook finds the optimal value automatically:
```python
k_range  = range(9, 90)
k_scores = []
for k in k_range:
    cv_scores = cross_val_score(KNeighborsClassifier(n_neighbors=k),
                                X_train_sc, y_train, cv=5, scoring='accuracy')
    k_scores.append(cv_scores.mean())
best_k = k_range[k_scores.index(max(k_scores))]
```
`cross_val_score` with `cv=5` splits the training data into 5 folds, trains and tests on each fold in turn, and returns 5 accuracy scores whose mean is used to compare k values — ensuring `best_k` is chosen without ever touching the test set.

#### Save all models at the end of the notebook
```python
import joblib, os
os.makedirs('models', exist_ok=True)

joblib.dump(rf_model,  'models/rf_model.pkl')
joblib.dump(knn_model, 'models/knn_model.pkl')
joblib.dump(dt_model,  'models/dt_model.pkl')
joblib.dump(nb_model,  'models/nb_model.pkl')
joblib.dump(scaler,    'models/scaler.pkl')
joblib.dump(diag_le,   'models/label_encoder_diagnosis.pkl')
joblib.dump(metadata,  'models/model_metadata.pkl')
```
`metadata` stores accuracy, confusion matrix, ROC curve data, AUC scores and feature importances for all 4 models — everything the Streamlit dashboard needs to display without retraining.

---

### Production Streamlit App (`risk_model_app.py`)

The app **never trains any model**. It only loads the pre-trained `.pkl` files saved by `Risk_Model2.ipynb`, which guarantees results are always in sync with the notebook.

```
Risk_Model2.ipynb                    risk_model_app.py
─────────────────                    ─────────────────
Train 4 models                       joblib.load('models/rf_model.pkl')
      ↓                              joblib.load('models/knn_model.pkl')
joblib.dump → models/*.pkl    →→→    joblib.load('models/metadata.pkl')
                                           ↓
                                     Serve predictions instantly ✅
```

#### App features — 3 tabs

**🔮 Tab 1 — Predict Patient Risk**
- 7 patient input fields: Age, Length of Stay, Treatment Cost, Abnormal Lab Count, Gender, Diagnosis, Doctor Experience
- Model selector in the sidebar — switch between all 4 models instantly
- Result card: High Risk 🚨 / Low Risk ✅ with probability %
- Risk gauge bar chart showing probability vs 0.5 decision threshold
- Automatic risk flag warnings (e.g. Age > 65, LOS > 7 days)
- All-models quick view — see what all 4 models predict for the same patient simultaneously

**📊 Tab 2 — Model Performance**
- Per-model accuracy, precision, recall, F1 score metric cards
- Confusion matrix heatmap + ROC curve side by side
- Model-specific bonus plot (Feature Importance / K vs Accuracy / Decision Tree diagram / Probability Distribution)

**📈 Tab 3 — Model Comparison**
- Accuracy bar chart across all 4 models
- Overlaid ROC curves with AUC scores
- Summary table sorted by accuracy with best model highlighted

#### To run the app

```bash
# Step 1 — run the last cell in Risk_Model2.ipynb to save models (once)
# Step 2 — launch the app
streamlit run risk_model_app.py
```

---

## 🔗 How the Three Tools Connect

The same business questions were answered in all three tools — this shows tool versatility, not three isolated exercises:

| Business Question | SQL Query | Excel | Python |
|---|---|---|---|
| Abnormal lab patients | Q3 — WHERE + HAVING | Filter + conditional format | `abnormal_conditions` dict + `count_abnormal_labs()` |
| Patient risk classification | Q9 — CASE WHEN + CTE | Pivot table by risk group | `np.where()` → `HighRisk` column → ML target |
| Doctor performance | Q10 — GROUP BY + CASE WHEN | Doctors sheet with revenue metrics | `merge()` + `groupby()` |
| Monthly trends | Q12 — LAG + cumulative SUM | Line chart from Patients sheet | `.dt.to_period('M')` + `groupby()` |
| Lab result trends | Q16 — LAG() OVER (PARTITION BY) | Sort by date per patient | `.shift()` + `pct_change()` |
| Cost segmentation | Q17 — NTILE + PERCENT_RANK | Sort by TreatmentCost | `.rank()` + `pd.qcut()` |

---

## 🛠️ Tech Stack

| Tool | Version | Purpose |
|---|---|---|
| Microsoft SQL Server | 2022 | Schema design, all 18 SQL queries |
| Python | 3.x | Data analysis and ML |
| Pandas | Latest | Data loading, merging, EDA |
| NumPy | Latest | Vectorised operations, np.where |
| Scikit-learn | Latest | Logistic Regression, Random Forest, KNN, Decision Tree, Naive Bayes |
| Joblib | Latest | Model serialisation (.pkl) |
| Matplotlib / Seaborn | Latest | Confusion matrix, ROC curves, feature importance, tree diagrams |
| Streamlit | Latest | Production interactive prediction web app |
| Jupyter Notebook | Latest | EDA and model development |
| Microsoft Excel | Office 365 | Data validation, pivot analysis |

---


## 📬 Contact

**Hiteshi Aglawe**
*Aspiring Data Analyst · SQL · Python · Excel · Power BI*

---

*This project was built as a learning exercise to develop and demonstrate practical data analytics skills. All patient data is entirely synthetic.*
