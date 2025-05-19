<?php
// Ensure logs directory exists
$logDir = "logs";
if (!is_dir($logDir)) {
    mkdir($logDir, 0777, true);
}

// Retrieve incoming data
$inputData = json_decode(file_get_contents("php://input"), true);

if (isset($inputData['image'])) {
    $imageData = $inputData['image'];

    // Sanitize base64 string
    $imageData = str_replace('data:image/png;base64,', '', $imageData);
    $imageData = str_replace(' ', '+', $imageData);
    $decodedData = base64_decode($imageData);

    // Create a unique filename
    $fileName = $logDir . "/capture_" . date("Y-m-d_H-i-s") . ".png";

    // Save the image
    if (file_put_contents($fileName, $decodedData)) {
        echo json_encode(["status" => "success", "message" => "Image captured successfully"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Failed to save image"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "No image data found"]);
}
?>