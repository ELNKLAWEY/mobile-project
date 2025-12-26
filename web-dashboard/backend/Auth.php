<?php
require_once 'Database.php';
require_once 'JWT.php';

class Auth {
    private $db;
    private $logsDir;

    public function __construct() {
        $this->db = Database::getInstance();
        $this->logsDir = __DIR__ . '/logs';
        // Create logs directory if it doesn't exist
        if (!file_exists($this->logsDir)) {
            mkdir($this->logsDir, 0755, true);
        }
    }

    /**
     * Simple logging function for debugging
     */
    private function logToFile($message) {
        $logFile = $this->logsDir . '/auth_' . date('Y-m-d') . '.log';
        $logLine = date('Y-m-d H:i:s') . ' - ' . $message . "\n";
        @file_put_contents($logFile, $logLine, FILE_APPEND);
    }

    public function register($name, $email, $password, $phone = null, $address = null) {
        // Check if email already exists
        $existing = $this->db->fetchOne(
            "SELECT id FROM users WHERE email = ?",
            [$email]
        );

        if ($existing) {
            http_response_code(400);
            return ['error' => 'Email already exists'];
        }

        // Hash password
        $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

        // Insert user and get ID
        $this->db->query(
            "INSERT INTO users (name, email, password, phone, address, role, created_at) VALUES (?, ?, ?, ?, ?, 'USER', NOW())",
            [$name, $email, $hashedPassword, $phone, $address]
        );
        
        $userId = $this->db->lastInsertId();
        $user = $this->db->fetchOne("SELECT id, name, email, phone, address, role, created_at FROM users WHERE id = ?", [$userId]);

        $token = JWT::encode(['user_id' => $userId, 'role' => 'USER']);

        return [
            'user' => $user,
            'access_token' => $token
        ];
    }

    public function login($email, $password, $requireAdmin = false) {
        $user = $this->db->fetchOne(
            "SELECT id, name, email, phone, address, password, role, created_at FROM users WHERE email = ?",
            [$email]
        );

        if (!$user || !password_verify($password, $user['password'])) {
            http_response_code(401);
            return ['error' => 'Invalid credentials'];
        }

        if ($requireAdmin && $user['role'] !== 'ADMIN') {
            http_response_code(403);
            return ['error' => 'Admin access required'];
        }

        unset($user['password']);
        $token = JWT::encode(['user_id' => $user['id'], 'role' => $user['role']]);

        $responseKey = $requireAdmin ? 'admin_user' : 'user';
        return [
            $responseKey => $user,
            'access_token' => $token
        ];
    }

    public function getCurrentUser($token) {
        $payload = JWT::decode($token);
        
        if (!$payload || !isset($payload['user_id'])) {
            return null;
        }

        $user = $this->db->fetchOne(
            "SELECT id, name, email, phone, address, role, created_at FROM users WHERE id = ?",
            [$payload['user_id']]
        );

        return $user;
    }

    public function refreshToken($token) {
        $payload = JWT::decode($token);
        
        if (!$payload || !isset($payload['user_id'])) {
            http_response_code(401);
            return ['error' => 'Invalid token'];
        }

        $newToken = JWT::encode(['user_id' => $payload['user_id'], 'role' => $payload['role']]);
        
        return ['access_token' => $newToken];
    }

