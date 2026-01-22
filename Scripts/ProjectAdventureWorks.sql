create database AdventureWorks;
use AdventureWorks;

#######################################################################################################################################

SHOW VARIABLES LIKE 'secure_file_priv';

#######################################################################################################################################

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/AdventureWorks/Dimcustomer.csv' into table Dimcustomer
FIELDS TERMINATED by ','
optionally  enclosed by '"'
lines terminated by '\r\n'
IGNORE 1 rows;

#######################################################################################################################################

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/AdventureWorks/DimDate.csv' into table Dimdate
FIELDS TERMINATED by ','
optionally  enclosed by '"'
lines terminated by '\r\n'
IGNORE 1 rows;

#######################################################################################################################################

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/AdventureWorks/DimProduct.csv' into table Dimproduct
FIELDS TERMINATED by ','
optionally  enclosed by '"'
lines terminated by '\r\n'
IGNORE 1 rows;

#######################################################################################################################################

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/AdventureWorks/FactInternetSales1.csv' into table factinternetsales1
FIELDS TERMINATED by ','
optionally  enclosed by '"'
lines terminated by '\r\n'
IGNORE 1 rows;

select * from factinternetsales1;
desc factinternetsales;
select productkey from factinternetsales1;

#######################################################################################################################################

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/AdventureWorks/FactInternetSales_New.csv' into table factinternetsales_new
FIELDS TERMINATED by ','
optionally  enclosed by '"'
lines terminated by '\r\n'
IGNORE 1 rows;

select * from factinternetsales_new;
select productkey from factinternetsales_new;

#######################################################################################################################################

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/AdventureWorks/Sales.csv' into table Dimsales
FIELDS TERMINATED by ','
optionally  enclosed by '"'
lines terminated by '\r\n'
IGNORE 1 rows;

#######################################################################################################################################

select * from dimdate;
desc dimdate;

select * from dimcustomer;
desc dimcustomer;

select * from dimproductcategory;
desc dimproductcategory;

select * from dimproduct;
desc dimproduct;

select * from dimproductsubcategory;
desc dimproductsubcategory;

select * from dimsalesterritory;
desc dimsalesterritory;

select * from dimsales;
desc dimsales;

select * from factinternetsales1;
desc factinternetsales1;

select * from factinternetsales_new;
desc factinternetsales_new;

#######################################################################################################################################

ALTER TABLE factinternetsales_new MODIFY OrderDate Date;
ALTER TABLE factinternetsales_new MODIFY ShipDate Date;
ALTER TABLE factinternetsales_new MODIFY DueDate Date;
ALTER TABLE dimcustomer MODIFY DateFirstPurchase DATE;

#######################################################################################################################################
#######################################################################################################################################
#######################################################################################################################################

#  Q0. Union of Fact Internet Sales and Fact Internet Sales New

SELECT * FROM factinternetsales1;
SELECT * FROM factinternetsales_new ;

SELECT * FROM factinternetsales1
UNION ALL
SELECT * FROM factinternetsales_new ;

#__________________________________________________________________________________________________________________________________________________

#  Q1. Lookup Product Name from Product Sheet to sales sheet-

SELECT * FROM sales;
select * from dimproduct ;


SELECT 
s.SalesOrderNumber, s.ProductKey, p.EnglishProductName
FROM sales s
JOIN dimproduct p
using(productkey);

 #__________________________________________________________________________________________________________________________________________________
#  Q2. Lookup customerfullnameName from customer  and unit price from product sheet to sales sheet-

SELECT * FROM sales;
select * from dimcustomer;
select * from dimproduct ;

SELECT
s.SalesOrderNumber, CONCAT(c.FirstName, ' ', c.LastName) AS CustomerFullName, p.UnitPrice
FROM sales s
JOIN dimcustomer c using (customerkey)
JOIN dimproduct p using (productkey);

  
    #_______________________________________________________________________________________________________________________________________
    
    # Q3. Date Calculations (Year, Month, Quarter, etc.)
    
