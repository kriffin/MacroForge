---------------------------------------------------
-- MacroForge — Analyzer (MacroToolkit-powered)
-- Dynamic spell/command/condition validation
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
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

function A:FindBestMatch(source)
    local diff, bestmatch = 99, ""
    for k, _ in pairs(commands) do
        local d = getLevenshtein(source, k)
        if d < diff then diff = d; bestmatch = k end
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
function A:ValidateCondition(cond, args)
    -- Strip leading 'no' prefix for checking
    local rawCond = cond
    if cond:sub(1, 2) == "no" then rawCond = cond:sub(3) end

    -- Is it a target spec? @X or target=X
    if cond:match("^@") or cond:match("^target%s*=") then
        return true, nil -- target specs are always valid
    end

    local ctype = CONDITIONS[rawCond]
    if ctype == nil then
        -- Unknown condition — find best match
        local best = self:FindBestCondition(rawCond)
        local msg = MF.C.red .. "Condition invalide: " .. cond .. "|r"
        if best and best ~= "" then
            msg = msg .. "  " .. MF.C.green .. "-> " .. best .. "|r"
        end
        return false, msg
    end

    -- Check if arguments are required/valid
    if #args == 0 then
        if ctype ~= CTYPE_NONE and not OPTIONAL_CONDS[rawCond] and cond:sub(1,2) ~= "no" then
            return false, MF.C.yellow .. "Argument manquant: " .. cond .. "|r"
        end
        return true, nil
    end

    -- Validate argument types
    if ctype == CTYPE_NONE then
        return false, MF.C.yellow .. "Pas d'argument attendu: " .. cond .. "|r"
    elseif ctype == CTYPE_NUMERIC or ctype == CTYPE_NUMERIC_SLASH then
        for _, a in ipairs(args) do
            local clean = a:gsub("/", "")
            if not tonumber(clean) then
                return false, MF.C.red .. "Argument numerique attendu: " .. cond .. ":" .. a .. "|r"
            end
        end
    elseif ctype == CTYPE_MOD_KEYS then
        for _, a in ipairs(args) do
            local key = a:gsub(":", ""):gsub(" ", ""):lower()
            if not VALID_MOD_KEYS[key] then
                return false, MF.C.yellow .. "Touche inconnue: " .. a .. "|r"
            end
        end
    elseif ctype == CTYPE_MOUSEBUTTONS then
        for _, a in ipairs(args) do
            if not VALID_BUTTONS[a:lower()] then
                return false, MF.C.yellow .. "Bouton inconnu: " .. a .. "|r"
            end
        end
    elseif ctype == CTYPE_PARTY_RAID then
        for _, a in ipairs(args) do
            if not VALID_GROUP[a:lower()] then
                return false, MF.C.yellow .. "Valeur invalide: " .. a .. " (party/raid)" .. "|r"
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
-- Full Analysis (enhanced with MT features)
---------------------------------------------------
function A:Analyze(body, name)
    self:BuildCommandList() -- ensure commands are loaded

    local r = { issues = {}, spells = {}, score = 100 }
    if not body or body == "" then
        self:AddIssue(r, "WARN", 0, "Macro vide.")
        return r
    end
    if name and #name > 16 then
        self:AddIssue(r, "ERR", 0, "Nom trop long (" .. #name .. "/16).", { fixType="name", fix=name:sub(1,16) })
    end
    if #body > 255 then
        self:AddIssue(r, "ERR", 0, "Body trop long (" .. #body .. "/255).")
    elseif #body > 240 then
        self:AddIssue(r, "WARN", 0, "Body presque plein (" .. #body .. "/255).")
    end

    -- Check matched brackets
    local ob, cb = 0, 0
    local op, cp = 0, 0
    for c in body:gmatch(".") do
        if c == "[" then ob = ob + 1 elseif c == "]" then cb = cb + 1 end
        if c == "(" then op = op + 1 elseif c == ")" then cp = cp + 1 end
    end
    if ob ~= cb then self:AddIssue(r, "ERR", 0, "Crochets: " .. ob .. " [ vs " .. cb .. " ]") end
    if op ~= cp then self:AddIssue(r, "WARN", 0, "Parentheses: " .. op .. " ( vs " .. cp .. " )") end

    local ln = 0
    for line in body:gmatch("[^\n]+") do
        ln = ln + 1
        self:AnalyzeLine(line, ln, r)
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
        local msg = "Commande inconnue: " .. cmd
        if best and best ~= "" and dist <= 4 then
            msg = msg .. "  -> /" .. best
        end
        self:AddIssue(r, "WARN", ln, msg, { fixType = "name", fix = best and ("/" .. best) or nil })
        return
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
                                self:AddIssue(r, "INFO", ln, "Non verifie: " .. spellPart, { fixType = "spell" })
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
                    self:AddIssue(r, "WARN", ln, "Cible vide: @")
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
        MF.Helpers:Print(MF.C.gold .. "=== Analyse ===" .. MF.C.r)
        local total = 0
        for _, m in ipairs(macros) do
            local res = self:Analyze(m.body, m.name)
            if #res.issues > 0 then
                MF.Helpers:Print(self:ScoreColor(res.score) .. res.score .. "%|r "
                    .. MF.C.white .. m.name .. "|r - " .. #res.issues .. " pb")
                for _, iss in ipairs(res.issues) do
                    MF.Helpers:Print("  " .. self:FmtSev(iss.severity) .. " " .. iss.message)
                end
                total = total + #res.issues
            end
        end
        if total == 0 then MF.Helpers:Print(MF.C.green .. "Toutes valides!|r")
        else MF.Helpers:Print(MF.C.orange .. total .. " probleme(s).|r") end
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

            -- 3) Remove spaces around semicolons (clause separators)
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
