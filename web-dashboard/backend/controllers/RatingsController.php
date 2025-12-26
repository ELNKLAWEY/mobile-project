<?php
require_once __DIR__ . '/../Database.php';
require_once __DIR__ . '/../Middleware.php';

class RatingsController {
    private $db;
    private $middleware;

    public function __construct() {
        $this->db = Database::getInstance();
        $this->middleware = new Middleware();
    }

    public function getByProduct($params) {
        $productId = $params['product_id'];
        
        // Check if product exists
        $product = $this->db->fetchOne("SELECT id FROM products WHERE id = ?", [$productId]);
        if (!$product) {
            http_response_code(404);
            echo json_encode(['error' => 'Product not found']);
            return;
        }

        $ratings = $this->db->fetchAll(
            "SELECT r.*, u.name as user_name, u.email as user_email 
             FROM product_ratings r 
             JOIN users u ON r.user_id = u.id 
             WHERE r.product_id = ? 
             ORDER BY r.created_at DESC",
            [$productId]
        );

        // Calculate average rating
        $avgRating = $this->db->fetchOne(
            "SELECT AVG(rating) as avg_rating, COUNT(*) as total_ratings 
             FROM product_ratings 
             WHERE product_id = ?",
            [$productId]
        );

        echo json_encode([
            'product_id' => intval($productId),
            'average_rating' => $avgRating['avg_rating'] ? round(floatval($avgRating['avg_rating']), 2) : 0,
            'total_ratings' => intval($avgRating['total_ratings']),
            'ratings' => $ratings
        ]);
    }

    public function create($params) {
        $user = $this->middleware->requireAuth();
        
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['product_id']) || !isset($data['rating'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields: product_id, rating']);
            return;
        }

        $productId = $data['product_id'];
        $rating = intval($data['rating']);
        $comment = $data['comment'] ?? null;

        // Validate rating
        if ($rating < 1 || $rating > 5) {
            http_response_code(400);
            echo json_encode(['error' => 'Rating must be between 1 and 5']);
            return;
        }

        // Check if product exists
        $product = $this->db->fetchOne("SELECT id FROM products WHERE id = ?", [$productId]);
        if (!$product) {
            http_response_code(404);
            echo json_encode(['error' => 'Product not found']);
            return;
        }

        // Check if user already rated this product
        $existing = $this->db->fetchOne(
            "SELECT id FROM product_ratings WHERE user_id = ? AND product_id = ?",
            [$user['id'], $productId]
        );

        if ($existing) {
            // Update existing rating
            $this->db->query(
                "UPDATE product_ratings SET rating = ?, comment = ? WHERE id = ?",
                [$rating, $comment, $existing['id']]
            );
            $ratingId = $existing['id'];
        } else {
            // Create new rating
            $this->db->query(
                "INSERT INTO product_ratings (product_id, user_id, rating, comment, created_at) VALUES (?, ?, ?, ?, NOW())",
                [$productId, $user['id'], $rating, $comment]
            );
            $ratingId = $this->db->lastInsertId();
        }

        $ratingRecord = $this->db->fetchOne(
            "SELECT r.*, u.name as user_name, u.email as user_email 
             FROM product_ratings r 
             JOIN users u ON r.user_id = u.id 
             WHERE r.id = ?",
            [$ratingId]
        );

        http_response_code($existing ? 200 : 201);
        echo json_encode($ratingRecord);
    }

    public function delete($params) {
        $user = $this->middleware->requireAuth();
        
        $ratingId = $params['id'];
        
        // Check if rating exists and belongs to user
        $rating = $this->db->fetchOne(
            "SELECT * FROM product_ratings WHERE id = ?",
            [$ratingId]
        );

        if (!$rating) {
            http_response_code(404);
            echo json_encode(['error' => 'Rating not found']);
            return;
        }

        // Check if user owns the rating or is admin
        if ($rating['user_id'] != $user['id'] && $user['role'] !== 'ADMIN') {
            http_response_code(403);
            echo json_encode(['error' => 'You can only delete your own ratings']);
            return;
        }

        $this->db->query("DELETE FROM product_ratings WHERE id = ?", [$ratingId]);
        echo json_encode(['message' => 'Rating deleted successfully']);
    }

    public function getMyRatings($params) {
        $user = $this->middleware->requireAuth();
        
        $ratings = $this->db->fetchAll(
            "SELECT r.*, p.title as product_title, p.image as product_image 
             FROM product_ratings r 
             JOIN products p ON r.product_id = p.id 
             WHERE r.user_id = ? 
             ORDER BY r.created_at DESC",
            [$user['id']]
        );

        // Convert image paths to full URLs
        foreach ($ratings as &$rating) {
            $rating['product_image'] = getFullImageUrl($rating['product_image']);
        }

        echo json_encode($ratings);
    }
}
?>

