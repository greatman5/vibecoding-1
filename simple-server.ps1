$port = 8080
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")

try {
    $listener.Start()
    Write-Host "=================================================="
    Write-Host "🚀 Local 3D Web Server Started!"
    Write-Host "👉 Open: http://localhost:$port/"
    Write-Host "👉 Or Summer Collection: http://localhost:$port/summer-collection.html"
    Write-Host "=================================================="
    Write-Host "Press Ctrl+C in this terminal to stop the server.`n"

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $urlPath = $request.Url.LocalPath
        # Prevent path traversal security issue
        $urlPath = $urlPath.Replace("..", "")
        if ($urlPath -eq "/") { $urlPath = "/index.html" }
        
        # Build absolute file path
        $localPath = Join-Path (Get-Location) $urlPath
        
        if (Test-Path $localPath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($localPath).ToLower()
            $contentType = "application/octet-stream"
            switch ($ext) {
                ".html" { $contentType = "text/html; charset=utf-8" }
                ".css" { $contentType = "text/css" }
                ".js" { $contentType = "application/javascript" }
                ".glb" { $contentType = "model/gltf-binary" }
                ".gltf" { $contentType = "model/gltf+json" }
                ".png" { $contentType = "image/png" }
                ".jpg" { $contentType = "image/jpeg" }
                ".jpeg" { $contentType = "image/jpeg" }
                ".svg" { $contentType = "image/svg+xml" }
                ".ico" { $contentType = "image/x-icon" }
            }
            
            $response.ContentType = $contentType
            # Add CORS headers just in case
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            
            # Read files as bytes to correctly server binary GLB and images
            $bytes = [System.IO.File]::ReadAllBytes($localPath)
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $response.ContentType = "text/plain; charset=utf-8"
            $bytes = [System.Text.Encoding]::UTF8.GetBytes("404 File Not Found - 파일이 존재하지 않습니다.")
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        }
        $response.OutputStream.Close()
    }
} catch {
    Write-Error $_
} finally {
    $listener.Stop()
}
