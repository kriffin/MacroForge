---------------------------------------------------
-- MacroForge — Analyzer Explain
-- Pseudo-algorithmic explanation for macros
-- Extracted from Analyzer.lua for maintainability
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local A = MF:GetModule("Analyzer")
if not A then return end

---------------------------------------------------
-- Condition translation dictionary (for explain)
---------------------------------------------------
local COND_FR = {
    help = "allie", harm = "hostile", exists = "cible existante",
    dead = "mort", nodead = "vivant",
    combat = "en combat", nocombat = "hors combat",
    stealth = "furtivement", nostealth = "pas en furtivite",
    swimming = "nage", noswimming = "pas en nage",
    flying = "en vol", noflying = "pas en vol",
    mounted = "sur monture", nomounted = "pas sur monture",
    indoors = "en interieur", outdoors = "en exterieur",
    channeling = "canalisation", nochanneling = "pas de canalisation",
    mod = "modificateur", nomod = "sans modificateur",
    modifier = "modificateur", nomodifier = "sans modificateur",
    group = "en groupe", nogroup = "pas en groupe",
    raid = "en raid", pet = "familier actif", nopet = "pas de familier",
    talent = "talent actif", known = "connu",
    equipped = "equipe", worn = "equipe",
    spec = "spe", form = "forme", stance = "posture",
}

---------------------------------------------------
-- Command verb translation (for explain)
---------------------------------------------------
local CMD_VERB = {
    ["/cast"] = "Lancer", ["/use"] = "Utiliser",
    ["/castsequence"] = "Sequence",
    ["/castrandom"] = "Au hasard", ["/userandom"] = "Au hasard",
    ["/startattack"] = "Lancer l'attaque auto",
    ["/stopattack"] = "Arreter l'attaque auto",
    ["/stopcasting"] = "Interrompre l'incantation",
    ["/cancelaura"] = "Annuler l'aura", ["/cancelform"] = "Annuler la forme",
    ["/dismount"] = "Descendre de monture",
    ["/target"] = "Cibler", ["/targetexact"] = "Cibler (exact)",
    ["/targetenemy"] = "Cibler le prochain ennemi",
    ["/targetenemyplayer"] = "Cibler le prochain ennemi joueur",
    ["/targetfriend"] = "Cibler le prochain allie",
    ["/targetfriendplayer"] = "Cibler le prochain allie joueur",
    ["/targetparty"] = "Cibler un membre du groupe",
    ["/targetraid"] = "Cibler un membre du raid",
    ["/targetlastenemy"] = "Re-cibler dernier ennemi",
    ["/targetlastfriend"] = "Re-cibler dernier allie",
    ["/targetlasttarget"] = "Re-cibler derniere cible",
    ["/cleartarget"] = "Effacer la cible",
    ["/clearfocus"] = "Effacer le focus",
    ["/focus"] = "Definir le focus",
    ["/assist"] = "Assister (cibler la cible de)",
    ["/equip"] = "Equiper", ["/equipset"] = "Charger set",
    ["/petattack"] = "Familier: attaquer",
    ["/petfollow"] = "Familier: suivre",
    ["/petstay"] = "Familier: rester",
    ["/petpassive"] = "Familier: passif",
    ["/petdefensive"] = "Familier: defensif",
    ["/stopmacro"] = "Arreter la macro",
    ["/click"] = "Simuler clic sur",
    ["/run"] = "Script Lua", ["/script"] = "Script Lua",
    ["/say"] = "Dire", ["/s"] = "Dire",
    ["/yell"] = "Crier", ["/y"] = "Crier",
    ["/emote"] = "Emote", ["/e"] = "Emote",
    ["/party"] = "Dire au groupe", ["/p"] = "Dire au groupe",
    ["/raid"] = "Dire au raid", ["/ra"] = "Dire au raid",
    ["/rw"] = "Alerte raid",
    ["/whisper"] = "Chuchoter a", ["/w"] = "Chuchoter a",
    ["/leavevehicle"] = "Quitter le vehicule",
    ["/stopspelltarget"] = "Annuler ciblage sort",
    ["/cancelqueuedspell"] = "Annuler sort en file",
}

local function TranslateConditions(condStr)
    local parts = {}
    for token in condStr:gmatch("[^,]+") do
        token = token:match("^%s*(.-)%s*$")
        local at = token:match("^@(.+)")
        if at then
            table.insert(parts, "cible=" .. at)
        else
            local key, val = token:match("^([^:]+):?(.*)$")
            if key then
                key = key:lower()
                if val and val ~= "" then
                    table.insert(parts, (COND_FR[key] or key) .. ":" .. val)
                else
                    table.insert(parts, COND_FR[key] or key)
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
        return ttip == "" and "Icone/tooltip: automatique" or ("Icone/tooltip: " .. ttip)
    end
    if line:match("^#show") then return "Icone: automatique" end
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
            local condText, actualSpells = "", spellList or rest
            local condPart, afterCond = actualSpells:match("^(%b[])%s*(.*)")
            if condPart then
                condText = "SI " .. TranslateConditions(condPart:sub(2, -2)) .. ": "
                actualSpells = afterCond
            end

            -- Build explanation
            local parts = {}
            if resetStr then
                local resets = {}
                for r in resetStr:gmatch("[^/]+") do
                    r = r:lower()
                    if r == "combat" then table.insert(resets, "fin combat")
                    elseif r == "target" then table.insert(resets, "changement cible")
                    elseif r:match("^%d+$") then table.insert(resets, r .. "s")
                    elseif r == "shift" then table.insert(resets, "Shift")
                    elseif r == "alt" then table.insert(resets, "Alt")
                    elseif r == "ctrl" then table.insert(resets, "Ctrl")
                    else table.insert(resets, r) end
                end
                table.insert(parts, MF.C.yellow .. "Reset: " .. table.concat(resets, ", ") .. "|r")
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

            return condText .. "Sequence:\n    " .. table.concat(parts, "\n    ")
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
                    local ct = table.concat(allConds, " OU ")
                    table.insert(segments, spell ~= "" and ("SI " .. ct .. ": " .. verb .. " '" .. spell .. "'") or ("SI " .. ct .. ": " .. verb))
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
    if not body or body == "" then return MF.C.grey .. "Macro vide.|r" end
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
    return #steps == 0 and (MF.C.grey .. "Aucune action detectee.|r") or table.concat(steps, "\n")
end
