# Hard Chip - Community Localization

Welcome to the Hard Chip community localization repository! This repository contains all the localization files for the Hard Chip game, and I invite the community to help review and suggest corrections to improve translations!

## 🤝 How to Contribute

1. **Fork** this repository
2. **Open** the `src` folder with ResX Resource Manager
3. **Review** translations and make corrections
4. **Verify** your translations using the verification script: `scripts\VerifyTranslations.ps1 -LanguageCode [your-language]` (e.g., `scripts\VerifyTranslations.ps1 -LanguageCode de` for German)
5. **Format** ResX files using the formatting script: `scripts\FormatResxFiles.ps1`
6. **Add contributor's name** to the [Contributors file](CONTRIBUTORS.md) (_Optional_)
7. **Agree** to the [Contributor License Agreement (CLA)](CLA.MD)
8. **Submit** a pull request with your improvements

#### ⚠️ Requirements
* Do not include any auto-generated Designer files (`.Designer.cs`)
* Maintain the file structure exactly as provided
* Do not add or remove any key

#### Guidelines
Where to draw the line, whether there needs to be a translation or not:
- Name like "HCDrive" or something that feels like a name, no translation.
- Technical words that have minimal usage in the current language. Example "MOS", or MOSFET, is an English acronym that is used across all languages.
- Widely known technical words like "transistor", widely translated in all languages, should be translated as well.
- Terminal commands are not to be translated. Examples "status", "reboot", and all other command lines.
- Terminal outputs are to be translated (while still applying other rules like widely known words and such)

## 📁 File Structure

The localization files in this repository are **ResX** (Resource Exchange) files. These files contain all the text strings used throughout the game in all languages.

The `src` folder is organized by game areas and features:

- **`src/Areas/`** - Contains game-specific areas like Campaign, ComponentEditor, MainMenu, etc.
  - Example: `src/Areas/Campaign/Texts/` contains terminal texts like `FabricatorTerminalTexts.resx` with translations for different languages (`*.de.resx` for German, `*.es.resx` for Spanish, etc.)
- **`src/Texts/`** - Contains common texts shared across the entire game
  - Example: `CommonTexts.resx` and `CommonHCTexts.resx` with their language variants

Each ResX file follows the naming pattern: `[FileName].[language].resx` (e.g., `FabricatorTerminalTexts.de.resx` for German). The base English files have no language suffix.

**Important:** Please do not move or rename any files. The current structure and file placement is intentional and required for the game to function properly.

## 🛠️ Recommended Tool

For efficient editing and management of these ResX files, I highly recommend using the **ResX Resource Manager** tool:

1. **Download and install** ResX Resource Manager from [here](https://github.com/dotnet/ResXResourceManager)
2. **Open the tool** and navigate to the `src` folder of this repository
3. The tool will automatically detect and organize visually all ResX files for easy editing

If you wish to add an entirely new language, this tool is the way to go. 

## 🌍 Supported Languages

Currently, Hard Chip supports the following languages:
- **English** (base language)
- **German** (de)
- **Spanish** (es)
- **French** (fr)
- **Russian** (ru)
- **Italian** (it)

Thank you for helping make Hard Chip accessible to players worldwide! 🎮
