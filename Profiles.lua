---------------------------------------------------
-- MacroForge — Profiles (Ace3)
-- Profils par spé + Backup / Restore
-- Now uses AceDB char namespace for storage
---------------------------------------------------
local _, MF_NS = ...
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
MF.Profiles = {}

-- 12.x clients (retail, WoW Forever) expose the slot limits: 120 account / 30 character
local MacroConsts = Constants and Constants.MacroConsts
local MAX_ACCOUNT_MACROS = MacroConsts and MacroConsts.MAX_ACCOUNT_MACROS or 120
local MAX_CHARACTER_MACROS = MacroConsts and MacroConsts.MAX_CHARACTER_MACROS or 18
MF.Profiles.MAX_ACCOUNT_MACROS = MAX_ACCOUNT_MACROS
MF.Profiles.MAX_CHARACTER_MACROS = MAX_CHARACTER_MACROS

---------------------------------------------------
-- Spec Detection
-- 12.x moved the spec API into C_SpecializationInfo: the old globals only
-- survive as deprecation fallbacks on retail and are absent on WoW Forever.
---------------------------------------------------
local SpecInfo = C_SpecializationInfo or {}
local GetSpecialization = SpecInfo.GetSpecialization or GetSpecialization
local GetSpecializationInfo = SpecInfo.GetSpecializationInfo or GetSpecializationInfo
local GetActiveSpecGroup = SpecInfo.GetActiveSpecGroup or GetActiveSpecGroup or GetActiveTalentGroup
local GetNumSpecializations = SpecInfo.GetNumSpecializations or GetNumSpecializations
local IsSpecSelectionEnabled = SpecInfo.IsSpecSelectionEnabled -- WoW Forever only

-- Returns the specID, or "group<N>" (active talent group) when the class has
-- no selected spec, e.g. on WoW Forever before a primary tree is picked.
function MF.Profiles:GetCurrentSpecID()
    local _, _, classID = UnitClass("player")
    local selectable = not IsSpecSelectionEnabled or IsSpecSelectionEnabled(classID)
    local currentSpec = selectable and GetSpecialization and GetSpecialization()
    if currentSpec and currentSpec > 0 then
        local specID = GetSpecializationInfo(currentSpec)
        if specID and specID > 0 then return specID end
    end
    if GetActiveSpecGroup then
        return "group" .. (GetActiveSpecGroup() or 1)
    end
    return nil
end

function MF.Profiles:GetSpecName(specID)
    if not specID then return "Inconnue" end
    local group = type(specID) == "string" and specID:match("^group(%d+)$")
    if group then return format(L["SPEC_GROUP"], tonumber(group)) end
    local _, name = GetSpecializationInfoByID(specID)
    return name or "Inconnue"
end

---------------------------------------------------
-- Macro Read / Write
---------------------------------------------------
function MF.Profiles:ReadCharacterMacros()
    local macros = {}
    local _, numCharacter = GetNumMacros()
    for i = 1, numCharacter do
        local idx = MAX_ACCOUNT_MACROS + i
        local name, icon, body = GetMacroInfo(idx)
        if name then
            table.insert(macros, {
                slot = i, index = idx,
                name = name, icon = icon, body = body,
                scope = "character",
            })
        end
    end
    return macros
end

function MF.Profiles:ReadAccountMacros()
    local macros = {}
    local numAccount = GetNumMacros()
    for i = 1, numAccount do
        local name, icon, body = GetMacroInfo(i)
        if name then
            table.insert(macros, {
                slot = i, index = i,
                name = name, icon = icon, body = body,
                scope = "account",
            })
        end
    end
    return macros
end

function MF.Profiles:ReadAllMacros()
    local all = {}
    for _, m in ipairs(self:ReadAccountMacros()) do table.insert(all, m) end
    for _, m in ipairs(self:ReadCharacterMacros()) do table.insert(all, m) end
    return all
end

function MF.Profiles:ReadMacros(scope)
    if scope == "account" then return self:ReadAccountMacros() end
    return self:ReadCharacterMacros()
end

local function CopyMacros(macros)
    local out = {}
    for _, m in ipairs(macros) do
        table.insert(out, { name = m.name, icon = m.icon, body = m.body })
    end
    return out
end

-- Groups a macro list by name, keeping slot order for duplicate names
local function GroupByName(macros)
    local byName = {}
    for _, m in ipairs(macros) do
        byName[m.name] = byName[m.name] or {}
        table.insert(byName[m.name], m)
    end
    return byName
