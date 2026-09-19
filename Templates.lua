---------------------------------------------------
-- MacroForge — Templates
-- Multi-class macro templates, auto-detect player class
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
MF.Templates = {}

---------------------------------------------------
-- Categories
---------------------------------------------------
MF.Templates.CATEGORIES = {
    { id = "universal",  name = "|cffffffff" .. L["TPL_CAT_UNIVERSAL"] .. "|r" },
    { id = "interrupt",  name = "|cff33ccff" .. L["TPL_CAT_INTERRUPT"] .. "|r" },
    { id = "offensive",  name = "|cffff6633" .. L["TPL_CAT_OFFENSIVE"] .. "|r" },
    { id = "defensive",  name = "|cff66ccff" .. L["TPL_CAT_DEFENSIVE"] .. "|r" },
    { id = "cc",         name = "|cffcc33ff" .. L["TPL_CAT_CC"] .. "|r" },
    { id = "utility",    name = "|cffaaaaaa" .. L["TPL_CAT_UTILITY"] .. "|r" },
    { id = "pvp",        name = "|cffff3333" .. L["TPL_CAT_PVP"] .. "|r" },
    { id = "tank",       name = "|cff3399ff" .. L["TPL_CAT_TANK"] .. "|r" },
    { id = "healer",     name = "|cff33ff99" .. L["TPL_CAT_HEALER"] .. "|r" },
}

---------------------------------------------------
-- Class Colors (for display)
---------------------------------------------------
local CLASS_COLORS = {
    WARRIOR     = "|cffc79c6e",
    PALADIN     = "|cfff58cba",
    HUNTER      = "|cffabd473",
    ROGUE       = "|cfffff569",
    PRIEST      = "|cffffffff",
    DEATHKNIGHT = "|cffc41f3b",
    SHAMAN      = "|cff0070de",
    MAGE        = "|cff69ccf0",
    WARLOCK     = "|cff9482c9",
    MONK        = "|cff00ff96",
    DRUID       = "|cffff7d0a",
    DEMONHUNTER = "|cffa330c9",
    EVOKER      = "|cff33937f",
}

