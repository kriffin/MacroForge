---------------------------------------------------
-- MacroForge — Locale: English (default)
---------------------------------------------------
local L = LibStub("AceLocale-3.0"):NewLocale("MacroForge", "enUS", true)
if not L then return end

-- General
L["ADDON_LOADED"] = "MacroForge v%s - %s"
L["UNKNOWN_CMD"] = "Unknown command: %s - /mf help"
L["OPEN_MACRO_FIRST"] = "Open a macro first to see its history."

-- Settings headers
L["GENERAL"] = "General"
L["EDITOR"] = "Editor"
L["BACKUPS"] = "Backups"
L["DATA"] = "Data"

-- Settings labels
L["OPT_AUTOSWAP"] = "Auto-swap profiles on specialization change"
L["OPT_AUTOCOMPLETE"] = "Autocomplete in editor (spells, commands, conditions)"
L["OPT_SYNTAX_COLORS"] = "Syntax highlighting in editor"
L["OPT_AUTOSAVE_DRAFT"] = "Auto-save drafts"
L["OPT_SOUND"] = "Sound effects (save, undo/redo...)"
L["OPT_MINIMAP"] = "Show minimap button"
L["OPT_FONTSIZE"] = "Editor font size"
L["OPT_FONT"] = "Editor font"
L["OPT_MAX_BACKUPS"] = "Maximum number of backups"
L["OPT_MAX_HISTORY"] = "Number of history versions"

-- Profiles
L["PROFILE_SAVED"] = "Profile saved"
L["PROFILE_LOADED"] = "Profile loaded"
L["PROFILE_NO_SPEC"] = "Cannot detect specialization."
L["PROFILE_NONE"] = "No profile for %s. Use /mf save."
L["PROFILE_AUTOSWAP"] = "Auto-swap"
L["AUTOSWAP_ON"] = "Auto-swap: enabled"
L["AUTOSWAP_OFF"] = "Auto-swap: disabled"
L["NO_MACROS_TO_LOAD"] = "No macros to load."

-- Backup
L["BACKUP_CREATED"] = "Backup created"
L["BACKUP_RESTORED"] = "Backup restored from %s"
L["BACKUP_NOT_FOUND"] = "Backup #%d not found."

-- Macros
L["MACRO_CREATED"] = "Macro created: %s"
L["MACRO_DELETED"] = "Macro deleted: %s"
L["MACRO_LIMIT_CHAR"] = "Limit reached: %d/18 character macros."
L["MACRO_LIMIT_ACCOUNT"] = "Limit reached: %d/120 account macros."
L["MACROS_PERSO"] = "character"
L["MACROS_COMPTE"] = "account"
L["PERSO_TAB"] = "Character (%d/18)"
L["COMPTE_TAB"] = "Account (%d/120)"

-- UI
L["NO_MACRO"] = "No macros."
L["SEARCH"] = "Search"
L["CLEAR"] = "Clear"
L["CREATE"] = "Create"
L["IMPORT"] = "Import"
L["EDIT"] = "Edit"
L["DUPLICATE"] = "Duplicate"
L["EXPORT"] = "Export"
L["DRAG_ACTIONBAR"] = "Drag to action bar"
L["DELETE"] = "Delete"

-- Editor
L["MACRO_NAME_LABEL"] = "Macro name (max 16 chars)"
L["MACRO_BODY_LABEL"] = "Macro body (max 255 chars)"
L["SAVE"] = "Save"
L["COPY"] = "Copy"
L["CANCEL"] = "Cancel"
L["SHORTEN"] = "Shorten"
L["INSERT_SPELL"] = "+ Insert spell"
L["INSERT_SNIPPET"] = "Insert snippet..."
L["NEW_MACRO"] = "+ New macro"
L["SAVE_FIRST_DRAG"] = "Save first before dragging."
L["SAVED"] = "Saved!"
L["SAVED_DETAIL"] = "%s saved (%d/255 chars)"
L["SHORTENED"] = "Shortened: %d character(s) saved"
L["ALREADY_OPTIMIZED"] = "Already optimized."
L["DRAFT_RESTORED"] = "Draft restored!"
L["DRAFT_DIALOG"] = "|cff00ccffMacroForge|r\n\nAn unsaved draft was found.\nRestore?"
L["RESTORE"] = "Restore"
L["IGNORE"] = "Ignore"

