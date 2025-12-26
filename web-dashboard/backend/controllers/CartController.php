<?php
require_once __DIR__ . '/../Database.php';
require_once __DIR__ . '/../Middleware.php';

class CartController {
    private $db;
    private $middleware;

    public function __construct() {
        $this->db = Database::getInstance();
        $this->middleware = new Middleware();
    }

    public function getAll($params) {
        $user = $this->middleware->requireUser();
        
        $cartItems = $this->db->fetchAll(
            "SELECT ci.id, ci.product_id, ci.quantity, p.title, p.description, p.price, p.image, p.stock
             FROM cart_items ci
             JOIN products p ON ci.product_id = p.id
             WHERE ci.user_id = ?
             ORDER BY ci.id DESC",
            [$user['id']]
        );

        // Convert image paths to full URLs
        foreach ($cartItems as &$item) {
            $item['image'] = getFullImageUrl($item['image']);
        }

        echo json_encode($cartItems);
    }

    public function create($params) {
        $user = $this->middleware->requireUser();
        
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['product_id']) || !isset($data['quantity'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields: product_id, quantity']);
            return;
        }

        // Check if product exists
        $product = $this->db->fetchOne("SELECT id, stock FROM products WHERE id = ?", [$data['product_id']]);
        
        if (!$product) {
            http_response_code(404);
            echo json_encode(['error' => 'Product not found']);
            return;
        }

        // Check stock
        if ($data['quantity'] > $product['stock']) {
            http_response_code(400);
            echo json_encode(['error' => 'Insufficient stock']);
            return;
        }

        // Check if item already in cart
        $existing = $this->db->fetchOne(
            "SELECT id, quantity FROM cart_items WHERE user_id = ? AND product_id = ?",
            [$user['id'], $data['product_id']]
        );

        if ($existing) {
            $newQuantity = $existing['quantity'] + $data['quantity'];
            if ($newQuantity > $product['stock']) {
                http_response_code(400);
                echo json_encode(['error' => 'Insufficient stock']);
                return;
            }
            
            $this->db->query(
                "UPDATE cart_items SET quantity = ? WHERE id = ?",
                [$newQuantity, $existing['id']]
            );
            
            $cartItem = $this->db->fetchOne(
                "SELECT ci.id, ci.product_id, ci.quantity, p.title, p.description, p.price, p.image, p.stock
                 FROM cart_items ci
                 JOIN products p ON ci.product_id = p.id
                 WHERE ci.id = ?",
                [$existing['id']]
            );
            
            // Convert image path to full URL
            $cartItem['image'] = getFullImageUrl($cartItem['image']);
        } else {
            $this->db->query(
                "INSERT INTO cart_items (user_id, product_id, quantity) VALUES (?, ?, ?)",
                [$user['id'], $data['product_id'], $data['quantity']]
            );

            $cartItemId = $this->db->lastInsertId();
            $cartItem = $this->db->fetchOne(
                "SELECT ci.id, ci.product_id, ci.quantity, p.title, p.description, p.price, p.image, p.stock
                 FROM cart_items ci
                 JOIN products p ON ci.product_id = p.id
                 WHERE ci.id = ?",
                [$cartItemId]
            );
            
            // Convert image path to full URL
            $cartItem['image'] = getFullImageUrl($cartItem['image']);
        }

        http_response_code(201);
        echo json_encode($cartItem);
    }

    public function update($params) {
        $user = $this->middleware->requireUser();
        
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['quantity'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required field: quantity']);
            return;
        }

        // Check if cart item exists and belongs to user
        $cartItem = $this->db->fetchOne(
            "SELECT ci.*, p.stock FROM cart_items ci
             JOIN products p ON ci.product_id = p.id
             WHERE ci.id = ? AND ci.user_id = ?",
            [$params['item_id'], $user['id']]
        );

        if (!$cartItem) {
            http_response_code(404);
            echo json_encode(['error' => 'Cart item not found']);
            return;
        }

        // Check stock
        if ($data['quantity'] > $cartItem['stock']) {
            http_response_code(400);
            echo json_encode(['error' => 'Insufficient stock']);
            return;
        }

        $this->db->query(
            "UPDATE cart_items SET quantity = ? WHERE id = ?",
            [$data['quantity'], $params['item_id']]
        );

        $updated = $this->db->fetchOne(
            "SELECT ci.id, ci.product_id, ci.quantity, p.title, p.description, p.price, p.image, p.stock
             FROM cart_items ci
             JOIN products p ON ci.product_id = p.id
             WHERE ci.id = ?",
            [$params['item_id']]
        );

        // Convert image path to full URL
        $updated['image'] = getFullImageUrl($updated['image']);

        echo json_encode($updated);
    }

    public function delete($params) {
        $user = $this->middleware->requireUser();
        
        $cartItem = $this->db->fetchOne(
            "SELECT id FROM cart_items WHERE id = ? AND user_id = ?",
            [$params['item_id'], $user['id']]
        );

        if (!$cartItem) {
            http_response_code(404);
            echo json_encode(['error' => 'Cart item not found']);
            return;
        }

        $this->db->query("DELETE FROM cart_items WHERE id = ?", [$params['item_id']]);
        echo json_encode(['message' => 'Cart item deleted successfully']);
    }

    public function clear($params) {
        $user = $this->middleware->requireUser();
        
        $this->db->query("DELETE FROM cart_items WHERE user_id = ?", [$user['id']]);
        echo json_encode(['message' => 'Cart cleared successfully']);
    }
}
?>

