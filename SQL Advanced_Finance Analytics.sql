--  SQL Advanced: Finance Analytics
-- Month
-- Product Name
-- Variant
-- Sold Quantity
-- Gross Price Per Item
-- Gross Price Total

-- ### Module: User-Defined SQL Functions
-- a). first grab customer codes for Croma india

SELECT * FROM dim_customer WHERE customer LIKE "%croma%" AND market = "india"; 

-- b. Get all the sales transaction data from fact_sales_monthly table for that customer(croma: 90002002) in the fiscal_year 2021

SELECT * FROM fact_sales_monthly 
WHERE 
     customer_code=90002002 AND 
     year(date_add(date, INTERVAL 4 MONTH))=2021
ORDER BY date DESC;

-- c. create a function 'get_fiscal_year' to get fiscal year by passing the date
			/* CREATE FUNCTION `get_fiscal_year`(calendar_date DATE) 
				RETURNS int
					DETERMINISTIC
				BEGIN
						DECLARE fiscal_year INT;
						SET fiscal_year = YEAR(DATE_ADD(calendar_date, INTERVAL 4 MONTH));
						RETURN fiscal_year;
				END
			*/
	
 -- d. Replacing the function created in the step:b
    
SELECT * FROM fact_sales_monthly 
WHERE 
     customer_code=90002002 AND 
     get_fiscal_year(date)=2021 AND
     get_fiscal_quarter(date)="Q4"
ORDER BY date ASC;

-- ### Module: Gross Sales Report: Monthly Product Transactions
-- a. Perform joins to pull product information

SELECT
		s.date, s.product_code, 
		p.product,p. variant, s.sold_quantity, 
		g.gross_price,
        ROUND(s.sold_quantity*g.gross_price,2) AS gross_price_total
FROM fact_sales_monthly s
JOIN dim_product p
ON p.product_code=s.product_code
JOIN fact_gross_price g
ON 
		g.product_code=s.product_code AND 
		g.fiscal_year=get_fiscal_year(s.date)
WHERE 
        customer_code= 90002002 AND
        get_fiscal_year(DATE)= 2021
        order by date
        ;
	
### Module: Gross Sales Report: Total Sales Amount

-- Generate monthly gross sales report for Croma India for all the years 
       
SELECT 
s.date,
SUM(s.sold_quantity*g.gross_price) AS monthly_sales
FROM fact_sales_monthly s
JOIN fact_gross_price g 
ON g.fiscal_year=get_fiscal_year(s.date) AND g.product_code=s.product_code
WHERE customer_code=90002002
GROUP BY date;

-- ### Module: Stored Procedures: Monthly Gross Sales Report

-- Generate monthly gross sales report for any customer using stored procedure

			/* CREATE PROCEDURE `get_monthly_gross_sales_for_customer`(
						in_customer_codes TEXT
				)
				BEGIN
						SELECT 
								s.date, 
								SUM(ROUND(s.sold_quantity*g.gross_price,2)) as monthly_sales
						FROM fact_sales_monthly s
						JOIN fact_gross_price g
								ON g.fiscal_year=get_fiscal_year(s.date)
								AND g.product_code=s.product_code
						WHERE 
								FIND_IN_SET(s.customer_code, in_customer_codes) > 0
						GROUP BY s.date
						ORDER BY s.date DESC;
				END
				 */
                 
-- ### Module: Stored Procedure: Market Badge

-- Write a stored proc that can retrieve market badge. i.e. if total sold quantity > 5 million that market is considered "Gold" else "Silver"

				/*
				CREATE PROCEDURE `get_market_badge`(
							IN in_market VARCHAR(45),
							IN in_fiscal_year YEAR,
							OUT out_level VARCHAR(45)
					)
					BEGIN
							 DECLARE qty INT DEFAULT 0;
					
							 # Default market is India
							 IF in_market = "" THEN
								  SET in_market="India";
							 END IF;
					
							 # Retrieve total sold quantity for a given market in a given year
							 SELECT 
								  SUM(s.sold_quantity) INTO qty
							 FROM fact_sales_monthly s
							 JOIN dim_customer c
							 ON s.customer_code=c.customer_code
							 WHERE 
								  get_fiscal_year(s.date)=in_fiscal_year AND
								  c.market=in_market;
						
							 # Determine Gold vs Silver status
							 IF qty > 5000000 THEN
								  SET out_level = 'Gold';
							 ELSE
								  SET out_level = 'Silver';
							 END IF;
					END
					*/

-- Chapter 8:- SQL Advanced: Top Customers, Products, Markets

