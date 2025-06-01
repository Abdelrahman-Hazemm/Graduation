# Replace YOUR_SERVER_KEY with your Firebase Server Key
# Replace YOUR_DEVICE_TOKEN with the token from Firestore app_users collection

$serverKey = "YOUR_SERVER_KEY"
$deviceToken = "YOUR_DEVICE_TOKEN"

$headers = @{
    "Authorization" = "key=$serverKey"
    "Content-Type" = "application/json"
}

$body = @{
    to = $deviceToken
    notification = @{
        title = "Test Notification"
        body = "Hello from PowerShell!"
        sound = "default"
    }
} | ConvertTo-Json -Depth 3

try {
    $response = Invoke-RestMethod -Uri "https://fcm.googleapis.com/fcm/send" -Method POST -Headers $headers -Body $body
    Write-Output "Notification sent successfully!"
    Write-Output $response
} catch {
    Write-Error "Failed to send notification: $_"
}
