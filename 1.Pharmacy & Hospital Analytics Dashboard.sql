CREATE DATABASE pharmacy_analytics_mini;
USE pharmacy_analytics_mini;
SELECT DATABASE();


-- Hospitals
CREATE TABLE Hospitals (
    Hospital_ID VARCHAR(100) PRIMARY KEY,
    Hospital_Name VARCHAR(150),
    Hospital_Type VARCHAR(100),
    State VARCHAR(100),
    City VARCHAR(100),
    Total_Beds INT
);

-- Departments
CREATE TABLE Departments (
    Department_ID VARCHAR(100) PRIMARY KEY,
    Department_Name VARCHAR(150),
    Department_Type VARCHAR(100)
);

-- Doctors
CREATE TABLE Doctors (
    Doctor_ID VARCHAR(100) PRIMARY KEY,
    Doctor_Name VARCHAR(150),
    Specialization VARCHAR(100),
    Department_ID VARCHAR(100),
    Hospital_ID VARCHAR(100),
    Experience_Years INT,
    Consultation_Fee INT
);

-- Staff
CREATE TABLE Staff (
    Staff_ID VARCHAR(100) PRIMARY KEY,
    Staff_Name VARCHAR(150),
    Role VARCHAR(100),
    Department_ID VARCHAR(100),
    Hospital_ID VARCHAR(100),
    Joining_Date DATE,
    Monthly_Salary INT
);

-- Patients
CREATE TABLE Patients (
    Patient_ID VARCHAR(100) PRIMARY KEY,
    Patient_Name VARCHAR(150),
    Gender VARCHAR(50),
    Age INT,
    State VARCHAR(100),
    City VARCHAR(100),
    Insurance_Type VARCHAR(100),
    Registration_Date DATE
);

-- Medicines
CREATE TABLE Medicines (
    Medicine_ID VARCHAR(100) PRIMARY KEY,
    Medicine_Name VARCHAR(150),
    Generic_Name VARCHAR(150),
    Category VARCHAR(100),
    Manufacturer VARCHAR(150),
    Unit_Cost DECIMAL(14,2),
    Selling_Price DECIMAL(14,2)
);

-- Vendors
CREATE TABLE Vendors (
    Vendor_ID VARCHAR(100) PRIMARY KEY,
    Vendor_Name VARCHAR(150),
    State VARCHAR(100),
    Rating DECIMAL(3,1)
);

-- Admissions
CREATE TABLE Admissions (
    Admission_ID VARCHAR(100) PRIMARY KEY,
    Patient_ID VARCHAR(100),
    Doctor_ID VARCHAR(100),
    Hospital_ID VARCHAR(100),
    Department_ID VARCHAR(100),
    Admission_Date DATE,
    Admission_Type VARCHAR(100),
    Diagnosis VARCHAR(150),
    Length_of_Stay INT,
    Discharge_Date DATE,
    Admission_Status VARCHAR(100)
);

-- Appointments
CREATE TABLE Appointments (
    Appointment_ID VARCHAR(100) PRIMARY KEY,
    Patient_ID VARCHAR(100),
    Doctor_ID VARCHAR(100),
    Department_ID VARCHAR(100),
    Hospital_ID VARCHAR(100),
    Appointment_Date DATE,
    Appointment_Type VARCHAR(100),
    Status VARCHAR(100),
    Consultation_Fee INT
);

-- Billing
CREATE TABLE Billing (
    Bill_ID VARCHAR(100) PRIMARY KEY,
    Patient_ID VARCHAR(100),
    Admission_ID VARCHAR(100),
    Hospital_ID VARCHAR(100),
    Department_ID VARCHAR(100),
    Bill_Date DATE,
    Service_Type VARCHAR(100),
    Quantity INT,
    Payment_Mode VARCHAR(100),
    Payment_Status VARCHAR(100),
    Unit_Price DECIMAL(14,2),
    Sales DECIMAL(14,2),
    Discount DECIMAL(14,2),
    Net_Sales DECIMAL(14,2),
    Target DECIMAL(14,2),
    Profit DECIMAL(14,2)
);

-- Lab-Tests
CREATE TABLE Lab_Tests (
    Lab_ID VARCHAR(100) PRIMARY KEY,
    Patient_ID VARCHAR(100),
    Hospital_ID VARCHAR(100),
    Department_ID VARCHAR(100),
    Test_Date DATE,
    Test_Name VARCHAR(150),
    Result_Status VARCHAR(100),
    Test_Cost DECIMAL(14,2)
);

-- Prescriptions
CREATE TABLE Prescriptions (
    Prescription_ID VARCHAR(100) PRIMARY KEY,
    Patient_ID VARCHAR(100),
    Doctor_ID VARCHAR(100),
    Hospital_ID VARCHAR(100),
    Department_ID VARCHAR(100),
    Medicine_ID VARCHAR(100),
    Prescription_Date DATE,
    Quantity INT,
    Dosage_Days INT,
    Prescription_Status VARCHAR(100),
    Selling_Price DECIMAL(14,2),
    Unit_Cost DECIMAL(14,2),
    Sales DECIMAL(14,2),
    Cost DECIMAL(14,2),
    Profit DECIMAL(14,2)
);

-- Inventory
CREATE TABLE Inventory (
    Inventory_ID VARCHAR(100) PRIMARY KEY,
    Hospital_ID VARCHAR(100),
    Medicine_ID VARCHAR(100),
    Vendor_ID VARCHAR(100),
    Transaction_Date DATE,
    Transaction_Type VARCHAR(100),
    Quantity INT,
    Unit_Cost DECIMAL(14,2),
    Selling_Price DECIMAL(14,2),
    Purchase_Value DECIMAL(14,2),
    Sales_Value DECIMAL(14,2)
);