---------------------------------------------------
-- Template Data — Universal
---------------------------------------------------
local UNIVERSAL = {
    {
        category = "universal", name = "Mouseover Heal/Cast",
        description = L["TPL_DESC_MOUSEOVER_HEAL_CAST"],
        body = "#showtooltip\n/cast [@mouseover,help,nodead][] {ph:SORT}",
    },
    {
        category = "universal", name = "Focus Interrupt",
        description = L["TPL_DESC_FOCUS_INTERRUPT"],
        body = "#showtooltip\n/cast [@focus,harm,nodead][] {ph:SORT}",
    },
    {
        category = "universal", name = "Mouseover Harm",
        description = L["TPL_DESC_MOUSEOVER_HARM"],
        body = "#showtooltip\n/cast [@mouseover,harm,nodead][] {ph:SORT}",
    },
    {
        category = "universal", name = "Trinket 1",
        description = L["TPL_DESC_TRINKET_1"],
        body = "#showtooltip\n/use 13",
    },
    {
        category = "universal", name = "Trinket 2",
        description = L["TPL_DESC_TRINKET_2"],
        body = "#showtooltip\n/use 14",
    },
    {
        category = "universal", name = "Mount Smart",
        description = L["TPL_DESC_MOUNT_SMART"],
        body = "#showtooltip\n/dismount [mounted]\n/cast [advflyable] {ph:MONTURE_VOL}; {ph:MONTURE_SOL}",
    },
    {
        category = "universal", name = "Cancelaura + Cast",
        description = L["TPL_DESC_CANCELAURA_CAST"],
        body = "#showtooltip\n/cancelaura {ph:NOM_BUFF}\n/cast {ph:SORT}",
    },
    {
        category = "universal", name = "Startattack + Cast",
        description = L["TPL_DESC_STARTATTACK_CAST"],
        body = "#showtooltip\n/startattack\n/cast {ph:SORT}",
    },
    {
        category = "universal", name = "Mod Shift/Ctrl/Alt",
        description = L["TPL_DESC_MOD_SHIFT_CTRL_ALT"],
        body = "#showtooltip\n/cast [mod:shift] {ph:SORT_SHIFT}; [mod:ctrl] {ph:SORT_CTRL}; {ph:SORT_NORMAL}",
    },
    {
        category = "universal", name = "Cast Sequence",
        description = L["TPL_DESC_CAST_SEQUENCE"],
        body = "#showtooltip\n/castsequence reset=target {ph:SORT1}, {ph:SORT2}, {ph:SORT3}",
    },
    {
        category = "universal", name = "Stopcasting + Cast",
        description = L["TPL_DESC_STOPCASTING_CAST"],
        body = "#showtooltip\n/stopcasting\n/cast {ph:SORT}",
    },
    {
        category = "utility", name = "Focus Set/Clear",
        description = L["TPL_DESC_FOCUS_SET_CLEAR"],
        body = "/focus [@focus,exists] [nomod]\n/clearfocus [@focus,exists] [mod:shift]",
    },
    {
        category = "pvp", name = "Arena Target 1",
        description = L["TPL_DESC_ARENA_TARGET_1"],
        body = "#showtooltip\n/cast [@arena1] {ph:SORT}",
    },
    {
        category = "pvp", name = "Arena Target 2",
        description = L["TPL_DESC_ARENA_TARGET_2"],
        body = "#showtooltip\n/cast [@arena2] {ph:SORT}",
    },
    {
        category = "pvp", name = "Arena Target 3",
        description = L["TPL_DESC_ARENA_TARGET_3"],
        body = "#showtooltip\n/cast [@arena3] {ph:SORT}",
    },
    {
        category = "pvp", name = "PvP Trinket",
        description = L["TPL_DESC_PVP_TRINKET"],
        body = "#showtooltip\n/use 14",
    },
    {
        category = "healer", name = "Mouseover Heal",
        description = L["TPL_DESC_MOUSEOVER_HEAL"],
        body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] {ph:SORT_HEAL}",
    },
    {
        category = "healer", name = "Dispel Mouseover",
        description = L["TPL_DESC_DISPEL_MOUSEOVER"],
        body = "#showtooltip\n/cast [@mouseover,help,nodead][] {ph:SORT_DISPEL}",
    },
    {
        category = "tank", name = "Taunt Mouseover",
        description = L["TPL_DESC_TAUNT_MOUSEOVER"],
        body = "#showtooltip\n/cast [@mouseover,harm,nodead][] {ph:SORT_TAUNT}",
    },
    {
        category = "tank", name = "Defensive + Mod",
        description = L["TPL_DESC_DEFENSIVE_MOD"],
        body = "#showtooltip\n/cast [mod:shift] {ph:GROS_DEF}; {ph:PETIT_DEF}",
    },
}

