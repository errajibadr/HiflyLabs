## HighFly Labs, Case Study

### 1 . Assumptions

1 - Frequency - Daily
* Would need Batch processing. 

2 - Volumetry ? Determining question as it would be a good indicator of the size of the problem. Shall we use some big Data or MPP for processing and storing or would a Datawarehouse be enough?
* i will assume it's not necessarily big data.
Daily CSV files would be of medium size hundreds of megabytes.
if i had the choice, parquet to reduce storage and network latency when data is in transit.

3 - formats :
given files have this structure
* I will assume 
 ID: int,Name: str,City:str  for Customer dimension
 CustomerID:id ,Product:str , SalesAmount:float ,ShopId:int,TransactionDate:datetime For sales Facts
Would there be any shift on the schema? No, for sake of simplicity

4 - What is the preferred achitecture of the stakeholders ? 
* From now on, i will assume we share the same preference.
Cloud preference : AWS
Start with event driven/Serverless architecture for most part.
Given this assumption, i won't use SPARK, or any big data framework.


#### II . The architecture would be as follows:

S3 + S3 trigger

AWS Batch ; Python for Data processing (Lambda would be a good alternative if the data is not big enough and <15mins to process)

Orchestration : AWS Step Functions

Data warehouse : PostGreSQL (AWS RDS) as it's Daily. 
For Streaming, i would use Clickhouse or Druid but much more complex to setup.

File format : CSV but would push to get them in parquet

But let us focus only on what i could spin up on my computer and run directly on my VS code

### Task 0 & 1: 

#### 0 . Load Data :

For sake of simplicity i just loaded the data into the raw tables.
in file task_0.md
better approach would be to load them into raw tables and then transform them into staging tables before loading them into the "data warehouse" with dimension and fact tables.

#### 1. Workflow : 

S3 Raw Files 
→ Raw Tables (in PostgreSQL) 
→ Transform 
→ DW Tables (dim/fact)

#### 2. Schema Organization:

Raw files land in a "raw" S3 prefix
Load them into raw tables
Transform 
dw schema for dimension and fact tables. 


Staging Tables:

raw.customer: Stores raw customer data
raw.customer_sales: Stores raw sales transactions

In 

Data Warehouse Tables:

dw.dim_customer: SCD Type 2 dimension table for customer data
dw.fact_sales: Fact table for sales transactions

#### 3. Transformation:

 - Clean Text Data. ( whitespace, special characters, etc.)
 -convert Data Types 
- handle missing values in ids, sales_amounts, dates ? 
- remove duplicate records based on rules ? 
- integrity Checks about customer_id in sales tables.
- Adapt business rules : e.g. if sales amount < 0 etc.

- Dim Customer SCD 2 to handle change for customers. What if he moves to a different city.

- Shop ID and Product ID dimensions.




### Task 2 : 

Create this KPI as a materialized view.
As refresh window is Daily, we can afford to refresh the view daily.

With correct indexes, business stakeholders will be able to query the view with very good performance.

All is needed is to refresh the view.
```
REFRESH MATERIALIZED VIEW dw.customer_ytd_spending;
```

### Task 3 : 

For this task, multiple approaches could be taken.

On the fly calculation as we just create a regular view.
But depending on the data size, and performance and business requirements on speed.

```
CREATE VIEW mart.customer_days_since_last_purchase AS
SELECT
    dc.customer_key,
    CURRENT_DATE AS reference_date,
    DATE_PART('day', CURRENT_DATE - MAX(fs.transaction_date))::INT AS days_since_last_purchase
FROM dw.dim_customer dc
LEFT JOIN dw.fact_sales fs 
  ON fs.customer_key = dc.customer_key
 AND fs.transaction_date <= CURRENT_DATE
GROUP BY dc.customer_key;
```

i would create another mart table with a daily refresh that precomputes the data. 

```
INSERT INTO mart.customer_days_since_last_purchase (customer_key, reference_date, days_since_last_purchase)
SELECT
    dc.customer_key,
    CURRENT_DATE AS reference_date,
    DATE_PART('day', CURRENT_DATE - MAX(fs.transaction_date))::INT AS days_since_last_purchase
FROM dw.dim_customer dc
LEFT JOIN dw.fact_sales fs 
  ON fs.customer_key = dc.customer_key
 AND fs.transaction_date <= CURRENT_DATE
GROUP BY dc.customer_key;
```
