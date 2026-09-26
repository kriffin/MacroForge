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
    { value = "",             label = L["BUILDER_TARGET_DEFAULT"] },
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

-- WoW Forever has no PvP talents, dragonriding, pet battles or vehicles:
-- those conditions are left out of the builder there (checked in game)
if select(4, GetBuildInfo()) < 20000 then
    local HIDDEN = { pvptalent = true, advflyable = true, petbattle = true, vehicleui = true, canexitvehicle = true }
    for i = #CONDITIONS, 1, -1 do
        if HIDDEN[CONDITIONS[i].value] then table.remove(CONDITIONS, i) end
    end
end

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
-- Build the condition string from state: state.target, and state.conds, a
-- list of { value, arg } with no holes
---------------------------------------------------
local SLOTS = 5

local function BuildCondString()
    local parts = {}
    if state.target and state.target ~= "" then
        table.insert(parts, "@" .. state.target)
    end
    for _, c in ipairs(state.conds or {}) do
        table.insert(parts, (c.arg and c.arg ~= "") and (c.value .. ":" .. c.arg) or c.value)
    end
    if #parts == 0 then return "" end
    return "[" .. table.concat(parts, ",") .. "]"
end
Builder.BuildCondString = BuildCondString
Builder.state = state

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

-- A tooltip line for a menu entry that has a description
local function EntryTooltip(desc, title)
    return function(tooltip)
        GameTooltip_SetTitle(tooltip, title)
        GameTooltip_AddNormalLine(tooltip, desc)
    end
end

-- Opens a radio menu over entries { value, label, desc? } at owner
local function ChoiceMenu(owner, entries, getValue, setValue)
    MenuUtil.CreateContextMenu(owner, function(_, root)
        if root.SetScrollMode then root:SetScrollMode(360) end
        for _, e in ipairs(entries) do
            local r = root:CreateRadio(e.label, function() return getValue() == e.value end,
                function() setValue(e.value) end)
            if e.desc and r.SetTooltip then r:SetTooltip(EntryTooltip(e.desc, e.label)) end
        end
    end)
end

-- A button opening a radio menu over entries { value, label }
local function ChoiceButton(parent, width, getEntries, getValue, setValue)
    local b = MF.Widgets:Button(parent, "", width)
    b:SetScript("OnClick", function(self) ChoiceMenu(self, getEntries(), getValue, setValue) end)
    return b
end

