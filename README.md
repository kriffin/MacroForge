<p align="center">
  <img src="docs/assets/thumbnail.png" alt="MacroForge — every macro checked, sorted, never lost" width="820">
</p>

<p align="center">
  <a href="https://www.curseforge.com/wow/addons/macroforge"><img src="https://img.shields.io/badge/CurseForge-MacroForge-F16436?style=for-the-badge" alt="CurseForge"></a>
  <img src="https://img.shields.io/badge/Retail-12.1.0-148EFF?style=for-the-badge" alt="Retail 12.1.0">
  <img src="https://img.shields.io/badge/WoW%20Forever-1.60.1-FFD700?style=for-the-badge" alt="WoW Forever 1.60.1">
  <img src="https://img.shields.io/badge/License-MIT-44CC88?style=for-the-badge" alt="MIT">
</p>

## Your macro is broken. You will find out mid-pull.

No syntax check. No spell verification. No history. Blizzard's macro frame is a text box, and it has been for twenty years.

**MacroForge is the editor that should have shipped with the game.** It checks every line as you type, tells you what your macro would do *right now*, keeps every version you ever saved, and swaps whole macro sets when you change spec — without emptying your action bars.

![Editor: code, analysis and detected spells](docs/assets/shots/editor.png)

---

## It catches the mistake before the boss does

- **Live analysis** — every command, condition and spell checked against your own spellbook
- **"Did you mean…?"** — `/csatsequence` becomes `/castsequence`, a misspelt spell gets the closest match
- **Plain-language explanation** of every line, right next to the code
- **One-click fixes** — click an issue to jump to its line, click **Fix** to correct a mistyped command
- **Live test** — one click and the panel shows which clause fires right now, on which target, and follows as you change target, hover a unit or hold Shift
- **Live 255-character counter**, with the shortener one click away

## One window, built for speed

Everything opens inside it: templates, history, sharing and duplicates are pages of the window (`Esc` goes back), and the spell list, commands, condition builder and icon picker slide in next to the code. Search by name **or content**. Filter to what is broken, what sits on a bar, what nobody uses. Drag a macro straight onto your action bars. Right-click for duplicate, share, move between Character and Account, or its full history.

`Ctrl+S` save · `Ctrl+Z` undo · `Ctrl+F` search · `↑ ↓` walk the list · `Del` delete

![The MacroForge window](docs/assets/shots/window.png)

![Icon picker next to the code](docs/assets/shots/drawer.png)

## Your macros follow your spec

Save your character macros as a **set** — Raid, M+, PvP, whatever you run. Bind it to a spec. Change spec, and the right set is in place before the pull. Macros that exist in both sets **keep their action bar slots**, and anything you changed is saved into the set before it swaps.

![Sets bound to specs](docs/assets/shots/sets.png)

## Nothing is ever lost

- **Every version of every macro** is kept — including the edits you make in Blizzard's own frame
- Deleted a macro? It is in the **Trash**, body intact, one click from coming back
- **Automatic backup** before every set swap or restore
- Unsaved changes are marked, and MacroForge asks before dropping them

![Trash: recreate a deleted macro](docs/assets/shots/trash.png)

## Also in the box

**190 templates** — stances, traps, totems, seals, curses, druid forms, focus interrupts, mouseover heals: 11 for every class and 16 to 21 per class on WoW Forever, every spell checked in the client. Browse any class, not only yours. Spell names are resolved from spell IDs, so they are always in the client's language.

**Audit** — one panel listing every macro that needs attention, worst first.

**Share** — export a macro as a short code, send it to another MacroForge user in game, or paste any macro copied from a guide: it is named for you.

**Condition builder** — build `[@mouseover,harm,nodead]` from menus instead of memorising it.

**Your language** — the whole addon, analysis and explanations included, follows your client's language:

![](docs/assets/flags/gb.png) English · ![](docs/assets/flags/fr.png) Français · ![](docs/assets/flags/de.png) Deutsch · ![](docs/assets/flags/es.png) Español · ![](docs/assets/flags/mx.png) Español (México) · ![](docs/assets/flags/it.png) Italiano · ![](docs/assets/flags/br.png) Português (Brasil) · ![](docs/assets/flags/ru.png) Русский · ![](docs/assets/flags/kr.png) 한국어 · ![](docs/assets/flags/cn.png) 简体中文 · ![](docs/assets/flags/tw.png) 繁體中文

**Blizzard's /macro window** gets a MacroForge button: the macro you selected there opens here.

![Templates of every class](docs/assets/shots/templates.png)

![The MacroForge button in /macro](docs/assets/shots/macroframe.png)

---

## Install

**With the CurseForge app** — search for *MacroForge*, or use the [project page](https://www.curseforge.com/wow/addons/macroforge).

**By hand** — download a [release](https://github.com/kriffin/MacroForge/releases) and drop the `MacroForge` folder into:

```
World of Warcraft/_retail_/Interface/AddOns/        # Retail 12.x
World of Warcraft/_classic_beta_/Interface/AddOns/  # WoW Forever
```

Then type `/mf` in game, or click the minimap button.

| Command | What it does |
|---|---|
| `/mf` | Open / close MacroForge |
| `/mf sets` | Macro sets |
| `/mf audit` | Check every macro |
| `/mf templates` | Class templates |
| `/mf import` · `/mf export` | Share codes |
| `/mf backups` · `/mf restore [n]` | Backups |
| `/mf trash` | Deleted macros |
| `/mf history` | Versions of the open macro |
| `/mf log [n]` · `/mf debug` | Debug log |
| `/mf help` | Everything else |

---

## Development

```bash
git clone https://github.com/kriffin/MacroForge.git
ln -s "$PWD/MacroForge" "/path/to/World of Warcraft/_retail_/Interface/AddOns/MacroForge"
bash tests/run.sh          # headless tests against a fake WoW API
luac -p $(git ls-files '*.lua')
```

| Path | |
|---|---|
| `Core.lua` | addon bootstrap, AceDB, slash commands, out-of-combat queue |
| `UI.lua` | main window: tabs, macro list, home and detail views |
| `Editor.lua` | editor pane: toolbar, code box, analysis, undo/redo |
| `Profiles.lua` | macro read/write, sets, backups |
| `History.lua` | revisions and trash |
| `Analyzer.lua` · `AnalyzerExplain.lua` | validation and explanations |
| `Templates.lua` · `Builder.lua` · `Share.lua` | templates, condition builder, share codes |
| `tests/` | fake WoW API + 11 headless tests |
| `docs/CURSEFORGE.md` | source of the CurseForge project page |

CI runs the syntax check, the tests, luacheck and a locale-key check on every push. Tagging `vX.Y.Z` builds the zip with the BigWigs packager and publishes it.

Built on [Ace3](https://www.wowace.com/projects/ace3), [LibDeflate](https://github.com/SafeteeWoW/LibDeflate), LibDataBroker + LibDBIcon and LibSharedMedia.

## License

[MIT](LICENSE) — use it, fork it, improve it.

<sub>World of Warcraft and its logos are trademarks of Blizzard Entertainment. MacroForge is fan-made and not affiliated with Blizzard.</sub>