-- History
L["HISTORY"] = "History"
L["NO_HISTORY"] = "No history for this macro."
L["VERSION_RESTORED"] = "Version #%d restored!"
L["CHARS"] = "%d/255 characters"

-- Share
L["SHARE"] = "Share"
L["SHARE_EXPORT_TITLE"] = "Export (Share)"
L["SHARE_IMPORT_TITLE"] = "Import (Share)"
L["SHARE_COPY_HELP"] = "Copy the code below and send it to a friend."
L["SHARE_IMPORT_HELP"] = "They can import with /mf import or the Import button."
L["SHARE_PASTE_HELP"] = "Paste a MF7: code received from another player."
L["SHARE_CODE_LABEL"] = "Share code:"
L["SHARE_OPEN_EDITOR"] = "Open in editor"
L["SHARE_CREATE_DIRECT"] = "Create directly"
L["SHARE_NO_DECODED"] = "No decoded macro."
L["SHARE_IMPORTED"] = "Macro imported: %s"
L["SHARE_INVALID"] = "Invalid format"
L["SHARE_NOT_MF"] = "Invalid format (not a MacroForge code)"
L["SHARE_DECODE_FAIL"] = "Decoding failed"
L["SHARE_BAD_STRUCT"] = "Invalid structure"
L["SHARE_PREVIEW"] = "(paste a code above)"

-- Share - direct send via AceComm
L["SEND_MACRO"] = "Send macro"
L["SEND_TARGET"] = "Target player name:"
L["SEND_SUCCESS"] = "Macro sent to %s!"
L["SEND_NO_TARGET"] = "Enter a player name."
L["RECV_MACRO"] = "Macro received from %s: %s"
L["RECV_ACCEPT"] = "Accept"
L["RECV_DECLINE"] = "Decline"
L["RECV_DIALOG"] = "|cff00ccffMacroForge|r\n\n%s sent you a macro:\n|cffffff00%s|r\n\nAccept?"

-- Duplicates
L["DUPLICATES"] = "Duplicates"
L["DETECT_DUPLICATES"] = "Detect duplicates"
L["NO_DUPLICATES"] = "No duplicates found."

-- Templates
L["TEMPLATES"] = "Templates"

-- Builder
L["BUILDER"] = "Condition Builder"

-- Commands
L["COMMANDS"] = "Command Palette"

-- Tools
L["TOOLS"] = "Tools"
L["TOOLS_BUILDER_DESC"] = "Visually build conditions [mod:shift, @focus, harm...]"
L["TOOLS_TEMPLATES_DESC"] = "Ready-to-use macros by role and specialization"
L["TOOLS_HISTORY_DESC"] = "View and restore previous versions of this macro"
L["TOOLS_DUPES_DESC"] = "Scan all your macros for duplicates"

-- Analysis
L["ANALYSIS_HEADING"] = "Analysis & Explanation"
L["ANALYSIS_HINT"] = "Real-time analysis. Hover to see spell tooltips."
L["SPELLS_HEADING"] = "Detected Spells & Items"
L["SPELLS_HINT"] = "Hover an icon to see the Blizzard spell/item tooltip."

-- File section
L["FILE"] = "File"
L["DRAG"] = "Drag to bar"
L["COPY_MACRO"] = "Copy macro"
L["COPY_HELP"] = "Ctrl+C to copy, then paste wherever you want."
L["IMPORT_MACRO"] = "Import a macro"
L["PASTE_HERE"] = "Paste macro text here:"
L["IMPORT_SUCCESS"] = "Macro imported!"
L["EXPORT_MACRO"] = "Export macro"
L["COPY_BELOW"] = "Copy the text below:"

-- Settings data
L["MACROS_COUNT"] = "Macros: %d/18 character, %d/120 account"
L["PROFILES_COUNT"] = "Profiles: %d — Backups: %d"
L["PURGE_HISTORY"] = "Purge history"
L["PURGE_DRAFTS"] = "Purge drafts"
L["HISTORY_PURGED"] = "History purged."
L["DRAFTS_PURGED"] = "Drafts purged."

-- Minimap
L["MINIMAP_LEFT"] = "Left-click"
L["MINIMAP_RIGHT"] = "Right-click"
L["MINIMAP_OPEN"] = "Open"
L["MINIMAP_HELP"] = "Help"

