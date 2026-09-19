---------------------------------------------------
-- MacroForge — Analyzer Explain
-- Pseudo-algorithmic explanation for macros
-- Extracted from Analyzer.lua for maintainability
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local A = MF:GetModule("Analyzer")
if not A then return end

---------------------------------------------------
-- Condition translation dictionary (for explain)
---------------------------------------------------
local COND_TEXT = {
    help = L["EXPLAIN_COND_HELP"], harm = L["EXPLAIN_COND_HARM"], exists = L["EXPLAIN_COND_EXISTS"],
    dead = L["EXPLAIN_COND_DEAD"], nodead = L["EXPLAIN_COND_NODEAD"],
    combat = L["EXPLAIN_COND_COMBAT"], nocombat = L["EXPLAIN_COND_NOCOMBAT"],
    stealth = L["EXPLAIN_COND_STEALTH"], nostealth = L["EXPLAIN_COND_NOSTEALTH"],
    swimming = L["EXPLAIN_COND_SWIMMING"], noswimming = L["EXPLAIN_COND_NOSWIMMING"],
    flying = L["EXPLAIN_COND_FLYING"], noflying = L["EXPLAIN_COND_NOFLYING"],
    mounted = L["EXPLAIN_COND_MOUNTED"], nomounted = L["EXPLAIN_COND_NOMOUNTED"],
    indoors = L["EXPLAIN_COND_INDOORS"], outdoors = L["EXPLAIN_COND_OUTDOORS"],
    channeling = L["EXPLAIN_COND_CHANNELING"], nochanneling = L["EXPLAIN_COND_NOCHANNELING"],
    mod = L["EXPLAIN_COND_MOD"], nomod = L["EXPLAIN_COND_NOMOD"],
    modifier = L["EXPLAIN_COND_MOD"], nomodifier = L["EXPLAIN_COND_NOMOD"],
    group = L["EXPLAIN_COND_GROUP"], nogroup = L["EXPLAIN_COND_NOGROUP"],
    raid = L["EXPLAIN_COND_RAID"], pet = L["EXPLAIN_COND_PET"], nopet = L["EXPLAIN_COND_NOPET"],
    talent = L["EXPLAIN_COND_TALENT"], known = L["EXPLAIN_COND_KNOWN"],
    equipped = L["EXPLAIN_COND_EQUIPPED"], worn = L["EXPLAIN_COND_EQUIPPED"],
    spec = L["EXPLAIN_COND_SPEC"], form = L["EXPLAIN_COND_FORM"], stance = L["EXPLAIN_COND_STANCE"],
}

