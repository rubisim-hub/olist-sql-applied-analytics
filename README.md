# Applied SQL Analytics on Olist: Revenue, Customer Behavior, Delivery Performance, and Review Signals

## Project Overview
This project analyzes a multi-table Brazilian e-commerce dataset using SQL in SQLite. The goal is to answer business questions around revenue, customer behavior, seller performance, delivery operations, and customer satisfaction.

The analysis was designed as a portfolio project for an Applied Data Scientist / ML Engineer trajectory, combining relational SQL analysis with business-oriented thinking and ML-ready feature ideas.

## Dataset
Source: Brazilian E-Commerce Public Dataset by Olist  
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

Core tables used in this project:
- customers
- orders
- order_items
- payments
- reviews
- products
- sellers
- product_category_translation

## Why this project fits an Applied Data Scientist profile
This project goes beyond basic SQL querying by connecting multiple business domains:
- revenue and order trends
- customer behavior
- seller performance
- delivery delays
- customer review signals

It also creates a natural bridge toward downstream ML tasks such as:
- late delivery prediction
- low review score prediction
- customer segmentation
- seller risk profiling

## Tools
- SQL
- SQLite
- SQLiteOnline
- GitHub

## Project Objectives
The project focuses on the following questions:
1. What is the overall revenue and average order value?
2. How does revenue change over time?
3. Who are the top customers by lifetime value?
4. Which product categories generate the highest revenue?
5. Which sellers contribute the most GMV?
6. How concentrated is seller revenue?
7. What is the distribution of order statuses?
8. How strong is delivery performance?
9. Which states show higher late-delivery rates?
10. How are review scores distributed?
11. Which categories are associated with lower customer satisfaction?
12. What payment patterns appear in the data?
13. Which signals could be useful for future ML modeling?

## Data Model
This project uses a relational schema built from the original Olist CSV files and an analytical view (`vw_order_line_enriched`) to simplify business analysis.

Main relationships:
- `customers` → `orders`
- `orders` → `order_items`
- `orders` → `payments`
- `orders` → `reviews`
- `order_items` → `products`
- `order_items` → `sellers`

## Repository Structure
```text
olist-sql-applied-analytics/
├── data/
│   └── raw/
├── sql/
├── outputs/
└── README.md

