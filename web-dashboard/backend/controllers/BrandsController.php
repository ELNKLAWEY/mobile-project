<?php
require_once __DIR__ . '/../Database.php';
require_once __DIR__ . '/../Middleware.php';
require_once __DIR__ . '/../FileUpload.php';

class BrandsController {
    private $db;
    private $middleware;
    private $fileUpload;

    public function __construct() {
        $this->db = Database::getInstance();
        $this->middleware = new Middleware();
        $this->fileUpload = new FileUpload('uploads');
    }

    public function getAll($params) {
        $brands = $this->db->fetchAll("SELECT * FROM brands ORDER BY name ASC");
        
        // Convert image paths to full URLs
        foreach ($brands as &$brand) {
            $brand['image'] = getFullImageUrl($brand['image']);
        }
        
        echo json_encode($brands);
    }

    public function getById($params) {
        $brand = $this->db->fetchOne(
            "SELECT * FROM brands WHERE id = ?",
            [$params['id']]
        );

        if (!$brand) {
            http_response_code(404);
            echo json_encode(['error' => 'Brand not found']);
            return;
        }

        // Convert image path to full URL
        $brand['image'] = getFullImageUrl($brand['image']);

        echo json_encode($brand);
    }

    public function getProducts($params) {
        $brandId = $params['id'];
        
        // Check if brand exists
        $brand = $this->db->fetchOne("SELECT * FROM brands WHERE id = ?", [$brandId]);
        if (!$brand) {
            http_response_code(404);
            echo json_encode(['error' => 'Brand not found']);
            return;
        }

        $search = $_GET['search'] ?? '';
        $minPrice = $_GET['min_price'] ?? null;
        $maxPrice = $_GET['max_price'] ?? null;
        $page = max(1, intval($_GET['page'] ?? 1));
        $limit = max(1, min(100, intval($_GET['limit'] ?? 20)));
        $offset = ($page - 1) * $limit;

        $where = ["brand_id = ?"];
        $queryParams = [$brandId];

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

        $whereClause = "WHERE " . implode(" AND ", $where);

        // Get total count
        $countSql = "SELECT COUNT(*) as total FROM products $whereClause";
        $total = $this->db->fetchOne($countSql, $queryParams)['total'];

        // Get products
        $sql = "SELECT * FROM products $whereClause ORDER BY created_at DESC LIMIT ? OFFSET ?";
        $queryParams[] = $limit;
        $queryParams[] = $offset;
        
        $products = $this->db->fetchAll($sql, $queryParams);

        // Convert image paths to full URLs
        $brand['image'] = getFullImageUrl($brand['image']);
        foreach ($products as &$product) {
            $product['image'] = getFullImageUrl($product['image']);
        }

        echo json_encode([
            'brand' => $brand,
            'products' => $products,
            'pagination' => [
                'page' => $page,
                'limit' => $limit,
                'total' => intval($total),
                'pages' => ceil($total / $limit)
            ]
        ]);
    }

    public function create($params) {
        $this->middleware->requireAdmin();
        
        // Check if request is multipart/form-data (file upload)
        $isMultipart = isset($_FILES['image']) && $_FILES['image']['error'] !== UPLOAD_ERR_NO_FILE;
        
        if ($isMultipart) {
            $name = $_POST['name'] ?? '';
            
            if (empty($name)) {
                http_response_code(400);
                echo json_encode(['error' => 'Missing required field: name']);
                return;
            }
            
            // Upload image
            $imagePath = null;
            if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
                $uploadResult = $this->fileUpload->upload($_FILES['image'], 'brand');
                if (!$uploadResult['success']) {
                    http_response_code(400);
                    echo json_encode(['error' => $uploadResult['error']]);
                    return;
                }
                $imagePath = $uploadResult['path'];
            }
        } else {
            $data = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($data['name'])) {
                http_response_code(400);
                echo json_encode(['error' => 'Missing required field: name']);
                return;
            }
            
