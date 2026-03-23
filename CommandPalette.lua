---------------------------------------------------
-- MacroForge — Command Palette
-- Searchable command/spell insertion menu
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local CP = {}
local AceGUI

local function G()
    if not AceGUI then AceGUI = LibStub("AceGUI-3.0") end
    return AceGUI
end

local paletteFrame, searchBox, resultScroll
local currentMode = "spells" -- "spells" or "commands"

---------------------------------------------------
-- Data: merge SlashDB + Analyzer commands
---------------------------------------------------
local function GetAllCommands()
    local cmds = {}
    local An = MF:GetModule("Analyzer")
    if An then An:BuildCommandList() end

    -- From SlashDB (categorized)
    local SDB = MF:GetModule("SlashDB")
    if SDB and MF.SlashDB and MF.SlashDB.DB then
        for cmd, cat in pairs(MF.SlashDB.DB) do
            cmds[cmd] = { cmd = cmd, label = cat.label, color = cat.color, source = "slash" }
        end
    end

    return cmds
end

---------------------------------------------------
-- Populate: Commands mode
---------------------------------------------------
local function PopulateCommands(scroll, query)
    local gui = G()
    local q = (query or ""):lower()

    local cmds = GetAllCommands()
    local sorted = {}
    for _, info in pairs(cmds) do table.insert(sorted, info) end
    table.sort(sorted, function(a, b) return a.cmd < b.cmd end)

    local count = 0
    local maxResults = 50

    for _, info in ipairs(sorted) do
        if count >= maxResults then break end
        if q == "" or info.cmd:lower():find(q, 1, true) or (info.label and info.label:lower():find(q, 1, true)) then
            local row = gui:Create("InteractiveLabel")
            row:SetFullWidth(true)
            row:SetText((info.color or MF.C.cyan) .. info.cmd .. "|r  " .. MF.C.grey .. (info.label or "") .. "|r")
            row:SetFontObject(GameFontNormal)
            row:SetCallback("OnClick", function()
                CP:InsertToEditor(info.cmd .. " ")
                if paletteFrame then paletteFrame:Hide() end
            end)
            row:SetCallback("OnEnter", function(w)
                GameTooltip:SetOwner(w.frame, "ANCHOR_RIGHT")
                GameTooltip:AddLine(info.cmd, 0, 0.8, 1)
                GameTooltip:AddLine(format(L["PALETTE_CATEGORY"], info.label or "?"), 0.7, 0.7, 0.7)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cff00ccff" .. L["PALETTE_CLICK_INSERT"] .. "|r")
                GameTooltip:Show()
            end)
            row:SetCallback("OnLeave", function() GameTooltip:Hide() end)
            scroll:AddChild(row)
            count = count + 1
        end
    end

    if count == 0 then
        local lbl = gui:Create("Label")
        lbl:SetFullWidth(true)
        lbl:SetText(MF.C.grey .. format(L["PALETTE_NO_RESULT"], query or "") .. "|r")
        scroll:AddChild(lbl)
    end
end

---------------------------------------------------
-- Populate: Spells mode
---------------------------------------------------
local function PopulateSpells(scroll, query)
    local gui = G()
    local q = (query or ""):lower()
    local count = 0
    local maxResults = 60

    -- Use the centralized spellbook cache from Helpers
    local spells = MF.Helpers:GetSpellbookSpells()
    for _, sp in ipairs(spells) do
        if count >= maxResults then break end
        if q == "" or sp.name:lower():find(q, 1, true) then
            local row = gui:Create("InteractiveLabel")
            row:SetFullWidth(true)
            row:SetText(MF.C.green .. sp.name .. "|r")
            row:SetFontObject(GameFontNormal)
            if sp.icon then
                row:SetImage(sp.icon)
                row:SetImageSize(18, 18)
            end
            row:SetCallback("OnClick", function()
                CP:InsertToEditor(sp.name)
                if paletteFrame then paletteFrame:Hide() end
            end)
            scroll:AddChild(row)
            count = count + 1
        end
    end

    if count == 0 then
        local lbl = gui:Create("Label")
        lbl:SetFullWidth(true)
        lbl:SetText(MF.C.grey .. format(L["PALETTE_NO_RESULT"], query or "") .. "|r")
        scroll:AddChild(lbl)
    end
end

---------------------------------------------------
-- Main populate dispatcher
---------------------------------------------------
local function PopulateResults(scroll, query)
    scroll:ReleaseChildren()
    if currentMode == "commands" then
        PopulateCommands(scroll, query)
    else
        PopulateSpells(scroll, query)
    end
end

---------------------------------------------------
-- Create palette frame
---------------------------------------------------
local function CreatePalette()
    if paletteFrame then return end
    local gui = G()

    local f = gui:Create("Frame")
    f:SetTitle("|cff00ccffMacroForge|r - " .. L["PALETTE_TITLE"])
    f:SetWidth(420)
    f:SetHeight(500)
    f:SetLayout("Flow")
    f:SetCallback("OnClose", function(w) w:Hide() end)
    f:EnableResize(true)
    paletteFrame = f

    -- Dark BG
    local bg = f.frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
    bg:SetPoint("TOPLEFT", f.content, -5, 5)
    bg:SetPoint("BOTTOMRIGHT", f.content, 5, -5)

    -- Search box
    searchBox = gui:Create("EditBox")
    searchBox:SetLabel("|cffffff33" .. L["PALETTE_SEARCH_LABEL"] .. "|r")
    searchBox:SetFullWidth(true)
    searchBox:DisableButton(true)
    searchBox:SetCallback("OnTextChanged", function(w)
        local text = w:GetText()
        if resultScroll then
            PopulateResults(resultScroll, text)
        end
    end)
    f:AddChild(searchBox)

    -- Help label
    local helpLbl = gui:Create("Label")
    helpLbl:SetFullWidth(true)
    helpLbl:SetText(MF.C.grey .. L["PALETTE_SEARCH_HINT"] .. "|r")
    helpLbl:SetFontObject(GameFontNormalSmall)
    f:AddChild(helpLbl)

    -- Results scroll
    resultScroll = gui:Create("ScrollFrame")
    resultScroll:SetFullWidth(true)
    resultScroll:SetFullHeight(true)
    resultScroll:SetLayout("List")
    f:AddChild(resultScroll)

    PopulateResults(resultScroll, "")
    f:Hide()
end

---------------------------------------------------
-- API
---------------------------------------------------
function CP:InsertToEditor(text)
    local E = MF:GetModule("Editor")
    if E and E.InsertText then
        E:InsertText(text)
    end
end

function CP:Open(mode)
    currentMode = mode or "spells"
    CreatePalette()
    -- Update title based on mode
    if currentMode == "commands" then
        paletteFrame:SetTitle("|cff00ccffMacroForge|r - " .. L["PALETTE_TITLE_COMMANDS"])
    else
        paletteFrame:SetTitle("|cff00ccffMacroForge|r - " .. L["PALETTE_TITLE_SPELLS"])
    end
    if searchBox then searchBox:SetText("") end
    if resultScroll then PopulateResults(resultScroll, "") end
    paletteFrame:Show()
    if searchBox then searchBox:SetFocus() end
end

function CP:OpenSpells()
    self:Open("spells")
end

function CP:OpenCommands()
    self:Open("commands")
end

function CP:Toggle(mode)
    if paletteFrame and paletteFrame.frame:IsShown() then
        paletteFrame:Hide()
    else
        self:Open(mode)
    end
end

MF:RegisterModule("CommandPalette", CP)

