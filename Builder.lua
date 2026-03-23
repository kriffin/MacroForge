---------------------------------------------------
-- MacroForge — Condition Builder
-- Visual dropdown-based condition composer
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local Builder = {}
local AceGUI

local function G()
    if not AceGUI then AceGUI = LibStub("AceGUI-3.0") end
    return AceGUI
end

local builderFrame
local state = {}

---------------------------------------------------
-- Data tables
---------------------------------------------------
local TARGETS = {
    { value = "",             label = "(aucune)" },
    { value = "player",       label = "@player" },
    { value = "target",       label = "@target" },
    { value = "targettarget", label = "@targettarget" },
    { value = "focus",        label = "@focus" },
    { value = "focustarget",  label = "@focustarget" },
    { value = "mouseover",    label = "@mouseover" },
    { value = "pet",          label = "@pet" },
    { value = "arena1",       label = "@arena1" },
    { value = "arena2",       label = "@arena2" },
    { value = "arena3",       label = "@arena3" },
    { value = "party1",       label = "@party1" },
    { value = "party2",       label = "@party2" },
    { value = "cursor",       label = "@cursor" },
    { value = "none",         label = "@none" },
}

local CONDITIONS = {
    { value = "",              label = "(aucune)",       hasArg = false, desc = "Aucune condition" },
    { value = "help",          label = "help (allie)",   hasArg = false, desc = "Vrai si la cible est amicale" },
    { value = "harm",          label = "harm (ennemi)",  hasArg = false, desc = "Vrai si la cible est hostile" },
    { value = "exists",        label = "exists",         hasArg = false, desc = "Vrai si la cible existe" },
    { value = "dead",          label = "dead",           hasArg = false, desc = "Vrai si la cible est morte" },
    { value = "nodead",        label = "nodead (vivant)",hasArg = false, desc = "Vrai si la cible est vivante" },
    { value = "combat",        label = "combat",         hasArg = false, desc = "Vrai si vous etes en combat" },
    { value = "nocombat",      label = "nocombat",       hasArg = false, desc = "Vrai si vous n'etes pas en combat" },
    { value = "stealth",       label = "stealth",        hasArg = false, desc = "Vrai si vous etes en camouflage" },
    { value = "nostealth",     label = "nostealth",      hasArg = false, desc = "Vrai si vous n'etes pas en camouflage" },
    { value = "mod",           label = "mod (modifieur)",hasArg = true, argType = "mod", desc = "Vrai si une touche modifieur est enfoncee (Shift/Ctrl/Alt)" },
    { value = "nomod",         label = "nomod",          hasArg = false, desc = "Vrai si aucune touche modifieur n'est enfoncee" },
    { value = "mounted",       label = "mounted",        hasArg = false, desc = "Vrai si vous etes sur une monture" },
    { value = "nomounted",     label = "nomounted",      hasArg = false, desc = "Vrai si vous n'etes pas sur une monture" },
    { value = "flying",        label = "flying",         hasArg = false, desc = "Vrai si vous etes en vol" },
    { value = "noflying",      label = "noflying",       hasArg = false, desc = "Vrai si vous n'etes pas en vol" },
    { value = "swimming",      label = "swimming",       hasArg = false, desc = "Vrai si vous nagez" },
    { value = "indoors",       label = "indoors",        hasArg = false, desc = "Vrai si vous etes en interieur" },
    { value = "outdoors",      label = "outdoors",       hasArg = false, desc = "Vrai si vous etes en exterieur" },
    { value = "channeling",    label = "channeling",     hasArg = true, argType = "text", desc = "Vrai si vous canalisez un sort (optionnel: nom du sort)" },
    { value = "nochanneling",  label = "nochanneling",   hasArg = false, desc = "Vrai si vous ne canalisez pas" },
    { value = "known",         label = "known",          hasArg = true, argType = "text", desc = "Vrai si le sort/talent est connu" },
    { value = "noknown",       label = "noknown",        hasArg = true, argType = "text", desc = "Vrai si le sort/talent n'est pas connu" },
    { value = "spec",          label = "spec",           hasArg = true, argType = "num4", desc = "Vrai si vous etes dans la specialisation N (1-4)" },
    { value = "talent",        label = "talent",         hasArg = true, argType = "numslash", desc = "Vrai si le talent tier/colonne est actif" },
    { value = "pvptalent",     label = "pvptalent",      hasArg = true, argType = "numslash", desc = "Vrai si le talent PvP tier/colonne est actif" },
    { value = "form",          label = "form/stance",    hasArg = true, argType = "num7", desc = "Vrai si vous etes dans la forme/posture N (0=aucune)" },
    { value = "group",         label = "group",          hasArg = true, argType = "group", desc = "Vrai si vous etes en groupe (party/raid)" },
    { value = "pet",           label = "pet (familier)", hasArg = false, desc = "Vrai si votre familier est actif" },
    { value = "nopet",         label = "nopet",          hasArg = false, desc = "Vrai si votre familier n'est pas actif" },
    { value = "btn",           label = "btn (bouton)",   hasArg = true, argType = "btn", desc = "Vrai si le bouton de souris specifie a ete utilise" },
    { value = "bar",           label = "bar",            hasArg = true, argType = "num7", desc = "Vrai si la barre d'action N est active" },
    { value = "bonusbar",      label = "bonusbar",       hasArg = true, argType = "num7", desc = "Vrai si la barre bonus N est active" },
    { value = "worn",          label = "worn/equipped",  hasArg = true, argType = "text", desc = "Vrai si l'objet ou type d'objet est equipe" },
    { value = "advflyable",    label = "advflyable",     hasArg = false, desc = "Vrai si le vol dynamique est disponible ici" },
    { value = "vehicleui",     label = "vehicleui",      hasArg = false, desc = "Vrai si l'interface vehicule est affichee" },
    { value = "canexitvehicle",label = "canexitvehicle", hasArg = false, desc = "Vrai si vous pouvez quitter le vehicule" },
    { value = "petbattle",     label = "petbattle",      hasArg = false, desc = "Vrai si vous etes en combat de mascottes" },
    { value = "cursor",        label = "cursor",         hasArg = false, desc = "Vrai si quelque chose est sur le curseur" },
}