            $name = $data['name'];
            $imagePath = $data['image'] ?? null;
        }

        $this->db->query(
            "INSERT INTO brands (name, image, created_at) VALUES (?, ?, NOW())",
            [$name, $imagePath]
        );

        $brandId = $this->db->lastInsertId();
        $brand = $this->db->fetchOne("SELECT * FROM brands WHERE id = ?", [$brandId]);

        // Convert image path to full URL
        $brand['image'] = getFullImageUrl($brand['image']);

        http_response_code(201);
        echo json_encode($brand);
    }

    public function update($params) {
        $this->middleware->requireAdmin();
        
        $brand = $this->db->fetchOne("SELECT id, image FROM brands WHERE id = ?", [$params['id']]);
        
        if (!$brand) {
            http_response_code(404);
            echo json_encode(['error' => 'Brand not found']);
            return;
        }

        $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
        $isMultipartFormData = strpos($contentType, 'multipart/form-data') !== false;
        $isJson = strpos($contentType, 'application/json') !== false;
        
        $updates = [];
        $values = [];
        $data = [];

        if ($isMultipartFormData) {
            $rawInput = file_get_contents('php://input');
            
            if (!empty($_POST)) {
                $data = array_merge($data, $_POST);
            }
            
            if (!empty($rawInput)) {
                $boundary = '';
                if (preg_match('/boundary=([^\s;]+)/i', $contentType, $matches)) {
                    $boundary = '--' . trim($matches[1]);
                }
                
                if ($boundary) {
                    $parts = explode($boundary, $rawInput);
                    foreach ($parts as $part) {
                        $part = trim($part);
                        if ($part === '' || $part === '--') {
                            continue;
                        }
                        
                        if (preg_match('/Content-Disposition:\s*form-data;\s*name="([^"]+)"\s*\r?\n\r?\n(.*?)(?=\r?\n--|$)/s', $part, $matches)) {
                            $fieldName = trim($matches[1]);
                            $fieldValue = trim($matches[2]);
                            $fieldValue = preg_replace('/[\r\n-]+$/', '', $fieldValue);
                            if ($fieldName !== 'image' && $fieldValue !== '') {
                                $data[$fieldName] = $fieldValue;
                            }
                        }
                    }
                }
            }
        } elseif ($isJson) {
            $rawInput = file_get_contents('php://input');
            if (!empty($rawInput)) {
                $data = json_decode($rawInput, true);
            }
        } else {
            if (!empty($_POST)) {
                $data = $_POST;
            } else {
                $rawInput = file_get_contents('php://input');
                if (!empty($rawInput)) {
                    parse_str($rawInput, $data);
                }
            }
        }

        if (isset($data['name']) && $data['name'] !== '' && $data['name'] !== null) {
            $updates[] = "name = ?";
            $values[] = $data['name'];
        }
        
        if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
            $uploadResult = $this->fileUpload->upload($_FILES['image'], 'brand');
            if ($uploadResult['success']) {
                if (!empty($brand['image'])) {
                    $this->fileUpload->delete($brand['image']);
                }
                $updates[] = "image = ?";
                $values[] = $uploadResult['path'];
            } else {
                http_response_code(400);
                echo json_encode(['error' => $uploadResult['error']]);
                return;
            }
        } elseif (isset($data['image']) && $data['image'] !== '' && $data['image'] !== null) {
            $updates[] = "image = ?";
            $values[] = $data['image'];
        }

        if (empty($updates)) {
            http_response_code(400);
            echo json_encode(['error' => 'No fields to update']);
            return;
        }

        $values[] = $params['id'];
        $sql = "UPDATE brands SET " . implode(', ', $updates) . " WHERE id = ?";
        $this->db->query($sql, $values);

        $brand = $this->db->fetchOne("SELECT * FROM brands WHERE id = ?", [$params['id']]);
        
        // Convert image path to full URL
        $brand['image'] = getFullImageUrl($brand['image']);

        echo json_encode($brand);
    }

    public function delete($params) {
        $this->middleware->requireAdmin();
        
        $brand = $this->db->fetchOne("SELECT id, image FROM brands WHERE id = ?", [$params['id']]);
        
        if (!$brand) {
            http_response_code(404);
            echo json_encode(['error' => 'Brand not found']);
            return;
        }

        // Check if brand has products
        $productsCount = $this->db->fetchOne(
            "SELECT COUNT(*) as count FROM products WHERE brand_id = ?",
            [$params['id']]
        )['count'];

        if ($productsCount > 0) {
            http_response_code(400);
            echo json_encode(['error' => 'Cannot delete brand with associated products. Please remove or reassign products first.']);
            return;
        }

        // Delete brand image if exists
        if (!empty($brand['image'])) {
            $this->fileUpload->delete($brand['image']);
        }

        $this->db->query("DELETE FROM brands WHERE id = ?", [$params['id']]);
        echo json_encode(['message' => 'Brand deleted successfully']);
    }
}
?>