    public function requestPasswordReset($email) {
        require_once __DIR__ . '/SMSService.php';
        
        // Check if user exists
        $user = $this->db->fetchOne(
            "SELECT id, email, phone FROM users WHERE email = ?",
            [$email]
        );

        if (!$user) {
            // Don't reveal if email exists for security
            return ['message' => 'If the email exists, an OTP will be sent'];
        }

        if (empty($user['phone'])) {
            http_response_code(400);
            return ['error' => 'Phone number not found. Please contact support.'];
        }

        // Generate OTP
        $smsService = new SMSService();
        $otp = $smsService->generateOTP();
        
        // Set expiration (10 minutes)
        $expiresAt = date('Y-m-d H:i:s', time() + 600);

        // Save OTP to database
        $this->db->query(
            "INSERT INTO password_reset_otps (email, otp, expires_at) VALUES (?, ?, ?)",
            [$email, $otp, $expiresAt]
        );

        // Send OTP via SMS
        $phoneNumber = $user['phone'];
        // Remove any non-numeric characters except leading +
        $phoneNumber = preg_replace('/[^0-9+]/', '', $phoneNumber);
        // If starts with 0, replace with country code (assuming Egypt +20)
        $phoneNumber = '2'.$user['phone'];


        // Remove + if present
        $phoneNumber = str_replace('+', '', $phoneNumber);

        $smsResult = $smsService->sendOTP($phoneNumber, $otp);

        if (!$smsResult['success']) {
            // Still return success to user, but log the error
            error_log('SMS sending failed: ' . $smsResult['message']);
        }

        return ['message' => 'If the email exists, an OTP will be sent to your phone'];
    }

    public function verifyOTPAndResetPassword($email, $otp, $newPassword) {
        // Find valid OTP
        $otpRecord = $this->db->fetchOne(
            "SELECT * FROM password_reset_otps 
             WHERE email = ? AND otp = ? AND used = FALSE AND expires_at > NOW() 
             ORDER BY created_at DESC LIMIT 1",
            [$email, $otp]
        );

        if (!$otpRecord) {
            http_response_code(400);
            return ['error' => 'Invalid or expired OTP'];
        }

        // Hash new password
        $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);

        // Update password
        $this->db->query(
            "UPDATE users SET password = ? WHERE email = ?",
            [$hashedPassword, $email]
        );

        // Mark OTP as used
        $this->db->query(
            "UPDATE password_reset_otps SET used = TRUE WHERE id = ?",
            [$otpRecord['id']]
        );

