---------------------------------------------------
-- MacroForge — Duplicate Detector
-- Find duplicate or near-identical macros
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local Detector = {}
local AceGUI

local function G()
    if not AceGUI then AceGUI = LibStub("AceGUI-3.0") end
    return AceGUI
end

---------------------------------------------------
-- Normalize body for comparison (trim whitespace, lowercase)
---------------------------------------------------
local function Normalize(body)
    if not body then return "" end
    return body:gsub("%s+", " "):lower():match("^%s*(.-)%s*$") or ""
end

---------------------------------------------------
-- Find duplicate groups
---------------------------------------------------
function Detector:FindDuplicates()
    local P = MF:GetModule("Profiles")
    if not P then return {} end

    local charMacros = P:ReadCharacterMacros()
    local acctMacros = P:ReadAccountMacros()
    local all = {}

    for _, m in ipairs(charMacros) do
        m._scope = "character"
        table.insert(all, m)
    end
    for _, m in ipairs(acctMacros) do
        m._scope = "account"
        table.insert(all, m)
    end

    -- Group by normalized body
    local groups = {}
    for _, m in ipairs(all) do
        local key = Normalize(m.body)
        if key ~= "" then
            groups[key] = groups[key] or {}
            table.insert(groups[key], m)
        end
    end

    -- Filter to only groups with 2+ macros
    local dupes = {}
    for _, group in pairs(groups) do
        if #group >= 2 then
            table.insert(dupes, group)
        end
    end

    return dupes
end

---------------------------------------------------
-- Duplicate Browser UI
---------------------------------------------------
function Detector:OpenBrowser()
    local gui = G()
    local dupes = self:FindDuplicates()

    local f = gui:Create("Frame")
    f:SetTitle("|cff00ccffMacroForge|r - " .. L["DUPES_TITLE"])
    f:SetWidth(520)
    f:SetHeight(400)
    f:SetLayout("Fill")
    f:SetCallback("OnClose", function(w) w:Release() end)

    local scroll = gui:Create("ScrollFrame")
    scroll:SetLayout("List")
    f:AddChild(scroll)

    if #dupes == 0 then
        local lbl = gui:Create("Label")
        lbl:SetFullWidth(true)
        lbl:SetFontObject(GameFontNormal)
        lbl:SetText(MF.C.green .. L["DUPES_NONE"] .. "|r")
        scroll:AddChild(lbl)
        f:Show()
        return
    end

    local totalDupes = 0
    for _, group in ipairs(dupes) do
        totalDupes = totalDupes + #group - 1
    end

    local summary = gui:Create("Label")
    summary:SetFullWidth(true)
    summary:SetFontObject(GameFontNormal)
    summary:SetText(MF.C.yellow .. format(L["DUPES_GROUPS"], #dupes, totalDupes) .. "|r")
    scroll:AddChild(summary)

    local An = MF:GetModule("Analyzer")

    for gi, group in ipairs(dupes) do
        local grp = gui:Create("InlineGroup")
        grp:SetFullWidth(true)
        grp:SetTitle(MF.C.gold .. format(L["DUPES_GROUP_N"], gi) .. "|r — " .. format(L["DUPES_IDENTICAL"], #group))
        grp:SetLayout("List")

        -- Show shared body preview
        local previewLbl = gui:Create("Label")
        previewLbl:SetFullWidth(true)
        previewLbl:SetFontObject(GameFontNormalSmall)
        local colored = An and An:ColorizeBody(group[1].body) or group[1].body
        previewLbl:SetText(colored)
        grp:AddChild(previewLbl)

        for mi, macro in ipairs(group) do
            local row = gui:Create("SimpleGroup")
            row:SetFullWidth(true)
            row:SetLayout("Flow")

            local scope = macro._scope == "character" and MF.C.cyan .. "[" .. L["MACROS_PERSO"] .. "]" or MF.C.yellow .. "[" .. L["MACROS_COMPTE"] .. "]"
            local info = gui:Create("Label")
            info:SetWidth(280)
            info:SetFontObject(GameFontNormal)
            info:SetText(scope .. "|r " .. MF.C.white .. (macro.name or "(Sans nom)") .. "|r " ..
                MF.C.grey .. "#" .. (macro.index or "?") .. "|r")
            row:AddChild(info)

            -- Only show delete button for non-first entry in group
            if mi > 1 then
                local btnDel = gui:Create("Button")
                btnDel:SetText(L["DELETE"])
                btnDel:SetWidth(90)
                btnDel:SetCallback("OnClick", function()
                    StaticPopupDialogs["MACROFORGE_DUPE_DELETE"] = {
                        text = format(L["DELETE_CONFIRM"], macro.name or "?"),
                        button1 = L["DELETE_YES"],
                        button2 = L["DELETE_NO"],
                        OnAccept = function()
                            local P = MF:GetModule("Profiles")
                            if P and macro.index then
                                P:DeleteMacroByIndex(macro.index)
                                MF.Helpers:Print(MF.C.red .. format(L["DUPES_DELETED"], macro.name or "") .. "|r")
                                f:Release()
                                C_Timer.After(0.3, function() Detector:OpenBrowser() end)
                            end
                        end,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                        preferredIndex = 3,
                    }
                    StaticPopup_Show("MACROFORGE_DUPE_DELETE")
                end)
                row:AddChild(btnDel)
            else
                local keepLbl = gui:Create("Label")
                keepLbl:SetWidth(90)
                keepLbl:SetFontObject(GameFontNormalSmall)
                keepLbl:SetText(MF.C.green .. L["DUPES_KEEP"] .. "|r")
                row:AddChild(keepLbl)
            end

            grp:AddChild(row)
        end

        scroll:AddChild(grp)
    end

    f:Show()
end

MF:RegisterModule("DuplicateDetector", Detector)
