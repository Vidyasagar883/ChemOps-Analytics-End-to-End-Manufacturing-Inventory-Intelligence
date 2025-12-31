CREATE DATABASE IF NOT EXISTS Chemical_Manufacturing;
USE Chemical_Manufacturing;
CREATE TABLE IF NOT EXISTS Suppliers
(Supplier_ID INT PRIMARY KEY,
 Supplier_Name VARCHAR(50),
 Contact_Person VARCHAR(50),
 Email VARCHAR(50),
 Phone VARCHAR(30),
 Adress VARCHAR(80),
 Country VARCHAR(30),
 Supplier_Rating DECIMAL(3,2),
 Created_Date DATETIME
);

CREATE TABLE IF NOT EXISTS Raw_Materials
(   Material_id INT PRIMARY KEY,
	Material_Name VARCHAR(70),
	Material_Type VARCHAR(80),
	Unit_Cost	DECIMAL(5,2),
    Currency VARCHAR(20),
	Unit_Of_Measure	VARCHAR(10),
	Minimum_Stock_Level	DECIMAL(6,2),
	Current_Stock_Quantity DECIMAL(6,2),
	Supplier_ID INT,	
	Hazard_Classification VARCHAR(50),
    FOREIGN KEY(Supplier_ID) REFERENCES Suppliers(Supplier_ID)
);

CREATE TABLE IF NOT EXISTS Purchase_Orders
(Purchase_Order_Id	VARCHAR(10) PRIMARY KEY,
Supplier_Id	INT,
Material_id INT,
Order_Date	DATETIME,
Quantity_Ordered	DECIMAL(10,2),
Unit_Price	DECIMAL(10,2),
Total_Cost DECIMAL(10,2),
Expected_Delivery_Date DATETIME,	
Actual_Delivery_Date DATETIME,	
Order_Status VARCHAR(20),
Quality_Check_Passed BIT,
Created_At DATETIME,
FOREIGN KEY(Supplier_Id) REFERENCES Suppliers(Supplier_ID),
FOREIGN KEY(Material_Id) REFERENCES Raw_Materials(Material_id)
);

CREATE TABLE IF NOT EXISTS Products
(   product_id	VARCHAR(20) PRIMARY KEY,
	product_name VARCHAR(100),	
	product_category VARCHAR(100),
	foam_density DECIMAL(5,1),	
	foam_type VARCHAR(30),
	selling_price_per_unit DECIMAL(6,2),	
	production_cost_per_unit DECIMAL(6,2),	
	unit_of_measure	VARCHAR(10),
	application_industry VARCHAR(100),	
	is_active	BIT,
	Production_Date DATETIME
);

CREATE TABLE IF NOT EXISTS Batch_Productions
(   batch_id	BIGINT PRIMARY KEY,
	product_id	VARCHAR(20),
	batch_number VARCHAR(30),	
	production_date	DATETIME,
	quantity_produced DECIMAL(10,2),
	batch_status VARCHAR(20),	
	production_line	VARCHAR(30),
	operator_name	VARCHAR(100),
	production_cost	DECIMAL(10,2),
	quality_grade	VARCHAR(10),
	waste_percentage DECIMAL(10,2),
    FOREIGN KEY(product_id) REFERENCES Products(product_id)
);

CREATE TABLE IF NOT EXISTS Batch_Usage_Materials
(   usage_id VARCHAR(10) PRIMARY KEY,
	batch_id VARCHAR(20),
	material_id	INT,
	quantity_used	DECIMAL(10,2),
	cost_of_material DECIMAL(10,2),
	unit_of_measure VARCHAR(10),
    FOREIGN KEY(batch_id) REFERENCES Batch_Productions(batch_id)
);

CREATE TABLE IF NOT EXISTS Customers
( Customer_ID BIGINT PRIMARY KEY,
  customer_name	VARCHAR (50),
  contact_person VARCHAR(50),
  email	VARCHAR(60),
  phone	VARCHAR(30),
  Billing_Address	VARCHAR(80),
  Country	VARCHAR(40),
  Industry_Type	VARCHAR(50),
  Customer_Tier	VARCHAR(30),
  Created_at DATETIME
);

CREATE TABLE IF NOT EXISTS Sales_Orders
(   sales_order_id	VARCHAR(20) PRIMARY KEY,
	Customer_ID	BIGINT,
	product_id VARCHAR(20),	
	order_date	DATETIME,
	quantity_ordered	DECIMAL(10,2),
	unit_price	DECIMAL(10,2),
	total_amount	DECIMAL(10,2),
	delivery_date	DATETIME,
	order_status	VARCHAR(30),
	payment_status VARCHAR(30),
    FOREIGN KEY(Customer_ID) REFERENCES Customers(Customer_ID),
    FOREIGN KEY(product_id) REFERENCES Products(product_id)
);

