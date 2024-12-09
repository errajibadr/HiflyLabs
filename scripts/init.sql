-- Create schemas
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS mart;

-- Task 0
-- Raw tables to store the initial data load
CREATE TABLE IF NOT EXISTS raw.customer (
    customer_id INTEGER PRIMARY KEY,
    name VARCHAR(100),
    city VARCHAR(100),
    source_file(100),
    raw_load_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS raw.customer_sales (
    sale_id SERIAL PRIMARY KEY,
    customer_id INTEGER,
    product VARCHAR(100),
    sales_amount DECIMAL(10,2),
    shop_id INTEGER,
    transaction_date TIMESTAMP,
    source_file VARCHAR(100)
    raw_load_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Create indexes for better query performance
CREATE INDEX idx_customer_id ON raw.customer_sales(customer_id);
CREATE INDEX idx_transaction_date ON raw.customer_sales(transaction_date);


-- Create dimension and fact tables
CREATE TABLE dw.dim_customer (
    customer_key SERIAL PRIMARY KEY,
    customer_id INTEGER UNIQUE,
    customer_name VARCHAR(255),
    city VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



CREATE TABLE dw.fact_sales (
    sales_key SERIAL PRIMARY KEY,
    customer_key INTEGER,
    product VARCHAR(255),
    sales_amount DECIMAL(10,2),
    shop_id INTEGER,
    transaction_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_key) REFERENCES dw.dim_customer(customer_key)
);

CREATE INDEX idx_dim_customer_customer_key ON dw.dim_customer(customer_key);
CREATE INDEX idx_fact_sales_date ON dw.fact_sales(transaction_date);
CREATE INDEX idx_fact_sales_customer ON dw.fact_sales(customer_key);


CREATE TRIGGER update_dim_customer_updated_at
    BEFORE UPDATE ON dw.dim_customer
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();