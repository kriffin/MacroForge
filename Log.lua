---------------------------------------------------
-- MacroForge — Log
-- Persistent debug log, readable outside the game.
--
-- Entries go to the MacroForgeLog SavedVariable (a ring buffer of plain
-- text lines), which the client writes to
--   WTF/Account/<account>/SavedVariables/MacroForge.lua
-- on /reload, logout or exit. tools/read-logs.lua prints it along with the
-- BugGrabber errors.
--
-- INFO/WARN/ERROR are always recorded; DEBUG only with /mf debug on, which
-- also echoes every entry to the chat frame.
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")

local MAX_LINES = 2000
local LEVELS = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }
local CHAT_COLORS = { DEBUG = "|cff888888", INFO = "|cff00ccff", WARN = "|cffffff33", ERROR = "|cffff4444" }

local function Store()
    if type(MacroForgeLog) ~= "table" then MacroForgeLog = {} end
    MacroForgeLog.lines = MacroForgeLog.lines or {}
    MacroForgeLog.session = MacroForgeLog.session or 0
    return MacroForgeLog
end

local function Stringify(...)
    local n = select("#", ...)
    local parts = {}
    for i = 1, n do
        local v = select(i, ...)
        parts[i] = type(v) == "string" and v or tostring(v)
    end
    return table.concat(parts, " ")
end

