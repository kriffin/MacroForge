-- WoW addon: the client provides the globals, and the embedded libraries
-- are third-party code.
std = "lua51"
max_line_length = false
exclude_files = { "Libs/", "tests/" }
ignore = { "212", "213", "542" }  -- unused args, unused loop vars, empty if
globals = { "MacroForge", "MacroForgeDB", "MacroForgeLog", "SLASH_MACROFORGE1", "BINDING_HEADER_MACROFORGE" }
read_globals = {
  -- Lua-ish helpers WoW adds
  "format", "strsplit", "strjoin", "strtrim", "wipe", "tinsert", "tremove", "date", "time", "print",
  "geterrorhandler", "hooksecurefunc", "securecallfunction", "issecurevariable",
  -- API used by the addon
  "CreateFrame", "UIParent", "GameTooltip", "GameTooltip_Hide", "GameFontNormal", "GameFontNormalLarge",
  "GameFontNormalSmall", "GameFontHighlight", "GameFontHighlightSmall", "GameFontDisable",
  "GameFontDisableLarge", "GameFontDisableSmall", "UISpecialFrames", "StaticPopupDialogs",
  "StaticPopup_Show", "StaticPopup_Visible", "PlaySound", "SOUNDKIT", "MenuUtil", "HelpTip",
  "ScrollUtil", "ScrollBoxConstants", "CreateTreeDataProvider", "CreateScrollBoxListTreeListView",
  "PanelTemplates_SetTab", "PanelTemplates_SetNumTabs", "PanelTemplates_TabResize",
  "GetMacroInfo", "GetNumMacros", "CreateMacro", "EditMacro", "DeleteMacro", "PickupMacro",
  "GetMacroSpell", "GetMacroItem", "GetActionInfo", "SecureCmdOptionParse", "InCombatLockdown",
  "GetCurrentKeyBoardFocus", "GetSpecializationInfoByID", "GetNumSpecializations",
  "GetSpecialization", "GetSpecializationInfo", "GetActiveSpecGroup", "GetActiveTalentGroup",
  "UnitClass", "UnitName", "UnitFullName", "GetRealmName", "GetBuildInfo", "GetAddOnMetadata",
  "C_Timer", "C_Spell", "C_Item", "C_SpellBook", "C_AddOns", "C_Texture", "C_SpecializationInfo",
  "Enum", "Constants", "Settings", "InterfaceOptionsFrame_OpenToCategory", "ChatFrameUtil",
  "ChatEdit_InsertLink", "GetCursorInfo", "ClearCursor", "SetDesaturation", "IsControlKeyDown",
  "IsShiftKeyDown", "LibStub", "YES", "NO", "OKAY", "ACCEPT", "CANCEL", "SETTINGS", "DELETE",
  "GetItemInfo", "MAX_ACCOUNT_MACROS", "MAX_CHARACTER_MACROS",
  "MacroFrame", "MacroDeleteButton", "HideUIPanel", "EventUtil",
  "CreateScrollBoxListLinearView", "CreateDataProvider", "BACK", "LOCALIZED_CLASS_NAMES_MALE",
}
