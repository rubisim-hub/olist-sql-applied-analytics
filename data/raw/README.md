# Raw Data Folder

The original Olist CSV files are stored locally and are not included in this repository due to file size considerations.

Files used for this project:
- olist_customers_dataset.csv
- olist_orders_dataset.csv
- olist_order_items_dataset.csv
- olist_order_payments_dataset.csv
- olist_order_reviews_dataset.csv
- olist_products_dataset.csv
- olist_sellers_dataset.csv
- product_category_name_translation.csv

Note:
- `olist_geolocation_dataset.csv` was intentionally excluded from this portfolio version because it is not required for the core SQL analysis.
- Raw data can be downloaded from Kaggle:
  https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

## Import Mapping

| CSV file | Table |
|---|---|
| olist_customers_dataset.csv | customers |
| olist_orders_dataset.csv | orders |
| olist_order_items_dataset.csv | order_items |
| olist_order_payments_dataset.csv | payments |
| olist_order_reviews_dataset.csv | reviews |
| olist_products_dataset.csv | products |
| olist_sellers_dataset.csv | sellers |
| product_category_name_translation.csv | product_category_translation |

## Reproducibility
To reproduce this project:
1. Download the dataset locally from Kaggle.
2. Create the schema using `sql/01_schema.sql`.
3. Import the CSV files into SQLite.
4. Run the analytical view and analysis queries.
