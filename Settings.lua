---------------------------------------------------
-- MacroForge — Settings (Ace3)
-- AceConfig-3.0 + AceConfigDialog-3.0 + LibSharedMedia
---------------------------------------------------
local _, MF_NS = ...
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local LSM = LibStub("LibSharedMedia-3.0")
local Settings = {}

---------------------------------------------------
-- Convenience accessor (backward compat)
---------------------------------------------------
function Settings:Get(key)
    if MF.db and MF.db.profile then
        return MF.db.profile[key]
    end
    return nil
end

function Settings:Set(key, value)
    if MF.db and MF.db.profile then
        MF.db.profile[key] = value
    end
end

---------------------------------------------------
-- AceConfig options table (Point 3 — replaces manual UI)
---------------------------------------------------
function Settings:GetOptionsTable()
    local options = {
        type = "group",
        name = "|cff00ccffMacro|r|cffffd700Forge|r",
        args = {
            -- General header
            generalHeader = {
                type = "header",
                name = "|cffffff99" .. L["GENERAL"] .. "|r",
                order = 1,
            },
            autoSwap = {
                type = "toggle",
                name = L["OPT_AUTOSWAP"],
                order = 2,
                width = "full",
                get = function() return MF.db.profile.autoSwap end,
                set = function(_, v) MF.db.profile.autoSwap = v end,
            },
            autocomplete = {
                type = "toggle",
                name = L["OPT_AUTOCOMPLETE"],
                order = 3,
                width = "full",
                get = function() return MF.db.profile.autocomplete end,
                set = function(_, v) MF.db.profile.autocomplete = v end,
            },
            syntaxColors = {
                type = "toggle",
                name = L["OPT_SYNTAX_COLORS"],
                order = 4,
                width = "full",
                get = function() return MF.db.profile.syntaxColors end,
                set = function(_, v) MF.db.profile.syntaxColors = v end,
            },
            autoSaveDraft = {
                type = "toggle",
                name = L["OPT_AUTOSAVE_DRAFT"],
                order = 5,
                width = "full",
                get = function() return MF.db.profile.autoSaveDraft end,
                set = function(_, v) MF.db.profile.autoSaveDraft = v end,
            },
            soundEffects = {
                type = "toggle",
                name = L["OPT_SOUND"],
                order = 6,
                width = "full",
                get = function() return MF.db.profile.soundEffects end,
                set = function(_, v) MF.db.profile.soundEffects = v end,
            },
            showMinimapButton = {
                type = "toggle",
                name = L["OPT_MINIMAP"],
                order = 7,
                width = "full",
                get = function() return MF.db.profile.showMinimapButton end,
                set = function(_, v)
                    MF.db.profile.showMinimapButton = v
                    local icon = LibStub("LibDBIcon-1.0", true)
                    if icon then
                        if v then icon:Show("MacroForge") else icon:Hide("MacroForge") end
                    end
                end,
            },

            -- Editor header
            editorHeader = {
                type = "header",
                name = "|cffffff99" .. L["EDITOR"] .. "|r",
                order = 10,
            },
            fontSize = {
                type = "range",
                name = L["OPT_FONTSIZE"],
                order = 11,
                min = 10, max = 22, step = 1,
                get = function() return MF.db.profile.fontSize end,
                set = function(_, v) MF.db.profile.fontSize = v end,
            },
            fontName = {
                type = "select",
                name = L["OPT_FONT"],
                order = 12,
                dialogControl = "LSM30_Font",
                values = LSM:HashTable("font"),
                get = function() return MF.db.profile.fontName end,
                set = function(_, v) MF.db.profile.fontName = v end,
            },

            -- Backups header
            backupsHeader = {
                type = "header",
                name = "|cffffff99" .. L["BACKUPS"] .. "|r",
                order = 20,
            },
            maxBackups = {
                type = "range",
                name = L["OPT_MAX_BACKUPS"],
                order = 21,
                min = 1, max = 10, step = 1,
                get = function() return MF.db.profile.maxBackups end,
                set = function(_, v) MF.db.profile.maxBackups = v end,
            },
            maxHistory = {
                type = "range",
                name = L["OPT_MAX_HISTORY"],
                order = 22,
                min = 3, max = 30, step = 1,
                get = function() return MF.db.profile.maxHistory end,
                set = function(_, v) MF.db.profile.maxHistory = v end,
            },

            -- Data header
            dataHeader = {
                type = "header",
                name = "|cffffff99" .. L["DATA"] .. "|r",
                order = 30,
            },
            macroCount = {
                type = "description",
                name = function()
                    local na, nc = GetNumMacros()
                    return MF.C.white .. format(L["MACROS_COUNT"], nc, na) .. "|r"
                end,
                order = 31,
                fontSize = "medium",
            },
            profileCount = {
                type = "description",
                name = function()
                    local profileCount = 0
                    local charData = MF.db and MF.db.char
                    if charData and charData.profiles then
                        for _ in pairs(charData.profiles) do profileCount = profileCount + 1 end
                    end
                    local backupCount = charData and charData.backups and #charData.backups or 0
                    return MF.C.white .. format(L["PROFILES_COUNT"], profileCount, backupCount) .. "|r"
                end,
                order = 32,
                fontSize = "medium",
            },
            purgeHistory = {
                type = "execute",
                name = L["PURGE_HISTORY"],
                order = 33,
                func = function()
                    if MF.db and MF.db.char then MF.db.char.history = {} end
                    MF:Print(MF.C.green .. L["HISTORY_PURGED"] .. "|r")
                end,
                width = "half",
            },
            purgeDrafts = {
                type = "execute",
                name = L["PURGE_DRAFTS"],
                order = 34,
                func = function()
                    if MF.db and MF.db.char then MF.db.char.draft = nil end
                    MF:Print(MF.C.green .. L["DRAFTS_PURGED"] .. "|r")
                end,
                width = "half",
            },

            -- Version
            version = {
                type = "description",
                name = MF.C.grey .. "MacroForge v" .. (MF.VERSION or "7.0") .. " — by Antigravity|r",
                order = 50,
                fontSize = "small",
            },
        },
    }

    return options
end

---------------------------------------------------
-- Toggle — still supports legacy manual panel
---------------------------------------------------
function Settings:Toggle()
    -- Try Blizzard options first
    if MF.optionsFrame then
        if InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory(MF.optionsFrame)
            InterfaceOptionsFrame_OpenToCategory(MF.optionsFrame) -- twice needed for subcategories
        elseif _G.Settings and _G.Settings.OpenToCategory then
            _G.Settings.OpenToCategory(MF.optionsFrame)
        end
    else
        -- Fallback: open via AceConfigDialog
        LibStub("AceConfigDialog-3.0"):Open("MacroForge")
    end
end

function Settings:OnInitialize()
    -- No-op: defaults are handled by AceDB now
end

MF:RegisterModule("Settings", Settings)