---------------------------------------------------
-- Template Data — Class-Specific
---------------------------------------------------
local CLASS_TEMPLATES = {
    ROGUE = {
        {
            category = "interrupt", name = "Kick Priority",
            description = L["TPL_DESC_ROGUE_KICK_PRIORITY"],
            body = "#showtooltip\n/cast [mod:shift,@focus,harm,nodead][mod:shift,@mouseover,harm,nodead][mod:shift] {spell:1776:Gouge}\n/cast [mod:ctrl,@focus,harm,nodead][mod:ctrl] {spell:408:Kidney Shot}\n/cast [nomod,@focus,harm,nodead][nomod,@mouseover,harm,nodead][nomod] {spell:1766:Kick}",
        },
        {
            category = "offensive", name = "Opener Burst",
            description = L["TPL_DESC_ROGUE_OPENER_BURST"],
            body = "#showtooltip {spell:185313:Shadow Dance}\n/startattack\n/use 13\n/cast {spell:212283:Symbols of Death}\n/cast {spell:121471:Shadow Blades}\n/cast {spell:185313:Shadow Dance}\n/cast {spell:185438:Shadowstrike}",
        },
        {
            category = "offensive", name = "Builder Smart",
            description = L["TPL_DESC_ROGUE_BUILDER_SMART"],
            body = "#showtooltip\n/cast [stealth] {spell:185438:Shadowstrike}; {spell:53:Backstab}",
        },
        {
            category = "offensive", name = "Finisher Multi",
            description = L["TPL_DESC_ROGUE_FINISHER_MULTI"],
            body = "#showtooltip\n/cast [mod:shift,@focus,harm,nodead][mod:shift] {spell:408:Kidney Shot}\n/cast [mod:ctrl] {spell:315496:Slice and Dice}\n/cast [nomod] {spell:196819:Eviscerate}",
        },
        {
            category = "cc", name = "CC Smart",
            description = L["TPL_DESC_ROGUE_CC_SMART"],
            body = "#showtooltip\n/cast [stealth] {spell:1833:Cheap Shot}; {spell:2094:Blind}",
        },
        {
            category = "defensive", name = "Defensives",
            description = L["TPL_DESC_ROGUE_DEFENSIFS"],
            body = "#showtooltip\n/cast [mod:shift] {spell:31224:Cloak of Shadows}\n/cast [mod:ctrl] {spell:1966:Feint}\n/cast [nomod] {spell:5277:Evasion}",
        },
        {
            category = "defensive", name = "Vanish",
            description = L["TPL_DESC_ROGUE_VANISH"],
            body = "#showtooltip {spell:1856:Vanish}\n/stopattack\n/cast {spell:1856:Vanish}",
        },
    },
    WARRIOR = {
        {
            category = "interrupt", name = "Pummel Priority",
            description = L["TPL_DESC_WARRIOR_PUMMEL_PRIORITY"],
            body = "#showtooltip\n/cast [mod:shift] {spell:5246:Intimidating Shout}\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:6552:Pummel}",
        },
        {
            category = "offensive", name = "Charge + Attack",
            description = L["TPL_DESC_WARRIOR_CHARGE_ATTACK"],
            body = "#showtooltip {spell:100:Charge}\n/startattack\n/cast {spell:100:Charge}",
        },
        {
            category = "defensive", name = "Def Multi",
            description = L["TPL_DESC_WARRIOR_DEF_MULTI"],
            body = "#showtooltip\n/cast [mod:shift] {spell:184364:Enraged Regeneration}\n/cast [mod:ctrl] {spell:97462:Rallying Cry}\n/cast [nomod] {spell:871:Shield Wall}",
        },
    },
    PALADIN = {
        {
            category = "interrupt", name = "Rebuke Priority",
            description = L["TPL_DESC_PALADIN_REBUKE_PRIORITY"],
            body = "#showtooltip\n/cast [mod:shift,@focus,harm,nodead][mod:shift] {spell:853:Hammer of Justice}\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:96231:Rebuke}",
        },
        {
            category = "healer", name = "Heal Smart",
            description = L["TPL_DESC_PALADIN_HEAL_SMART"],
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] {spell:82326:Holy Light}",
        },
        {
            category = "defensive", name = "Bubble + Cancel",
            description = L["TPL_DESC_PALADIN_BUBBLE_CANCEL"],
            body = "#showtooltip {spell:642:Divine Shield}\n/cast [nomod] {spell:642:Divine Shield}\n/cancelaura [mod:shift] {spell:642:Divine Shield}",
        },
    },
    MAGE = {
        {
            category = "interrupt", name = "Counterspell Priority",
            description = L["TPL_DESC_MAGE_COUNTERSPELL_PRIORITY"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:2139:Counterspell}",
        },
        {
            category = "cc", name = "Polymorph Focus",
            description = L["TPL_DESC_MAGE_POLYMORPH_FOCUS"],
            body = "#showtooltip {spell:118:Polymorph}\n/cast [@focus,exists,nodead][mod:shift] {spell:118:Polymorph}",
        },
        {
            category = "defensive", name = "Ice Block Cancel",
            description = L["TPL_DESC_MAGE_ICE_BLOCK_CANCEL"],
            body = "#showtooltip {spell:45438:Ice Block}\n/cast [nomod] {spell:45438:Ice Block}\n/cancelaura [mod:shift] {spell:45438:Ice Block}",
        },
    },
    HUNTER = {
        {
            category = "interrupt", name = "Counter Shot Priority",
            description = L["TPL_DESC_HUNTER_COUNTER_SHOT_PRIORITY"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:147362:Counter Shot}",
        },
        {
            category = "utility", name = "Pet Control",
            description = L["TPL_DESC_HUNTER_PET_CONTROL"],
            body = "#showtooltip\n/petpassive [mod:shift]\n/petfollow [mod:ctrl]\n/petattack [nomod]",
        },
        {
            category = "cc", name = "Trap Mouseover",
            description = L["TPL_DESC_HUNTER_TRAP_MOUSEOVER"],
            body = "#showtooltip {spell:187650:Freezing Trap}\n/cast [@cursor] {spell:187650:Freezing Trap}",
        },
    },
    PRIEST = {
        {
            category = "healer", name = "Heal Mouseover",
            description = L["TPL_DESC_PRIEST_HEAL_MOUSEOVER"],
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] {spell:2061:Flash Heal}",
        },
        {
            category = "healer", name = "Dispel Smart",
            description = L["TPL_DESC_PRIEST_DISPEL_SMART"],
            body = "#showtooltip\n/cast [@mouseover,help,nodead][] {spell:213634:Purify Disease}",
        },
        {
            category = "defensive", name = "Fade + Shield",
            description = L["TPL_DESC_PRIEST_FADE_SHIELD"],
            body = "#showtooltip\n/cast [mod:shift,@player] {spell:17:Power Word: Shield}\n/cast [nomod] {spell:586:Fade}",
        },
    },
    DRUID = {
        {
            category = "interrupt", name = "Skull Bash Priority",
            description = L["TPL_DESC_DRUID_SKULL_BASH_PRIORITY"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:106839:Skull Bash}",
        },
        {
            category = "healer", name = "Rejuv Mouseover",
            description = L["TPL_DESC_DRUID_REJUV_MOUSEOVER"],
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] {spell:774:Rejuvenation}",
        },
        {
            category = "utility", name = "Form Cancel + Cast",
            description = L["TPL_DESC_DRUID_FORM_CANCEL_CAST"],
            body = "#showtooltip\n/cancelform [form:1/2/3/4]\n/cast {ph:SORT}",
        },
    },
    DEATHKNIGHT = {
        {
            category = "interrupt", name = "Mind Freeze Priority",
            description = L["TPL_DESC_DEATHKNIGHT_MIND_FREEZE_PRIORITY"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:47528:Mind Freeze}",
        },
        {
            category = "offensive", name = "Death Grip + Attack",
            description = L["TPL_DESC_DEATHKNIGHT_DEATH_GRIP_ATTACK"],
            body = "#showtooltip {spell:49576:Death Grip}\n/startattack\n/cast {spell:49576:Death Grip}",
        },
    },
    SHAMAN = {
        {
            category = "interrupt", name = "Wind Shear Priority",
            description = L["TPL_DESC_SHAMAN_WIND_SHEAR_PRIORITY"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:57994:Wind Shear}",
        },
        {
            category = "healer", name = "Healing Surge MO",
            description = L["TPL_DESC_SHAMAN_HEALING_SURGE_MO"],
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] {spell:8004:Healing Surge}",
        },
    },
    WARLOCK = {
        {
            category = "interrupt", name = "Spelllock Pet",
            description = L["TPL_DESC_WARLOCK_SPELLLOCK_PET"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][] {spell:19647:Spell Lock}",
        },
        {
            category = "utility", name = "Pet Sacrifice",
            description = L["TPL_DESC_WARLOCK_PET_SACRIFICE"],
            body = "#showtooltip\n/cast [mod:shift] {spell:108416:Dark Pact}\n/cast [nomod] {spell:108503:Grimoire of Sacrifice}",
        },
    },
    MONK = {
        {
            category = "interrupt", name = "Spear Hand Priority",
            description = L["TPL_DESC_MONK_SPEAR_HAND_PRIORITY"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:116705:Spear Hand Strike}",
        },
        {
            category = "healer", name = "Vivify MO",
            description = L["TPL_DESC_MONK_VIVIFY_MO"],
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] {spell:116670:Vivify}",
        },
    },
    DEMONHUNTER = {
        {
            category = "interrupt", name = "Disrupt Priority",
            description = L["TPL_DESC_DEMONHUNTER_DISRUPT_PRIORITY"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:183752:Disrupt}",
        },
        {
            category = "offensive", name = "Fel Rush + Attack",
            description = L["TPL_DESC_DEMONHUNTER_FEL_RUSH_ATTACK"],
            body = "#showtooltip {spell:195072:Fel Rush}\n/startattack\n/cast {spell:195072:Fel Rush}",
        },
    },
    EVOKER = {
        {
            category = "interrupt", name = "Quell Priority",
            description = L["TPL_DESC_EVOKER_QUELL_PRIORITY"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:351338:Quell}",
        },
        {
            category = "healer", name = "Dream Breath MO",
            description = L["TPL_DESC_EVOKER_DREAM_BREATH_MO"],
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] {spell:355936:Dream Breath}",
        },
    },
}