-- Dim date

CREATE TABLE DimDate (
    Date DATE PRIMARY KEY,
    Date_Key INT,
    Year INT,
    Quarter VARCHAR(10),
    Month_Number INT,
    Month_Name VARCHAR(30),
    Month_Short VARCHAR(10),
    `Year_Month` VARCHAR(20),
    Week_Number INT,
    Day INT,
    Day_Name VARCHAR(20),
    Is_Weekend BOOLEAN
);

-- verify tables
show tables;

SELECT COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'pharmacy_analytics_mini';

select * from hospitals;
select * from admissions;

-- Q1. Which hospitals have the highest number of patients?
CREATE OR REPLACE VIEW v_01_hospital_patient_volume AS
SELECT
    h.Hospital_ID,
    h.Hospital_Name,
    COUNT(DISTINCT a.Patient_ID) AS Total_Patients
FROM Hospitals h
JOIN Admissions a
    ON h.Hospital_ID = a.Hospital_ID
GROUP BY
    h.Hospital_ID,
    h.Hospital_Name;

SELECT *
FROM v_01_hospital_patient_volume
ORDER BY Total_Patients DESC;

-- Q2. Which hospitals have the highest number of admissions?
CREATE OR REPLACE VIEW v_02_hospital_admissions AS
SELECT
    h.Hospital_ID,
    h.Hospital_Name,
    COUNT(a.Admission_ID) AS Total_Admissions
FROM Hospitals h
JOIN Admissions a
    ON h.Hospital_ID = a.Hospital_ID
GROUP BY
    h.Hospital_ID,
    h.Hospital_Name;
    
SELECT *
FROM v_02_hospital_admissions
ORDER BY Total_Admissions DESC;

-- Q3. Which hospitals generate the highest revenue?
CREATE OR REPLACE VIEW v_03_hospital_revenue AS
SELECT
    h.Hospital_ID,
    h.Hospital_Name,
    SUM(b.Net_Sales) AS Total_Revenue
FROM Hospitals h
JOIN Billing b
    ON h.Hospital_ID = b.Hospital_ID
GROUP BY
    h.Hospital_ID,
    h.Hospital_Name;
    
SELECT *
FROM v_03_hospital_revenue
ORDER BY Total_Revenue DESC;

-- Q4. Which hospitals generate the highest profit?
CREATE OR REPLACE VIEW v_04_hospital_profit AS
SELECT
    h.Hospital_ID,
    h.Hospital_Name,
    SUM(b.Profit) AS Total_Profit
FROM Hospitals h
JOIN Billing b
    ON h.Hospital_ID = b.Hospital_ID
GROUP BY
    h.Hospital_ID,
    h.Hospital_Name;
    
SELECT *
FROM v_04_hospital_profit
ORDER BY Total_Profit DESC;

-- Q5. How does hospital performance compare with bed capacity?
CREATE OR REPLACE VIEW v_05_hospital_bed_performance AS
SELECT
    h.Hospital_ID,
    h.Hospital_Name,
    h.Total_Beds,
    COUNT(a.Admission_ID) AS Total_Admissions,
    ROUND(
        COUNT(a.Admission_ID) / NULLIF(h.Total_Beds, 0),
        2
    ) AS Admissions_Per_Bed
FROM Hospitals h
LEFT JOIN Admissions a
    ON h.Hospital_ID = a.Hospital_ID
GROUP BY
    h.Hospital_ID,
    h.Hospital_Name,
    h.Total_Beds;
    
SELECT *
FROM v_05_hospital_bed_performance
ORDER BY Admissions_Per_Bed DESC;

-- 

-- Q7. What is the monthly admission trend?
CREATE OR REPLACE VIEW v_07_monthly_admission_trend AS
SELECT
    YEAR(Admission_Date) AS Year,
    MONTH(Admission_Date) AS Month_Number,
    DATE_FORMAT(Admission_Date, '%Y-%m') AS `Year_Month`,
    COUNT(*) AS Total_Admissions
FROM Admissions
GROUP BY
    YEAR(Admission_Date),
    MONTH(Admission_Date),
    DATE_FORMAT(Admission_Date, '%Y-%m');

SELECT *
FROM v_07_monthly_admission_trend
ORDER BY Year, Month_Number;

-- Q8. Which admission types are most common?
CREATE OR REPLACE VIEW v_08_admission_type_distribution AS
SELECT
    Admission_Type,
    COUNT(*) AS Total_Admissions
FROM Admissions
GROUP BY Admission_Type;

SELECT *
FROM v_08_admission_type_distribution
ORDER BY Total_Admissions DESC;

-- Q9. What is the distribution of admission statuses?
CREATE OR REPLACE VIEW v_09_admission_status_distribution AS
SELECT
    Admission_Status,
    COUNT(*) AS Total_Admissions
FROM Admissions
GROUP BY Admission_Status;

SELECT *
FROM v_09_admission_status_distribution
ORDER BY Total_Admissions DESC;

-- Q10. Which diagnoses account for the highest number of admissions?
CREATE OR REPLACE VIEW v_10_diagnosis_admissions AS
SELECT
    Diagnosis,
    COUNT(*) AS Total_Admissions
FROM Admissions
GROUP BY Diagnosis;

SELECT *
FROM v_10_diagnosis_admissions
ORDER BY Total_Admissions DESC;

