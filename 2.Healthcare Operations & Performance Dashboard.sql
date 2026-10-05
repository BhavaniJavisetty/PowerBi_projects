create database priyaqubit;
use priyaqubit;

select count(*) from products;
select count(*) from medical_sales;
select count(*) from inventory;

USE priyaqubit;

SELECT 'products' AS TableName, COUNT(*) AS RowCount FROM products
UNION ALL
SELECT 'medical_sales', COUNT(*) FROM medical_sales
UNION ALL
SELECT 'inventory', COUNT(*) FROM inventory;

-- Which manufacturers control the largest product portfolio?
SELECT
    Manufacturer,
    COUNT(*) AS BatchCount,
    COUNT(DISTINCT ProductID) AS ProductCount
FROM products
GROUP BY Manufacturer
ORDER BY ProductCount DESC;


CREATE OR REPLACE VIEW vw_manufacturer_portfolio AS
SELECT
    Manufacturer,
    COUNT(DISTINCT ProductName) AS ProductCount,
    COUNT(*) AS BatchCount,
    COUNT(DISTINCT GenericName) AS GenericCount,
    COUNT(DISTINCT Category) AS CategoryCount
FROM products
WHERE Manufacturer IS NOT NULL
  AND TRIM(Manufacturer) <> ''
  AND LOWER(TRIM(Manufacturer)) NOT IN ('na', 'unknown')
GROUP BY Manufacturer
ORDER BY ProductCount DESC;


SELECT *
FROM vw_manufacturer_portfolio
LIMIT 10;

-- which manufacturers have the largest and most diverse product portfolios?

CREATE OR REPLACE VIEW vw_manufacturer_scale AS
SELECT
    Manufacturer,
    COUNT(DISTINCT ProductName) AS ProductCount,
    COUNT(DISTINCT GenericName) AS GenericCount,
    COUNT(DISTINCT Category) AS CategoryCount,
    COUNT(*) AS BatchCount
FROM products
WHERE Manufacturer IS NOT NULL
  AND TRIM(Manufacturer) <> ''
  AND LOWER(TRIM(Manufacturer)) NOT IN ('na', 'unknown')
GROUP BY Manufacturer
ORDER BY ProductCount DESC,
         GenericCount DESC,
         CategoryCount DESC;
         
SELECT *
FROM vw_manufacturer_scale
LIMIT 15;


-- 4. Product Type Distribution
CREATE OR REPLACE VIEW vw_product_type_distribution AS
SELECT
    ProductType,
    COUNT(DISTINCT ProductName) AS ProductCount,
    ROUND(
        COUNT(DISTINCT ProductName) * 100.0 /
        (
            SELECT COUNT(DISTINCT ProductName)
            FROM products
            WHERE ProductName IS NOT NULL
              AND TRIM(ProductName) <> ''
        ),
        2
    ) AS ProductPercentage
FROM products
WHERE ProductType IS NOT NULL
  AND TRIM(ProductType) <> ''
GROUP BY ProductType
ORDER BY ProductCount DESC;

SELECT *
FROM vw_product_type_distribution;

-- or 

CREATE OR REPLACE VIEW vw_product_type_distribution AS
SELECT
    ProductType,
    COUNT(*) AS ProductCount,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM products),
        2
    ) AS ProductPercentage
FROM products
WHERE ProductType IS NOT NULL
  AND TRIM(ProductType) <> ''
GROUP BY ProductType
ORDER BY ProductCount DESC;

SELECT *
FROM vw_product_type_distribution;

-- Q5. Which active ingredients / generic names are most saturated?

CREATE OR REPLACE VIEW vw_generic_saturation AS
SELECT
    GenericName,
    COUNT(DISTINCT ProductName) AS ProductCount,
    COUNT(DISTINCT Manufacturer) AS ManufacturerCount
FROM products
WHERE GenericName IS NOT NULL
  AND TRIM(GenericName) <> ''
  AND LOWER(TRIM(GenericName)) NOT IN ('na', 'unknown')
GROUP BY GenericName
ORDER BY ProductCount DESC, ManufacturerCount DESC;

SELECT *
FROM vw_generic_saturation
LIMIT 10;

-- Q6 — Single-Supplier Risk

CREATE OR REPLACE VIEW vw_single_manufacturer_risk AS
SELECT
    GenericName,
    COUNT(DISTINCT ProductName) AS ProductCount,
    COUNT(DISTINCT Manufacturer) AS ManufacturerCount