-- DML Queries 
use chemical_manufacturing;
select * from suppliers;
select * from raw_materials;
select * from purchase_orders;
select * from products;
select * from batch_productions;
select * from batch_usage_materials;
select * from customers ;
select * from sales_orders;

select count(*) from customers ;
select count(*) from sales_orders;
select count(*) from raw_materials;
select count(*) from purchase_orders;
select count(*) from products;
select count(*) from batch_productions;
select count(*) from batch_usage_materials;


alter table purchase_orders modify column Order_Date DATE;
alter table purchase_orders modify column Expected_Delivery_Date DATE;
alter table purchase_orders modify column Actual_Delivery_Date DATE;
alter table purchase_orders drop column Actual_Delivery_Date;
alter table purchase_orders modify column  Quality_Check_Passed VARCHAR(7);
alter table products modify column Production_Date DATE;
alter table products modify column is_active VARCHAR(7);
alter table batch_productions modify column production_date DATE;
alter table sales_orders modify column delivery_date DATE;
ALTER TABLE sales_orders MODIFY COLUMN total_amount DECIMAL(15,2);
alter table purchase_orders add column Order_Date date;
alter table purchase_orders drop column Created_At ;
alter table batch_productions modify column batch_id varchar(20);
alter table batch_usage_materials modify column batch_id varchar(20);
alter table customers modify column Created_at date;
drop table batch_usage_materials;
alter table sales_orders drop constraint sales_orders_ibfk_1;
alter table customers modify column Customer_ID Varchar(20);
alter table sales_orders modify column Customer_ID Varchar(20);
alter table sales_orders add constraint FK_Sales_Cust_ID 
foreign key sales_orders(Customer_ID) references Customers(Customer_ID);
alter table batch_usage_materials add constraint FK_Batch_Usage_Raw_Mat_ID
Foreign key (material_id) references raw_materials(material_id);

-- To check the constraints in table 
SELECT 
    CONSTRAINT_NAME, 
    COLUMN_NAME,
    REFERENCED_TABLE_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'chemical_manufacturing' AND TABLE_NAME = 'Sales_orders' 
AND REFERENCED_TABLE_NAME IS NOT NULL;
    
SHOW CREATE TABLE sales_orders;  -- simple method

--

DESCRIBE  products;
describe sales_orders;
describe raw_materials;
describe purchase_orders;
describe batch_productions ;
describe batch_usage_materials;
-- Data Query Language (DQL)

-- What's the actual material cost for each product batch?


DELIMITER $$
Create Procedure Cost_Per_Batch_Unit()
BEGIN
	SELECT 
		bp.batch_id,
		p.product_name,
		bp.production_date,
		bp.quantity_produced,
		ROUND(SUM(bum.quantity_used * rm.unit_cost),3) AS total_material_cost,
		ROUND(SUM(bum.quantity_used * rm.unit_cost) / bp.quantity_produced , 3) AS cost_per_unit_batch
	FROM batch_productions bp
	JOIN products p ON bp.product_id = p.product_id
	JOIN batch_usage_materials bum ON bp.batch_id = bum.batch_id
	JOIN raw_materials rm ON bum.material_id = rm.material_id
	GROUP BY bp.batch_id, p.product_name, bp.production_date, bp.quantity_produced
	ORDER BY bp.production_date ASC;
END $$
DELIMITER ;

Call Cost_Per_Batch_Unit();

-- Which materials are below minimum stock and need reordering?

SELECT m.Material_Name, m.Minimum_Stock_Level,m.Current_Stock_Quantity,
(m.Minimum_Stock_Level-m.Current_Stock_Quantity) AS Shortage_Quantity,
m.Unit_Of_Measure,
s.Supplier_Name, s.Contact_Person, s.Phone, s.Email
FROM raw_materials m
JOIN suppliers s ON m.Supplier_ID = s.Supplier_ID
WHERE m.Current_Stock_Quantity < m.Minimum_Stock_Level
ORDER BY 4 DESC;

-- Which products are most profitable?  production_cost_per_unit   selling_price_per_unit

DELIMITER $$
CREATE PROCEDURE Most_Profit_Products()
BEGIN
	SELECT p.product_id,p.product_name, bp.Total_Prod_Cost,
	so.Total_Sales_Amount,
	(so.Total_Sales_Amount - bp.Total_Prod_Cost) AS Total_Profit
	FROM products p 
	JOIN (SELECT product_id, sum(total_amount) Total_Sales_Amount FROM sales_orders
		   GROUP BY product_id  ) AS so ON so.product_id=p.product_id
	JOIN (SELECT product_id , sum(production_cost) Total_Prod_Cost FROM batch_productions
		   WHERE batch_status='Completed' GROUP BY product_id ) AS bp ON bp.product_id=p.product_id
	ORDER BY 5 DESC;
