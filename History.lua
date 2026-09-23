---------------------------------------------------
-- MacroForge — History (Ace3)
-- Macro revisions: every version of every macro, deleted ones included.
--
-- Revisions are keyed by macro name (duplicates get "#2", "#3" in slot
-- order), not by slot index: indexes shift whenever a macro is created or
-- deleted. Character macros live in db.char.revisions, account macros in
-- db.global.revisions.
--
-- The store is fed by diffing the macro list on UPDATE_MACROS, so edits made
-- anywhere (Blizzard's editor, other addons, set swaps) are recorded. A macro
-- that disappears keeps its versions and is flagged deleted: it can be
-- recreated from the trash.
---------------------------------------------------
local _, MF_NS = ...
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local AceGUI = LibStub("AceGUI-3.0")
local History = {}

local MAX_DELETED = 50
local SCOPES = { "character", "account" }

local claims = {}        -- claims[scope][macroIndex] = entry key, rebuilt on each scan
local ready = false      -- macros are only reliable once the client loaded them
local scanPending = false
local nextReason         -- reason tag for the next scan (e.g. a set swap)

---------------------------------------------------
-- Store helpers
---------------------------------------------------
function History:Store(scope)
    if scope == "account" then
        MF.db.global.revisions = MF.db.global.revisions or {}
        return MF.db.global.revisions
    end
    MF.db.char.revisions = MF.db.char.revisions or {}
    return MF.db.char.revisions
end

-- Current macros of a scope, each tagged with its revision key
function History:KeyedMacros(scope)
    local out = {}
    for _, m in ipairs(MF:GetModule("Profiles"):ReadMacros(scope)) do
        m.key = claims[scope] and claims[scope][m.index]
        table.insert(out, m)
    end
    return out
end

local function LastVersion(entry)
    return entry.versions[#entry.versions]
end

local function Record(entry, m, reason)
    local last = LastVersion(entry)
    if last and last.body == m.body and last.icon == m.icon and last.name == m.name then
        return
    end
    table.insert(entry.versions, {
        name = m.name, icon = m.icon, body = m.body,
        time = time(), reason = reason,
    })
    local maxHistory = MF.db.profile.maxHistory or 20
    while #entry.versions > maxHistory do
        table.remove(entry.versions, 1)
    end
end

local function PruneDeleted(store)
    local deleted = {}
    for key, entry in pairs(store) do
        if entry.deleted then table.insert(deleted, key) end
    end
    if #deleted <= MAX_DELETED then return end
    table.sort(deleted, function(a, b) return store[a].deleted > store[b].deleted end)
    for i = MAX_DELETED + 1, #deleted do
        store[deleted[i]] = nil
    end
end

---------------------------------------------------
-- Scan: diff the live macros against the store
---------------------------------------------------
-- Entries are claimed by content first, then by name: two macros with the
-- same name (or no name at all) used to swap histories as soon as one was
-- deleted, because the key was just "name" plus its rank in the slot order.
local function UniqueKey(store, name)
    local base = name ~= "" and name or "?"
    if not store[base] then return base end
    local n = 2
    while store[base .. "#" .. n] do n = n + 1 end
    return base .. "#" .. n
end

local function ClaimEntry(store, taken, macro)
    local byName, byBody
    for key, entry in pairs(store) do
        if not taken[key] then
            local last = LastVersion(entry)
            local sameName = (entry.name or key) == macro.name
            local sameBody = last and last.body == macro.body
            if sameName and sameBody then return key end       -- exact match wins
            if sameName and not byName then byName = key end
            if sameBody and not byBody then byBody = key end
        end
    end
    return byName or byBody                                     -- name kept, or renamed
end

function History:Scan(scope, reason)
    local store = self:Store(scope)
    local taken, scopeClaims = {}, {}
    claims[scope] = scopeClaims

    for _, macro in ipairs(MF:GetModule("Profiles"):ReadMacros(scope)) do
        local key = ClaimEntry(store, taken, macro)
        if key then
            store[key].deleted, store[key].deletedReason = nil, nil
        else
            key = UniqueKey(store, macro.name)
            store[key] = { versions = {} }
        end
        taken[key] = true
        scopeClaims[macro.index] = key
        store[key].name = macro.name
        Record(store[key], macro, reason)
    end

    local vanished = 0
    for key, entry in pairs(store) do
        if not taken[key] and not entry.deleted then
            entry.deleted, entry.deletedReason = time(), reason
            vanished = vanished + 1
        end
    end
    PruneDeleted(store)
    if vanished > 0 then
        MF:Debug("history", "%s scan: %d deleted%s", scope, vanished, reason and (" [" .. reason .. "]") or "")
    end
end

function History:ScanAll(reason)
    if not ready or not MF.db then return end
    self:MigrateIndexHistory()
    for _, scope in ipairs(SCOPES) do self:Scan(scope, reason) end
end

-- Tags the versions recorded by the next scan (e.g. "set: Raid")
function History:SetNextReason(reason)
    nextReason = reason
end

function History:OnMacrosUpdated()
    ready = true
    if scanPending then return end
    scanPending = true
    -- A set swap fires one UPDATE_MACROS per write: scan once at the end
    C_Timer.After(0.5, function()
        scanPending = false
        local reason = nextReason
        nextReason = nil
        self:ScanAll(reason)
    end)
end

-- Called by the editor right before it overwrites a macro. The scan already
-- holds the current state; this only catches changes not yet scanned.
function History:SaveSnapshot()
    self:ScanAll()
end

---------------------------------------------------
-- Migration: v7.1 history was keyed by slot index
---------------------------------------------------
function History:MigrateIndexHistory()
    local old = MF.db.char.history
    if not old or not next(old) then return end
    local maxAccount = MF.Profiles.MAX_ACCOUNT_MACROS
    for indexKey, versions in pairs(old) do
        local index = tonumber(indexKey)
        local name = index and GetMacroInfo(index)
        if name and type(versions) == "table" then
            local scope = index > maxAccount and "character" or "account"
            local store = self:Store(scope)
            store[name] = store[name] or { versions = {} }
            local merged = {}
            for _, v in ipairs(versions) do
                table.insert(merged, {
                    name = v.name, icon = v.icon, body = v.body,
                    stamp = v.timestamp, reason = "v7",
                })
            end
            for _, v in ipairs(store[name].versions) do table.insert(merged, v) end
            store[name].versions = merged
        end
    end
    MF.db.char.history = nil
    MF:Log("INFO", "migrate", "index-keyed history migrated to revisions")
end

---------------------------------------------------
-- Queries
---------------------------------------------------
-- Revision key of a macro as returned by Profiles:Read*Macros
function History:KeyFor(macro)
    if not macro or not macro.scope then return nil end
    self:ScanAll()
    return claims[macro.scope] and claims[macro.scope][macro.index] or macro.name
end

-- A macro moving to the other scope keeps its versions
function History:MoveEntry(macro, toScope)
    if not MF.db then return end
    local key = self:KeyFor(macro)
    local from, to = self:Store(macro.scope), self:Store(toScope)
    if key and from[key] then
        to[UniqueKey(to, macro.name)], from[key] = from[key], nil
    end
end

function History:GetVersions(scope, key)
    local entry = MF.db and self:Store(scope)[key]
    return entry and entry.versions or {}
end

function History:GetDeleted()
    local list = {}
    for _, scope in ipairs(SCOPES) do
        for key, entry in pairs(self:Store(scope)) do
            if entry.deleted and LastVersion(entry) then
                table.insert(list, { scope = scope, key = key, entry = entry })
            end
        end
    end
    table.sort(list, function(a, b) return a.entry.deleted > b.entry.deleted end)
    return list
end

-- Forgets every deleted macro (their versions go too)
function History:EmptyTrash()
    for _, scope in ipairs(SCOPES) do
        local store = self:Store(scope)
        for key, entry in pairs(store) do
            if entry.deleted then store[key] = nil end
        end
    end
    MF:Log("INFO", "history", "trash emptied")
end

function History:Purge()
    MF.db.char.revisions = {}
    MF.db.global.revisions = {}
    MF.db.char.history = nil
end

---------------------------------------------------
-- UI helpers
---------------------------------------------------
local function FormatTime(v)
    if v.time then return date("%Y-%m-%d %H:%M", v.time) end
    return v.stamp or "?"
end

local function ReasonTag(reason)
    if not reason then return "" end
    return "  " .. MF.C.grey .. "[" .. reason .. "]|r"
end

local function AddBodyPreview(grp, body)
    local An = MF:GetModule("Analyzer")
    local preview = AceGUI:Create("Label")
    preview:SetFullWidth(true)
    preview:SetFontObject(GameFontNormalSmall)
    preview:SetText((An and An:ColorizeBody(body) or body) .. "\n"
        .. MF.C.grey .. format(L["CHARS"], #body) .. "|r")
    grp:AddChild(preview)
end

---------------------------------------------------
-- Versions of one macro: a page of the main window (UI:OpenPage), newest
-- version first on the left, the selected one on the right
---------------------------------------------------
local function BuildVersionsPage(page)
    local W = MF.Widgets
    local state = {}
    local list, card = W:ListAndCard(page, {
        icon = function(row) return (row.v.icon and row.v.icon ~= 0) and row.v.icon or 134400 end,
        name = function(row) return MF.C.gold .. "#" .. row.i .. "|r  " .. FormatTime(row.v) end,
        sub = function(row) return (row.v.name or state.key or "") .. (row.v.reason and ("  [" .. row.v.reason .. "]") or "") end,
        badge = function(row) return row.latest and (MF.C.green .. L["VERSION_LATEST"] .. "|r") or "" end,
        onSelect = function(row) page.ShowVersion(row) end,
        empty = L["NO_HISTORY"],
    }, 0)
    local title = W:Text(card, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -14)
    title:SetPoint("RIGHT", card, "RIGHT", -14, 0)
    local sub = W:Text(card, "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    local preview = W:Text(card, "GameFontHighlight")
    preview:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -14)
    preview:SetPoint("RIGHT", card, "RIGHT", -14, 0)
    preview:SetJustifyV("TOP")
    local count = W:Text(card, "GameFontDisableSmall")
    count:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", 0, -8)

    local load = W:Button(page, L["VERSION_LOAD"], 180, function()
        local row = list.selected
        if not row then return end
        local E = MF:GetModule("Editor")
        -- Loaded into the live macro if it still exists, otherwise as a
        -- new macro; nothing is written until the user saves
        local live
        for _, m in ipairs(History:KeyedMacros(state.scope)) do
            if m.key == state.key then live = m; break end
        end
        local function Fill() E:LoadContent(row.v.name, row.v.body, row.v.icon) end
        if live then E:Open(live, nil, Fill) else E:OpenNew(state.scope == "character", nil, Fill) end
        MF:Notify(MF.C.green .. format(L["VERSION_RESTORED"], row.i) .. "|r")
    end)
    load:SetPoint("BOTTOMRIGHT", 0, 0)

    function page.ShowVersion(row)
        card:SetShown(row ~= nil)
        load:SetEnabled(row ~= nil)
        if not row then return end
        local An = MF:GetModule("Analyzer")
        local body = row.v.body or ""
        title:SetText(MF.C.gold .. "#" .. row.i .. "|r  " .. (row.v.name or state.key))
        sub:SetText(MF.C.grey .. FormatTime(row.v) .. "|r" .. ReasonTag(row.v.reason))
        preview:SetText(An and An:ColorizeBody(body) or body)
        count:SetText(format(L["CHARS"], #body))
    end

    function page.Fill(arg)
        state.scope, state.key = arg.scope, arg.key
        local versions = History:GetVersions(arg.scope, arg.key)
        local rows = {}
        for i = #versions, 1, -1 do
            table.insert(rows, { i = i, v = versions[i], latest = i == #versions })
        end
        list.selected = nil
        list:SetRows(rows)
    end
end

function History:OpenVersions(scope, key)
    if #self:GetVersions(scope, key) == 0 then
        MF:Notify(MF.C.grey .. L["NO_HISTORY"] .. "|r")
        return
    end
    local UI = MF:GetModule("UI")
    if not self.pageRegistered then
        self.pageRegistered = true
        UI:RegisterPage("history", {
            title = L["HISTORY"],
            build = BuildVersionsPage,
            onShow = function(page, arg) page.Fill(arg) end,
        })
    end
    UI:OpenPage("history", { scope = scope, key = key })
end

-- Kept for callers passing a macro (editor, /mf history)
function History:OpenBrowser(macro)
    if type(macro) ~= "table" then
        MF:Print(MF.C.yellow .. L["OPEN_MACRO_FIRST"] .. "|r")
        return
    end
    self:ScanAll()
    self:OpenVersions(macro.scope, self:KeyFor(macro))
end

---------------------------------------------------
-- Trash: deleted macros, recreatable
---------------------------------------------------
-- One deleted macro: title, last body, Recreate / Versions.
-- onDone runs after either button (e.g. close the window hosting it).
function History:BuildTrashGroup(d, onDone)
    local last = LastVersion(d.entry)
    local grp = AceGUI:Create("InlineGroup")
    grp:SetFullWidth(true)
    grp:SetLayout("Flow")
    grp:SetTitle(MF.C.white .. self:EntryLabel(d.scope, d.key) .. "|r  "
        .. MF.C.cyan .. (d.scope == "character" and L["SCOPE_CHAR"] or L["SCOPE_ACCOUNT"]) .. "|r  "
        .. MF.C.grey .. format(L["TRASH_DELETED_AT"], date("%Y-%m-%d %H:%M", d.entry.deleted)) .. "|r"
        .. ReasonTag(d.entry.deletedReason))
    AddBodyPreview(grp, last.body or "")

    local btnRecreate = AceGUI:Create("Button")
    btnRecreate:SetText(L["TRASH_RECREATE"])
    btnRecreate:SetWidth(130)
    btnRecreate:SetCallback("OnClick", function()
        local P = MF:GetModule("Profiles")
        if P then P:CreateNewMacro(last.name, last.icon, last.body, d.scope == "character") end
        local UI = MF:GetModule("UI")
        if UI then C_Timer.After(0.6, function() UI:Refresh() end) end
        if onDone then onDone() end
    end)
    grp:AddChild(btnRecreate)

    local btnVersions = AceGUI:Create("Button")
    btnVersions:SetText(format(L["TRASH_VERSIONS"], #d.entry.versions))
    btnVersions:SetWidth(130)
    btnVersions:SetCallback("OnClick", function()
        if onDone then onDone() end
        self:OpenVersions(d.scope, d.key)
    end)
    grp:AddChild(btnVersions)
    return grp
end

-- Deleted entry by scope + key, or nil once recreated / pruned
-- What to show for an entry: its macro name, or the spell of #showtooltip
function History:EntryLabel(scope, key)
    local entry = self:Store(scope)[key]
    local last = entry and LastVersion(entry)
    local name = entry and entry.name or key
    if name and name:match("^%s*$") then
        name = (last and MF.Helpers:ParseShowTooltip(last.body)) or L["MACRO_UNNAMED"]
    end
    return name
end

function History:GetDeletedEntry(scope, key)
    local entry = MF.db and self:Store(scope)[key]
    if entry and entry.deleted and LastVersion(entry) then
        return { scope = scope, key = key, entry = entry }
    end
end

-- The Trash lives in the main window's Trash tab
function History:OpenTrash()
    self:ScanAll()
    local UI = MF:GetModule("UI")
    UI:Show()
    UI:SetTab("trash")
end

function History:OnInitialize()
    MF:RegisterMessage("MF_MACROS_UPDATED", function() self:OnMacrosUpdated() end)
end

MF:RegisterModule("History", History)