FROM products
WHERE GenericName IS NOT NULL
  AND TRIM(GenericName) <> ''
  AND LOWER(TRIM(GenericName)) NOT IN ('na', 'unknown')
  AND Manufacturer IS NOT NULL
  AND TRIM(Manufacturer) <> ''
  AND LOWER(TRIM(Manufacturer)) NOT IN ('na', 'unknown')
GROUP BY GenericName
HAVING COUNT(DISTINCT Manufacturer) = 1
ORDER BY ProductCount DESC, GenericName;

SELECT *
FROM vw_single_manufacturer_risk;

-- Q7: Expiry Pipeline

CREATE OR REPLACE VIEW vw_expiry_pipeline AS
SELECT
    CASE
        WHEN ExpiryDate < CURDATE() THEN 'Expired'
        WHEN ExpiryDate <= DATE_ADD(CURDATE(), INTERVAL 30 DAY) THEN 'Within 30 Days'
        WHEN ExpiryDate <= DATE_ADD(CURDATE(), INTERVAL 90 DAY) THEN '31-90 Days'
        WHEN ExpiryDate <= DATE_ADD(CURDATE(), INTERVAL 180 DAY) THEN '91-180 Days'
        WHEN ExpiryDate <= DATE_ADD(CURDATE(), INTERVAL 365 DAY) THEN '181-365 Days'
        ELSE 'More Than 365 Days'
    END AS ExpiryBucket,
    COUNT(*) AS BatchCount
FROM products
WHERE ExpiryDate IS NOT NULL
GROUP BY ExpiryBucket
ORDER BY
    CASE ExpiryBucket
        WHEN 'Expired' THEN 1
        WHEN 'Within 30 Days' THEN 2
        WHEN '31-90 Days' THEN 3
        WHEN '91-180 Days' THEN 4
        WHEN '181-365 Days' THEN 5
        ELSE 6
    END;
    
SELECT *
FROM vw_expiry_pipeline;

-- Q8 — Manufacturer Revenue

CREATE OR REPLACE VIEW vw_manufacturer_revenue AS
SELECT
    p.Manufacturer,
    COUNT(DISTINCT p.ProductName) AS ProductCount,
    ROUND(SUM(s.TotalAmount), 2) AS TotalRevenue
FROM medical_sales s
JOIN products p
    ON s.ProductID = p.ProductID
WHERE p.Manufacturer IS NOT NULL
  AND TRIM(p.Manufacturer) <> ''
  AND LOWER(TRIM(p.Manufacturer)) NOT IN ('na', 'unknown')
GROUP BY p.Manufacturer
ORDER BY TotalRevenue DESC;

SELECT *
FROM vw_manufacturer_revenue
LIMIT 10;

SELECT
    ProductID,
    COUNT(DISTINCT Manufacturer) AS ManufacturerCount
FROM products
GROUP BY ProductID
HAVING COUNT(DISTINCT Manufacturer) > 1
LIMIT 20;

-- 8-skips;

-- Q9 — Revenue/Sales decline by year
CREATE OR REPLACE VIEW vw_yearly_sales_trend AS
SELECT
    YEAR(SaleDate) AS SalesYear,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    SUM(QuantitySold) AS TotalUnits,
    COUNT(DISTINCT SaleID) AS TotalOrders
FROM medical_sales
WHERE SaleDate IS NOT NULL
GROUP BY YEAR(SaleDate)
ORDER BY SalesYear;

SELECT *
FROM vw_yearly_sales_trend;

-- Q10 — Highest revenue region
CREATE OR REPLACE VIEW vw_region_revenue AS
SELECT
    Region,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    SUM(QuantitySold) AS TotalUnits,
    COUNT(DISTINCT SaleID) AS TotalOrders
FROM medical_sales
WHERE Region IS NOT NULL
  AND TRIM(Region) <> ''
GROUP BY Region
ORDER BY TotalRevenue DESC;

SELECT *
FROM vw_region_revenue;

-- Q11 — Highest and lowest revenue month
CREATE OR REPLACE VIEW vw_monthly_revenue AS
SELECT
    MONTH(SaleDate) AS MonthNumber,
    MONTHNAME(SaleDate) AS MonthName,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    SUM(QuantitySold) AS TotalUnits,
    COUNT(DISTINCT SaleID) AS TotalOrders
