-- Drop view if it exists
DROP MATERIALIZED VIEW IF EXISTS dw.customer_ytd_spending;

-- Create materialized view for customer YTD spending
CREATE MATERIALIZED VIEW dw.customer_ytd_spending AS
WITH monthly_sales AS (
    -- Get monthly sales per customer
    SELECT 
        dc.customer_id,
        dc.customer_name,
        EXTRACT(YEAR FROM fs.transaction_date) AS year,
        EXTRACT(MONTH FROM fs.transaction_date) AS month,
        SUM(fs.sales_amount) AS monthly_amount
    FROM dw.fact_sales fs
    JOIN dw.dim_customer dc ON fs.customer_key = dc.customer_key
    GROUP BY 
        dc.customer_id,
        dc.customer_name,
        EXTRACT(YEAR FROM fs.transaction_date),
        EXTRACT(MONTH FROM fs.transaction_date)
),
ytd_sales AS (
    -- Calculate running total within each year
    SELECT 
        customer_id,
        customer_name,
        year,
        month,
        monthly_amount,
        SUM(monthly_amount) OVER (
            PARTITION BY customer_id, year
            ORDER BY month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS ytd_amount
    FROM monthly_sales
)
SELECT 
    customer_id,
    customer_name,
    year,
    month,
    monthly_amount,
    ytd_amount,
    -- Calculate percentage of yearly total
    ROUND(
        (ytd_amount / SUM(monthly_amount) OVER (PARTITION BY customer_id, year)) * 100,
        2
    ) as ytd_percentage
FROM ytd_sales
ORDER BY 
    customer_id,
    year,
    month;

-- Create indexes for better query performance
CREATE INDEX idx_customer_ytd_year ON dw.customer_ytd_spending(year);
CREATE INDEX idx_customer_ytd_month ON dw.customer_ytd_spending(month);
CREATE INDEX idx_customer_ytd_customer ON dw.customer_ytd_spending(customer_id);
