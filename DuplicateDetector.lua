---------------------------------------------------
-- MacroForge — Duplicate Detector
-- Find duplicate or near-identical macros
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local Detector = {}

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
-- Duplicates page (main window): groups on the left, the selected group
-- on the right with its code and one row per copy (keep the first one)
---------------------------------------------------
StaticPopupDialogs["MACROFORGE_DUPE_DELETE"] = {
    text = L["DELETE_CONFIRM"],
    button1 = L["DELETE_YES"],
    button2 = L["DELETE_NO"],
    OnAccept = function(_, macro)
        local P = MF:GetModule("Profiles")
        if P and macro.index and P:DeleteMacroByIndex(macro.index) then
            MF:Notify(MF.C.red .. format(L["DUPES_DELETED"], macro.name or "") .. "|r")
        end
        C_Timer.After(0.3, function()
            MF:GetModule("UI"):Refresh()
            if Detector.page then Detector.page.Fill() end
        end)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local MAX_COPIES_SHOWN = 8

local function BuildPage(page)
    local W = MF.Widgets
    local summary = W:Text(page, "GameFontNormal")
    summary:SetPoint("TOPLEFT", 4, -4)
    local list, card = W:ListAndCard(page, {
        icon = function(group) local m = group[1]; return (m.icon and m.icon ~= 0) and m.icon or 134400 end,
        name = function(group) return group[1].name:match("^%s*$") and L["MACRO_UNNAMED"] or group[1].name end,
        sub = function(group) return format(L["DUPES_IDENTICAL"], #group) end,
        onSelect = function(group) page.ShowGroup(group) end,
        empty = L["DUPES_NONE"],
    }, 26)

    local preview = W:Text(card, "GameFontHighlight")
    preview:SetPoint("TOPLEFT", 14, -14)
    preview:SetPoint("RIGHT", card, "RIGHT", -14, 0)
    preview:SetJustifyV("TOP")
    local copies = {}
    for i = 1, MAX_COPIES_SHOWN do
        local row = CreateFrame("Frame", nil, card)
        row:SetHeight(24)
        row:SetPoint("LEFT", 14, 0)
        row:SetPoint("RIGHT", -14, 0)
        if i == 1 then row:SetPoint("TOP", preview, "BOTTOM", 0, -16) else row:SetPoint("TOP", copies[i - 1], "BOTTOM", 0, -4) end
        row.text = W:Text(row, "GameFontHighlight")
        row.text:SetPoint("LEFT")
        row.del = W:Button(row, L["DELETE"], 100)
        row.del:SetPoint("RIGHT")
        row.keep = W:Text(row, "GameFontDisableSmall", L["DUPES_KEEP"], "RIGHT")
        row.keep:SetPoint("RIGHT", -8, 0)
        copies[i] = row
    end

    function page.ShowGroup(group)
        card:SetShown(group ~= nil)
        if not group then return end
        local An = MF:GetModule("Analyzer")
        preview:SetText(An and An:ColorizeBody(group[1].body) or group[1].body)
        for i, row in ipairs(copies) do
            local m = group[i]
            row:SetShown(m ~= nil)
            if m then
                local scope = m._scope == "character" and (MF.C.cyan .. L["SCOPE_CHAR"]) or (MF.C.yellow .. L["SCOPE_ACCOUNT"])
                row.text:SetText(scope .. "|r  " .. MF.C.white .. (m.name:match("^%s*$") and L["MACRO_UNNAMED"] or m.name)
                    .. "|r  " .. MF.C.grey .. "#" .. (m.index or "?") .. "|r")
                row.del:SetShown(i > 1)
                row.keep:SetShown(i == 1)
                row.del:SetScript("OnClick", function()
                    StaticPopup_Show("MACROFORGE_DUPE_DELETE", m.name or "?", nil, m)
                end)
            end
        end
    end

    function page.Fill()
        local dupes = Detector:FindDuplicates()
        local extra = 0
        for _, group in ipairs(dupes) do extra = extra + #group - 1 end
        summary:SetText(#dupes == 0 and (MF.C.green .. L["DUPES_NONE"] .. "|r")
            or (MF.C.yellow .. format(L["DUPES_GROUPS"], #dupes, extra) .. "|r"))
        list.selected = nil
        list:SetRows(dupes)
    end
    Detector.page = page
end

function Detector:OpenBrowser()
    local UI = MF:GetModule("UI")
    if not self.pageRegistered then
        self.pageRegistered = true
        UI:RegisterPage("dupes", {
            title = L["DUPES_TITLE"],
            build = BuildPage,
            onShow = function(page) page.Fill() end,
        })
    end
    UI:OpenPage("dupes")
end

MF:RegisterModule("DuplicateDetector", Detector)
