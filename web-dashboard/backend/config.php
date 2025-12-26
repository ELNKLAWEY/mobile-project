<?php
// Database Configuration (MySQL)
define('DB_HOST', 'localhost');
define('DB_PORT', '3306'); // MySQL default port
define('DB_NAME', 'api_db');
define('DB_USER', 'api_root');
define('DB_PASS', 'NtqPvc2WLvcuaO');

// JWT Configuration
define('JWT_SECRET', 'bc26e8b8c72effc8b36a4390531ba9527cdaa755');
define('JWT_ALGORITHM', 'HS256');
define('JWT_EXPIRATION', 3600); // 1 hour

// API Configuration
define('API_VERSION', 'v1');
define('API_PREFIX', '/api/v1');
define('BASE_URL', 'https://api.mohamed-osama.cloud');

// Helper function to get full image URL
function getFullImageUrl($path) {
    if (empty($path)) {
        return null;
    }
    // If already a full URL, return as is
    if (strpos($path, 'http://') === 0 || strpos($path, 'https://') === 0) {
        return $path;
    }
    // Remove leading slash if exists
    $path = ltrim($path, '/');
    return BASE_URL . '/' . $path;
}

// CORS Headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
?>

