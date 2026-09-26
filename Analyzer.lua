---------------------------------------------------
-- MacroForge — Analyzer (MacroToolkit-powered)
-- Dynamic spell/command/condition validation
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local A = {}

-- Colors for syntax highlighting
A.SYN = {
    cmd    = "|cff00ccff",  -- cyan: valid command
    cond   = "|cffffff33",  -- yellow: [conditions]
    spell  = "|cff00ff88",  -- green: known spell
    item   = "|cff33aa55",  -- dark green: known item
    unk    = "|cffff6633",  -- orange: unverified
    err    = "|cffff4444",  -- red: error
    dir    = "|cff888888",  -- grey: #showtooltip
    text   = "|cffcccccc",  -- light grey: plain text
    seq    = "|cff66ccff",  -- light blue: sequence
    target = "|cffcc88ff",  -- purple: target
    emote  = "|cffff88ff",  -- pink: emote
    r      = "|r",
}

---------------------------------------------------
-- Dynamic Command List (ported from MacroToolkit)
-- Scans ALL SLASH_* globals at runtime
---------------------------------------------------
local commands = {}       -- { cmdname = { shortest, paramType, isEmote } }
local castAliases = {}    -- { "cast", "spell", ... }
local scriptAliases = {}  -- { "script", "run" }
local seqAliases = {}     -- { "castsequence" }
local cmdBuilt = false

local COMMAND_PARAM_REQUIRED = 1
local COMMAND_PARAM_OPTIONAL = 2
local COMMAND_PARAM_REMOVED = 5

-- Static commandinfo table (from MacroToolkit initialise.lua)
local commandinfo = {
    SHOW = COMMAND_PARAM_OPTIONAL, SHOWTOOLTIP = COMMAND_PARAM_OPTIONAL,
    ASSIST = COMMAND_PARAM_OPTIONAL, CANCELAURA = COMMAND_PARAM_REQUIRED,
    CAST = COMMAND_PARAM_REQUIRED, CASTRANDOM = COMMAND_PARAM_REQUIRED,
    CASTSEQUENCE = COMMAND_PARAM_REQUIRED, CHANGEACTIONBAR = COMMAND_PARAM_REQUIRED,
    CLICK = COMMAND_PARAM_REQUIRED, CONSOLE = COMMAND_PARAM_REQUIRED,
    EMOTE = COMMAND_PARAM_REQUIRED, EQUIP = COMMAND_PARAM_REQUIRED,
    EQUIP_SET = COMMAND_PARAM_REQUIRED, EQUIP_TO_SLOT = COMMAND_PARAM_REQUIRED,
    FOCUS = COMMAND_PARAM_OPTIONAL, FOLLOW = COMMAND_PARAM_OPTIONAL,
    GUILD = COMMAND_PARAM_REQUIRED, IGNORE = COMMAND_PARAM_REQUIRED,
    INVITE = COMMAND_PARAM_REQUIRED, PARTY = COMMAND_PARAM_REQUIRED,
    PET_AUTOCASTOFF = COMMAND_PARAM_REQUIRED, PET_AUTOCASTON = COMMAND_PARAM_REQUIRED,
    PET_AUTOCASTTOGGLE = COMMAND_PARAM_REQUIRED,
    RAID = COMMAND_PARAM_REQUIRED, RAID_WARNING = COMMAND_PARAM_REQUIRED,
    SAY = COMMAND_PARAM_REQUIRED, SCRIPT = COMMAND_PARAM_REQUIRED,
    STARTATTACK = COMMAND_PARAM_OPTIONAL, SWAPACTIONBAR = COMMAND_PARAM_REQUIRED,
    TARGET = COMMAND_PARAM_REQUIRED, TARGET_EXACT = COMMAND_PARAM_REQUIRED,
    TARGET_NEAREST_ENEMY = COMMAND_PARAM_OPTIONAL,
    TARGET_NEAREST_ENEMY_PLAYER = COMMAND_PARAM_OPTIONAL,
    TARGET_NEAREST_FRIEND = COMMAND_PARAM_OPTIONAL,
    TARGET_NEAREST_FRIEND_PLAYER = COMMAND_PARAM_OPTIONAL,
    TARGET_NEAREST_PARTY = COMMAND_PARAM_OPTIONAL,
    TARGET_NEAREST_RAID = COMMAND_PARAM_OPTIONAL,
    USE = COMMAND_PARAM_REQUIRED, USERANDOM = COMMAND_PARAM_REQUIRED,
    YELL = COMMAND_PARAM_REQUIRED, WHISPER = COMMAND_PARAM_REQUIRED,
    SMART_WHISPER = COMMAND_PARAM_REQUIRED,
}

local function escape(s) return (s:gsub("[%-%.%+%[%]%(%)%$%^%%%?%*]","%%%1"):gsub("%z","%%z")) end

local function findShortest(cglobal)
    local shortest = string.rep("x", 99)
    for c = 1, 99 do
        local current = _G[string.format("%s%s", cglobal, c)]
        if current then
            if #current < #shortest then shortest = current end
        else break end
    end
    return shortest
end