FROM medical_sales
WHERE SaleDate IS NOT NULL
GROUP BY MONTH(SaleDate), MONTHNAME(SaleDate)
ORDER BY TotalRevenue DESC;

SELECT *
FROM vw_monthly_revenue;

-- Q12 — Strongest Sales Cities
CREATE OR REPLACE VIEW vw_city_sales AS
SELECT
    City,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    SUM(QuantitySold) AS TotalUnits,
    COUNT(DISTINCT SaleID) AS TotalOrders
FROM medical_sales
WHERE City IS NOT NULL
  AND TRIM(City) <> ''
GROUP BY City
ORDER BY TotalRevenue DESC;

SELECT *
FROM vw_city_sales;

-- Q13 — Customer Type Revenue 
CREATE OR REPLACE VIEW vw_customer_type_revenue AS
SELECT
    CustomerType,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    SUM(QuantitySold) AS TotalUnits,
    COUNT(DISTINCT SaleID) AS TotalOrders
FROM medical_sales
WHERE CustomerType IS NOT NULL
  AND TRIM(CustomerType) <> ''
GROUP BY CustomerType
ORDER BY TotalRevenue DESC;

SELECT *
FROM vw_customer_type_revenue;

-- Q14 — Channel Dependency

CREATE OR REPLACE VIEW vw_channel_dependency AS
SELECT
    CustomerType,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    SUM(QuantitySold) AS TotalUnits,
    COUNT(DISTINCT SaleID) AS TotalOrders,
    ROUND(
        SUM(TotalAmount) * 100.0 /
        (SELECT SUM(TotalAmount)
         FROM medical_sales
         WHERE CustomerType IS NOT NULL
           AND TRIM(CustomerType) <> ''
           AND CustomerType <> 'Unknown'),
        2
    ) AS RevenueSharePercent
FROM medical_sales
WHERE CustomerType IN (
    'Hospital',
    'Clinic',
    'Retail Pharmacy',
    'Online Pharmacy'
)
GROUP BY CustomerType
ORDER BY TotalRevenue DESC;

SELECT *
FROM vw_channel_dependency;

-- Q15 — Highest-Revenue Medicine Category
CREATE OR REPLACE VIEW vw_category_revenue AS
SELECT
    p.Category,
    ROUND(SUM(s.TotalAmount), 2) AS TotalRevenue,
    SUM(s.QuantitySold) AS TotalUnits,
    COUNT(DISTINCT s.SaleID) AS TotalOrders
FROM medical_sales s
JOIN (
    SELECT
        ProductID,
        MAX(Category) AS Category
    FROM products
    GROUP BY ProductID
) p
    ON s.ProductID = p.ProductID
WHERE p.Category IS NOT NULL
  AND TRIM(p.Category) <> ''
GROUP BY p.Category
ORDER BY TotalRevenue DESC;

SELECT *
FROM vw_category_revenue;


-- Q16 — Dominant Product Category
CREATE OR REPLACE VIEW vw_category_contribution AS
SELECT
    p.Category,
    ROUND(SUM(s.TotalAmount), 2) AS TotalRevenue,
    SUM(s.QuantitySold) AS TotalUnits,
    ROUND(
        SUM(s.TotalAmount) * 100.0 /
        (
            SELECT SUM(s2.TotalAmount)
            FROM medical_sales s2
            JOIN (
                SELECT ProductID, MAX(Category) AS Category
                FROM products
                GROUP BY ProductID
            ) p2 ON s2.ProductID = p2.ProductID
            WHERE p2.Category IS NOT NULL
              AND TRIM(p2.Category) <> ''
              AND p2.Category <> 'Unknown'
        ),
        2
    ) AS RevenueSharePercent,
    ROUND(
        SUM(s.QuantitySold) * 100.0 /
        (
            SELECT SUM(s3.QuantitySold)
            FROM medical_sales s3
            JOIN (
                SELECT ProductID, MAX(Category) AS Category
                FROM products
                GROUP BY ProductID
            ) p3 ON s3.ProductID = p3.ProductID
            WHERE p3.Category IS NOT NULL
              AND TRIM(p3.Category) <> ''
              AND p3.Category <> 'Unknown'
        ),
        2
    ) AS UnitSharePercent
FROM medical_sales s
JOIN (
    SELECT
        ProductID,
        MAX(Category) AS Category
    FROM products
    GROUP BY ProductID
) p
    ON s.ProductID = p.ProductID
WHERE p.Category IS NOT NULL
  AND TRIM(p.Category) <> ''
  AND p.Category <> 'Unknown'
