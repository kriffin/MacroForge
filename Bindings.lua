---------------------------------------------------
-- MacroForge — Bindings (Ace3)
-- Keybinding support + global functions + localized names
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")

-- Binding header name (shown in WoW Key Bindings UI)
BINDING_HEADER_MACROFORGE = "|cff00ccffMacroForge|r"
BINDING_NAME_MACROFORGE_TOGGLE = L["BINDING_TOGGLE"]
BINDING_NAME_MACROFORGE_BUILDER = L["BINDING_BUILDER"]
BINDING_NAME_MACROFORGE_COMMANDS = L["BINDING_COMMANDS"]

-- Global functions referenced by Bindings.xml
function MacroForge_Toggle()
    local UI = MF:GetModule("UI")
    if UI then UI:Toggle() end
end

function MacroForge_Builder()
    local B = MF:GetModule("Builder")
    if B then B:Toggle() end
end

function MacroForge_Commands()
    local CP = MF:GetModule("CommandPalette")
    if CP then CP:Toggle() end
end
