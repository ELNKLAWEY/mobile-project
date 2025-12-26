<?php
require_once 'config.php';

class Database {
    private static $instance = null;
    private $connection;

    private function __construct() {
        try {
            // Build MySQL connection string
            $dsn = "mysql:host=" . DB_HOST;
            
            if (defined('DB_PORT') && DB_PORT) {
                $dsn .= ";port=" . DB_PORT;
            }
            
            $dsn .= ";dbname=" . DB_NAME . ";charset=utf8mb4";
            
            $this->connection = new PDO(
                $dsn,
                DB_USER,
                DB_PASS,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false
                ]
            );
        } catch (PDOException $e) {
            http_response_code(500);
            $errorMsg = 'Database connection failed: ' . $e->getMessage();
            $errorMsg .= "\n\nTroubleshooting tips:";
            $errorMsg .= "\n1. Verify MySQL is running";
            $errorMsg .= "\n2. Check DB_HOST in config.php";
            $errorMsg .= "\n3. Verify DB_PORT (default: 3306)";
            $errorMsg .= "\n4. Check database credentials in config.php";
            $errorMsg .= "\n5. Ensure database 'moha_db' exists";
            echo json_encode(['error' => $errorMsg]);
            exit();
        }
    }

    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function getConnection() {
        return $this->connection;
    }

    public function query($sql, $params = []) {
        try {
            $stmt = $this->connection->prepare($sql);
            $stmt->execute($params);
            return $stmt;
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Database query failed: ' . $e->getMessage()]);
            exit();
        }
    }

    public function fetchAll($sql, $params = []) {
        return $this->query($sql, $params)->fetchAll();
    }

    public function fetchOne($sql, $params = []) {
        return $this->query($sql, $params)->fetch();
    }

    public function lastInsertId() {
        return $this->connection->lastInsertId();
    }
}
?>