SELECT
FullDateAlternateKey AS OrderDate, YEAR(FullDateAlternateKey) AS Years ,
    MONTH(FullDateAlternateKey) AS MonthNo,
    MONTHNAME(FullDateAlternateKey) AS MonthFullName,
    CONCAT('Q', QUARTER(FullDateAlternateKey)) AS Quarter,
    weekday(FullDateAlternateKey)+1 as weekdayno,
    dayname(FullDateAlternateKey) as weekdayname,
DATE_FORMAT(FullDateAlternateKey, '%Y-%b') AS YearMonth

from  dimdate ;

-- -----------------------------------------------------------------------------------------

/* SQL has no built-in financial year function . We need custom business logic
 We use CASE WHEN in SQL to apply logic.CASE allows us to apply conditions and mapping in sql.
Concept before query -

Financial Month logic: Financial year is shifted 3 months forward from calendar year

First 9 months → MONTH − 3
Last 3 months → MONTH + 9
so,If month ≥ 4 (April–Dec) → subtract 3
If month ≤ 3 (Jan–Mar) → add 9

SQL CASE logic -
CASE
WHEN MONTH(date) >= 4 , THEN MONTH(date) - 3
ELSE
MONTH(date) + 9
END AS FinancialMonth*/

 #  SQL Query – Financial Month
 
SELECT d.FullDateAlternateKey AS OrderDate, MONTH(d.FullDateAlternateKey) AS CalendarMonth,
CASE
WHEN MONTH(d.FullDateAlternateKey) >= 4
THEN MONTH(d.FullDateAlternateKey) - 3
ELSE
MONTH(d.FullDateAlternateKey) + 9
END AS FinancialMonth
FROM dimdate d;
-- -----------------------------------------------------------------------------------------

/* Financial Quarter logic: we will map financial quarter from calendar quarter.
Q1	Jan–Mar	Q4 
Q2	Apr–Jun	Q1
Q3	Jul–Sep	Q2
Q4	Oct–Dec	Q3

So mapping is:
Calendar Q1 → Financial Q4
Calendar Q2 → Financial Q1
Calendar Q3 → Financial Q2
Calendar Q4 → Financial Q3 */

# SQL Query – Financial Quarter

SELECT d.FullDateAlternateKey AS Date,
CONCAT('Q', QUARTER(d.FullDateAlternateKey)) AS CalendarQuarter,
CASE
WHEN QUARTER(d.FullDateAlternateKey) = 1 THEN 'Q4'
WHEN QUARTER(d.FullDateAlternateKey) = 2 THEN 'Q1'
WHEN QUARTER(d.FullDateAlternateKey) = 3 THEN 'Q2'
ELSE 'Q3'
END AS FinancialQuarter
FROM dimdate d;

#___________________________________________________________________________________________________________________________________________________

# Q4. Calculate Sales Amount Using Unit Price, Order Quantity, Unit Discount
# Sales Amount = Unit Price × Order Quantity

SELECT * FROM sales;

SELECT 
SalesOrderNumber, (UnitPrice * OrderQuantity) as sales
FROM sales ;


#__________________________________________________________________________________________________________________________________________

# Q5. Calculate Production Cost- Using Unit Cost and Order Quantity -
SELECT * FROM sales;
select * from dimproduct ;

select StandardCost from dimproduct;

 /* The StandardCost column is  stored as text because the data was loaded from a CSV file. 
 Due to this,  it contains no data in the table view. 
 However, when we run calculations in SQL, 
 MySQL automatically converts the text values into numeric form, which is why the production cost calculation still returns valid results. */


SELECT s.SalesOrderNumber, p.StandardCost * s.OrderQuantity AS ProductionCost
FROM sales s
JOIN dimproduct p
using(productkey);


#_______________________________________________________________________________________________________________________________________

# Q6. Calculate PROFIT
# Profit = Sales Amount − Production Cost

SELECT s.SalesOrderNumber,
round((s.UnitPrice * s.OrderQuantity) - (p.StandardCost * s.OrderQuantity),2) AS Profit
FROM sales s
JOIN dimproduct p
using(productkey);