GROUP BY p.Category
ORDER BY TotalRevenue DESC;

SELECT *
FROM vw_category_contribution;

-- Q17 — Top 10 Products by Revenue
CREATE OR REPLACE VIEW vw_top_products_revenue AS
SELECT
    s.ProductID,
    MAX(p.ProductName) AS ProductName,
    ROUND(SUM(s.TotalAmount), 2) AS TotalRevenue,
    SUM(s.QuantitySold) AS TotalUnits,
    COUNT(DISTINCT s.SaleID) AS TotalOrders
FROM medical_sales s
LEFT JOIN (
    SELECT
        ProductID,
        MAX(ProductName) AS ProductName
    FROM products
    GROUP BY ProductID
) p
    ON s.ProductID = p.ProductID
GROUP BY s.ProductID
ORDER BY TotalRevenue DESC
LIMIT 10;

SELECT *
FROM vw_top_products_revenue;


CREATE OR REPLACE VIEW vw_top_named_products_revenue AS
SELECT
    s.ProductID,
    MAX(p.ProductName) AS ProductName,
    ROUND(SUM(s.TotalAmount), 2) AS TotalRevenue,
    SUM(s.QuantitySold) AS TotalUnits,
    COUNT(DISTINCT s.SaleID) AS TotalOrders
FROM medical_sales s
LEFT JOIN (
    SELECT
        ProductID,
        MAX(ProductName) AS ProductName
    FROM products
    GROUP BY ProductID
) p
    ON s.ProductID = p.ProductID
WHERE p.ProductName IS NOT NULL
  AND TRIM(p.ProductName) <> ''
  AND LOWER(TRIM(p.ProductName)) <> 'unknown'
GROUP BY s.ProductID
ORDER BY TotalRevenue DESC
LIMIT 10;

SELECT *
FROM vw_top_named_products_revenue;

-- Q18 — Prescription Drugs vs OTC / Non-Prescription Revenue
CREATE OR REPLACE VIEW vw_prescription_vs_otc_revenue AS
SELECT
    p.ProductType,
    ROUND(SUM(s.TotalAmount), 2) AS TotalRevenue,
    SUM(s.QuantitySold) AS TotalUnits,
    COUNT(DISTINCT s.SaleID) AS TotalOrders
FROM medical_sales s
JOIN (
    SELECT
        ProductID,
        MAX(ProductType) AS ProductType
    FROM products
    GROUP BY ProductID
) p
    ON s.ProductID = p.ProductID
WHERE p.ProductType IN (
    'Prescription Drug',
    'OTC / Non-Prescription',
    'Health Supplement'
)
GROUP BY p.ProductType
ORDER BY TotalRevenue DESC;

SELECT *
FROM vw_prescription_vs_otc_revenue;

-- Q19 — Which products have the highest sales volume?
CREATE OR REPLACE VIEW vw_top_products_units AS
SELECT
    s.ProductID,
    MAX(p.ProductName) AS ProductName,
    SUM(s.QuantitySold) AS TotalUnits,
    ROUND(SUM(s.TotalAmount), 2) AS TotalRevenue,
    COUNT(DISTINCT s.SaleID) AS TotalOrders
FROM medical_sales s
LEFT JOIN (
    SELECT
        ProductID,
        MAX(ProductName) AS ProductName
    FROM products
    GROUP BY ProductID
) p
    ON s.ProductID = p.ProductID
WHERE p.ProductName IS NOT NULL
  AND TRIM(p.ProductName) <> ''
  AND LOWER(TRIM(p.ProductName)) <> 'unknown'
GROUP BY s.ProductID
ORDER BY TotalUnits DESC
LIMIT 10;

SELECT * FROM vw_top_products_units;

-- Q20 — Which products generate the highest revenue per unit?
CREATE OR REPLACE VIEW vw_product_revenue_per_unit AS
SELECT
    s.ProductID,
    MAX(p.ProductName) AS ProductName,
    SUM(s.QuantitySold) AS TotalUnits,
    ROUND(SUM(s.TotalAmount), 2) AS TotalRevenue,
    ROUND(
        SUM(s.TotalAmount) / NULLIF(SUM(s.QuantitySold), 0),
        2
    ) AS RevenuePerUnit,
    COUNT(DISTINCT s.SaleID) AS TotalOrders
