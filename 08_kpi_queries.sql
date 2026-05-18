--TOTAL REVENUE

SELECT
ROUND(SUM(sales),2) AS total_revenue
FROM SUPPLY_CHAIN_DB.CLEAN.CLEAN_SUPPLY_CHAIN;


--TOTAL PROFIT

SELECT
ROUND(SUM(order_profit_per_order),2) AS total_profit
FROM SUPPLY_CHAIN_DB.CLEAN.CLEAN_SUPPLY_CHAIN;


--LATE DELIVERY %

SELECT
COUNT(*) AS total_shipments,
SUM(late_delivery_risk) AS late_shipments,
ROUND(SUM(late_delivery_risk)/COUNT(*)*100,2) AS late_delivery_percentage
FROM SUPPLY_CHAIN_DB.CLEAN.CLEAN_SUPPLY_CHAIN;


--TOP 10 PRODUCTS

SELECT
product_name,
ROUND(SUM(sales),2) AS revenue,
ROUND(SUM(order_profit_per_order),2) AS profit
FROM SUPPLY_CHAIN_DB.CLEAN.CLEAN_SUPPLY_CHAIN
GROUP BY product_name
ORDER BY revenue DESC
LIMIT 10;


--TOP CATEGORIES

SELECT *
FROM SUPPLY_CHAIN_DB.ANALYTICS.VW_REVENUE_BY_CATEGORY
ORDER BY total_revenue DESC;


--MONTHLY REVENUE TREND

SELECT * FROM SUPPLY_CHAIN_DB.ANALYTICS.VW_MONTHLY_REVENUE;

SELECT
order_month,
monthly_revenue,
LAG(monthly_revenue) OVER (ORDER BY order_month) AS previous_month_revenue,
ROUND((monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY order_month))/
NULLIF(LAG(monthly_revenue) OVER (ORDER BY order_month),0)*100,2) AS revenue_growth_percentage
FROM SUPPLY_CHAIN_DB.ANALYTICS.VW_MONTHLY_REVENUE
ORDER BY order_month;