#_________________________________________________________________________________________________________________________________________

# Q7. Month-wise Sales (Pivot-style)

SELECT MONTHNAME(d.FullDateAlternateKey) AS Months, round(SUM(s.UnitPrice * s.OrderQuantity),2) AS TotalSales
FROM sales s
JOIN dimdate d
ON s.OrderDateKey = d.DateKey
GROUP BY Months ;

#__________________________________________________________________________________________________________________________________

#  Q8. Year-wise Sales -

SELECT YEAR(d.FullDateAlternateKey) AS Years, round(SUM(s.UnitPrice * s.OrderQuantity),2) AS TotalSales
FROM sales s
JOIN dimdate d
ON s.OrderDateKey = d.DateKey
GROUP BY Years
ORDER BY years ;

#___________________________________________________________________________________________________________________________________--

# Q9. Month-wise Sales (Year–Month format)

SELECT
DATE_FORMAT(d.FullDateAlternateKey, '%Y-%b') AS YearMonth,
round(SUM(s.UnitPrice * s.OrderQuantity),2) AS TotalSales
FROM sales s
JOIN dimdate d
ON s.OrderDateKey = d.DateKey
GROUP BY YearMonth ;

#____________________________________________________________________________________________________________________________________

# Q10. Quarter-wise Sales-

SELECT
CONCAT('Q', QUARTER(d.FullDateAlternateKey)) AS Quarters,
round(SUM(s.UnitPrice * s.OrderQuantity),2) AS TotalSales
FROM sales s
JOIN dimdate d
ON s.OrderDateKey = d.DateKey
GROUP BY Quarters
ORDER BY Quarters ;

#______________________________________________________________________________________________________________________________---

# Q11. Sales Amount & Production Cost Together

SELECT
YEAR(d.FullDateAlternateKey) AS Years,
round( SUM(s.UnitPrice * s.OrderQuantity),2) AS TotalSales,
round(SUM(p.StandardCost * s.OrderQuantity),2) AS TotalProductionCost
FROM sales s
JOIN dimdate d
ON s.OrderDateKey = d.DateKey
JOIN dimproduct p
using(productkey)
GROUP BY years
ORDER BY Years ;

#______________________________________________________________________________________________________________________________---

# Region Wise Sales and Profit
SELECT 
    r.SalesTerritoryRegion AS Region,
	CASE 
		WHEN SUM(s.SalesAmount) >= 1000000 
			THEN CONCAT(ROUND(SUM(s.SalesAmount)/1000000, 2), 'M')
        WHEN SUM(s.SalesAmount) >= 1000 
			THEN CONCAT(ROUND(SUM(s.SalesAmount)/1000, 2), 'K')
        ELSE 
            FORMAT(SUM(s.SalesAmount), 0)
	END AS Total_Sales,
    CASE 
		WHEN SUM(Profit) >= 1000000 
			THEN CONCAT(ROUND(SUM(Profit)/1000000, 2), 'M')
        WHEN SUM(Profit) >= 1000 
			THEN CONCAT(ROUND(SUM(Profit)/1000, 2), 'K')
        ELSE 
            FORMAT(SUM(Profit), 0)
   END AS Total_Profit
FROM DimSales s
JOIN DimSalesTerritory r 
ON s.SalesTerritoryKey = r.SalesTerritoryKey
GROUP BY r.SalesTerritoryRegion;

#######################################################################################################################################

