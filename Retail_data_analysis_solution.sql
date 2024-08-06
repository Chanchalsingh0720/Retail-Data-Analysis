-- CREATING DATABASE RETAIL_DATA_ANALYSIS
	CREATE DATABASE RETAIL_DATA_ANALYSIS

-- USING RETAIL_DATA_ANALYSIS DATABASE
	USE RETAIL_DATA_ANALYSIS

--DATA PREPARATION AND UNDERSTANDING

--Q1. What is the total number of rows in each of the 3 tables in the database?

	SELECT 'CUSTOMER_TABLE' AS TABLENAME, COUNT(*) AS TOTAL_ROWS FROM DBO.Customer
	UNION ALL
	SELECT 'PROD_CAT_INFO_TABLE' AS TABLENAME, COUNT(*) FROM DBO.prod_cat_info
	UNION ALL
	SELECT 'TRANSACTIONS_TABLE' AS TABLENAME, COUNT(*) FROM DBO.Transactions

--Q2. What is the total number of transactions that have a return?
	
	SELECT COUNT(*) AS TRANSACTION_CNT 
	FROM DBO.Transactions
	WHERE total_amt<0

	--OR
	
	SELECT COUNT(TOTAL_AMT) AS TRANSACTION_CNT 
	FROM DBO.Transactions
	WHERE TOTAL_AMT<0
	
--Q3. As you would have noticed, the dates provided across the datasets 
--	  are not in a correct format. As first steps, pls convert the date
--	  variables into valid date formats before proceeding ahead.

	alter table dbo.Customer
	alter column DOB date
	alter table transactions 
	alter column tran_date date
	
--Q4. What is the time range of the transaction data available for analysis?
--	  Show the output in number of days, months and years simultaneously in different columns.
	
	SELECT
	DATEDIFF(DAY,MIN(A.TRAN_DATE),MAX(TRAN_DATE)) AS TOTAL_DAYS,
	DATEDIFF(MONTH,MIN(A.TRAN_DATE),MAX(TRAN_DATE)) AS TOTAL_MONTHS,
	DATEDIFF(YEAR,MIN(A.TRAN_DATE),MAX(TRAN_DATE)) AS TOTAL_YEARS
	FROM Transactions AS A

--Q5. Which product category does the sub-category "DIY" belong to?
	
	SELECT A.prod_cat AS DIY_PRODUCT_CATEGORY
	FROM dbo.prod_cat_info AS A
	WHERE A.prod_subcat ='DIY'

-- DATA ANALYSIS

--Q1. Which channel is most frequently used for transactions?
		
	SELECT TOP 1 A.Store_type, COUNT(STORE_TYPE) AS CNT_CHANNEL
	FROM Transactions AS A
	GROUP BY A.Store_type 
	ORDER BY COUNT(STORE_TYPE) DESC

--Q2. What is the count of Male and Female customers in the database?
	
	SELECT A.GENDER, COUNT(A.CUSTOMER_ID) AS CNT_GENDER
	FROM DBO.Customer AS A
	GROUP BY A.GENDER
	HAVING A.Gender IS NOT NULL

--Q3. From which city do we have the maximum number of customers and how many?

	SELECT TOP 1 A.city_code, COUNT(A.CUSTOMER_ID) AS CNT_CUSTOMER
	FROM DBO.Customer AS A
	GROUP BY A.city_code
	HAVING A.city_code IS NOT NULL
	ORDER BY COUNT(A.CUSTOMER_ID) DESC

--Q4. How many sub-categories are there under the Books category?
	
	SELECT A.prod_cat,COUNT(DISTINCT A.prod_subcat) AS CNT_SUB_CAT
	FROM DBO.prod_cat_info AS A
	GROUP BY A.prod_cat
	HAVING A.prod_cat='BOOKS'