-- Q11. Which hospitals have the highest average length of stay?
CREATE OR REPLACE VIEW v_11_hospital_avg_length_of_stay AS
SELECT
    h.Hospital_ID,
    h.Hospital_Name,
    ROUND(AVG(a.Length_of_Stay), 2) AS Average_Length_of_Stay
FROM Hospitals h
JOIN Admissions a
    ON h.Hospital_ID = a.Hospital_ID
GROUP BY
    h.Hospital_ID,
    h.Hospital_Name;
    
SELECT *
FROM v_11_hospital_avg_length_of_stay
ORDER BY Average_Length_of_Stay DESC;

-- PHASE 2 — DOCTOR & DEPARTMENT ANALYSIS
-- Q12. Which doctors have the highest appointment volume?
CREATE OR REPLACE VIEW v_12_doctor_appointment_volume AS
SELECT
    d.Doctor_ID,
    d.Doctor_Name,
    d.Specialization,
    COUNT(a.Appointment_ID) AS Appointment_Volume
FROM Doctors d
JOIN Appointments a
    ON d.Doctor_ID = a.Doctor_ID
GROUP BY
    d.Doctor_ID,
    d.Doctor_Name,
    d.Specialization;
    
SELECT *
FROM v_12_doctor_appointment_volume
ORDER BY Appointment_Volume DESC;

-- Q13. Which specializations are most demanded?
CREATE OR REPLACE VIEW v_13_specialization_demand AS
SELECT
    d.Specialization,
    COUNT(a.Appointment_ID) AS Total_Appointments
FROM Doctors d
JOIN Appointments a
    ON d.Doctor_ID = a.Doctor_ID
GROUP BY d.Specialization;

SELECT *
FROM v_13_specialization_demand
ORDER BY Total_Appointments DESC;

-- Q14. Which departments handle the highest number of patients?
CREATE OR REPLACE VIEW v_14_department_patient_volume AS
SELECT
    d.Department_ID,
    d.Department_Name,
    COUNT(DISTINCT a.Patient_ID) AS Total_Patients
FROM Departments d
JOIN Admissions a
    ON d.Department_ID = a.Department_ID
GROUP BY
    d.Department_ID,
    d.Department_Name;
    
SELECT *
FROM v_14_department_patient_volume
ORDER BY Total_Patients DESC;

-- Q15. Which departments generate the highest revenue?
CREATE OR REPLACE VIEW v_15_department_revenue AS
SELECT
    d.Department_ID,
    d.Department_Name,
    SUM(b.Net_Sales) AS Total_Revenue
FROM Departments d
JOIN Billing b
    ON d.Department_ID = b.Department_ID
GROUP BY
    d.Department_ID,
    d.Department_Name;
    
SELECT *
FROM v_15_department_revenue
ORDER BY Total_Revenue DESC;

-- Q16. Which departments generate the highest profit?
CREATE OR REPLACE VIEW v_16_department_profit AS
SELECT
    d.Department_ID,
    d.Department_Name,
    SUM(b.Profit) AS Total_Profit
FROM Departments d
JOIN Billing b
    ON d.Department_ID = b.Department_ID
GROUP BY
    d.Department_ID,
    d.Department_Name;

SELECT *
FROM v_16_department_profit
ORDER BY Total_Profit DESC;

-- Q17. What is the appointment status distribution?
CREATE OR REPLACE VIEW v_17_appointment_status AS
SELECT
    Status,
    COUNT(*) AS Total_Appointments
FROM Appointments
GROUP BY Status;

SELECT *
FROM v_17_appointment_status
ORDER BY Total_Appointments DESC;

-- PHASE 3 — PATIENT ANALYSIS
-- Q18. What is the gender distribution?
CREATE OR REPLACE VIEW v_18_gender_distribution AS
SELECT
    Gender,
    COUNT(*) AS Total_Patients
FROM Patients
GROUP BY Gender;

SELECT *
FROM v_18_gender_distribution;

-- Q19. What is the age-group distribution?
CREATE OR REPLACE VIEW v_19_age_group_distribution AS
SELECT
    CASE
        WHEN Age < 18 THEN 'Below 18'
        WHEN Age BETWEEN 18 AND 30 THEN '18-30'
        WHEN Age BETWEEN 31 AND 45 THEN '31-45'
        WHEN Age BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END AS Age_Group,
    COUNT(*) AS Total_Patients
FROM Patients
GROUP BY
    CASE
        WHEN Age < 18 THEN 'Below 18'
        WHEN Age BETWEEN 18 AND 30 THEN '18-30'
        WHEN Age BETWEEN 31 AND 45 THEN '31-45'
        WHEN Age BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END;
    
SELECT *
FROM v_19_age_group_distribution;

-- Q20. Which states have the highest number of patients?
CREATE OR REPLACE VIEW v_20_state_patient_distribution AS
SELECT
    State,
    COUNT(*) AS Total_Patients
FROM Patients
GROUP BY State;

SELECT *
FROM v_20_state_patient_distribution
ORDER BY Total_Patients DESC;

-- Q21. Which cities have the highest number of patients?
CREATE OR REPLACE VIEW v_21_city_patient_distribution AS
SELECT
    State,
    City,
    COUNT(*) AS Total_Patients
FROM Patients
GROUP BY State, City;

SELECT *
FROM v_21_city_patient_distribution
ORDER BY Total_Patients DESC;

-- Q22. Distribution by insurance type
CREATE OR REPLACE VIEW v_22_insurance_distribution AS
SELECT
    Insurance_Type,
    COUNT(*) AS Total_Patients
FROM Patients
GROUP BY Insurance_Type;

SELECT *
FROM v_22_insurance_distribution
ORDER BY Total_Patients DESC;

