# PowerShell script to verify translation consistency for any language
# This script will check all .{LanguageCode}.resx files for translation inconsistencies

param(
    [Parameter(Mandatory=$true)]
    [string]$LanguageCode,
    [string]$WorkspacePath = "c:\Repos\hardchip-localization"
)

# Validate language code format (2-5 characters, letters and hyphens only)
if ($LanguageCode -notmatch '^[a-zA-Z]{2}(-[a-zA-Z]{2,4})?$') {
    Write-Host "Error: Invalid language code format. Examples: 'it', 'de', 'es', 'fr', 'ru', 'zh-Hans'" -ForegroundColor Red
    exit 1
}

Write-Host "Starting $LanguageCode translation verification..." -ForegroundColor Green

# Get all English .resx files (reference files)
$englishFiles = Get-ChildItem -Path $WorkspacePath -Filter "*.resx" -Recurse | Where-Object { $_.Name -notmatch '\.[a-zA-Z]{2}(-[a-zA-Z]{2,4})?\.resx$' }

if ($englishFiles.Count -eq 0) {
    Write-Host "No English .resx files found in $WorkspacePath." -ForegroundColor Yellow
    exit
}

Write-Host "Found $($englishFiles.Count) English reference files:" -ForegroundColor Cyan
$englishFiles | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }

# Get all language-specific .resx files
$languageFiles = Get-ChildItem -Path $WorkspacePath -Filter "*.$LanguageCode.resx" -Recurse

Write-Host "`nFound $($languageFiles.Count) $LanguageCode translation files to verify." -ForegroundColor Cyan
if ($languageFiles.Count -gt 0) {
    $languageFiles | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
}

$issues = @()
$totalEntries = 0
$translatedEntries = 0

# Function to extract data entries from resx file
function Get-ResxEntries {
    param([string]$filePath)
    
    try {
        [xml]$xml = Get-Content $filePath -Encoding UTF8
        $entries = @{}
        
        foreach ($data in $xml.root.data) {
            if ($data.name -and $data.value) {
                $entries[$data.name] = @{
                    'value' = $data.value
                    'comment' = $data.comment
                }
            }
        }
        return $entries
    }
    catch {
        Write-Warning "Failed to parse $filePath`: $($_.Exception.Message)"
        return @{}
    }
}

# Function to get corresponding English file
function Get-EnglishFile {
    param([string]$languageFilePath)
    return $languageFilePath -replace "\.$LanguageCode\.resx$", '.resx'
}

# Function to get corresponding language file for an English file
function Get-LanguageFile {
    param([string]$englishFilePath)
    return $englishFilePath -replace '\.resx$', ".$LanguageCode.resx"
}

Write-Host "`nChecking for missing language files..." -ForegroundColor White

# Check if each English file has a corresponding language file
$missingLanguageFiles = @()
foreach ($englishFile in $englishFiles) {
    $expectedLanguageFile = Get-LanguageFile -englishFilePath $englishFile.FullName
    if (-not (Test-Path $expectedLanguageFile)) {
        $expectedFileName = Split-Path $expectedLanguageFile -Leaf
        $missingLanguageFiles += $expectedFileName
        $issues += "Missing $LanguageCode translation file: $expectedFileName (for $($englishFile.Name))"
    }
}

if ($missingLanguageFiles.Count -gt 0) {
    Write-Host "Missing $($missingLanguageFiles.Count) $LanguageCode translation files:" -ForegroundColor Yellow
    $missingLanguageFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
} else {
    Write-Host "All English files have corresponding $LanguageCode translation files." -ForegroundColor Green
}

Write-Host "`nAnalyzing translation files..." -ForegroundColor White

