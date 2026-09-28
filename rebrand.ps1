$dir = "c:\Users\bhoop\Downloads\website clothing"

$files = Get-ChildItem -Path $dir -Include *.html, *.css, *.js -Recurse -File
foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    $original = $content
    
    # Branding replacements
    $content = $content -replace 'Haus Studio', 'Kch. Studio'
    # Match Haus but not if it's part of another word
    $content = $content -replace '\bHaus\b', 'Kch.'
    $content = $content -replace '\bHAUS\b', 'KCH.'
    $content = $content -replace 'haus-portfolio', 'kch-portfolio'
    
    if ($content -ne $original) {
        [System.IO.File]::WriteAllText($file.FullName, $content)
    }
}

# Rename folders and files
$oldDir = "$dir\haus-portfolio"
if (Test-Path $oldDir) {
    Rename-Item -Path $oldDir -NewName "kch-portfolio"
}

$cssDir = "$dir\cdn.prod.website-files.com\69a3b779dc496975c0b73f42\css"
$oldCss = "$cssDir\haus-portfolio.css"
if (Test-Path $oldCss) {
    Rename-Item -Path $oldCss -NewName "kch-portfolio.css"
}

Write-Host "Branding updated successfully."
