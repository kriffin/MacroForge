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

---------------------------------------------------
-- Spec Detection
-- 12.x moved the spec API into C_SpecializationInfo: the old globals only
-- survive as deprecation fallbacks on retail and are absent on WoW Forever.
---------------------------------------------------
local SpecInfo = C_SpecializationInfo or {}
local GetSpecialization = SpecInfo.GetSpecialization or GetSpecialization
local GetSpecializationInfo = SpecInfo.GetSpecializationInfo or GetSpecializationInfo
local GetActiveSpecGroup = SpecInfo.GetActiveSpecGroup or GetActiveSpecGroup or GetActiveTalentGroup
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

function MF.Profiles:WriteCharacterMacros(savedMacros)
    if not savedMacros or #savedMacros == 0 then
        MF:Print(MF.C.red .. L["NO_MACROS_TO_LOAD"] .. "|r")
        return false
    end

    local _, numCharacter = GetNumMacros()
    for i = numCharacter, 1, -1 do
        DeleteMacro(MAX_ACCOUNT_MACROS + i)
    end

    local created = 0
    for _, macro in ipairs(savedMacros) do
        if created < MAX_CHARACTER_MACROS then
            local icon = macro.icon or 134400
            local body = macro.body or ""
            CreateMacro(macro.name, icon, body, true)
            created = created + 1
        end
    end
    return true, created
end

---------------------------------------------------
-- Profile Save / Load (uses AceDB char namespace)
---------------------------------------------------
function MF.Profiles:SaveCurrentProfile()
    local specID = self:GetCurrentSpecID()
    if not specID then
        MF:Print(MF.C.red .. L["PROFILE_NO_SPEC"] .. "|r")
        return
    end

    local specName = self:GetSpecName(specID)
    local macros = self:ReadCharacterMacros()
    local serialized = {}
    for _, m in ipairs(macros) do
        table.insert(serialized, { name = m.name, icon = m.icon, body = m.body })
    end

    MF.db.char.profiles[specID] = {
        specName = specName,
        macros = serialized,
        timestamp = date("%Y-%m-%d %H:%M"),
    }

    MF:Print(MF.C.green .. L["PROFILE_SAVED"] .. "|r → "
        .. MF.C.cyan .. specName .. "|r (" .. #serialized .. " macros)")

    if MF.UI and MF.UI.frame and MF.UI.frame:IsShown() then
        MF.UI:Refresh()
    end
end

function MF.Profiles:LoadCurrentProfile()
    local specID = self:GetCurrentSpecID()
    if not specID then
        MF:Print(MF.C.red .. L["PROFILE_NO_SPEC"] .. "|r")
        return
    end

    local profile = MF.db.char.profiles[specID]
    if not profile then
        MF:Print(MF.C.red .. format(L["PROFILE_NONE"], MF.C.cyan .. self:GetSpecName(specID) .. "|r"))
        return
    end

    local success, count = self:WriteCharacterMacros(profile.macros)
    if success then
        MF:Print(MF.C.green .. L["PROFILE_LOADED"] .. "|r → "
            .. MF.C.cyan .. profile.specName .. "|r (" .. count .. " macros)")
    end
end

function MF.Profiles:ListProfiles()
    local C = MF.C
    MF:Print(C.gold .. "═══ Profils ═══|r")
    local found = false
    for specID, p in pairs(MF.db.char.profiles) do
        found = true
        MF:Print(C.cyan .. p.specName .. "|r — "
            .. #p.macros .. " macros — " .. C.grey .. p.timestamp .. "|r")
    end
    if not found then
        MF:Print(C.grey .. "Aucun profil. /mf save|r")
    end
end

---------------------------------------------------
-- Auto-swap
---------------------------------------------------
function MF.Profiles:OnSpecChanged()
    if not MF.db or not MF.db.profile.autoSwap then return end
    local specID = self:GetCurrentSpecID()
    if not specID then return end

    local profile = MF.db.char.profiles[specID]
    if profile then
        local specName = self:GetSpecName(specID)
        C_Timer.After(1, function()
            local success, count = self:WriteCharacterMacros(profile.macros)
            if success then
                MF:Print(MF.C.green .. L["PROFILE_AUTOSWAP"] .. "|r → "
                    .. MF.C.cyan .. specName .. "|r (" .. count .. " macros)")
            end
        end)
    end
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
function MF.Profiles:CreateBackup()
    local charMacros = self:ReadCharacterMacros()
    local accountMacros = self:ReadAccountMacros()

    local backup = {
        timestamp = date("%Y-%m-%d %H:%M:%S"),
        character = {},
        account = {},
    }
    for _, m in ipairs(charMacros) do
        table.insert(backup.character, { name = m.name, icon = m.icon, body = m.body })
    end
    for _, m in ipairs(accountMacros) do
        table.insert(backup.account, { name = m.name, icon = m.icon, body = m.body })
    end

    local maxBackups = MF.db.profile.maxBackups or 3
    table.insert(MF.db.char.backups, 1, backup)
    while #MF.db.char.backups > maxBackups do
        table.remove(MF.db.char.backups)
    end

    MF:Print(MF.C.green .. L["BACKUP_CREATED"] .. "|r — "
        .. #backup.character .. " perso, " .. #backup.account .. " compte ("
        .. MF.C.grey .. backup.timestamp .. "|r)")
end

function MF.Profiles:RestoreBackup(index)
    index = index or 1
    if not MF.db.char.backups or not MF.db.char.backups[index] then
        MF:Print(MF.C.red .. format(L["BACKUP_NOT_FOUND"], index) .. "|r")
        return
    end
    local backup = MF.db.char.backups[index]
    local success, count = self:WriteCharacterMacros(backup.character)
    if success then
        MF:Print(MF.C.green .. format(L["BACKUP_RESTORED"], MF.C.grey .. backup.timestamp .. "|r")
            .. " (" .. count .. " macros)")
    end
end

---------------------------------------------------
-- Create / Delete macros
---------------------------------------------------
function MF.Profiles:CreateNewMacro(name, icon, body, perCharacter)
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
    local name = GetMacroInfo(macroIndex)
    if name then
        DeleteMacro(macroIndex)
        MF:Print(MF.C.orange .. format(L["MACRO_DELETED"], name) .. "|r")
        return true
    end
    return false
end

function MF.Profiles:OnInitialize()
    MF:RegisterMessage("MF_SPEC_CHANGED", function()
        self:OnSpecChanged()
    end)
end

MF:RegisterModule("Profiles", MF.Profiles)
