# Translation Verification Script Documentation

## Overview
The `VerifyTranslations.ps1` script is a PowerShell tool designed to verify translation consistency across any language in the hardchip-localization project. It analyzes resource (.resx) files to identify missing translations, inconsistencies, and potential issues.

## Usage

### Basic Syntax
```powershell
.\VerifyTranslations.ps1 -LanguageCode <language-code> [-WorkspacePath <path>]
```

### Parameters

#### Required Parameters
- **LanguageCode**: The language code to verify (e.g., 'it', 'de', 'es', 'fr', 'ru', 'zh-Hans')
  - Must be 2-5 characters containing only letters and hyphens
  - Examples: `it`, `de`, `es`, `fr`, `ru`, `zh-Hans`

#### Optional Parameters
- **WorkspacePath**: Path to the hardchip-localization workspace (default: "c:\Repos\hardchip-localization")

### Examples

#### Verify Italian translations:
```powershell
.\VerifyTranslations.ps1 -LanguageCode "it"
```

#### Verify German translations:
```powershell
.\VerifyTranslations.ps1 -LanguageCode "de"
```

#### Verify Chinese Simplified translations:
```powershell
.\VerifyTranslations.ps1 -LanguageCode "zh-Hans"
```

#### Verify translations with custom workspace path:
```powershell
.\VerifyTranslations.ps1 -LanguageCode "es" -WorkspacePath "D:\Projects\hardchip-localization"
```

## What the Script Checks

### 1. Missing Translations
- Identifies keys that exist in English base files but are missing in target language files
- Reports empty translation values

### 2. Untranslated Text
- Detects entries that appear to be unchanged from English
- Excludes proper nouns and technical terms that should remain unchanged

### 3. File Structure Issues
- Reports missing English base files
- Identifies extra keys in translation files that don't exist in English versions

### 4. Terminology Consistency
- Analyzes common terms across all translation files
- Reports inconsistent translations for the same English term

## Output

### Generated Report File
A detailed report is saved to: `{WorkspacePath}\{LANGUAGECODE}_Translation_Report.txt`

The report includes:
- Complete summary statistics
- List of all analyzed files
- Detailed list of all issues found
- Timestamp and configuration information

### Missing English Base Files
The script will report if English base files are missing for any translation files.

## Script Workflow

1. **Validation**: Validates the provided language code format
2. **Discovery**: Finds all .{languagecode}.resx files in the workspace
3. **Analysis**: For each translation file:
   - Loads the corresponding English base file
   - Compares keys and values
   - Identifies missing, empty, or potentially untranslated entries
4. **Consistency Check**: Analyzes terminology consistency across all files
5. **Reporting**: Generates console output and detailed report file

## Best Practices

### Before Running
- Ensure PowerShell execution policy allows script execution
- Verify the workspace path is correct
- Confirm the target language files exist

### Interpreting Results
- **High Priority**: Missing translations (affect functionality)
- **Medium Priority**: Possibly untranslated text (affects user experience)
- **Low Priority**: Terminology inconsistencies (affects quality)

### Regular Usage
- Run after adding new English text to identify what needs translation
- Run before releases to ensure translation completeness
- Use for quality assurance during translation reviews

## Integration Tips

### Batch Verification
To verify multiple languages at once, create a batch script:
```powershell
$languages = @("it", "de", "es", "fr", "ru", "zh-Hans")
foreach ($lang in $languages) {
    Write-Host "Verifying $lang translations..." -ForegroundColor Green
    .\VerifyTranslations.ps1 -LanguageCode $lang
}
```

### Translation Workflow
1. Developers add new English text
2. Run script to identify missing translations  
3. Translators update the missing entries
4. Re-run script to verify completeness
5. Commit translated files