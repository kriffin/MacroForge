---------------------------------------------------
-- MacroForge — Autocomplete
-- Context-aware autocomplete for macro editing
-- Suggests: /commands, [conditions], spell names
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local AC = {}

local MAX_SUGGESTIONS = 8
local MIN_QUERY_LEN = 2

local popup        -- the floating suggestion frame
local suggestions  -- current suggestion list
local selectedIdx  -- currently highlighted index
local activeEB     -- the EditBox we're attached to
local hookInstalled = false

---------------------------------------------------
-- Spellbook cache (delegated to Helpers)
---------------------------------------------------
local function BuildSpellbookCache()
    return MF.Helpers:GetSpellbookSpells()
end

-- Invalidate spellbook cache on spec change (new spells)
local function InvalidateCache()
    MF.Helpers:InvalidateSpellbookCache()
end

---------------------------------------------------
-- Conditions list
---------------------------------------------------
local CONDITION_LIST = {
    "actionbar", "advflyable", "bar", "bonusbar", "btn", "button",
    "canexitvehicle", "channeling", "combat", "cursor",
    "dead", "equipped", "exists", "extrabar",
    "flyable", "flying", "form",
    "group", "harm", "help",
    "indoors", "known",
    "mod", "modifier", "mounted",
    "nochanneling", "nocombat", "nodead", "noflying", "nogroup",
    "noknown", "nomounted", "nomod", "nostealth", "noswimming",
    "outdoors", "overridebar",
    "party", "pet", "petbattle", "possessbar", "pvptalent",
    "raid", "spec", "stance", "stealth", "swimming",
    "talent", "unithasvehicleui", "vehicleui", "worn",
}

-- Target completions
local TARGET_LIST = {
    "@player", "@target", "@targettarget",
    "@focus", "@focustarget",
    "@mouseover", "@pet",
    "@arena1", "@arena2", "@arena3",
    "@party1", "@party2", "@party3", "@party4",
    "@cursor", "@none",
}

---------------------------------------------------
-- Create/show the popup frame
---------------------------------------------------
local function CreatePopup()
    if popup then return end

    popup = CreateFrame("Frame", "MacroForgeACPopup", UIParent, "BackdropTemplate")
    popup:SetSize(280, 24)
    popup:SetFrameStrata("TOOLTIP")
    popup:SetFrameLevel(100)
    popup:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    popup:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
    popup:SetBackdropBorderColor(0, 0.5, 0.8, 0.6)
    popup:Hide()

    popup.rows = {}
    for i = 1, MAX_SUGGESTIONS do
        local row = CreateFrame("Button", nil, popup)
        row:SetHeight(22)
        row:SetPoint("TOPLEFT", popup, "TOPLEFT", 3, -(3 + (i - 1) * 22))
        row:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -3, -(3 + (i - 1) * 22))
        row:EnableMouse(true)

        -- Background highlight
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(0.2, 0.5, 0.8, 0)

        -- Icon
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(16, 16)
        row.icon:SetPoint("LEFT", 4, 0)

        -- Text
        row.text = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
        row.text:SetPoint("RIGHT", -4, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetTextColor(0.9, 0.9, 0.9)

        row:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(0.2, 0.5, 0.8, 0.3)
        end)
        row:SetScript("OnLeave", function(self)
            if selectedIdx ~= i then
                self.bg:SetColorTexture(0.2, 0.5, 0.8, 0)
            end
        end)
        row:SetScript("OnClick", function()
            AC:AcceptSuggestion(i)
        end)

        popup.rows[i] = row
    end
end

local function ShowPopup(editBox, items)
    CreatePopup()
    suggestions = items
    selectedIdx = 0

    local count = math.min(#items, MAX_SUGGESTIONS)
    if count == 0 then popup:Hide(); return end

    -- Position below the caret
    popup:ClearAllPoints()
    popup:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, 0)
    popup:SetSize(280, 6 + count * 22)

    for i = 1, MAX_SUGGESTIONS do
        local row = popup.rows[i]
        if i <= count then
            local item = items[i]
            row.text:SetText(item.display or item.text)
            if item.icon then
                row.icon:SetTexture(item.icon)
                row.icon:Show()
            else
                row.icon:Hide()
            end
            row.bg:SetColorTexture(0.2, 0.5, 0.8, 0)
            row:Show()
        else
            row:Hide()
        end
    end

    popup:Show()