-- The conditions offered in the menus (the "none" entry only exists for
-- the debug dump: a condition is taken off with its row's X)
local PICKABLE = {}
for _, c in ipairs(CONDITIONS) do
    if c.value ~= "" then table.insert(PICKABLE, c) end
end

---------------------------------------------------
-- Drawer (editor), three numbered steps read top to bottom:
--   1. who the spell goes on, 2. the conditions that must all be true
--   (one row each, added on demand), 3. the result and Insert
---------------------------------------------------
local function BuildDrawer(body)
    local W = MF.Widgets
    local rows = {}
    local preview, example, insert, hint
    state.conds = state.conds or {}

    local function Update()
        local conds = state.conds
        for i, row in ipairs(rows) do
            local c = conds[i]
            row:SetShown(c ~= nil)
            if c then
                local entry = FindCondEntry(c.value)
                row.cond:SetText(entry and entry.label or c.value)
                local choices = entry and entry.hasArg and ArgChoices(entry.argType) or nil
                row.argButton:SetShown(choices ~= nil)
                row.argInput:SetShown(entry ~= nil and entry.hasArg and choices == nil)
                if choices then row.argButton:SetText(LabelOf(choices, c.arg or "")) end
                if row.argInput:IsShown() and row.argInput:GetText() ~= (c.arg or "") then
                    row.argInput:SetText(c.arg or "")
                end
            end
        end
        -- The Add button sits under the last used row
        body.add:ClearAllPoints()
        body.add:SetPoint("TOPLEFT", #conds == 0 and body.whenLabel or rows[#conds], "BOTTOMLEFT", 0, -6)
        body.add:SetShown(#conds < SLOTS)
        hint:SetShown(#conds == 0)
        body.target:SetText(LabelOf(TARGETS, state.target or ""))

        local cond = BuildCondString()
        local An = MF:GetModule("Analyzer")
        preview:SetText(cond == "" and (MF.C.grey .. L["BUILDER_EMPTY"] .. "|r") or (MF.C.yellow .. cond .. "|r"))
        example:SetText(cond == "" and ""
            or (MF.C.grey .. L["BUILDER_EXAMPLE"] .. "|r  "
                .. (An and An:ColorizeLine("/cast " .. cond .. " " .. L["BUILDER_PREVIEW_SPELL"]) or cond)))
        insert:SetEnabled(cond ~= "")
    end

    local intro = W:Text(body, "GameFontHighlightSmall", MF.C.grey .. L["BUILDER_INTRO"] .. "|r")
    intro:SetPoint("TOPLEFT", 4, -2)
    intro:SetPoint("RIGHT", body, "RIGHT", -4, 0)

    -- 1. Target
    local targetLabel = W:Text(body, "GameFontNormal", L["BUILDER_STEP_TARGET"])
    targetLabel:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -12)
    body.target = ChoiceButton(body, 200, function() return TARGETS end,
        function() return state.target or "" end,
        function(v) state.target = v; Update() end)
    body.target:SetPoint("TOPLEFT", targetLabel, "BOTTOMLEFT", 0, -4)

    -- 2. Conditions, one row per condition picked
    body.whenLabel = W:Text(body, "GameFontNormal", L["BUILDER_STEP_WHEN"])
    body.whenLabel:SetPoint("TOPLEFT", body.target, "BOTTOMLEFT", 0, -14)
    hint = W:Text(body, "GameFontHighlightSmall", MF.C.grey .. L["BUILDER_WHEN_HINT"] .. "|r")

    for i = 1, SLOTS do
        local row = CreateFrame("Frame", nil, body)
        row:SetSize(1, 22)
        row:SetPoint("TOPLEFT", i == 1 and body.whenLabel or rows[i - 1], "BOTTOMLEFT", 0, -4)
        row:SetPoint("RIGHT", body, "RIGHT", -4, 0)

        row.remove = CreateFrame("Button", nil, row)
        row.remove:SetSize(20, 20)
        row.remove:SetPoint("RIGHT", 0, 0)
        row.remove:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        row.remove:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
        row.remove:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        row.remove:SetScript("OnClick", function()
            table.remove(state.conds, i)
            Update()
        end)
        row.remove:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(L["BUILDER_REMOVE"], 1, 1, 1)
            GameTooltip:Show()
        end)
        row.remove:SetScript("OnLeave", GameTooltip_Hide)

        row.cond = ChoiceButton(row, 130, function() return PICKABLE end,
            function() return state.conds[i] and state.conds[i].value end,
            function(v) state.conds[i] = { value = v, arg = "" }; Update() end)
        row.cond:SetPoint("LEFT", 0, 0)
        -- The condition's meaning, on hover
        row.cond:SetScript("OnEnter", function(self)
            local entry = state.conds[i] and FindCondEntry(state.conds[i].value)
            if not entry then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(entry.label)
            GameTooltip:AddLine(entry.desc, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        row.cond:SetScript("OnLeave", GameTooltip_Hide)

        row.argButton = ChoiceButton(row, 84, function()
                local entry = state.conds[i] and FindCondEntry(state.conds[i].value)
                return entry and ArgChoices(entry.argType) or {}
            end,
            function() return state.conds[i] and state.conds[i].arg or "" end,
            function(v) if state.conds[i] then state.conds[i].arg = v end; Update() end)
        row.argButton:SetPoint("LEFT", row.cond, "RIGHT", 4, 0)
        row.argInput = W:Input(row, 78)
        row.argInput:SetPoint("LEFT", row.cond, "RIGHT", 10, 0)
        row.argInput:SetScript("OnTextChanged", function(box, user)
            if user and state.conds[i] then state.conds[i].arg = box:GetText(); Update() end
        end)
        row:Hide()
        rows[i] = row
    end

    -- Add: picks the condition straight away, the row appears filled
    body.add = W:Button(body, L["BUILDER_ADD"], 200, function(self)
        ChoiceMenu(self, PICKABLE, function() return nil end, function(v)
            if #state.conds < SLOTS then table.insert(state.conds, { value = v, arg = "" }) end
            Update()
        end)
    end)
    hint:SetPoint("TOPLEFT", body.add, "BOTTOMLEFT", 2, -4)
    hint:SetPoint("RIGHT", body, "RIGHT", -4, 0)

    -- 3. Result, pinned above the buttons so it never moves
    insert = W:Button(body, L["BUILDER_INSERT"], 150, function()
        local cond = BuildCondString()
        if cond == "" then return end
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
        local E = MF:GetModule("Editor")
        E:InsertCondition(cond)
        E:FocusBody()
    end)
    insert:SetPoint("BOTTOMLEFT", 2, 2)
    local reset = W:Button(body, L["RESET"], 90, function()
        wipe(state)
        state.conds = {}
        Update()
    end)
    reset:SetPoint("LEFT", insert, "RIGHT", 6, 0)

    example = W:Text(body, "GameFontHighlightSmall")
    example:SetPoint("BOTTOMLEFT", insert, "TOPLEFT", 2, 10)
    example:SetPoint("RIGHT", body, "RIGHT", -4, 0)
    preview = W:Text(body, "GameFontHighlightLarge")
    preview:SetPoint("BOTTOMLEFT", example, "TOPLEFT", 0, 6)
    preview:SetPoint("RIGHT", body, "RIGHT", -4, 0)
    local pvLabel = W:Text(body, "GameFontNormal", L["BUILDER_STEP_RESULT"])
    pvLabel:SetPoint("BOTTOMLEFT", preview, "TOPLEFT", 0, 6)

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