FROM medical_sales s
LEFT JOIN (
    SELECT
        ProductID,
        MAX(ProductName) AS ProductName
    FROM products
    GROUP BY ProductID
) p
    ON s.ProductID = p.ProductID
WHERE p.ProductName IS NOT NULL
  AND TRIM(p.ProductName) <> ''
  AND LOWER(TRIM(p.ProductName)) <> 'unknown'
GROUP BY s.ProductID
HAVING SUM(s.QuantitySold) > 0
ORDER BY RevenuePerUnit DESC
LIMIT 10;

SELECT * FROM vw_product_revenue_per_unit;

-- Q21 — Which regions generate the highest sales volume?
CREATE OR REPLACE VIEW vw_region_sales_volume AS
SELECT
    Region,
    SUM(QuantitySold) AS TotalUnits,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    COUNT(DISTINCT SaleID) AS TotalOrders
FROM medical_sales
WHERE Region IS NOT NULL
  AND TRIM(Region) <> ''
GROUP BY Region
ORDER BY TotalUnits DESC;

SELECT * FROM vw_region_sales_volume;

-- Q22 — Which cities generate the highest sales volume?
CREATE OR REPLACE VIEW vw_city_sales_volume AS
SELECT
    City,
    SUM(QuantitySold) AS TotalUnits,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    COUNT(DISTINCT SaleID) AS TotalOrders
FROM medical_sales
WHERE City IS NOT NULL
  AND TRIM(City) <> ''
  AND LOWER(TRIM(City)) <> 'unknown'
GROUP BY City
ORDER BY TotalUnits DESC;

SELECT * FROM vw_city_sales_volume;

-- Q23 — Which customer types generate the highest sales volume?
CREATE OR REPLACE VIEW vw_customer_type_sales_volume AS
SELECT
    CustomerType,
    SUM(QuantitySold) AS TotalUnits,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    COUNT(DISTINCT SaleID) AS TotalOrders
FROM medical_sales
WHERE CustomerType IS NOT NULL
  AND TRIM(CustomerType) <> ''
  AND LOWER(TRIM(CustomerType)) <> 'unknown'
GROUP BY CustomerType
ORDER BY TotalUnits DESC;

SELECT * FROM vw_customer_type_sales_volume;

-- Q24 — Which categories have the highest sales volume?
CREATE OR REPLACE VIEW vw_category_sales_volume AS
SELECT
    p.Category,
    SUM(s.QuantitySold) AS TotalUnits,
    ROUND(SUM(s.TotalAmount), 2) AS TotalRevenue,
    COUNT(DISTINCT s.SaleID) AS TotalOrders
FROM medical_sales s
JOIN (
    SELECT
        ProductID,
        MAX(Category) AS Category
    FROM products
    GROUP BY ProductID
) p
    ON s.ProductID = p.ProductID
WHERE p.Category IS NOT NULL
  AND TRIM(p.Category) <> ''
  AND LOWER(TRIM(p.Category)) <> 'unknown'
GROUP BY p.Category
ORDER BY TotalUnits DESC;

SELECT * FROM vw_category_sales_volume;

-- Q22 — How can inventory be optimized between warehouses?
CREATE OR REPLACE VIEW vw_warehouse_inventory_optimization AS
SELECT
    WarehouseLocation,
    SUM(OpeningStock) AS OpeningStock,
    SUM(StockReceived) AS StockReceived,
    SUM(StockSold) AS StockSold,
    SUM(ClosingStock) AS ClosingStock,
    SUM(ReorderLevel) AS ReorderLevel,
    COUNT(*) AS InventoryRecords,

    ROUND(
        SUM(ClosingStock) * 100.0 /
        NULLIF(SUM(OpeningStock) + SUM(StockReceived), 0),
        2
    ) AS ClosingStockPercent,

    ROUND(
        SUM(StockSold) * 100.0 /
        NULLIF(SUM(OpeningStock) + SUM(StockReceived), 0),
        2
    ) AS StockUtilizationPercent

FROM inventory
WHERE WarehouseLocation IS NOT NULL
  AND TRIM(WarehouseLocation) <> ''
GROUP BY WarehouseLocation
ORDER BY ClosingStock DESC;

SELECT * FROM vw_warehouse_inventory_optimization;