MF.Templates.CLASS_TEMPLATES = CLASS_TEMPLATES
MF.Templates.UNIVERSAL = UNIVERSAL

---------------------------------------------------
-- API
---------------------------------------------------
function MF.Templates:GetByCategory(categoryId)
    local result = {}
    for _, t in ipairs(UNIVERSAL) do
        if categoryId == "" or t.category == categoryId then
            table.insert(result, t)
        end
    end
    return result
end

function MF.Templates:GetPlayerClass()
    local _, cls = UnitClass("player")
    return cls or "WARRIOR"
end

function MF.Templates:GetTemplatesForPlayer(categoryFilter)
    local cls = self:GetPlayerClass()
    local result = {}
    -- Universal first
    for _, t in ipairs(UNIVERSAL) do
        if not categoryFilter or categoryFilter == "" or t.category == categoryFilter then
            t._source = "universal"
            table.insert(result, t)
        end
    end
    -- Class-specific
    local cTemplates = CLASS_TEMPLATES[cls]
    if cTemplates then
        for _, t in ipairs(cTemplates) do
            if not categoryFilter or categoryFilter == "" or t.category == categoryFilter then
                t._source = cls
                table.insert(result, t)
            end
        end
    end
    return result
end

---------------------------------------------------
-- Body resolution
-- Template bodies never hold localized spell names: WoW matches /cast by
-- name in the client's language. Markers are resolved when a template is
-- previewed, loaded or created:
--   {spell:ID:Name}  spell name in the client language (Name if the spell
--                    does not exist in this client, e.g. another flavor)
--   {ph:KEY}         placeholder to replace by hand (L["TPL_PH_KEY"])
---------------------------------------------------
local GetSpellName = C_Spell and C_Spell.GetSpellName
    or function(id) return (GetSpellInfo(id)) end