-- Q23. New patients registered each month
CREATE OR REPLACE VIEW v_23_monthly_patient_registration AS
SELECT
    YEAR(Registration_Date) AS Year,
    MONTH(Registration_Date) AS Month_Number,
    DATE_FORMAT(Registration_Date, '%Y-%m') AS `Year_Month`,
    COUNT(*) AS New_Patients
FROM Patients
GROUP BY
    YEAR(Registration_Date),
    MONTH(Registration_Date),
    DATE_FORMAT(Registration_Date, '%Y-%m');
    
SELECT *
FROM v_23_monthly_patient_registration
ORDER BY Year, Month_Number;

-- Q24–Q34: MEDICINE & PRESCRIPTION ANALYSIS
-- Q24. Which medicines are prescribed most frequently?
CREATE OR REPLACE VIEW v_24_most_prescribed_medicines AS
SELECT
    p.Medicine_ID,
    m.Medicine_Name,
    COUNT(p.Prescription_ID) AS Prescription_Count,
    SUM(p.Quantity) AS Total_Quantity
FROM Prescriptions p
JOIN Medicines m
    ON p.Medicine_ID = m.Medicine_ID
GROUP BY
    p.Medicine_ID,
    m.Medicine_Name;
    
SELECT *
FROM v_24_most_prescribed_medicines
ORDER BY Total_Quantity DESC;

-- Q25. Which medicines have the highest sales?
CREATE OR REPLACE VIEW v_25_medicine_sales AS
SELECT
    p.Medicine_ID,
    m.Medicine_Name,
    SUM(p.Sales) AS Total_Sales,
    SUM(p.Quantity) AS Total_Quantity
FROM Prescriptions p
JOIN Medicines m
    ON p.Medicine_ID = m.Medicine_ID
GROUP BY
    p.Medicine_ID,
    m.Medicine_Name;
    
SELECT *
FROM v_25_medicine_sales
ORDER BY Total_Sales DESC;

-- Q26. Which medicines generate the highest profit?
CREATE OR REPLACE VIEW v_26_medicine_profit AS
SELECT
    p.Medicine_ID,
    m.Medicine_Name,
    SUM(p.Profit) AS Total_Profit
FROM Prescriptions p
JOIN Medicines m
    ON p.Medicine_ID = m.Medicine_ID
GROUP BY
    p.Medicine_ID,
    m.Medicine_Name;
    
SELECT *
FROM v_26_medicine_profit
ORDER BY Total_Profit DESC;

-- Q27. Which medicine categories have the highest demand?
CREATE OR REPLACE VIEW v_27_category_demand AS
SELECT
    m.Category,
    SUM(p.Quantity) AS Total_Quantity,
    COUNT(p.Prescription_ID) AS Prescription_Count
FROM Prescriptions p
JOIN Medicines m
    ON p.Medicine_ID = m.Medicine_ID
GROUP BY m.Category;

SELECT *
FROM v_27_category_demand
ORDER BY Total_Quantity DESC;

-- Q28. Which medicine categories generate the highest revenue?
CREATE OR REPLACE VIEW v_28_category_revenue AS
SELECT
    m.Category,
    SUM(p.Sales) AS Total_Revenue
FROM Prescriptions p
JOIN Medicines m
    ON p.Medicine_ID = m.Medicine_ID
GROUP BY m.Category;

SELECT *
FROM v_28_category_revenue
ORDER BY Total_Revenue DESC;

