# WoW Macro Syntax Reference

> **Source**: [Secure Command Options](https://warcraft.wiki.gg/wiki/Secure_command_options), [Macro Conditionals](https://warcraft.wiki.gg/wiki/Macro_conditionals), [Making a Macro](https://warcraft.wiki.gg/wiki/Making_a_macro)
> **Last Updated**: 2026-03-23

## EBNF Grammar (Official)

```ebnf
command          = "/" command-verb [ {command-object ";"} command-object ]
command-verb     = <any secure command word>
command-object   = { condition } parameters
parameters       = <anything passed to the command word>
condition        = "[" condition-phrase { "," condition-phrase } "]"
condition-phrase = ([ "no" ] option-word [ ":" option-argument { "/" option-argument } ]
                 | "@" target)
option-argument  = <any one-word option: 'shift', 'ctrl', 'target', '1', '2', etc.>
target           = <a target pattern: player, focus, mouseover, party1, etc.>
```

## Structure Overview

```
/command [conditions] spell; [conditions] spell2; default_spell
│        │           │     │                    │
│        │           │     └── semicolons separate clauses (ELSE IF)
│        │           └── clause value (spell/item name)
│        └── zero or more condition sets in brackets
└── secure command verb (/cast, /use, etc.)
```

## Delimiter Rules

| Character | Role | Where | Example |
|-----------|------|-------|---------|
| `;` | Clause separator (ELSE) | Between `]spell` groups | `[mod:shift] Heal; [nomod] Flash Heal` |
| `,` | AND within conditions | Inside `[...]` | `[help,nodead,@focus]` |
| `:` | Condition parameter | Inside `[...]` | `[mod:shift]`, `[stance:1]`, `[spec:2]` |
| `/` | OR between parameters | Inside `[...]` after `:` | `[mod:shift/ctrl]`, `[stance:1/2]` |
| `@` | Target specification | Inside `[...]` | `[@mouseover]`, `[@focus]` |
| `[ ]` | Condition boundary | Enclose conditions | `[help,nodead]` |

## Space Rules

### Safe to Remove (Confirmed by Wiki)

| Rule | Before | After | Why Safe |
|------|--------|-------|----------|
| Spaces **inside** `[...]` | `[ mod:shift , @player ]` | `[mod:shift,@player]` | The WoW parser ignores whitespace within brackets |
| Space after `]` before spell | `[mod:shift] Heal` | `[mod:shift]Heal` | Confirmed working in-game |
| Spaces around `;` | `Heal ; Flash Heal` | `Heal;Flash Heal` | Semicolons are unambiguous clause delimiters |
| Multiple spaces → single | `spell1  spell2` | `spell1 spell2` | Redundant whitespace |
| Trailing whitespace | `line   ` | `line` | Never meaningful |

### UNSAFE to Remove (Outside Brackets)

| Rule | Example | Risk |
|------|---------|------|
| Space between command and `[` | `/use [mod:shift]` → `/use[mod:shift]` | **Breaks in-game** — the command parser requires a space before `[` |
| Spaces around `:` globally | `Mot de l'ombre : Douleur` → broken | Colons appear in spell names (e.g. "Shadow Word: Pain") |
| Spaces around `,` globally | `/say Hello, World` → broken | Commas appear in chat text and `/castsequence` spell lists |
| Spaces around `=` globally | `/run x = 5` → broken | Equals signs appear in `/run`, `/script` commands, and `reset=target` |
| Space after `]` before spell | `[mod:shift] Heal` → `[mod:shift]Heal` | May work but undocumented; risky |

## Secure Commands (Accept Conditions)

These commands support `[conditions]` syntax:

```
#show          #showtooltip    /assist        /cancelaura
/cancelform    /cast           /castrandom    /castsequence
/changeactionbar /clearfocus   /cleartarget   /click
/dismount      /equip          /equipslot     /equipset
/focus         /petassist      /petattack     /petautocastoff
/petautocaston /petdefensive   /petfollow     /petpassive
/petstay       /startattack    /stopattack    /stopcasting
/stopmacro     /swapactionbar  /target        /targetexact
/targetenemy   /targetfriend   /targetfriendplayer
/targetenemyplayer /targetlasttarget /targetlastfriend
/targetlastenemy   /targetparty     /targetraid
/use           /userandom
```

> **Important**: Insecure commands (`/say`, `/emote`, `/whisper`, etc.) do NOT process conditions.
> Semicolons in `/say` are literal text, NOT clause separators.

## Command Aliases (Shortest Forms)

| Full Command | Shortest | Saves |
|-------------|----------|-------|
| `/castsequence` | `/castse` | 6 chars |
| `/cancelaura` | `/cancelau` | 2 chars |
| `/cancelform` | `/cancelf` | 3 chars |
| `/startattack` | `/starta` | 5 chars |
| `/stopattack` | `/stopa` | 5 chars |
| `/stopcasting` | `/stopc` | 6 chars |
| `/stopmacro` | `/stopm` | 4 chars |
| `/dismount` | `/dism` | 4 chars |
| `/targetenemy` | `/targete` | 4 chars |
| `/targetfriend` | `/targetf` | 5 chars |

## Macro Conditionals (Complete List)

### Temporary Targeting
- `@unit` or `target=unit` — Cast on specified unit without changing target
- Units: `player`, `target`, `targettarget`, `focus`, `focustarget`, `mouseover`, `pet`, `arena1-3`, `party1-4`, `cursor`, `none`

### Boolean Conditions (most support `no` prefix)

| Condition | Parameter | Description |
|-----------|-----------|-------------|
| `exists` | — | Target exists |
| `help` | — | Target is friendly (implies exists) |
| `harm` | — | Target is hostile (implies exists) |
| `dead` | — | Target is dead |
| `party` | — | Target in your party |
| `raid` | — | Target in your raid |
| `combat` | — | You are in combat |
| `stealth` | — | You are stealthed |
| `mounted` | — | You are mounted |
| `flying` | — | You are flying |
| `flyable` | — | Area allows flying (old) |
| `advflyable` | — | Area allows Skyriding |
| `swimming` | — | You are swimming |
| `indoors` | — | You are indoors |
| `outdoors` | — | You are outdoors |
| `mod` / `modifier` | `:shift/ctrl/alt` | Modifier key held |
| `btn` / `button` | `:1/2/3/4/5` | Mouse button clicked |
| `stance` / `form` | `:0/1/2/3/4` | Current stance/form |
| `spec` | `:1/2/3/4` | Current specialization |
| `talent` | `:row/col` | Talent selected |
| `pvptalent` | `:id` | PvP talent active |
| `known` | `:spell` | Spell is known |
| `equipped` / `worn` | `:type` | Item type equipped |
| `channeling` | `:spell` | Currently channeling |
| `actionbar` / `bar` | `:1-6` | Current action bar page |
| `bonusbar` | `:1-5` | Bonus bar active |
| `extrabar` | — | Extra action bar visible |
| `overridebar` | — | Override bar visible |
| `possessbar` | — | Possess bar visible |
| `vehicleui` | — | In vehicle with UI |
| `canexitvehicle` | — | Can exit vehicle |
| `cursor` | — | Cursor has item/spell |
| `group` | `:party/raid` | In a group |
| `petbattle` | — | In pet battle |
| `resting` | — | In resting area |

## ShortenMacro Implementation Rules

Based on the above, our `ShortenMacro` function applies these optimizations:

### Always Applied (All Lines)
1. **Shorten command verbs** to their shortest alias
2. **Collapse multiple spaces to one**
3. **Strip trailing whitespace** per line and end of macro

### Applied ONLY to Secure Commands + `#show`/`#showtooltip`
4. **Compress all whitespace inside `[...]`** — colons, commas, equals, slashes, spaces
5. **Remove space between `]` and spell name** — `] Heal` → `]Heal` (confirmed in-game)
6. **Remove spaces around `;`** — clause separators

> [!IMPORTANT]
> Insecure commands (`/say`, `/emote`, `/whisper`, `/guild`, etc.) are **never** processed
> for condition-specific rules. This prevents breaking literal `;` `,` `:` in chat text.

### NOT Applied (Unsafe)
- **Removing space between command and `[`** — `/cast [mod]` → `/cast[mod]` — **breaks in-game**
- Removing `:` `,` `=` `/` spaces **outside** brackets
- Any modification to non-command text (`/say`, `/emote`, `/script` body)
