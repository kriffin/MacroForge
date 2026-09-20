<!--
CurseForge project page for MacroForge (project 1494025).
The upload API cannot edit descriptions: paste this into
authors.curseforge.com → MacroForge → Description, in Markdown mode.

Summary line (max ~120 chars):
  A real macro editor: live error checking, autocomplete, templates, spec-based macro sets and a full history.

Images are served from the GitHub repo, so updating a screenshot there
updates the page. Keep them under screenshots/ with these names.
-->

<p align="center">
  <img src="https://github.com/kriffin/MacroForge/raw/main/icons/MacroForge_128x128.png" width="112" height="112" alt="MacroForge">
</p>

<h1 align="center">MacroForge</h1>
<p align="center"><b>The macro editor WoW should have shipped with.</b></p>

<p align="center">
  <img src="https://github.com/kriffin/MacroForge/raw/main/docs/assets/wow-midnight.png" width="200" alt="World of Warcraft: Midnight">
  &nbsp;&nbsp;&nbsp;
  <img src="https://github.com/kriffin/MacroForge/raw/main/docs/assets/wow-forever.png" width="240" alt="World of Warcraft: Forever">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Retail-12.1.0-148EFF?style=for-the-badge" alt="Retail 12.1.0">
  <img src="https://img.shields.io/badge/WoW%20Forever-1.60.1-FFD700?style=for-the-badge" alt="WoW Forever 1.60.1">
  <img src="https://img.shields.io/badge/English%20%C2%B7%20Francais-00CCFF?style=for-the-badge" alt="English and French">
  <img src="https://img.shields.io/badge/License-MIT-44CC88?style=for-the-badge" alt="MIT">
</p>

Write, check and organize your macros in **one window**: live error checking, autocomplete, class templates, macro sets that follow your spec, and a history that means you never lose a macro again.

<p align="center">
  <img src="https://github.com/kriffin/MacroForge/raw/main/screenshots/main-window.png" alt="The MacroForge window: macro list on the left, editor and analysis on the right">
</p>

---

## Why MacroForge?

Blizzard's macro frame is a text box. You find out a macro is broken when you press it mid-pull and nothing happens.

MacroForge tells you **while you type** — unknown spell, typo in a condition, missing bracket, 255-character limit — and keeps every version of every macro, so an edit gone wrong is one click away from undone.

---

## The editor

- **Live analysis**: every command, condition and spell checked against your spellbook, with "did you mean…?" fixes and a plain-English explanation of each line
- **Test button**: resolves the macro against your current state and tells you which clause would fire, on which target — hold Shift to test your Shift branch
- **Syntax highlighting**, line numbers and a live `n/255` counter
- **Autocomplete** for `/commands`, `[conditions]` and spell names
- **Condition builder**: pick `@mouseover`, `mod:shift`, `harm,nodead` from dropdowns
- **Shortener**: squeezes a macro under 255 characters, safe rewrites only

<p align="center">
  <img src="https://github.com/kriffin/MacroForge/raw/main/screenshots/editor.png" alt="Editor: coloured code on the left, analysis and detected spells on the right">
</p>

---

## Everything in one window

- Search by name **or content**, and filter: with issues, on an action bar, unused
- **Drag** a macro straight onto your bars
- **Right-click** to duplicate, share, move between Character and Account, or open its history
- Keyboard first: `Ctrl+S` save, `Ctrl+Z` undo, `Ctrl+F` search, `↑ ↓` to walk the list
- A home view with your character, free slots, the macros that need attention and the ones you edited last

<p align="center">
  <img src="https://github.com/kriffin/MacroForge/raw/main/screenshots/context-menu.png" alt="Right-click menu on a macro">
</p>

---

## Macro sets that follow your spec

Save your character macros as a **set** (Raid, M+, PvP…) and bind it to one or more specs. Change spec and the right set is applied. Macros that exist in both sets **keep their action bar slots**, and the edits you made are saved into the set before it swaps.

<p align="center">
  <img src="https://github.com/kriffin/MacroForge/raw/main/screenshots/sets.png" alt="Sets tab: a set bound to a spec, with apply, update, rename and delete">
</p>

---

## Never lose a macro

- **Every version** of every macro is kept — including edits made in Blizzard's own macro frame
- Deleted macros go to the **Trash**, ready to be recreated
- **Automatic backup** before every set swap or restore
- Unsaved changes are marked, and you are asked before leaving them

<p align="center">
  <img src="https://github.com/kriffin/MacroForge/raw/main/screenshots/trash.png" alt="Trash: a deleted macro with its body, Recreate and Versions">
</p>

---

## Also in the box

**50+ class templates** — interrupt chains, stealth openers, defensives, mouseover heals, arena targeting. Spell names are filled in your client's language.

**Audit** — one panel listing every macro the analyzer flags, worst first, with a click to fix.

**Share** — export a macro as a short code for Discord, or send it straight to another MacroForge user in game.

---

## Getting started

1. Install with the CurseForge app
2. Type **`/mf`** in game (or use the minimap button)
3. Click a macro on the left to edit it — hover the **?** in the title bar for every shortcut

| Command | |
|---|---|
| `/mf` | Open / close MacroForge |
| `/mf sets` | Manage macro sets |
| `/mf audit` | Check every macro |
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
WoW blocks macro changes in combat. MacroForge queues them and applies them when combat ends, and it never swallows your keys while you fight.

**My macro shows a "?" icon.**
That is the dynamic icon: with `#showtooltip`, the icon follows the spell the macro casts. MacroForge keeps it dynamic instead of freezing it.

**Where are my old spec profiles?**
Version 7.2 turned them into sets named after each spec (Sets tab).

**Does it work on WoW Forever?**
Yes — the beta client is supported alongside Retail 12.x.

---

## Feedback

Found a bug or have an idea? Open an issue on [GitHub](https://github.com/kriffin/MacroForge/issues) — include the error from BugSack if you have one.

MIT licensed · Built on Ace3

<sub>World of Warcraft and its logos are trademarks of Blizzard Entertainment. MacroForge is fan-made and not affiliated with Blizzard.</sub>
