<p align="center">
  <img src="https://img.shields.io/badge/WoW-Retail_12.0-blue?style=for-the-badge&logo=world-of-warcraft" alt="WoW Retail" />
  <img src="https://img.shields.io/badge/Version-7.0.0-gold?style=for-the-badge" alt="Version" />
  <img src="https://img.shields.io/badge/Ace3-Framework-cyan?style=for-the-badge" alt="Ace3" />
  <img src="https://img.shields.io/github/license/kriffin/MacroForge?style=for-the-badge" alt="License" />
</p>

<h1 align="center">
  ⚒️ MacroForge
</h1>

<p align="center">
  <strong>The macro editor that WoW should have shipped with.</strong><br/>
  Write smarter macros, faster — with real-time analysis, autocomplete, syntax highlighting, and a full toolkit built for serious players.
</p>

---

## 🎬 Screenshots

<p align="center">
  <img src="screenshots/main_list.png" alt="Main macro list" width="45%" />
  <img src="screenshots/editor.png" alt="Smart editor with syntax highlighting" width="50%" />
</p>

<p align="center">
  <img src="screenshots/spells.png" alt="Spell & Item browser" width="38%" />
  <img src="screenshots/commands.png" alt="Slash command palette" width="38%" />
</p>

---

## 💡 Why MacroForge?

WoW's built-in macro editor is a plain text box. No syntax checking. No autocomplete. No way to know if your macro is broken until you press it in a dungeon and nothing happens.

**MacroForge changes that.** It gives you a real editor with everything you need — from syntax validation to spell detection to one-click templates — all wrapped in a sleek interface that feels native to WoW.

Whether you're a PvP player fine-tuning arena macros, a healer optimizing mouseover casts, or a new player writing your first `/cast`, MacroForge has your back.

---

## ✨ Features

### 🔍 Real-Time Macro Analyzer
Your macros are validated **live** as you type. MacroForge checks every command, condition, and spell name against the game's own database and your spellbook — no more guessing.

- **Syntax highlighting** — Commands, conditions, spells, items, and errors each get their own color
- **"Did you mean?"** — Misspelled `/csatsequence`? MacroForge suggests `/castsequence` using fuzzy matching
- **Quality score** — Each macro gets a health score from 0–100%, so you spot issues at a glance
- **Plain-English explanations** — Hover over a macro to get a line-by-line breakdown of what it actually does

### ⌨️ Context-Aware Autocomplete
Start typing and MacroForge knows what you need:
- After `/` → suggests **slash commands** with categories
- Inside `[` → suggests **conditions** and `@targets`
- After `/cast` → suggests **spells from your spellbook** with icons
- Navigate with **↑ ↓ Tab Enter** — no mouse needed

### 🧩 Visual Condition Builder
Never memorize condition syntax again. Pick from dropdowns — target, modifiers, stance, spec, talents — and MacroForge builds the `[condition]` string for you with a live preview. Insert directly into your macro with one click.

### 📋 40+ Ready-to-Use Templates
Macro templates for **every class**, organized by role:
- **Universal** — Mouseover casts, modifier combos, mount macros, trinket usage
- **Class-specific** — Interrupt priorities, burst openers, defensive rotations, CC chains
- **Role-based** — Tank taunts, healer mouseover heals, PvP arena targeting

Templates auto-detect your class and show the most relevant ones first. Edit or create directly — no copy-pasting from Wowhead.

### ✂️ Macro Shortener
Hitting the 255-character limit? MacroForge compresses your macro intelligently:
- Replaces commands with their **shortest aliases** (`/castsequence` → `/castse`)
- Strips unnecessary whitespace inside conditions
- Respects WoW's syntax rules — only applies **safe** transformations

### 🔗 Share, Import & Export
- **Compressed sharing codes** — Generate a compact string to paste in Discord, guild chat, or forums
- **Direct player-to-player sending** — Send macros to any online player via AceComm, they get a popup to accept
- **Legacy support** — Imports codes from older MacroForge versions (MF5, MF6, MF7)

### 🔎 Spell & Command Palette
- **Spell browser** — Browse your entire spellbook with icons, search and insert any spell or item into your macro
- **Command palette** — All WoW slash commands organized by category (Combat, Chat, Targeting, System…) with searchable filtering

### 💾 Profiles & Auto-Swap
- **Per-spec profiles** — Save and load macro sets for each specialization
- **Auto-swap** — Switch specs and your macros follow automatically
- **Backups** — Up to 10 backup slots with one-click restore
- **Edit history** — Undo/redo support per macro

### 🔎 Duplicate Detector
Scans all your macros and flags exact or near-duplicate entries, so you can clean up unused copies.

### ⚙️ Fully Configurable
- Editor font & size (LibSharedMedia support)
- Syntax coloring on/off
- Auto-save drafts
- Sound effects
- Minimap button toggle
- Keybinding support
- Settings integrated into WoW's Interface → AddOns panel

### 🌐 Localization
- 🇬🇧 English
- 🇫🇷 French

---

## 📦 Installation

### Manual
1. Download the [latest release](https://github.com/kriffin/MacroForge/releases) or clone:
   ```bash
   git clone https://github.com/kriffin/MacroForge.git
   ```
2. Copy the `MacroForge` folder into:
   ```
   World of Warcraft/_retail_/Interface/AddOns/
   ```
3. Restart WoW or `/reload`

---

## 📝 Slash Commands

| Command | What it does |
|---------|-------------|
| `/mf` | Toggle the main window |
| `/mf analyze` | Run analysis on all your macros |
| `/mf builder` | Open the visual condition builder |
| `/mf commands` | Open the slash command palette |
| `/mf templates` | Browse macro templates |
| `/mf share` | Export the current macro |
| `/mf import` | Import a macro from a code |
| `/mf send` | Send a macro to another player |
| `/mf duplicates` | Detect duplicate macros |
| `/mf save` | Save macros to current spec profile |
| `/mf load` | Load macros from current spec profile |
| `/mf backup` | Create a backup |
| `/mf restore [n]` | Restore backup #n |
| `/mf settings` | Open settings |
| `/mf help` | Show all commands |

---

## 🏗️ Built With

| Library | Purpose |
|---------|---------|
| [Ace3](https://www.wowace.com/projects/ace3) | Addon framework (AceAddon, AceDB, AceEvent, AceGUI, AceConfig, AceConsole, AceComm, AceSerializer, AceHook, AceTimer, AceLocale) |
| [LibDeflate](https://github.com/SafeteeWoW/LibDeflate) | Data compression for sharing |
| [LibDataBroker](https://github.com/tekkub/libdatabroker-1-1) + [LibDBIcon](https://www.wowace.com/projects/libdbicon-1-0) | Minimap button |
| [LibSharedMedia](https://www.wowace.com/projects/libsharedmedia-3-0) | Custom font support |

---

## 📄 License

[MIT](LICENSE) — Use it, fork it, improve it.

---

<p align="center">
  <strong>⚒️ Stop writing macros blind. Start forging them.</strong><br/>
  <em>Made with ❤️ by Antigravity</em>
</p>
