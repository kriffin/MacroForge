# Screenshots to capture (7.4)

For the CurseForge page (docs/CURSEFORGE.md) and the README. In game:
UI scale 1.0, interface at 2560x1440 or 1920x1080, a character with about
10 macros. Hide the chat and the other windows. Take the screenshot with
Print Screen; files go to `_classic_beta_/Screenshots/`.

Claude can take them itself through the dev bridge (tools/bridge.sh): a query
binds one key per scene, xdotool presses them and `import` captures the WoW
window; the crops go to `docs/assets/shots/`. Sets, Trash and the right-click
menu still use the 7.2 captures (no set or deleted macro on the test
character; the context menu is left alone after the MenuUtil crash).

| File | What to show |
|---|---|
| `window.png` | `/mf`, Macros tab, a macro open with one mistyped command: the issue and its green "Fix" row visible |
| `editor.png` | Close-up of the editor with the live Test on (button reads "Stop test", result under the analysis) |
| `templates.png` | Templates page, another class picked in the Class button, one template selected |
| `news.png` | The What's new page (? button) |
| `sets.png` | Sets tab, one set selected, bound to 2 specs, `[active]` badge visible |
| `trash.png` | Trash tab with 2-3 deleted macros, one selected (Recreate / Versions) |
| `macroframe.png` | Blizzard's `/macro` window with the MacroForge button next to Delete |
| `menu.png` | Right-click menu on a macro in the list |
| `drawer.png` | Editor with the icon drawer open (the macro's own icons on top) |
