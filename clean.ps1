$dir = "c:\Users\bhoop\Downloads\website clothing"

# 1. Rename files
$cssDir = "$dir\cdn.prod.website-files.com\69a3b779dc496975c0b73f42\css"
if (Test-Path $cssDir) {
    Get-ChildItem -Path $cssDir -Filter "*webflow*.css" | Rename-Item -NewName { $_.Name -replace 'haus-portfolio-template.webflow.shared.9bbb44e70.css','haus-portfolio.css' }
}

$jsDir = "$dir\cdn.prod.website-files.com\69a3b779dc496975c0b73f42\js"
if (Test-Path $jsDir) {
    Get-ChildItem -Path $jsDir -Filter "webflow*.js" | Rename-Item -NewName { $_.Name -replace 'webflow','script' }
}

# 2. Text replacements
$files = Get-ChildItem -Path $dir -Include *.html, *.css, *.js -Recurse -File
foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    $modified = $false
    
    if ($content -match 'haus-portfolio-template\.webflow\.io') {
        $content = $content -replace 'haus-portfolio-template\.webflow\.io', 'haus-portfolio'
        $modified = $true
    }
    if ($content -match '<!-- This site was created in Webflow\. https://webflow\.com -->') {
        $content = $content -replace '<!-- This site was created in Webflow\. https://webflow\.com -->', ''
        $modified = $true
    }
    if ($content -match '<meta content="Webflow" name="generator"/>') {
        $content = $content -replace '<meta content="Webflow" name="generator"/>', ''
        $modified = $true
    }
    if ($content -match 'haus-portfolio-template\.webflow\.shared\.9bbb44e70\.css') {
        $content = $content -replace 'haus-portfolio-template\.webflow\.shared\.9bbb44e70\.css', 'haus-portfolio.css'
        $modified = $true
    }
    if ($content -match '/js/webflow\.') {
        $content = $content -replace '/js/webflow\.', '/js/script.'
        $modified = $true
    }
    
    if ($modified) {
        [System.IO.File]::WriteAllText($file.FullName, $content)
    }
}

# 3. Rename root folder
$webflowDir = "$dir\haus-portfolio-template.webflow.io"
if (Test-Path $webflowDir) {
    Rename-Item -Path $webflowDir -NewName "haus-portfolio"
}

# 4. Remove unneeded webflow.com folder
$webflowCom = "$dir\webflow.com"
if (Test-Path $webflowCom) {
    Remove-Item -Path $webflowCom -Recurse -Force
}

Write-Host "Cleanup complete."