-- Q29. Which medicines have the highest profit margins?
CREATE OR REPLACE VIEW v_29_medicine_profit_margin AS
SELECT
    p.Medicine_ID,
    m.Medicine_Name,
    SUM(p.Sales) AS Total_Sales,
    SUM(p.Profit) AS Total_Profit,
    ROUND(
        SUM(p.Profit) / NULLIF(SUM(p.Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent
FROM Prescriptions p
JOIN Medicines m
    ON p.Medicine_ID = m.Medicine_ID
GROUP BY
    p.Medicine_ID,
    m.Medicine_Name;
    
SELECT *
FROM v_29_medicine_profit_margin
ORDER BY Profit_Margin_Percent DESC;

-- Q30. Which medicines are most demanded in each hospital?
CREATE OR REPLACE VIEW v_30_hospital_medicine_demand AS
SELECT
    p.Hospital_ID,
    h.Hospital_Name,
    p.Medicine_ID,
    m.Medicine_Name,
    SUM(p.Quantity) AS Total_Quantity
FROM Prescriptions p
JOIN Hospitals h
    ON p.Hospital_ID = h.Hospital_ID
JOIN Medicines m
    ON p.Medicine_ID = m.Medicine_ID
GROUP BY
    p.Hospital_ID,
    h.Hospital_Name,
    p.Medicine_ID,
    m.Medicine_Name;
    
SELECT *
FROM v_30_hospital_medicine_demand
ORDER BY Hospital_ID, Total_Quantity DESC;

SELECT *
FROM (
    SELECT
        Hospital_ID,
        Hospital_Name,
        Medicine_ID,
        Medicine_Name,
        Total_Quantity,
        RANK() OVER (
            PARTITION BY Hospital_ID
            ORDER BY Total_Quantity DESC
        ) AS Medicine_Rank
    FROM v_30_hospital_medicine_demand
) x
WHERE Medicine_Rank = 1;

-- Q31. Which medicines have the highest sales in each month?
CREATE OR REPLACE VIEW v_31_monthly_medicine_sales AS
SELECT
    YEAR(p.Prescription_Date) AS Year,
    MONTH(p.Prescription_Date) AS Month_Number,
    DATE_FORMAT(p.Prescription_Date, '%Y-%m') AS `Year_Month`,
    p.Medicine_ID,
    m.Medicine_Name,
    SUM(p.Sales) AS Total_Sales
FROM Prescriptions p
JOIN Medicines m
    ON p.Medicine_ID = m.Medicine_ID
GROUP BY
    YEAR(p.Prescription_Date),
    MONTH(p.Prescription_Date),
    DATE_FORMAT(p.Prescription_Date, '%Y-%m'),
    p.Medicine_ID,
    m.Medicine_Name;
    
SELECT *
FROM v_31_monthly_medicine_sales
ORDER BY Year, Month_Number, Total_Sales DESC;

-- Top medicine for each month
SELECT *
FROM (
    SELECT
        Year,
        Month_Number,
        `Year_Month`,
        Medicine_ID,
        Medicine_Name,
        Total_Sales,
        RANK() OVER (
            PARTITION BY `Year_Month`
            ORDER BY Total_Sales DESC
        ) AS Sales_Rank
    FROM v_31_monthly_medicine_sales
) x
WHERE Sales_Rank = 1
ORDER BY Year, Month_Number;

-- Q32. Which medicines have the highest sales in each season?
CREATE OR REPLACE VIEW v_32_seasonal_medicine_sales AS
SELECT
    CASE
        WHEN MONTH(p.Prescription_Date) BETWEEN 1 AND 3
            THEN 'Winter'
        WHEN MONTH(p.Prescription_Date) BETWEEN 4 AND 6
            THEN 'Summer'
        WHEN MONTH(p.Prescription_Date) BETWEEN 7 AND 9
            THEN 'Monsoon'
        ELSE 'Post-Monsoon'
    END AS Season,
    p.Medicine_ID,
    m.Medicine_Name,
    SUM(p.Sales) AS Total_Sales
FROM Prescriptions p
JOIN Medicines m
    ON p.Medicine_ID = m.Medicine_ID
GROUP BY
    CASE
        WHEN MONTH(p.Prescription_Date) BETWEEN 1 AND 3
            THEN 'Winter'
        WHEN MONTH(p.Prescription_Date) BETWEEN 4 AND 6
            THEN 'Summer'
        WHEN MONTH(p.Prescription_Date) BETWEEN 7 AND 9
            THEN 'Monsoon'
        ELSE 'Post-Monsoon'
    END,
    p.Medicine_ID,
    m.Medicine_Name;
    
SELECT *
FROM v_32_seasonal_medicine_sales
ORDER BY Season, Total_Sales DESC;

-- Top medicine per season
SELECT *
FROM (
    SELECT
        Season,
        Medicine_ID,
        Medicine_Name,
        Total_Sales,
        RANK() OVER (
            PARTITION BY Season
            ORDER BY Total_Sales DESC
        ) AS Sales_Rank
    FROM v_32_seasonal_medicine_sales
) x
WHERE Sales_Rank = 1;

-- Q33. Which medicine categories are most demanded in each season?
CREATE OR REPLACE VIEW v_33_seasonal_category_demand AS
SELECT
    CASE
        WHEN MONTH(p.Prescription_Date) BETWEEN 1 AND 3
            THEN 'Winter'
        WHEN MONTH(p.Prescription_Date) BETWEEN 4 AND 6
            THEN 'Summer'
        WHEN MONTH(p.Prescription_Date) BETWEEN 7 AND 9
            THEN 'Monsoon'
        ELSE 'Post-Monsoon'
    END AS Season,
    m.Category,
    SUM(p.Quantity) AS Total_Quantity
FROM Prescriptions p
JOIN Medicines m
    ON p.Medicine_ID = m.Medicine_ID
GROUP BY
    CASE
        WHEN MONTH(p.Prescription_Date) BETWEEN 1 AND 3
            THEN 'Winter'
        WHEN MONTH(p.Prescription_Date) BETWEEN 4 AND 6
            THEN 'Summer'
        WHEN MONTH(p.Prescription_Date) BETWEEN 7 AND 9
            THEN 'Monsoon'
        ELSE 'Post-Monsoon'
    END,
    m.Category;
    
SELECT *
FROM v_33_seasonal_category_demand
ORDER BY Season, Total_Quantity DESC;

-- Top category per season
SELECT *
FROM (
    SELECT
        Season,
        Category,
        Total_Quantity,
        RANK() OVER (
            PARTITION BY Season
            ORDER BY Total_Quantity DESC
        ) AS Category_Rank
    FROM v_33_seasonal_category_demand
) x
WHERE Category_Rank = 1;

-- Q34. Which medicines show the strongest year-over-year growth?
CREATE OR REPLACE VIEW v_34_medicine_yoy_growth AS
WITH yearly_sales AS (
    SELECT
        YEAR(p.Prescription_Date) AS Sales_Year,
        p.Medicine_ID,
        m.Medicine_Name,
        SUM(p.Sales) AS Total_Sales
    FROM Prescriptions p
    JOIN Medicines m
        ON p.Medicine_ID = m.Medicine_ID
    GROUP BY
        YEAR(p.Prescription_Date),
        p.Medicine_ID,
        m.Medicine_Name
),
growth AS (
    SELECT
        Sales_Year,
        Medicine_ID,
        Medicine_Name,
        Total_Sales,
        LAG(Total_Sales) OVER (
            PARTITION BY Medicine_ID
            ORDER BY Sales_Year
        ) AS Previous_Year_Sales
    FROM yearly_sales
)
SELECT
    Sales_Year,
    Medicine_ID,
    Medicine_Name,
    Total_Sales,
    Previous_Year_Sales,
    ROUND(
        (Total_Sales - Previous_Year_Sales)
        / NULLIF(Previous_Year_Sales, 0) * 100,
        2
    ) AS YoY_Growth_Percent
FROM growth
WHERE Previous_Year_Sales IS NOT NULL;

SELECT *
FROM v_34_medicine_yoy_growth
ORDER BY YoY_Growth_Percent DESC;

-- Q35–Q39: REVENUE & BILLING ANALYSIS
-- Q35. What are the total gross sales, discounts, net revenue and profit?
CREATE OR REPLACE VIEW v_35_overall_billing_summary AS
SELECT
    SUM(Sales) AS Gross_Sales,
    SUM(Discount) AS Total_Discount,
    SUM(Net_Sales) AS Net_Revenue,
    SUM(Profit) AS Total_Profit
FROM Billing;

SELECT *
FROM v_35_overall_billing_summary;

-- Q36. Which service types generate the highest revenue?
CREATE OR REPLACE VIEW v_36_service_type_revenue AS
SELECT
    Service_Type,
    COUNT(Bill_ID) AS Total_Bills,
    SUM(Net_Sales) AS Total_Revenue,
    SUM(Profit) AS Total_Profit
FROM Billing
GROUP BY Service_Type;

SELECT *
FROM v_36_service_type_revenue
ORDER BY Total_Revenue DESC;

-- Q37. Which hospitals generate the highest billing revenue?
CREATE OR REPLACE VIEW v_37_hospital_billing_revenue AS
SELECT
    b.Hospital_ID,
    h.Hospital_Name,
    SUM(b.Net_Sales) AS Total_Revenue,
    SUM(b.Profit) AS Total_Profit
FROM Billing b
JOIN Hospitals h
    ON b.Hospital_ID = h.Hospital_ID
GROUP BY
    b.Hospital_ID,
    h.Hospital_Name;
    
SELECT *
FROM v_37_hospital_billing_revenue
ORDER BY Total_Revenue DESC;

-- Q38. How much revenue is lost through discounts?
CREATE OR REPLACE VIEW v_38_discount_impact AS
SELECT
    SUM(Sales) AS Gross_Sales,
    SUM(Discount) AS Total_Discount,
    SUM(Net_Sales) AS Net_Revenue,
    ROUND(
        SUM(Discount) / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Discount_Percentage
FROM Billing;

SELECT *
FROM v_38_discount_impact;

-- Q39. Which payment modes generate the highest transaction value?
CREATE OR REPLACE VIEW v_39_payment_mode_analysis AS
SELECT
    Payment_Mode,
    COUNT(Bill_ID) AS Total_Transactions,
    SUM(Net_Sales) AS Total_Transaction_Value
FROM Billing
GROUP BY Payment_Mode;

SELECT *
FROM v_39_payment_mode_analysis
ORDER BY Total_Transaction_Value DESC;

-- Q40–Q43: LABORATORY ANALYSIS
-- Q40. Which laboratory tests are performed most frequently?
CREATE OR REPLACE VIEW v_40_lab_test_frequency AS
SELECT
    Test_Name,
    COUNT(Lab_ID) AS Test_Count,
    SUM(Test_Cost) AS Total_Test_Cost
FROM Lab_Tests
GROUP BY Test_Name;

SELECT *
FROM v_40_lab_test_frequency
ORDER BY Test_Count DESC;

-- Q41. Which hospitals have the highest laboratory activity?
CREATE OR REPLACE VIEW v_41_hospital_lab_activity AS
SELECT
    l.Hospital_ID,
    h.Hospital_Name,
    COUNT(l.Lab_ID) AS Total_Lab_Tests,
    SUM(l.Test_Cost) AS Total_Lab_Cost
FROM Lab_Tests l
JOIN Hospitals h
    ON l.Hospital_ID = h.Hospital_ID
GROUP BY
    l.Hospital_ID,
    h.Hospital_Name;
    
SELECT *
FROM v_41_hospital_lab_activity
ORDER BY Total_Lab_Tests DESC;

-- Q42. Which departments have the highest laboratory activity?
CREATE OR REPLACE VIEW v_42_department_lab_activity AS
SELECT
    l.Department_ID,
    d.Department_Name,
    COUNT(l.Lab_ID) AS Total_Lab_Tests,
    SUM(l.Test_Cost) AS Total_Lab_Cost
FROM Lab_Tests l
JOIN Departments d
    ON l.Department_ID = d.Department_ID
GROUP BY
    l.Department_ID,
    d.Department_Name;
    
SELECT *
FROM v_42_department_lab_activity
ORDER BY Total_Lab_Tests DESC;

-- Q43. What is the distribution of laboratory result statuses?
CREATE OR REPLACE VIEW v_43_lab_result_status AS
SELECT
    Result_Status,
    COUNT(Lab_ID) AS Total_Tests
FROM Lab_Tests
GROUP BY Result_Status;

SELECT *
FROM v_43_lab_result_status
ORDER BY Total_Tests DESC;

-- Q44–Q47: INVENTORY & VENDOR ANALYSIS
-- Q44. What is the total inventory purchase value versus sales value?
CREATE OR REPLACE VIEW v_44_inventory_purchase_vs_sales AS
SELECT
    SUM(Purchase_Value) AS Total_Purchase_Value,
    SUM(Sales_Value) AS Total_Sales_Value,
    SUM(Sales_Value) - SUM(Purchase_Value) AS Inventory_Value_Difference
FROM Inventory;

SELECT *
FROM v_44_inventory_purchase_vs_sales;

-- Q45. Which medicines have the highest inventory sales value?
CREATE OR REPLACE VIEW v_45_medicine_inventory_sales AS
SELECT
    i.Medicine_ID,
    m.Medicine_Name,
    SUM(i.Sales_Value) AS Total_Sales_Value,
    SUM(i.Quantity) AS Total_Quantity
FROM Inventory i
JOIN Medicines m
    ON i.Medicine_ID = m.Medicine_ID
GROUP BY
    i.Medicine_ID,
    m.Medicine_Name;
    
SELECT *
FROM v_45_medicine_inventory_sales
ORDER BY Total_Sales_Value DESC;

-- Q46. Which vendors have the highest purchase value?
CREATE OR REPLACE VIEW v_46_vendor_purchase_value AS
SELECT
    i.Vendor_ID,
    v.Vendor_Name,
    SUM(i.Purchase_Value) AS Total_Purchase_Value
FROM Inventory i
JOIN Vendors v
    ON i.Vendor_ID = v.Vendor_ID
GROUP BY
    i.Vendor_ID,
    v.Vendor_Name;
    
SELECT *
FROM v_46_vendor_purchase_value
ORDER BY Total_Purchase_Value DESC;

-- Q47. Which vendors have the highest transaction volume?
CREATE OR REPLACE VIEW v_47_vendor_transaction_volume AS
SELECT
    i.Vendor_ID,
    v.Vendor_Name,
    COUNT(i.Inventory_ID) AS Transaction_Count,
    SUM(i.Quantity) AS Total_Quantity,
    SUM(i.Purchase_Value) AS Total_Purchase_Value
FROM Inventory i
JOIN Vendors v
    ON i.Vendor_ID = v.Vendor_ID
GROUP BY
    i.Vendor_ID,
    v.Vendor_Name;
    
SELECT *
FROM v_47_vendor_transaction_volume
ORDER BY Transaction_Count DESC;

-- Q48–Q50: OPERATIONAL TRENDS
-- Q48. How do monthly appointments change over time?
CREATE OR REPLACE VIEW v_48_monthly_appointments AS
SELECT
    YEAR(Appointment_Date) AS Year,
    MONTH(Appointment_Date) AS Month_Number,
    DATE_FORMAT(Appointment_Date, '%Y-%m') AS `Year_Month`,
    COUNT(Appointment_ID) AS Total_Appointments
FROM Appointments
GROUP BY
    YEAR(Appointment_Date),
    MONTH(Appointment_Date),
    DATE_FORMAT(Appointment_Date, '%Y-%m');
    
SELECT *
FROM v_48_monthly_appointments
ORDER BY Year, Month_Number;

-- Q49. How does monthly billing revenue change over time?
CREATE OR REPLACE VIEW v_49_monthly_billing_revenue AS
SELECT
    YEAR(Bill_Date) AS Year,
    MONTH(Bill_Date) AS Month_Number,
    DATE_FORMAT(Bill_Date, '%Y-%m') AS `Year_Month`,
    SUM(Net_Sales) AS Total_Revenue,
    SUM(Profit) AS Total_Profit,
    COUNT(Bill_ID) AS Total_Bills
FROM Billing
GROUP BY
    YEAR(Bill_Date),
    MONTH(Bill_Date),
    DATE_FORMAT(Bill_Date, '%Y-%m');
    
SELECT *
FROM v_49_monthly_billing_revenue
ORDER BY Year, Month_Number;

-- Q50. How does overall hospital activity change over time?
CREATE OR REPLACE VIEW v_50_overall_hospital_activity AS

SELECT
    DATE_FORMAT(Admission_Date, '%Y-%m') AS `Year_Month`,
    'Admissions' AS Activity_Type,
    COUNT(*) AS Activity_Count
FROM Admissions
GROUP BY DATE_FORMAT(Admission_Date, '%Y-%m')

UNION ALL

SELECT
    DATE_FORMAT(Appointment_Date, '%Y-%m') AS `Year_Month`,
    'Appointments' AS Activity_Type,
    COUNT(*) AS Activity_Count
FROM Appointments
GROUP BY DATE_FORMAT(Appointment_Date, '%Y-%m')

UNION ALL

SELECT
    DATE_FORMAT(Bill_Date, '%Y-%m') AS `Year_Month`,
    'Billing' AS Activity_Type,
    COUNT(*) AS Activity_Count
FROM Billing
GROUP BY DATE_FORMAT(Bill_Date, '%Y-%m')

UNION ALL

SELECT
    DATE_FORMAT(Prescription_Date, '%Y-%m') AS `Year_Month`,
    'Prescriptions' AS Activity_Type,
    COUNT(*) AS Activity_Count
FROM Prescriptions
GROUP BY DATE_FORMAT(Prescription_Date, '%Y-%m')

UNION ALL

SELECT
    DATE_FORMAT(Test_Date, '%Y-%m') AS `Year_Month`,
    'Lab Tests' AS Activity_Type,
    COUNT(*) AS Activity_Count
FROM Lab_Tests
GROUP BY DATE_FORMAT(Test_Date, '%Y-%m');

SELECT *
FROM v_50_overall_hospital_activity
ORDER BY `Year_Month`, Activity_Type;

-- to get total activity by month
SELECT
    `Year_Month`,
    SUM(Activity_Count) AS Total_Activity
FROM v_50_overall_hospital_activity
GROUP BY `Year_Month`
ORDER BY `Year_Month`;

RENAME TABLE
v_01_hospital_patient_volume TO vw_hospital_patients,
v_02_hospital_admissions TO vw_hospital_admissions,
v_03_hospital_revenue TO vw_hospital_revenue,
v_04_hospital_profit TO vw_hospital_profit,
v_05_hospital_bed_performance TO vw_bed_performance,
v_07_monthly_admission_trend TO vw_monthly_adm,
v_08_admission_type_distribution TO vw_adm_type,
v_09_admission_status_distribution TO vw_adm_status,
v_10_diagnosis_admissions TO vw_diagnosis,
v_11_hospital_avg_length_of_stay TO vw_avg_los,
v_12_doctor_appointment_volume TO vw_doctor_appts,
v_13_specialization_demand TO vw_specialization,
v_14_department_patient_volume TO vw_dept_patients,
v_15_department_revenue TO vw_dept_revenue,
v_16_department_profit TO vw_dept_profit,
v_17_appointment_status TO vw_appt_status,
v_18_gender_distribution TO vw_gender,
v_19_age_group_distribution TO vw_age_group,
v_20_state_patient_distribution TO vw_state_patients,
v_21_city_patient_distribution TO vw_city_patients,
v_22_insurance_distribution TO vw_insurance,
v_23_monthly_patient_registration TO vw_monthly_patients,
v_24_most_prescribed_medicines TO vw_medicine_demand,
v_25_medicine_sales TO vw_medicine_sales,
v_26_medicine_profit TO vw_medicine_profit,
v_27_category_demand TO vw_category_demand,
v_28_category_revenue TO vw_category_revenue,
v_29_medicine_profit_margin TO vw_medicine_margin,
v_30_hospital_medicine_demand TO vw_hosp_medicine,
v_31_monthly_medicine_sales TO vw_monthly_med_sales,
v_32_seasonal_medicine_sales TO vw_season_med_sales,
v_33_seasonal_category_demand TO vw_season_category,
v_34_medicine_yoy_growth TO vw_medicine_yoy,
v_35_overall_billing_summary TO vw_billing_summary,
v_36_service_type_revenue TO vw_service_revenue,
v_37_hospital_billing_revenue TO vw_hosp_billing,
v_38_discount_impact TO vw_discount_impact,
v_39_payment_mode_analysis TO vw_payment_mode,
v_40_lab_test_frequency TO vw_lab_tests,
v_41_hospital_lab_activity TO vw_hosp_lab,
v_42_department_lab_activity TO vw_dept_lab,
v_43_lab_result_status TO vw_lab_status,
v_44_inventory_purchase_vs_sales TO vw_inventory_value,
v_45_medicine_inventory_sales TO vw_med_inventory,
v_46_vendor_purchase_value TO vw_vendor_purchase,
v_47_vendor_transaction_volume TO vw_vendor_trans,
v_48_monthly_appointments TO vw_monthly_appts,
v_49_monthly_billing_revenue TO vw_monthly_revenue,
v_50_overall_hospital_activity TO vw_hospital_activity;

SHOW FULL TABLES
WHERE Table_type = 'VIEW';

RENAME TABLE v_01_hospital_patient_volume
TO vw_hospital_patients;
RENAME TABLE v_02_hospital_admissions
TO vw_hospital_admissions;



DROP VIEW IF EXISTS v_06_admission_summary;
DROP VIEW IF EXISTS v_06_revenue_summary;

USE pharmacy_analytics_mini;

SHOW FULL TABLES
WHERE Table_type = 'VIEW';

select * from billing;


USE pharmacy_analytics_mini;

SELECT COUNT(*) AS prescription_count
FROM prescriptions;

SHOW COLUMNS FROM prescriptions;

SHOW VARIABLES LIKE 'secure_file_priv';


USE pharmacy_analytics_mini;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/prescriptions.csv'
INTO TABLE prescriptions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    Prescription_ID,
    Patient_ID,
    Doctor_ID,
    Hospital_ID,
    Department_ID,
    Medicine_ID,
    Prescription_Date,
    Quantity,
    Dosage_Days,
    Prescription_Status,
    Selling_Price,
    Unit_Cost,
    Sales,
    Cost,
    Profit
);

SET GLOBAL local_infile = 1;

SELECT Medicine_ID, COUNT(*) AS Records
FROM inventory
GROUP BY Medicine_ID
ORDER BY Records DESC
LIMIT 10;

SELECT 
    MIN(Sales_Value) AS Min_Sales,
    MAX(Sales_Value) AS Max_Sales,
    SUM(Sales_Value) AS Total_Sales,
    COUNT(DISTINCT Sales_Value) AS Different_Sales_Values
FROM inventory;


SELECT 
    m.Category,
    COUNT(i.Inventory_ID) AS Records,
    SUM(i.Sales_Value) AS Sales
FROM inventory i
JOIN medicines m
    ON i.Medicine_ID = m.Medicine_ID
GROUP BY m.Category
ORDER BY Sales DESC;


UPDATE inventory i
JOIN (
    SELECT 
        Inventory_ID,
        CONCAT(
            'M',
            LPAD(
                MOD(ROW_NUMBER() OVER (ORDER BY Inventory_ID) - 1, 2000) + 1,
                5,
                '0'
            )
        ) AS New_Medicine_ID
    FROM inventory
) x
ON i.Inventory_ID = x.Inventory_ID
SET i.Medicine_ID = x.New_Medicine_ID;

SELECT COUNT(*) AS Matched_Records
FROM inventory i
JOIN medicines m
ON i.Medicine_ID = m.Medicine_ID;

SELECT 
    m.Category,
    COUNT(i.Inventory_ID) AS Records,
    SUM(i.Sales_Value) AS Sales
FROM inventory i
JOIN medicines m
ON i.Medicine_ID = m.Medicine_ID
GROUP BY m.Category
ORDER BY Sales DESC;

