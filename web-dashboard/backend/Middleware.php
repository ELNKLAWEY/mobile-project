<?php
require_once 'Auth.php';

class Middleware {
    private $auth;

    public function __construct() {
        $this->auth = new Auth();
    }

    public function requireAuth() {
        $token = $this->getTokenFromHeader();
        
        if (!$token) {
            http_response_code(401);
            echo json_encode(['error' => 'Authentication required']);
            exit();
        }

        $user = $this->auth->getCurrentUser($token);
        
        if (!$user) {
            http_response_code(401);
            echo json_encode(['error' => 'Invalid or expired token']);
            exit();
        }

        return $user;
    }

    public function requireRole($allowedRoles) {
        $user = $this->requireAuth();
        
        if (!in_array($user['role'], $allowedRoles)) {
            http_response_code(403);
            echo json_encode(['error' => 'Insufficient permissions']);
            exit();
        }

        return $user;
    }

    public function requireAdmin() {
        return $this->requireRole(['ADMIN']);
    }

    public function requireUser() {
        return $this->requireRole(['USER', 'ADMIN']);
    }

    public function requireSelfOrAdmin($userId) {
        $user = $this->requireAuth();
        
        if ($user['id'] != $userId && $user['role'] !== 'ADMIN') {
            http_response_code(403);
            echo json_encode(['error' => 'Insufficient permissions']);
            exit();
        }

        return $user;
    }

    public function getTokenFromHeader() {
        $headers = getallheaders();
        
        if (isset($headers['Authorization'])) {
            $authHeader = $headers['Authorization'];
        } elseif (isset($headers['authorization'])) {
            $authHeader = $headers['authorization'];
        } else {
            return null;
        }

        if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            return $matches[1];
        }

        return null;
    }
}
?>