# Only analyze existing language files
if ($languageFiles.Count -eq 0) {
    Write-Host "No $LanguageCode translation files to analyze." -ForegroundColor Yellow
} else {
    foreach ($langFile in $languageFiles) {
    Write-Host "Checking: $($langFile.Name)" -ForegroundColor Cyan
    
    $languageEntries = Get-ResxEntries -filePath $langFile.FullName
    $englishFile = Get-EnglishFile -languageFilePath $langFile.FullName
    
    if (-not (Test-Path $englishFile)) {
        $issues += "Missing English base file for $($langFile.Name)"
        continue
    }
    
    $englishEntries = Get-ResxEntries -filePath $englishFile
    
    # Check for missing translations
    foreach ($englishKey in $englishEntries.Keys) {
        $totalEntries++
        
        if (-not $languageEntries.ContainsKey($englishKey)) {
            $issues += "Missing key '$englishKey' in $($langFile.Name)"
        }
        elseif ([string]::IsNullOrWhiteSpace($languageEntries[$englishKey].value)) {
            $issues += "Empty translation for key '$englishKey' in $($langFile.Name)"
        }
        elseif ($languageEntries[$englishKey].value -eq $englishEntries[$englishKey].value) {
            # Check if it's likely untranslated (same as English, excluding proper nouns)
            $englishValue = $englishEntries[$englishKey].value
            if ($englishValue -notmatch '^[A-Z][a-z]*$' -and $englishValue -ne "Info" -and $englishValue -ne "HCDrives") {
                $issues += "Possibly untranslated text '$englishValue' for key '$englishKey' in $($langFile.Name)"
            }
            else {
                $translatedEntries++
            }
        }
        else {
            $translatedEntries++
        }
    }
    
    # Check for extra keys in target language that don't exist in English
    foreach ($languageKey in $languageEntries.Keys) {
        if (-not $englishEntries.ContainsKey($languageKey)) {
            $issues += "Extra key '$languageKey' in $($langFile.Name) not found in English version"
        }
        }
    }
}

# Analyze for terminology consistency across files
Write-Host "`nAnalyzing terminology consistency..." -ForegroundColor White

$terminologyMap = @{}
if ($languageFiles.Count -gt 0) {
    foreach ($langFile in $languageFiles) {
        $entries = Get-ResxEntries -filePath $langFile.FullName
        foreach ($key in $entries.Keys) {
            $value = $entries[$key].value
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                if (-not $terminologyMap.ContainsKey($value)) {
                    $terminologyMap[$value] = @()
                }
                $terminologyMap[$value] += "$($langFile.Name):$key"
            }
        }
    }

    # Look for common English words that might have inconsistent translations
    $commonWords = @("Edit", "Delete", "Remove", "Save", "Cancel", "OK", "Yes", "No", "Settings", "Help")
    foreach ($word in $commonWords) {
        $translations = @()
        foreach ($langFile in $languageFiles) {
            $englishFile = Get-EnglishFile -languageFilePath $langFile.FullName
            if (Test-Path $englishFile) {
                $englishEntries = Get-ResxEntries -filePath $englishFile
                $languageEntries = Get-ResxEntries -filePath $langFile.FullName
                
                foreach ($key in $englishEntries.Keys) {
                    if ($englishEntries[$key].value -eq $word -and $languageEntries.ContainsKey($key)) {
                        $translation = $languageEntries[$key].value
                        if (-not [string]::IsNullOrWhiteSpace($translation) -and $translation -ne $word) {
                            $translations += "$translation ($($langFile.Name):$key)"
                        }
                    }
                }
            }
        }
        
        if ($translations.Count -gt 1) {
            $uniqueTranslations = $translations | Sort-Object -Unique
            if ($uniqueTranslations.Count -gt 1) {
                $issues += "Inconsistent translations for '$word': $($uniqueTranslations -join ', ')"
            }
        }
    }
}

# Report results
Write-Host "`n=======================================================" -ForegroundColor Yellow
Write-Host "$($LanguageCode.ToUpper()) TRANSLATION VERIFICATION REPORT" -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Yellow

