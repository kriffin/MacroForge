---------------------------------------------------
-- MacroForge — Condition Builder
-- Visual dropdown-based condition composer
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local Builder = {}
local state = {}

---------------------------------------------------
-- Data tables
---------------------------------------------------
local TARGETS = {
    { value = "",             label = L["BUILDER_NONE"] },
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
    { value = "",              label = L["BUILDER_NONE"],       hasArg = false, desc = L["BUILDER_DESC_NONE"] },
    { value = "help",          label = L["BUILDER_LABEL_HELP"],   hasArg = false, desc = L["BUILDER_DESC_HELP"] },
    { value = "harm",          label = L["BUILDER_LABEL_HARM"],  hasArg = false, desc = L["BUILDER_DESC_HARM"] },
    { value = "exists",        label = "exists",         hasArg = false, desc = L["BUILDER_DESC_EXISTS"] },
    { value = "dead",          label = "dead",           hasArg = false, desc = L["BUILDER_DESC_DEAD"] },
    { value = "nodead",        label = L["BUILDER_LABEL_NODEAD"],hasArg = false, desc = L["BUILDER_DESC_NODEAD"] },
    { value = "combat",        label = "combat",         hasArg = false, desc = L["BUILDER_DESC_COMBAT"] },
    { value = "nocombat",      label = "nocombat",       hasArg = false, desc = L["BUILDER_DESC_NOCOMBAT"] },
    { value = "stealth",       label = "stealth",        hasArg = false, desc = L["BUILDER_DESC_STEALTH"] },
    { value = "nostealth",     label = "nostealth",      hasArg = false, desc = L["BUILDER_DESC_NOSTEALTH"] },
    { value = "mod",           label = L["BUILDER_LABEL_MOD"],hasArg = true, argType = "mod", desc = L["BUILDER_DESC_MOD"] },
    { value = "nomod",         label = "nomod",          hasArg = false, desc = L["BUILDER_DESC_NOMOD"] },
    { value = "mounted",       label = "mounted",        hasArg = false, desc = L["BUILDER_DESC_MOUNTED"] },
    { value = "nomounted",     label = "nomounted",      hasArg = false, desc = L["BUILDER_DESC_NOMOUNTED"] },
    { value = "flying",        label = "flying",         hasArg = false, desc = L["BUILDER_DESC_FLYING"] },
    { value = "noflying",      label = "noflying",       hasArg = false, desc = L["BUILDER_DESC_NOFLYING"] },
    { value = "swimming",      label = "swimming",       hasArg = false, desc = L["BUILDER_DESC_SWIMMING"] },
    { value = "indoors",       label = "indoors",        hasArg = false, desc = L["BUILDER_DESC_INDOORS"] },
    { value = "outdoors",      label = "outdoors",       hasArg = false, desc = L["BUILDER_DESC_OUTDOORS"] },
    { value = "channeling",    label = "channeling",     hasArg = true, argType = "text", desc = L["BUILDER_DESC_CHANNELING"] },
    { value = "nochanneling",  label = "nochanneling",   hasArg = false, desc = L["BUILDER_DESC_NOCHANNELING"] },
    { value = "known",         label = "known",          hasArg = true, argType = "text", desc = L["BUILDER_DESC_KNOWN"] },
    { value = "noknown",       label = "noknown",        hasArg = true, argType = "text", desc = L["BUILDER_DESC_NOKNOWN"] },
    { value = "spec",          label = "spec",           hasArg = true, argType = "num4", desc = L["BUILDER_DESC_SPEC"] },
    { value = "talent",        label = "talent",         hasArg = true, argType = "numslash", desc = L["BUILDER_DESC_TALENT"] },
    { value = "pvptalent",     label = "pvptalent",      hasArg = true, argType = "numslash", desc = L["BUILDER_DESC_PVPTALENT"] },
    { value = "form",          label = "form/stance",    hasArg = true, argType = "num7", desc = L["BUILDER_DESC_FORM"] },
    { value = "group",         label = "group",          hasArg = true, argType = "group", desc = L["BUILDER_DESC_GROUP"] },
    { value = "pet",           label = L["BUILDER_LABEL_PET"], hasArg = false, desc = L["BUILDER_DESC_PET"] },
    { value = "nopet",         label = "nopet",          hasArg = false, desc = L["BUILDER_DESC_NOPET"] },
    { value = "btn",           label = L["BUILDER_LABEL_BTN"],   hasArg = true, argType = "btn", desc = L["BUILDER_DESC_BTN"] },
    { value = "bar",           label = "bar",            hasArg = true, argType = "num7", desc = L["BUILDER_DESC_BAR"] },
    { value = "bonusbar",      label = "bonusbar",       hasArg = true, argType = "num7", desc = L["BUILDER_DESC_BONUSBAR"] },
    { value = "worn",          label = "worn/equipped",  hasArg = true, argType = "text", desc = L["BUILDER_DESC_WORN"] },
    { value = "advflyable",    label = "advflyable",     hasArg = false, desc = L["BUILDER_DESC_ADVFLYABLE"] },
    { value = "vehicleui",     label = "vehicleui",      hasArg = false, desc = L["BUILDER_DESC_VEHICLEUI"] },
    { value = "canexitvehicle",label = "canexitvehicle", hasArg = false, desc = L["BUILDER_DESC_CANEXITVEHICLE"] },
    { value = "petbattle",     label = "petbattle",      hasArg = false, desc = L["BUILDER_DESC_PETBATTLE"] },
    { value = "cursor",        label = "cursor",         hasArg = false, desc = L["BUILDER_DESC_CURSOR"] },
}

