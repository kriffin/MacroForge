<!--
CurseForge project page for MacroForge (project 1494025).
The CurseForge upload API does not edit descriptions: paste this into
authors.curseforge.com → MacroForge → Description (Markdown mode) when 7.2 is released.

Summary line (max ~120 chars):
  A real macro editor: live error checking, autocomplete, templates, spec-based macro sets and a full history.

Images: upload them to the project's Images tab, then replace each
"IMAGE:" line with the Markdown image CurseForge gives you. Shot list in
docs/SCREENSHOTS.md.
-->

# MacroForge

**The macro editor WoW should have shipped with.**

Write, check and organize your macros in one window: live error checking, autocomplete, class templates, macro sets that follow your spec, and a history that means you never lose a macro again.

IMAGE: main-window.png — the main window, a macro open in the editor

✅ Retail 12.x · ✅ WoW Forever · English & Français

---

## Why MacroForge?

Blizzard's macro frame is a text box. You find out a macro is broken when you press it mid-pull and nothing happens.

MacroForge tells you **while you type**: unknown spell, typo in a condition, missing bracket, 255-character limit. And it keeps every version of every macro, so an edit gone wrong is one click away from undone.

---

## What you get

### ✍️ An editor that knows macros
- **Live analysis** — every command, condition and spell checked against your spellbook, with "did you mean…?" fixes and a plain-English explanation of each line
- **Syntax highlighting** and line numbers
- **Autocomplete** for `/commands`, `[conditions]` and spell names
- **Condition builder** — pick `@mouseover`, `mod:shift`, `harm,nodead` from dropdowns
- **Shortener** — squeezes a macro under 255 characters with safe rewrites only

IMAGE: editor.png — code on the left, analysis and detected spells on the right

### 🗂️ Everything in one window
- Search your macros by name **or content**
- **Drag** a macro straight onto your action bars
- **Right-click** to duplicate, share, move between Character and Account, or open its history
- Keyboard first: `Ctrl+S` save, `Ctrl+Z` undo, `Ctrl+F` search, `↑ ↓` to walk the list

### 🔄 Macro sets that follow your spec
Save your character macros as a **set** (Raid, M+, PvP…) and bind it to one or more specs. Change spec and the right set is applied. Macros that exist in both sets keep their **action bar slots**, and the edits you made are saved into the set before it swaps.

IMAGE: sets.png — the Sets tab with a set bound to two specs

### 🛟 Never lose a macro
- **Every version** of every macro is kept, including edits made in Blizzard's own macro frame
- Deleted macros go to the **Trash**, ready to be recreated
- **Automatic backup** before every set swap or restore
- Unsaved changes are marked and you're asked before leaving them

### 📋 50+ templates
Interrupt chains, stealth openers, defensives, mouseover heals, arena targeting… for every class. Spell names are filled in **your client's language**.

### 🔗 Share
Export a macro as a short code for Discord, or send it directly to another MacroForge user in game.

---

## Getting started

1. Install with the CurseForge app
2. Type **`/mf`** in game (or use the minimap button)
3. Click a macro on the left to edit it — hover the **?** in the title bar for every shortcut

## Commands

| Command | |
|---|---|
| `/mf` | Open / close MacroForge |
| `/mf sets` | Manage macro sets |
| `/mf templates` | Browse class templates |
| `/mf import` | Import a share code |
| `/mf backups` · `/mf restore [n]` | List / restore backups |
| `/mf trash` | Deleted macros |
| `/mf help` | All commands |

---

## FAQ

**Does MacroForge replace my macros?**
No. It edits the same macros as Blizzard's frame; uninstall it and your macros are still there.

**Is it safe in combat?**
WoW blocks macro changes in combat. MacroForge queues them and applies them when combat ends, and never touches your keys while you fight.

**My macro shows a "?" icon.**
That's the dynamic icon: with `#showtooltip`, the icon follows the spell the macro casts. MacroForge keeps it dynamic.

**Where are my old spec profiles?**
MacroForge 7.2 converted them into sets named after each spec (Sets tab).

---

## Feedback

Found a bug or have an idea? Open an issue on [GitHub](https://github.com/kriffin/MacroForge/issues). Include the error from BugSack if you have one.

MIT licensed · Built on Ace3