local MOD_KEYS = {
    { value = "",      label = "(tout)" },
    { value = "shift", label = "shift" },
    { value = "ctrl",  label = "ctrl" },
    { value = "alt",   label = "alt" },
}

local BUTTONS = {
    { value = "1",           label = "LeftButton (1)" },
    { value = "2",           label = "RightButton (2)" },
    { value = "3",           label = "MiddleButton (3)" },
    { value = "4",           label = "Button4" },
    { value = "5",           label = "Button5" },
}

---------------------------------------------------
-- Build the condition string from state
---------------------------------------------------
local function BuildCondString()
    local parts = {}

    -- Target
    if state.target and state.target ~= "" then
        table.insert(parts, "@" .. state.target)
    end

    -- Conditions (up to 5 slots)
    for i = 1, 5 do
        local cond = state["cond" .. i]
        if cond and cond ~= "" then
            local arg = state["arg" .. i]
            if arg and arg ~= "" then
                table.insert(parts, cond .. ":" .. arg)
            else
                table.insert(parts, cond)
            end
        end
    end

    if #parts == 0 then return "" end
    return "[" .. table.concat(parts, ",") .. "]"
end

---------------------------------------------------
-- Build condition dropdown list/order for AceGUI
---------------------------------------------------
local function ToDropdownList(tbl)
    local list, order = {}, {}
    for _, entry in ipairs(tbl) do
        list[entry.value] = entry.label
        table.insert(order, entry.value)
    end
    return list, order
end

---------------------------------------------------
-- Find condition entry by value
---------------------------------------------------
local function FindCondEntry(val)
    for _, c in ipairs(CONDITIONS) do
        if c.value == val then return c end
    end
    return nil
end