function MF.Templates:ResolveBody(body)
    if not body then return "" end
    body = body:gsub("{spell:(%d+):([^}]*)}", function(id, fallback)
        return GetSpellName(tonumber(id)) or fallback
    end)
    return (body:gsub("{ph:([%w_]+)}", function(key)
        return L["TPL_PH_" .. key]
    end))
end

---------------------------------------------------
-- Templates Browser UI
---------------------------------------------------
local browserFrame

function MF.Templates:OpenBrowser()
    local AceGUI = LibStub("AceGUI-3.0")

    if browserFrame then
        browserFrame:Release()
        browserFrame = nil
    end

    local f = AceGUI:Create("Frame")
    f:SetTitle("|cff00ccffMacroForge|r - " .. L["TEMPLATES"])
    f:SetWidth(560)
    f:SetHeight(600)
    f:SetLayout("Flow")
    f:SetCallback("OnClose", function(w) w:Release(); browserFrame = nil end)
    f:EnableResize(true)
    browserFrame = f

    -- Dark BG
    local bg = f.frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
    bg:SetPoint("TOPLEFT", f.content, -5, 5)
    bg:SetPoint("BOTTOMRIGHT", f.content, 5, -5)

    -- Class indicator
    local cls = self:GetPlayerClass()
    local clsColor = CLASS_COLORS[cls] or "|cffffffff"
    local clsName = UnitClass("player") or cls

    local clsLabel = AceGUI:Create("Label")
    clsLabel:SetFullWidth(true)
    clsLabel:SetFontObject(GameFontNormalLarge)
    clsLabel:SetText(clsColor .. clsName .. "|r  " .. MF.C.grey .. L["TPL_HEADER"] .. "|r")
    f:AddChild(clsLabel)

    -- Filter row
    local filterRow = AceGUI:Create("SimpleGroup")
    filterRow:SetFullWidth(true)
    filterRow:SetLayout("Flow")

    -- Category dropdown
    local catDD = AceGUI:Create("Dropdown")
    catDD:SetLabel("|cffffff33" .. L["TPL_CATEGORY"] .. "|r")
    catDD:SetWidth(200)
    local catList, catOrder = { [""] = L["TPL_ALL"] }, { "" }
    for _, cat in ipairs(self.CATEGORIES) do
        catList[cat.id] = cat.name
        table.insert(catOrder, cat.id)
    end
    catDD:SetList(catList, catOrder)
    catDD:SetValue("")
    filterRow:AddChild(catDD)

    -- Source filter (universal/class)
    local srcDD = AceGUI:Create("Dropdown")
    srcDD:SetLabel("|cffffff33" .. L["TPL_SOURCE"] .. "|r")
    srcDD:SetWidth(160)
    srcDD:SetList({
        [""] = L["TPL_ALL"],
        ["universal"] = L["TPL_SRC_UNIVERSAL"],
        [cls] = clsColor .. clsName .. "|r",
    }, { "", "universal", cls })
    srcDD:SetValue("")
    filterRow:AddChild(srcDD)

    f:AddChild(filterRow)

    -- Results scroll
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    scroll:SetLayout("List")

    local currentCat = ""
    local currentSrc = ""

    local function PopulateTemplates()
        scroll:ReleaseChildren()
        local An = MF:GetModule("Analyzer")
        local templates = self:GetTemplatesForPlayer(currentCat)

        local count = 0
        for _, tmpl in ipairs(templates) do
            local srcMatch = (currentSrc == "" or tmpl._source == currentSrc)
            if srcMatch then
                local grp = AceGUI:Create("InlineGroup")
                grp:SetFullWidth(true)
                local srcTag = tmpl._source == "universal"
                    and (MF.C.grey .. L["TPL_TAG_UNIVERSAL"] .. "|r")
                    or (clsColor .. "[" .. clsName .. "]|r")
                grp:SetTitle(srcTag .. "  " .. (tmpl.name or "?"))
                grp:SetLayout("List")

                -- Description
                local descLbl = AceGUI:Create("Label")
                descLbl:SetFullWidth(true)
                descLbl:SetFontObject(GameFontNormalSmall)
                descLbl:SetText(MF.C.grey .. (tmpl.description or "") .. "|r")
                grp:AddChild(descLbl)

                -- Colorized preview of body
                if An and tmpl.body then
                    local colored = An:ColorizeBody(MF.Templates:ResolveBody(tmpl.body))
                    local pvLbl = AceGUI:Create("Label")
                    pvLbl:SetFullWidth(true)
                    pvLbl:SetFontObject(GameFontNormalSmall)
                    pvLbl:SetText(colored)
                    grp:AddChild(pvLbl)
                end

                -- Buttons
                local btnRow = AceGUI:Create("SimpleGroup")
                btnRow:SetFullWidth(true)
                btnRow:SetLayout("Flow")

                local btnEdit = AceGUI:Create("Button")
                btnEdit:SetText(L["EDIT"])
                btnEdit:SetWidth(100)
                btnEdit:SetCallback("OnClick", function()
                    local E = MF:GetModule("Editor")
                    if E then
                        E:OpenNew(true)
                        C_Timer.After(0.1, function()
                            E:LoadContent(tmpl.name or "", MF.Templates:ResolveBody(tmpl.body), 134400)
                        end)
                    end
                    if browserFrame then browserFrame:Release(); browserFrame = nil end
                end)
                btnRow:AddChild(btnEdit)

                local btnCreate = AceGUI:Create("Button")
                btnCreate:SetText(L["TPL_CREATE_DIRECT"])
                btnCreate:SetWidth(150)
                btnCreate:SetCallback("OnClick", function()
                    local P = MF:GetModule("Profiles")
                    if P then
                        P:CreateNewMacro(tmpl.name or "Template", 134400, MF.Templates:ResolveBody(tmpl.body), true)
                        local UI = MF:GetModule("UI")
                        if UI then C_Timer.After(0.3, function() UI:Refresh() end) end
                    end
                end)
                btnRow:AddChild(btnCreate)

                grp:AddChild(btnRow)
                scroll:AddChild(grp)
                count = count + 1
            end
        end

        if count == 0 then
            local lbl = AceGUI:Create("Label")
            lbl:SetFullWidth(true)
            lbl:SetText(MF.C.grey .. L["TPL_EMPTY"] .. "|r")
            scroll:AddChild(lbl)
        end
    end

    catDD:SetCallback("OnValueChanged", function(_, _, val)
        currentCat = val
        PopulateTemplates()
    end)
    srcDD:SetCallback("OnValueChanged", function(_, _, val)
        currentSrc = val
        PopulateTemplates()
    end)

    f:AddChild(scroll)
    PopulateTemplates()
    f:Show()
end

MF:RegisterModule("Templates", MF.Templates)
