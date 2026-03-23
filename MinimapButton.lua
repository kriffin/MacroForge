---------------------------------------------------
-- MacroForge — Minimap Button (Ace3)
-- LibDataBroker + LibDBIcon, position stored in AceDB
---------------------------------------------------
local _, MF_NS = ...
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local MB = {}

function MB:OnInitialize()
    local ldb = LibStub("LibDataBroker-1.1")
    local icon = LibStub("LibDBIcon-1.0")

    local dataObj = ldb:NewDataObject("MacroForge", {
        type = "launcher",
        icon = "Interface\\Icons\\Trade_Engineering",
        OnClick = function(_, button)
            if button == "LeftButton" then
                local UI = MF:GetModule("UI")
                if UI then UI:Toggle() end
            elseif button == "RightButton" then
                MF:Print(MF.C.gold .. "MacroForge|r — /mf help")
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine("|cff00ccffMacro|r|cffffd700Forge|r")
            tt:AddDoubleLine(L["MINIMAP_LEFT"], L["MINIMAP_OPEN"], 0, 0.8, 1, 1, 1, 1)
            tt:AddDoubleLine(L["MINIMAP_RIGHT"], L["MINIMAP_HELP"], 1, 0.6, 0, 1, 1, 1)
            tt:AddLine(" ")
            local na, nc = GetNumMacros()
            tt:AddLine(format(L["MACROS_COUNT"], nc, na), 0.7, 0.7, 0.7)
        end,
    })

    -- Use AceDB global namespace for minimap position
    icon:Register("MacroForge", dataObj, MF.db.global.minimap)
end

MF:RegisterModule("MinimapButton", MB)