---------------------------------------------------
-- Create Builder Frame
---------------------------------------------------
local function CreateBuilderFrame()
    if builderFrame then return end
    local gui = G()

    local f = gui:Create("Frame")
    f:SetTitle("|cff00ccffMacroForge|r - " .. L["BUILDER_TITLE"])
    f:SetWidth(600)
    f:SetHeight(500)
    f:SetLayout("Fill")
    f:SetCallback("OnClose", function(w) w:Hide() end)
    f:EnableResize(false)
    builderFrame = f

    -- Dark BG
    local bg = f.frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
    bg:SetPoint("TOPLEFT", f.content, -5, 5)
    bg:SetPoint("BOTTOMRIGHT", f.content, 5, -5)

    local scroll = gui:Create("ScrollFrame")
    scroll:SetLayout("List")
    f:AddChild(scroll)

    -- Heading
    local hd = gui:Create("Heading")
    hd:SetFullWidth(true)
    hd:SetText("|cffffff33" .. L["BUILDER_HEADING"] .. "|r")
    scroll:AddChild(hd)

    -- Target dropdown
    local targetList, targetOrder = ToDropdownList(TARGETS)
    local ddTarget = gui:Create("Dropdown")
    ddTarget:SetLabel(L["BUILDER_TARGET_LABEL"])
    ddTarget:SetFullWidth(true)
    ddTarget:SetList(targetList, targetOrder)
    ddTarget:SetValue("")
    ddTarget:SetCallback("OnValueChanged", function(_, _, val)
        state.target = val
        Builder:UpdatePreview()
    end)
    scroll:AddChild(ddTarget)

    -- Condition rows (5 slots)
    local condList, condOrder = ToDropdownList(CONDITIONS)
    local modList, modOrder = ToDropdownList(MOD_KEYS)

    local argWidgets = {}

    for i = 1, 5 do
        local grp = gui:Create("SimpleGroup")
        grp:SetFullWidth(true)
        grp:SetLayout("Flow")

        local dd = gui:Create("Dropdown")
        dd:SetLabel(i == 1 and "|cffffff33" .. L["BUILDER_CONDITIONS_LABEL"] .. "|r" or "")
        dd:SetWidth(300)
        dd:SetList(condList, condOrder)
        dd:SetValue("")

        -- Arg widget (hidden by default)
        local argDD = gui:Create("Dropdown")
        argDD:SetWidth(180)
        argDD:SetList(modList, modOrder)
        argDD:SetValue("")
        argDD.frame:Hide()

        local argEB = gui:Create("EditBox")
        argEB:SetWidth(180)
        argEB:SetLabel("")
        argEB:DisableButton(true)
        argEB.frame:Hide()

        argWidgets[i] = { dd = argDD, eb = argEB }

        -- Description label for this condition
        local descLbl = gui:Create("Label")
        descLbl:SetFullWidth(true)
        descLbl:SetFontObject(GameFontNormalSmall)
        descLbl:SetText("")
        descLbl.frame:Hide()

        dd:SetCallback("OnValueChanged", function(_, _, val)
            state["cond" .. i] = val
            state["arg" .. i] = ""
            -- Show/hide arg widget
            local entry = FindCondEntry(val)
            argDD.frame:Hide()
            argEB.frame:Hide()
            argDD:SetValue("")
            argEB:SetText("")

            -- Update description
            if entry and entry.desc and val ~= "" then
                descLbl:SetText(MF.C.grey .. entry.desc .. "|r")
                descLbl.frame:Show()
            else
                descLbl:SetText("")
                descLbl.frame:Hide()
            end

            if entry and entry.hasArg then
                if entry.argType == "mod" then
                    argDD:SetList(modList, modOrder)
                    argDD:SetValue("")
                    argDD.frame:Show()
                elseif entry.argType == "btn" then
                    local bList, bOrder = ToDropdownList(BUTTONS)
                    argDD:SetList(bList, bOrder)
                    argDD:SetValue("")
                    argDD.frame:Show()
                elseif entry.argType == "group" then
                    argDD:SetList({ [""] = "(tout)", party = "party", raid = "raid" }, { "", "party", "raid" })
                    argDD:SetValue("")
                    argDD.frame:Show()
                elseif entry.argType == "num4" then
                    local l, o = {}, {}
                    for n = 1, 4 do l[tostring(n)] = tostring(n); table.insert(o, tostring(n)) end
                    argDD:SetList(l, o)
                    argDD:SetValue("")
                    argDD.frame:Show()
                elseif entry.argType == "num7" then
                    local l, o = {}, {}
                    for n = 0, 7 do l[tostring(n)] = tostring(n); table.insert(o, tostring(n)) end
                    argDD:SetList(l, o)
                    argDD:SetValue("")
                    argDD.frame:Show()
                elseif entry.argType == "numslash" then
                    argEB:SetLabel("tier/col (ex: 1/2)")
                    argEB.frame:Show()
                else -- text
                    argEB:SetLabel("Valeur")
                    argEB.frame:Show()
                end
            end
            Builder:UpdatePreview()
        end)

        argDD:SetCallback("OnValueChanged", function(_, _, val)
            state["arg" .. i] = val
            Builder:UpdatePreview()
        end)

        argEB:SetCallback("OnTextChanged", function(w)
            state["arg" .. i] = w:GetText()
            Builder:UpdatePreview()
        end)

        grp:AddChild(dd)
        grp:AddChild(argDD)
        grp:AddChild(argEB)
        scroll:AddChild(grp)
        scroll:AddChild(descLbl)
    end

    -- Separator
    local sep = gui:Create("Heading")
    sep:SetFullWidth(true)
    sep:SetText("|cffffff33" .. L["BUILDER_PREVIEW"] .. "|r")
    scroll:AddChild(sep)

    -- Preview label
    local preview = gui:Create("Label")
    preview:SetFullWidth(true)
    preview:SetFontObject(GameFontHighlightLarge)
    preview:SetText(MF.C.grey .. L["BUILDER_EMPTY"] .. "|r")
    scroll:AddChild(preview)
    Builder.previewLabel = preview

    -- Buttons
    local btnGrp = gui:Create("SimpleGroup")
    btnGrp:SetFullWidth(true)
    btnGrp:SetLayout("Flow")

    local btnInsert = gui:Create("Button")
    btnInsert:SetText(L["BUILDER_INSERT"])
    btnInsert:SetWidth(200)
    btnInsert:SetCallback("OnClick", function()
        local cond = BuildCondString()
        if cond ~= "" then
            Builder:InsertToEditor(cond)
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
        end
    end)
    btnGrp:AddChild(btnInsert)

    local btnCopy = gui:Create("Button")
    btnCopy:SetText("Copier")
    btnCopy:SetWidth(100)
    btnCopy:SetCallback("OnClick", function()
        local cond = BuildCondString()
        if cond ~= "" then
            -- No clipboard in WoW, print it
            MF.Helpers:Print(MF.C.cyan .. "Condition: " .. MF.C.white .. cond .. MF.C.r)
        end
    end)
    btnGrp:AddChild(btnCopy)

    local btnReset = gui:Create("Button")
    btnReset:SetText(L["RESET"])
    btnReset:SetWidth(80)
    btnReset:SetCallback("OnClick", function()
        Builder:ResetState()
    end)
    btnGrp:AddChild(btnReset)

    scroll:AddChild(btnGrp)
    f:Hide()