end

-- Replaces the macros of a scope with savedMacros without wiping the slots.
-- A macro that exists on both sides under the same name is edited in place,
-- so action bar buttons pointing to it survive the swap. Only macros absent
-- from savedMacros are deleted, and only missing ones are created.
function MF.Profiles:WriteMacros(scope, savedMacros)
    if InCombatLockdown() then
        MF:Print(MF.C.red .. L["COMBAT_BLOCKED"] .. "|r")
        return false
    end
    if not savedMacros or #savedMacros == 0 then
        MF:Print(MF.C.red .. L["NO_MACROS_TO_LOAD"] .. "|r")
        return false
    end

    local perCharacter = scope ~= "account"
    local limit = perCharacter and MAX_CHARACTER_MACROS or MAX_ACCOUNT_MACROS

    -- 1. Pair wanted macros with existing ones by name
    local pool = GroupByName(self:ReadMacros(scope))
    local matched, toCreate = {}, {}
    for _, wanted in ipairs(savedMacros) do
        local candidates = pool[wanted.name]
        if candidates and #candidates > 0 then
            table.remove(candidates, 1)
            table.insert(matched, wanted)
        else
            table.insert(toCreate, wanted)
        end
    end

    -- 2. Delete the leftovers, highest index first so lower indexes stay valid
    local toDelete = {}
    for _, candidates in pairs(pool) do
        for _, m in ipairs(candidates) do table.insert(toDelete, m.index) end
    end
    table.sort(toDelete, function(a, b) return a > b end)
    for _, idx in ipairs(toDelete) do DeleteMacro(idx) end

    -- 3. Edit kept macros in place. Deletions shifted indexes, so re-read:
    -- the scope now only holds matched names, in their original order.
    local current = GroupByName(self:ReadMacros(scope))
    local edited = 0
    for _, wanted in ipairs(matched) do
        local m = table.remove(current[wanted.name], 1)
        local icon = wanted.icon or 134400
        local body = wanted.body or ""
        if m.body ~= body or m.icon ~= icon then
            EditMacro(m.index, wanted.name, icon, body)
            edited = edited + 1
        end
    end

    -- 4. Create what is missing, within the slot limit
    local numAccount, numCharacter = GetNumMacros()
    local used = perCharacter and numCharacter or numAccount
    local created, skipped = 0, 0
    for _, wanted in ipairs(toCreate) do
        if used < limit then
            CreateMacro(wanted.name, wanted.icon or 134400, wanted.body or "", perCharacter)
            used = used + 1
            created = created + 1
        else
            skipped = skipped + 1
        end
    end
    if skipped > 0 then
        MF:Print(MF.C.red .. format(L["MACROS_SKIPPED_LIMIT"], skipped, limit) .. "|r")
    end

    return true, #matched + created, {
        kept = #matched, edited = edited, created = created,
        deleted = #toDelete, skipped = skipped,
    }
end

function MF.Profiles:WriteCharacterMacros(savedMacros)
    return self:WriteMacros("character", savedMacros)
end

---------------------------------------------------
-- Macro sets (uses AceDB char namespace)
-- A set is a named snapshot of the character macros:
--   db.char.sets[name] = { macros = {...}, specs = { [specKey] = true }, updated = time() }
-- A spec key (specID or "group<N>") belongs to at most one set; changing
-- spec applies the set bound to the new spec. db.char.activeSet is the set
-- currently on the bars: with autoSaveOnSwap, it absorbs the edits made to
-- the macros before another set replaces them.
---------------------------------------------------
function MF.Profiles:GetSets()
    MF.db.char.sets = MF.db.char.sets or {}
    return MF.db.char.sets
end

function MF.Profiles:GetSetNames()
    local names = {}
    for name in pairs(self:GetSets()) do table.insert(names, name) end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

function MF.Profiles:GetActiveSet()
    local name = MF.db.char.activeSet
    if name and self:GetSets()[name] then return name end
    return nil
end

function MF.Profiles:GetSetForSpec(specKey)
    if not specKey then return nil end
    for name, set in pairs(self:GetSets()) do
        if set.specs and set.specs[specKey] then return name end
    end
    return nil
end