-- MF:Log("INFO", "sets", "applied %s (%d macros)", name, count)
-- With no format args, the message is used as is (no % escaping needed).
function MF:Log(level, category, msg, ...)
    level = LEVELS[level] and level or "INFO"
    local log = Store()
    if level == "DEBUG" and not log.debug then return end

    if select("#", ...) > 0 then
        local ok, formatted = pcall(format, msg, ...)
        msg = ok and formatted or Stringify(msg, ...)
    end
    msg = tostring(msg):gsub("\n", " \\n ")

    local line = format("%s #%d [%s] %s: %s", date("%Y-%m-%d %H:%M:%S"), log.session, level, category or "-", msg)
    local lines = log.lines
    lines[#lines + 1] = line
    if #lines > MAX_LINES then
        table.remove(lines, 1)
    end

    if log.debug then
        print(CHAT_COLORS[level] .. "MF " .. level .. "|r " .. (category or "-") .. ": " .. msg)
    end
end

function MF:Debug(category, msg, ...) self:Log("DEBUG", category, msg, ...) end

function MF:SetDebug(enabled)
    Store().debug = enabled or nil
    self:Print(format(L["LOG_DEBUG_STATE"], enabled and ("|cff00ff88" .. L["STATE_ON"] .. "|r") or ("|cffff4444" .. L["STATE_OFF"] .. "|r")))
end

function MF:IsDebug()
    return Store().debug == true
end

-- /mf log [n|clear]: last n lines in chat, or wipe the log
function MF:PrintLog(arg)
    local log = Store()
    if arg == "clear" then
        wipe(log.lines)
        self:Print(L["LOG_CLEARED"])
        return
    end
    local n = tonumber(arg) or 20
    local lines = log.lines
    self:Print(format(L["LOG_STATUS"], #lines, log.session, log.debug and L["STATE_ON"] or L["STATE_OFF"]))
    for i = math.max(1, #lines - n + 1), #lines do
        print("|cff888888" .. lines[i] .. "|r")
    end
end

---------------------------------------------------
-- Session header + mirror of MacroForge errors caught by BugGrabber
---------------------------------------------------
function MF:StartLogSession()
    local log = Store()
    log.session = log.session + 1
    local _, build, _, interface = GetBuildInfo()
    local name, realm = UnitFullName("player")
    self:Log("INFO", "session", "start v%s build=%s interface=%s char=%s-%s",
        self.VERSION or "?", tostring(build), tostring(interface), tostring(name), tostring(realm or GetRealmName()))

    -- BugGrabber keeps the full stack; the log only gets a pointer line so the
    -- timeline shows when an error happened relative to MacroForge actions.
    local grabber = _G.BugGrabber
    if grabber and grabber.RegisterCallback then
        pcall(grabber.RegisterCallback, self, "BugGrabber_BugGrabbed", function(_, err)
            local message = err and err.message or ""
            if message:find("MacroForge", 1, true) then
                self:Log("ERROR", "lua", "%s (x%d)", message, err.counter or 1)
            end
        end)
    end
end

---------------------------------------------------
-- Client dump (/mf dump): what this client really offers, written to the
-- SavedVariables (MacroForgeDB.global.dump) so it can be read off disk:
-- API documentation of this build, playable classes, the spells behind the
-- templates, how each macro condition parses, the character's spellbook.
---------------------------------------------------
local function Signature(fn)
    local args, rets = {}, {}
    for _, a in ipairs(fn.Arguments or {}) do table.insert(args, a.Name .. ":" .. tostring(a.Type)) end
    for _, r in ipairs(fn.Returns or {}) do table.insert(rets, r.Name .. ":" .. tostring(r.Type)) end
    return fn.Name .. "(" .. table.concat(args, ", ") .. ")" .. (#rets > 0 and (" -> " .. table.concat(rets, ", ")) or "")
end

function MF:DumpClient()
    local dump = { time = date("%Y-%m-%d %H:%M:%S"), locale = GetLocale() }
    local _, build, _, interface = GetBuildInfo()
    dump.build, dump.interface = build, interface

    -- API documentation (what /api browses)
    local load = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
    pcall(load, "Blizzard_APIDocumentationGenerated")
    pcall(load, "Blizzard_APIDocumentation")
    dump.api = {}
    local doc = _G.APIDocumentation
    for _, sys in ipairs(doc and doc.systems or {}) do
        local entry = { functions = {}, events = {} }
        for _, fn in ipairs(sys.Functions or {}) do table.insert(entry.functions, Signature(fn)) end
        for _, ev in ipairs(sys.Events or {}) do table.insert(entry.events, ev.LiteralName or ev.Name) end
        dump.api[(sys.Namespace or sys.Name or "?")] = entry
    end

    -- Playable classes
    dump.classes = {}
    dump.classes = MF.Helpers:PlayableClasses()

    -- Every spell ID used by a template, resolved in this client
    dump.templateSpells = {}
    local T = self:GetModule("Templates")
    local lists = { T and T.UNIVERSAL or {} }
    for _, l in pairs(T and T.CLASS_TEMPLATES or {}) do table.insert(lists, l) end
    for _, l in ipairs(lists) do
        for _, tmpl in ipairs(l) do
            for id in (tmpl.body or ""):gmatch("{spell:(%d+):") do
                dump.templateSpells[id] = C_Spell.GetSpellName(tonumber(id)) or false
            end
        end
    end

    -- How each builder condition parses here (unknown ones error or never match)
    dump.conditions = {}
    local B = self:GetModule("Builder")
    for _, c in ipairs(B and B.CONDITIONS or {}) do
        if c.value ~= "" then
            local test = c.hasArg and (c.value .. ":1") or c.value
            local ok, res = pcall(SecureCmdOptionParse, "[" .. test .. "] yes; no")
            dump.conditions[c.value] = ok and tostring(res) or ("ERROR " .. tostring(res))
        end
    end

    -- The logged character's spellbook (names and IDs as this client has them)
    dump.spellbook = {}
    for _, sp in ipairs(MF.Helpers:GetSpellbookSpells()) do
        table.insert(dump.spellbook, (sp.id or "?") .. " " .. sp.name)
    end
    dump.class = select(2, UnitClass("player"))

    self.db.global.dump = dump
    local n = 0
    for _ in pairs(dump.api) do n = n + 1 end
    self:Print(format("dump: %d API systems, %d classes, %d spells. /reload to write it to disk.",
        n, #dump.classes, #dump.spellbook))
end
