# PowerShell script to extract .so files from mobilertc.aar
# This script helps extract native libraries from the Zoom Video SDK AAR file

Write-Host "Extracting .so files from mobilertc.aar..." -ForegroundColor Green

# Create extraction directory
$extractDir = "temp_extract"
if (Test-Path $extractDir) {
    Remove-Item $extractDir -Recurse -Force
}
New-Item -ItemType Directory -Path $extractDir | Out-Null

# Extract AAR file (AAR is essentially a ZIP file)
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory("mobilertc.aar", $extractDir)
    Write-Host "Successfully extracted AAR file" -ForegroundColor Green
} catch {
    Write-Host "Failed to extract AAR file: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Look for .so files in the extracted content
$soFiles = Get-ChildItem -Path $extractDir -Recurse -Filter "*.so"
Write-Host "Found $($soFiles.Count) .so files:" -ForegroundColor Yellow

foreach ($file in $soFiles) {
    Write-Host "  - $($file.Name)" -ForegroundColor Cyan
}

# Create jniLibs directory structure if it doesn't exist
$jniLibsPath = "../../src/main/jniLibs"
if (-not (Test-Path $jniLibsPath)) {
    New-Item -ItemType Directory -Path $jniLibsPath | Out-Null
}

# Create ABI directories
$abiDirs = @("arm64-v8a", "armeabi-v7a", "x86", "x86_64")
foreach ($abi in $abiDirs) {
    $abiPath = "$jniLibsPath/$abi"
    if (-not (Test-Path $abiPath)) {
        New-Item -ItemType Directory -Path $abiPath | Out-Null
    }
}

Write-Host "Created jniLibs directory structure" -ForegroundColor Green

# Copy .so files to appropriate ABI directories
# Note: You may need to manually copy the correct .so files to the right ABI folders
# based on the actual structure of your Zoom Video SDK

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Check the extracted files in the '$extractDir' directory" -ForegroundColor White
Write-Host "2. Copy the appropriate .so files to the jniLibs/abi directories" -ForegroundColor White
Write-Host "3. Clean up the extraction directory when done" -ForegroundColor White

Write-Host "`nExtraction complete!" -ForegroundColor Green 