Builder.CONDITIONS = CONDITIONS

local MOD_KEYS = {
    { value = "",      label = L["BUILDER_ANY"] },
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
-- Find condition entry by value
---------------------------------------------------
local function FindCondEntry(val)
    for _, c in ipairs(CONDITIONS) do
        if c.value == val then return c end
    end
    return nil
end

local function LabelOf(tbl, value)
    for _, e in ipairs(tbl) do
        if e.value == value then return e.label end
    end
    return value
end

-- Choices of an argument with a fixed list, or nil when it is typed
local function ArgChoices(argType)
    if argType == "mod" then return MOD_KEYS end
    if argType == "btn" then return BUTTONS end
    if argType == "group" then
        return { { value = "", label = L["BUILDER_ANY"] }, { value = "party", label = "party" }, { value = "raid", label = "raid" } }
    end
    local max = argType == "num4" and 4 or argType == "num7" and 7
    if max then
        local t = {}
        for n = (argType == "num7" and 0 or 1), max do table.insert(t, { value = tostring(n), label = tostring(n) }) end
        return t
    end
end

-- A button opening a radio menu over entries { value, label }
local function ChoiceButton(parent, width, getEntries, getValue, setValue)
    local b = MF.Widgets:Button(parent, "", width)
    b:SetScript("OnClick", function(self)
        MenuUtil.CreateContextMenu(self, function(_, root)
            if root.SetScrollMode then root:SetScrollMode(360) end
            for _, e in ipairs(getEntries()) do
                root:CreateRadio(e.label, function() return getValue() == e.value end,
                    function() setValue(e.value) end)
            end
        end)
    end)
    return b
end

---------------------------------------------------
-- Drawer (editor): target, up to 5 conditions, live preview, Insert
---------------------------------------------------
local SLOTS = 5

local function BuildDrawer(body)
    local W = MF.Widgets
    local rows = {}
    local desc, preview

    local function Update()
        for i, row in ipairs(rows) do
            local entry = FindCondEntry(state["cond" .. i] or "")
            row.cond:SetText(entry and entry.value ~= "" and entry.label or L["BUILDER_NONE"])
            local choices = entry and entry.hasArg and ArgChoices(entry.argType)
            row.argButton:SetShown(choices ~= nil)
            row.argInput:SetShown(entry ~= nil and entry.hasArg and choices == nil)
            if choices then row.argButton:SetText(LabelOf(choices, state["arg" .. i] or "")) end
        end
        body.target:SetText(LabelOf(TARGETS, state.target or ""))
        local cond = BuildCondString()
        local An = MF:GetModule("Analyzer")
        preview:SetText(cond == "" and (MF.C.grey .. L["BUILDER_EMPTY"] .. "|r")
            or (An and An:ColorizeLine("/cast " .. cond .. " " .. L["BUILDER_PREVIEW_SPELL"]) or cond))
    end

    local targetLabel = W:Text(body, "GameFontNormal", L["BUILDER_TARGET_LABEL"])
    targetLabel:SetPoint("TOPLEFT", 4, -2)
    body.target = ChoiceButton(body, 160, function() return TARGETS end,
        function() return state.target or "" end,
        function(v) state.target = v; Update() end)
    body.target:SetPoint("TOPLEFT", targetLabel, "BOTTOMLEFT", 0, -4)

    local condLabel = W:Text(body, "GameFontNormal", L["BUILDER_CONDITIONS_LABEL"])
    condLabel:SetPoint("TOPLEFT", body.target, "BOTTOMLEFT", 0, -12)
    for i = 1, SLOTS do
        local row = {}
        row.cond = ChoiceButton(body, 150, function() return CONDITIONS end,
            function() return state["cond" .. i] or "" end,
            function(v)
                state["cond" .. i], state["arg" .. i] = v, ""
                rows[i].argInput:SetText("")
                local entry = FindCondEntry(v)
                desc:SetText(entry and entry.value ~= "" and (MF.C.grey .. entry.desc .. "|r") or "")
                Update()
            end)
        row.cond:SetPoint("TOPLEFT", i == 1 and condLabel or rows[i - 1].cond, "BOTTOMLEFT", 0, i == 1 and -4 or -4)
        row.argButton = ChoiceButton(body, 100, function()
                local entry = FindCondEntry(state["cond" .. i] or "")
                return entry and ArgChoices(entry.argType) or {}
            end,
            function() return state["arg" .. i] or "" end,
            function(v) state["arg" .. i] = v; Update() end)
        row.argButton:SetPoint("LEFT", row.cond, "RIGHT", 6, 0)
        row.argInput = W:Input(body, 94)
        row.argInput:SetPoint("LEFT", row.cond, "RIGHT", 12, 0)
        row.argInput:SetScript("OnTextChanged", function(box, user)
            if user then state["arg" .. i] = box:GetText(); Update() end
        end)
        rows[i] = row
    end

    desc = W:Text(body, "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", rows[SLOTS].cond, "BOTTOMLEFT", 0, -8)
    desc:SetPoint("RIGHT", body, "RIGHT", -4, 0)
    local pvLabel = W:Text(body, "GameFontNormal", L["BUILDER_PREVIEW"])
    pvLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -12)
    preview = W:Text(body, "GameFontHighlight")
    preview:SetPoint("TOPLEFT", pvLabel, "BOTTOMLEFT", 0, -6)
    preview:SetPoint("RIGHT", body, "RIGHT", -4, 0)

    local insert = W:Button(body, L["BUILDER_INSERT"], 150, function()
        local cond = BuildCondString()
        if cond == "" then return end
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
        local E = MF:GetModule("Editor")
        E:InsertText(cond .. " ")
        E:FocusBody()
    end)
    insert:SetPoint("BOTTOMLEFT", 2, 2)
    local reset = W:Button(body, L["RESET"], 90, function()
        wipe(state)
        for _, row in ipairs(rows) do row.argInput:SetText("") end
        desc:SetText("")
        Update()
    end)
    reset:SetPoint("LEFT", insert, "RIGHT", 6, 0)
    body.Update = Update
end

---------------------------------------------------
-- API
---------------------------------------------------
local registered
function Builder:Toggle()
    local E = MF:GetModule("Editor")
    if not registered then
        registered = true
        E:RegisterDrawer("builder", {
            title = L["BUILDER_TITLE"],
            build = BuildDrawer,
            onShow = function(body) body.Update() end,
        })
    end
    E:ToggleDrawer("builder")
end
Builder.Open = Builder.Toggle

MF:RegisterModule("Builder", Builder)
