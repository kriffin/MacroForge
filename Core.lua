---------------------------------------------------
-- MacroForge — Core (Ace3)
-- AceAddon + AceEvent + AceConsole + AceDB
---------------------------------------------------
local ADDON_NAME = ...

-- Create the main addon with Ace3 mixins
local MF = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME,
    "AceConsole-3.0",
    "AceEvent-3.0",
    "AceHook-3.0",
    "AceSerializer-3.0",
    "AceComm-3.0"
)
_G.MacroForge = MF  -- Global ref for Bindings.lua

-- Locale
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
MF.L = L

-- Version (from TOC metadata)
MF.VERSION = C_AddOns and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or GetAddOnMetadata(ADDON_NAME, "Version") or "7.0.0"

-- Legacy compat bridge: MF.modules mirrors Ace3 modules for backward compat
MF.modules = {}

-- Couleurs raccourcies (kept for backward compat, used everywhere)
MF.C = {
    gold = "|cffffd700", cyan = "|cff00ccff", green = "|cff00ff88",
    red = "|cffff4444", orange = "|cffff9933", grey = "|cff888888",
    white = "|cffffffff", yellow = "|cffffff33", r = "|r",
}
MF.Colors = MF.C

---------------------------------------------------
-- AceDB defaults
---------------------------------------------------
local DB_DEFAULTS = {
    profile = {
        -- Options
        autoSwap = true,
        fontSize = 13,
        fontName = "Friz Quadrata TT",
        maxBackups = 3,
        maxHistory = 10,
        autocomplete = true,
        showMinimapButton = true,
        syntaxColors = true,
        autoSaveDraft = true,
        soundEffects = true,
    },
    char = {
        -- Per-character data
        profiles = {},
        backups = {},
        history = {},
        draft = nil,
    },
    global = {
        -- Minimap button position (shared across profiles)
        minimap = { hide = false, minimapPos = 220 },
    },
}

---------------------------------------------------
-- Module registration via Ace3 NewModule
-- Wraps the module table into a proper Ace3 module
---------------------------------------------------
function MF:RegisterModule(name, mod)
    -- Store in legacy bridge table
    self.modules[name] = mod
    -- If the module has OnInitialize and DB is ready, call it
    if self.db and mod.OnInitialize then
        mod:OnInitialize()
    end
end

function MF:GetModule(name)
    return self.modules[name]
end

---------------------------------------------------
-- AceAddon lifecycle
---------------------------------------------------
function MF:OnInitialize()
    -- Initialize AceDB
    self.db = LibStub("AceDB-3.0"):New("MacroForgeDB", DB_DEFAULTS, true)

    -- Migrate old flat DB structure to new AceDB structure
    self:MigrateDB()

    -- Signal initialization via AceEvent message
    self:SendMessage("MF_INIT")

    -- Initialize any legacy modules that registered before OnInitialize
    for name, mod in pairs(self.modules) do
        if mod.OnInitialize and not mod._initialized then
            mod:OnInitialize()
            mod._initialized = true
        end
    end

    -- Register AceConfig options
    local Settings = self:GetModule("Settings")
    if Settings and Settings.GetOptionsTable then
        LibStub("AceConfig-3.0"):RegisterOptionsTable("MacroForge", Settings:GetOptionsTable())
        self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MacroForge", "|cff00ccffMacro|r|cffffd700Forge|r")
    end

    -- Register slash commands via AceConsole
    self:RegisterChatCommand("mf", "HandleSlash")
    self:RegisterChatCommand("macroforge", "HandleSlash")

    -- Register AceComm prefix for direct sharing
    self:RegisterComm("MacroForge")
end

function MF:OnEnable()
    -- Register WoW events via AceEvent
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "OnSpecChanged")

    -- Signal login via AceEvent message
    self:SendMessage("MF_LOGIN")

    -- Print welcome
    local P = self:GetModule("Profiles")
    local spec = P and P:GetSpecName(P:GetCurrentSpecID()) or "?"
    self:Print(MF.C.cyan .. spec .. MF.C.r)
end

function MF:OnSpecChanged()
    self:SendMessage("MF_SPEC_CHANGED")
end

---------------------------------------------------
-- DB Migration (old flat → new AceDB)
---------------------------------------------------
function MF:MigrateDB()
    -- If old-style flat data exists from v6, migrate it
    local raw = _G.MacroForgeDB
    if raw and raw.profiles and not raw.profileKeys then
        -- This is old-style data, AceDB hasn't touched it yet
        -- We need to be careful: AceDB:New already wrapped it
        -- Check if char data needs migration
        if raw.profiles and type(raw.profiles) == "table" then
            -- Old profiles were spec-based macro sets
            local charData = self.db.char
            if not next(charData.profiles) then
                for k, v in pairs(raw.profiles) do
                    if type(v) == "table" and v.macros then
                        charData.profiles[k] = v
                    end
                end
            end
        end
        if raw.backups and type(raw.backups) == "table" and #raw.backups > 0 then
            if not self.db.char.backups or #self.db.char.backups == 0 then
                self.db.char.backups = raw.backups
            end
        end
        if raw.history and type(raw.history) == "table" then
            if not self.db.char.history or not next(self.db.char.history) then
                self.db.char.history = raw.history
            end
        end
        if raw.options and type(raw.options) == "table" then
            for k, v in pairs(raw.options) do
                if self.db.profile[k] ~= nil then
                    self.db.profile[k] = v
                end
            end
        end
        if raw.draft then
            self.db.char.draft = raw.draft
        end
        if raw.minimap then
            self.db.global.minimap = raw.minimap
        end
    end
