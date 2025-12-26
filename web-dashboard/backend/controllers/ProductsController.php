<?php
require_once __DIR__ . '/../Database.php';
require_once __DIR__ . '/../Middleware.php';
require_once __DIR__ . '/../FileUpload.php';

class ProductsController {
    private $db;
    private $middleware;
    private $fileUpload;

    public function __construct() {
        $this->db = Database::getInstance();
        $this->middleware = new Middleware();
        $this->fileUpload = new FileUpload('uploads');
    }

    public function getAll($params) {
        $search = $_GET['search'] ?? '';
        $minPrice = $_GET['min_price'] ?? null;
        $maxPrice = $_GET['max_price'] ?? null;
        $page = max(1, intval($_GET['page'] ?? 1));
        $limit = max(1, min(100, intval($_GET['limit'] ?? 20)));
        $offset = ($page - 1) * $limit;

        $where = [];
        $queryParams = [];

        if ($search) {
            $where[] = "(LOWER(title) LIKE LOWER(?) OR LOWER(description) LIKE LOWER(?))";
            $queryParams[] = "%$search%";
            $queryParams[] = "%$search%";
        }

        if ($minPrice !== null && is_numeric($minPrice)) {
            $where[] = "price >= ?";
            $queryParams[] = $minPrice;
        }

        if ($maxPrice !== null && is_numeric($maxPrice)) {
            $where[] = "price <= ?";
            $queryParams[] = $maxPrice;
        }

        $whereClause = !empty($where) ? "WHERE " . implode(" AND ", $where) : "";

        // Get total count - use same params as where clause (before adding limit/offset)
        $countSql = "SELECT COUNT(*) as total FROM products $whereClause";
        $total = $this->db->fetchOne($countSql, $queryParams)['total'];

        // Get products with brand info
        $sql = "SELECT p.*, b.name as brand_name, b.image as brand_image 
                FROM products p 
                LEFT JOIN brands b ON p.brand_id = b.id 
                $whereClause 
                ORDER BY p.created_at DESC 
                LIMIT ? OFFSET ?";
        $queryParams[] = $limit;
        $queryParams[] = $offset;
        
        $products = $this->db->fetchAll($sql, $queryParams);

        // Convert image paths to full URLs
        foreach ($products as &$product) {
            $product['image'] = getFullImageUrl($product['image']);
            if (isset($product['brand_image'])) {
                $product['brand_image'] = getFullImageUrl($product['brand_image']);
            }
        }

        echo json_encode([
            'products' => $products,
            'pagination' => [
                'page' => $page,
                'limit' => $limit,
                'total' => intval($total),
                'pages' => ceil($total / $limit)
            ]
        ]);
    }

    public function getById($params) {
        $product = $this->db->fetchOne(
            "SELECT p.*, b.name as brand_name, b.image as brand_image 
             FROM products p 
             LEFT JOIN brands b ON p.brand_id = b.id 
             WHERE p.id = ?",
            [$params['id']]
        );

        if (!$product) {
            http_response_code(404);
            echo json_encode(['error' => 'Product not found']);
            return;
        }

        // Convert image paths to full URLs
        $product['image'] = getFullImageUrl($product['image']);
        if (isset($product['brand_image'])) {
            $product['brand_image'] = getFullImageUrl($product['brand_image']);
        }

        echo json_encode($product);
    }

