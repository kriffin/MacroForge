---------------------------------------------------
-- MacroForge — Templates
-- Multi-class macro templates, auto-detect player class
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
MF.Templates = {}

---------------------------------------------------
-- Categories
---------------------------------------------------
MF.Templates.CATEGORIES = {
    { id = "universal",  name = "|cffffffffUniversel|r" },
    { id = "interrupt",  name = "|cff33ccffInterrupt|r" },
    { id = "offensive",  name = "|cffff6633Offensif|r" },
    { id = "defensive",  name = "|cff66ccffDefensif|r" },
    { id = "cc",         name = "|cffcc33ffCC|r" },
    { id = "utility",    name = "|cffaaaaaaUtilitaire|r" },
    { id = "pvp",        name = "|cffff3333PvP|r" },
    { id = "tank",       name = "|cff3399ffTank|r" },
    { id = "healer",     name = "|cff33ff99Healer|r" },
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
        description = "Lance sur mouseover s'il existe, sinon sur la cible courante.",
        body = "#showtooltip\n/cast [@mouseover,help,nodead][] SORT",
    },
    {
        category = "universal", name = "Focus Interrupt",
        description = "Interrupt le focus si hostile et vivant, sinon la cible.",
        body = "#showtooltip\n/cast [@focus,harm,nodead][] SORT",
    },
    {
        category = "universal", name = "Mouseover Harm",
        description = "Cast offensif sur mouseover si hostile, sinon cible.",
        body = "#showtooltip\n/cast [@mouseover,harm,nodead][] SORT",
    },
    {
        category = "universal", name = "Trinket 1",
        description = "Utilise le trinket slot 13.",
        body = "#showtooltip\n/use 13",
    },
    {
        category = "universal", name = "Trinket 2",
        description = "Utilise le trinket slot 14.",
        body = "#showtooltip\n/use 14",
    },
    {
        category = "universal", name = "Mount Smart",
        description = "Monte/descend de monture. En vol = vol dynamique, au sol = monture terrestre.",
        body = "#showtooltip\n/dismount [mounted]\n/cast [advflyable] MONTURE_VOL; MONTURE_SOL",
    },
    {
        category = "universal", name = "Cancelaura + Cast",
        description = "Annule un buff puis lance un sort (ex: Bouclier de glace + cast).",
        body = "#showtooltip\n/cancelaura NOM_BUFF\n/cast SORT",
    },
    {
        category = "universal", name = "Startattack + Cast",
        description = "Lance l'attaque auto en meme temps que le cast.",
        body = "#showtooltip\n/startattack\n/cast SORT",
    },
    {
        category = "universal", name = "Mod Shift/Ctrl/Alt",
        description = "Sort different selon le modificateur (Shift/Ctrl/par defaut).",
        body = "#showtooltip\n/cast [mod:shift] SORT_SHIFT; [mod:ctrl] SORT_CTRL; SORT_NORMAL",
    },
    {
        category = "universal", name = "Cast Sequence",
        description = "Sequence de sorts avec reset sur changement de cible.",
        body = "#showtooltip\n/castsequence reset=target SORT1, SORT2, SORT3",
    },
    {
        category = "universal", name = "Stopcasting + Cast",
        description = "Interrompt votre propre incantation pour lancer un sort prioritaire.",
        body = "#showtooltip\n/stopcasting\n/cast SORT",
    },
    {
        category = "utility", name = "Focus Set/Clear",
        description = "Definit la cible comme focus, ou efface le focus si elle l'est deja.",
        body = "/focus [@focus,exists] [nomod]\n/clearfocus [@focus,exists] [mod:shift]",
    },
    {
        category = "pvp", name = "Arena Target 1",
        description = "Cible le joueur arena 1.",
        body = "#showtooltip\n/cast [@arena1] SORT",
    },
    {
        category = "pvp", name = "Arena Target 2",
        description = "Cible le joueur arena 2.",
        body = "#showtooltip\n/cast [@arena2] SORT",
    },
    {
        category = "pvp", name = "Arena Target 3",
        description = "Cible le joueur arena 3.",
        body = "#showtooltip\n/cast [@arena3] SORT",
    },
    {
        category = "pvp", name = "PvP Trinket",
        description = "Breaker CC — Trinket PvP.",
        body = "#showtooltip\n/use 14",
    },
    {
        category = "healer", name = "Mouseover Heal",
        description = "Heal le mouseover allié vivant, sinon la cible, sinon vous.",
        body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] SORT_HEAL",
    },
    {
        category = "healer", name = "Dispel Mouseover",
        description = "Dispel le mouseover allié, sinon la cible.",
        body = "#showtooltip\n/cast [@mouseover,help,nodead][] SORT_DISPEL",
    },
    {
        category = "tank", name = "Taunt Mouseover",
        description = "Provoque le mouseover ennemi, sinon la cible.",
        body = "#showtooltip\n/cast [@mouseover,harm,nodead][] SORT_TAUNT",
    },
    {
        category = "tank", name = "Defensive + Mod",
        description = "Defensif principal, Shift = second defensif.",
        body = "#showtooltip\n/cast [mod:shift] GROS_DEF; PETIT_DEF",
    },
}