end

---------------------------------------------------
-- Slash command handler (via AceConsole)
---------------------------------------------------
function MF:HandleSlash(msg)
    local cmd = (msg:match("^(%S+)") or ""):lower()
    local arg = msg:match("^%S+%s+(.+)") or ""
    local P, UI = self:GetModule("Profiles"), self:GetModule("UI")

    if cmd == "" or cmd == "show" then
        if UI then UI:Toggle() end
    elseif cmd == "save" then if P then P:SaveCurrentProfile() end
    elseif cmd == "load" then if P then P:LoadCurrentProfile() end
    elseif cmd == "backup" then if P then P:CreateBackup() end
    elseif cmd == "restore" then if P then P:RestoreBackup(tonumber(arg) or 1) end
    elseif cmd == "list" then if P then P:ListProfiles() end
    elseif cmd == "autoswap" then if P then P:ToggleAutoSwap() end
    elseif cmd == "analyze" then self:SendMessage("MF_ANALYZE_ALL")
    elseif cmd == "builder" then
        local B = self:GetModule("Builder")
        if B then B:Toggle() end
    elseif cmd == "commands" or cmd == "cmd" then
        local CP = self:GetModule("CommandPalette")
        if CP then CP:Toggle() end
    elseif cmd == "templates" then
        local T = self:GetModule("Templates")
        if T and T.OpenBrowser then T:OpenBrowser() end
    elseif cmd == "share" then
        local S = self:GetModule("Share")
        local E = self:GetModule("Editor")
        if S and E and E.cur then
            S:OpenExport(E.cur.name or "", E.cur.icon or 134400, E.cur.body or "")
        elseif S then
            S:OpenImport()
        end
    elseif cmd == "import" then
        local S = self:GetModule("Share")
        if S then S:OpenImport() end
    elseif cmd == "export" then
        local E = self:GetModule("Editor")
        if E then E:OpenExport() end
    elseif cmd == "duplicates" or cmd == "dupes" then
        local D = self:GetModule("DuplicateDetector")
        if D then D:OpenBrowser() end
    elseif cmd == "settings" or cmd == "options" then
        -- Open Blizzard options or custom panel
        if self.optionsFrame then
            if InterfaceOptionsFrame_OpenToCategory then
                InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
            elseif _G.Settings and _G.Settings.OpenToCategory then
                _G.Settings.OpenToCategory(self.optionsFrame)
            end
        else
            local S = self:GetModule("Settings")
            if S then S:Toggle() end
        end
    elseif cmd == "history" then
        local H = self:GetModule("History")
        local E = self:GetModule("Editor")
        if H and E and E.cur and E.cur.index then
            H:OpenBrowser(E.cur.index)
        else
            self:Print(MF.C.yellow .. L["OPEN_MACRO_FIRST"] .. "|r")
        end
    elseif cmd == "send" then
        local S = self:GetModule("Share")
        if S and S.OpenSend then S:OpenSend() end
    elseif cmd == "help" then self:PrintHelp()
    else
        self:Print(MF.C.red .. format(L["UNKNOWN_CMD"], cmd) .. "|r")
    end
end

function MF:PrintHelp()
    local c = MF.C
    self:Print(c.gold .. format(L["HELP_TITLE"], self.VERSION) .. c.r)
    local cmds = {
        { "/mf", L["HELP_SHOW"] },
        { "/mf save", L["HELP_SAVE"] },
        { "/mf load", L["HELP_LOAD"] },
        { "/mf backup", L["HELP_BACKUP"] },
        { "/mf restore [1-3]", L["HELP_RESTORE"] },
        { "/mf autoswap", L["HELP_AUTOSWAP"] },
        { "/mf analyze", L["HELP_ANALYZE"] },
        { "/mf builder", L["HELP_BUILDER"] },
        { "/mf commands", L["HELP_COMMANDS"] },
        { "/mf templates", L["HELP_TEMPLATES"] },
        { "/mf share", L["HELP_SHARE"] },
        { "/mf import", L["HELP_IMPORT"] },
        { "/mf export", L["HELP_EXPORT"] },
        { "/mf duplicates", L["HELP_DUPLICATES"] },
        { "/mf history", L["HELP_HISTORY"] },
        { "/mf send", "Send macro to player (AceComm)" },
        { "/mf settings", L["HELP_SETTINGS"] },
    }
    for _, v in ipairs(cmds) do
        self:Print(c.cyan .. v[1] .. "|r - " .. v[2])
    end
    self:Print(c.grey .. L["HELP_SHORTCUTS"] .. c.r)
end

---------------------------------------------------
-- AceComm handler (receive macros from other players)
---------------------------------------------------
function MF:OnCommReceived(prefix, message, distribution, sender)
    if prefix ~= "MacroForge" then return end
    if sender == UnitName("player") then return end

    local success, data = self:Deserialize(message)
    if not success or not data or not data.name then return end

    -- Show dialog to accept
    StaticPopupDialogs["MACROFORGE_RECV"] = {
        text = format(L["RECV_DIALOG"], sender, data.name),
        button1 = L["RECV_ACCEPT"],
        button2 = L["RECV_DECLINE"],
        OnAccept = function()
            local E = self:GetModule("Editor")
            if E then
                E:OpenNew(true)
                C_Timer.After(0.1, function()
                    E:LoadContent(data.name, data.body, data.icon)
                end)
            end
            self:Print(MF.C.green .. format(L["RECV_MACRO"], sender, data.name) .. "|r")
        end,
        timeout = 60,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show("MACROFORGE_RECV")
end