        return ['message' => 'Password reset successfully'];
    }

    /**
     * Check phone number and send OTP for password reset
     */
    public function checkPhoneAndSendOTP($phone) {
        require_once __DIR__ . '/SMSService.php';
        
        // Validate phone number format (numbers only, at least 10 digits)
        $phone = preg_replace('/[^0-9]/', '', $phone);
        if (strlen($phone) < 10) {
            http_response_code(400);
            return [
                'success' => false,
                'message' => 'Invalid phone number format'
            ];
        }

        // Check if user exists with this phone number
        $user = $this->db->fetchOne(
            "SELECT id, email, phone FROM users WHERE phone = ?",
            [$phone]
        );

        if (!$user) {
            http_response_code(404);
            return [
                'success' => false,
                'message' => 'Phone number is not registered'
            ];
        }

        // Generate OTP
        $smsService = new SMSService();
        $otp = $smsService->generateOTP();
        
        // Set expiration (10 minutes)
        $expiresAt = date('Y-m-d H:i:s', time() + 600);

        // Save OTP to database (using both email and phone for compatibility)
        // First try to insert with phone column if it exists, otherwise use email
        try {
            $this->db->query(
                "INSERT INTO password_reset_otps (email, phone, otp, expires_at) VALUES (?, ?, ?, ?)",
                [$user['email'], $phone, $otp, $expiresAt]
            );
        } catch (Exception $e) {
            // If phone column doesn't exist, use email only
            $this->db->query(
                "INSERT INTO password_reset_otps (email, otp, expires_at) VALUES (?, ?, ?)",
                [$user['email'], $otp, $expiresAt]
            );
        }

        // Format phone number for SMS (add country code if starts with 0)
        $phoneNumber = $phone;
        if (substr($phoneNumber, 0, 1) === '0') {
            $phoneNumber = '20' . substr($phoneNumber, 1); // Egypt country code
        }

        // Log before sending SMS
        $this->logToFile('Before sending SMS - Phone: ' . $phoneNumber . ', OTP: ' . $otp);

        // Send OTP via SMS
        try {
            $smsResult = $smsService->sendOTP($phoneNumber, $otp);
            $this->logToFile('SMS Result: ' . json_encode($smsResult));
        } catch (Exception $e) {
            $this->logToFile('Exception in sendOTP: ' . $e->getMessage());
            $smsResult = [
                'success' => false,
                'message' => 'SMS service error: ' . $e->getMessage()
            ];
        }

        if (!$smsResult['success']) {
            $this->logToFile('SMS sending failed for phone: ' . $phoneNumber . ' - Error: ' . $smsResult['message']);
            error_log('SMS sending failed for phone: ' . $phoneNumber . ' - Error: ' . $smsResult['message']);
            // Still return success to user for security (to prevent phone number enumeration)
        }

        return [
            'success' => true,
            'message' => 'OTP sent successfully'
        ];
    }

    /**
     * Verify OTP and return reset token
     */
    public function verifyOTPAndGetResetToken($phone, $otp) {
        // Find valid OTP - try with phone column first, fallback to email
        $otpRecord = null;
        try {
            $otpRecord = $this->db->fetchOne(
                "SELECT * FROM password_reset_otps 
                 WHERE phone = ? AND otp = ? AND used = FALSE AND expires_at > NOW() 
                 ORDER BY created_at DESC LIMIT 1",
                [$phone, $otp]
            );
        } catch (Exception $e) {
            // If phone column doesn't exist, get user email first then query by email
            $user = $this->db->fetchOne("SELECT email FROM users WHERE phone = ?", [$phone]);
            if ($user) {
                $otpRecord = $this->db->fetchOne(
                    "SELECT * FROM password_reset_otps 
                     WHERE email = ? AND otp = ? AND used = FALSE AND expires_at > NOW() 
                     ORDER BY created_at DESC LIMIT 1",
                    [$user['email'], $otp]
                );
            }
        }

        if (!$otpRecord) {
            http_response_code(400);
            return [
                'success' => false,
                'message' => 'Invalid or expired OTP'
            ];
        }

        // Get user info
        $user = $this->db->fetchOne(
            "SELECT id FROM users WHERE phone = ?",
            [$phone]
        );

        if (!$user) {
            http_response_code(404);
            return [
                'success' => false,
                'message' => 'User not found'
            ];
        }

        // Mark OTP as used
        $this->db->query(
            "UPDATE password_reset_otps SET used = TRUE WHERE id = ?",
            [$otpRecord['id']]
        );

        // Generate reset token (JWT valid for 30 minutes)
        $payload = [
            'user_id' => $user['id'],
            'phone' => $phone,
            'type' => 'password_reset'
        ];
        $resetToken = JWT::encode($payload, 1800); // 30 minutes

        return [
            'success' => true,
            'message' => 'OTP verified successfully',
            'reset_token' => $resetToken
        ];
    }

    /**
     * Reset password using reset token
     */
    public function resetPasswordWithToken($phone, $newPassword, $passwordConfirmation, $resetToken) {
        // Decode and verify reset token
        $payload = JWT::decode($resetToken);
        
        if (!$payload) {
            http_response_code(401);
            return [
                'success' => false,
                'message' => 'Invalid or expired reset token'
            ];
        }
        
        // Verify token type and phone
        if (!isset($payload['user_id']) || 
            !isset($payload['phone']) || 
            !isset($payload['type']) ||
            $payload['type'] !== 'password_reset' ||
            $payload['phone'] !== $phone) {
            http_response_code(401);
            return [
                'success' => false,
                'message' => 'Invalid or expired reset token'
            ];
        }

        // Validate password confirmation
        if ($newPassword !== $passwordConfirmation) {
            http_response_code(400);
            return [
                'success' => false,
                'message' => 'Validation failed',
                'errors' => [
                    'password' => ['Password confirmation does not match']
                ]
            ];
        }

        // Validate password length (minimum 8 characters)
        if (strlen($newPassword) < 8) {
            http_response_code(400);
            return [
                'success' => false,
                'message' => 'Validation failed',
                'errors' => [
                    'password' => ['Password must be at least 8 characters']
                ]
            ];
        }

        // Hash new password
        $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);

        // Update password
        $this->db->query(
            "UPDATE users SET password = ? WHERE phone = ? AND id = ?",
            [$hashedPassword, $phone, $payload['user_id']]
        );

        return [
            'success' => true,
            'message' => 'Password reset successfully'
        ];
    }
}
?>

