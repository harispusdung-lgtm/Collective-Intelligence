$files = @(
    "contracts\collective-intelligence.clar"
)

foreach ($file in $files) {
    Write-Host "Converting line endings for $file"
    $content = Get-Content -Path $file -Raw
    $content = $content -replace "`r`n", "`n"
    Set-Content -Path $file -Value $content -NoNewline
    Write-Host "Conversion completed"
}

Write-Host "All files processed. Line endings converted from CRLF to LF."