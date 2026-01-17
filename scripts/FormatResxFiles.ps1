# PowerShell script to format all .resx files in the workspace
# This script will format XML indentation, preserve UTF-8 encoding, and remove comments

Write-Host "Starting to format all .resx files in the workspace..." -ForegroundColor Green

# Get all .resx files in the workspace recursively
$resxFiles = Get-ChildItem -Path "." -Filter "*.resx" -Recurse

if ($resxFiles.Count -eq 0) {
    Write-Host "No .resx files found in the workspace." -ForegroundColor Yellow
    exit
}

Write-Host "Found $($resxFiles.Count) .resx files to format." -ForegroundColor Cyan

$successCount = 0
$errorCount = 0

foreach ($file in $resxFiles) {
    try {
        Write-Host "Formatting: $($file.FullName)" -ForegroundColor White
        
        # Load XML content
        [xml]$xml = Get-Content $file.FullName -Encoding UTF8
        
        # Remove all comment nodes
        $commentNodes = $xml.SelectNodes("//comment()")
        foreach ($comment in $commentNodes) {
            $comment.ParentNode.RemoveChild($comment) | Out-Null
        }
        
        # Create XmlWriterSettings for proper formatting
        $writerSettings = New-Object System.Xml.XmlWriterSettings
        $writerSettings.Indent = $true
        $writerSettings.IndentChars = "  "  # 2 spaces for indentation
        $writerSettings.NewLineChars = "`r`n"  # Windows line endings
        $writerSettings.Encoding = [System.Text.UTF8Encoding]::new($false)  # UTF-8 without BOM
        $writerSettings.OmitXmlDeclaration = $false
        
        # Write formatted XML back to file
        $writer = [System.Xml.XmlWriter]::Create($file.FullName, $writerSettings)
        $xml.Save($writer)
        $writer.Close()
        
        Write-Host "  Successfully formatted and comments removed" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host "  Error formatting file: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""
Write-Host "Formatting complete!" -ForegroundColor Green
Write-Host "Successfully formatted: $successCount files" -ForegroundColor Green
if ($errorCount -gt 0) {
    Write-Host "Failed to format: $errorCount files" -ForegroundColor Red
}