Write-Host "`nSUMMARY:" -ForegroundColor Green
Write-Host "  English reference files: $($englishFiles.Count)"
Write-Host "  $LanguageCode translation files found: $($languageFiles.Count)"
Write-Host "  Missing $LanguageCode translation files: $($missingLanguageFiles.Count)"
Write-Host "  Total entries: $totalEntries"
Write-Host "  Translated entries: $translatedEntries"
if ($totalEntries -gt 0) {
    Write-Host "  Translation coverage: $([Math]::Round(($translatedEntries / $totalEntries) * 100, 2))%"
} else {
    Write-Host "  Translation coverage: 0%"
}
Write-Host "  Issues found: $($issues.Count)"
Write-Host "  Unique translations: $($terminologyMap.Count)"

if ($issues.Count -gt 0) {
    Write-Host "`nISSUES FOUND:" -ForegroundColor Red
    $issues | Sort-Object | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Red
    }
}
else {
    Write-Host "`nNo issues found! All $LanguageCode translations appear consistent." -ForegroundColor Green
}

Write-Host "`n=======================================================" -ForegroundColor Yellow

# Export detailed report to file
$reportPath = "$WorkspacePath\$($LanguageCode.ToUpper())_Translation_Report.txt"
$reportContent = @"
$($LanguageCode.ToUpper()) TRANSLATION VERIFICATION REPORT
Generated: $(Get-Date)
Language Code: $LanguageCode
Workspace: $WorkspacePath

SUMMARY:
- English reference files: $($englishFiles.Count)
- $LanguageCode translation files found: $($languageFiles.Count)
- Missing $LanguageCode translation files: $($missingLanguageFiles.Count)
- Total entries: $totalEntries
- Translated entries: $translatedEntries  
- Translation coverage: $(if ($totalEntries -gt 0) { [Math]::Round(($translatedEntries / $totalEntries) * 100, 2) } else { 0 })%
- Issues found: $($issues.Count)
- Unique translations: $($terminologyMap.Count)

ENGLISH REFERENCE FILES:
$($englishFiles | ForEach-Object { "- $($_.Name)" } | Out-String)

$LanguageCode TRANSLATION FILES FOUND:
$(if ($languageFiles.Count -gt 0) { 
    ($languageFiles | ForEach-Object { "- $($_.Name)" } | Out-String)
} else { "- No $LanguageCode translation files found" })

$(if ($missingLanguageFiles.Count -gt 0) {
    "MISSING $($LanguageCode.ToUpper()) TRANSLATION FILES:`n$(($missingLanguageFiles | ForEach-Object { "- $_" }) -join "`n")`n"
} else {
    "All English files have corresponding $LanguageCode translation files.`n"
})

TERMINOLOGY ANALYSIS:
Most Frequently Used Translations:
$(if ($frequentTerms.Count -gt 0) { 
    ($frequentTerms | ForEach-Object { "- '$_' (used $($terminologyMap[$_].Count) times in: $($terminologyMap[$_] -join ', '))" }) -join "`n"
} else { "- No frequently repeated terms found" })

Translation Patterns:
- Single-use translations: $(($terminologyMap.Keys | Where-Object { $terminologyMap[$_].Count -eq 1 }).Count)
- Multi-use translations: $(($terminologyMap.Keys | Where-Object { $terminologyMap[$_].Count -gt 1 }).Count)
- Potential abbreviations: $(if ($shortTranslations.Count -gt 0) { $shortTranslations.Count } else { 0 })

"@

if ($issues.Count -gt 0) {
    $reportContent += "`nISSUES FOUND:`n"
    $issues | Sort-Object | ForEach-Object {
        $reportContent += "- $_`n"
    }
}
else {
    $reportContent += "`nNo issues found! All $LanguageCode translations appear consistent.`n"
}

# $reportContent | Out-File -FilePath $reportPath -Encoding UTF8
# Write-Host "Detailed report saved to: $reportPath" -ForegroundColor Cyan