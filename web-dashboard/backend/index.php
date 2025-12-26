<?php
require_once 'config.php';
require_once 'Router.php';
require_once 'controllers/AuthController.php';
require_once 'controllers/UsersController.php';
require_once 'controllers/ProductsController.php';
require_once 'controllers/CartController.php';
require_once 'controllers/FavoritesController.php';
require_once 'controllers/OrdersController.php';
require_once 'controllers/BrandsController.php';
require_once 'controllers/RatingsController.php';

$router = new Router();

// Initialize controllers
$authController = new AuthController();
$usersController = new UsersController();
$productsController = new ProductsController();
$cartController = new CartController();
$favoritesController = new FavoritesController();
$ordersController = new OrdersController();
$brandsController = new BrandsController();
$ratingsController = new RatingsController();

// Auth Routes
$router->addRoute('POST', '/auth/admin/login', [$authController, 'adminLogin'], false);
$router->addRoute('POST', '/auth/register', [$authController, 'register'], false);
$router->addRoute('POST', '/auth/login', [$authController, 'login'], false);
$router->addRoute('POST', '/auth/logout', [$authController, 'logout'], true);
$router->addRoute('GET', '/auth/me', [$authController, 'me'], true);
$router->addRoute('POST', '/auth/refresh', [$authController, 'refresh'], false);
$router->addRoute('POST', '/auth/password/reset/request', [$authController, 'requestPasswordReset'], false);
$router->addRoute('POST', '/auth/password/reset', [$authController, 'resetPassword'], false);
// New password reset APIs using phone
$router->addRoute('POST', '/auth/reset-password/check-phone', [$authController, 'checkPhoneAndSendOTP'], false);
$router->addRoute('POST', '/auth/reset-password/verify-otp', [$authController, 'verifyOTP'], false);
$router->addRoute('POST', '/auth/reset-password/change', [$authController, 'resetPasswordWithToken'], false);

// Users Routes
$router->addRoute('GET', '/users', [$usersController, 'getAll'], true, ['ADMIN']);
$router->addRoute('GET', '/users/{id}', [$usersController, 'getById'], true, ['ADMIN']);
$router->addRoute('PATCH', '/users/{id}', [$usersController, 'update'], true);
$router->addRoute('DELETE', '/users/{id}', [$usersController, 'delete'], true, ['ADMIN']);

// Products Routes
$router->addRoute('GET', '/products', [$productsController, 'getAll'], false);
$router->addRoute('GET', '/products/{id}', [$productsController, 'getById'], false);
$router->addRoute('POST', '/products', [$productsController, 'create'], true, ['ADMIN']);
$router->addRoute('PATCH', '/products/{id}', [$productsController, 'update'], true, ['ADMIN']);
$router->addRoute('DELETE', '/products/{id}', [$productsController, 'delete'], true, ['ADMIN']);

// Cart Routes (specific routes before general ones)
$router->addRoute('GET', '/cart', [$cartController, 'getAll'], true, ['USER', 'ADMIN']);
$router->addRoute('POST', '/cart', [$cartController, 'create'], true, ['USER', 'ADMIN']);
$router->addRoute('PATCH', '/cart/{item_id}', [$cartController, 'update'], true, ['USER', 'ADMIN']);
$router->addRoute('DELETE', '/cart/{item_id}', [$cartController, 'delete'], true, ['USER', 'ADMIN']);
$router->addRoute('DELETE', '/cart', [$cartController, 'clear'], true, ['USER', 'ADMIN']);

// Favorites Routes
$router->addRoute('GET', '/favorites', [$favoritesController, 'getAll'], true, ['USER', 'ADMIN']);
$router->addRoute('POST', '/favorites', [$favoritesController, 'create'], true, ['USER', 'ADMIN']);
$router->addRoute('DELETE', '/favorites/{product_id}', [$favoritesController, 'delete'], true, ['USER', 'ADMIN']);

// Orders Routes
$router->addRoute('GET', '/orders', [$ordersController, 'getAll'], true);
$router->addRoute('GET', '/orders/{id}', [$ordersController, 'getById'], true);
$router->addRoute('POST', '/orders', [$ordersController, 'create'], true, ['USER', 'ADMIN']);
$router->addRoute('PATCH', '/orders/{id}', [$ordersController, 'update'], true, ['ADMIN']);
$router->addRoute('DELETE', '/orders/{id}', [$ordersController, 'delete'], true, ['ADMIN']);

// Brands Routes
$router->addRoute('GET', '/brands', [$brandsController, 'getAll'], false);
$router->addRoute('GET', '/brands/{id}', [$brandsController, 'getById'], false);
$router->addRoute('GET', '/brands/{id}/products', [$brandsController, 'getProducts'], false);
$router->addRoute('POST', '/brands', [$brandsController, 'create'], true, ['ADMIN']);
$router->addRoute('PATCH', '/brands/{id}', [$brandsController, 'update'], true, ['ADMIN']);
$router->addRoute('DELETE', '/brands/{id}', [$brandsController, 'delete'], true, ['ADMIN']);

// Ratings Routes
$router->addRoute('GET', '/products/{product_id}/ratings', [$ratingsController, 'getByProduct'], false);
$router->addRoute('POST', '/ratings', [$ratingsController, 'create'], true);
$router->addRoute('DELETE', '/ratings/{id}', [$ratingsController, 'delete'], true);
$router->addRoute('GET', '/ratings/my', [$ratingsController, 'getMyRatings'], true);

// Handle request
$router->handleRequest();
?>