end

---------------------------------------------------
-- API
---------------------------------------------------
function Builder:UpdatePreview()
    if not self.previewLabel then return end
    local cond = BuildCondString()
    if cond == "" then
        self.previewLabel:SetText(MF.C.grey .. L["BUILDER_EMPTY"] .. "|r")
    else
        -- Colorize the preview
        local An = MF:GetModule("Analyzer")
        if An then
            local colored = An:ColorizeLine("/cast " .. cond .. " Sort")
            self.previewLabel:SetText(colored)
        else
            self.previewLabel:SetText(MF.C.cyan .. cond .. MF.C.r)
        end
    end
end

function Builder:InsertToEditor(text)
    local E = MF:GetModule("Editor")
    if E and E.InsertText then
        E:InsertText(text)
    end
    if builderFrame then builderFrame:Hide() end
end

function Builder:ResetState()
    wipe(state)
    -- Destroy and recreate for clean dropdowns (AceGUI dropdowns don't support resetting values reliably)
    if builderFrame then
        local wasShown = builderFrame.frame:IsShown()
        builderFrame:Release()
        builderFrame = nil
        CreateBuilderFrame()
        if wasShown then builderFrame:Show() end
    end
end

function Builder:Open()
    if builderFrame then
        builderFrame:Release()
        builderFrame = nil
    end
    state = {}
    CreateBuilderFrame()
    builderFrame:Show()
end

function Builder:Toggle()
    if builderFrame and builderFrame.frame:IsShown() then
        builderFrame:Hide()
    else
        self:Open()
    end
end

MF:RegisterModule("Builder", Builder)
