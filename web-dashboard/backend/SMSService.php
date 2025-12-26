<?php
/**
 * SMS Service for sending OTP via WhySMS API
 */

class SMSService {
    private $apiUrl = 'https://bulk.whysms.com/api/v3/sms/send';
    private $apiToken = '358|Xsl0S4eocFjxnFiHso5JZuSi1ePpXeMXOL7YasWi5fcb9034';
    private $senderId = 'StudyOnline';
    private $logsDir = __DIR__ . '/logs';

    public function __construct() {
        // Create logs directory if it doesn't exist
        if (!file_exists($this->logsDir)) {
            if (!mkdir($this->logsDir, 0755, true)) {
                error_log('Failed to create logs directory: ' . $this->logsDir);
            }
        }
    }

    /**
     * Log SMS request and response
     */
    private function logSMS($phoneNumber, $otp, $data, $response, $httpCode, $error, $success) {
        $logEntry = [
            'timestamp' => date('Y-m-d H:i:s'),
            'phone_number' => $phoneNumber,
            'otp' => $otp,
            'api_url' => $this->apiUrl,
            'request_data' => [
                'recipient' => $data['recipient'],
                'sender_id' => $data['sender_id'],
                'type' => $data['type'],
                'message' => $data['message']
            ],
            'response' => [
                'http_code' => $httpCode,
                'body' => $response ? json_decode($response, true) : null,
                'raw_response' => $response
            ],
            'curl_error' => $error ?: null,
            'success' => $success
        ];

        $logFile = $this->logsDir . '/sms_'. $phoneNumber .'.log';
        $logLine = json_encode($logEntry, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT) . "\n" . str_repeat('=', 80) . "\n\n";
        
        $result = @file_put_contents($logFile, $logLine, FILE_APPEND);
        if ($result === false) {
            error_log('Failed to write to log file: ' . $logFile);
            error_log('Log entry: ' . $logLine);
        }
    }

    /**
     * Send SMS with OTP
     * @param string $phoneNumber Phone number in international format (e.g., 31612345678)
     * @param string $otp 4-digit OTP code
     * @return array ['success' => bool, 'message' => string]
     */
    public function sendOTP($phoneNumber, $otp) {
        $message = "Your verification code is: $otp";
        
        $data = [
            'recipient' => $phoneNumber,
            'sender_id' => $this->senderId,
            'type' => 'plain',
            'message' => $message
        ];

        $ch = curl_init($this->apiUrl);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $this->apiToken,
            'Content-Type: application/json',
            'Accept: application/json'
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);

        $success = false;
        $result = [];

        if ($error) {
            $result = [
                'success' => false,
                'message' => 'SMS service error: ' . $error
            ];
            $this->logSMS($phoneNumber, $otp, $data, $response, $httpCode, $error, false);
            return $result;
        }

        if ($httpCode >= 200 && $httpCode < 300) {
            $success = true;
            $result = [
                'success' => true,
                'message' => 'OTP sent successfully'
            ];
        } else {
            $responseData = json_decode($response, true);
            $result = [
                'success' => false,
                'message' => 'Failed to send OTP: ' . ($responseData['message'] ?? 'Unknown error')
            ];
        }

        // Log the request and response
        $this->logSMS($phoneNumber, $otp, $data, $response, $httpCode, $error, $success);

        return $result;
    }

    /**
     * Generate a 4-digit OTP
     * @return string
     */
    public function generateOTP() {
        return str_pad(rand(0, 9999), 4, '0', STR_PAD_LEFT);
    }
}
?>

