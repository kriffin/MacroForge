---------------------------------------------------
-- MacroForge — UI
-- Main window: macro list (sidebar) + editor (right pane) in one frame.
--
-- Built on Blizzard templates, like the modern default UI:
--   PortraitFrameFlatTemplate  window chrome, title, close button
--   PanelResizeButtonTemplate  resize grip
--   InsetFrameTemplate         sidebar well
--   SearchBoxTemplate          macro search (name + body)
--   WowScrollBoxList + MinimalScrollBar + tree view   grouped macro list
-- The editor (Editor.lua, AceGUI widgets) is hosted in GetEditorPane().
---------------------------------------------------
local _, MF_NS = ...
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local UI = {}

local FRAME_NAME = "MacroForgeMainFrame"
local DEFAULT_WIDTH, DEFAULT_HEIGHT = 980, 640
local MIN_WIDTH, MIN_HEIGHT = 860, 520
local SIDEBAR_WIDTH = 270
local ROW_HEIGHT, HEADER_HEIGHT = 30, 26
local SCOPES = { "character", "account" }

local frame, scrollBox, searchBox, editorPane, emptyState
local searchQuery = ""
local visibleMacros = {}  -- list order of the macros currently shown (keyboard navigation)
local collapsed = {}

---------------------------------------------------
-- Context menu (right-click) — WoW 11.0+ API
---------------------------------------------------
local function ShowContextMenu(macro)
    MenuUtil.CreateContextMenu(UIParent, function(_, rootDescription)
        rootDescription:CreateTitle(macro.name or L["MACRO_FALLBACK_NAME"])

        rootDescription:CreateButton("|cff00ccff" .. L["EDIT"] .. "|r", function()
            local E = MF:GetModule("Editor")
            if E then E:Open(macro) end
        end)

        rootDescription:CreateButton("|cff00ff88" .. L["DUPLICATE"] .. "|r", function()
            local P = MF:GetModule("Profiles")
            if P then
                local newName = (macro.name or "Macro"):sub(1, 11) .. " (cp)"
                local perChar = macro.scope == "character"
                P:CreateNewMacro(newName, macro.icon or 134400, macro.body or "", perChar)
                C_Timer.After(0.3, function() UI:Refresh() end)
            end
        end)

        rootDescription:CreateButton("|cffffff33" .. L["EXPORT"] .. "|r", function()
            local E = MF:GetModule("Editor")
            if E then
                E:Open(macro, nil, function() E:OpenExport() end)
            end
        end)

        local other = macro.scope == "character" and "account" or "character"
        rootDescription:CreateButton(other == "account" and L["MOVE_TO_ACCOUNT"] or L["MOVE_TO_CHARACTER"], function()
            UI:ConfirmMove(macro, other)
        end)

        rootDescription:CreateButton("|cffff9933" .. L["DRAG_ACTIONBAR"] .. "|r", function()
            MF.Helpers:PickupMacro(macro.index)
        end)

        local H = MF:GetModule("History")
        if H then
            rootDescription:CreateButton(L["HISTORY_BTN"], function() H:OpenBrowser(macro) end)
        end

        rootDescription:CreateButton("|cffff4444" .. L["DELETE"] .. "|r", function()
            UI:ConfirmDelete(macro)
        end)
    end)
end

