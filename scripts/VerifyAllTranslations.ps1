# PowerShell script to verify translation consistency for all supported languages
# This script will check all supported language translations for inconsistencies

param(
    [string[]]$LanguagesToCheck = @()
)

# Define all supported language codes
$WorkspacePath = Split-Path -Parent $PSScriptRoot

# Try to detect all supported languages by scanning existing files
$MainMenuTextsPath = Join-Path $WorkspacePath "src\Areas\MainMenu\Texts"
$AllSupportedLanguages = @()

if (Test-Path $MainMenuTextsPath) {
    # Find all MainMenuTexts files with language codes
    $mainMenuFiles = Get-ChildItem -Path $MainMenuTextsPath -Name "MainMenuTexts.*.resx"
    
    foreach ($file in $mainMenuFiles) {
        # Extract language code from filename (e.g., MainMenuTexts.de.resx -> de)
        if ($file -match "MainMenuTexts\.([a-z]{2})\.resx") {
            $languageCode = $matches[1]
            if ($languageCode -notin $AllSupportedLanguages) {
                $AllSupportedLanguages += $languageCode
            }
        }
    }
    
    # Sort the languages for consistent output
    $AllSupportedLanguages = $AllSupportedLanguages | Sort-Object
}


Write-Host "HardChip Localization - Verify All Translations" -ForegroundColor Magenta
Write-Host "=================================================" -ForegroundColor Magenta

if ($LanguagesToCheck.Count -eq 0) {
    $LanguagesToCheck = $AllSupportedLanguages
    Write-Host "Checking all supported languages: $($LanguagesToCheck -join ', ')" -ForegroundColor Cyan
} else {
    # Validate provided language codes
    $invalidLanguages = $LanguagesToCheck | Where-Object { $_ -notin $AllSupportedLanguages }
    if ($invalidLanguages.Count -gt 0) {
        Write-Host "Error: Invalid language codes: $($invalidLanguages -join ', ')" -ForegroundColor Red
        Write-Host "Supported languages: $($AllSupportedLanguages -join ', ')" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "Checking specified languages: $($LanguagesToCheck -join ', ')" -ForegroundColor Cyan
}

Write-Host "Workspace: $WorkspacePath" -ForegroundColor Gray
Write-Host ""

# Check if VerifyTranslations.ps1 exists
$verifyScriptPath = Join-Path $PSScriptRoot "VerifyTranslations.ps1"
if (-not (Test-Path $verifyScriptPath)) {
    Write-Host "Error: VerifyTranslations.ps1 not found at $verifyScriptPath" -ForegroundColor Red
    exit 1
}

$timestampStart = Get-Date
Write-Host "Starting verification at $($timestampStart.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host ""

# Process each language
foreach ($language in $LanguagesToCheck) {
    Write-Host "==================== $($language.ToUpper()) ====================" -ForegroundColor Yellow
    
    try {
        # Capture output from VerifyTranslations.ps1
        $output = & $verifyScriptPath -LanguageCode $language -WorkspacePath $WorkspacePath 2>&1
        $output | ForEach-Object { Write-Host $_ }
        
    }
    catch {
        Write-Host "Error processing language '$language': $($_.Exception.Message)" -ForegroundColor Red
        $overallSummary.LanguageResults[$language] = @{
            'Language' = $language
            'HasErrors' = $true
            'Error' = $_.Exception.Message
        }
        $overallSummary.LanguagesWithIssues++
    }
    
    Write-Host ""
}

$timestampEnd = Get-Date
$duration = $timestampEnd - $timestampStart

Write-Host ""
Write-Host "Verification completed at $($timestampEnd.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "Duration: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray

# Exit with appropriate code
exit 0