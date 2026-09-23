---------------------------------------------------
-- MacroForge — Command Palette
-- Searchable command/spell insertion menu
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local CP = {}

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
-- Drawer (editor): search + list, a click inserts at the cursor
---------------------------------------------------
local function Rows(mode, query)
    local q = (query or ""):lower()
    local rows = {}
    if mode == "commands" then
        local sorted = {}
        for _, info in pairs(GetAllCommands()) do table.insert(sorted, info) end
        table.sort(sorted, function(a, b) return a.cmd < b.cmd end)
        for _, info in ipairs(sorted) do
            if q == "" or info.cmd:lower():find(q, 1, true) or (info.label and info.label:lower():find(q, 1, true)) then
                table.insert(rows, { text = info.cmd .. " ", name = (info.color or MF.C.cyan) .. info.cmd .. "|r",
                    sub = info.label or "" })
            end
        end
    else
        for _, sp in ipairs(MF.Helpers:GetSpellbookSpells()) do
            if q == "" or sp.name:lower():find(q, 1, true) then
                table.insert(rows, { text = sp.name, name = sp.name, icon = sp.icon or 134400, id = sp.id })
            end
        end
    end
    return rows
end

local function BuildDrawer(body, mode)
    local W = MF.Widgets
    local search = CreateFrame("EditBox", nil, body, "SearchBoxTemplate")
    search:SetHeight(20)
    search:SetPoint("TOPLEFT", 6, 0)
    search:SetPoint("TOPRIGHT", -2, 0)
    local hint = W:Text(body, "GameFontDisableSmall", L[mode == "commands" and "PALETTE_HINT_COMMANDS" or "PALETTE_HINT_SPELLS"])
    hint:SetPoint("TOPLEFT", search, "BOTTOMLEFT", -4, -6)
    hint:SetPoint("RIGHT", body, "RIGHT", -2, 0)
    local list = W:List(body, {
        icon = function(row) return row.icon end,
        name = function(row) return row.name end,
        sub = function(row) return row.sub end,
        onClick = function(row) CP:InsertToEditor(row.text) end,
        tooltip = mode == "spells" and function(owner, row)
            if not row.id then return end
            GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
            GameTooltip:SetSpellByID(row.id)
            GameTooltip:Show()
        end or nil,
        empty = L["PALETTE_EMPTY"],
    })
    list.frame:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -6)
    list.frame:SetPoint("BOTTOMRIGHT", 0, 0)
    local rows = {}
    local function Fill()
        rows = Rows(mode, search:GetText())
        list:SetRows(rows)
    end
    search:HookScript("OnTextChanged", Fill)
    -- Enter inserts the first match
    search:HookScript("OnEnterPressed", function()
        if rows[1] then CP:InsertToEditor(rows[1].text) end
    end)
    body.Fill = function()
        search:SetText("")
        Fill()
        search:SetFocus()
    end
end

function CP:InsertToEditor(text)
    local E = MF:GetModule("Editor")
    E:InsertText(text)
    E:FocusBody()
end

local registered
function CP:Toggle(mode)
    local E = MF:GetModule("Editor")
    if not registered then
        registered = true
        for _, m in ipairs({ "spells", "commands" }) do
            E:RegisterDrawer(m, {
                title = L[m == "commands" and "PALETTE_TITLE_COMMANDS" or "PALETTE_TITLE_SPELLS"],
                build = function(body) BuildDrawer(body, m) end,
                onShow = function(body) body.Fill() end,
            })
        end
    end
    E:ToggleDrawer(mode == "commands" and "commands" or "spells")
end

function CP:OpenSpells() self:Toggle("spells") end
function CP:OpenCommands() self:Toggle("commands") end

MF:RegisterModule("CommandPalette", CP)

