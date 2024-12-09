#!/bin/bash

# Copy CSV files into the container
docker cp data/customer.csv retail_dw:/tmp/customer.csv
docker cp data/sales.csv retail_dw:/tmp/sales.csv

# Load data using psql
docker exec -it retail_dw psql -U postgres -d retail_dw -c "\copy raw.customer FROM '/tmp/customer.csv' WITH (FORMAT csv, HEADER true);"

docker exec -it retail_dw psql -U postgres -d retail_dw -c "\copy raw.customer_sales FROM '/tmp/sales.csv' WITH (FORMAT csv, HEADER true);"

# Clean up
docker exec -it retail_dw rm /tmp/customer.csv /tmp/sales.csv