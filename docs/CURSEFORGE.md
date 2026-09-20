<!--
CurseForge project page for MacroForge (project 1494025).
The upload API cannot edit descriptions: paste everything below this comment
into authors.curseforge.com → MacroForge → Description, in Markdown mode.

Summary line (set on the General tab, max ~120 chars):
  Never press a broken macro again: live checks, autocomplete, templates, spec sets and a full history.

Images live in the repo (docs/assets, screenshots): update them there and the
page follows. CurseForge ignores align="center", so nothing relies on it.
-->

![MacroForge — every macro checked, sorted, never lost](https://github.com/kriffin/MacroForge/raw/main/docs/assets/thumbnail.png)

## Your macro is broken. You will find out mid-pull.

No syntax check. No spell verification. No history. Blizzard's macro frame is a text box, and it has been for twenty years.

**MacroForge is the editor that should have shipped with the game.** It checks every line as you type, tells you what your macro would do *right now*, keeps every version you ever saved, and swaps whole macro sets when you change spec — without emptying your action bars.

![Editor: code, analysis and detected spells](https://github.com/kriffin/MacroForge/raw/main/docs/assets/shots/editor.png)

---

## It catches the mistake before the boss does

- **Live analysis** — every command, condition and spell checked against your own spellbook
- **"Did you mean…?"** — `/csatsequence` becomes `/castsequence`, a misspelt spell gets the closest match
- **Plain-English explanation** of every line, right next to the code
- **Test button** — resolves the macro against your current state: which clause fires, on which target, or nothing at all. Hold Shift to test your Shift branch
- **Live 255-character counter**, with the shortener one click away

---

## One window, built for speed

Search by name **or content**. Filter to what is broken, what sits on a bar, what nobody uses. Drag a macro straight onto your action bars. Right-click for duplicate, share, move between Character and Account, or its full history.

`Ctrl+S` save · `Ctrl+Z` undo · `Ctrl+F` search · `↑ ↓` walk the list · `Del` delete

![The MacroForge window](https://github.com/kriffin/MacroForge/raw/main/docs/assets/shots/window.png)

![Right-click menu](https://github.com/kriffin/MacroForge/raw/main/docs/assets/shots/menu.png)

---

## Your macros follow your spec

Save your character macros as a **set** — Raid, M+, PvP, whatever you run. Bind it to a spec. Change spec, and the right set is in place before the pull.

Macros that exist in both sets **keep their action bar slots**, and anything you changed is saved into the set before it swaps. No more rebuilding your bars every Tuesday.

![Sets bound to specs](https://github.com/kriffin/MacroForge/raw/main/docs/assets/shots/sets.png)

---

## Nothing is ever lost

- **Every version of every macro** is kept — including the edits you make in Blizzard's own frame
- Deleted a macro? It is in the **Trash**, body intact, one click from coming back
- An **automatic backup** is taken before every set swap or restore
- Unsaved changes are marked, and MacroForge asks before dropping them

![Trash: recreate a deleted macro](https://github.com/kriffin/MacroForge/raw/main/docs/assets/shots/trash.png)

---

## Also in the box

**50+ class templates** — interrupt chains, stealth openers, defensive stacks, mouseover heals, arena targeting. Spell names are filled in your client's language, so they work the moment you create them.

**Audit** — one panel listing every macro that needs attention, worst first, each a click away from being fixed.

**Share** — export a macro as a short code for Discord, or send it straight to another MacroForge user in game.

**Condition builder** — build `[@mouseover,harm,nodead]` from dropdowns instead of memorising it.

---

![Retail and WoW Forever](https://github.com/kriffin/MacroForge/raw/main/docs/assets/flavors.png)

## Start in ten seconds

1. Install with the CurseForge app
2. Type **`/mf`** in game, or click the minimap button
3. Pick a macro on the left — hover the **?** in the title bar for every shortcut

| Command | What it does |
|---|---|
| `/mf` | Open / close MacroForge |
| `/mf sets` | Macro sets |
| `/mf audit` | Check every macro |
| `/mf templates` | Class templates |
| `/mf import` | Import a share code |
| `/mf backups` · `/mf restore [n]` | Backups |
| `/mf trash` | Deleted macros |
| `/mf help` | Everything else |

---

## FAQ

**Does it replace my macros?**
No. It edits the very same macros as Blizzard's frame. Uninstall it and every macro is still there, on the same slot.

**Is it safe in combat?**
WoW forbids macro changes in combat. MacroForge queues them and applies them the moment you leave combat, and it never swallows your keys while you fight.

**Why does my macro show a "?" icon?**
That is the dynamic icon: with `#showtooltip` it follows the spell being cast. MacroForge keeps it dynamic instead of freezing it on one spell, the way saving from other tools does.

**Where are my spec profiles from older versions?**
They became sets, named after each spec, in the Sets tab.

**Does it run on WoW Forever?**
Yes. Retail 12.x and the Forever client are both supported, from the same install.

---

Found a bug or have an idea? [Open an issue on GitHub](https://github.com/kriffin/MacroForge/issues) — include the error from BugSack if you have one. MIT licensed, built on Ace3.

<sub>World of Warcraft and its logos are trademarks of Blizzard Entertainment. MacroForge is fan-made and not affiliated with Blizzard.</sub>
