<?php
require_once __DIR__ . '/../Database.php';
require_once __DIR__ . '/../Middleware.php';

class FavoritesController {
    private $db;
    private $middleware;

    public function __construct() {
        $this->db = Database::getInstance();
        $this->middleware = new Middleware();
    }

    public function getAll($params) {
        $user = $this->middleware->requireUser();
        
        $favorites = $this->db->fetchAll(
            "SELECT f.id, f.product_id, p.title, p.description, p.price, p.image, p.stock, p.created_at
             FROM favorites f
             JOIN products p ON f.product_id = p.id
             WHERE f.user_id = ?
             ORDER BY f.id DESC",
            [$user['id']]
        );

        // Convert image paths to full URLs
        foreach ($favorites as &$favorite) {
            $favorite['image'] = getFullImageUrl($favorite['image']);
        }

        echo json_encode($favorites);
    }

    public function create($params) {
        $user = $this->middleware->requireUser();
        
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['product_id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required field: product_id']);
            return;
        }

        // Check if product exists
        $product = $this->db->fetchOne("SELECT id FROM products WHERE id = ?", [$data['product_id']]);
        
        if (!$product) {
            http_response_code(404);
            echo json_encode(['error' => 'Product not found']);
            return;
        }

        // Check if already favorited
        $existing = $this->db->fetchOne(
            "SELECT id FROM favorites WHERE user_id = ? AND product_id = ?",
            [$user['id'], $data['product_id']]
        );

        if ($existing) {
            http_response_code(400);
            echo json_encode(['error' => 'Product already in favorites']);
            return;
        }

        $this->db->query(
            "INSERT INTO favorites (user_id, product_id) VALUES (?, ?)",
            [$user['id'], $data['product_id']]
        );

        $favoriteId = $this->db->lastInsertId();
        $favorite = $this->db->fetchOne(
            "SELECT f.id, f.product_id, p.title, p.description, p.price, p.image, p.stock, p.created_at
             FROM favorites f
             JOIN products p ON f.product_id = p.id
             WHERE f.id = ?",
            [$favoriteId]
        );

        // Convert image path to full URL
        $favorite['image'] = getFullImageUrl($favorite['image']);

        http_response_code(201);
        echo json_encode($favorite);
    }

    public function delete($params) {
        $user = $this->middleware->requireUser();
        
        $favorite = $this->db->fetchOne(
            "SELECT id FROM favorites WHERE product_id = ? AND user_id = ?",
            [$params['product_id'], $user['id']]
        );

        if (!$favorite) {
            http_response_code(404);
            echo json_encode(['error' => 'Favorite not found']);
            return;
        }

        $this->db->query(
            "DELETE FROM favorites WHERE product_id = ? AND user_id = ?",
            [$params['product_id'], $user['id']]
        );
        
        echo json_encode(['message' => 'Favorite removed successfully']);
    }
}
?>

