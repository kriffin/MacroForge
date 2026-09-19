# Changes

## 7.2.0 — Unreleased

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