StaticPopupDialogs["MACROFORGE_DELETE_CONFIRM"] = {
    text = L["DELETE_CONFIRM"],
    button1 = L["DELETE_YES"],
    button2 = L["DELETE_NO"],
    OnAccept = function(_, macro)
        local P = MF:GetModule("Profiles")
        if P and P:DeleteMacroByIndex(macro.index) then
            local E = MF:GetModule("Editor")
            if E and E:IsEditing(macro) then UI:ShowEmpty() end
        end
        C_Timer.After(0.2, function() UI:Refresh() end)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["MACROFORGE_MOVE_CONFIRM"] = {
    text = L["MOVE_CONFIRM"],
    button1 = YES,
    button2 = NO,
    OnAccept = function(_, data)
        local P, E = MF:GetModule("Profiles"), MF:GetModule("Editor")
        local wasOpen = E and E:IsEditing(data.macro)
        if P:MoveMacro(data.macro, data.toScope) and wasOpen then
            -- Follow the macro to its new slot
            C_Timer.After(0.3, function()
                for _, m in ipairs(P:ReadMacros(data.toScope)) do
                    if m.name == data.macro.name and m.body == data.macro.body then return E:Open(m, true) end
                end
            end)
        end
        C_Timer.After(0.2, function() UI:Refresh() end)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function UI:ConfirmMove(macro, toScope)
    StaticPopup_Show("MACROFORGE_MOVE_CONFIRM", macro.name or "?",
        toScope == "character" and L["SIDEBAR_CHARACTER"] or L["SIDEBAR_ACCOUNT"],
        { macro = macro, toScope = toScope })
end

-- Macro currently on the cursor (dragged from the list or Blizzard's frame)
local function CursorMacro()
    local cursorType, index = GetCursorInfo()
    if cursorType ~= "macro" or not index then return nil end
    local P = MF:GetModule("Profiles")
    local scope = index > P.MAX_ACCOUNT_MACROS and "character" or "account"
    for _, m in ipairs(P:ReadMacros(scope)) do
        if m.index == index then return m end
    end
end

function UI:ConfirmDelete(macro)
    StaticPopup_Show("MACROFORGE_DELETE_CONFIRM", macro.name or "?", nil, macro)
end

---------------------------------------------------
-- Data
---------------------------------------------------
local function MatchesSearch(macro)
    if searchQuery == "" then return true end
    local q = searchQuery:lower()
    return (macro.name and macro.name:lower():find(q, 1, true))
        or (macro.body and macro.body:lower():find(q, 1, true))
end

local function DisplayName(macro)
    local dn = macro.name and macro.name:match("^%s*(.-)%s*$") or ""
    if dn == "" then dn = MF.Helpers:ParseShowTooltip(macro.body) or L["MACRO_UNNAMED"] end
    return dn:match("^([^\n]+)") or dn
end

local function BuildDataProvider()
    local P = MF:GetModule("Profiles")
    local An = MF:GetModule("Analyzer")
    local numAccount, numCharacter = GetNumMacros()
    local limits = {
        character = { count = numCharacter, max = P.MAX_CHARACTER_MACROS },
        account = { count = numAccount, max = P.MAX_ACCOUNT_MACROS },
    }

    local dataProvider = CreateTreeDataProvider()
    wipe(visibleMacros)
    for _, scope in ipairs(SCOPES) do
        local header = dataProvider:Insert({
            header = scope, count = limits[scope].count, max = limits[scope].max,
        })
        local shown = 0
        for _, macro in ipairs(P:ReadMacros(scope)) do
            if MatchesSearch(macro) then
                local res = An and An:Analyze(macro.body, macro.name)
                header:Insert({ macro = macro, analysis = res })
                shown = shown + 1
            end
        end
        header:GetData().shown = shown
        -- A search always expands the groups so matches are visible
        local isCollapsed = searchQuery == "" and collapsed[scope] or false
        header:SetCollapsed(isCollapsed, false, true)
        if not isCollapsed then
            for _, child in ipairs(header:GetNodes()) do
                table.insert(visibleMacros, child:GetData().macro)
            end
        end
    end
    return dataProvider
end

---------------------------------------------------
-- Row rendering (one pooled Button type for headers and macros)
---------------------------------------------------
local function EnsureRowRegions(btn)
    if btn.mfIcon then return end
    btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

    btn.mfSelected = btn:CreateTexture(nil, "BACKGROUND")
    btn.mfSelected:SetAllPoints()
    btn.mfSelected:SetColorTexture(0.2, 0.6, 1, 0.18)

    btn.mfIcon = btn:CreateTexture(nil, "ARTWORK")
    btn.mfIcon:SetSize(24, 24)
    btn.mfIcon:SetPoint("LEFT", 6, 0)

    btn.mfName = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    btn.mfName:SetJustifyH("LEFT")
    btn.mfName:SetWordWrap(false)

    btn.mfSub = btn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    btn.mfSub:SetJustifyH("LEFT")
    btn.mfSub:SetWordWrap(false)

    btn.mfBadge = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.mfBadge:SetPoint("RIGHT", -6, 0)

    btn.mfArrow = btn:CreateTexture(nil, "ARTWORK")
    btn.mfArrow:SetSize(14, 14)
    btn.mfArrow:SetPoint("LEFT", 4, 0)

    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
end

local function MacroTooltip(owner, data)
    local macro, res = data.macro, data.analysis
    local An = MF:GetModule("Analyzer")
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:AddLine(DisplayName(macro), 0, 0.8, 1)
    if res then GameTooltip:AddLine(format(L["QUALITY"], res.score or 100), 1, 0.84, 0) end
    if macro.body and macro.body ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(macro.body, 0.75, 0.75, 0.75, true)
    end
    if res and res.issues and #res.issues > 0 then
        GameTooltip:AddLine(" ")
        for _, iss in ipairs(res.issues) do
            GameTooltip:AddLine(An:FmtSev(iss.severity) .. " " .. iss.message, 1, 1, 1, true)
        end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["CLICK_EDIT"] .. "  " .. L["CLICK_DRAG"] .. "  " .. L["CLICK_RIGHT_MENU"], 1, 1, 1, true)
    GameTooltip:Show()
end

local function InitHeader(btn, node)
    local data = node:GetData()
    btn.mfIcon:Hide(); btn.mfSub:Hide(); btn.mfSelected:Hide()
    btn.mfArrow:Show()
    btn.mfArrow:SetTexture(node:IsCollapsed()
        and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")

    btn.mfName:SetFontObject("GameFontNormal")
    btn.mfName:ClearAllPoints()
    btn.mfName:SetPoint("LEFT", btn.mfArrow, "RIGHT", 6, 0)
    btn.mfName:SetPoint("RIGHT", btn.mfBadge, "LEFT", -6, 0)
    btn.mfName:SetText(data.header == "character" and L["SIDEBAR_CHARACTER"] or L["SIDEBAR_ACCOUNT"])

    local full = data.count >= data.max
    btn.mfBadge:SetText((full and MF.C.red or MF.C.grey) .. data.count .. "/" .. data.max .. "|r")

    -- Dropping a macro from the other group on this header moves it here
    local function DropMacro()
        local m = CursorMacro()
        if m and m.scope ~= data.header then
            ClearCursor()
            UI:ConfirmMove(m, data.header)
            return true
        end
    end
    btn:SetScript("OnReceiveDrag", DropMacro)
    btn:SetScript("OnClick", function()
        if DropMacro() then return end
        node:ToggleCollapsed()
        if searchQuery == "" then collapsed[data.header] = node:IsCollapsed() end
        btn.mfArrow:SetTexture(node:IsCollapsed()
            and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
    end)
    btn:SetScript("OnDragStart", nil)
    btn:SetScript("OnEnter", nil)
    btn:SetScript("OnLeave", nil)
end

local function InitMacroRow(btn, node)
    local data = node:GetData()
    local macro, res = data.macro, data.analysis
    btn.mfArrow:Hide()
    btn.mfIcon:Show(); btn.mfSub:Show()

    local icon = macro.displayIcon or macro.icon
    btn.mfIcon:SetTexture((icon and icon ~= 0) and icon or 134400)

    btn.mfName:SetFontObject("GameFontHighlight")
    btn.mfName:ClearAllPoints()
    btn.mfName:SetPoint("TOPLEFT", btn.mfIcon, "TOPRIGHT", 8, 1)
    btn.mfName:SetPoint("RIGHT", btn.mfBadge, "LEFT", -6, 0)
    local E = MF:GetModule("Editor")
    local editing = E and E:IsEditing(macro)
    btn.mfName:SetText(((editing and E:IsDirty()) and (E.DIRTY_MARK .. " ") or "") .. DisplayName(macro))

    btn.mfSub:ClearAllPoints()
    btn.mfSub:SetPoint("BOTTOMLEFT", btn.mfIcon, "BOTTOMRIGHT", 8, -1)
    btn.mfSub:SetPoint("RIGHT", btn.mfBadge, "LEFT", -6, 0)
    btn.mfSub:SetText(MF.Helpers:CondenseBody(macro.body))

    local score = res and res.score or 100
    btn.mfBadge:SetText(score < 100 and (MF.C.red .. score .. "%|r") or "")

    btn.mfSelected:SetShown(editing and true or false)

    btn:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            ShowContextMenu(macro)
        elseif IsShiftKeyDown() then
            MF.Helpers:PickupMacro(macro.index)
        else
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
            if E then E:Open(macro) end
        end
    end)
    btn:SetScript("OnDragStart", function() MF.Helpers:PickupMacro(macro.index) end)
    btn:SetScript("OnEnter", function(self) MacroTooltip(self, data) end)
    btn:SetScript("OnLeave", GameTooltip_Hide)
end

local function InitElement(btn, node)
    EnsureRowRegions(btn)
    if node:GetData().header then InitHeader(btn, node) else InitMacroRow(btn, node) end
end

---------------------------------------------------
-- Window position / size (MF.db.global.window)
---------------------------------------------------
local function SaveGeometry()
    if not MF.db then return end
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    MF.db.global.window = {
        point = point, relativePoint = relativePoint, x = x, y = y,
        width = frame:GetWidth(), height = frame:GetHeight(),
    }
end

local function RestoreGeometry()
    local g = MF.db and MF.db.global.window
    frame:ClearAllPoints()
    if g and g.point then
        frame:SetPoint(g.point, UIParent, g.relativePoint or g.point, g.x or 0, g.y or 0)
        frame:SetSize(math.max(g.width or DEFAULT_WIDTH, MIN_WIDTH), math.max(g.height or DEFAULT_HEIGHT, MIN_HEIGHT))
    else
        frame:SetPoint("CENTER")
        frame:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT)
    end
end

---------------------------------------------------
-- Build
---------------------------------------------------
local function CreateSidebar()
    searchBox = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    searchBox:SetHeight(20)
    searchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 68, -32)
    searchBox:SetWidth(SIDEBAR_WIDTH - 60)
    searchBox:HookScript("OnTextChanged", function(self)
        searchQuery = (self:GetText() or ""):match("^%s*(.-)%s*$")
        UI:Refresh()
    end)
    searchBox:HookScript("OnKeyDown", function(self, key)
        if IsControlKeyDown() then UI:HandleKey(key) end
    end)
    -- Up/Down from the search box walk the results, Enter opens the first one
    searchBox:HookScript("OnArrowPressed", function(self, key)
        if key == "UP" then UI:SelectRelative(-1) elseif key == "DOWN" then UI:SelectRelative(1) end
    end)
    searchBox:HookScript("OnEnterPressed", function(self)
        self:ClearFocus()
        local E = MF:GetModule("Editor")
        if visibleMacros[1] and E and not E.cur then E:Open(visibleMacros[1]) end
    end)

    local inset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
    inset:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -62)
    inset:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 36)
    inset:SetWidth(SIDEBAR_WIDTH)

    scrollBox = CreateFrame("Frame", nil, inset, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", 4, -4)
    scrollBox:SetPoint("BOTTOMRIGHT", -18, 4)

    local scrollBar = CreateFrame("EventFrame", nil, inset, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, -2)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 2)

    local view = CreateScrollBoxListTreeListView(0)
    view:SetElementFactory(function(factory, node)
        factory("Button", InitElement)
    end)
    view:SetElementExtentCalculator(function(_, node)
        return node:GetData().header and HEADER_HEIGHT or ROW_HEIGHT
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    local btnNew = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btnNew:SetSize(132, 22)
    btnNew:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 9)
    btnNew:SetText(L["CREATE"])
    btnNew:SetScript("OnClick", function()
        MenuUtil.CreateContextMenu(btnNew, function(_, root)
            local E = MF:GetModule("Editor")
            root:CreateButton(L["SIDEBAR_NEW_CHARACTER"], function() E:OpenNew(true) end)
            root:CreateButton(L["SIDEBAR_NEW_ACCOUNT"], function() E:OpenNew(false) end)
        end)
    end)

    local btnImport = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btnImport:SetSize(132, 22)
    btnImport:SetPoint("LEFT", btnNew, "RIGHT", 6, 0)
    btnImport:SetText(L["IMPORT"])
    btnImport:SetScript("OnClick", function()
        local S = MF:GetModule("Share")
        if S then S:OpenImport() end
    end)

    return inset
