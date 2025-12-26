<?php
require_once __DIR__ . '/../Database.php';
require_once __DIR__ . '/../Middleware.php';

class UsersController {
    private $db;
    private $middleware;

    public function __construct() {
        $this->db = Database::getInstance();
        $this->middleware = new Middleware();
    }

    public function getAll($params) {
        $this->middleware->requireAdmin();
        
        $users = $this->db->fetchAll("SELECT id, name, email, phone, address, role, created_at FROM users ORDER BY created_at DESC");
        echo json_encode($users);
    }

    public function getById($params) {
        $this->middleware->requireAdmin();
        
        $user = $this->db->fetchOne(
            "SELECT id, name, email, phone, address, role, created_at FROM users WHERE id = ?",
            [$params['id']]
        );

        if (!$user) {
            http_response_code(404);
            echo json_encode(['error' => 'User not found']);
            return;
        }

        echo json_encode($user);
    }

    public function update($params) {
        $user = $this->middleware->requireSelfOrAdmin($params['id']);
        
        $data = json_decode(file_get_contents('php://input'), true);
        
        $updates = [];
        $values = [];

        if (isset($data['name'])) {
            $updates[] = "name = ?";
            $values[] = $data['name'];
        }

        if (isset($data['email'])) {
            // Check if email already exists
            $existing = $this->db->fetchOne(
                "SELECT id FROM users WHERE email = ? AND id != ?",
                [$data['email'], $params['id']]
            );
            
            if ($existing) {
                http_response_code(400);
                echo json_encode(['error' => 'Email already exists']);
                return;
            }
            
            $updates[] = "email = ?";
            $values[] = $data['email'];
        }

        if (isset($data['password'])) {
            $updates[] = "password = ?";
            $values[] = password_hash($data['password'], PASSWORD_DEFAULT);
        }

        if (isset($data['phone'])) {
            $updates[] = "phone = ?";
            $values[] = $data['phone'];
        }

        if (isset($data['address'])) {
            $updates[] = "address = ?";
            $values[] = $data['address'];
        }

        if (empty($updates)) {
            http_response_code(400);
            echo json_encode(['error' => 'No fields to update']);
            return;
        }

        $values[] = $params['id'];
        $sql = "UPDATE users SET " . implode(', ', $updates) . " WHERE id = ?";
        $this->db->query($sql, $values);

        $user = $this->db->fetchOne(
            "SELECT id, name, email, phone, address, role, created_at FROM users WHERE id = ?",
            [$params['id']]
        );

        echo json_encode($user);
    }

    public function delete($params) {
        $this->middleware->requireAdmin();
        
        $user = $this->db->fetchOne("SELECT id FROM users WHERE id = ?", [$params['id']]);
        
        if (!$user) {
            http_response_code(404);
            echo json_encode(['error' => 'User not found']);
            return;
        }

        $this->db->query("DELETE FROM users WHERE id = ?", [$params['id']]);
        echo json_encode(['message' => 'User deleted successfully']);
    }
}
?>



