# E-commerce Backend API

A custom PHP e-commerce backend API built without any framework.

## Features

- JWT-based authentication
- Role-based access control (USER, ADMIN)
- RESTful API design
- MySQL database (phpMyAdmin compatible)
- Complete CRUD operations for all resources

## Installation

1. **Database Setup**

   Run the database setup script to create all necessary tables:

   ```bash
   php setup_database.php
   ```

   After running, you can delete `setup_database.php` for security.

2. **Configuration**

   Update `config.php` with your database credentials and JWT secret:

   ```php
   define('DB_HOST', 'localhost');
   define('DB_NAME', 'moha_db');
   define('DB_USER', 'moha_root');
   define('DB_PASS', 'your_password');
   define('JWT_SECRET', 'your-secret-key-change-this-in-production');
   ```

3. **Web Server Configuration**

   Ensure your web server is configured to:
   - Point to the `public_html` directory
   - Enable mod_rewrite (for Apache)
   - Allow `.htaccess` files

## API Endpoints

### Authentication

- `POST /api/v1/auth/register` - Register a new user
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/admin/login` - Admin login
- `POST /api/v1/auth/logout` - Logout (requires auth)
- `GET /api/v1/auth/me` - Get current user (requires auth)
- `POST /api/v1/auth/refresh` - Refresh access token

### Users

- `GET /api/v1/users` - Get all users (ADMIN only)
- `GET /api/v1/users/{id}` - Get user by ID (ADMIN only)
- `PATCH /api/v1/users/{id}` - Update user (self or ADMIN)
- `DELETE /api/v1/users/{id}` - Delete user (ADMIN only)

### Products

- `GET /api/v1/products` - Get all products (public)
  - Query params: `search`, `min_price`, `max_price`, `page`, `limit`
- `GET /api/v1/products/{id}` - Get product by ID (public)
- `POST /api/v1/products` - Create product (ADMIN only)
- `PATCH /api/v1/products/{id}` - Update product (ADMIN only)
- `DELETE /api/v1/products/{id}` - Delete product (ADMIN only)

### Cart

- `GET /api/v1/cart` - Get cart items (USER)
- `POST /api/v1/cart` - Add item to cart (USER)
- `PATCH /api/v1/cart/{item_id}` - Update cart item quantity (USER)
- `DELETE /api/v1/cart/{item_id}` - Remove item from cart (USER)
- `DELETE /api/v1/cart` - Clear cart (USER)

### Favorites

- `GET /api/v1/favorites` - Get favorites (USER)
- `POST /api/v1/favorites` - Add to favorites (USER)
- `DELETE /api/v1/favorites/{product_id}` - Remove from favorites (USER)

### Orders

- `GET /api/v1/orders` - Get orders (USER: own, ADMIN: all)
- `GET /api/v1/orders/{id}` - Get order by ID (USER: own, ADMIN: any)
- `POST /api/v1/orders` - Create order from cart (USER)
- `PATCH /api/v1/orders/{id}` - Update order status (ADMIN only)
- `DELETE /api/v1/orders/{id}` - Delete order (ADMIN only)

## Authentication

All protected endpoints require a JWT token in the Authorization header:

```
Authorization: Bearer <token>
```

## Request/Response Format

All requests and responses use JSON format.

### Example Request

```bash
curl -X POST https://your-domain.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

### Example Response

```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "user@example.com",
    "role": "USER",
    "created_at": "2024-01-01 12:00:00"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

## Database Schema

The API uses the following tables:
- `users` - User accounts
- `products` - Product catalog
- `cart_items` - Shopping cart items
- `favorites` - User favorites
- `orders` - Order records
- `order_items` - Order line items

## Security Notes

1. **Change JWT_SECRET** in `config.php` to a strong, random string in production
2. **Use HTTPS** in production
3. **Implement rate limiting** for production use
4. **Delete setup_database.php** after initial setup
5. **Keep database credentials secure**

## Error Responses

The API returns standard HTTP status codes:

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

Error responses include a JSON object with an `error` field:

```json
{
  "error": "Error message here"
}
```