end

local function CreateToolbar()
    -- Top-right shortcuts to the other windows
    local buttons = {
        { L["SETS"], function() local S = MF:GetModule("Sets"); if S then S:Open() end end },
        { L["TEMPLATES"], function() local T = MF:GetModule("Templates"); if T then T:OpenBrowser() end end },
        { L["TRASH"], function() local H = MF:GetModule("History"); if H then H:OpenTrash() end end },
        { SETTINGS or "Settings", function() local S = MF:GetModule("Settings"); if S then S:Toggle() end end },
    }
    local anchor
    for i = #buttons, 1, -1 do
        local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        b:SetSize(100, 22)
        if anchor then
            b:SetPoint("RIGHT", anchor, "LEFT", -4, 0)
        else
            b:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -31)
        end
        b:SetText(buttons[i][1])
        b:SetScript("OnClick", buttons[i][2])
        anchor = b
    end
end

function UI:CreateMainFrame()
    if frame then return end
    frame = CreateFrame("Frame", FRAME_NAME, UIParent, "PortraitFrameFlatTemplate")
    self.mainFrame = frame
    frame:Hide()
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveGeometry()
    end)
    frame:SetTitle("|cff00ccffMacro|r|cffffd700Forge|r  " .. MF.C.grey .. "v" .. MF.VERSION .. "|r")
    frame:SetPortraitToAsset("Interface\\Icons\\Trade_Engineering")
    tinsert(UISpecialFrames, FRAME_NAME)  -- ESC closes

    frame:SetScript("OnShow", function()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
        UI:Refresh()
    end)
    frame:SetScript("OnHide", function()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
        local E = MF:GetModule("Editor")
        if E and E.OnHostHidden then E:OnHostHidden() end
    end)

    RestoreGeometry()

    -- Keys reach this frame when no text field has the focus; the editor's
    -- and the search box's fields forward their Ctrl shortcuts to HandleKey.
    -- SetPropagateKeyboardInput is blocked in combat: keys then just propagate.
    frame:EnableKeyboard(true)
    frame:SetScript("OnKeyDown", function(self, key)
        if InCombatLockdown() then return end
        self:SetPropagateKeyboardInput(not UI:HandleKey(key))
    end)

    local resize = CreateFrame("Button", nil, frame, "PanelResizeButtonTemplate")
    resize:SetPoint("BOTTOMRIGHT", -2, 2)
    resize:Init(frame, MIN_WIDTH, MIN_HEIGHT)
    resize:SetOnResizeStoppedCallback(SaveGeometry)

    local inset = CreateSidebar()
    CreateToolbar()

    editorPane = CreateFrame("Frame", nil, frame)
    editorPane:SetPoint("TOPLEFT", inset, "TOPRIGHT", 10, 0)
    editorPane:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 10)

    emptyState = CreateFrame("Frame", nil, editorPane)
    emptyState:SetAllPoints()
    local emptyIcon = emptyState:CreateTexture(nil, "ARTWORK")
    emptyIcon:SetSize(64, 64)
    emptyIcon:SetPoint("CENTER", 0, 40)
    emptyIcon:SetTexture("Interface\\Icons\\Trade_Engineering")
    emptyIcon:SetDesaturated(true)
    emptyIcon:SetAlpha(0.5)
    local emptyText = emptyState:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
    emptyText:SetPoint("TOP", emptyIcon, "BOTTOM", 0, -14)
    emptyText:SetWidth(360)
    emptyText:SetText(L["EDITOR_EMPTY_STATE"])
