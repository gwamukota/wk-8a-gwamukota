## Simple Inventory Tracking Database Management System
A MySQL-based inventory tracking system. This focuses on the core functionality needed for basic inventory management without unnecessary complexity.

## What's Included

SQL Database File - Contains all table definitions, relationships, constraints, a view, stored procedures, and sample data
README.md - Documentation explaining how the system works and how to set it up

## Database Features
Tables with Proper Constraints

Primary Keys: All tables use auto-incrementing primary keys
Foreign Keys: Appropriate relationships between tables
NOT NULL: Critical fields are protected from null values
UNIQUE: Business keys have uniqueness constraints (e.g., SKUs, location names)

## Core Tables

Products - Store product information with SKUs and pricing
Categories - Simple product categorization
Inventory - Track stock levels by product and location
Locations - Store/warehouse locations
Suppliers - Basic supplier information
Transactions - Record inventory movements
Transaction_Items - Individual items in each transaction
Transaction_Types - Types of inventory movements

## Extra Features

View: For low stock alerts
Stored Procedures: For adding and removing inventory
Indices: On frequently queried columns for performance

## How to Use It
The system is designed to be straightforward:

1.Import the SQL file into your MySQL server
2.Add your categories, products, and locations
3.Use the stored procedures to add and remove inventory:
    add_inventory(product_id, location_id, quantity, notes)
    remove_inventory(product_id, location_id, quantity, notes)
4.Query the low_stock_items view to see products that need reordering

## Code
Here's how you might use the system:
"" sql-- Add a category
INSERT INTO categories (category_name, description) 
VALUES ('Electronics', 'Electronic devices');

-- Add a product
INSERT INTO products (product_name, sku, description, category_id, unit_price, reorder_level) 
VALUES ('Wireless Mouse', 'WM-001', 'Bluetooth mouse', 1, 19.99, 5);

-- Add a location
INSERT INTO locations (location_name, address) 
VALUES ('Main Store', '123 Main St');

-- Add inventory using the stored procedure
CALL add_inventory(1, 1, 20, 'Initial stock');

-- Make a sale using the stored procedure
CALL remove_inventory(1, 1, 5, 'Customer order #12345');""