--Q5. What is the maximum quantity of products ever ordered?
	
	SELECT TOP 1 A.PROD_CAT,
	COUNT(B.QTY) AS PROD_QTY
	FROM PROD_CAT_INFO AS A
	LEFT JOIN TRANSACTIONS AS B
	ON A.PROD_CAT_CODE=B.PROD_CAT_CODE
	AND 
	A.PROD_SUB_CAT_CODE=B.PROD_SUBCAT_CODE
	GROUP BY A.PROD_CAT
	ORDER BY PROD_QTY DESC

--Q6. What is the net total revenue generated in categories Electronics and Books?
	
	SELECT ROUND(SUM(A.TOTAL_AMT),2) AS NET_REVENUE
	FROM TRANSACTIONS AS A
	INNER JOIN PROD_CAT_INFO AS B
	ON A.PROD_CAT_CODE=B.PROD_CAT_CODE
	AND
	A.PROD_SUBCAT_CODE=B.PROD_SUB_CAT_CODE
	WHERE B.PROD_CAT IN('ELECTRONICS','BOOKS')

--Q7. How many customers have >10 transactions with us, excluding returns?
	
	SELECT COUNT(C.CUSTOMER_ID) AS CNT_CUSTOMER 
	FROM CUSTOMER AS C
	WHERE C.CUSTOMER_ID IN(
							SELECT A.CUST_ID FROM TRANSACTIONS AS A
							INNER JOIN CUSTOMER AS B
							ON A.CUST_ID=B.CUSTOMER_ID
							WHERE A.TOTAL_AMT >0
							GROUP BY A.CUST_ID
							HAVING COUNT(A.TOTAL_AMT) > 10
						   )
						   
--Q8. What is the combined revenue earned from the “Electronics” & “Clothing” categories, 
--	  from “Flagship stores”?
	
	SELECT ROUND(SUM(TOTAL_AMT),2) AS COMBINED_REVENUE
	FROM DBO.prod_cat_info AS A
	INNER JOIN DBO.Transactions AS B
	ON A.prod_cat_code=B.prod_cat_code
	AND A.PROD_SUB_CAT_CODE=B.PROD_SUBCAT_CODE
	WHERE A.prod_cat IN ('ELECTRONICS','CLOTHING') AND B.Store_type ='Flagship store'

--Q9. What is the total revenue generated from “Male” customers in “Electronics” category?
--	  Output should display total revenue by prod sub-cat.
	
	SELECT A.PROD_SUBCAT, SUM(B.TOTAL_AMT) AS TOTAL_REVENUE_GENERATED FROM PROD_CAT_INFO AS A
	INNER JOIN TRANSACTIONS AS B
	ON 
	A.PROD_SUB_CAT_CODE=B.PROD_SUBCAT_CODE
	AND
	A.PROD_CAT_CODE=B.PROD_CAT_CODE
	RIGHT JOIN CUSTOMER AS C
	ON C.CUSTOMER_ID=B.CUST_ID
	WHERE C.GENDER= 'M' AND A.PROD_CAT='ELECTRONICS'
	GROUP BY A.PROD_SUBCAT

--Q10. What is percentage of sales and returns by product sub category;
--	   display only top 5 sub categories in terms of sales?
	
	SELECT TOP 5 
    B.PROD_SUBCAT, 
    SUM(CAST(A.TOTAL_AMT AS FLOAT)) AS TOTAL_SALES,
    CAST(100.0 * SUM(CAST(A.TOTAL_AMT AS FLOAT)) / 
        (SELECT SUM(CAST(TOTAL_AMT AS FLOAT)) FROM TRANSACTIONS) AS INT) AS TOTAL_SALES_PERCENTAGE,
    CAST(100.0 * SUM(CAST(CASE WHEN A.QTY < 0 THEN A.QTY ELSE 0 END AS FLOAT)) / 
        (SELECT SUM(CAST(QTY AS FLOAT)) FROM TRANSACTIONS WHERE QTY < 0) AS INT) AS TOTAL_RETURNS_PERCENTAGE
	FROM TRANSACTIONS AS A
	LEFT JOIN PROD_CAT_INFO AS B
	ON A.PROD_CAT_CODE = B.PROD_CAT_CODE 
	   AND A.PROD_SUBCAT_CODE = B.PROD_SUB_CAT_CODE
	GROUP BY B.PROD_SUBCAT
	ORDER BY TOTAL_SALES DESC