-- 23. Which products have high sales but low inventory? Identify potential stockout/high-demand products.
CREATE OR REPLACE VIEW vw_high_sales_low_inventory AS
SELECT
    i.ProductID,
    MAX(p.ProductName) AS ProductName,
    SUM(i.ClosingStock) AS ClosingStock,
    SUM(i.StockSold) AS TotalStockSold,
    SUM(i.ReorderLevel) AS ReorderLevel,
    COUNT(*) AS InventoryRecords,
    ROUND(
        SUM(i.ClosingStock) * 100.0 /
        NULLIF(SUM(i.StockSold), 0),
        2
    ) AS StockToSalesPercent
FROM inventory i
LEFT JOIN (
    SELECT
        ProductID,
        MAX(ProductName) AS ProductName
    FROM products
    GROUP BY ProductID
) p
    ON i.ProductID = p.ProductID
WHERE p.ProductName IS NOT NULL
  AND TRIM(p.ProductName) <> ''
  AND LOWER(TRIM(p.ProductName)) <> 'unknown'
GROUP BY i.ProductID
HAVING SUM(i.StockSold) > 0
ORDER BY StockToSalesPercent ASC
LIMIT 20;

SELECT * FROM vw_high_sales_low_inventory;

--  Q24 — High Inventory + Low Sales
CREATE OR REPLACE VIEW vw_high_inventory_low_sales AS
SELECT
    i.ProductID,
    MAX(p.ProductName) AS ProductName,
    SUM(i.ClosingStock) AS ClosingStock,
    SUM(i.StockSold) AS TotalStockSold,
    SUM(i.ReorderLevel) AS ReorderLevel,
    COUNT(*) AS InventoryRecords,
    ROUND(
        SUM(i.StockSold) * 100.0 /
        NULLIF(SUM(i.ClosingStock), 0),
        2
    ) AS SalesToStockPercent
FROM inventory i
LEFT JOIN (
    SELECT
        ProductID,
        MAX(ProductName) AS ProductName
    FROM products
    GROUP BY ProductID
) p
    ON i.ProductID = p.ProductID
WHERE p.ProductName IS NOT NULL
  AND TRIM(p.ProductName) <> ''
  AND LOWER(TRIM(p.ProductName)) <> 'unknown'
GROUP BY i.ProductID
HAVING SUM(i.ClosingStock) > 0
ORDER BY SalesToStockPercent ASC
LIMIT 20;

SELECT * FROM vw_high_inventory_low_sales;

-- Q25 — Expired Product/Batch Records
CREATE OR REPLACE VIEW vw_expired_product_batches AS
SELECT
    COUNT(*) AS ExpiredBatchRecords,
    COUNT(DISTINCT ProductID) AS ExpiredProducts,
    MIN(ExpiryDate) AS EarliestExpiryDate,
    MAX(ExpiryDate) AS LatestExpiryDate
FROM products
WHERE ExpiryDate < CURDATE();

SELECT * FROM vw_expired_product_batches;

-- 26.Which warehouses are holding products that are close to expiry?
CREATE OR REPLACE VIEW vw_warehouse_expiry_risk AS
SELECT
    i.WarehouseLocation,
    COUNT(*) AS InventoryRecords,
    COUNT(DISTINCT i.ProductID) AS ProductsAtRisk,
    SUM(i.ClosingStock) AS ClosingStockAtRisk
FROM inventory i
JOIN products p
    ON i.ProductID = p.ProductID
WHERE p.ExpiryDate BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 90 DAY)
  AND i.ClosingStock > 0
  AND i.WarehouseLocation IS NOT NULL
  AND TRIM(i.WarehouseLocation) <> ''
GROUP BY i.WarehouseLocation
ORDER BY ClosingStockAtRisk DESC;

SELECT * FROM vw_warehouse_expiry_risk;

-- Q27. Which product categories have the highest expiry exposure?
CREATE OR REPLACE VIEW vw_category_expiry_risk AS
SELECT
    p.Category,
    COUNT(*) AS ExpiredOrAtRiskBatches,
    COUNT(DISTINCT p.ProductID) AS ProductsAtRisk,
    SUM(i.ClosingStock) AS ClosingStockAtRisk
FROM products p
JOIN inventory i
    ON p.ProductID = i.ProductID
WHERE p.ExpiryDate <= DATE_ADD(CURDATE(), INTERVAL 90 DAY)
  AND i.ClosingStock > 0
  AND p.Category IS NOT NULL
  AND TRIM(p.Category) <> ''
  AND LOWER(TRIM(p.Category)) <> 'unknown'
GROUP BY p.Category
ORDER BY ClosingStockAtRisk DESC;