function A:BuildCommandList()
    if cmdBuilt then return end
    cmdBuilt = true
    wipe(commands); wipe(castAliases); wipe(scriptAliases); wipe(seqAliases)

    -- Register #show and #showtooltip
    _G.SLASH_SHOW1 = "#show"
    _G.SLASH_SHOWTOOLTIP1 = "#showtooltip"

    local castmax, usemax, randommax, usermax = 0, 0, 0, 0
    for k, v in pairs(_G) do
        if type(v) == "string" and k:sub(1, 6) == "SLASH_" then
            local dpos = k:find("%d+$") or 2
            local digit = tonumber(k:match("%d+$"))
            local cglobal = k:sub(1, dpos - 1)

            if cglobal == "SLASH_CAST" then
                if digit and digit > castmax then castmax = digit end
                castAliases[v:sub(2)] = true
            elseif cglobal == "SLASH_USE" then
                if digit and digit > usemax then usemax = digit end
                castAliases[v:sub(2)] = true
            elseif cglobal == "SLASH_CASTRANDOM" then
                if digit and digit > randommax then randommax = digit end
            elseif cglobal == "SLASH_USERANDOM" then
                if digit and digit > usermax then usermax = digit end
            elseif cglobal == "SLASH_CASTSEQUENCE" then
                seqAliases[v:sub(2)] = true
            elseif cglobal == "SLASH_SCRIPT" then
                scriptAliases[v:sub(2)] = true
            end
        end
    end
    -- Merge use into cast
    for c = 1, usemax do _G[string.format("SLASH_CAST%d", castmax + c)] = _G[string.format("SLASH_USE%d", c)] end
    for r = 1, usermax do _G[string.format("SLASH_CASTRANDOM%d", randommax + r)] = _G[string.format("SLASH_USERANDOM%d", r)] end

    -- Second pass: build full command table
    for k, v in pairs(_G) do
        if type(v) == "string" then
            if k:sub(1, 6) == "SLASH_" and not k:find("STOPWATCH_PARAM_") then
                local dpos = k:find("%d+$")
                if not dpos then dpos = #k + 1 end
                local cglobal = k:sub(1, dpos - 1)
                local command = v:sub(2)
                local shortest = findShortest(cglobal):sub(2)
                local param = commandinfo[cglobal:sub(7)] or 0
                commands[command] = { shortest, param }
            elseif k:find("EMOTE%d+_CMD") then
                local command = v:sub(2)
                commands[command] = { command, 0, true }
            end
        end
    end
end

function A:IsKnownCommand(cmd)
    if not cmd then return false end
    local c = cmd:lower():sub(2) -- strip /
    if commands[c] then return true end
    if IsSecureCmd and IsSecureCmd(cmd) then return true end
    return false
end

function A:IsCastCmd(cmd)
    return castAliases[cmd:lower():sub(2)] or false
end

function A:IsSeqCmd(cmd)
    return seqAliases[cmd:lower():sub(2)] or false
end

---------------------------------------------------
-- Conditions (from MacroToolkit initialise.lua)
---------------------------------------------------
local CTYPE_NONE = 0
local CTYPE_NUMERIC = 1
local CTYPE_TEXTUAL = 2
local CTYPE_ALPHANUMERIC = 3
local CTYPE_PARTY_RAID = 4
local CTYPE_MOD_KEYS = 5
local CTYPE_MOUSEBUTTONS = 6
local CTYPE_NUMERIC_SLASH = 7
local CTYPE_ALPHANUM_SPACES = 8

local CONDITIONS = {
    actionbar = CTYPE_NUMERIC, advflyable = CTYPE_NONE,
    bar = CTYPE_NUMERIC, bonusbar = CTYPE_NUMERIC,
    btn = CTYPE_MOUSEBUTTONS, button = CTYPE_MOUSEBUTTONS,
    canexitvehicle = CTYPE_NONE, channeling = CTYPE_ALPHANUMERIC,
    channelling = CTYPE_ALPHANUMERIC, combat = CTYPE_NONE,
    cursor = CTYPE_TEXTUAL, dead = CTYPE_NONE,
    equipped = CTYPE_TEXTUAL, exists = CTYPE_NONE,
    extrabar = CTYPE_NUMERIC, flyable = CTYPE_NONE,
    flying = CTYPE_NONE, form = CTYPE_NUMERIC,
    group = CTYPE_PARTY_RAID, harm = CTYPE_NONE,
    help = CTYPE_NONE, house = CTYPE_TEXTUAL,
    indoors = CTYPE_NONE, known = CTYPE_ALPHANUM_SPACES,
    mod = CTYPE_MOD_KEYS, modifier = CTYPE_MOD_KEYS,
    mounted = CTYPE_NONE, none = CTYPE_NONE,
    outdoors = CTYPE_NONE, overridebar = CTYPE_NONE,
    party = CTYPE_NONE, pet = CTYPE_TEXTUAL,
    petbattle = CTYPE_NONE, possessbar = CTYPE_NUMERIC,
    pvptalent = CTYPE_NUMERIC_SLASH, raid = CTYPE_NONE,
    spec = CTYPE_NUMERIC, stance = CTYPE_NUMERIC,
    stealth = CTYPE_NONE, swimming = CTYPE_NONE,
    talent = CTYPE_NUMERIC_SLASH,
    unithasvehicleui = CTYPE_NONE, vehicleui = CTYPE_NONE,
    worn = CTYPE_TEXTUAL,
}

local OPTIONAL_CONDS = { channeling=true, channelling=true, group=true, house=true, mod=true, modifier=true, pet=true }

