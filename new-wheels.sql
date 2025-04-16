/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
  
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/
     
-- Answer: Perform the query to find the distribution of customers across state
/* Steps:
Use the customer_t table to access customer data.
Group the records by the state column.
Count the distinct number of customer_id for each state.
Order the results by the number of customers in descending order to see the highest customer distribution first. 
*/

SELECT 
    state, COUNT(DISTINCT customer_id) AS No_of_customers
FROM
    customer_t
GROUP BY state
ORDER BY No_of_customers DESC;



-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5. */

-- Answer: Perfrom sub-query to assign numeric values for customer_feeback and use CTE to find average feedback
/* Steps:
Use a CASE statement to assign numeric values to the customer_feedback column.
Create a Common Table Expression (CTE) to store the feedback data.
Calculate the average feedback score for each quarter by grouping by quarter_number. 
*/

WITH feedback_t AS (
    SELECT quarter_number, 
           CASE 
               WHEN customer_feedback = 'Very Bad' THEN 1
               WHEN customer_feedback = 'Bad' THEN 2
               WHEN customer_feedback = 'Okay' THEN 3
               WHEN customer_feedback = 'Good' THEN 4
               WHEN customer_feedback = 'Very Good' THEN 5
           END AS feedback
    FROM order_t
)
SELECT quarter_number, 
       AVG(feedback) AS average_rating 
FROM feedback_t
GROUP BY quarter_number
ORDER BY quarter_number;
;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. 
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  And find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback. */

-- Answer:
/* Steps:
Create a CTE to count the occurrences of each feedback type (Very Good, Good, Okay, Bad, Very Bad) for each quarter.
Calculate the percentage of each feedback type relative to the total feedback for that quarter.
Return the feedback percentages for each quarter.
*/
WITH feedback_final AS (
    SELECT quarter_number,
           SUM(CASE WHEN customer_feedback = 'Very Good' THEN 1 ELSE 0 END) AS very_good,
           SUM(CASE WHEN customer_feedback = 'Good' THEN 1 ELSE 0 END) AS good,
           SUM(CASE WHEN customer_feedback = 'Okay' THEN 1 ELSE 0 END) AS okay,
           SUM(CASE WHEN customer_feedback = 'Bad' THEN 1 ELSE 0 END) AS bad,
           SUM(CASE WHEN customer_feedback = 'Very BAD' THEN 1 ELSE 0 END) AS very_bad,
           COUNT(customer_feedback) AS total_feedback
    FROM order_t
    GROUP BY quarter_number
)
SELECT quarter_number,
       100 * (very_good / total_feedback) AS very_good,
       100 * (good / total_feedback) AS good,
       100 * (okay / total_feedback) AS okay,
       100 * (bad / total_feedback) AS bad,
       100 * (very_bad / total_feedback) AS very_bad
FROM feedback_final
ORDER BY quarter_number;


	
-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/

-- Answer: Joining product_t and order_t to retrieve top 5 vehicle makers preferred by the customer
/* Steps:
Join the product_t and order_t tables on product_id.
Group by the vehicle_maker column and count the number of occurrences (i.e., orders).
Order the results by the count in descending order and limit to the top 5. 
*/

SELECT vehicle_maker, COUNT(ot.product_id) AS top_5
FROM product_t AS pt
INNER JOIN order_t AS ot USING (product_id)
GROUP BY vehicle_maker
ORDER BY top_5 DESC
LIMIT 5;



-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state? */

-- Answer: Rank count of customers for each state and vehicle. Use CTE with nested query in order to achieve the expected results
/* Steps:
Join the customer_t, order_t, and product_t tables.
Count the number of customers for each vehicle maker in each state.
Use a window function to rank vehicle makers by customer count for each state.
Return the top-ranked vehicle maker per state. 
*/
WITH final AS (
    SELECT C.state,
           P.vehicle_maker,
           COUNT(C.customer_id) AS cnt_cust
    FROM customer_t C 
    INNER JOIN order_t O ON C.customer_id = O.customer_id
    INNER JOIN product_t P ON O.product_id = P.product_id
    GROUP BY 1, 2
),
final_rank AS (
    SELECT *, DENSE_RANK() OVER(PARTITION BY state ORDER BY cnt_cust DESC) AS drank
    FROM final
)
SELECT state, vehicle_maker, cnt_cust, drank
FROM final_rank
WHERE drank = 1;



-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/

-- Answer: 
/* Steps:
Use the order_t table.
Group by quarter_number and count the number of quantity.
Return the result ordered by quarter_number.
 */
SELECT
	DISTINCT quarter_number,
    count(quantity) OVER(PARTITION BY quarter_number) AS orders_by_quarter
FROM order_t;



-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      
*/
-- Asnwer: 
/* Steps:
Calculate total revenue for each quarter by multiplying quantity by the discounted vehicle price.
Use the LAG() function to calculate the revenue for the previous quarter.
Compute the quarter-over-quarter percentage change.
 */
WITH quarter_rev AS (
SELECT quarter_number,
	   SUM(quantity *(vehicle_price - ((discount/100)*vehicle_price))) AS total_revenue
FROM order_t
GROUP BY 1
ORDER BY 1)

SELECT *, 100*((total_revenue - LAG(total_revenue) OVER(ORDER BY quarter_number)))/(LAG(total_revenue)OVER(ORDER BY quarter_number)) AS perc_qoq
FROM  quarter_rev;
  


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

-- Asnwer: 
/* Steps:
Calculate the total revenue for each quarter using quantity and vehicle_price (adjusted for discount).
Count the number of orders for each quarter.
Group by and order by quarter_number.
*/
SELECT quarter_number,
	   SUM(quantity *(vehicle_price - ((discount/100)*vehicle_price))) AS total_revenue,
       COUNT(order_id) AS total_orders
FROM order_t
GROUP BY 1
ORDER BY 1;



-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/
-- ANswer:
/* Steps:
Join the customer_t and order_t tables.
Group by credit_card_type and calculate the average discount for each type.
*/
SELECT DISTINCT ct.credit_card_type,
       AVG(ot.discount) OVER (PARTITION BY ct.credit_card_type) AS avg_discount_per_credit_type
FROM customer_t AS ct
INNER JOIN order_t AS ot ON ct.customer_id = ot.customer_id;



-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/
-- Answer:
/* Steps:
Use the DATEDIFF() function to calculate the time difference between ship_date and order_date.
Group by quarter_number and calculate the average number of days.
*/
SELECT DISTINCT quarter_number,
  AVG(DATEDIFF(ship_date, order_date)) OVER (PARTITION BY quarter_number) AS avg_ship_days
FROM order_t;



-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------



