-- Inventory Tracking System Database


-- Create database
CREATE DATABASE simple_inventory;

-- Use the database
USE simple_inventory;

-- Create categories table
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    UNIQUE (category_name)
);

-- Create products table
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    sku VARCHAR(50) NOT NULL,
    description VARCHAR(255),
    category_id INT,
    unit_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    reorder_level INT NOT NULL DEFAULT 10,
    discontinued BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
    UNIQUE (sku)
);

-- Create locations table
CREATE TABLE locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    location_name VARCHAR(100) NOT NULL,
    address VARCHAR(255),
    UNIQUE (location_name)
);

-- Create inventory table
CREATE TABLE inventory (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    location_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES locations(location_id) ON DELETE CASCADE,
    UNIQUE (product_id, location_id)
);

-- Create suppliers table
CREATE TABLE suppliers (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    contact_name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    address VARCHAR(255),
    UNIQUE (supplier_name)
);

-- Create transaction_types table
CREATE TABLE transaction_types (
    type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    affects_inventory ENUM('increase', 'decrease', 'none') NOT NULL,
    UNIQUE (type_name)
);

-- Create transactions table
CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    transaction_type_id INT NOT NULL,
    notes VARCHAR(255),
    FOREIGN KEY (transaction_type_id) REFERENCES transaction_types(type_id)
);

-- Create transaction_items table
CREATE TABLE transaction_items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    location_id INT NOT NULL,
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (location_id) REFERENCES locations(location_id)
);

-- Insert sample data into transaction_types table
INSERT INTO transaction_types (type_name, affects_inventory) VALUES
('Purchase', 'increase'),
('Sale', 'decrease'),
('Adjustment', 'increase'),
('Return', 'increase'),
('Damaged', 'decrease');

-- Create view for low stock items
CREATE VIEW low_stock_items AS
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    l.location_name,
    i.quantity,
    p.reorder_level,
    CASE 
        WHEN i.quantity <= 0 THEN 'Out of stock'
        WHEN i.quantity <= p.reorder_level THEN 'Low stock'
        ELSE 'Adequate'
    END AS stock_status
FROM 
    products p
JOIN 
    inventory i ON p.product_id = i.product_id
JOIN 
    locations l ON i.location_id = l.location_id
WHERE 
    p.discontinued = FALSE AND i.quantity <= p.reorder_level
ORDER BY 
    i.quantity ASC;

-- Create a simple stored procedure for adding inventory
DELIMITER $$
CREATE PROCEDURE add_inventory(
    IN p_product_id INT,
    IN p_location_id INT,
    IN p_quantity INT,
    IN p_notes VARCHAR(255)
)
BEGIN
    DECLARE v_transaction_id INT;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Create transaction record
    INSERT INTO transactions (
        transaction_date,
        transaction_type_id,
        notes
    )
    VALUES (
        NOW(),
        (SELECT type_id FROM transaction_types WHERE type_name = 'Purchase'),
        p_notes
    );
    
    -- Get the inserted transaction ID
    SET v_transaction_id = LAST_INSERT_ID();
    
    -- Create transaction item
    INSERT INTO transaction_items (
        transaction_id,
        product_id,
        quantity,
        location_id
    )
    VALUES (
        v_transaction_id,
        p_product_id,
        p_quantity,
        p_location_id
    );
    
    -- Update inventory
    INSERT INTO inventory (product_id, location_id, quantity)
    VALUES (p_product_id, p_location_id, p_quantity)
    ON DUPLICATE KEY UPDATE quantity = quantity + p_quantity;
    
    -- Commit the transaction
    COMMIT;
END$$
DELIMITER ;

-- Create a simple stored procedure for removing inventory
DELIMITER $$
CREATE PROCEDURE remove_inventory(
    IN p_product_id INT,
    IN p_location_id INT,
    IN p_quantity INT,
    IN p_notes VARCHAR(255)
)
BEGIN
    DECLARE v_transaction_id INT;
    DECLARE v_current_quantity INT;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Check if there's enough inventory
    SELECT quantity INTO v_current_quantity
    FROM inventory
    WHERE product_id = p_product_id AND location_id = p_location_id
    FOR UPDATE;
    
    IF v_current_quantity IS NULL OR v_current_quantity < p_quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient inventory';
        ROLLBACK;
    ELSE
        -- Create transaction record
        INSERT INTO transactions (
            transaction_date,
            transaction_type_id,
            notes
        )
        VALUES (
            NOW(),
            (SELECT type_id FROM transaction_types WHERE type_name = 'Sale'),
            p_notes
        );
        
        -- Get the inserted transaction ID
        SET v_transaction_id = LAST_INSERT_ID();
        
        -- Create transaction item
        INSERT INTO transaction_items (
            transaction_id,
            product_id,
            quantity,
            location_id
        )
        VALUES (
            v_transaction_id,
            p_product_id,
            p_quantity,
            p_location_id
        );
        
        -- Update inventory
        UPDATE inventory
        SET quantity = quantity - p_quantity
        WHERE product_id = p_product_id AND location_id = p_location_id;
        
        -- Commit the transaction
        COMMIT;
    END IF;
END$$
DELIMITER ;

-- Create indices for performance
CREATE INDEX idx_inventory_product ON inventory(product_id);
CREATE INDEX idx_inventory_location ON inventory(location_id);
CREATE INDEX idx_product_category ON products(category_id);
CREATE INDEX idx_transaction_type ON transactions(transaction_type_id);