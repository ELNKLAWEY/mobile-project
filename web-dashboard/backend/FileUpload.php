<?php
class FileUpload {
    private $uploadDir;
    private $allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
    private $maxSize = 5242880; // 5MB

    public function __construct($uploadDir = 'uploads') {
        $this->uploadDir = $uploadDir;
        $this->ensureUploadDir();
    }

    private function ensureUploadDir() {
        if (!file_exists($this->uploadDir)) {
            mkdir($this->uploadDir, 0755, true);
        }
    }

    public function upload($file, $prefix = 'product') {
        if (!isset($file) || $file['error'] !== UPLOAD_ERR_OK) {
            return ['success' => false, 'error' => 'File upload error'];
        }

        // Validate file type
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mimeType = finfo_file($finfo, $file['tmp_name']);
        finfo_close($finfo);

        if (!in_array($mimeType, $this->allowedTypes)) {
            return ['success' => false, 'error' => 'Invalid file type. Allowed types: JPEG, PNG, GIF, WebP'];
        }

        // Validate file size
        if ($file['size'] > $this->maxSize) {
            return ['success' => false, 'error' => 'File size exceeds maximum allowed size (5MB)'];
        }

        // Generate unique filename
        $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
        $filename = $prefix . '_' . uniqid() . '_' . time() . '.' . $extension;
        $filepath = $this->uploadDir . '/' . $filename;

        // Move uploaded file
        if (move_uploaded_file($file['tmp_name'], $filepath)) {
            // Return relative path
            $relativePath = '/' . $this->uploadDir . '/' . $filename;
            return ['success' => true, 'path' => $relativePath];
        }

        return ['success' => false, 'error' => 'Failed to move uploaded file'];
    }

    public function delete($filepath) {
        // Remove leading slash if present
        $filepath = ltrim($filepath, '/');
        
        // Security check - ensure file is in upload directory
        if (strpos($filepath, $this->uploadDir) !== 0) {
            return false;
        }

        if (file_exists($filepath)) {
            return unlink($filepath);
        }
        return false;
    }
}
?>



