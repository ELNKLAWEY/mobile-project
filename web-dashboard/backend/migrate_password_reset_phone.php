<?php
/**
 * Migration: Add phone column to password_reset_otps table
 * Run this once to update the database schema
 */

require_once 'config.php';
require_once 'Database.php';

try {
    $db = Database::getInstance();
    $pdo = $db->getConnection();

    // Check if phone column exists
    $columns = $pdo->query("SHOW COLUMNS FROM password_reset_otps LIKE 'phone'")->fetch();
    
    if (!$columns) {
        // Add phone column
        $pdo->exec("ALTER TABLE password_reset_otps ADD COLUMN phone VARCHAR(20) NULL AFTER email");
        echo "Added phone column to password_reset_otps table\n";
        
        // Add index for phone and otp
        try {
            $pdo->exec("CREATE INDEX idx_phone_otp ON password_reset_otps (phone, otp, used)");
            echo "Added index for phone and otp\n";
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'Duplicate key name') === false) {
                throw $e;
            }
            echo "Index already exists\n";
        }
    } else {
        echo "Phone column already exists in password_reset_otps table\n";
    }

    echo "\nMigration completed successfully!\n";
    echo "You can delete this file for security.\n";

} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
    exit(1);
}
?>