SELECT * FROM vw_category_expiry_risk;

-- Q28.Which warehouses are holding the highest inventory quantities? 
CREATE OR REPLACE VIEW vw_warehouse_inventory_value AS
SELECT
    WarehouseLocation,
    SUM(ClosingStock) AS ClosingStock,
    SUM(OpeningStock) AS OpeningStock,
    SUM(StockReceived) AS StockReceived,
    SUM(StockSold) AS StockSold,
    COUNT(DISTINCT ProductID) AS ProductsStored
FROM inventory
WHERE WarehouseLocation IS NOT NULL
  AND TRIM(WarehouseLocation) <> ''
GROUP BY WarehouseLocation
ORDER BY ClosingStock DESC;

SELECT * FROM vw_warehouse_inventory_value;

-- Q29 — Products requiring immediate reorder
CREATE OR REPLACE VIEW vw_products_immediate_reorder AS
SELECT
    i.ProductID,
    MAX(p.ProductName) AS ProductName,
    SUM(i.ClosingStock) AS ClosingStock,
    SUM(i.ReorderLevel) AS ReorderLevel,
    SUM(i.StockSold) AS StockSold,
    ROUND(
        (SUM(i.ReorderLevel) - SUM(i.ClosingStock)) * 100.0 /
        NULLIF(SUM(i.ReorderLevel), 0),
        2
    ) AS ReorderGapPercent
FROM inventory i
LEFT JOIN (
    SELECT
        ProductID,
        MAX(ProductName) AS ProductName
    FROM products
    GROUP BY ProductID
) p
    ON i.ProductID = p.ProductID
WHERE p.ProductName IS NOT NULL
  AND TRIM(p.ProductName) <> ''
  AND LOWER(TRIM(p.ProductName)) <> 'unknown'
GROUP BY i.ProductID
HAVING SUM(i.ClosingStock) < SUM(i.ReorderLevel)
ORDER BY ReorderGapPercent DESC;

SELECT * FROM vw_products_immediate_reorder;

-- Q30 — Potentially overstocked products
CREATE OR REPLACE VIEW vw_potentially_overstocked_products AS
SELECT
    i.ProductID,
    MAX(p.ProductName) AS ProductName,
    SUM(i.ClosingStock) AS ClosingStock,
    SUM(i.StockSold) AS StockSold,
    SUM(i.ReorderLevel) AS ReorderLevel,
    ROUND(
        SUM(i.ClosingStock) * 100.0 /
        NULLIF(SUM(i.StockSold), 0),
        2
    ) AS StockToSalesPercent
FROM inventory i
LEFT JOIN (
    SELECT
        ProductID,
        MAX(ProductName) AS ProductName
    FROM products
    GROUP BY ProductID
) p
    ON i.ProductID = p.ProductID
WHERE p.ProductName IS NOT NULL
  AND TRIM(p.ProductName) <> ''
  AND LOWER(TRIM(p.ProductName)) <> 'unknown'
GROUP BY i.ProductID
HAVING SUM(i.StockSold) > 0
ORDER BY StockToSalesPercent DESC
LIMIT 20;

SELECT * FROM vw_potentially_overstocked_products;

-- Q31 — What does negative quantity mean?
CREATE OR REPLACE VIEW vw_negative_sales_analysis AS
SELECT
    COUNT(*) AS NegativeSalesRecords,
    SUM(ABS(QuantitySold)) AS NegativeUnits,
    ROUND(SUM(ABS(TotalAmount)), 2) AS NegativeSalesValue
FROM medical_sales
WHERE QuantitySold < 0;

SELECT * FROM vw_negative_sales_analysis;

-- Q32 — Why are there no negative sales quantities?
CREATE OR REPLACE VIEW vw_sales_quantity_quality AS
SELECT
    COUNT(*) AS TotalSalesRecords,
    SUM(CASE WHEN QuantitySold > 0 THEN 1 ELSE 0 END) AS PositiveQuantityRecords,
    SUM(CASE WHEN QuantitySold = 0 THEN 1 ELSE 0 END) AS ZeroQuantityRecords,
    SUM(CASE WHEN QuantitySold < 0 THEN 1 ELSE 0 END) AS NegativeQuantityRecords,
    MIN(QuantitySold) AS MinimumQuantity,
    MAX(QuantitySold) AS MaximumQuantity
FROM medical_sales;

SELECT * FROM vw_sales_quantity_quality;