# Category Wise TotalSales, Total Profit, Total ProductionCost
SELECT 
    pc.EnglishProductCategoryName as Product_Name,
	CASE 
		WHEN SUM(s.SalesAmount) >= 1000000 
			THEN CONCAT(ROUND(SUM(s.SalesAmount)/1000000, 2), 'M')
        WHEN SUM(s.SalesAmount) >= 1000 
			THEN CONCAT(ROUND(SUM(s.SalesAmount)/1000, 2), 'K')
        ELSE 
            FORMAT(SUM(s.SalesAmount), 0)
	END AS Total_Sales,
	CASE 
		WHEN SUM(s.Profit) >= 1000000 
			THEN CONCAT(ROUND(SUM(s.Profit)/1000000, 2), 'M')
        WHEN SUM(s.Profit) >= 1000 
			THEN CONCAT(ROUND(SUM(s.Profit)/1000, 2), 'K')
        ELSE 
            FORMAT(SUM(s.Profit), 0)
	END AS Total_Profit,
	CASE 
		WHEN SUM(s.ProductionCost) >= 1000000 
			THEN CONCAT(ROUND(SUM(s.ProductionCost)/1000000, 2), 'M')
        WHEN SUM(s.ProductionCost) >= 1000 
			THEN CONCAT(ROUND(SUM(s.ProductionCost)/1000, 2), 'K')
        ELSE 
            FORMAT(SUM(s.ProductionCost), 0)
	END AS Total_ProductionCost
FROM DimSales s
JOIN DimProduct p ON s.ProductKey = p.ProductKey
JOIN DimProductSubCategory ps ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
JOIN DimProductCategory pc ON ps.ProductCategoryKey = pc.ProductCategoryKey
GROUP BY pc.EnglishProductCategoryName;

#######################################################################################################################################

# Total Sales, Total Profit, Total Production Cost, Total Profit Margin
select 
CASE 
		WHEN SUM(salesAmount) >= 1000000 
			THEN CONCAT(ROUND(SUM(salesAmount)/1000000, 2), 'M')
        WHEN SUM(salesAmount) >= 1000 
			THEN CONCAT(ROUND(SUM(salesAmount)/1000, 2), 'K')
        ELSE 
            FORMAT(SUM(salesAmount), 0)
END AS Total_Sales,
CASE 
		WHEN SUM(Profit) >= 1000000 
			THEN CONCAT(ROUND(SUM(Profit)/1000000, 2), 'M')
        WHEN SUM(Profit) >= 1000 
			THEN CONCAT(ROUND(SUM(Profit)/1000, 2), 'K')
        ELSE 
            FORMAT(SUM(Profit), 0)
END AS Total_Profit,
CASE 
		WHEN SUM(ProductionCost) >= 1000000 
			THEN CONCAT(ROUND(SUM(ProductionCost)/1000000, 2), 'M')
        WHEN SUM(ProductionCost) >= 1000 
			THEN CONCAT(ROUND(SUM(ProductionCost)/1000, 2), 'K')
        ELSE 
            FORMAT(SUM(ProductionCost), 0)
END AS Total_ProductionCost,
CASE 
		WHEN SUM(ProfitMargin) >= 1000000 
			THEN CONCAT(ROUND(SUM(ProfitMargin)/1000000, 2), 'M')
        WHEN SUM(ProfitMargin) >= 1000 
			THEN CONCAT(ROUND(SUM(ProfitMargin)/1000, 2), 'K')
        ELSE 
            FORMAT(SUM(ProfitMargin), 0)
END AS Total_ProfitMargin
from DimSales;

#######################################################################################################################################

# Top 5 Product Wise Sales

SELECT 
	row_number() over (order by sum(SalesAmount) desc) as S_No,
    s.ProductName as Product_Name,
	CASE 
		WHEN SUM(salesAmount) >= 1000000 
			THEN CONCAT(ROUND(SUM(salesAmount)/1000000, 2), 'M')
        WHEN SUM(salesAmount) >= 1000 
			THEN CONCAT(ROUND(SUM(salesAmount)/1000, 2), 'K')
        ELSE 
            FORMAT(SUM(salesAmount), 0)
	END AS Total_Sales
	FROM DimSales s
    JOIN Dimproduct p
    ON s.productkey = p.productkey
GROUP BY s.ProductName
Order by sum(SalesAmount) Desc
LIMIT 5;

#######################################################################################################################################