-- Keybindings
L["BINDING_TOGGLE"] = "Open/Close MacroForge"
L["BINDING_BUILDER"] = "Condition Builder"
L["BINDING_COMMANDS"] = "Command Palette"

-- Slash help
L["HELP_TITLE"] = "=== MacroForge v%s ==="
L["HELP_SHOW"] = "Open/Close"
L["HELP_SAVE"] = "Save profile"
L["HELP_LOAD"] = "Load profile"
L["HELP_BACKUP"] = "Backup"
L["HELP_RESTORE"] = "Restore"
L["HELP_AUTOSWAP"] = "Toggle auto-swap"
L["HELP_ANALYZE"] = "Analyze macros"
L["HELP_BUILDER"] = "Condition Builder"
L["HELP_COMMANDS"] = "Command palette"
L["HELP_TEMPLATES"] = "Browse templates"
L["HELP_SHARE"] = "Share / import macro"
L["HELP_IMPORT"] = "Import a shared code"
L["HELP_EXPORT"] = "Export macro"
L["HELP_DUPLICATES"] = "Detect duplicates"
L["HELP_HISTORY"] = "History of current macro"
L["HELP_SETTINGS"] = "Addon settings"
L["HELP_SHORTCUTS"] = "Shortcuts: Ctrl+S save, Ctrl+Z undo, Ctrl+Y redo"

-- Click tooltips
L["CLICK_EDIT"] = "|cff00ccffClick|r edit"
L["CLICK_SHIFT_DRAG"] = "|cffff9933Shift+Click|r drag"
L["CLICK_RIGHT_MENU"] = "|cff888888Right-click|r menu"
L["QUALITY"] = "Quality: %d%% (syntax, spells, length)"

-- Editor UI
L["EDITOR_TITLE"] = "Editor"
L["TOOLS_HEADING"] = "Tools"
L["CONDITION_BUILDER"] = "Condition Builder"
L["CONDITION_BUILDER_DESC"] = "Visually build conditions [mod:shift, @focus, harm...]"
L["TEMPLATES_BTN"] = "Templates"
L["TEMPLATES_DESC"] = "Ready-to-use macros by role and specialization"
L["HISTORY_BTN"] = "History"
L["HISTORY_DESC"] = "View and restore previous versions of this macro"
L["DETECT_DUPES_BTN"] = "Detect duplicates"
L["DETECT_DUPES_DESC"] = "Scan all your macros for duplicates"
L["INSERT_SNIPPET_LABEL"] = "Insert snippet..."
L["FONT_SIZE"] = "Font size"
L["FILE_HEADING"] = "File"
L["ANALYSIS_LIVE_HINT"] = "Real-time analysis. Hover to see spell tooltips."
L["SPELL_ICON_HINT"] = "Hover an icon to see the Blizzard spell/item tooltip."
L["EMPTY_NAME"] = "Name is empty!"
L["MISSING_INDEX"] = "Missing index!"
L["NOTHING_TO_UNDO"] = "Nothing to undo."
L["NOTHING_TO_REDO"] = "Nothing to redo."
L["SAVE_FIRST"] = "Save first."
L["DRAG_SAVE_FIRST"] = "Save first before dragging."
L["COPY_MACRO_TITLE"] = "Copy macro"
L["COPY_HELP_MSG"] = "Ctrl+C to copy, then paste wherever you want."
L["MACRO_IMPORTED"] = "Macro imported!"
L["COPY_BELOW_MSG"] = "Copy the text below:"
L["ALREADY_OPTIMIZED"] = "Already optimized."
L["SHORTENED_MSG"] = "Shortened: %d character(s) saved"
L["DRAFT_FOUND"] = "|cff00ccffMacroForge|r\n\nAn unsaved draft was found.\nRestore?"
L["DRAFT_RESTORED_MSG"] = "Draft restored!"
L["SLOT_N"] = "Slot %d"
L["SLOT_LABEL"] = "Slot"
L["CHARACTER_SCOPE"] = "Character"
L["ACCOUNT_SCOPE"] = "Account"
L["NEW_MACRO_TITLE"] = "+ New macro"
L["SAVE_BTN"] = "Save"
L["COPY_BTN"] = "Copy"
L["IMPORT_BTN"] = "Import"
L["EXPORT_BTN"] = "Export"
L["CANCEL_BTN"] = "Cancel"
L["SHORTEN_BTN"] = "Shorten"
L["INSERT_SPELL_BTN"] = "+ Insert spell"
L["DRAG_TO_BAR_BTN"] = "Drag to bar"
L["RESTORE_BTN"] = "Restore"
L["IGNORE_BTN"] = "Ignore"
L["DETECTED_SPELLS_HEADING"] = "Detected Spells & Items"
L["IMPORT_MACRO_TITLE"] = "Import a macro"
L["EXPORT_MACRO_TITLE"] = "Export macro"
L["PASTE_MACRO_TEXT_LABEL"] = "Paste macro text here:"
L["COPY_BELOW_LABEL"] = "Copy the text below:"
L["MACRO_SAVED"] = "Saved: %s"
L["MACRO_BODY_LABEL_COUNT"] = "|cffffff99Macro body|r  %s%d/255|r"
L["AND_MORE_ISSUES"] = "... and %d more"
L["FIX_SUGGESTION"] = "-> %s"
L["CHECK_GRIMOIRE_HINT"] = "(check spellbook)"
L["DUPLICATE_DETECTOR_BTN"] = "Detect duplicates"
L["DUPLICATE_DETECTOR_DESC"] = "Scan all your macros for duplicates"