-- Q33 — Which products have the highest number of sales transactions?
CREATE OR REPLACE VIEW vw_top_products_transaction_count AS
SELECT
    s.ProductID,
    MAX(p.ProductName) AS ProductName,
    COUNT(DISTINCT s.SaleID) AS SalesTransactionCount,
    SUM(s.QuantitySold) AS TotalUnitsSold,
    ROUND(SUM(s.TotalAmount), 2) AS TotalRevenue
FROM medical_sales s
LEFT JOIN (
    SELECT
        ProductID,
        MAX(ProductName) AS ProductName
    FROM products
    GROUP BY ProductID
) p
    ON s.ProductID = p.ProductID
WHERE p.ProductName IS NOT NULL
  AND TRIM(p.ProductName) <> ''
  AND LOWER(TRIM(p.ProductName)) <> 'unknown'
GROUP BY s.ProductID
ORDER BY SalesTransactionCount DESC
LIMIT 20;

SELECT * FROM vw_top_products_transaction_count;

-- Q34 — Which products generate the highest revenue per transaction?
CREATE OR REPLACE VIEW vw_product_revenue_per_transaction AS
SELECT
    s.ProductID,
    MAX(p.ProductName) AS ProductName,
    COUNT(DISTINCT s.SaleID) AS SalesTransactionCount,
    ROUND(SUM(s.TotalAmount), 2) AS TotalRevenue,
    ROUND(
        SUM(s.TotalAmount) / NULLIF(COUNT(DISTINCT s.SaleID), 0),
        2
    ) AS RevenuePerTransaction
FROM medical_sales s
LEFT JOIN (
    SELECT
        ProductID,
        MAX(ProductName) AS ProductName
    FROM products
    GROUP BY ProductID
) p
    ON s.ProductID = p.ProductID
WHERE p.ProductName IS NOT NULL
  AND TRIM(p.ProductName) <> ''
  AND LOWER(TRIM(p.ProductName)) <> 'unknown'
GROUP BY s.ProductID
HAVING COUNT(DISTINCT s.SaleID) >= 10
ORDER BY RevenuePerTransaction DESC
LIMIT 20;

SELECT * FROM vw_product_revenue_per_transaction;

-- Q35 — Which payment modes generate the most revenue?

CREATE OR REPLACE VIEW vw_payment_mode_revenue AS
SELECT
    PaymentMode,
    COUNT(DISTINCT SaleID) AS TotalTransactions,
    SUM(QuantitySold) AS TotalUnitsSold,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    ROUND(
        SUM(TotalAmount) * 100.0 /
        NULLIF((SELECT SUM(TotalAmount) FROM medical_sales), 0),
        2
    ) AS RevenuePercentage
FROM medical_sales
WHERE PaymentMode IS NOT NULL
  AND TRIM(PaymentMode) <> ''
GROUP BY PaymentMode
ORDER BY TotalRevenue DESC;

SELECT * FROM vw_payment_mode_revenue;

-- Q20: How much revenue is affected by discounts, and which discount levels generate the highest revenue?
CREATE OR REPLACE VIEW vw_discount_impact AS
SELECT
    DiscountPercent,
    COUNT(DISTINCT SaleID) AS TotalTransactions,
    SUM(QuantitySold) AS TotalUnitsSold,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    ROUND(
        SUM(TotalAmount) * 100.0 /
        NULLIF((SELECT SUM(TotalAmount) FROM medical_sales), 0),
        2
    ) AS RevenuePercentage
FROM medical_sales
GROUP BY DiscountPercent
ORDER BY DiscountPercent;

SELECT * FROM vw_discount_impact;


CREATE OR REPLACE VIEW vw_page1_sales_detail AS
SELECT
    s.SaleID,
    s.SaleDate,
    YEAR(s.SaleDate) AS SaleYear,
    MONTH(s.SaleDate) AS SaleMonthNumber,
    MONTHNAME(s.SaleDate) AS SaleMonthName,
    s.Region,
    s.State,
    s.City,
    s.ProductID,
    COALESCE(p.Category, 'Unknown') AS Category,
    s.QuantitySold,
    s.TotalAmount,
    s.CustomerType,
    s.PaymentMode
FROM medical_sales s
LEFT JOIN (
    SELECT
        ProductID,
        MAX(Category) AS Category
    FROM products
    GROUP BY ProductID
) p
ON s.ProductID = p.ProductID;

SELECT COUNT(*) FROM vw_page1_sales_detail;