-- Specs selectable for binding, in class order: { key, name }
function MF.Profiles:GetSpecChoices()
    local choices = {}
    local _, _, classID = UnitClass("player")
    local selectable = not IsSpecSelectionEnabled or IsSpecSelectionEnabled(classID)
    local numSpecs = selectable and GetNumSpecializations and GetNumSpecializations() or 0
    for i = 1, numSpecs do
        local specID, name = GetSpecializationInfo(i)
        if specID and specID > 0 then table.insert(choices, { key = specID, name = name }) end
    end
    if #choices == 0 then
        for group = 1, 2 do
            local key = "group" .. group
            table.insert(choices, { key = key, name = self:GetSpecName(key) })
        end
    end
    return choices
end

function MF.Profiles:BindSpec(setName, specKey, bound)
    local sets = self:GetSets()
    local set = sets[setName]
    if not set or not specKey then return end
    set.specs = set.specs or {}
    if bound then
        for _, other in pairs(sets) do
            if other.specs then other.specs[specKey] = nil end
        end
        set.specs[specKey] = true
    else
        set.specs[specKey] = nil
    end
end

function MF.Profiles:GetSetSpecNames(setName)
    local set = self:GetSets()[setName]
    local names = {}
    for specKey in pairs(set and set.specs or {}) do
        table.insert(names, self:GetSpecName(specKey))
    end
    table.sort(names)
    return names
end

