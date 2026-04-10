use adventure_works;
SET SQL_SAFE_UPDATES = 0;

SELECT * FROM SALES;
SELECT * FROM DIMCUSTOMER;
SELECT * FROM dimsalesterritory;
SELECT * FROM dimproduct1;


UPDATE sales
SET 
    OrderDate = STR_TO_DATE(OrderDate, '%d-%m-%Y'),
    ShipDate = STR_TO_DATE(ShipDate, '%d-%m-%Y'),
    DueDate = STR_TO_DATE(DueDate, '%d-%m-%Y');
    
ALTER TABLE sales
MODIFY COLUMN OrderDate DATETIME,
MODIFY COLUMN ShipDate DATETIME,
MODIFY COLUMN DueDate DATETIME;
    
# ################################################ TOTALS KPI ###################################################################################################
-- --------------------------------------------------------------------------------TOTAL SALES 
SELECT 
    CASE
        WHEN SUM(SalesAmount) >= 1000000 THEN 
            CONCAT(ROUND(SUM(SalesAmount) / 1000000, 2), ' M')
        WHEN SUM(SalesAmount) >= 1000 THEN 
            CONCAT(ROUND(SUM(SalesAmount) / 1000, 2), ' K')
        ELSE 
            ROUND(SUM(SalesAmount), 2)
    END AS 'TOTAL SALES'
FROM sales;

-- --------------------------------------------------------------------------------TOTAL PROFIT 
SELECT 
    CASE
        WHEN (SUM(SalesAmount) - SUM(TotalProductCost)) >= 1000000 THEN 
            CONCAT(ROUND((SUM(SalesAmount) - SUM(TotalProductCost)) / 1000000, 2), ' M')
        WHEN (SUM(SalesAmount) - SUM(TotalProductCost)) >= 1000 THEN 
            CONCAT(ROUND((SUM(SalesAmount) - SUM(TotalProductCost)) / 1000, 2), ' K')
        ELSE 
            ROUND((SUM(SalesAmount) - SUM(TotalProductCost)), 2)
    END AS 'TOTAL PROFIT'
FROM sales;

-- --------------------------------------------------------------------------------TOTAL ORDERDS
SELECT
COUNT(distinct SALESORDERNUMBER) AS 'TOTAL ORDERS'
FROM SALES;

-- --------------------------------------------------------------------------------TOTAL CUSTOMERS
SELECT
COUNT(distinct CUSTOMERKEY) AS 'TOTAL CUSTOMERS'
FROM DIMCUSTOMER;

-- --------------------------------------------------------------------------------TOTAL QUANTITY
SELECT
SUM(ORDERQUANTITY) AS 'TOTAL QUANTITY'
FROM SALES;

# ################################################ PROFIT MARGIN, NET PROFIT MARGIN ######################################################################################
-- --------------------------------------------------------------------------------PROFIT MARGIN
SELECT 
    ROUND(
        ((SUM(SalesAmount) - SUM(TotalProductCost)) / SUM(SalesAmount)) * 100, 
        2
    ) AS 'PROFIT MARGIN %'
FROM sales;

-- --------------------------------------------------------------------------------NET PROFIT MARGIN
SELECT 
    ROUND(
        (
            (SUM(SalesAmount) - SUM(TotalProductCost) - SUM(TaxAmt) - SUM(Freight))
            / SUM(SalesAmount)
        ) * 100, 
        2
    ) AS 'NET PROFIT MARGIN %'
FROM sales;

# ################################################ AVERAGES ###################################################################################################
-- --------------------------------------------------------------------------------AVG SALES PER CUSTOMER
SELECT 
    ROUND(SUM(SalesAmount) / COUNT(DISTINCT CustomerKey), 0) AS Avg_Sales_Per_Customer
FROM sales;

-- --------------------------------------------------------------------------------AVG ORDER VALUE
SELECT 
    ROUND(SUM(SalesAmount) / COUNT(DISTINCT SALESORDERNUMBER), 2) AS Avg_Order_Value
FROM sales;