end

local function HidePopup()
    if popup then popup:Hide() end
    suggestions = nil
    selectedIdx = 0
end

---------------------------------------------------
-- Query context detection
---------------------------------------------------
local function GetCursorContext(editBox)
    local text = editBox:GetText() or ""
    local pos = editBox:GetCursorPosition() or #text

    -- Get text up to cursor
    local before = text:sub(1, pos)
    -- Get the current line
    local lines = {}
    for line in (before .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(lines, line)
    end
    local currentLine = lines[#lines] or ""

    -- Context: inside [conditions]?
    local lastOpen = currentLine:match(".*()%[")
    local lastClose = currentLine:match(".*()%]")
    if lastOpen and (not lastClose or lastClose < lastOpen) then
        -- Inside a condition block
        local condContent = currentLine:sub(lastOpen + 1)
        -- Get the last token being typed (after , or : or @)
        local token = condContent:match(",?%s*([%a@]*)$") or ""
        return "condition", token
    end

    -- Context: starting a command on this line?
    local cmdPartial = currentLine:match("^(/[%a]*)$")
    if cmdPartial then
        return "command", cmdPartial
    end

    -- Context: after a /cast or /use command, look for spell name
    local cmd = currentLine:match("^(/[%a]+)")
    if cmd then
        local An = MF:GetModule("Analyzer")
        if An and (An:IsCastCmd(cmd) or An:IsSeqCmd(cmd)) then
            -- Find the last spell token (after ] or ; or ,)
            local rest = currentLine:sub(#cmd + 1)
            -- Strip reset= if castsequence
            rest = rest:gsub("reset=[%w/]*%s*", "")
            -- Find what user is currently typing (after last separator)
            local token = rest:match("[%;,]%s*([%a][%a%s%'%-]*)$")
                or rest:match("%]%s*([%a][%a%s%'%-]*)$")
                or rest:match("^%s+([%a][%a%s%'%-]*)$")
            if token and #token >= MIN_QUERY_LEN then
                return "spell", token
            end
        end
    end

    return nil, ""
end

---------------------------------------------------
-- Build suggestions
---------------------------------------------------
local function BuildCommandSuggestions(partial)
    local items = {}
    local An = MF:GetModule("Analyzer")
    if An then An:BuildCommandList() end

    local SDB = MF:GetModule("SlashDB")
    local q = partial:lower()

    if SDB and MF.SlashDB and MF.SlashDB.DB then
        for cmdKey, cat in pairs(MF.SlashDB.DB) do
            if cmdKey:find(q, 1, true) then
                table.insert(items, {
                    text = cmdKey .. " ",
                    display = (cat.color or MF.C.cyan) .. cmdKey .. "|r  " .. MF.C.grey .. (cat.label or "") .. "|r",
                })
            end
        end
    end

    table.sort(items, function(a, b) return a.text < b.text end)
    return items
end

local function BuildConditionSuggestions(partial)
    local items = {}
    local q = partial:lower()

    -- Check for @ target
    if q:sub(1, 1) == "@" then
        local tpart = q:sub(2)
        for _, t in ipairs(TARGET_LIST) do
            if t:lower():find("@" .. tpart, 1, true) then
                table.insert(items, {
                    text = t,
                    display = MF.C.cyan .. t .. "|r",
                })
            end
        end
        return items
    end

    -- Strip leading "no" for matching but include both
    for _, cond in ipairs(CONDITION_LIST) do
        if cond:find(q, 1, true) then
            table.insert(items, {
                text = cond,
                display = MF.C.yellow .. cond .. "|r",
            })
        end
    end

    return items
end

local function BuildSpellSuggestions(partial)
    local items = {}
    local spells = BuildSpellbookCache()
    local q = partial:lower()

    for _, sp in ipairs(spells) do
        if sp.name:lower():find(q, 1, true) then
            table.insert(items, {
                text = sp.name,
                display = MF.C.green .. sp.name .. "|r",
                icon = sp.icon,
            })
            if #items >= MAX_SUGGESTIONS then break end
        end
    end

    return items
end

---------------------------------------------------
-- Accept a suggestion
---------------------------------------------------
function AC:AcceptSuggestion(idx)
    if not suggestions or not suggestions[idx] or not activeEB then return end
    local item = suggestions[idx]
    local text = activeEB:GetText() or ""
    local pos = activeEB:GetCursorPosition() or #text
    local before = text:sub(1, pos)

    -- Determine what to replace
    local context, token = GetCursorContext(activeEB)
    if not context or not token then HidePopup(); return end

    local tokenStart = pos - #token
    local newBefore = before:sub(1, tokenStart) .. item.text
    local after = text:sub(pos + 1)

    activeEB:SetText(newBefore .. after)
    activeEB:SetCursorPosition(#newBefore)

    HidePopup()

    -- Trigger Editor onChange
    local E = MF:GetModule("Editor")
    if E and E.OnChanged then E:OnChanged() end
end

---------------------------------------------------
-- Navigate suggestions
---------------------------------------------------
function AC:NavigateUp()
    if not popup or not popup:IsShown() or not suggestions then return false end
    selectedIdx = math.max(0, (selectedIdx or 0) - 1)
    AC:HighlightRow(selectedIdx)
    return true
end

function AC:NavigateDown()
    if not popup or not popup:IsShown() or not suggestions then return false end
    local max = math.min(#suggestions, MAX_SUGGESTIONS)
    selectedIdx = math.min(max, (selectedIdx or 0) + 1)
    AC:HighlightRow(selectedIdx)
    return true
end

function AC:AcceptSelected()
    if not popup or not popup:IsShown() or not suggestions then return false end
    if selectedIdx and selectedIdx > 0 then
        AC:AcceptSuggestion(selectedIdx)
        return true
    end
    return false
end

function AC:HighlightRow(idx)
    if not popup then return end
    for i, row in ipairs(popup.rows) do
        if i == idx then
            row.bg:SetColorTexture(0.2, 0.5, 0.8, 0.4)
        else
            row.bg:SetColorTexture(0.2, 0.5, 0.8, 0)
        end
    end
end

function AC:IsShown()
    return popup and popup:IsShown()
end

---------------------------------------------------
-- Main update: called on text change in EditBox
---------------------------------------------------
function AC:Update(editBox)
    activeEB = editBox
    local context, token = GetCursorContext(editBox)

    if not context or not token or #token < MIN_QUERY_LEN then
        -- Exception: / always triggers command complete
        if context == "command" and token and #token >= 1 then
            -- ok, continue
        else
            HidePopup()
            return
        end
    end

    local items = {}
    if context == "command" then
        items = BuildCommandSuggestions(token)
    elseif context == "condition" then
        items = BuildConditionSuggestions(token)
    elseif context == "spell" then
        items = BuildSpellSuggestions(token)
    end

    if #items > 0 then
        ShowPopup(editBox, items)
    else
        HidePopup()
    end
end

---------------------------------------------------
-- Hook into Editor's EditBox
---------------------------------------------------
function AC:HookEditBox(editBox)
    if not editBox or hookInstalled then return end
    hookInstalled = true
    activeEB = editBox

    -- OnTextChanged — update suggestions
    editBox:HookScript("OnTextChanged", function(self)
        AC:Update(self)
    end)

    -- OnKeyDown — navigate suggestions
    editBox:HookScript("OnKeyDown", function(self, key)
        if AC:IsShown() then
            if key == "UP" then
                if AC:NavigateUp() then
                    self:SetPropagateKeyboardInput(false)
                    return
                end
            elseif key == "DOWN" then
                if AC:NavigateDown() then
                    self:SetPropagateKeyboardInput(false)
                    return
                end
            elseif key == "TAB" or key == "ENTER" then
                if AC:AcceptSelected() then
                    self:SetPropagateKeyboardInput(false)
                    return
                end
            elseif key == "ESCAPE" then
                HidePopup()
                self:SetPropagateKeyboardInput(false)
                return
            end
        end
        self:SetPropagateKeyboardInput(true)
    end)

    -- Close popup when EditBox loses focus
    editBox:HookScript("OnEditFocusLost", function()
        C_Timer.After(0.1, function() HidePopup() end)
    end)
end

function AC:Hide()
    HidePopup()
end

---------------------------------------------------
-- Initialize
---------------------------------------------------
function AC:OnInitialize()
    -- Invalidate spell cache on spec change
    MF:RegisterMessage("MF_SPEC_CHANGED", function() InvalidateCache() end)
end

MF:RegisterModule("Autocomplete", AC)