--Q11. For all customers aged between 25 to 35 years find what is the net total revenue 
--    generated by these consumers in last 30 days of transactions from max transaction date available in the data?

	SELECT C.CUSTOMER_ID,
    DATEDIFF(YEAR, C.DOB, T.TRAN_DATE) AS AGE,
    ROUND(SUM(T.TOTAL_AMT), 2) AS TOTAL_REVENUE
	FROM TRANSACTIONS T
	INNER JOIN CUSTOMER C ON T.CUST_ID = C.CUSTOMER_ID
	WHERE DATEDIFF(YEAR, C.DOB, T.TRAN_DATE) BETWEEN 25 AND 35
	AND T.TRAN_DATE >= DATEADD(DAY, -30, (SELECT MAX(T.TRAN_DATE) FROM TRANSACTIONS T))
	GROUP BY C.CUSTOMER_ID, C.DOB, T.TRAN_DATE
	ORDER BY AGE
	
--Q12. Which product category has seen the max value of returns in the last 3 months of transactions?
	
	SELECT TOP 1 B.PROD_CAT, 
    SUM(CASE WHEN A.TOTAL_AMT < 0 THEN A.TOTAL_AMT ELSE 0 END) AS VALUE_OF_RETURN
	FROM TRANSACTIONS AS A
	INNER JOIN PROD_CAT_INFO AS B 
	ON 
	B.PROD_CAT_CODE = A.PROD_CAT_CODE
	GROUP BY B.PROD_CAT, A.TRAN_DATE
	HAVING A.TRAN_DATE > DATEADD(MONTH, -3, (SELECT MAX(A.TRAN_DATE) FROM TRANSACTIONS AS A))
	ORDER BY VALUE_OF_RETURN

--Q13. Which store-type sells the maximum products; by value of sales amount and by quantity sold?
	
	SELECT TOP 1 A.STORE_TYPE,
    SUM(CAST(A.QTY AS INT)) AS SOLD_QTY,
    (SELECT ROUND(SUM(A.TOTAL_AMT), 2)) AS SALES_AMT
	FROM TRANSACTIONS A
	GROUP BY A.STORE_TYPE
	ORDER BY SALES_AMT DESC, SOLD_QTY DESC

--Q14.What are the categories for which average revenue is above the overall average. 

	WITH OVERALL_AVERAGE AS (
							  SELECT AVG(CAST(TOTAL_AMT AS FLOAT)) AS OVERALL_AVG
							  FROM TRANSACTIONS
							)
	SELECT B.PROD_CAT,
	ROUND(AVG(CAST(A.TOTAL_AMT AS FLOAT)), 2) AS CATEGORY_AVG_SALES
	FROM TRANSACTIONS AS A
	INNER JOIN PROD_CAT_INFO AS B 
	ON
	B.PROD_CAT_CODE = A.PROD_CAT_CODE
	CROSS JOIN OVERALL_AVERAGE
	GROUP BY B.PROD_CAT, OVERALL_AVERAGE.OVERALL_AVG
	HAVING ROUND(AVG(CAST(A.TOTAL_AMT AS FLOAT)), 2) > OVERALL_AVERAGE.OVERALL_AVG	   	

--Q15. Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.
	
	WITH SubcatRevenue AS (
							SELECT B.PROD_SUBCAT,
							ROUND(AVG(A.total_amt),2) AS AVG_REVENUE,
							SUM(CAST(A.Qty AS INT)) AS Total_Qty
							FROM Transactions AS A
							INNER JOIN prod_cat_info AS B 
							ON A.prod_cat_code = B.prod_cat_code 
							AND A.prod_subcat_code = B.prod_sub_cat_code
							GROUP BY B.prod_subcat
						  )
	SELECT TOP 5 PROD_SUBCAT, AVG_REVENUE
	FROM SubcatRevenue
	ORDER BY Total_Qty DESC