<?php
require_once __DIR__ . '/../Database.php';
require_once __DIR__ . '/../Middleware.php';

class OrdersController {
    private $db;
    private $middleware;

    public function __construct() {
        $this->db = Database::getInstance();
        $this->middleware = new Middleware();
    }

    public function getAll($params) {
        $user = $this->middleware->requireAuth();
        
        if ($user['role'] === 'ADMIN') {
            $orders = $this->db->fetchAll(
                "SELECT o.*, u.name as user_name, u.email as user_email
                 FROM orders o
                 JOIN users u ON o.user_id = u.id
                 ORDER BY o.created_at DESC"
            );
        } else {
            $orders = $this->db->fetchAll(
                "SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC",
                [$user['id']]
            );
        }

        // Get order items for each order
        foreach ($orders as &$order) {
            $order['items'] = $this->db->fetchAll(
                "SELECT oi.*, p.title, p.image
                 FROM order_items oi
                 JOIN products p ON oi.product_id = p.id
                 WHERE oi.order_id = ?",
                [$order['id']]
            );
            
            // Convert image paths to full URLs
            foreach ($order['items'] as &$item) {
                $item['image'] = getFullImageUrl($item['image']);
            }
        }

        echo json_encode($orders);
    }

    public function getById($params) {
        $user = $this->middleware->requireAuth();
        
        $order = $this->db->fetchOne("SELECT * FROM orders WHERE id = ?", [$params['id']]);
        
        if (!$order) {
            http_response_code(404);
            echo json_encode(['error' => 'Order not found']);
            return;
        }

        // Check permissions
        if ($user['role'] !== 'ADMIN' && $order['user_id'] != $user['id']) {
            http_response_code(403);
            echo json_encode(['error' => 'Insufficient permissions']);
            return;
        }

        $order['items'] = $this->db->fetchAll(
            "SELECT oi.*, p.title, p.image
             FROM order_items oi
             JOIN products p ON oi.product_id = p.id
             WHERE oi.order_id = ?",
            [$params['id']]
        );

        // Convert image paths to full URLs
        foreach ($order['items'] as &$item) {
            $item['image'] = getFullImageUrl($item['image']);
        }

        echo json_encode($order);
    }

    public function create($params) {
        $user = $this->middleware->requireUser();
        
        // Get cart items
        $cartItems = $this->db->fetchAll(
            "SELECT ci.product_id, ci.quantity, p.price, p.stock, p.title
             FROM cart_items ci
             JOIN products p ON ci.product_id = p.id
             WHERE ci.user_id = ?",
            [$user['id']]
        );

        if (empty($cartItems)) {
            http_response_code(400);
            echo json_encode(['error' => 'Cart is empty']);
            return;
        }

        // Validate stock and calculate total
        $totalPrice = 0;
        foreach ($cartItems as $item) {
            if ($item['quantity'] > $item['stock']) {
                http_response_code(400);
                echo json_encode(['error' => "Insufficient stock for product: {$item['title']}"]);
                return;
            }
            $totalPrice += $item['price'] * $item['quantity'];
        }

        // Start transaction
        $this->db->getConnection()->beginTransaction();

        try {
            // Create order
            $this->db->query(
                "INSERT INTO orders (user_id, total_price, status, created_at) VALUES (?, ?, 'pending', NOW())",
                [$user['id'], $totalPrice]
            );

            $orderId = $this->db->lastInsertId();

            // Create order items and update stock
            foreach ($cartItems as $item) {
                $this->db->query(
                    "INSERT INTO order_items (order_id, product_id, price, quantity) VALUES (?, ?, ?, ?)",
                    [$orderId, $item['product_id'], $item['price'], $item['quantity']]
                );

                $this->db->query(
                    "UPDATE products SET stock = stock - ? WHERE id = ?",
                    [$item['quantity'], $item['product_id']]
                );
            }

            // Clear cart
            $this->db->query("DELETE FROM cart_items WHERE user_id = ?", [$user['id']]);

            $this->db->getConnection()->commit();

            $order = $this->db->fetchOne("SELECT * FROM orders WHERE id = ?", [$orderId]);
            $order['items'] = $this->db->fetchAll(
                "SELECT oi.*, p.title, p.image
                 FROM order_items oi
                 JOIN products p ON oi.product_id = p.id
                 WHERE oi.order_id = ?",
                [$orderId]
            );

            // Convert image paths to full URLs
            foreach ($order['items'] as &$item) {
                $item['image'] = getFullImageUrl($item['image']);
            }

            http_response_code(201);
            echo json_encode($order);
        } catch (Exception $e) {
            $this->db->getConnection()->rollBack();
            http_response_code(500);
            echo json_encode(['error' => 'Failed to create order: ' . $e->getMessage()]);
        }
    }

    public function update($params) {
        $this->middleware->requireAdmin();
        
        $order = $this->db->fetchOne("SELECT id FROM orders WHERE id = ?", [$params['id']]);
        
        if (!$order) {
            http_response_code(404);
            echo json_encode(['error' => 'Order not found']);
            return;
        }

        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['status'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required field: status']);
            return;
        }

        $allowedStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
        if (!in_array($data['status'], $allowedStatuses)) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid status']);
            return;
        }

        $this->db->query(
            "UPDATE orders SET status = ? WHERE id = ?",
            [$data['status'], $params['id']]
        );

        $order = $this->db->fetchOne("SELECT * FROM orders WHERE id = ?", [$params['id']]);
        $order['items'] = $this->db->fetchAll(
            "SELECT oi.*, p.title, p.image
             FROM order_items oi
             JOIN products p ON oi.product_id = p.id
             WHERE oi.order_id = ?",
            [$params['id']]
        );

        // Convert image paths to full URLs
        foreach ($order['items'] as &$item) {
            $item['image'] = getFullImageUrl($item['image']);
        }

        echo json_encode($order);
    }

    public function delete($params) {
        $this->middleware->requireAdmin();
        
        $order = $this->db->fetchOne("SELECT id FROM orders WHERE id = ?", [$params['id']]);
        
        if (!$order) {
            http_response_code(404);
            echo json_encode(['error' => 'Order not found']);
            return;
        }

        // Delete order items first
        $this->db->query("DELETE FROM order_items WHERE order_id = ?", [$params['id']]);
        
        // Delete order
        $this->db->query("DELETE FROM orders WHERE id = ?", [$params['id']]);
        
        echo json_encode(['message' => 'Order deleted successfully']);
    }
}
?>