    public function create($params) {
        $this->middleware->requireAdmin();
        
        // Check if request is multipart/form-data (file upload)
        $isMultipart = isset($_FILES['image']) && $_FILES['image']['error'] !== UPLOAD_ERR_NO_FILE;
        
        if ($isMultipart) {
            // Handle multipart/form-data
            $title = $_POST['title'] ?? '';
            $description = $_POST['description'] ?? '';
            $price = $_POST['price'] ?? '';
            $stock = $_POST['stock'] ?? '';
            $brandId = $_POST['brand_id'] ?? null;
            
            // Validate required fields
            if (empty($title) || empty($description) || empty($price) || empty($stock)) {
                http_response_code(400);
                echo json_encode(['error' => 'Missing required fields: title, description, price, stock']);
                return;
            }
            
            // Validate brand_id if provided
            if ($brandId !== null && $brandId !== '') {
                $brand = $this->db->fetchOne("SELECT id FROM brands WHERE id = ?", [$brandId]);
                if (!$brand) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Invalid brand_id']);
                    return;
                }
            } else {
                $brandId = null;
            }
            
            // Upload image
            $imagePath = null;
            if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
                $uploadResult = $this->fileUpload->upload($_FILES['image'], 'product');
                if (!$uploadResult['success']) {
                    http_response_code(400);
                    echo json_encode(['error' => $uploadResult['error']]);
                    return;
                }
                $imagePath = $uploadResult['path'];
            }
        } else {
            // Handle JSON request (backward compatibility)
            $data = json_decode(file_get_contents('php://input'), true);
            
            $required = ['title', 'description', 'price', 'stock'];
            foreach ($required as $field) {
                if (!isset($data[$field])) {
                    http_response_code(400);
                    echo json_encode(['error' => "Missing required field: $field"]);
                    return;
                }
            }
            
            $title = $data['title'];
            $description = $data['description'];
            $price = $data['price'];
            $stock = $data['stock'];
            $brandId = $data['brand_id'] ?? null;
            $imagePath = $data['image'] ?? ''; // Optional if no file uploaded

            // Validate brand_id if provided
            if ($brandId !== null && $brandId !== '') {
                $brand = $this->db->fetchOne("SELECT id FROM brands WHERE id = ?", [$brandId]);
                if (!$brand) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Invalid brand_id']);
                    return;
                }
            } else {
                $brandId = null;
            }
        }

        $this->db->query(
            "INSERT INTO products (title, description, price, image, stock, brand_id, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())",
            [$title, $description, $price, $imagePath, $stock, $brandId]
        );

        $productId = $this->db->lastInsertId();
        $product = $this->db->fetchOne(
            "SELECT p.*, b.name as brand_name, b.image as brand_image 
             FROM products p 
             LEFT JOIN brands b ON p.brand_id = b.id 
             WHERE p.id = ?",
            [$productId]
        );

        // Convert image paths to full URLs
        $product['image'] = getFullImageUrl($product['image']);
        if (isset($product['brand_image'])) {
            $product['brand_image'] = getFullImageUrl($product['brand_image']);
        }

        http_response_code(201);
        echo json_encode($product);
    }

    public function update($params) {
        $this->middleware->requireAdmin();
        
        $product = $this->db->fetchOne("SELECT id, image FROM products WHERE id = ?", [$params['id']]);
        
        if (!$product) {
            http_response_code(404);
            echo json_encode(['error' => 'Product not found']);
            return;
        }

        // Check Content-Type to determine request type
        $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
        $isMultipartFormData = strpos($contentType, 'multipart/form-data') !== false;
        $isJson = strpos($contentType, 'application/json') !== false;
        
        $updates = [];
        $values = [];
        $data = [];

        // Handle multipart/form-data
        if ($isMultipartFormData) {
            // PHP may not populate $_POST automatically for PATCH with multipart/form-data
            // So we always parse manually for multipart
            $rawInput = file_get_contents('php://input');
            
            // Also check $_POST in case PHP did populate it
            if (!empty($_POST)) {
                $data = array_merge($data, $_POST);
            }
            
            // Parse multipart data manually
            if (!empty($rawInput)) {
                // Extract boundary from Content-Type
                $boundary = '';
                if (preg_match('/boundary=([^\s;]+)/i', $contentType, $matches)) {
                    $boundary = '--' . trim($matches[1]);
                }
                
                if ($boundary) {
                    // Split by boundary
                    $parts = explode($boundary, $rawInput);
                    foreach ($parts as $part) {
                        // Skip empty parts and closing boundary
                        $part = trim($part);
                        if ($part === '' || $part === '--') {
                            continue;
                        }
                        
                        // Match form field
                        if (preg_match('/Content-Disposition:\s*form-data;\s*name="([^"]+)"\s*\r?\n\r?\n(.*?)(?=\r?\n--|$)/s', $part, $matches)) {
                            $fieldName = trim($matches[1]);
                            $fieldValue = trim($matches[2]);
                            // Remove trailing newlines and boundary markers
                            $fieldValue = preg_replace('/[\r\n-]+$/', '', $fieldValue);
                            // Only process non-file fields
                            if ($fieldName !== 'image' && $fieldValue !== '') {
                                $data[$fieldName] = $fieldValue;
                            }
                        }
                    }
                }
            }
        } elseif ($isJson) {
            // Handle JSON
            $rawInput = file_get_contents('php://input');
            if (!empty($rawInput)) {
                $data = json_decode($rawInput, true);
            }
        } else {
            // Handle form-urlencoded or $_POST
            if (!empty($_POST)) {
                $data = $_POST;
            } else {
                $rawInput = file_get_contents('php://input');
                if (!empty($rawInput)) {
                    parse_str($rawInput, $data);
                }
            }
        }

        // Process data fields
        $allowedFields = ['title', 'description', 'price', 'stock'];
        foreach ($allowedFields as $field) {
            if (isset($data[$field]) && $data[$field] !== '' && $data[$field] !== null) {
                $updates[] = "$field = ?";
                $values[] = $data[$field];
            }
        }

        // Handle brand_id
        if (isset($data['brand_id'])) {
            if ($data['brand_id'] === '' || $data['brand_id'] === null) {
                $updates[] = "brand_id = NULL";
            } else {
                // Validate brand_id
                $brand = $this->db->fetchOne("SELECT id FROM brands WHERE id = ?", [$data['brand_id']]);
                if (!$brand) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Invalid brand_id']);
                    return;
                }
                $updates[] = "brand_id = ?";
                $values[] = $data['brand_id'];
            }
        }
        
        // Handle image upload (only if file is uploaded)
        if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
            $uploadResult = $this->fileUpload->upload($_FILES['image'], 'product');
            if ($uploadResult['success']) {
                // Delete old image if exists
                if (!empty($product['image'])) {
                    $this->fileUpload->delete($product['image']);
                }
                $updates[] = "image = ?";
                $values[] = $uploadResult['path'];
            } else {
                http_response_code(400);
                echo json_encode(['error' => $uploadResult['error']]);
                return;
            }
        } elseif (isset($data['image']) && $data['image'] !== '' && $data['image'] !== null) {
            // If image is provided as URL/path (not file upload)
            $updates[] = "image = ?";
            $values[] = $data['image'];
        }

        if (empty($updates)) {
            http_response_code(400);
            echo json_encode(['error' => 'No fields to update. Please provide at least one field to update.']);
            return;
        }

        $values[] = $params['id'];
        $sql = "UPDATE products SET " . implode(', ', $updates) . " WHERE id = ?";
        $this->db->query($sql, $values);

        $product = $this->db->fetchOne(
            "SELECT p.*, b.name as brand_name, b.image as brand_image 
             FROM products p 
             LEFT JOIN brands b ON p.brand_id = b.id 
             WHERE p.id = ?",
            [$params['id']]
        );

        // Convert image paths to full URLs
        $product['image'] = getFullImageUrl($product['image']);
        if (isset($product['brand_image'])) {
            $product['brand_image'] = getFullImageUrl($product['brand_image']);
        }

        echo json_encode($product);
    }

    public function delete($params) {
        $this->middleware->requireAdmin();
        
        $product = $this->db->fetchOne("SELECT id, image FROM products WHERE id = ?", [$params['id']]);
        
        if (!$product) {
            http_response_code(404);
            echo json_encode(['error' => 'Product not found']);
            return;
        }

        // Delete product image if exists
        if (!empty($product['image'])) {
            $this->fileUpload->delete($product['image']);
        }

        $this->db->query("DELETE FROM products WHERE id = ?", [$params['id']]);
        echo json_encode(['message' => 'Product deleted successfully']);
    }
}
?>