-- Stores the current character macros into a set (created if missing)
function MF.Profiles:SaveSet(name, silent)
    local sets = self:GetSets()
    local macros = CopyMacros(self:ReadCharacterMacros())
    local set = sets[name] or { specs = {} }
    set.macros = macros
    set.updated = time()
    sets[name] = set
    MF.db.char.activeSet = name
    if not silent then
        MF:Print(MF.C.green .. L["SET_SAVED"] .. "|r → " .. MF.C.cyan .. name .. "|r ("
            .. #macros .. " macros)")
    end
    self:RefreshUI()
    return set
end

-- Replaces the character macros with a set's macros
function MF.Profiles:ApplySet(name, reasonMsg)
    local set = self:GetSets()[name]
    if not set then
        MF:Print(MF.C.red .. format(L["SET_NOT_FOUND"], name) .. "|r")
        return
    end
    MF:RunOutOfCombat("load", function()
        self:CreateBackup(true)
        local H = MF:GetModule("History")
        if H then H:SetNextReason("set: " .. name) end
        local success, count = self:WriteCharacterMacros(set.macros)
        if success then
            MF.db.char.activeSet = name
            MF:Print(MF.C.green .. (reasonMsg or L["SET_APPLIED"]) .. "|r → "
                .. MF.C.cyan .. name .. "|r (" .. count .. " macros)")
        end
        self:RefreshUI()
    end)
end

function MF.Profiles:DeleteSet(name)
    local sets = self:GetSets()
    if not sets[name] then return end
    sets[name] = nil
    if MF.db.char.activeSet == name then MF.db.char.activeSet = nil end
    MF:Print(MF.C.orange .. format(L["SET_DELETED"], name) .. "|r")
    self:RefreshUI()
end

function MF.Profiles:RenameSet(oldName, newName)
    local sets = self:GetSets()
    newName = newName and newName:match("^%s*(.-)%s*$")
    if not sets[oldName] or not newName or newName == "" or sets[newName] then return false end
    sets[newName], sets[oldName] = sets[oldName], nil
    if MF.db.char.activeSet == oldName then MF.db.char.activeSet = newName end
    self:RefreshUI()
    return true
end

function MF.Profiles:RefreshUI()
    local SetsUI = MF:GetModule("Sets")
    if SetsUI and SetsUI.Refresh then SetsUI:Refresh() end
    if MF.UI and MF.UI.mainFrame and MF.UI.mainFrame.frame:IsShown() then
        C_Timer.After(0.3, function() MF.UI:Refresh() end)
    end
end

-- /mf save [name]: without a name, targets the set bound to the current
-- spec, creating one named after the spec (and bound to it) if needed.
function MF.Profiles:SaveCurrentProfile(name)
    name = name and name:match("^%s*(.-)%s*$")
    if name and name ~= "" then
        self:SaveSet(name)
        return
    end
    local specID = self:GetCurrentSpecID()
    if not specID then
        MF:Print(MF.C.red .. L["PROFILE_NO_SPEC"] .. "|r")
        return
    end
    local target = self:GetSetForSpec(specID)
    if not target then
        target = self:GetSpecName(specID)
        self:SaveSet(target)
        self:BindSpec(target, specID, true)
    else
        self:SaveSet(target)
    end
end

-- /mf load [name]: without a name, applies the set bound to the current spec
function MF.Profiles:LoadCurrentProfile(name)
    name = name and name:match("^%s*(.-)%s*$")
    if name and name ~= "" then
        self:ApplySet(name)
        return
    end
    local specID = self:GetCurrentSpecID()
    if not specID then
        MF:Print(MF.C.red .. L["PROFILE_NO_SPEC"] .. "|r")
        return
    end
    local target = self:GetSetForSpec(specID)
    if not target then
        MF:Print(MF.C.red .. format(L["PROFILE_NONE"], MF.C.cyan .. self:GetSpecName(specID) .. "|r"))
        return
    end
    self:ApplySet(target)
end

function MF.Profiles:ListProfiles()
    local C = MF.C
    MF:Print(C.gold .. "═══ Sets ═══|r")
    local names = self:GetSetNames()
    if #names == 0 then
        MF:Print(C.grey .. L["SET_NONE"] .. "|r")
        return
    end
    local active = self:GetActiveSet()
    for _, name in ipairs(names) do
        local set = self:GetSets()[name]
        local specs = self:GetSetSpecNames(name)
        MF:Print(C.cyan .. name .. "|r"
            .. (name == active and (" " .. C.green .. L["SET_ACTIVE_TAG"] .. "|r") or "")
            .. " — " .. #set.macros .. " macros"
            .. (#specs > 0 and (" — " .. C.yellow .. table.concat(specs, ", ") .. "|r") or ""))
    end
end

---------------------------------------------------
-- Auto-swap
---------------------------------------------------
-- Both ACTIVE_TALENT_GROUP_CHANGED and spec events can fire for one change:
-- only a real change of spec key triggers a swap.
function MF.Profiles:OnSpecChanged()
    if not MF.db then return end
    local specID = self:GetCurrentSpecID()
    if not specID or specID == MF.db.char.lastSpec then return end
    MF.db.char.lastSpec = specID

    if not MF.db.profile.autoSwap then return end
    local target = self:GetSetForSpec(specID)
    if not target or target == self:GetActiveSet() then return end

    C_Timer.After(1, function()
        MF:RunOutOfCombat("swap", function()
            local active = self:GetActiveSet()
            if active and MF.db.profile.autoSaveOnSwap then
                self:SaveSet(active, true)
            end
            self:ApplySet(target, L["PROFILE_AUTOSWAP"])
        end)
    end)
end

function MF.Profiles:OnLogin()
    MF.db.char.lastSpec = self:GetCurrentSpecID()
end

-- v7.1 stored one profile per spec in db.char.profiles
function MF.Profiles:MigrateProfilesToSets()
    local old = MF.db.char.profiles
    if not old or not next(old) then return end
    local sets = self:GetSets()
    for specKey, p in pairs(old) do
        if type(p) == "table" and p.macros then
            local name = p.specName or self:GetSpecName(specKey)
            local unique, n = name, 2
            while sets[unique] do unique = name .. " " .. n; n = n + 1 end
            sets[unique] = { macros = p.macros, specs = { [specKey] = true } }
            self:BindSpec(unique, specKey, true)
        end
    end
    MF.db.char.profiles = nil
end

function MF.Profiles:ToggleAutoSwap()
    MF.db.profile.autoSwap = not MF.db.profile.autoSwap
    local state = MF.db.profile.autoSwap
        and (MF.C.green .. L["AUTOSWAP_ON"]) or (MF.C.red .. L["AUTOSWAP_OFF"])
    MF:Print(state .. "|r")
end

---------------------------------------------------
-- Backup / Restore (uses AceDB char namespace)
---------------------------------------------------
-- Automatic backups (taken before any overwrite) rotate on their own quota,
-- so a few spec swaps never push the manual ones out.
local MAX_AUTO_BACKUPS = 5

function MF.Profiles:CreateBackup(auto)
    local backup = {
        timestamp = date("%Y-%m-%d %H:%M:%S"),
        auto = auto or nil,
        character = CopyMacros(self:ReadCharacterMacros()),
        account = CopyMacros(self:ReadAccountMacros()),
    }
    if #backup.character == 0 and #backup.account == 0 then return end

    local backups = MF.db.char.backups
    table.insert(backups, 1, backup)

    -- Drop the oldest entries beyond each quota (list is newest first)
    local maxManual = MF.db.profile.maxBackups or 3
    local nAuto, nManual = 0, 0
    for i = 1, #backups do
        if backups[i].auto then nAuto = nAuto + 1 else nManual = nManual + 1 end
    end
    for i = #backups, 1, -1 do
        if backups[i].auto and nAuto > MAX_AUTO_BACKUPS then
            table.remove(backups, i); nAuto = nAuto - 1
        elseif not backups[i].auto and nManual > maxManual then
            table.remove(backups, i); nManual = nManual - 1
        end
    end

    if not auto then
        MF:Print(MF.C.green .. L["BACKUP_CREATED"] .. "|r — "
            .. format(L["BACKUP_COUNTS"], #backup.character, #backup.account)
            .. " (" .. MF.C.grey .. backup.timestamp .. "|r)")
    end
end

function MF.Profiles:ListBackups()
    local C = MF.C
    MF:Print(C.gold .. "═══ Backups ═══|r")
    local backups = MF.db.char.backups or {}
    if #backups == 0 then
        MF:Print(C.grey .. L["BACKUP_NONE"] .. "|r")
        return
    end
    for i, b in ipairs(backups) do
        MF:Print(C.cyan .. "#" .. i .. "|r " .. C.grey .. b.timestamp .. "|r — "
            .. format(L["BACKUP_COUNTS"], #(b.character or {}), #(b.account or {}))
            .. (b.auto and (" " .. C.grey .. L["BACKUP_AUTO_TAG"] .. "|r") or ""))
    end
end

function MF.Profiles:RestoreBackup(index)
    index = index or 1
    if not MF.db.char.backups or not MF.db.char.backups[index] then
        MF:Print(MF.C.red .. format(L["BACKUP_NOT_FOUND"], index) .. "|r")
        return
    end
    local backup = MF.db.char.backups[index]
    MF:RunOutOfCombat("load", function()
        self:CreateBackup(true)
        -- The restored macros are no set: don't let a swap save them into one
        MF.db.char.activeSet = nil
        local counts = {}
        -- An empty scope in the backup is skipped rather than wiping that scope
        for _, scope in ipairs({ "character", "account" }) do
            local list = backup[scope]
            if list and #list > 0 then
                local success, count = self:WriteMacros(scope, list)
                counts[scope] = success and count or 0
            end
        end
        MF:Print(MF.C.green .. format(L["BACKUP_RESTORED"], MF.C.grey .. backup.timestamp .. "|r")
            .. " (" .. format(L["BACKUP_COUNTS"], counts.character or 0, counts.account or 0) .. ")")
    end)
end

---------------------------------------------------
-- Create / Delete macros
---------------------------------------------------
local queuedCreates = 0

function MF.Profiles:CreateNewMacro(name, icon, body, perCharacter)
    if InCombatLockdown() then
        queuedCreates = queuedCreates + 1
        MF:RunOutOfCombat("create" .. queuedCreates, function()
            self:CreateNewMacro(name, icon, body, perCharacter)
        end)
        return nil
    end
    local numAccount, numCharacter = GetNumMacros()
    if perCharacter then
        if numCharacter >= MAX_CHARACTER_MACROS then
            MF:Print(MF.C.red .. format(L["MACRO_LIMIT_CHAR"], numCharacter) .. "|r")
            return nil
        end
    else
        if numAccount >= MAX_ACCOUNT_MACROS then
            MF:Print(MF.C.red .. format(L["MACRO_LIMIT_ACCOUNT"], numAccount) .. "|r")
            return nil
        end
    end

    local newIcon = icon or 134400
    local newBody = body or ""
    local macroId = CreateMacro(name, newIcon, newBody, perCharacter)

    if macroId then
        MF:Print(MF.C.green .. format(L["MACRO_CREATED"], MF.C.cyan .. name .. "|r"))
    end
    return macroId
end

function MF.Profiles:DeleteMacroByIndex(macroIndex)
    -- Not queued: two queued deletes would shift each other's index
    if InCombatLockdown() then
        MF:Print(MF.C.red .. L["COMBAT_BLOCKED"] .. "|r")
        return false
    end
    local name = GetMacroInfo(macroIndex)
    if name then
        DeleteMacro(macroIndex)
        MF:Print(MF.C.orange .. format(L["MACRO_DELETED"], name) .. "|r")
        return true
    end
    return false
end

function MF.Profiles:OnInitialize()
    self:MigrateProfilesToSets()
    MF:RegisterMessage("MF_SPEC_CHANGED", function()
        self:OnSpecChanged()
    end)
    MF:RegisterMessage("MF_LOGIN", function()
        self:OnLogin()
    end)
end

MF:RegisterModule("Profiles", MF.Profiles)