# Top 3 products in each category
SELECT *
FROM (
    SELECT 
		DENSE_RANK() OVER (
            PARTITION BY pc.EnglishProductCategoryName 
            ORDER BY SUM(s.SalesAmount) DESC
        ) AS _Rank_,
        pc.EnglishProductCategoryName AS Category,
        s.ProductName AS Product_Name,
		CASE 
			WHEN SUM(s.SalesAmount) >= 1000000 
				THEN CONCAT(ROUND(SUM(s.SalesAmount)/1000000, 2), 'M')
			WHEN SUM(s.SalesAmount) >= 1000 
				THEN CONCAT(ROUND(SUM(s.SalesAmount)/1000, 2), 'K')
			ELSE 
				FORMAT(SUM(s.SalesAmount), 0)
		END AS Total_Sales
    FROM DimSales s
    JOIN DimProduct p ON s.ProductKey = p.ProductKey
    JOIN DimProductSubCategory ps ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
    JOIN DimProductCategory pc ON ps.ProductCategoryKey = pc.ProductCategoryKey
    GROUP BY pc.EnglishProductCategoryName, s.ProductName
) t
WHERE _Rank_ <= 3;

#######################################################################################################################################

# Gender Wise Distribution
SELECT 
    c.Gender,
    COUNT(DISTINCT s.CustomerKey) AS Customer_Count
FROM DimSales s
JOIN DimCustomer c ON s.CustomerKey = c.CustomerKey
GROUP BY c.Gender;

# Region Wise Customer Count
SELECT 
    r.SalesTerritoryRegion AS Region,
    COUNT(DISTINCT s.CustomerKey) AS Customer_Count
FROM DimSales s
JOIN DimSalesTerritory r ON s.SalesTerritoryKey = r.SalesTerritoryKey
GROUP BY r.SalesTerritoryRegion  
ORDER BY COUNT(DISTINCT s.CustomerKey) Desc;

# Top 5 Customer Wise Sales
SELECT 
    ROW_NUMBER() OVER (ORDER BY SUM(s.SalesAmount) DESC) AS S_No,
    s.CustomerFullName as Customer_Name,
    CASE 
		WHEN SUM(salesAmount) >= 1000000 
			THEN CONCAT(ROUND(SUM(salesAmount)/1000000, 2), 'M')
        WHEN SUM(salesAmount) >= 1000 
			THEN CONCAT(ROUND(SUM(salesAmount)/1000, 2), 'K')
        ELSE 
            FORMAT(SUM(salesAmount), 0)
	END AS Total_Sales
	FROM DimSales s
	JOIN DimCustomer c 
    ON s.CustomerKey = c.CustomerKey
GROUP BY s.CustomerFullName
ORDER BY SUM(SalesAmount) DESC
LIMIT 5; 

#######################################################################################################################################

# Year-wise Sales with YoY %

SELECT 
    Year,
    CASE 
        WHEN Total_Sales >= 1000000 
            THEN CONCAT(ROUND(Total_Sales / 1000000, 2), 'M')
        WHEN Total_Sales >= 1000 
            THEN CONCAT(ROUND(Total_Sales / 1000, 2), 'K')
        ELSE FORMAT(Total_Sales, 0)
    END AS Total_Sales,

    CASE 
        WHEN Previous_Year_Sales >= 1000000 
            THEN CONCAT(ROUND(Previous_Year_Sales / 1000000, 2), 'M')
        WHEN Previous_Year_Sales >= 1000 
            THEN CONCAT(ROUND(Previous_Year_Sales / 1000, 2), 'K')
        ELSE FORMAT(Previous_Year_Sales, 0)
    END AS Previous_Year_Sales,
    ROUND(
        ((Total_Sales - Previous_Year_Sales) / Previous_Year_Sales) * 100, 2) AS YoY_Growth_Percentage
FROM (
    SELECT 
        YEAR(OrderDate) AS Year,
        SUM(SalesAmount) AS Total_Sales,
        LAG(SUM(SalesAmount)) OVER (ORDER BY YEAR(OrderDate)) AS Previous_Year_Sales
    FROM DimSales
    GROUP BY YEAR(OrderDate)
) t
ORDER BY Year;


