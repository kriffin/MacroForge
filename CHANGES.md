# Changes

## Unreleased

- **Drafts** now follow their macro by scope and name instead of its slot
  number: creating or renaming a macro no longer offers a draft on the wrong
  macro. A new macro's draft is kept too - it used to be saved and never
  offered back. The Home view shows a "Resume the draft" button.
- A draft is no longer wiped by opening another macro first, and discarding
  or cancelling your edits drops it.
- **Import**: one window for everything you paste. A MacroForge code, or the
  plain text of a macro copied from a guide or a forum - the name comes from
  its first line, or from the spell it casts. The preview says which one it
  read, and why it refuses anything else.
- **Blizzard's /macro window** gets a MacroForge button next to Delete: it
  opens the selected macro in MacroForge (what you typed there is saved
  first), or a new macro when the tab is empty.
- **Test is live**: click it once and the result follows your target, focus,
  the unit under your cursor, combat and the keys you hold - no more clicking
  with Shift down. Click again (Stop test) to turn it off; saving keeps it on.
- **French**: every string has its accents back (the locale had none), and
  the whole interface now says "vous", like Blizzard's own French UI.
- **Clickable analysis**: click an issue to select its line in the code, and
  click "Fix: /castsequence" under a mistyped command (or a name over 16
  characters) to apply the correction. Line numbers now match the editor
  gutter: blank lines used to be skipped, so every issue below one pointed
  one line too high.
- **One window**: tools now open inside the main window instead of on top of
  it, Blizzard style. Templates is the first: search and filter on top, the
  list on the left, the selected template on the right. The title shows where
  you are; Back (or Esc) returns to what was open, unsaved edits included.

## 7.3.0 — 2026-09-20

A home view, an audit of every macro, a Test button and list filters.

- **Home**: the right pane now opens on your character (name, class, spec),
  free slots per scope, active set, set and trash counts, the macros that need
  attention, the ones you edited last (click to open) and New / Templates /
  Import buttons. Come back to it with the Home button or by clicking the empty
  part of the list.
- **Audit**: every macro the analyzer flags, worst score first, with its issues
  and an Edit button. Home button, the Audit button or `/mf audit`.
- **Test** (editor): resolves the macro against your current state and says
  which clause would fire, on which target - or that nothing would happen.
  Hold a modifier while clicking to test it.
- **Filters** (macro list): all, with issues, on an action bar, not on a bar.
- New macros are unnamed by default instead of refusing to save.
- Project: the headless tests ship in `tests/`, CI checks syntax, tests, lint
  and locale keys, and a `.pkgmeta` lets the standard packager build the zip.

## 7.2.1 — 2026-09-20

Fixes found while testing 7.2 in game:

- The window painted no background of its own: the game world showed through it.
- Clicking a set (or a deleted macro) opened an empty pane.
- The editor's analysis column floated in the middle of the row instead of
  starting at the top, and the code box did not grow with the window.
- Typing in the editor reached the game: the character moved and keybinds
  fired. Keys are swallowed again while a field has the focus.
- Two macros with the same name (or none) swapped revisions as soon as one was
  deleted, so the Trash showed the wrong body.
- `#showtooltip` on its own line reported the next line as its spell.
- The Blizzard options panel was empty: AceGUI calls `SetDesaturation`, dropped
  in 12.x, and the font option needed a control we do not embed.
- New macros start unnamed (a single space) instead of refusing to save.

## 7.2.0 — 2026-09-20

Safer macro writes, full revisions and named macro sets.

---

### 🛡️ Fixes

#### Spec swap no longer empties your action bars

The swap used to delete every character macro and recreate them. A deleted
macro disappears from the action bars, so every swap left empty buttons.

Now a macro present in both sets under the same name is **edited in place**.
Only macros missing from the new set are deleted, and only new ones are created.

```
Before                                  After
Bar: [Nuke] [Combu] [Blink]             Bar: [Nuke] [Combu] [Blink]
      │ swap Fire → Frost                     │ swap Fire → Frost
      ▼                                       ▼
Bar: [    ] [     ] [     ]             Bar: [Nuke] [     ] [Blink]
     all macros deleted + recreated          Nuke edited in place (Frostbolt)
                                             Combu deleted (not in Frost set)
```

#### No macro write during combat

`CreateMacro` / `EditMacro` / `DeleteMacro` are blocked in combat: a spec
change or a save mid-fight failed halfway.

