SELECT * FROM balanced_tree.product_details;

-- High level Sales Analysis

-- Total Quantity Sold for all Products
SELECT SUM(qty) as total_quantity_sold FROM balanced_tree.sales;

SELECT prod_id, SUM(qty) as total_quantity_sold
FROM balanced_tree.sales
GROUP BY prod_id;


-- Total Generated Revenue for all Products before Discounts

SELECT SUM(price*qty) as revenue_before_discounts
FROM balanced_tree.sales;

-- Total Discount Amount for all Products

SELECT ROUND(SUM(price*(discount*1.0/100)*qty),2) as total_discount
FROM balanced_tree.sales;

-- Transaction Analysis

-- Number of Unique Transactios

SELECT COUNT(DISTINCT(txn_id)) as number_of_unique_transactions
FROM balanced_tree.sales;

-- Average Unique Products Purchased in each Transaction
WITH products_per_transaction AS 
(SELECT txn_id, COUNT(prod_id) as number_of_products
FROM balanced_tree.sales
GROUP BY txn_id
ORDER BY txn_id)
SELECT ROUND(SUM(number_of_products)/COUNT(txn_id),0) as average_products_per_transaction 
FROM products_per_transaction;

-- The 25th, 50th and 75th percentile values for the revenue per transaction
-- revenue = qty*price(1-(discount/100))
WITH revenue_per_transaction AS
(SELECT txn_id, ROUND(SUM((1-(CAST(discount as DECIMAL(5,2))/100))*price*qty),2) as revenue
FROM balanced_tree.sales
GROUP BY txn_id
ORDER BY txn_id)
SELECT  
percentile_disc(0.25) WITHIN GROUP (ORDER BY revenue) AS percentile_25,
percentile_disc(0.50) WITHIN GROUP (ORDER BY revenue) AS percentile_50,
percentile_disc(0.75) WITHIN GROUP (ORDER BY revenue) AS percentile_75
FROM revenue_per_transaction;

-- The average discount value per transaction
SELECT ROUND(AVG(total_discount),3) as average_discount FROM
(SELECT txn_id, ROUND(SUM((CAST(discount as DECIMAL(5,2))/100)*price*qty),2) as total_discount
FROM balanced_tree.sales
GROUP BY txn_id
ORDER BY txn_id) as discount_per_transaction;

-- Percentage split of all Transactions for Members vs Non-members
SELECT COUNT(DISTINCT(member))
FROM balanced_tree.sales
GROUP BY txn_id;

-- The Percentage split of all Transactions for Members vs Non-members
SELECT member_status, ROUND((COUNT(txn_id)/ SUM(COUNT(txn_id)) OVER())*100,2) as percentage_of_transactions  FROM
(SELECT DISTINCT(txn_id), (CASE
			WHEN sales.member= 't' THEN 'member'
			WHEN sales.member= 'f' THEN 'non-member'
			END) as member_status
FROM balanced_tree.sales
ORDER BY txn_id) as member_status_per_txn
GROUP BY member_status;

-- The average Revenue for Member transactions and Non-member Transactions
WITH revenue_perTxn_byMemberType AS
(SELECT txn_id, (CASE
			WHEN sales.member= 't' THEN 'member'
			WHEN sales.member= 'f' THEN 'non-member'
			END) as member_status,
ROUND(SUM((1-(CAST(discount as DECIMAL(5,2))/100))*price*qty),2) as revenue
FROM balanced_tree.sales
GROUP BY txn_id, member_status
ORDER BY txn_id)
SELECT member_status, ROUND(AVG(revenue),3)
FROM revenue_perTxn_byMemberType
GROUP BY member_status;

--  Product Analysis

-- The top 3 Products by Total Revenue before Discount
SELECT prod_id, SUM(qty*price) as revenue_before_discount 
FROM balanced_tree.sales
GROUP BY prod_id
ORDER BY revenue_before_discount desc
LIMIT 3;

