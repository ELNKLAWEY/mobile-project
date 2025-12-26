<?php
class Router {
    private $routes = [];
    private $middleware;

    public function __construct() {
        $this->middleware = new Middleware();
    }

    public function addRoute($method, $path, $handler, $authRequired = false, $allowedRoles = []) {
        $this->routes[] = [
            'method' => $method,
            'path' => $path,
            'handler' => $handler,
            'authRequired' => $authRequired,
            'allowedRoles' => $allowedRoles
        ];
    }

    public function handleRequest() {
        $method = $_SERVER['REQUEST_METHOD'];
        $path = $this->getPath();

        foreach ($this->routes as $route) {
            if ($route['method'] === $method && $this->matchPath($route['path'], $path, $params)) {
                // Apply authentication/authorization
                if ($route['authRequired']) {
                    if (!empty($route['allowedRoles'])) {
                        $this->middleware->requireRole($route['allowedRoles']);
                    } else {
                        $this->middleware->requireAuth();
                    }
                }

                // Call handler
                call_user_func($route['handler'], $params);
                return;
            }
        }

        http_response_code(404);
        echo json_encode(['error' => 'Route not found']);
    }

    private function getPath() {
        $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
        
        // Remove /api/v1 prefix if present
        if (strpos($path, '/api/v1') === 0) {
            $path = substr($path, 7); // Remove '/api/v1'
        }
        
        // Remove leading slash and ensure we have a path
        $path = ltrim($path, '/');
        return $path ? '/' . $path : '/';
    }

    private function matchPath($routePath, $requestPath, &$params) {
        $params = [];
        
        $routeParts = explode('/', trim($routePath, '/'));
        $requestParts = explode('/', trim($requestPath, '/'));

        if (count($routeParts) !== count($requestParts)) {
            return false;
        }

        for ($i = 0; $i < count($routeParts); $i++) {
            if (preg_match('/^{(\w+)}$/', $routeParts[$i], $matches)) {
                $params[$matches[1]] = $requestParts[$i];
            } elseif ($routeParts[$i] !== $requestParts[$i]) {
                return false;
            }
        }

        return true;
    }
}
?>