local VALID_MOD_KEYS = {}
do
    local mods = {"cmd","ctrl","shift","alt"}
    -- Generate all combinations
    local function genCombo(arr, combo, used, out)
        combo = combo or {}; used = used or {}; out = out or {}
        if #combo > 0 then out[table.concat(combo, "")] = true end
        for i, m in ipairs(arr) do
            if not used[i] then
                used[i] = true; combo[#combo+1] = m
                genCombo(arr, combo, used, out)
                combo[#combo] = nil; used[i] = false
            end
        end
        return out
    end
    VALID_MOD_KEYS = genCombo(mods)
    -- Also add special bindings
    for _, k in ipairs({"AUTOLOOTTOGGLE","STICKCAMERA","SPLITSTACK","PICKUPACTION",
        "COMPAREITEMS","OPENALLBAGS","QUESTWATCHTOGGLE","SELFCAST"}) do
        VALID_MOD_KEYS[k] = true
    end
end

local VALID_BUTTONS = {}
for _, b in ipairs({"1","2","3","4","5","LeftButton","MiddleButton","RightButton","Button4","Button5"}) do
    VALID_BUTTONS[b:lower()] = true
end

local VALID_GROUP = { party = true, raid = true }

---------------------------------------------------
-- Levenshtein Distance (from MacroToolkit)
---------------------------------------------------
local function getLevenshtein(s, t, lim)
    local slen, tlen = #s, #t
    if lim and math.abs(slen - tlen) >= lim then return lim end
    if type(s) == "string" then s = {string.byte(s, 1, slen)} end
    if type(t) == "string" then t = {string.byte(t, 1, tlen)} end
    local numcols = tlen + 1
    local d = {}
    for i = 0, slen do d[i * numcols] = i end
    for j = 0, tlen do d[j] = j end
    for i = 1, slen do
        local ipos = i * numcols
        local best = lim
        for j = 1, tlen do
            local addcost = (s[i] ~= t[j] and 1 or 0)
            local val = math.min(d[ipos - numcols + j] + 1, d[ipos + j - 1] + 1, d[ipos - numcols + j - 1] + addcost)
            d[ipos + j] = val
            if i > 1 and j > 1 and s[i] == t[j-1] and s[i-1] == t[j] then
                d[ipos + j] = math.min(val, d[ipos - numcols - numcols + j - 2] + addcost)
            end
            if lim and val < best then best = val end
        end
        if lim and best >= lim then return lim end
    end
    return d[#d]
end

-- Ties are common ("csat" is one edit from both "cast" and "cat"): prefer
-- the secure macro commands, then the same length, then alphabetical, so
-- the answer does not depend on the table's iteration order
local function Better(k, best, source)
    local sk = IsSecureCmd and IsSecureCmd("/" .. k) and 1 or 0
    local sb = IsSecureCmd and IsSecureCmd("/" .. best) and 1 or 0
    if sk ~= sb then return sk > sb end
    local lk, lb = math.abs(#k - #source), math.abs(#best - #source)
    if lk ~= lb then return lk < lb end
    return k < best
end

function A:FindBestMatch(source)
    local diff, bestmatch = 99, ""
    for k, _ in pairs(commands) do
        local d = getLevenshtein(source, k)
        if d < diff or (d == diff and Better(k, bestmatch, source)) then diff = d; bestmatch = k end
    end
    return bestmatch, diff
end

---------------------------------------------------
-- Spell/Item validation cache (enhanced)
---------------------------------------------------
local spellCache = {}
local talentCache

local function buildTalentCache()
    if talentCache then return talentCache end
    talentCache = {}
    local ok, LibTalentTree = pcall(function() return LibStub("LibTalentTree-1.0") end)
    if not ok or not LibTalentTree or not LibTalentTree.IsCompatible or not LibTalentTree:IsCompatible() then return talentCache end

    local treeId = LibTalentTree:GetClassTreeID(UnitClassBase and UnitClassBase('player') or '')
    if not treeId then return talentCache end
    local nodes = C_Traits and C_Traits.GetTreeNodes and C_Traits.GetTreeNodes(treeId) or {}
    for _, nodeId in ipairs(nodes) do
        local nodeInfo = LibTalentTree:GetNodeInfo(nodeId)
        for _, entryID in ipairs(nodeInfo and nodeInfo.entryIDs or {}) do
            local entryInfo = LibTalentTree:GetEntryInfo(entryID)
            local defInfo = entryInfo and entryInfo.definitionID and C_Traits.GetDefinitionInfo(entryInfo.definitionID)
            local spellID = defInfo and defInfo.spellID
            if spellID and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID) then
                talentCache[C_Spell.GetSpellName(spellID):lower()] = spellID
            end
        end
    end
    return talentCache
end

function A:CheckSpell(name)
    if not name or name == "" or name:match("^%d+$") then return nil end
    if spellCache[name] ~= nil then return spellCache[name] end

    -- Try spell API
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(name)
    if info then
        spellCache[name] = { type = "spell", icon = info.iconID, id = info.spellID }
        return spellCache[name]
    end

    -- Try talent cache
    local tc = buildTalentCache()
    local spellID = tc[name:lower()]
    if spellID then
        local si = C_Spell.GetSpellInfo(spellID)
        if si then
            spellCache[name] = { type = "spell", icon = si.iconID, id = si.spellID }
            return spellCache[name]
        end
    end

    -- Try item
    local GetItemInfo = GetItemInfo or (C_Item and C_Item.GetItemInfo)
    if GetItemInfo then
        local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(name)
        if itemName then
            spellCache[name] = { type = "item", icon = itemIcon }
            return spellCache[name]
        end
    end

    spellCache[name] = false
    return false
end

---------------------------------------------------
-- Condition Validation (from MacroToolkit)
---------------------------------------------------
local IS_FOREVER = select(4, GetBuildInfo()) < 20000
local FOREVER_UNSUPPORTED = { pvptalent = true, advflyable = true, petbattle = true }

function A:ValidateCondition(cond, args)
    -- Strip leading 'no' prefix for checking
    local rawCond = cond
    if cond:sub(1, 2) == "no" then rawCond = cond:sub(3) end

    -- Is it a target spec? @X or target=X
    if cond:match("^@") or cond:match("^target%s*=") then
        return true, nil -- target specs are always valid
    end

    local ctype = CONDITIONS[rawCond]
    -- WoW Forever parses these but has no such thing: an unknown condition
    -- is TRUE there, so [pvptalent:1] would always fire (checked in game)
    if IS_FOREVER and FOREVER_UNSUPPORTED[rawCond] then
        return false, MF.C.yellow .. L["ANALYZER_NOT_ON_FOREVER"]:format(cond) .. "|r"
    end
    if ctype == nil then
        -- Unknown condition — find best match
        local best = self:FindBestCondition(rawCond)
        local msg = MF.C.red .. L["ANALYZER_INVALID_CONDITION"]:format(cond) .. "|r"
        if best and best ~= "" then
            msg = msg .. "  " .. MF.C.green .. "-> " .. best .. "|r"
        end
        return false, msg
    end

    -- Check if arguments are required/valid
    if #args == 0 then
        if ctype ~= CTYPE_NONE and not OPTIONAL_CONDS[rawCond] and cond:sub(1,2) ~= "no" then
            return false, MF.C.yellow .. L["ANALYZER_MISSING_ARG"]:format(cond) .. "|r"
        end
        return true, nil
    end

    -- Validate argument types
    if ctype == CTYPE_NONE then
        return false, MF.C.yellow .. L["ANALYZER_NO_ARG_EXPECTED"]:format(cond) .. "|r"
    elseif ctype == CTYPE_NUMERIC or ctype == CTYPE_NUMERIC_SLASH then
        for _, a in ipairs(args) do
            local clean = a:gsub("/", "")
            if not tonumber(clean) then
                return false, MF.C.red .. L["ANALYZER_NUMERIC_ARG_EXPECTED"]:format(cond, a) .. "|r"
            end
        end
    elseif ctype == CTYPE_MOD_KEYS then
        for _, a in ipairs(args) do
            local key = a:gsub(":", ""):gsub(" ", ""):lower()
            if not VALID_MOD_KEYS[key] then
                return false, MF.C.yellow .. L["ANALYZER_UNKNOWN_KEY"]:format(a) .. "|r"
            end
        end
    elseif ctype == CTYPE_MOUSEBUTTONS then
        for _, a in ipairs(args) do
            if not VALID_BUTTONS[a:lower()] then
                return false, MF.C.yellow .. L["ANALYZER_UNKNOWN_BUTTON"]:format(a) .. "|r"
            end
        end
    elseif ctype == CTYPE_PARTY_RAID then
        for _, a in ipairs(args) do
            if not VALID_GROUP[a:lower()] then
                return false, MF.C.yellow .. L["ANALYZER_INVALID_GROUP_VALUE"]:format(a) .. "|r"
            end
        end
    end

    return true, nil
end

function A:FindBestCondition(source)
    local diff, best = 99, ""
    for k, _ in pairs(CONDITIONS) do
        local d = getLevenshtein(source, k)
        if d < diff then diff = d; best = k end
    end
    return best
end

---------------------------------------------------
-- Colorize preview (enhanced)
---------------------------------------------------
function A:ColorizeLine(line)
    if not line or line == "" then return "" end

    -- #showtooltip / #show
    if line:match("^#") then return A.SYN.dir .. line .. A.SYN.r end

    -- Extract command
    local cmd = line:match("^(/[%a]+)")
    if not cmd then return A.SYN.text .. line .. A.SYN.r end

    local cmdColor
    if self:IsKnownCommand(cmd) then
        cmdColor = A.SYN.cmd
    else
        cmdColor = A.SYN.err
    end
    local rest = line:sub(#cmd + 1)

    -- For /cast and /use: colorize conditionals and spell names
    if self:IsCastCmd(cmd) or self:IsSeqCmd(cmd) or cmd:lower() == "/castrandom" or cmd:lower() == "/userandom" then
        local colored = cmdColor .. cmd .. A.SYN.r
        local pos = 1
        while pos <= #rest do
            local c = rest:sub(pos, pos)
            if c == "[" then
                local closePos = rest:find("]", pos + 1)
                if closePos then
                    colored = colored .. A.SYN.cond .. rest:sub(pos, closePos) .. A.SYN.r
                    pos = closePos + 1
                else
                    colored = colored .. A.SYN.err .. rest:sub(pos) .. A.SYN.r
                    break
                end
            elseif c == ";" then
                colored = colored .. A.SYN.text .. ";" .. A.SYN.r
                pos = pos + 1
            elseif c == " " or c == "," then
                colored = colored .. c; pos = pos + 1
            else
                local nameEnd = rest:find("[;]", pos) or (#rest + 1)
                local spellName = rest:sub(pos, nameEnd - 1):match("^%s*(.-)%s*$")
                if spellName and spellName ~= "" then
                    local check = self:CheckSpell(spellName)
                    if check and check.type == "spell" then
                        colored = colored .. A.SYN.spell .. spellName .. A.SYN.r
                    elseif check and check.type == "item" then
                        colored = colored .. A.SYN.item .. spellName .. A.SYN.r
                    elseif check == false then
                        colored = colored .. A.SYN.unk .. spellName .. A.SYN.r
                    else
                        colored = colored .. A.SYN.text .. spellName .. A.SYN.r
                    end
                end
                pos = nameEnd
            end
        end
        return colored
    end

    return cmdColor .. cmd .. A.SYN.r .. A.SYN.text .. rest .. A.SYN.r
end

function A:ColorizeBody(body)
    if not body or body == "" then return "" end
    local lines = {}
    for line in body:gmatch("[^\n]+") do
        table.insert(lines, self:ColorizeLine(line))
    end
    return table.concat(lines, "\n")
end

---------------------------------------------------
-- Syntax of the options: [conditions] come first in each ;-separated
-- clause of a command that takes them. Finds the first mistake on a line
-- and, when the intent is clear, the corrected line.
---------------------------------------------------
-- Conditions whose argument may hold spaces ([known:Fire Blast]): a space
-- after one of them can be part of the argument, never a safe split point
local SPACED_ARG = { [CTYPE_TEXTUAL] = true, [CTYPE_ALPHANUMERIC] = true, [CTYPE_ALPHANUM_SPACES] = true }

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- A single condition phrase with nothing wrong: @unit, target=unit, or a
-- known condition with valid arguments
local function IsCondPhrase(phrase)
    phrase = trim(phrase)
    if phrase:match("^@[%w]+$") or phrase:match("^target=[%w]+$") then return true end
    local cond, argStr = phrase:match("^(%a+):?(.*)$")
    if not cond then return false end
    cond = cond:lower()
    local args = {}
    for a in (argStr .. "/"):gmatch("([^/]*)/") do
        a = trim(a)
        if a ~= "" then args[#args + 1] = a end
    end
    local ok = A:ValidateCondition(cond, args)
    return ok, cond, #args > 0
end

local function TakesSpacedArg(phrase)
    local ok, cond, hasArg = IsCondPhrase(phrase)
    if not ok or not hasArg then return false end
    return SPACED_ARG[CONDITIONS[cond:gsub("^no", "")] or CONDITIONS[cond]] or false
end

-- Every comma-separated phrase of s is a valid condition, with no space inside
local function AllCondPhrases(s)
    if trim(s) == "" then return false end
    for phrase in (s .. ","):gmatch("([^,]*),") do
        phrase = trim(phrase)
        if phrase ~= "" and (phrase:find("%s") or not IsCondPhrase(phrase)) then return false end
    end
    return true
end

-- Tokens of the text after the command: cond ([...]), text, semi (;).
-- Stops at the first bracket error: { kind, at [, reopen] }
local function Tokenize(rest)
    local toks, pos, n = {}, 1, #rest
    while pos <= n do
        local c = rest:sub(pos, pos)
        if c == "[" then
            local close = rest:find("]", pos + 1, true)
            local reopen = rest:find("[", pos + 1, true)
            if reopen and (not close or reopen < close) then
                return toks, { kind = "nested", at = pos, reopen = reopen }
            end
            if not close then return toks, { kind = "unclosed", at = pos } end
            toks[#toks + 1] = { t = "cond", s = pos, e = close, body = rest:sub(pos + 1, close - 1) }
            pos = close + 1
        elseif c == "]" then
            return toks, { kind = "stray", at = pos }
        elseif c == ";" then
            toks[#toks + 1] = { t = "semi", s = pos, e = pos }
            pos = pos + 1
        else
            local stop = rest:find("[%[%];]", pos) or n + 1
            local txt = rest:sub(pos, stop - 1)
            if txt:find("%S") then toks[#toks + 1] = { t = "text", s = pos, e = stop - 1, body = txt } end
            pos = stop
        end
    end
    return toks
end

local function Splice(rest, s, e, with) return rest:sub(1, s - 1) .. with .. rest:sub(e + 1) end

-- First mistake in rest (the text after the command): message, fixed rest or nil
local function FirstSyntaxError(rest, isSeq)
    local toks, err = Tokenize(rest)

    -- Inside the brackets, left to right, up to the first bracket error
    for _, t in ipairs(toks) do
        if t.t == "cond" then
            if t.body:find(";", 1, true) then
                return L["SYNTAX_SEMICOLON_IN_COND"]
            end
            local pos = 1
            for phrase in (t.body .. ","):gmatch("([^,]*),") do
                local p = trim(phrase)
                -- [known:Fire Blast]: the space belongs to the argument
                if p:find("%s") and not TakesSpacedArg(p:match("^%S+")) then
                    local pieces, fixable = {}, true
                    for piece in p:gmatch("%S+") do
                        pieces[#pieces + 1] = piece
                        if not IsCondPhrase(piece) then fixable = false end
                    end
                    local msg = L["SYNTAX_SPACE_IN_COND"]:format(p)
                    if not fixable then return msg end
                    local ps = t.s + pos + (phrase:find(p, 1, true) - 1)
                    return msg, Splice(rest, ps, ps + #p - 1, table.concat(pieces, ","))
                end
                pos = pos + #phrase + 1
            end
        end
    end

    -- Clause shape: [conditions] then the argument, nothing after
    local clause, clauses = {}, {}
    for _, t in ipairs(toks) do
        if t.t == "semi" then clauses[#clauses + 1] = clause; clause = {}
        else clause[#clause + 1] = t end
    end
    clauses[#clauses + 1] = clause
    -- A bracket error cuts the last clause short: judge only whole ones
    if err then clauses[#clauses] = nil end
    for _, cl in ipairs(clauses) do
        local ti
        for i, t in ipairs(cl) do
            if t.t == "text" then ti = i; break end
        end
        local j
        for i = (ti or #cl) + 1, #cl do
            if cl[i].t == "cond" then j = i; break end
        end
        if j then
            local k
            for i = j + 1, #cl do
                if cl[i].t == "text" then k = i; break end
            end
            local arg = trim(cl[ti].body)
            local resetOnly = isSeq and arg:match("^reset=%S+$")
            if k and not resetOnly then
                -- /cast [combat] A [nocombat] B: the ; is missing
                local head = rest:sub(1, cl[j].s - 1):gsub("%s+$", "")
                return L["SYNTAX_MISSING_SEMICOLON"]:format(rest:sub(cl[j].s, cl[j].e)),
                    head .. "; " .. rest:sub(cl[j].s)
            end
            local msg = L["SYNTAX_COND_AFTER"]:format(arg)
            -- Conditions on both sides of the argument: the intent is unclear
            if ti > 1 and not resetOnly then return msg end
            local conds, texts = {}, {}
            for _, t in ipairs(cl) do
                if t.t == "cond" then conds[#conds + 1] = rest:sub(t.s, t.e)
                else texts[#texts + 1] = trim(t.body) end
            end
            local fixed = table.concat(conds) .. " " .. table.concat(texts, " ")
            local s = cl[1].s
            while s > 1 and rest:sub(s - 1, s - 1):match("%s") do s = s - 1 end
            -- One space after the command or the ;
            return msg, Splice(rest, s, cl[#cl].e, " " .. fixed)
        end
    end

    if not err then return nil end
    local at = err.at
    if err.kind == "nested" then
        local msg = L["SYNTAX_NESTED"]
        -- [[combat]: one [ too many
        if err.reopen == at + 1 then return msg, Splice(rest, at, at, "") end
        return msg
    elseif err.kind == "stray" then
        local msg = L["SYNTAX_STRAY_CLOSE"]
        local prev = toks[#toks]
        -- [combat]]: one ] too many
        if prev and prev.e == at - 1 and prev.t == "cond" then return msg, Splice(rest, at, at, "") end
        -- /cast combat] X: the [ is missing
        local cs = (prev and prev.t == "semi") and prev.e + 1 or 1
        if not prev or prev.t == "semi" or prev.t == "text" then
            if prev and prev.t == "text" then
                -- the text right before ] must be the clause's first token
                local before = toks[#toks - 1]
                cs = prev.s
                if before and before.t ~= "semi" then return msg, Splice(rest, at, at, "") end
            end
            local pre = rest:sub(cs, at - 1)
            if AllCondPhrases(pre) then
                local first = cs + #pre:match("^%s*")
                return msg, Splice(rest, first, first - 1, "[")
            end
        end
        return msg, Splice(rest, at, at, "")
    else
        local msg = L["SYNTAX_UNCLOSED"]
        -- The ] goes before the first space that follows a whole condition
        local stop = rest:find(";", at + 1, true) or #rest + 1
        local seg = rest:sub(at + 1, stop - 1)
        local i = 1
        while true do
            local ws, we = seg:find("%s+", i)
            if not ws then
                if AllCondPhrases(seg) then
                    local tail = at + #(seg:gsub("%s+$", ""))
                    return msg, Splice(rest, tail + 1, tail, "]")
                end
                return msg
            end
            local prefix = seg:sub(1, ws - 1)
            if prefix:sub(-1) ~= "," and ws > 1 then
                local last = trim(prefix:match("([^,]*)$"))
                if AllCondPhrases(prefix) and not TakesSpacedArg(last)
                    and seg:sub(we + 1):find("%S") then
                    return msg, Splice(rest, at + ws, at + ws - 1, "]")
                end
                return msg
            end
            i = we + 1
        end
    end
end

-- The line's first syntax mistake: message and the line with every mistake
-- that has a clear fix corrected (a fix can reveal the next one), or nil
function A:CheckSyntax(line)
    local cmd = line:match("^(/[%a]+)")
    if not cmd then return nil end
    local isSeq = self:IsSeqCmd(cmd)
    local rest = line:sub(#cmd + 1)
    local msg, fixed = FirstSyntaxError(rest, isSeq)
    if not msg then return nil end
    local cur = fixed
    for _ = 1, 8 do
        if not cur then break end
        local m2, f2 = FirstSyntaxError(cur, isSeq)
        if not m2 then break end
        if not f2 then break end
        fixed, cur = f2, f2
    end
    return msg, fixed and (cmd .. fixed) or nil
end

-- Commands whose text goes through the macro options parser
function A:TakesOptions(cmd)
    if IsSecureCmd then return IsSecureCmd(cmd) and true or false end
    return self:IsCastCmd(cmd) or self:IsSeqCmd(cmd)
end

---------------------------------------------------
-- Full Analysis (enhanced with MT features)
---------------------------------------------------
function A:Analyze(body, name)
    self:BuildCommandList() -- ensure commands are loaded

    local r = { issues = {}, spells = {}, score = 100 }
    if not body or body == "" then
        self:AddIssue(r, "WARN", 0, L["ANALYZER_EMPTY_MACRO"])
        return r
    end
    local H = MF.Helpers
    local nameLen, bodyLen = H:CharLen(name), H:CharLen(body)
    if name and nameLen > 16 then
        self:AddIssue(r, "ERR", 0, L["ANALYZER_NAME_TOO_LONG"]:format(nameLen, 16), { fixType="name", fix=H:TruncateChars(name, 16) })
    end
    if bodyLen > 255 then
        self:AddIssue(r, "ERR", 0, L["ANALYZER_BODY_TOO_LONG"]:format(bodyLen, 255))
    elseif bodyLen > 240 then
        self:AddIssue(r, "WARN", 0, L["ANALYZER_BODY_ALMOST_FULL"]:format(bodyLen, 255))
    end

    -- Brackets are checked per line (CheckSyntax), where they matter
    local op, cp = 0, 0
    for c in body:gmatch("[()]") do
        if c == "(" then op = op + 1 else cp = cp + 1 end
    end
    if op ~= cp then self:AddIssue(r, "WARN", 0, L["ANALYZER_PARENS_MISMATCH"]:format(op, cp)) end

    -- Real line numbers (blank lines count), as the editor gutter shows them
    local ln = 0
    for line in (body .. "\n"):gmatch("([^\n]*)\n") do
        ln = ln + 1
        if line ~= "" then self:AnalyzeLine(line, ln, r) end
    end

    for _, i in ipairs(r.issues) do
        if i.severity == "ERR" then r.score = r.score - 25
        elseif i.severity == "WARN" then r.score = r.score - 10 end
    end
    r.score = math.max(0, r.score)
    return r
end

function A:AddIssue(r, sev, line, msg, extra)
    local issue = { severity = sev, message = msg, line = line }
    if extra then for k, v in pairs(extra) do issue[k] = v end end
    table.insert(r.issues, issue)
end

function A:AnalyzeLine(line, ln, r)
    if line:match("^#") then return end

    local cmd = line:match("^(/[%a]+)")
    if not cmd then return end

    -- Command validation with "did you mean"
    if not self:IsKnownCommand(cmd) then
        local best, dist = self:FindBestMatch(cmd:sub(2):lower())
        local close = best and best ~= "" and dist <= 4
        self:AddIssue(r, "WARN", ln, L["ANALYZER_UNKNOWN_COMMAND"]:format(cmd),
            { fixType = "command", fixFrom = close and cmd or nil, fix = close and ("/" .. best) or nil })
        return
    end

    -- Broken [ ] or ; : the rest of the line cannot be read reliably
    if self:TakesOptions(cmd) then
        local msg, fixed = self:CheckSyntax(line)
        if msg then
            self:AddIssue(r, "ERR", ln, msg, { fixType = "line", fixFrom = line, fix = fixed })
            return
        end
    end

    -- For cast/use commands: validate spell names and conditions
    if self:IsCastCmd(cmd) or self:IsSeqCmd(cmd) then
        local rest = line:sub(#cmd + 1):match("^%s*(.-)%s*$") or ""
        self:AnalyzeCastLine(rest, ln, r)
    end
end

function A:AnalyzeCastLine(text, ln, r)
    -- Parse [conditions] and spell names
    for seg in (text .. ";"):gmatch("([^;]*);") do
        seg = seg:match("^%s*(.-)%s*$")
        if seg ~= "" then
            -- Extract conditions
            local rem = seg
            while true do
                local condBlock, after = rem:match("^%[(.-)%]%s*(.*)")
                if condBlock then
                    self:ValidateConditions(condBlock, ln, r)
                    rem = after
                else break end
            end

            -- Remaining is spell/item name
            local spell = rem:match("^%s*(.-)%s*$")
            if spell and spell ~= "" and not spell:match("^reset=") then
                -- Strip reset= from castsequence
                spell = spell:gsub("^reset=[%w/]*%s*", "")
                if spell ~= "" then
                    for spellPart in (spell .. ","):gmatch("([^,]*),") do
                        spellPart = spellPart:match("^%s*(.-)%s*$")
                        if spellPart ~= "" and not tonumber(spellPart) then
                            local check = self:CheckSpell(spellPart)
                            if check == false then
                                self:AddIssue(r, "INFO", ln, L["ANALYZER_UNVERIFIED"]:format(spellPart), { fixType = "spell" })
                            elseif check and check.type then
                                table.insert(r.spells, { name = spellPart, type = check.type, icon = check.icon })
                            end
                        end
                    end
                end
            end
        end
    end
end

function A:ValidateConditions(condBlock, ln, r)
    for phrase in condBlock:gmatch("[^,]+") do
        phrase = phrase:match("^%s*(.-)%s*$")
        if phrase ~= "" then
            -- @target specs
            if phrase:match("^@") then
                local target = phrase:sub(2)
                if target == "" then
                    self:AddIssue(r, "WARN", ln, L["ANALYZER_EMPTY_TARGET"])
                end
            else
                -- condition:args
                local cond, argStr = phrase:match("^([^:]+):?(.*)")
                if cond then
                    local args = {}
                    if argStr and argStr ~= "" then
                        for a in (argStr .. "/"):gmatch("([^/]*)/?") do
                            a = a:match("^%s*(.-)%s*$")
                            if a ~= "" then table.insert(args, a) end
                        end
                    end
                    local ok, err = self:ValidateCondition(cond, args)
                    if not ok and err then
                        self:AddIssue(r, "WARN", ln, err)
                    end
                end
            end
        end
    end
end

---------------------------------------------------
-- Score helpers
---------------------------------------------------
function A:ScoreColor(score)
    if score >= 90 then return MF.C.green
    elseif score >= 70 then return MF.C.yellow
    else return MF.C.red end
end

function A:FmtSev(sev)
    if sev == "ERR"  then return MF.C.red .. "[ERR]|r"
    elseif sev == "WARN" then return MF.C.yellow .. "[!]|r"
    elseif sev == "INFO" then return MF.C.grey .. "[i]|r"
    else return "[?]" end
end

---------------------------------------------------
-- CLI entry
---------------------------------------------------
function A:OnInitialize()
    MF:RegisterMessage("MF_ANALYZE_ALL", function()
        self:BuildCommandList()
        local P = MF:GetModule("Profiles")
        if not P then return end
        local macros = P:ReadCharacterMacros()
        MF.Helpers:Print(MF.C.gold .. L["ANALYZER_HEADER"] .. MF.C.r)
        local total = 0
        for _, m in ipairs(macros) do
            local res = self:Analyze(m.body, m.name)
            if #res.issues > 0 then
                MF.Helpers:Print(self:ScoreColor(res.score) .. res.score .. "%|r "
                    .. MF.C.white .. m.name .. "|r - " .. L["ANALYZER_ISSUES_SHORT"]:format(#res.issues))
                for _, iss in ipairs(res.issues) do
                    MF.Helpers:Print("  " .. self:FmtSev(iss.severity) .. " " .. iss.message)
                end
                total = total + #res.issues
            end
        end
        if total == 0 then MF.Helpers:Print(MF.C.green .. L["ANALYZER_ALL_VALID"] .. "|r")
        else MF.Helpers:Print(MF.C.orange .. L["ANALYZER_TOTAL_ISSUES"]:format(total) .. "|r") end
    end)
end

-- ExplainLine / ExplainBody moved to AnalyzerExplain.lua

---------------------------------------------------
-- Macro Shortener
-- Uses shortest command aliases to save characters
---------------------------------------------------
-- Secure commands that accept [conditions] syntax (from warcraft.wiki.gg)
-- Insecure commands (/say, /emote, /whisper, etc.) must NOT be processed.
local SECURE_COMMANDS = {
    ["cast"] = true, ["use"] = true, ["spell"] = true,
    ["castrandom"] = true, ["castsequence"] = true, ["userandom"] = true,
    ["cancelaura"] = true, ["cancelform"] = true,
    ["startattack"] = true, ["stopattack"] = true,
    ["stopcasting"] = true, ["stopmacro"] = true,
    ["changeactionbar"] = true, ["swapactionbar"] = true,
    ["target"] = true, ["targetexact"] = true,
    ["targetenemy"] = true, ["targetenemyplayer"] = true,
    ["targetfriend"] = true, ["targetfriendplayer"] = true,
    ["targetlasttarget"] = true, ["targetlastfriend"] = true, ["targetlastenemy"] = true,
    ["targetparty"] = true, ["targetraid"] = true,
    ["assist"] = true, ["focus"] = true, ["clearfocus"] = true, ["cleartarget"] = true,
    ["petattack"] = true, ["petfollow"] = true, ["petstay"] = true,
    ["petpassive"] = true, ["petdefensive"] = true, ["petassist"] = true,
    ["petautocaston"] = true, ["petautocastoff"] = true, ["petautocasttoggle"] = true,
    ["petmoveto"] = true,
    ["dismount"] = true, ["leavevehicle"] = true,
    ["equip"] = true, ["equipslot"] = true, ["equipset"] = true,
    ["click"] = true,
}

function A:ShortenMacro(body)
    if not body or body == "" then return body, 0 end
    self:BuildCommandList()

    local origLen = #body
    local lines = {}

    -- Compress spaces ONLY inside [...] brackets (conditions)
    local function compressBrackets(s)
        return s:gsub("%b[]", function(bracket)
            local inner = bracket:sub(2, -2)         -- strip [ ]
            inner = inner:gsub("%s*,%s*", ",")        -- commas (AND separator)
            inner = inner:gsub("%s*:%s*", ":")        -- colons (param separator)
            inner = inner:gsub("%s*=%s*", "=")        -- equals (target=)
            inner = inner:gsub("%s*/%s*", "/")        -- slashes (OR separator)
            inner = inner:gsub("%s+", "")             -- remaining spaces
            return "[" .. inner .. "]"
        end)
    end

    for line in body:gmatch("[^\n]+") do
        -- Detect if this line uses a secure command or metacommand
        local cmd = line:match("^(/[%a]+)")
        local isMeta = line:match("^#show") ~= nil  -- #show / #showtooltip
        local isSecure = false

        if cmd then
            local cmdLower = cmd:sub(2):lower()

            -- 1) Shorten command name to its shortest alias (always safe)
            local info = commands[cmdLower]
            if info and info[1] and #info[1] < #cmdLower then
                local shortest = "/" .. info[1]
                line = shortest .. line:sub(#cmd + 1)
                -- Update cmdLower to shortened form for secure check
                cmdLower = info[1]
            end

            -- Check if this is a secure command (accepts conditions)
            -- Also resolve aliases: e.g. "w" → whisper (insecure), "sp" → cast (secure)
            isSecure = SECURE_COMMANDS[cmdLower] or false
            if not isSecure and info then
                -- Check if any alias maps to a known secure command
                for _, alias in ipairs(info) do
                    if SECURE_COMMANDS[alias] then
                        isSecure = true
                        break
                    end
                end
            end
        end

        -- Condition-aware optimizations ONLY for secure commands and metacommands
        if isSecure or isMeta then
            -- NOTE: Do NOT remove the space between command and "["
            -- e.g. "/use [mod]" must keep the space — "/use[mod]" breaks in-game.

            -- 2) Compress spaces inside [...] conditions
            line = compressBrackets(line)

            -- 3) Remove space between "]" and spell/item name
            -- e.g. "] Heal" → "]Heal" — confirmed working in-game
            line = line:gsub("]%s+", "]")

            -- 4) Remove spaces around semicolons (clause separators)
            line = line:gsub("%s*;%s*", ";")
        end

        -- 5) Collapse multiple spaces to one (always safe)
        line = line:gsub("  +", " ")

        -- 6) Strip trailing spaces on each line (always safe)
        line = line:match("^(.-)%s*$")
        table.insert(lines, line)
    end

    local result = table.concat(lines, "\n")
    -- Strip trailing newlines
    result = result:match("^(.-)%s*$")
    local saved = origLen - #result
    return result, math.max(0, saved)
end

---------------------------------------------------
-- Expose commands table for CommandPalette
---------------------------------------------------
function A:GetCommands()
    self:BuildCommandList()
    return commands
end

MF:RegisterModule("Analyzer", A)