-- ### Module: Problem Statement and Pre-Invoice Discount Report

SELECT 
    	   s.date, 
           s.product_code, 
           p.product, 
	   p.variant, 
           s.sold_quantity, 
           g.gross_price as gross_price_per_item,
           ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total,
           pre.pre_invoice_discount_pct
	FROM fact_sales_monthly s
	JOIN dim_product p
            ON s.product_code=p.product_code
	JOIN fact_gross_price g
    	    ON g.fiscal_year=get_fiscal_year(s.date)
    	    AND g.product_code=s.product_code
	JOIN fact_pre_invoice_deductions as pre
            ON pre.customer_code = s.customer_code AND
            pre.fiscal_year=get_fiscal_year(s.date)
	WHERE 
	    s.customer_code=90002002 AND 
    	    get_fiscal_year(s.date)=2021     
	LIMIT 1000000;
    
-- Same report but all the customers
	SELECT 
    	   s.date, 
           s.product_code, 
           p.product, 
	   p.variant, 
           s.sold_quantity, 
           g.gross_price as gross_price_per_item,
           ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total,
           pre.pre_invoice_discount_pct
	FROM fact_sales_monthly s
	JOIN dim_product p
            ON s.product_code=p.product_code
	JOIN fact_gross_price g
    	    ON g.fiscal_year=get_fiscal_year(s.date)
    	    AND g.product_code=s.product_code
	JOIN fact_pre_invoice_deductions as pre
            ON pre.customer_code = s.customer_code AND
            pre.fiscal_year=get_fiscal_year(s.date)
	WHERE 
    	    get_fiscal_year(s.date)=2021     
	LIMIT 1000000;

-- ### Module: Performance Improvement # 1

-- creating dim_date and joining with this table and avoid using the function 'get_fiscal_year()' to reduce the amount of time taking to run the query

SELECT 
    s.date,
    s.product_code,
    p.product,
    p.variant,
    s.sold_quantity,
    g.gross_price AS gross_price_per_item,
    ROUND(s.sold_quantity * g.gross_price, 2) AS gross_price_total,
    pre.pre_invoice_discount_pct
FROM
    fact_sales_monthly s
        JOIN
    dim_date dt ON dt.calendar_date = s.date
        JOIN
    dim_product p ON s.product_code = p.product_code
        JOIN
    fact_gross_price g ON g.fiscal_year = dt.fiscal_year
        AND g.product_code = s.product_code
        JOIN
    fact_pre_invoice_deductions AS pre ON pre.customer_code = s.customer_code
        AND pre.fiscal_year = dt.fiscal_year
WHERE
    GET_FISCAL_YEAR(s.date) = 2021
LIMIT 1000000;

-- ### Module: Performance Improvement # 2

-- Added the fiscal year in the fact_sales_monthly table itself


SELECT 
    s.date,
    s.product_code,
    p.product,
    p.variant,
    s.sold_quantity,
    g.gross_price AS gross_price_per_item,
    ROUND(s.sold_quantity * g.gross_price, 2) AS gross_price_total,
    pre.pre_invoice_discount_pct
FROM
    fact_sales_monthly s
        JOIN
    dim_product p ON s.product_code = p.product_code
        JOIN
    fact_gross_price g ON g.fiscal_year = s.fiscal_year
        AND g.product_code = s.product_code
        JOIN
    fact_pre_invoice_deductions AS pre ON pre.customer_code = s.customer_code
        AND pre.fiscal_year = s.fiscal_year
WHERE
    s.fiscal_year = 2021
LIMIT 1000000;

### Module: Database Views: Introduction

-- Get the net_invoice_sales amount using the CTE's
WITH cte1 as(
SELECT 
    s.date,
    s.product_code,
    p.product,
    p.variant,
    s.sold_quantity,
    g.gross_price AS gross_price_per_item,
    ROUND(s.sold_quantity * g.gross_price, 2) AS gross_price_total,
    pre.pre_invoice_discount_pct
FROM
    fact_sales_monthly s
        JOIN
    dim_product p ON s.product_code = p.product_code
        JOIN
    fact_gross_price g ON g.fiscal_year = s.fiscal_year
        AND g.product_code = s.product_code
        JOIN
    fact_pre_invoice_deductions AS pre ON pre.customer_code = s.customer_code
        AND pre.fiscal_year = s.fiscal_year
WHERE
    s.fiscal_year = 2021)