---------------------------------------------------
-- Command verb translation (for explain)
---------------------------------------------------
local CMD_VERB = {
    ["/cast"] = L["EXPLAIN_VERB_CAST"], ["/use"] = L["EXPLAIN_VERB_USE"],
    ["/castsequence"] = L["EXPLAIN_VERB_CASTSEQUENCE"],
    ["/castrandom"] = L["EXPLAIN_VERB_RANDOM"], ["/userandom"] = L["EXPLAIN_VERB_RANDOM"],
    ["/startattack"] = L["EXPLAIN_VERB_STARTATTACK"],
    ["/stopattack"] = L["EXPLAIN_VERB_STOPATTACK"],
    ["/stopcasting"] = L["EXPLAIN_VERB_STOPCASTING"],
    ["/cancelaura"] = L["EXPLAIN_VERB_CANCELAURA"], ["/cancelform"] = L["EXPLAIN_VERB_CANCELFORM"],
    ["/dismount"] = L["EXPLAIN_VERB_DISMOUNT"],
    ["/target"] = L["EXPLAIN_VERB_TARGET"], ["/targetexact"] = L["EXPLAIN_VERB_TARGETEXACT"],
    ["/targetenemy"] = L["EXPLAIN_VERB_TARGETENEMY"],
    ["/targetenemyplayer"] = L["EXPLAIN_VERB_TARGETENEMYPLAYER"],
    ["/targetfriend"] = L["EXPLAIN_VERB_TARGETFRIEND"],
    ["/targetfriendplayer"] = L["EXPLAIN_VERB_TARGETFRIENDPLAYER"],
    ["/targetparty"] = L["EXPLAIN_VERB_TARGETPARTY"],
    ["/targetraid"] = L["EXPLAIN_VERB_TARGETRAID"],
    ["/targetlastenemy"] = L["EXPLAIN_VERB_TARGETLASTENEMY"],
    ["/targetlastfriend"] = L["EXPLAIN_VERB_TARGETLASTFRIEND"],
    ["/targetlasttarget"] = L["EXPLAIN_VERB_TARGETLASTTARGET"],
    ["/cleartarget"] = L["EXPLAIN_VERB_CLEARTARGET"],
    ["/clearfocus"] = L["EXPLAIN_VERB_CLEARFOCUS"],
    ["/focus"] = L["EXPLAIN_VERB_FOCUS"],
    ["/assist"] = L["EXPLAIN_VERB_ASSIST"],
    ["/equip"] = L["EXPLAIN_VERB_EQUIP"], ["/equipset"] = L["EXPLAIN_VERB_EQUIPSET"],
    ["/petattack"] = L["EXPLAIN_VERB_PETATTACK"],
    ["/petfollow"] = L["EXPLAIN_VERB_PETFOLLOW"],
    ["/petstay"] = L["EXPLAIN_VERB_PETSTAY"],
    ["/petpassive"] = L["EXPLAIN_VERB_PETPASSIVE"],
    ["/petdefensive"] = L["EXPLAIN_VERB_PETDEFENSIVE"],
    ["/stopmacro"] = L["EXPLAIN_VERB_STOPMACRO"],
    ["/click"] = L["EXPLAIN_VERB_CLICK"],
    ["/run"] = L["EXPLAIN_VERB_SCRIPT"], ["/script"] = L["EXPLAIN_VERB_SCRIPT"],
    ["/say"] = L["EXPLAIN_VERB_SAY"], ["/s"] = L["EXPLAIN_VERB_SAY"],
    ["/yell"] = L["EXPLAIN_VERB_YELL"], ["/y"] = L["EXPLAIN_VERB_YELL"],
    ["/emote"] = L["EXPLAIN_VERB_EMOTE"], ["/e"] = L["EXPLAIN_VERB_EMOTE"],
    ["/party"] = L["EXPLAIN_VERB_PARTY"], ["/p"] = L["EXPLAIN_VERB_PARTY"],
    ["/raid"] = L["EXPLAIN_VERB_RAID"], ["/ra"] = L["EXPLAIN_VERB_RAID"],
    ["/rw"] = L["EXPLAIN_VERB_RAIDWARNING"],
    ["/whisper"] = L["EXPLAIN_VERB_WHISPER"], ["/w"] = L["EXPLAIN_VERB_WHISPER"],
    ["/leavevehicle"] = L["EXPLAIN_VERB_LEAVEVEHICLE"],
    ["/stopspelltarget"] = L["EXPLAIN_VERB_STOPSPELLTARGET"],
    ["/cancelqueuedspell"] = L["EXPLAIN_VERB_CANCELQUEUEDSPELL"],
}

local function TranslateConditions(condStr)
    local parts = {}
    for token in condStr:gmatch("[^,]+") do
        token = token:match("^%s*(.-)%s*$")
        local at = token:match("^@(.+)")
        if at then
            table.insert(parts, L["EXPLAIN_TARGET_EQ"]:format(at))
        else
            local key, val = token:match("^([^:]+):?(.*)$")
            if key then
                key = key:lower()
                if val and val ~= "" then
                    table.insert(parts, (COND_TEXT[key] or key) .. ":" .. val)
                else
                    table.insert(parts, COND_TEXT[key] or key)
                end
            end
        end
    end
    return table.concat(parts, ", ")
end