| Action in combat | Before | After |
|---|---|---|
| Spec swap, set load, backup restore | Partially applied | Queued, applied when combat ends |
| Save in the editor, create a macro | Error | Queued, applied when combat ends |
| Delete a macro | Error | Refused with a message |

#### Automatic backup before every overwrite

Loading a set, auto-swapping and restoring now take a backup first.
Automatic backups have their own quota (5), so they never push manual ones out.

```
/mf backups
#1 2026-09-19 21:40:12 — 4 character, 12 account (auto)
#2 2026-09-19 21:12:03 — 5 character, 12 account
```

#### Restoring a backup restores account macros too

Backups stored account macros, but `/mf restore` only wrote character macros
back. Both are restored now. An empty scope in the backup is skipped instead
of wiping your current macros.

#### Received and imported macros are validated

Before, a whisper through the addon channel only needed a `name` field to open
a popup with arbitrary content.

- Name: control characters and `|` removed (no color or link codes), 16 chars max.
- Body: 255 chars max, rejected instead of silently truncated.
- Comm: whisper only, size-capped, one popup at a time.
- Share codes: size-capped before and after decompression.

#### Dynamic "?" icons stay dynamic

A macro with the `?` icon and `#showtooltip` shows the icon of the spell it
casts. `GetMacroInfo` returns that resolved icon, and MacroForge wrote it back
on save, swap, restore or recreate: the icon was frozen on one spell.
MacroForge now detects it (returned icon = icon of the macro's spell or item)
and keeps `?`.

#### Class templates work in every client language

Template bodies held French spell names (`/cast Mur protecteur`), and several
were wrong even in French (`Gouger`, `Rebuffade`, `Tranche Menu`). WoW matches
`/cast` by name in the client language, so they failed on an English client.

Bodies now store spell IDs, resolved when a template is previewed, loaded or
created:

```
Stored                                   English client          French client
/cast [nomod] {spell:871:Shield Wall}    /cast [nomod] Shield Wall   /cast [nomod] Mur protecteur
```

The name after the ID is the fallback when the spell does not exist in the
client. Generic placeholders (`SPELL`, `FLYING_MOUNT`…) are localized too.

---

### ✨ New

#### One window, Blizzard style

The list and the editor were two AceGUI windows replacing each other. They are
now one movable, resizable window built on Blizzard templates (ESC closes it,
position and size are remembered).

```
┌─ MacroForge ───────────────────────────────────── [Templates][Settings] X ┐
│ 🔍 search            │ ● Character  Kick  #121                             │
│ ▾ Character   6/30   │ [📖][📝][⚙][✂] [📜][✉][✉] [⌚][👣]  Snippets ▾  13px │
│   Kick          82%  │ ┌ code ─────────────────┐  Analysis                  │
│   Backstab           │ │1 #showtooltip         │  ⚠ ...                     │
│ ▾ Account    21/120  │ │2 /cast [@focus] Kick  │  Detected spells [i][i]    │
│ ▾ Sets               │ └───────────────────────┘                            │
│   Raid     [active]  │ [Save] [Cancel]  Ctrl+S save, Ctrl+Z undo            │
│ ▸ Trash           3  │                                                     │
│ [Create] [Import]    │                                                   ◢ │
└──────────────────────────────────────────────────────────────────────────────┘
```

- Sidebar: search (name + body), Character / Account groups with n/max,
  rows with icon, condensed body and quality badge; click edits, drag puts
  on a bar, right-click menu (duplicate, share, move, history, delete).
  Sets and Trash are groups too: click shows the detail, double-click
  applies a set.
- Unsaved changes are marked (header + row) and switching away asks
  Save / Keep editing / Discard.
- Editor: icon toolbar with tooltips, code and analysis side by side.
- Sidebar tabs: Macros / Sets / Trash (count in the tab), each with its
  own buttons and empty state; the last tab is remembered.
- Keyboard: Ctrl+S / Ctrl+Z / Ctrl+Y / Ctrl+F / Ctrl+N, Up / Down to walk
  the list, Delete, Enter to edit the code.
- Editor toolbar: interface icons for insert spell / command / conditions
  / shorten, everything else in a "More" menu.
- Onboarding: a one-time "what's new" popup, HelpTip bubbles shown once
  each, and a "?" button listing every shortcut.
- Move a macro between Character and Account (menu, or drop it on the other
  group's header); its revisions follow.

#### Revisions and trash

Every version of every macro is kept, **including edits made in Blizzard's
macro editor or by other addons**. A deleted macro keeps its versions and
lands in the trash.

```
History : Nuke
#4  2026-09-19 21:40  Nuke  [set: Frost]   (current)
#3  2026-09-19 20:02  Nuke  [set: Fire]
#2  2026-09-18 23:15  Nuke
#1  2025-01-01        Nuke  [v7]           ← migrated from 7.1
    [Load in editor]
```

```
Trash
Combu   character   deleted 2026-09-19 21:40   [set: Frost]
#showtooltip
/cast Combustion
    [Recreate]  [Versions (3)]
```

- Versions are keyed by macro name, not by slot, so they survive reordering;
  a rename keeps the history.
- 20 versions per macro by default (up to 50), 50 deleted macros max.
- **History** button in the editor, **Trash** button in the main window.
- 7.1 history is migrated automatically.

#### Named macro sets bound to specs

Per-spec profiles become **named sets** (Raid, M+, PvP…). A set can be bound
to one or more specs; each spec belongs to at most one set.

```
┌ Sets ─────────────────────────────────────────────────────────┐
│ Spec: Fire   Active set: Raid   Auto-swap: ON                 │
│ Set name [ PvP          ]  [Save current macros]              │
│                                                               │
│ ┌ Raid [active]  6 macros — 2026-09-19 21:40 ──────────────┐  │
│ │ Nuke  Combu  Blink  Focus  Poly  Burst                   │  │
│ │ Bound specs [Fire ▾]  [Apply] [Update] [Rename] [Delete] │  │
│ └──────────────────────────────────────────────────────────┘  │
│ ┌ PvP  8 macros ───────────────────────────────────────────┐  │
│ │ ...                                                      │  │
│ └──────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
```

How the swap works:

```
Edit "Nuke" while in Fire ──► switch to Frost
                               1. edits saved into the active set (Raid)
                               2. automatic backup
                               3. set bound to Frost applied
Switch back to Fire ─────────► your edited "Nuke" is there
```

- Option **Save edits into the active set before swapping** (on by default).
- A spec change that fires several events swaps only once.
- 7.1 spec profiles are migrated to sets named after the spec.

#### Debug log

A persistent log (`MacroForgeLog` SavedVariable, 2000 lines) records sessions,
spec changes, set swaps, macro writes, backups, combat queue and rejected
comm messages. MacroForge errors caught by BugGrabber are mirrored in it.

```
2026-09-19 21:40:11 #3 [INFO] spec: 63 -> 64
2026-09-19 21:40:12 #3 [INFO] sets: saved Raid (6 macros) [auto]
2026-09-19 21:40:12 #3 [INFO] write: character: kept=4 edited=2 created=1 deleted=2 skipped=0
```

- `/mf log [n|clear]` in game, `/mf debug` for verbose mode echoed to chat.
- `tools/read-logs.sh` prints the log and BugGrabber errors outside the game
  (written on `/reload`, logout or exit).

---

### ⌨️ Commands

| Command | Status | Effect |
|---|---|---|
| `/mf sets` | new | Open the sets window |
| `/mf save [set]` | changed | Save current macros into a set (default: set of the current spec) |
| `/mf load [set]` | changed | Apply a set (default: set of the current spec) |
| `/mf list` | changed | List sets, active set and bound specs |
| `/mf backups` | new | List backups (manual and automatic) |
| `/mf restore [n]` | changed | Restores character **and** account macros |
| `/mf trash` | new | Deleted macros, recreatable |
| `/mf history` | changed | Versions of the open macro, by name |
| `/mf log [n\|clear]` | new | Last log lines in chat |
| `/mf debug [on\|off]` | new | Verbose log, echoed to chat |

---

### 🗄️ Saved data

| Key | Change |
|---|---|
| `char.profiles` | Migrated to `char.sets`, then removed |
| `char.sets`, `char.activeSet`, `char.lastSpec` | New |
| `char.history` (by slot index) | Migrated to `char.revisions` (by name), then removed |
| `global.revisions` | New: account macro versions |
| `profile.autoSaveOnSwap` | New, default `true` |
| `MacroForgeLog` | New SavedVariable: debug log |
| `profile.maxHistory` | Default 10 → 20, max 30 → 50 |