end

---------------------------------------------------
-- Keyboard
--   Ctrl+S save   Ctrl+Z / Ctrl+Y undo / redo   Ctrl+F search   Ctrl+N new
--   Up / Down previous / next macro   Delete delete (confirm)   Enter edit the code
-- The list keys only act when no text field has the focus.
---------------------------------------------------
function UI:SelectRelative(delta)
    if #visibleMacros == 0 then return end
    local E = MF:GetModule("Editor")
    local pos
    for i, m in ipairs(visibleMacros) do
        if E and E:IsEditing(m) then pos = i; break end
    end
    local target = visibleMacros[pos and math.max(1, math.min(#visibleMacros, pos + delta)) or 1]
    if not target or (E and E:IsEditing(target)) then return end
    E:Open(target)
    scrollBox:ScrollToElementDataByPredicate(function(node)
        local m = node:GetData().macro
        return m and m.index == target.index and m.scope == target.scope
    end, ScrollBoxConstants.AlignNearest)
end

function UI:HandleKey(key)
    local E = MF:GetModule("Editor")
    if IsControlKeyDown() then
        if key == "S" then E:Save()
        elseif key == "Z" then E:Undo()
        elseif key == "Y" then E:Redo()
        elseif key == "F" then searchBox:SetFocus(); searchBox:HighlightText()
        elseif key == "N" then E:OpenNew(true)
        else return false end
        return true
    end
    if GetCurrentKeyBoardFocus() then return false end
    if key == "UP" then self:SelectRelative(-1)
    elseif key == "DOWN" then self:SelectRelative(1)
    elseif key == "DELETE" and E.cur then self:ConfirmDelete(E.cur)
    elseif key == "ENTER" and E.FocusBody then E:FocusBody()
    else return false end
    return true
end

---------------------------------------------------
-- Public API
---------------------------------------------------
function UI:GetEditorPane()
    self:CreateMainFrame()
    return editorPane
end

-- Called by the editor when it shows content / is cleared
function UI:ShowEditorContent(shown)
    if emptyState then emptyState:SetShown(not shown) end
end

function UI:ShowEmpty()
    local E = MF:GetModule("Editor")
    if E and E.Clear then E:Clear() end
    self:ShowEditorContent(false)
    self:Refresh()
end

function UI:IsShown()
    return frame and frame:IsShown()
end

function UI:Show()
    self:CreateMainFrame()
    frame:Show()
end

function UI:Refresh()
    if not frame or not frame:IsShown() then return end
    scrollBox:SetDataProvider(BuildDataProvider(), ScrollBoxConstants.RetainScrollPosition)
end

function UI:Toggle()
    self:CreateMainFrame()
    frame:SetShown(not frame:IsShown())
end

MF.UI = UI
MF:RegisterModule("UI", UI)
