param([int]$Port = 3000)

$rootDir = $PSScriptRoot

$mimeTypes = @{
    ".html"  = "text/html; charset=utf-8"
    ".css"   = "text/css"
    ".js"    = "application/javascript"
    ".json"  = "application/json"
    ".png"   = "image/png"
    ".jpg"   = "image/jpeg"
    ".jpeg"  = "image/jpeg"
    ".svg"   = "image/svg+xml"
    ".ico"   = "image/x-icon"
    ".woff"  = "font/woff"
    ".woff2" = "font/woff2"
    ".gif"   = "image/gif"
    ".webp"  = "image/webp"
    ".txt"   = "text/plain"
    ".xml"   = "application/xml"
}

function Get-MimeType($path) {
    $ext = [System.IO.Path]::GetExtension($path).ToLower()
    if ($mimeTypes.ContainsKey($ext)) { return $mimeTypes[$ext] }
    return "application/octet-stream"
}

function Send-Response($stream, $statusCode, $statusText, $contentType, $body) {
    $writer = New-Object System.IO.StreamWriter($stream, [System.Text.Encoding]::UTF8, 4096, $true)
    $writer.WriteLine("HTTP/1.1 $statusCode $statusText")
    $writer.WriteLine("Content-Type: $contentType")
    $writer.WriteLine("Content-Length: $($body.Length)")
    $writer.WriteLine("Connection: close")
    $writer.WriteLine("Access-Control-Allow-Origin: *")
    $writer.WriteLine("")
    $writer.Flush()
    $stream.Write($body, 0, $body.Length)
    $stream.Flush()
    $writer.Dispose()
}

function Handle-Client($client) {
    try {
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII, $false, 4096, $true)
        
        # Read request line
        $requestLine = $reader.ReadLine()
        if ([string]::IsNullOrEmpty($requestLine)) { return }
        
        # Drain headers
        while ($true) {
            $line = $reader.ReadLine()
            if ([string]::IsNullOrEmpty($line)) { break }
        }
        
        # Parse request
        $parts = $requestLine.Split(' ')
        if ($parts.Length -lt 2) { return }
        $method = $parts[0]
        $rawPath = $parts[1]
        
        # Decode URL (handle %20 etc)
        $urlPath = [Uri]::UnescapeDataString($rawPath.Split('?')[0]).TrimStart('/')
        
        if ([string]::IsNullOrEmpty($urlPath) -or $urlPath -eq "/") {
            $urlPath = "kch-portfolio/index.html"
        }
        
        # Security: prevent directory traversal
        $localPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($rootDir, $urlPath.Replace('/', '\')))
        if (-not $localPath.StartsWith($rootDir)) {
            $body = [System.Text.Encoding]::UTF8.GetBytes("403 Forbidden")
            Send-Response $stream 403 "Forbidden" "text/plain" $body
            return
        }
        
        # If directory, try index.html
        if ([System.IO.Directory]::Exists($localPath)) {
            $localPath = [System.IO.Path]::Combine($localPath, "index.html")
        }
        
        if ([System.IO.File]::Exists($localPath)) {
            $bytes = [System.IO.File]::ReadAllBytes($localPath)
            $mime = Get-MimeType $localPath
            Send-Response $stream 200 "OK" $mime $bytes
        } else {
            # Try 404 page
            $notFoundPage = [System.IO.Path]::Combine($rootDir, "kch-portfolio\404.html")
            if ([System.IO.File]::Exists($notFoundPage)) {
                $bytes = [System.IO.File]::ReadAllBytes($notFoundPage)
                Send-Response $stream 404 "Not Found" "text/html; charset=utf-8" $bytes
            } else {
                $body = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $urlPath")
                Send-Response $stream 404 "Not Found" "text/plain" $body
            }
        }
    } catch {
        # Silently ignore client errors
    } finally {
        try { $client.Close() } catch {}
    }
}

# Start TCP listener (no admin required)
$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $Port)
$listener.Start()

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Kch. Studio Website Server" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Running at: http://localhost:$Port/" -ForegroundColor Green
Write-Host "  Open:       http://localhost:$Port/kch-portfolio/index.html" -ForegroundColor Green
Write-Host "  Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        $capturedClient = $client
        $job = [System.Threading.Tasks.Task]::Run([Action]{
            Handle-Client $capturedClient
        })
    }
} finally {
    $listener.Stop()
    Write-Host "Server stopped."
}
