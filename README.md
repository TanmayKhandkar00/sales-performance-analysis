# Balanced Tree Clothing co. Sales Performance Analysis
This project and the data used was part of a case study which can be found [here](https://8weeksqlchallenge.com/case-study-7/).
## Background
Balanced Tree Clothing Company prides themselves on providing an optimised range of clothing and lifestyle wear for the modern adventurer!
Danny, the CEO of this trendy fashion company has asked you to assist the team’s merchandising teams analyse their sales performance and generate a basic financial report to share with the wider business.
## Data
1. **Product Details:** </br>
   **balanced_tree.product_details** includes all information about the entire range that Balanced Clothing sells in their store.
2. **Product Sales:** </br>
   balanced_tree.sales contains product level information for all the transactions made for Balanced Tree including quantity, price, percentage discount, member status, a transaction ID and also the transaction      timestamp.
## Skills Applied
* Window Functions
* CTEs
* Aggregations
* JOINs
* Write scripts to generate basic reports that can be run every period
## Questions Explored
### High Level Sales Analysis
1. What was the total quantity sold for all products?
2. What is the total generated revenue for all products before discounts?
3. What was the total discount amount for all products?
### Transaction Analysis
1. How many unique transactions were there?
2. What is the average unique products purchased in each transaction?
3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
4. What is the average discount value per transaction?
5. What is the percentage split of all transactions for members vs non-members?
6. What is the average revenue for member transactions and non-member transactions?
### Product Analysis
1. What are the top 3 products by total revenue before discount?
2. What is the total quantity, revenue and discount for each segment?
3. What is the top selling product for each segment?
4. What is the total quantity, revenue and discount for each category?
5. What is the top selling product for each category?
6. What is the percentage split of revenue by product for each segment?
7. What is the percentage split of revenue by segment for each category?
8. What is the percentage split of total revenue by category?
9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
## Some Interesting Queries
**Product Analysis: Q10 - What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?**
```SQL
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
```
**Transaction Analysis: Q6 - What is the average revenue for member transactions and non-member transactions?**
```SQL
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
```
**Product Analysis" Q3 - What is the top selling product for each segment?**
```SQL
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
```