-- The Total Quantity, Revenue and Discount for each Segment
SELECT b.segment_name, SUM(a.qty) as quantity_sold, ROUND(SUM((1-(CAST(a.discount as DECIMAL(5,2))/100))*a.price*a.qty),2) as revenue, 
ROUND(SUM((CAST(a.discount as DECIMAL(5,2))/100)*a.price*a.qty),2) as total_discount
FROM balanced_tree.sales a JOIN balanced_tree.product_details b on a.prod_id = b.product_id
GROUP BY b.segment_name
ORDER BY b.segment_name, revenue desc;

-- The top selling Product for each Segment by Total Quantity Sold
WITH ranked_products_bySegment_byQuantity AS(
SELECT b.segment_name, a.prod_id, b.product_name, SUM(a.qty) as quantity_sold,
RANK() OVER(PARTITION BY b.segment_name ORDER BY SUM(a.qty) DESC) as product_rank
FROM balanced_tree.sales a JOIN balanced_tree.product_details b on a.prod_id = b.product_id
GROUP BY b.segment_name, a.prod_id, b.product_name
ORDER BY quantity_sold desc)
SELECT segment_name, prod_id, product_name, quantity_sold
FROM ranked_products_bySegment_byQuantity
WHERE product_rank = 1;

-- The top selling Product for each Segment by Revenue Generated
WITH ranked_products_bySegment_byRevenue AS(
SELECT b.segment_name, a.prod_id, b.product_name,ROUND(SUM((1-(CAST(a.discount as DECIMAL(5,2))/100))*a.price*a.qty),2) as revenue,
RANK() OVER(PARTITION BY b.segment_name ORDER BY ROUND(SUM((1-(CAST(a.discount as DECIMAL(5,2))/100))*a.price*a.qty),2)  DESC) as product_rank
FROM balanced_tree.sales a JOIN balanced_tree.product_details b on a.prod_id = b.product_id
GROUP BY b.segment_name, a.prod_id, b.product_name
ORDER BY revenue desc)
SELECT segment_name, prod_id, product_name, revenue
FROM ranked_products_bySegment_byRevenue
WHERE product_rank = 1
ORDER BY segment_name, revenue desc;

-- The Total Quantity, Revenue and Discount for each Category
SELECT b.category_name, SUM(a.qty) as quantity_sold, ROUND(SUM((1-(CAST(a.discount as DECIMAL(5,2))/100))*a.price*a.qty),2) as revenue, 
ROUND(SUM((CAST(a.discount as DECIMAL(5,2))/100)*a.price*a.qty),2) as total_discount
FROM balanced_tree.sales a JOIN balanced_tree.product_details b on a.prod_id = b.product_id
GROUP BY b.category_name
ORDER BY b.category_name, revenue desc;

-- The top selling Product for each Category by Quantity sold
WITH ranked_products_byCategory_byQuantity AS(
	SELECT b.category_name, a.prod_id, b.product_name, SUM(a.qty) as quantity_sold,
	RANK() OVER(PARTITION BY b.category_name ORDER BY SUM(a.qty) DESC) as product_rank
	FROM balanced_tree.sales a JOIN balanced_tree.product_details b on a.prod_id = b.product_id
	GROUP BY b.category_name, a.prod_id, b.product_name
	ORDER BY quantity_sold desc)
SELECT category_name, prod_id, product_name, quantity_sold
FROM ranked_products_byCategory_byQuantity
WHERE product_rank = 1
ORDER BY category_name, quantity_sold desc;

-- The top selling Product for each Category by Revenue Generated
WITH ranked_products_byCategory_byRevenue AS(
	SELECT b.category_name, a.prod_id, b.product_name, ROUND(SUM((1-(CAST(a.discount as DECIMAL(5,2))/100))*a.price*a.qty),2) as revenue ,
	RANK() OVER(PARTITION BY b.category_name ORDER BY ROUND(SUM((1-(CAST(a.discount as DECIMAL(5,2))/100))*a.price*a.qty),2) DESC) as product_rank
	FROM balanced_tree.sales a JOIN balanced_tree.product_details b on a.prod_id = b.product_id
	GROUP BY b.category_name, a.prod_id, b.product_name
	ORDER BY revenue desc)