SELECT
*,
(gross_price_total-gross_price_total*pre_invoice_discount_pct) net_invoice_sale
FROM cte1;


 /* -- Creating the view `sales_preinv_discount` and store all the data in like a virtual table
	CREATE  VIEW `sales_preinv_discount` AS
	SELECT 
    	    s.date, 
            s.fiscal_year,
            s.customer_code,
            c.market,
            s.product_code, 
            p.product, 
            p.variant, 
            s.sold_quantity, 
            g.gross_price as gross_price_per_item,
            ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total,
            pre.pre_invoice_discount_pct
	FROM fact_sales_monthly s
	JOIN dim_customer c 
		ON s.customer_code = c.customer_code
	JOIN dim_product p
        	ON s.product_code=p.product_code
	JOIN fact_gross_price g
    		ON g.fiscal_year=s.fiscal_year
    		AND g.product_code=s.product_code
	JOIN fact_pre_invoice_deductions as pre
        	ON pre.customer_code = s.customer_code AND
    		pre.fiscal_year=s.fiscal_year
            */
            
-- Now generate net_invoice_sales using the above created view "sales_preinv_discount"
	SELECT 
            *,
    	    (gross_price_total-pre_invoice_discount_pct*gross_price_total) as net_invoice_sales
	FROM gdb0041.sales_preinv_discount;
    
    
/*
### Module: Database Views: Post Invoice Discount, Net Sales

-- Create a view for post invoice deductions: `sales_postinv_discount`
	CREATE VIEW `sales_postinv_discount` AS
	SELECT 
    	    s.date, s.fiscal_year,
            s.customer_code, s.market,
            s.product_code, s.product, s.variant,
            s.sold_quantity, s.gross_price_total,
            s.pre_invoice_discount_pct,
            (s.gross_price_total-s.pre_invoice_discount_pct*s.gross_price_total) as net_invoice_sales,
            (po.discounts_pct+po.other_deductions_pct) as post_invoice_discount_pct
	FROM sales_preinv_discount s
	JOIN fact_post_invoice_deductions po
		ON po.customer_code = s.customer_code AND
   		po.product_code = s.product_code AND
   		po.date = s.date;
   */
   
-- Create a report for net sales 

SELECT             *, 
    	    net_invoice_sales*(1-post_invoice_discount_pct) as net_sales
	FROM sales_postinv_discount;
    

/*
Exercise - Create a view for gross sales. It should have the following columns,

	date, fiscal_year, customer_code, customer, market, product_code, product, variant,
	sold_quanity, gross_price_per_item, gross_price_total

Solution-
	CREATE  VIEW `gross_sales` AS
	SELECT 
		s.date,
		s.fiscal_year,
		s.customer_code,
		c.customer,
		c.market,
		s.product_code,
		p.product, p.variant,
		s.sold_quantity,
		g.gross_price as gross_price_per_item,
		round(s.sold_quantity*g.gross_price,2) as gross_price_total
	from fact_sales_monthly s
	join dim_product p
	on s.product_code=p.product_code
	join dim_customer c
	on s.customer_code=c.customer_code
	join fact_gross_price g
	on g.fiscal_year=s.fiscal_year
	and g.product_code=s.product_code;
    */
    

-- ### Module: Top Markets and Customers 

-- Get top 5 market by net sales in fiscal year 2021

SELECT market,ROUND(SUM(net_sales)/1000000,2) AS net_sales_mln 
FROM gdb0041.net_sales
WHERE fiscal_year=2021
GROUP BY market
ORDER BY net_sales_mln DESC
LIMIT 5;

-- Stored proc to get top n markets by net sales for a given year
/*
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_top_n_market_by_net_sales`(
in_fiscal_year YEAR,
in_top_n INT)
BEGIN
		SELECT 
                 market,
                 ROUND(SUM(net_sales)/1000000,2) AS net_sales_mln 
		FROM gdb0041.net_sales
		WHERE fiscal_year=in_fiscal_year
		GROUP BY market
		ORDER BY net_sales_mln DESC
		LIMIT in_top_n;
END
*/

/*
-- stored procedure that takes market, fiscal_year and top n as an input and returns top n customers by net sales in that given fiscal year and market
	CREATE PROCEDURE `get_top_n_customers_by_net_sales`(
        	in_market VARCHAR(45),
        	in_fiscal_year INT,
    		in_top_n INT
	)
	BEGIN
        	select 
                     customer, 
                     round(sum(net_sales)/1000000,2) as net_sales_mln
        	from net_sales s
        	join dim_customer c
                on s.customer_code=c.customer_code
        	where 
		    s.fiscal_year=in_fiscal_year 
		    and s.market=in_market
        	group by customer
        	order by net_sales_mln desc
        	limit in_top_n;
	END
    */