-- Delete confirmation
L["DELETE_CONFIRM"] = "|cff00ccffMacroForge|r\n\nDelete macro |cffffff00%s|r?\nThis cannot be undone."
L["DELETE_YES"] = "Delete"
L["DELETE_NO"] = "Cancel"
L["RESET"] = "Reset"

-- Builder
L["BUILDER_TITLE"] = "Condition Builder"
L["BUILDER_HEADING"] = "Condition Composer"
L["BUILDER_TARGET_LABEL"] = "Target (@target)"
L["BUILDER_CONDITIONS_LABEL"] = "Conditions"
L["BUILDER_INSERT"] = "Insert into editor"
L["BUILDER_PREVIEW"] = "Preview"
L["BUILDER_EMPTY"] = "(empty)"

-- IconPicker
L["ICON_PICKER_TITLE"] = "Icons"
L["ICON_SEARCH"] = "Search"
L["ICON_CLICK_SELECT"] = "Click to select"
L["ICON_NONE_FOUND"] = "No icons found."

-- SlashDB categories
L["CAT_COMBAT"] = "Combat"
L["CAT_TARGET"] = "Targeting"
L["CAT_PET"] = "Pet"
L["CAT_CHAT"] = "Chat"
L["CAT_CHAR"] = "Character"
L["CAT_GUILD"] = "Guild"
L["CAT_PARTY"] = "Party/Raid"
L["CAT_SYSTEM"] = "System"
L["CAT_PVP"] = "PvP"
L["CAT_BATTLEPET"] = "Battle Pet"
L["CAT_UI"] = "Interface"

-- DuplicateDetector
L["DUPES_TITLE"] = "Duplicates detected"
L["DUPES_NONE"] = "No duplicates! All your macros are unique."
L["DUPES_GROUPS"] = "%d group(s) of duplicates found (%d extra macros)"
L["DUPES_GROUP_N"] = "Group %d"
L["DUPES_IDENTICAL"] = "%d identical macros"
L["DUPES_KEEP"] = "(keep)"
L["DUPES_DELETED"] = "Deleted: %s"

-- CommandPalette
L["PALETTE_TITLE"] = "Commands & Spells"
L["PALETTE_SEARCH_LABEL"] = "Search (command or spell)"
L["PALETTE_SEARCH_HINT"] = "Type / to filter commands, or a spell/item name."
L["PALETTE_SLASH_HEADING"] = "Slash Commands"
L["PALETTE_SPELL_HEADING"] = "Spells / Items"
L["PALETTE_NO_RESULT"] = "No result for: %s"
L["PALETTE_CATEGORY"] = "Category: %s"
L["PALETTE_CLICK_INSERT"] = "Click to insert"
L["PALETTE_TITLE_SPELLS"] = "Spells & Items"
L["PALETTE_TITLE_COMMANDS"] = "Slash Commands"
L["INSERT_CMD_BTN"] = "+ Insert command"