SELECT category_name, prod_id, product_name, revenue
FROM ranked_products_byCategory_byRevenue
WHERE product_rank = 1
ORDER BY category_name, revenue desc;

-- The Percentage split of Revenue by Product for each Segment
WITH product_revenue_by_segment AS (
	SELECT b.segment_name, a.prod_id, b.product_name, ROUND(SUM((1-(CAST(a.discount as DECIMAL(5,2))/100))*a.price*a.qty),2) as revenue
	FROM balanced_tree.sales a JOIN balanced_tree.product_details b on a.prod_id = b.product_id
	GROUP BY b.segment_name, a.prod_id, b.product_name
	ORDER BY b.segment_name, revenue desc)
SELECT segment_name, prod_id, product_name, revenue, ROUND((revenue/SUM(revenue) OVER(PARTITION BY segment_name))*100, 2) as percent_of_segment_revenue
FROM product_revenue_by_segment;

-- The Percentage split of Revenue by Segment for each Category
WITH segment_revenue_by_category AS 
	(SELECT b.category_name, b.segment_name, ROUND(SUM((1-(CAST(a.discount as DECIMAL(5,2))/100))*a.price*a.qty),2) as revenue
	FROM balanced_tree.sales a JOIN balanced_tree.product_details b on a.prod_id = b.product_id
	GROUP BY b.category_name, b.segment_name
	ORDER BY b.category_name, revenue desc)
SELECT category_name, segment_name, revenue, ROUND((revenue/SUM(revenue) OVER(PARTITION BY category_name))*100, 2) as percent_of_categoory_revenue
FROM segment_revenue_by_category;

-- The Percentage split of Total Revenue by Category
SELECT b.category_name, ROUND(SUM((1-(CAST(a.discount as DECIMAL(5,2))/100))*a.price*a.qty),2) as revenue,
ROUND((ROUND(SUM((1-(CAST(a.discount as DECIMAL(5,2))/100))*a.price*a.qty),2)/ SUM(ROUND(SUM((1-(CAST(a.discount as DECIMAL(5,2))/100))*a.price*a.qty),2)) OVER())*100,2) as percent_of_total_revenue
FROM balanced_tree.sales a JOIN balanced_tree.product_details b on a.prod_id = b.product_id
GROUP BY b.category_name
ORDER BY b.category_name, revenue desc;

-- Total Transaction Penetration for each Product
-- Penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
WITH total_transactions AS
(
	SELECT COUNT(DISTINCT txn_id) as total
	FROM balanced_tree.sales
)
SELECT prod_id, 
ROUND(COUNT(DISTINCT txn_id)*1.0 / (SELECT total FROM total_transactions) *100,2) as transaction_penetration
FROM balanced_tree.sales
WHERE qty > 0
GROUP BY prod_id
ORDER BY prod_id;

-- The most Common Combination of at least 1 Quantity of any 3 Products in a 1 single Transaction
WITH product_transactions AS
(
	SELECT txn_id, prod_id
	FROM balanced_tree.sales
	WHERE qty>0
),
transaction_triples AS
(
	SELECT a.txn_id,
	a.prod_id AS product1, b.prod_id AS product2, c.prod_id AS product3
	FROM product_transactions a 
	INNER JOIN product_transactions b ON a.txn_id = b.txn_id AND a.prod_id < b.prod_id
	INNER JOIN product_transactions c ON a.txn_id = c.txn_id AND b.prod_id < c.prod_id
)
SELECT CONCAT (product1,', ',product2,', ',product3) AS product_combination, COUNT(*) AS number_of_transactions_for_combination
FROM transaction_triples 
GROUP BY product1, product2, product3
ORDER BY number_of_transactions_for_combination DESC
LIMIT 1;
 



