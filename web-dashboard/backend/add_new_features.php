<?php
/**
 * Migration: Add phone, address, brands, ratings, and password reset features
 * Run this once to update the database schema
 */

require_once 'config.php';

try {
    $dsn = "mysql:host=" . DB_HOST;
    if (defined('DB_PORT') && DB_PORT) {
        $dsn .= ";port=" . DB_PORT;
    }
    $dsn .= ";dbname=" . DB_NAME . ";charset=utf8mb4";
    
    $pdo = new PDO(
        $dsn,
        DB_USER,
        DB_PASS,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    // Add phone and address columns to users table
    try {
        $pdo->exec("ALTER TABLE users ADD COLUMN phone VARCHAR(20) NULL AFTER email");
        echo "Added phone column to users table\n";
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'Duplicate column') === false) {
            throw $e;
        }
        echo "Phone column already exists in users table\n";
    }

    try {
        $pdo->exec("ALTER TABLE users ADD COLUMN address TEXT NULL AFTER phone");
        echo "Added address column to users table\n";
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'Duplicate column') === false) {
            throw $e;
        }
        echo "Address column already exists in users table\n";
    }

    // Create brands table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS brands (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            image VARCHAR(500),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
    echo "Created brands table\n";

    // Add brand_id to products table
    try {
        $pdo->exec("ALTER TABLE products ADD COLUMN brand_id INT NULL AFTER stock");
        echo "Added brand_id column to products table\n";
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'Duplicate column') === false) {
            throw $e;
        }
        echo "Brand_id column already exists in products table\n";
    }

    try {
        $pdo->exec("ALTER TABLE products ADD FOREIGN KEY (brand_id) REFERENCES brands(id) ON DELETE SET NULL");
        echo "Added foreign key constraint for brand_id\n";
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'Duplicate foreign key') === false) {
            throw $e;
        }
        echo "Foreign key constraint already exists\n";
    }

    // Create product_ratings table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS product_ratings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            product_id INT NOT NULL,
            user_id INT NOT NULL,
            rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
            comment TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            UNIQUE KEY unique_user_product_rating (user_id, product_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
    echo "Created product_ratings table\n";

    // Create password_reset_otps table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS password_reset_otps (
            id INT AUTO_INCREMENT PRIMARY KEY,
            email VARCHAR(255) NOT NULL,
            otp VARCHAR(4) NOT NULL,
            expires_at TIMESTAMP NOT NULL,
            used BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_email_otp (email, otp, used),
            INDEX idx_expires_at (expires_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
    echo "Created password_reset_otps table\n";

    echo "\nMigration completed successfully!\n";
    echo "You can now delete this file for security.\n";

} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
    exit(1);
}
?>