# ################################################ OVER A PERIOD ###################################################################################################
-- --------------------------------------------------------------------------------MONTH AND YEAR WISE SALES, PROFIT,PROFIT MARGIN, ORDERS
SELECT
  YEAR(OrderDate) AS order_year,
  MONTHNAME(OrderDate) AS month_name,
  month(OrderDate) AS month_number,
    CASE
        WHEN SUM(SalesAmount) >= 1000000 THEN 
            CONCAT(ROUND(SUM(SalesAmount) / 1000000, 2), ' M')
        WHEN SUM(SalesAmount) >= 1000 THEN 
            CONCAT(ROUND(SUM(SalesAmount) / 1000, 2), ' K')
        ELSE 
            ROUND(SUM(SalesAmount), 2)
    END AS 'TOTAL SALES',
    CASE
        WHEN (SUM(SalesAmount) - SUM(TotalProductCost)) >= 1000000 THEN 
            CONCAT(ROUND((SUM(SalesAmount) - SUM(TotalProductCost)) / 1000000, 2), ' M')
        WHEN (SUM(SalesAmount) - SUM(TotalProductCost)) >= 1000 THEN 
            CONCAT(ROUND((SUM(SalesAmount) - SUM(TotalProductCost)) / 1000, 2), ' K')
        ELSE 
            ROUND((SUM(SalesAmount) - SUM(TotalProductCost)), 2)
    END AS 'TOTAL PROFIT',
    ROUND(
        ((SUM(SalesAmount) - SUM(TotalProductCost)) / SUM(SalesAmount)) * 100, 
        2
    ) AS 'PROFIT MARGIN %',
      COUNT(DISTINCT SALESORDERNUMBER) AS 'TOTAL ORDERS'
FROM sales
GROUP BY YEAR(OrderDate),month(OrderDate), MONTHNAME(OrderDate)
ORDER BY YEAR(OrderDate),month(OrderDate),MONTHNAME(OrderDate);

-- --------------------------------------------------------------------------------MONTH AND YEAR WISE SALES, YOY SALES, MONTHLY YOY SALES GROWTH %
WITH monthly_sales AS (
    SELECT
        YEAR(OrderDate)  AS order_year,
        MONTH(OrderDate) AS order_month,
        MONTHNAME(OrderDate) AS month_name,
        ROUND(SUM(SalesAmount),1) AS total_sales
    FROM sales
    GROUP BY YEAR(OrderDate), MONTH(OrderDate),MONTHNAME(OrderDate)
)
SELECT
    ms.order_year,
    ms.month_name,
    ms.total_sales,
    prev.total_sales AS prev_year_sales,
    ROUND(ms.total_sales - prev.total_sales, 2) AS yoy_change,
    ROUND(((ms.total_sales - prev.total_sales) / prev.total_sales) * 100, 2) AS yoy_growth_percent
FROM monthly_sales ms
LEFT JOIN monthly_sales prev
    ON ms.order_month = prev.order_month
   AND ms.order_year = prev.order_year + 1
ORDER BY ms.order_year, ms.order_month;

-- -------------------------------------------------------------------------------- YEAR AND QUARTER WISE SALES, PROFIT
SELECT
    YEAR(OrderDate) AS _Year,
    QUARTER(OrderDate) AS _Quarter,
    ROUND(SUM(SalesAmount), 2) AS Total_Sales,
    ROUND(SUM(SalesAmount - TotalProductCost), 2) AS Total_Profit
FROM sales
GROUP BY 
    YEAR(OrderDate),
    QUARTER(OrderDate)
ORDER BY 
    _Year,
    _Quarter;

# ################################################ TOP N ###################################################################################################
-- --------------------------------------------------------------------------------TOP 5 PRODUCTS
SELECT
    p.EnglishProductName as 'Product Name',
    SUM(s.SalesAmount) AS Total_Sales
FROM sales s
JOIN dimproduct1 p
    ON s.ProductKey = p.ProductKey
GROUP BY p.EnglishProductName
ORDER BY Total_Sales desc
LIMIT 5;
-- --------------------------------------------------------------------------------TOP 5 Customers
SELECT
    c.FullName,
    round(sum(s.SalesAmount),0) AS total_sales
FROM sales s
JOIN dimcustomer c
    ON s.CustomerKey = c.CustomerKey
