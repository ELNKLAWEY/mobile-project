<?php
require_once __DIR__ . '/../Auth.php';
require_once __DIR__ . '/../Middleware.php';

class AuthController {
    private $auth;
    private $middleware;

    public function __construct() {
        $this->auth = new Auth();
        $this->middleware = new Middleware();
    }

    public function register($params) {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['name']) || !isset($data['email']) || !isset($data['password'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields: name, email, password']);
            return;
        }

        $phone = $data['phone'] ?? null;
        $address = $data['address'] ?? null;

        $result = $this->auth->register($data['name'], $data['email'], $data['password'], $phone, $address);
        
        if (isset($result['error'])) {
            echo json_encode($result);
            return;
        }

        http_response_code(201);
        echo json_encode($result);
    }

    public function login($params) {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['email']) || !isset($data['password'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields: email, password']);
            return;
        }

        $result = $this->auth->login($data['email'], $data['password']);
        echo json_encode($result);
    }

    public function adminLogin($params) {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['email']) || !isset($data['password'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields: email, password']);
            return;
        }

        $result = $this->auth->login($data['email'], $data['password'], true);
        echo json_encode($result);
    }

    public function logout($params) {
        // JWT is stateless, so logout is handled client-side by removing the token
        echo json_encode(['message' => 'Logged out successfully']);
    }

    public function me($params) {
        $user = $this->middleware->requireAuth();
        echo json_encode(['user' => $user]);
    }

    public function refresh($params) {
        $token = $this->middleware->getTokenFromHeader();
        
        if (!$token) {
            http_response_code(401);
            echo json_encode(['error' => 'Token required']);
            return;
        }

        $result = $this->auth->refreshToken($token);
        echo json_encode($result);
    }

    public function requestPasswordReset($params) {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['email'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Email is required']);
            return;
        }

        $result = $this->auth->requestPasswordReset($data['email']);
        echo json_encode($result);
    }

    public function resetPassword($params) {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['email']) || !isset($data['otp']) || !isset($data['new_password'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields: email, otp, new_password']);
            return;
        }

        $result = $this->auth->verifyOTPAndResetPassword($data['email'], $data['otp'], $data['new_password']);
        
        if (isset($result['error'])) {
            echo json_encode($result);
            return;
        }

        echo json_encode($result);
    }

    /**
     * Check phone number and send OTP
     */
    public function checkPhoneAndSendOTP($params) {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['phone'])) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Phone number is required'
            ]);
            return;
        }

        $result = $this->auth->checkPhoneAndSendOTP($data['phone']);
        echo json_encode($result);
    }

    /**
     * Verify OTP and get reset token
     */
    public function verifyOTP($params) {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['phone']) || !isset($data['otp'])) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Phone number and OTP are required'
            ]);
            return;
        }

        $result = $this->auth->verifyOTPAndGetResetToken($data['phone'], $data['otp']);
        echo json_encode($result);
    }

    /**
     * Reset password with reset token
     */
    public function resetPasswordWithToken($params) {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['phone']) || !isset($data['password']) || !isset($data['password_confirmation'])) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Phone number, password and password_confirmation are required'
            ]);
            return;
        }

        // Get reset token from Authorization header
        $resetToken = $this->middleware->getTokenFromHeader();
        
        if (!$resetToken) {
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'message' => 'Reset token is required'
            ]);
            return;
        }

        $result = $this->auth->resetPasswordWithToken(
            $data['phone'],
            $data['password'],
            $data['password_confirmation'],
            $resetToken
        );
        
        echo json_encode($result);
    }
}
?>



