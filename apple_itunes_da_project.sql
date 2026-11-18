create database apple_iphone;
use apple_iphone;

--1.Customer analysis
SELECT c.customer_id, c.first_name, c.last_name,SUM(i.total) 
AS total_spent
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC limit 10;


select avg(total_spent) as average_lifetime
from(select c.customer_id, sum(i.total) as total_spent
from customer c join invoice i on c.customer_id=i.customer_id
group by c.customer_id);

WITH PurchaseCounts AS (
    SELECT customer_id, COUNT(invoice_id) AS num_purchases
    FROM invoice
    GROUP BY customer_id
)
SELECT
    SUM(CASE WHEN num_purchases = 1 THEN 1 ELSE 0 END) AS one_time_purchasers,
    SUM(CASE WHEN num_purchases > 1 THEN 1 ELSE 0 END) AS repeat_purchasers,
    COUNT(customer_id) AS total_customers
FROM PurchaseCounts;

SELECT c.country, SUM(i.total) AS total_revenue,
COUNT(DISTINCT c.customer_id) AS num_customers,
SUM(i.total) * 1.0 / COUNT(DISTINCT c.customer_id) AS revenue_per_customer
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.country
ORDER BY revenue_per_customer DESC;

-- 2. Sales & Revenue Analysis
SELECT TO_CHAR(invoice_date, 'YYYY-MM') AS sales_month, SUM(total) AS monthly_revenue
FROM invoice
WHERE invoice_date >= DATEADD(year, -2, (SELECT MAX(invoice_date) FROM invoice))
GROUP BY sales_month
ORDER BY sales_month;

SELECT AVG(total) AS average_invoice_value FROM invoice;

SELECT e.employee_id, e.first_name AS employee_first_name, e.last_name AS employee_last_name, SUM(i.total) AS total_revenue_contributed
FROM employee e
JOIN customer c ON e.employee_id = c.support_rep_id
JOIN invoice i ON c.customer_id = i.customer_id
WHERE e.title = 'Sales Support Agent'
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY total_revenue_contributed DESC;

SELECT 
  CAST(TO_CHAR(invoice_date, 'MM') AS INTEGER) AS sales_month, 
  SUM(total) AS monthly_sales
FROM invoice
GROUP BY sales_month
ORDER BY monthly_sales DESC;

SELECT
    DATE_PART('QUARTER', invoice_date) AS sales_quarter,
    SUM(total) AS quarterly_sales
FROM invoice
GROUP BY sales_quarter
ORDER BY quarterly_sales DESC;

-- 3. Product & Content Analysis
SELECT il.track_id, SUM(il.unit_price * il.quantity) AS total_track_revenue
FROM invoicelink il
GROUP BY il.track_id
ORDER BY total_track_revenue DESC
LIMIT 10;

SELECT
    p.playlist_id,
    p.name AS playlist_name,
    SUM(il.quantity) AS total_quantity_sold
FROM invoicelink il
JOIN playlisttrack pt ON il.track_id = pt.track_id
JOIN playlist p ON pt.playlist_id = p.playlist_id
GROUP BY p.playlist_id, p.name
ORDER BY total_quantity_sold DESC
LIMIT 10;

SELECT pt.track_id
FROM playlisttrack pt
LEFT JOIN invoicelink il ON pt.track_id = il.track_id
WHERE il.track_id IS NULL;

-- 4. Employee & Operational Efficiency
SELECT e.employee_id,e.first_name AS employee_first_name, e.last_name AS employee_last_name,
    c.customer_id, c.first_name AS customer_first_name, c.last_name AS customer_last_name,
    SUM(i.total) AS total_customer_spending
FROM employee e
JOIN customer c ON e.employee_id = c.support_rep_id
JOIN invoice i ON c.customer_id = i.customer_id
WHERE e.title = 'Sales Support Agent' 
GROUP BY e.employee_id, e.first_name, e.last_name, c.customer_id, c.first_name, c.last_name
ORDER BY total_customer_spending DESC
LIMIT 10;

SELECT 
    CAST(COUNT(DISTINCT customer_id) AS REAL) / COUNT(DISTINCT support_rep_id) AS avg_customers_per_rep
FROM customer
WHERE support_rep_id IS NOT NULL;

SELECT e.country AS employee_country, e.city AS employee_city, SUM(i.total) AS total_revenue
FROM employee e
JOIN customer c ON e.employee_id = c.support_rep_id
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY e.country, e.city
ORDER BY total_revenue DESC;

-- 5. Geographic Trends
SELECT country, COUNT(customer_id) AS num_customers
FROM customer
GROUP BY country
ORDER BY num_customers DESC
LIMIT 10;

SELECT city, COUNT(customer_id) AS num_customers
FROM customer
GROUP BY city
ORDER BY num_customers DESC
LIMIT 10;

SELECT billing_country AS country, SUM(total) AS total_revenue
FROM invoice
GROUP BY billing_country
ORDER BY total_revenue DESC
LIMIT 10;

SELECT billing_city AS city, SUM(total) AS total_revenue
FROM invoice
GROUP BY billing_city
ORDER BY total_revenue DESC
LIMIT 10;

WITH CustomerCounts AS (
    SELECT country, COUNT(customer_id) AS num_customers
    FROM customer
    GROUP BY country
),
RevenueCounts AS (
    SELECT billing_country AS country, SUM(total) AS total_revenue
    FROM invoice
    GROUP BY billing_country
)
SELECT
    cc.country, cc.num_customers,
    rc.total_revenue, (rc.total_revenue * 1.0 / cc.num_customers) AS revenue_per_customer
FROM CustomerCounts cc
JOIN RevenueCounts rc ON cc.country = rc.country
ORDER BY revenue_per_customer ASC
LIMIT 10;

-- 6. Customer Retention & Purchase Patterns
SELECT num_purchases, COUNT(customer_id) AS num_customers
FROM
    (SELECT customer_id, COUNT(invoice_id) AS num_purchases
    FROM invoice
    GROUP BY customer_id
    ) AS customer_purchase_counts
GROUP BY num_purchases
ORDER BY num_purchases;

SELECT AVG(DATEDIFF('day', invoice_date, next_purchase_date)) AS avg_days_between_purchases
FROM (
    SELECT
        customer_id,
        invoice_date,
        LEAD(invoice_date) OVER (PARTITION BY customer_id ORDER BY invoice_date) AS next_purchase_date
    FROM invoice
) AS purchase_lags
WHERE next_purchase_date IS NOT NULL;

-- 7. Operational Optimization
SELECT unit_price, SUM(quantity) AS total_quantity_sold
FROM invoicelink
GROUP BY unit_price
ORDER BY unit_price;

SELECT il1.track_id AS track_id_1, il2.track_id AS track_id_2, COUNT(*) AS frequency
FROM invoicelink il1
JOIN invoicelink il2 ON il1.invoice_id = il2.invoice_id
WHERE il1.track_id < il2.track_id 
GROUP BY track_id_1, track_id_2
ORDER BY frequency DESC
LIMIT 10;