function A:ExplainLine(line)
    if not line or line == "" then return nil end
    line = line:match("^%s*(.-)%s*$")
    if line == "" then return nil end

    local ttip = line:match("^#showtooltip%s*(.*)")
    if ttip then
        ttip = ttip:match("^%s*(.-)%s*$")
        return ttip == "" and L["EXPLAIN_SHOWTOOLTIP_AUTO"] or L["EXPLAIN_SHOWTOOLTIP"]:format(ttip)
    end
    if line:match("^#show") then return L["EXPLAIN_SHOW_AUTO"] end
    if line:match("^#") then return nil end

    local cmd = line:match("^(/[%a]+)")
    if not cmd then return nil end

    local verb = CMD_VERB[cmd:lower()] or cmd
    local rest = line:sub(#cmd + 1):match("^%s*(.-)%s*$") or ""

    if rest == "" then return verb end

    if cmd:lower():match("^/cast") or cmd:lower():match("^/use") then
        -- Check for castsequence
        if cmd:lower() == "/castsequence" then
            -- Parse reset conditions
            local resetStr, spellList = rest:match("^reset=([%w/]+)%s+(.*)")
            if not resetStr then
                spellList = rest
            end

            -- Parse conditions before spell list
            local condText, actualSpells = nil, spellList or rest
            local condPart, afterCond = actualSpells:match("^(%b[])%s*(.*)")
            if condPart then
                condText = TranslateConditions(condPart:sub(2, -2))
                actualSpells = afterCond
            end

            -- Build explanation
            local parts = {}
            if resetStr then
                local resets = {}
                for r in resetStr:gmatch("[^/]+") do
                    r = r:lower()
                    if r == "combat" then table.insert(resets, L["EXPLAIN_RESET_COMBAT"])
                    elseif r == "target" then table.insert(resets, L["EXPLAIN_RESET_TARGET"])
                    elseif r:match("^%d+$") then table.insert(resets, r .. "s")
                    elseif r == "shift" then table.insert(resets, "Shift")
                    elseif r == "alt" then table.insert(resets, "Alt")
                    elseif r == "ctrl" then table.insert(resets, "Ctrl")
                    else table.insert(resets, r) end
                end
                table.insert(parts, MF.C.yellow .. L["EXPLAIN_RESET"]:format(table.concat(resets, ", ")) .. "|r")
            end

            -- List spells in sequence
            local i = 0
            for spell in (actualSpells .. ","):gmatch("([^,]+),") do
                spell = spell:match("^%s*(.-)%s*$")
                if spell ~= "" then
                    i = i + 1
                    table.insert(parts, MF.C.cyan .. "  " .. i .. ".|r " .. spell)
                end
            end

            local seqText = L["EXPLAIN_SEQUENCE"] .. "\n    " .. table.concat(parts, "\n    ")
            return condText and L["EXPLAIN_IF_THEN"]:format(condText, seqText) or seqText
        end

        -- Regular /cast or /use
        local segments = {}
        for seg in (rest .. ";"):gmatch("([^;]*);") do
            seg = seg:match("^%s*(.-)%s*$")
            if seg ~= "" then
                local allConds, rem = {}, seg
                while true do
                    local c, after = rem:match("^%[(.-)%]%s*(.*)")
                    if c then table.insert(allConds, TranslateConditions(c)); rem = after
                    else break end
                end
                local spell = rem:match("^%s*(.-)%s*$")
                if #allConds > 0 then
                    local ct = table.concat(allConds, L["EXPLAIN_OR"])
                    table.insert(segments, L["EXPLAIN_IF_THEN"]:format(ct, spell ~= "" and (verb .. " '" .. spell .. "'") or verb))
                elseif spell ~= "" then
                    table.insert(segments, verb .. " '" .. spell .. "'")
                end
            end
        end
        return #segments > 0 and table.concat(segments, "\n    ") or (verb .. " " .. rest)
    end

    if cmd:lower() == "/cancelaura" then return verb .. " '" .. rest .. "'" end
    return verb .. " " .. rest
end

function A:ExplainBody(body)
    if not body or body == "" then return MF.C.grey .. L["ANALYZER_EMPTY_MACRO"] .. "|r" end
    local steps, n = {}, 0
    for line in body:gmatch("[^\n]+") do
        local explained = self:ExplainLine(line)
        if explained then
            n = n + 1
            for subline in explained:gmatch("[^\n]+") do
                if subline:match("^%s+") then
                    table.insert(steps, MF.C.grey .. "       " .. subline .. "|r")
                else
                    table.insert(steps, MF.C.cyan .. n .. ".|r " .. MF.C.white .. subline .. "|r")
                end
            end
        end
    end
    return #steps == 0 and (MF.C.grey .. L["EXPLAIN_NO_ACTION"] .. "|r") or table.concat(steps, "\n")
end