END $$
DELIMITER ;

CALL Most_Profit_Products();
 -- How is revenue trending month-over-month for each product?
 
 DELIMITER $$
 CREATE PROCEDURE Monthly_sales_trends()
 BEGIN
	 SELECT p.product_name, MONTH(so.order_date) MONTH, SUM(so.total_amount) Total_Sales, 
	 COUNT(quantity_ordered) Total_Quantity,
	 COUNT(DISTINCT so.Customer_ID) Total_Customers
	 FROM sales_orders so JOIN 
	 products p ON so.product_id=p.product_id
	 WHERE SO.payment_status ='Paid'
	 GROUP BY 1,2 ORDER BY 3 DESC;
END $$
DELIMITER ;
CALL Monthly_sales_trends();

-- Who are our most valuable customers?
DELIMITER $$
CREATE PROCEDURE MV_Customers()
BEGIN

	SELECT c.customer_name,c.Country,c.Customer_Tier,
	COUNT(s.sales_order_id) AS Total_Orders,
	SUM(s.total_amount) AS Total_Sales,
	ROUND(AVG(s.total_amount),2) AS Avg_Order_Value,
	MAX(s.order_date) AS Last_Order_Date
	FROM Customers c JOIN sales_orders s
	ON c.Customer_ID=s.Customer_ID
	GROUP BY 1,2,3 ORDER BY 5 DESC
	LIMIT 10;
END$$
DELIMITER ;
CALL MV_Customers();

-- Which customer types  buy the most?

DELIMITER $$
CREATE PROCEDURE Customer_type_max_purchase()
	BEGIN
	SELECT c.Industry_Type, COUNT(so.total_amount)
	FROM customers c JOIN sales_orders so ON
	c.Customer_ID=so.Customer_ID 
	GROUP BY 1
	ORDER BY 2 DESC
	LIMIT 1;
END$$
DELIMITER ;

call Customer_type_max_purchase();

-- How Is the production of each product over time monthly?
SELECT p.product_name, SUM(bp.quantity_produced) Total_Quantity_Produced, 
MONTH(bp.production_date) Month
FROM products p JOIN batch_productions bp
ON p.product_id = bp.product_id 
WHERE batch_status='Completed' GROUP BY 1,3
ORDER BY 3;

-- What's our total inventory value right now?
select * from products;

DELIMITER $$
CREATE PROCEDURE Current_Inventory_Vaue(in Product_ID VARCHAR(15))
BEGIN
	SELECT so.product_id,SUM(so.total_amount) Total_Selling_price,
	SUM(bp.production_cost) Total_production_Cost,
	(SUM(bp.production_cost)- SUM(so.total_amount)) Current_Inventory_Vaue
	FROM sales_orders so JOIN batch_productions bp
	ON so.product_id=bp.product_id
    WHERE so.product_id= Product_ID
	GROUP BY 1;
END$$
DELIMITER ;

CALL Current_Inventory_Vaue('PROD-11');

-- Which materials have we purchased the most in the last 6 months?

SELECT rw.Material_Name, MAX(po.Quantity_Ordered)
FROM raw_materials rW JOIN purchase_orders po
ON rw.Material_id=po.Material_id
WHERE po.Order_Date BETWEEN 2025-05-15 AND CURDATE()
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5; 

-- Which products generate the most revenue?

SELECT p.product_name, so.product_id , SUM(so.total_amount)
FROM products p JOIN sales_orders so ON
p.product_id=so.product_id 
GROUP BY 1,2 ORDER BY 3 DESC LIMIT 5;

-- get current stock of raw materials status.
use chemical_manufacturing;
SELECT 
rw.Material_Name,
rw.Current_Stock_Quantity-SUM(bum.quantity_used) Current_Stock_Raw_Materials,
CASE 
  WHEN rw.Current_Stock_Quantity-SUM(bum.quantity_used) < 0 THEN 'Out_Of_Stockrw.Material_Name'
  WHEN rw.Current_Stock_Quantity-SUM(bum.quantity_used) < rw.Minimum_Stock_Level THEN 'Less_Than_Min_Stock'
  ELSE 'Sufficient_Stock'
END AS Current_Stock_Level     
FROM raw_materials rw JOIN batch_usage_materials bum
ON rw.Material_id=bum.Material_id
WHERE Material_Name='Ethylene Glycol'
GROUP BY rw.Material_Name,rw.Minimum_Stock_Level,rw.Current_Stock_Quantity
ORDER BY Current_Stock_Level ASC;

use chemical_manufacturing;
select * from batch_usage_materials;