GROUP BY c.FullName
ORDER BY total_sales DESC
LIMIT 5;

# ################################################ COUNTRY, PRODUCT WISE METRICS ###################################################################################################
-- --------------------------------------------------------------------------------COUNTRY WISE SASLES,PROFIT MARGIN
SELECT
    t.SalesTerritoryCountry AS country,
    round(SUM(s.SalesAmount)) AS total_sales,
    ROUND(
        ((SUM(SalesAmount) - SUM(TotalProductCost)) / SUM(SalesAmount)) * 100, 
        2
    ) AS 'Profit_Margin_%'
FROM sales s
JOIN dimsalesterritory t
    ON s.SalesTerritoryKey = t.SalesTerritoryAlternateKey
GROUP BY t.SalesTerritoryCountry
ORDER BY total_sales DESC;

-- --------------------------------------------------------------------------------COUNTRY WISE SASLES WITH TOTAL
SELECT 
    t.SalesTerritoryCountry AS Country,
    ROUND(SUM(s.SalesAmount), 2) AS Total_Sales
FROM sales s
JOIN dimsalesterritory t 
    ON s.SalesTerritoryKey = t.SalesTerritoryAlternateKey
GROUP BY t.SalesTerritoryCountry

UNION ALL

SELECT 
    'TOTAL' AS Country,
    ROUND(SUM(s.SalesAmount), 2) AS Total_Sales
FROM sales s
JOIN dimsalesterritory t 
    ON s.SalesTerritoryKey = t.SalesTerritoryAlternateKey
ORDER BY 
    CASE WHEN Country = 'TOTAL' THEN 2 ELSE 1 END,
    Total_Sales DESC;

-- --------------------------------------------------------------------------------PRODUCT CATEGORY WISE SASLES    
SELECT 
    p.EnglishProductCategoryName AS Product_Category,
    ROUND(SUM(s.SalesAmount), 2) AS Total_Sales
FROM sales s
JOIN dimproduct1 p 
    ON s.ProductKey = p.ProductKey
GROUP BY 
    p.EnglishProductCategoryName
ORDER BY 
    Total_Sales DESC;

-- --------------------------------------------------------------------------------PRODUCT SUBCATEGORY WISE SASLES 
SELECT 
    p.EnglishProductSubcategoryName AS Product_SUBCategory,
    ROUND(SUM(s.SalesAmount), 2) AS Total_Sales
FROM sales s
JOIN dimproduct1 p 
    ON s.ProductKey = p.ProductKey
GROUP BY 
    p.EnglishProductSubcategoryName
ORDER BY 
    Total_Sales DESC;

-- --------------------------------------------------------------------------------VIEW FOR SALES & PROFIT BY COUNTRY OR PRODUCT CATEGORY OR PRODUCT SUBCATEGORY

CREATE OR REPLACE VIEW vw_total_sales_summary AS
SELECT 
    t.SalesTerritoryCountry AS Country,
    p.EnglishProductCategoryName AS Product_Category,
    p.EnglishProductSubcategoryName AS Product_Subcategory,
    ROUND(SUM(s.SalesAmount), 2) AS Total_Sales,
    ROUND(SUM(s.Salesamount)-SUM(s.TotalProductCost),2) AS Total_Profit
FROM sales s
LEFT JOIN dimproduct1 p 
    ON s.ProductKey = p.ProductKey
LEFT JOIN dimsalesterritory t 
    ON s.SalesTerritoryKey = t.SalesTerritoryAlternateKey
GROUP BY 
    t.SalesTerritoryCountry,
    p.EnglishProductCategoryName,
    p.EnglishProductSubcategoryName;

-- -------------------------------------------------------------------------------Show data for specific country
SELECT * 
FROM vw_total_sales_summary
WHERE Country = 'United States';

-- -------------------------------------------------------------------------------Show data for specific category
SELECT * 
FROM vw_total_sales_summary
WHERE Product_Category = 'Bikes';

-- -------------------------------------------------------------------------------Show data for specific subcategory
SELECT * 
FROM vw_total_sales_summary
WHERE Product_Subcategory = 'Mountain Bikes';