---------------------------------------------------
-- Template Data — Class-Specific
---------------------------------------------------
local CLASS_TEMPLATES = {
    ROGUE = {
        {
            category = "interrupt", name = "Kick Priority",
            description = "Kick Focus > Mouseover > Target. Shift=Gouge, Ctrl=Kidney.",
            body = "#showtooltip\n/cast [mod:shift,@focus,harm,nodead][mod:shift,@mouseover,harm,nodead][mod:shift] Gouger\n/cast [mod:ctrl,@focus,harm,nodead][mod:ctrl] Coup au rein\n/cast [nomod,@focus,harm,nodead][nomod,@mouseover,harm,nodead][nomod] Coup de pied",
        },
        {
            category = "offensive", name = "Opener Burst",
            description = "Full burst stealth: Trinket + Symbols + Dance + Shadowstrike.",
            body = "#showtooltip Danse de l'ombre\n/startattack\n/use 13\n/cast Symboles de mort\n/cast Lames de l'ombre\n/cast Danse de l'ombre\n/cast Frappe-tenebres",
        },
        {
            category = "offensive", name = "Builder Smart",
            description = "Stealth=Shadowstrike, sinon Backstab.",
            body = "#showtooltip\n/cast [stealth] Frappe-tenebres; Attaque sournoise",
        },
        {
            category = "offensive", name = "Finisher Multi",
            description = "Evisc / Shift=Kidney @focus / Ctrl=Slice.",
            body = "#showtooltip\n/cast [mod:shift,@focus,harm,nodead][mod:shift] Coup au rein\n/cast [mod:ctrl] Tranche Menu\n/cast [nomod] Evisceration",
        },
        {
            category = "cc", name = "CC Smart",
            description = "Stealth=Cheap Shot, sinon Blind.",
            body = "#showtooltip\n/cast [stealth] Coup bas; Cecite",
        },
        {
            category = "defensive", name = "Defensifs",
            description = "Evasion / Shift=Cape / Ctrl=Feinte.",
            body = "#showtooltip\n/cast [mod:shift] Cape de l'ombre\n/cast [mod:ctrl] Feinte\n/cast [nomod] Evasion",
        },
        {
            category = "defensive", name = "Vanish",
            description = "Stop attack + Vanish clean.",
            body = "#showtooltip Disparition\n/stopattack\n/cast Disparition",
        },
    },
    WARRIOR = {
        {
            category = "interrupt", name = "Pummel Priority",
            description = "Pummel Focus > Mouseover > Target. Shift=Intimidating Shout.",
            body = "#showtooltip\n/cast [mod:shift] Cri d'intimidation\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] Volée de coups",
        },
        {
            category = "offensive", name = "Charge + Attack",
            description = "Charge puis attaque automatique.",
            body = "#showtooltip Charge\n/startattack\n/cast Charge",
        },
        {
            category = "defensive", name = "Def Multi",
            description = "Mur protecteur / Shift=Enrager / Ctrl=Rallying Cry.",
            body = "#showtooltip\n/cast [mod:shift] Enrager\n/cast [mod:ctrl] Cri de ralliement\n/cast [nomod] Mur protecteur",
        },
    },
    PALADIN = {
        {
            category = "interrupt", name = "Rebuke Priority",
            description = "Rebuke Focus > Mouseover > Target. Shift=HoJ.",
            body = "#showtooltip\n/cast [mod:shift,@focus,harm,nodead][mod:shift] Marteau de la justice\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] Rebuffade",
        },
        {
            category = "healer", name = "Heal Smart",
            description = "Mouseover heal, sinon target, sinon player.",
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] Lumiere sacree",
        },
        {
            category = "defensive", name = "Bubble + Cancel",
            description = "Bouclier divin, Shift pour l'annuler.",
            body = "#showtooltip Bouclier divin\n/cast [nomod] Bouclier divin\n/cancelaura [mod:shift] Bouclier divin",
        },
    },
    MAGE = {
        {
            category = "interrupt", name = "Counterspell Priority",
            description = "Counterspell Focus > Mouseover > Target.",
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] Contresort",
        },
        {
            category = "cc", name = "Polymorph Focus",
            description = "Poly le focus, Shift = la cible.",
            body = "#showtooltip Metamorphose\n/cast [@focus,exists,nodead][mod:shift] Metamorphose",
        },
        {
            category = "defensive", name = "Ice Block Cancel",
            description = "Ice Block, Shift pour annuler.",
            body = "#showtooltip Bloc de glace\n/cast [nomod] Bloc de glace\n/cancelaura [mod:shift] Bloc de glace",
        },
    },
    HUNTER = {
        {
            category = "interrupt", name = "Counter Shot Priority",
            description = "Counter Shot Focus > Mouseover > Target.",
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] Tir de desarcon",
        },
        {
            category = "utility", name = "Pet Control",
            description = "Shift=Passif, Ctrl=Suivre, sinon Attaque.",
            body = "#showtooltip\n/petpassive [mod:shift]\n/petfollow [mod:ctrl]\n/petattack [nomod]",
        },
        {
            category = "cc", name = "Trap Mouseover",
            description = "Piege givrant au curseur.",
            body = "#showtooltip Piege givrant\n/cast [@cursor] Piege givrant",
        },
    },
    PRIEST = {
        {
            category = "healer", name = "Heal Mouseover",
            description = "Heal mouseover > target > self.",
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] Soins rapides",
        },
        {
            category = "healer", name = "Dispel Smart",
            description = "Purifier mouseover ally, sinon target.",
            body = "#showtooltip\n/cast [@mouseover,help,nodead][] Purifier la maladie",
        },
        {
            category = "defensive", name = "Fade + Shield",
            description = "Shift=Bouclier sur soi, sinon Oubli.",
            body = "#showtooltip\n/cast [mod:shift,@player] Mot de pouvoir : Bouclier\n/cast [nomod] Oubli",
        },
    },
    DRUID = {
        {
            category = "interrupt", name = "Skull Bash Priority",
            description = "Skull Bash Focus > Mouseover > Target.",
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] Choc cerebral",
        },
        {
            category = "healer", name = "Rejuv Mouseover",
            description = "Recuperation mouseover > target > self.",
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] Recuperation",
        },
        {
            category = "utility", name = "Form Cancel + Cast",
            description = "Annule forme actuelle pour cast (ex: heal en Feral).",
            body = "#showtooltip\n/cancelform [form:1/2/3/4]\n/cast SORT",
        },
    },
    DEATHKNIGHT = {
        {
            category = "interrupt", name = "Mind Freeze Priority",
            description = "Mind Freeze Focus > Mouseover > Target.",
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] Gel de l'esprit",
        },
        {
            category = "offensive", name = "Death Grip + Attack",
            description = "Agrippe et attaque.",
            body = "#showtooltip Poigne de la mort\n/startattack\n/cast Poigne de la mort",
        },
    },
    SHAMAN = {
        {
            category = "interrupt", name = "Wind Shear Priority",
            description = "Wind Shear Focus > Mouseover > Target.",
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] Cisaillement",
        },
        {
            category = "healer", name = "Healing Surge MO",
            description = "Vague de soins mouseover > target > self.",
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] Vague de soins",
        },
    },
    WARLOCK = {
        {
            category = "interrupt", name = "Spelllock Pet",
            description = "Interrupt via familier sur Focus > Target.",
            body = "#showtooltip\n/cast [@focus,harm,nodead][] Verrouillage de sort",
        },
        {
            category = "utility", name = "Pet Sacrifice",
            description = "Sacrifice du familier ou invocation.",
            body = "#showtooltip\n/cast [mod:shift] Pacte demoniaque\n/cast [nomod] Sacrifice demoniaque",
        },
    },
    MONK = {
        {
            category = "interrupt", name = "Spear Hand Priority",
            description = "Frappe de la main en fer Focus > MO > Target.",
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] Frappe de la paume",
        },
        {
            category = "healer", name = "Vivify MO",
            description = "Vivifier mouseover > target > self.",
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] Vivifier",
        },
    },
    DEMONHUNTER = {
        {
            category = "interrupt", name = "Disrupt Priority",
            description = "Disrupt Focus > Mouseover > Target.",
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] Perturbation",
        },
        {
            category = "offensive", name = "Fel Rush + Attack",
            description = "Ruee de Gangrefeu puis attaque.",
            body = "#showtooltip Ruee de Gangrefeu\n/startattack\n/cast Ruee de Gangrefeu",
        },
    },
    EVOKER = {
        {
            category = "interrupt", name = "Quell Priority",
            description = "Apaisement Focus > Mouseover > Target.",
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] Apaisement",
        },
        {
            category = "healer", name = "Dream Breath MO",
            description = "Souffle onirique mouseover > target > self.",
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] Souffle onirique",
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
    f:SetTitle("|cff00ccffMacroForge|r - Templates")
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
    clsLabel:SetText(clsColor .. clsName .. "|r  " .. MF.C.grey .. "— Templates universels + specifiques a votre classe|r")
    f:AddChild(clsLabel)

    -- Filter row
    local filterRow = AceGUI:Create("SimpleGroup")
    filterRow:SetFullWidth(true)
    filterRow:SetLayout("Flow")

    -- Category dropdown
    local catDD = AceGUI:Create("Dropdown")
    catDD:SetLabel("|cffffff33Categorie|r")
    catDD:SetWidth(200)
    local catList, catOrder = { [""] = "Toutes" }, { "" }
    for _, cat in ipairs(self.CATEGORIES) do
        catList[cat.id] = cat.name
        table.insert(catOrder, cat.id)
    end
    catDD:SetList(catList, catOrder)
    catDD:SetValue("")
    filterRow:AddChild(catDD)

    -- Source filter (universal/class)
    local srcDD = AceGUI:Create("Dropdown")
    srcDD:SetLabel("|cffffff33Source|r")
    srcDD:SetWidth(160)
    srcDD:SetList({
        [""] = "Toutes",
        ["universal"] = "Universelles",
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
                    and (MF.C.grey .. "[Universel]|r")
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
                    local colored = An:ColorizeBody(tmpl.body)
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
                btnEdit:SetText("Editer")
                btnEdit:SetWidth(100)
                btnEdit:SetCallback("OnClick", function()
                    local E = MF:GetModule("Editor")
                    if E then
                        E:OpenNew(true)
                        C_Timer.After(0.1, function()
                            E:LoadContent(tmpl.name or "", tmpl.body or "", 134400)
                        end)
                    end
                    if browserFrame then browserFrame:Release(); browserFrame = nil end
                end)
                btnRow:AddChild(btnEdit)

                local btnCreate = AceGUI:Create("Button")
                btnCreate:SetText("Creer directement")
                btnCreate:SetWidth(150)
                btnCreate:SetCallback("OnClick", function()
                    local P = MF:GetModule("Profiles")
                    if P then
                        P:CreateNewMacro(tmpl.name or "Template", 134400, tmpl.body or "", true)
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
            lbl:SetText(MF.C.grey .. "Aucune template dans cette categorie.|r")
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
