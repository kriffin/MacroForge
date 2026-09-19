---------------------------------------------------
-- MacroForge — Editor (Ace3)
-- EditBox + Toolbar + Syntax Preview + Inline Errors
-- All content inside a ScrollFrame to avoid overlaps
---------------------------------------------------
local _, MF_NS = ...
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local LSM = LibStub("LibSharedMedia-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local Editor = {}

local function G()
    return AceGUI
end

local editorFrame
local nameWidget, bodyWidget, errorsLabel, explainLabel
local iconButton, _iconTexture
local syntaxOverlay    -- FontString overlay for inline syntax highlighting
local lineNumOverlay   -- FontString for line numbers
local spellIconGroup   -- Container for spell/item icons with native tooltips
local currentFontSize = 13  -- default font size
local insertLinkHooked = false  -- Shift+Click link insertion hook installed

-- Global GetItemInfo was removed in 12.x (retail, WoW Forever)
local GetItemInfoCompat = C_Item and C_Item.GetItemInfo or GetItemInfo

---------------------------------------------------
-- Undo/Redo stacks
---------------------------------------------------
local MAX_UNDO = 30
local undoStack, redoStack = {}, {}
local undoTimer, lastSnapshot
local UNDO_DEBOUNCE = 0.5

local function PushUndo(name, body, icon)
    local snap = (name or "") .. "\0" .. (body or "")
    if snap == lastSnapshot then return end
    lastSnapshot = snap
    table.insert(undoStack, { name = name, body = body, icon = icon })
    if #undoStack > MAX_UNDO then table.remove(undoStack, 1) end
    wipe(redoStack)
end

---------------------------------------------------
-- Auto-save draft timer
---------------------------------------------------
local draftTimer

-- Marker for unsaved changes (header + list row)
local DIRTY_MARK = "|TInterface\\COMMON\\Indicator-Yellow:14:14|t"
Editor.DIRTY_MARK = DIRTY_MARK

---------------------------------------------------
-- Snippets database
---------------------------------------------------
local SNIPPETS = {
    { label = "#showtooltip",           text = "#showtooltip\n" },
    { label = "#showtooltip " .. L["SNIPPET_SPELL"], text = "#showtooltip " },
    { label = "/cast [cond] " .. L["SNIPPET_SPELL"], text = "/cast " },
    { label = "/use [cond] " .. L["SNIPPET_ITEM"], text = "/use " },
    { label = "/castsequence reset=",   text = "/castsequence reset=target " },
    { label = "/stopcasting",           text = "/stopcasting\n" },
    { label = "/stopattack",            text = "/stopattack\n" },
    { label = "/startattack",           text = "/startattack\n" },
    { label = "/cancelaura " .. L["SNIPPET_SPELL"], text = "/cancelaura " },
    { label = "/cancelform",            text = "/cancelform\n" },
    { label = "/dismount",              text = "/dismount\n" },
    { label = "/target @focus",         text = "/target [@focus] " },
    { label = "/stopmacro [cond]",      text = "/stopmacro " },
    { label = "/click " .. L["SNIPPET_SECURE_BUTTON"], text = "/click " },
    { label = "/run Script()",          text = "/run " },
    { label = "[mod:shift]",            text = "[mod:shift] " },
    { label = "[mod:ctrl]",             text = "[mod:ctrl] " },
    { label = "[mod:alt]",              text = "[mod:alt] " },
    { label = "[@focus,harm,nodead]",   text = "[@focus,harm,nodead] " },
    { label = "[@mouseover,harm,nodead]",text = "[@mouseover,harm,nodead] " },
    { label = "[@player]",              text = "[@player] " },
    { label = "[combat]",               text = "[combat] " },
    { label = "[nocombat]",             text = "[nocombat] " },
    { label = "[stealth]",              text = "[stealth] " },
}

---------------------------------------------------
-- Create Editor
---------------------------------------------------
local function CreateEditor()
    if editorFrame then return end
    local gui = G()

    -- Hosted in the main window's right pane (UI.lua). The AceGUI container
    -- is sized by hand: AceGUI only lays out on SetWidth/SetHeight.
    local UI = MF:GetModule("UI")
    local pane = UI:GetEditorPane()
    local f = gui:Create("SimpleGroup")
    f:SetLayout("Fill")
    f.frame:SetParent(pane)
    f.frame:ClearAllPoints()
    f.frame:SetPoint("TOPLEFT", pane, "TOPLEFT")
    local function Fit()
        f:SetWidth(pane:GetWidth())
        f:SetHeight(pane:GetHeight())
    end
    pane:HookScript("OnSizeChanged", Fit)
    Fit()

    -- Header: scope + name of the macro being edited
    local header = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", pane, "TOPLEFT", 4, 18)
    header:SetJustifyH("LEFT")

    -- Shim keeping the old AceGUI Frame calls working on the embedded pane
    local headerText, headerDirty = "", false
    local function RenderHeader()
        header:SetText((headerDirty and (DIRTY_MARK .. " ") or "") .. headerText)
    end
    editorFrame = {
        frame = f.frame,
        SetTitle = function(_, text) headerText = text; RenderHeader() end,
        SetStatusText = function(_, text) headerText = text; RenderHeader() end,
        SetDirty = function(_, dirty) headerDirty = dirty; RenderHeader() end,
        Show = function()
            f.frame:Show()
            header:Show()
            UI:ShowEditorContent(true)
            UI:Show()
        end,
        Hide = function()
            f.frame:Hide()
            header:Hide()
            UI:ShowEditorContent(false)
        end,
        IsShown = function() return f.frame:IsShown() end,
    }

    ---------------------------------------------------
    -- Single-column: full-width editor, analysis below
    ---------------------------------------------------
    local mainCol = gui:Create("ScrollFrame")
    mainCol:SetFullWidth(true)
    mainCol:SetFullHeight(true)
    mainCol:SetLayout("List")

    -- Name + Icon row
    local nameRow = gui:Create("SimpleGroup")
    nameRow:SetFullWidth(true)
    nameRow:SetLayout("Flow")

    -- Icon display (click to change)
    iconButton = gui:Create("Icon")
    iconButton:SetImage(134400)
    iconButton:SetImageSize(28, 28)
    iconButton:SetWidth(36)
    iconButton:SetHeight(36)
    iconButton:SetCallback("OnClick", function()
        local IP = MF:GetModule("IconPicker")
        if IP then
            IP:Open(function(iconId)
                Editor.selectedIcon = iconId
                iconButton:SetImage(iconId)
                Editor:OnChanged()
            end)
        end
    end)
    nameRow:AddChild(iconButton)

    -- Name
    nameWidget = gui:Create("EditBox")
    nameWidget:SetLabel(L["MACRO_NAME_LABEL"])
    nameWidget:SetWidth(280)
    nameWidget:SetMaxLetters(16)
    nameWidget:DisableButton(true)
    nameWidget:SetCallback("OnTextChanged", function() Editor:OnChanged() end)
    nameRow:AddChild(nameWidget)

    mainCol:AddChild(nameRow)

    ---------------------------------------------------
    -- Toolbar: compact icon buttons (tooltip = label + help) + dropdowns
    ---------------------------------------------------
    local toolbar = gui:Create("SimpleGroup")
    toolbar:SetFullWidth(true)
    toolbar:SetLayout("Flow")

    local function ToolButton(icon, title, desc, onClick)
        local b = gui:Create("Icon")
        b:SetImage("Interface\\Icons\\" .. icon)
        b:SetImageSize(22, 22)
        b:SetWidth(30)
        b:SetHeight(30)
        b:SetCallback("OnClick", onClick)
        b:SetCallback("OnEnter", function(w)
            GameTooltip:SetOwner(w.frame, "ANCHOR_TOP")
            GameTooltip:AddLine((title:gsub("^%+%s*", "")), 1, 1, 1)
            if desc then GameTooltip:AddLine(desc, nil, nil, nil, true) end
            GameTooltip:Show()
        end)
        b:SetCallback("OnLeave", GameTooltip_Hide)
        toolbar:AddChild(b)
        return b
    end
    local function Spacer(width)
        local sp = gui:Create("Label")
        sp:SetWidth(width)
        sp:SetText(" ")
        toolbar:AddChild(sp)
    end

    ToolButton("INV_Misc_Book_09", L["INSERT_SPELL_BTN"], L["TOOL_SPELL_DESC"], function()
        local CP = MF:GetModule("CommandPalette")
        if CP then CP:OpenSpells() end
    end)
    ToolButton("INV_Misc_Note_01", L["INSERT_CMD_BTN"], L["TOOL_CMD_DESC"], function()
        local CP = MF:GetModule("CommandPalette")
        if CP then CP:OpenCommands() end
    end)
    ToolButton("INV_Misc_Gear_01", L["BUILDER"], L["TOOLS_BUILDER_DESC"], function()
        local B = MF:GetModule("Builder")
        if B then B:Toggle() end
    end)
    ToolButton("Ability_Warrior_Cleave", L["SHORTEN_BTN"], L["TOOL_SHORTEN_DESC"], function()
        Editor:Shorten()
    end)
    Spacer(8)
    ToolButton("INV_Scroll_03", L["COPY_BTN"], L["TOOL_COPY_DESC"], function() Editor:OpenCopy() end)
    ToolButton("INV_Letter_15", L["IMPORT_BTN"], L["TOOL_IMPORT_DESC"], function() Editor:OpenImport() end)
    ToolButton("INV_Letter_18", L["EXPORT_BTN"], L["TOOL_EXPORT_DESC"], function() Editor:OpenExport() end)
    Spacer(8)
    ToolButton("INV_Misc_PocketWatch_01", L["HISTORY_BTN"], L["HISTORY_DESC"], function()
        local H = MF:GetModule("History")
        if H and Editor.cur and Editor.cur.index then
            H:OpenBrowser(Editor.cur)
        else
            MF:Print(MF.C.yellow .. L["OPEN_MACRO_FIRST"] .. "|r")
        end
    end)
    ToolButton("Ability_Hunter_Pathfinding", L["DRAG_TO_BAR_BTN"], L["TOOL_DRAG_DESC"], function()
        if Editor.cur and Editor.cur.index then
            MF.Helpers:PickupMacro(Editor.cur.index)
        elseif Editor.isNew then
            MF:Print(MF.C.yellow .. L["SAVE_FIRST_DRAG"] .. "|r")
        end
    end)
    Spacer(8)

    -- Snippets dropdown
    local snippetDD = gui:Create("Dropdown")
    snippetDD:SetWidth(150)
    local sList, sOrder = {}, {}
    sList[""] = L["INSERT_SNIPPET_LABEL"]
    table.insert(sOrder, "")
    for i, sn in ipairs(SNIPPETS) do
        local key = tostring(i)
        sList[key] = sn.label
        table.insert(sOrder, key)
    end
    snippetDD:SetList(sList, sOrder)
    snippetDD:SetValue("")
    snippetDD:SetCallback("OnValueChanged", function(_, _, val)
        if val ~= "" then
            local idx = tonumber(val)
            if idx and SNIPPETS[idx] then
                Editor:InsertText(SNIPPETS[idx].text)
            end
            snippetDD:SetValue("")
        end
    end)
    toolbar:AddChild(snippetDD)

    -- Font size dropdown
    local fontDD = gui:Create("Dropdown")
    fontDD:SetWidth(70)
    local fList, fOrder = {}, {}
    for sz = 12, 20 do
        local key = tostring(sz)
        fList[key] = key .. "px"
        table.insert(fOrder, key)
    end
    fontDD:SetList(fList, fOrder)
    fontDD:SetValue(tostring(currentFontSize))
    fontDD:SetCallback("OnValueChanged", function(_, _, val)
        local sz = tonumber(val) or 13
        currentFontSize = sz
        Editor:ApplyFontSize(sz)
    end)
    toolbar:AddChild(fontDD)

    mainCol:AddChild(toolbar)

    ---------------------------------------------------
    -- Two columns: code (left) | analysis + detected spells (right)
    ---------------------------------------------------
    local columns = gui:Create("SimpleGroup")
    columns:SetFullWidth(true)
    columns:SetLayout("Flow")

    local leftCol = gui:Create("SimpleGroup")
    leftCol:SetRelativeWidth(0.6)
    leftCol:SetLayout("List")
    columns:AddChild(leftCol)

    local rightCol = gui:Create("SimpleGroup")
    rightCol:SetRelativeWidth(0.39)
    rightCol:SetLayout("List")
    columns:AddChild(rightCol)

    -- Body (the label carries the live n/255 counter)
    bodyWidget = gui:Create("MultiLineEditBox")
    bodyWidget:SetLabel(L["MACRO_BODY_LABEL"])
    bodyWidget:SetFullWidth(true)
    bodyWidget:SetNumLines(14)
    bodyWidget:SetMaxLetters(255)
    bodyWidget:DisableButton(true)
    bodyWidget:SetCallback("OnTextChanged", function() Editor:OnChanged() end)
    leftCol:AddChild(bodyWidget)

    -- Primary actions under the code
    local actions = gui:Create("SimpleGroup")
    actions:SetFullWidth(true)
    actions:SetLayout("Flow")
    local btnSave = gui:Create("Button")
    btnSave:SetText(L["SAVE_BTN"])
    btnSave:SetWidth(130)
    btnSave:SetCallback("OnClick", function() Editor:Save() end)
    actions:AddChild(btnSave)
    local btnCancel = gui:Create("Button")
    btnCancel:SetText(L["CANCEL_BTN"])
    btnCancel:SetWidth(110)
    btnCancel:SetCallback("OnClick", function() Editor:Revert() end)
    actions:AddChild(btnCancel)
    local shortcuts = gui:Create("Label")
    shortcuts:SetWidth(200)
    shortcuts:SetFontObject(GameFontDisableSmall)
    shortcuts:SetText("  " .. L["EDITOR_SHORTCUTS_HINT"])
    actions:AddChild(shortcuts)
    leftCol:AddChild(actions)

    -- Inline syntax highlighting: overlay a colored FontString on the EditBox
    C_Timer.After(0.05, function()
        local eb = bodyWidget.editBox or bodyWidget.editbox
        if eb then
            -- Get font from LibSharedMedia, fallback to default
            local fontName = MF.db and MF.db.profile.fontName or "Friz Quadrata TT"
            local fontFile = LSM:Fetch("font", fontName) or "Fonts\\FRIZQT__.TTF"
            local fontFlags = ""
            currentFontSize = MF.db and MF.db.profile.fontSize or 13

            -- Indent EditBox text to leave room for line numbers
            local indent = 30
            eb:SetTextInsets(indent, 0, 0, 0)

            -- Set font on EditBox first
            eb:SetFont(fontFile, currentFontSize, fontFlags)

            -- Full white text: the syntax overlay covers it with colors,
            -- and the cursor is bright white on the black background
            eb:SetTextColor(1, 1, 1, 1)

            -- Dark background behind line-number gutter
            local gutterBG = eb:CreateTexture(nil, "BACKGROUND")
            gutterBG:SetPoint("TOPLEFT", eb, "TOPLEFT", 0, 0)
            gutterBG:SetPoint("BOTTOMLEFT", eb, "BOTTOMLEFT", 0, 0)
            gutterBG:SetWidth(indent)
            gutterBG:SetColorTexture(0.08, 0.08, 0.10, 0.9)

            -- Line numbers FontString (monospace, left gutter)
            lineNumOverlay = eb:CreateFontString(nil, "ARTWORK")
            lineNumOverlay:SetFont("Fonts\\ARIALN.TTF", currentFontSize, "")
            lineNumOverlay:SetPoint("TOPLEFT", eb, "TOPLEFT", 2, 0)
            lineNumOverlay:SetPoint("BOTTOMLEFT", eb, "BOTTOMLEFT", 2, 0)
            lineNumOverlay:SetWidth(indent - 4)
            lineNumOverlay:SetJustifyH("RIGHT")
            lineNumOverlay:SetJustifyV("TOP")
            lineNumOverlay:SetTextColor(0.55, 0.55, 0.6, 0.9)
            lineNumOverlay:SetText("1")

            -- Syntax overlay FontString (indented to match text)
            syntaxOverlay = eb:CreateFontString(nil, "ARTWORK")
            syntaxOverlay:SetFont(fontFile, currentFontSize, fontFlags)
            syntaxOverlay:SetPoint("TOPLEFT", eb, "TOPLEFT", indent, 0)
            syntaxOverlay:SetPoint("TOPRIGHT", eb, "TOPRIGHT", 0, 0)
            syntaxOverlay:SetJustifyH("LEFT")
            syntaxOverlay:SetJustifyV("TOP")
            syntaxOverlay:SetWordWrap(true)
            syntaxOverlay:SetNonSpaceWrap(true)
            syntaxOverlay:SetText("")

            -- Trigger initial syntax coloring now that overlay exists
            Editor:OnChanged(true)

            -- Hook Autocomplete into this EditBox
            local AC = MF:GetModule("Autocomplete")
            if AC and AC.HookEditBox then
                AC:HookEditBox(eb)
            end

            -- Shift+Click on spells/items inserts the name into our EditBox
            -- when it has focus. 12.x routes every link through
            -- ChatFrameUtil.InsertLink (ChatEdit_InsertLink is only a
            -- deprecated alias nobody calls); a secure post-hook keeps
            -- that path untainted.
            if not insertLinkHooked then
                insertLinkHooked = true
                local function OnInsertLink(text)
                    if text and eb:IsVisible() and eb:HasFocus() then
                        -- Extract spell/item name from link: [Name] or |h[Name]|h
                        eb:Insert(text:match("%[(.-)%]") or text)
                    end
                end
                if ChatFrameUtil and ChatFrameUtil.InsertLink then
                    hooksecurefunc(ChatFrameUtil, "InsertLink", OnInsertLink)
                elseif ChatEdit_InsertLink then
                    hooksecurefunc("ChatEdit_InsertLink", OnInsertLink)
                end
            end
        end
    end)

    -------------------------------------------------
    -- Right column: errors, explanation, detected spells
    -------------------------------------------------
    local analysisHeading = gui:Create("Heading")
    analysisHeading:SetFullWidth(true)
    analysisHeading:SetText("|cffffff33" .. L["ANALYSIS_HEADING"] .. "|r")
    rightCol:AddChild(analysisHeading)

    -- Errors display (hidden when clean)
    errorsLabel = gui:Create("Label")
    errorsLabel:SetFullWidth(true)
    errorsLabel:SetFontObject(GameFontNormalSmall)
    errorsLabel:SetText("")
    rightCol:AddChild(errorsLabel)

    -- Algorithmic explanation
    explainLabel = gui:Create("Label")
    explainLabel:SetFullWidth(true)
    explainLabel:SetFontObject(GameFontHighlightSmall)
    explainLabel:SetText("")
    rightCol:AddChild(explainLabel)

    -- Spell/Item icons row (native Blizzard tooltips on hover)
    local spellHeading = gui:Create("Heading")
    spellHeading:SetFullWidth(true)
    spellHeading:SetText("|cffffff33" .. L["DETECTED_SPELLS_HEADING"] .. "|r")
    rightCol:AddChild(spellHeading)

    spellIconGroup = gui:Create("SimpleGroup")
    spellIconGroup:SetFullWidth(true)
    spellIconGroup:SetLayout("Flow")
    rightCol:AddChild(spellIconGroup)

    mainCol:AddChild(columns)

    f:AddChild(mainCol)

    ---------------------------------------------------
    -- Keyboard shortcuts (Ctrl+S, Ctrl+Z, Ctrl+Y)
    ---------------------------------------------------
    f.frame:EnableKeyboard(true)
    f.frame:SetPropagateKeyboardInput(true)
    f.frame:SetScript("OnKeyDown", function(self, key)
        -- SetPropagateKeyboardInput is blocked in combat: keys keep propagating
        if InCombatLockdown() then return end
        -- Check if an EditBox has focus — if so, don't propagate to the game
        local nameEB = nameWidget and (nameWidget.editBox or nameWidget.editbox)
        local bodyEB = bodyWidget and (bodyWidget.editBox or bodyWidget.editbox)
        local hasFocus = (nameEB and nameEB:HasFocus()) or (bodyEB and bodyEB:HasFocus())

        if IsControlKeyDown() then
            if key == "S" then
                self:SetPropagateKeyboardInput(false)
                Editor:Save()
                return
            elseif key == "Z" then
                self:SetPropagateKeyboardInput(false)
                Editor:Undo()
                return
            elseif key == "Y" then
                self:SetPropagateKeyboardInput(false)
                Editor:Redo()
                return
            end
        end

        -- If an EditBox has focus, swallow ALL keys so they don't leak to the game
        if hasFocus then
            self:SetPropagateKeyboardInput(false)
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    editorFrame:Hide()
end

---------------------------------------------------
-- Apply font size to both EditBox and overlay
---------------------------------------------------
function Editor:ApplyFontSize(size)
    if not bodyWidget then return end
    local eb = bodyWidget.editBox or bodyWidget.editbox
    if eb then
        local fontFile, _, fontFlags = eb:GetFont()
        eb:SetFont(fontFile, size, fontFlags or "")
        if syntaxOverlay then
            syntaxOverlay:SetFont(fontFile, size, fontFlags or "")
        end
        if lineNumOverlay then
            lineNumOverlay:SetFont("Fonts\\ARIALN.TTF", size, "")
        end
    end
end

---------------------------------------------------
-- Copy macro body to "clipboard" (EditBox popup)
---------------------------------------------------
function Editor:OpenCopy()
    local gui = G()
    local body = bodyWidget and bodyWidget:GetText() or ""
    local name = nameWidget and nameWidget:GetText() or ""
    local text = name ~= "" and (name .. "\n" .. body) or body

    local f = gui:Create("Frame")
    f:SetTitle(L["COPY_MACRO_TITLE"])
    f:SetWidth(420)
    f:SetHeight(200)
    f:SetLayout("Flow")
    f:SetCallback("OnClose", function(w) w:Release() end)

    local bg = f.frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
    bg:SetPoint("TOPLEFT", f.content, -5, 5)
    bg:SetPoint("BOTTOMRIGHT", f.content, 5, -5)

    local lbl = gui:Create("Label")
    lbl:SetFullWidth(true)
    lbl:SetFontObject(GameFontNormalSmall)
    lbl:SetText(MF.C.cyan .. L["COPY_BELOW_MSG"] .. "|r")
    f:AddChild(lbl)

    local eb = gui:Create("MultiLineEditBox")
    eb:SetLabel("")
    eb:SetFullWidth(true)
    eb:SetNumLines(6)
    eb:SetText(text)
    eb:DisableButton(true)
    f:AddChild(eb)

    -- Select all on focus
    C_Timer.After(0.1, function()
        local edit = eb.editBox or eb.editbox
        if edit then
            edit:HighlightText()
            edit:SetFocus()
        end
    end)

    f:Show()
end

---------------------------------------------------
-- Load content into the editor (for templates/share import)
-- Does NOT change isNew/cur state — assumes OpenNew was called first
---------------------------------------------------
function Editor:LoadContent(name, body, icon)
    if nameWidget then nameWidget:SetText(name or "") end
    if bodyWidget then bodyWidget:SetText(body or "") end
    if icon and iconButton then
        self.selectedIcon = icon
        iconButton:SetImage(icon)
    end
    -- Reset undo with new content
    wipe(undoStack); wipe(redoStack)
    lastSnapshot = nil
    PushUndo(name or "", body or "", icon or 134400)
    self:OnChanged()
end

---------------------------------------------------
-- Insert text at cursor position in body
---------------------------------------------------
function Editor:InsertText(text)
    if bodyWidget then
        local eb = bodyWidget.editBox or bodyWidget.editbox
        if eb then
            eb:Insert(text)
            Editor:OnChanged()
        else
            -- Fallback: append
            local current = bodyWidget:GetText() or ""
            bodyWidget:SetText(current .. text)
            Editor:OnChanged()
        end
    end
end

---------------------------------------------------
-- Shorten macro body
---------------------------------------------------
function Editor:Shorten()
    if not bodyWidget then return end
    local body = bodyWidget:GetText()
    if not body or body == "" then return end

    local An = MF:GetModule("Analyzer")
    if An and An.ShortenMacro then
        local shortened, saved = An:ShortenMacro(body)
        bodyWidget:SetText(shortened)
        self:OnChanged()
        if saved > 0 then
            MF:Print(MF.C.green .. format(L["SHORTENED_MSG"], saved) .. "|r")
        else
            MF:Print(MF.C.grey .. L["ALREADY_OPTIMIZED"] .. "|r")
        end
    end
end

---------------------------------------------------
-- Import/Export
---------------------------------------------------
function Editor:OpenImport()
    local gui = G()
    local f = gui:Create("Frame")
    f:SetTitle(L["IMPORT_MACRO_TITLE"])
    f:SetWidth(420)
    f:SetHeight(250)
    f:SetLayout("Flow")
    f:SetCallback("OnClose", function(w) w:Release() end)

    local bg = f.frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
    bg:SetPoint("TOPLEFT", f.content, -5, 5)
    bg:SetPoint("BOTTOMRIGHT", f.content, 5, -5)

    local eb = gui:Create("MultiLineEditBox")
    eb:SetLabel(L["PASTE_MACRO_TEXT_LABEL"])
    eb:SetFullWidth(true)
    eb:SetNumLines(8)
    eb:DisableButton(true)
    f:AddChild(eb)

    local btnOk = gui:Create("Button")
    btnOk:SetText(L["IMPORT_BTN"])
    btnOk:SetWidth(100)
    btnOk:SetCallback("OnClick", function()
        local text = eb:GetText()
        if text and text ~= "" then
            -- Parse: first line could be macro name
            local firstLine, rest = text:match("^([^\n]*)\n(.*)$")
            if firstLine and rest then
                -- If first line starts with # or /, treat entire thing as body
                if firstLine:match("^#") or firstLine:match("^/") then
                    bodyWidget:SetText(text)
                else
                    nameWidget:SetText(firstLine:sub(1, 16))
                    bodyWidget:SetText(rest)
                end
            else
                bodyWidget:SetText(text)
            end
            self:OnChanged()
            MF:Print(MF.C.green .. L["MACRO_IMPORTED"] .. "|r")
        end
        f:Release()
    end)
    f:AddChild(btnOk)

    f:Show()
end

function Editor:OpenExport()
    local gui = G()
    local name = nameWidget and nameWidget:GetText() or ""
    local body = bodyWidget and bodyWidget:GetText() or ""
    local text = name .. "\n" .. body

    local f = gui:Create("Frame")
    f:SetTitle(L["EXPORT_MACRO_TITLE"])
    f:SetWidth(420)
    f:SetHeight(250)
    f:SetLayout("Flow")
    f:SetCallback("OnClose", function(w) w:Release() end)

    local bg = f.frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
    bg:SetPoint("TOPLEFT", f.content, -5, 5)
    bg:SetPoint("BOTTOMRIGHT", f.content, 5, -5)

    local eb = gui:Create("MultiLineEditBox")
    eb:SetLabel(L["COPY_BELOW_LABEL"])
    eb:SetFullWidth(true)
    eb:SetNumLines(8)
    eb:SetText(text)
    eb:DisableButton(true)
    f:AddChild(eb)

    -- Select all on focus
    C_Timer.After(0.1, function()
        local edit = eb.editBox or eb.editbox
        if edit then
            edit:HighlightText()
            edit:SetFocus()
        end
    end)

    f:Show()
end

---------------------------------------------------
-- Open (edit existing)
---------------------------------------------------
-- The edit box can drop a trailing newline: compare bodies without it, or
-- merely opening a macro would leave a "draft" that differs from it.
local function SameBody(a, b)
    return (a or ""):gsub("%s+$", "") == (b or ""):gsub("%s+$", "")
end

-- onOpened (optional) runs once the macro is shown: callers that fill the
-- editor afterwards must use it, since Open can wait for the user to
-- save/discard unsaved changes.
function Editor:Open(macro, force, onOpened)
    if not force and self:IsDirty() and not self:IsEditing(macro) then
        return self:ConfirmLeave(function() self:Open(macro, true, onOpened) end)
    end
    CreateEditor()
    self.isNew = false; self.cur = macro
    self.selectedIcon = macro.icon
    self.baseline = { name = macro.name or "", body = macro.body or "", icon = macro.icon }
    MF.editingIndex = macro.index

    -- Reset undo/redo stacks
    wipe(undoStack); wipe(redoStack)
    lastSnapshot = nil

    local dn = macro.name or L["MACRO_UNNAMED"]
    if dn:match("^%s*$") then dn = MF.Helpers:ParseShowTooltip(macro.body) or L["MACRO_UNNAMED"] end
    dn = dn:match("^([^\n]+)") or dn

    local scope = macro.scope == "character" and MF.C.cyan .. L["CHARACTER_SCOPE"] or MF.C.yellow .. L["ACCOUNT_SCOPE"]
    editorFrame:SetStatusText(scope .. "|r " .. MF.C.white .. dn .. "|r  #" .. (macro.index or "?"))

    -- Check for auto-saved draft
    local draft = MF.db and MF.db.char and MF.db.char.draft
    if draft and draft.index == macro.index and not SameBody(draft.body, macro.body) then
        -- Propose draft restoration
        StaticPopupDialogs["MACROFORGE_DRAFT"] = {
            text = L["DRAFT_FOUND"],
            button1 = L["RESTORE_BTN"],
            button2 = L["IGNORE_BTN"],
            OnAccept = function()
                nameWidget:SetText(draft.name or macro.name or "")
                bodyWidget:SetText(draft.body or "")
                if draft.icon and iconButton then
                    Editor.selectedIcon = draft.icon
                    iconButton:SetImage(draft.icon)
                end
                Editor:OnChanged()
                MF:Print(MF.C.green .. L["DRAFT_RESTORED_MSG"] .. "|r")
            end,
            OnCancel = function()
                MF.db.char.draft = nil
            end,
            timeout = 0, whileDead = true, hideOnEscape = true,
        }
        nameWidget:SetText(macro.name or "")
        bodyWidget:SetText(macro.body or "")
        local iconTex = (macro.icon and macro.icon ~= 0) and macro.icon or 134400
        if iconButton then iconButton:SetImage(iconTex) end
        self:OnChanged()
        StaticPopup_Show("MACROFORGE_DRAFT")
    else
        nameWidget:SetText(macro.name or "")
        bodyWidget:SetText(macro.body or "")
        local iconTex = (macro.icon and macro.icon ~= 0) and macro.icon or 134400
        if iconButton then iconButton:SetImage(iconTex) end
        self:OnChanged()
    end

    -- Push initial state for undo
    PushUndo(macro.name or "", macro.body or "", macro.icon or 134400)

    editorFrame:Show()
    local UI = MF:GetModule("UI")
    if UI then UI:Refresh() end
    if onOpened then C_Timer.After(0.1, onOpened) end
end

---------------------------------------------------
-- Open (new)
---------------------------------------------------
function Editor:OpenNew(perChar, force, onOpened)
    if not force and self:IsDirty() then
        return self:ConfirmLeave(function() self:OpenNew(perChar, true, onOpened) end)
    end
    CreateEditor()
    self.isNew = true; self.newPerChar = perChar; self.cur = nil
    self.selectedIcon = 134400
    self.baseline = { name = "", body = "#showtooltip\n/cast ", icon = 134400 }
    MF.editingIndex = nil

    -- Reset undo/redo stacks
    wipe(undoStack); wipe(redoStack)
    lastSnapshot = nil

    editorFrame:SetTitle(MF.C.green .. L["NEW_MACRO_TITLE"] .. "|r")
    editorFrame:SetStatusText(perChar and MF.C.cyan .. L["CHARACTER_SCOPE"] .. "|r" or MF.C.yellow .. L["ACCOUNT_SCOPE"] .. "|r")

    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
    nameWidget:SetText("")
    bodyWidget:SetText("#showtooltip\n/cast ")
    if iconButton then iconButton:SetImage(134400) end
    self:OnChanged()

    -- Push initial state
    PushUndo("", "#showtooltip\n/cast ", 134400)

    editorFrame:Show()
    local UI = MF:GetModule("UI")
    if UI then UI:Refresh() end
    nameWidget:SetFocus()
    if onOpened then C_Timer.After(0.1, onOpened) end
end

---------------------------------------------------
-- Refresh spell/item icons with native tooltips
---------------------------------------------------
local function RefreshSpellIcons(body)
    if not spellIconGroup then return end
    spellIconGroup:ReleaseChildren()

    if not body or body == "" then return end

    local gui = G()
    local seen = {}
    local spells = {}

    for line in body:gmatch("[^\n]+") do
        local cmd = line:match("^(/[%a]+)")
        if cmd then
            local cl = cmd:lower()
            if cl:match("^/cast") or cl:match("^/use") then
                local rest = line:sub(#cmd + 1)
                rest = rest:gsub("reset=[%w/]+%s*", "")
                rest = rest:gsub("%b[]", "")
                for sp in rest:gmatch("([^;,]+)") do
                    sp = sp:match("^%s*(.-)%s*$")
                    if sp ~= "" and not seen[sp:lower()] then
                        seen[sp:lower()] = true
                        table.insert(spells, sp)
                    end
                end
            end
        end
    end

    for _, spellName in ipairs(spells) do
        -- Try as spell
        local spellInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellName)
        if spellInfo and spellInfo.spellID then
            local icon = gui:Create("Icon")
            icon:SetImage(spellInfo.iconID or 134400)
            icon:SetImageSize(28, 28)
            icon:SetWidth(36)
            icon:SetHeight(44)
            icon:SetLabel("|cff71d5ff" .. (spellInfo.name or spellName) .. "|r")
            local sid = spellInfo.spellID
            icon.frame:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(sid)
                GameTooltip:Show()
            end)
            icon.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
            spellIconGroup:AddChild(icon)
        else
            -- Try as item
            local itemName, itemLink, _, _, _, _, _, _, _, itemIcon = GetItemInfoCompat(spellName)
            if itemName then
                local ic = gui:Create("Icon")
                ic:SetImage(itemIcon or 134400)
                ic:SetImageSize(28, 28)
                ic:SetWidth(36)
                ic:SetHeight(44)
                ic:SetLabel("|cff00ff88" .. itemName .. "|r")
                ic.frame:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink(itemLink)
                    GameTooltip:Show()
                end)
                ic.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
                spellIconGroup:AddChild(ic)
            else
                -- Try as slot number (e.g. /use 13)
                local slotNum = tonumber(spellName)
                if slotNum and slotNum >= 1 and slotNum <= 19 then
                    local slotIcon = GetInventoryItemTexture("player", slotNum)
                    local ic = gui:Create("Icon")
                    ic:SetImage(slotIcon or 134400)
                    ic:SetImageSize(28, 28)
                    ic:SetWidth(36)
                    ic:SetHeight(44)
                    ic:SetLabel("|cffffff99" .. L["SLOT_LABEL"] .. " " .. slotNum .. "|r")
                    local sn = slotNum
                    ic.frame:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetInventoryItem("player", sn)
                        GameTooltip:Show()
                    end)
                    ic.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
                    spellIconGroup:AddChild(ic)
                else
                    -- Unknown — show with question mark
                    local ic = gui:Create("Icon")
                    ic:SetImage(134400)
                    ic:SetImageSize(28, 28)
                    ic:SetWidth(36)
                    ic:SetHeight(44)
                    ic:SetLabel("|cffaaaaaa" .. spellName .. "|r")
                    spellIconGroup:AddChild(ic)
                end
            end
        end
    end
end

---------------------------------------------------
-- Live analysis + preview update
---------------------------------------------------
function Editor:OnChanged(skipUndo)
    local body = bodyWidget:GetText()
    local name = nameWidget:GetText()
    local An = MF:GetModule("Analyzer")
    if not An then return end

    -- Inline syntax overlay
    local colored = An:ColorizeBody(body)
    if syntaxOverlay then syntaxOverlay:SetText(colored) end

    -- Line numbers
    if lineNumOverlay then
        local lineCount = 1
        for _ in body:gmatch("\n") do lineCount = lineCount + 1 end
        local nums = {}
        for i = 1, lineCount do nums[i] = tostring(i) end
        lineNumOverlay:SetText(MF.C.grey .. table.concat(nums, "\n") .. "|r")
    end

    -- Full analysis
    local res = An:Analyze(body, name)
    local len = #body
    -- Update char count in body label
    local cc = len > 240 and MF.C.red or len > 200 and MF.C.yellow or MF.C.green
    if bodyWidget then
        bodyWidget:SetLabel(L["MACRO_BODY_LABEL_COUNT"]:format(cc, len))
    end

    -- Errors: inline display, hide when clean
    if #res.issues == 0 then
        errorsLabel:SetText("")
        errorsLabel.frame:Hide()
    else
        local lines = {}
        for idx, iss in ipairs(res.issues) do
            if idx > 6 then
                table.insert(lines, MF.C.grey .. L["AND_MORE_ISSUES"]:format(#res.issues - 6) .. "|r")
                break
            end
            local ln = iss.line > 0 and ("L" .. iss.line .. " ") or ""
            local sevIcon = An:FmtSev(iss.severity)
            local errLine = sevIcon .. " " .. ln .. iss.message
            if iss.fixType == "name" and iss.fix then
                errLine = errLine .. "  " .. MF.C.green .. L["FIX_SUGGESTION"]:format(iss.fix) .. "|r"
            elseif iss.fixType == "spell" then
                errLine = errLine .. "  " .. MF.C.yellow .. L["CHECK_GRIMOIRE_HINT"] .. "|r"
            end
            table.insert(lines, errLine)
        end
        errorsLabel:SetText(table.concat(lines, "\n"))
        errorsLabel.frame:Show()
    end

    -- Algorithmic explanation
    local explained = An:ExplainBody(body)
    explainLabel:SetText(explained)

    -- Refresh spell/item icons
    RefreshSpellIcons(body)

    -- Debounced undo snapshot
    if not skipUndo then
        if undoTimer then undoTimer:Cancel() end
        undoTimer = C_Timer.NewTimer(UNDO_DEBOUNCE, function()
            PushUndo(name, body, Editor.selectedIcon)
        end)
    end

    -- Unsaved-changes marker: header now, list row on state change only
    local dirty = self:IsDirty()
    if dirty ~= (self.wasDirty or false) then
        self.wasDirty = dirty
        editorFrame:SetDirty(dirty)
        local UI = MF:GetModule("UI")
        if UI then UI:Refresh() end
    end

    -- Auto-save draft (throttled 2s) — uses AceDB char namespace
    if MF.db and MF.db.profile.autoSaveDraft then
        if draftTimer then draftTimer:Cancel() end
        draftTimer = C_Timer.NewTimer(2, function()
            local cur = Editor.cur
            if cur and SameBody(body, cur.body) and name == cur.name and Editor.selectedIcon == cur.icon then
                MF.db.char.draft = nil  -- nothing unsaved
                return
            end
            MF.db.char.draft = {
                name = name, body = body,
                icon = Editor.selectedIcon,
                index = Editor.cur and Editor.cur.index or nil,
                timestamp = date("%Y-%m-%d %H:%M:%S"),
            }
        end)
    end
end

---------------------------------------------------
-- Save
---------------------------------------------------
function Editor:Save(noReopen)
    local name = nameWidget:GetText()
    local body = bodyWidget:GetText()
    if not name or name == "" then MF:Print(MF.C.red .. L["EMPTY_NAME"] .. "|r"); return end

    local icon = self.selectedIcon or 134400
    local P = MF:GetModule("Profiles")
    if self.isNew then
        if P then P:CreateNewMacro(name, icon, body, self.newPerChar) end
    else
        if not self.cur or not self.cur.index then
            MF:Print(MF.C.red .. L["MISSING_INDEX"] .. "|r"); return
        end
        -- Nothing can move macro slots during combat, so the index stays valid
        local cur = self.cur
        MF:RunOutOfCombat("save" .. cur.index, function()
            -- Save history snapshot before overwriting
            local H = MF:GetModule("History")
            if H then H:SaveSnapshot(cur) end
            EditMacro(cur.index, name, icon, body)
            MF:Print(MF.C.green .. L["MACRO_SAVED"]:format(MF.C.cyan .. name .. MF.C.r))
        end)
    end

    -- Clear draft on save
    if MF.db and MF.db.char then MF.db.char.draft = nil end
    if draftTimer then draftTimer:Cancel(); draftTimer = nil end

    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
    -- Stay on the saved macro: find it again once the client has written it
    -- (a new macro gets a slot, a renamed one may move)
    self.baseline = { name = name, body = body, icon = icon }
    self:OnChanged()
    if noReopen then return end
    local scope = self.isNew and (self.newPerChar and "character" or "account") or self.cur.scope
    C_Timer.After(0.3, function()
        local P = MF:GetModule("Profiles")
        local saved
        for _, m in ipairs(P:ReadMacros(scope)) do
            if m.name == name and m.body == body then saved = m; break end
        end
        if saved then Editor:Open(saved, true) else Editor:Clear() end
    end)
end

---------------------------------------------------
-- Unsaved changes
---------------------------------------------------
function Editor:IsEditing(macro)
    return self.cur and macro and self.cur.index == macro.index and self.cur.scope == macro.scope
end

function Editor:IsDirty()
    local b = self.baseline
    if not b or not editorFrame or not editorFrame:IsShown() then return false end
    return nameWidget:GetText() ~= b.name
        or not SameBody(bodyWidget:GetText(), b.body)
        or (self.selectedIcon or 134400) ~= (b.icon or 134400)
end

StaticPopupDialogs["MACROFORGE_UNSAVED"] = {
    text = L["UNSAVED_PROMPT"],
    button1 = L["SAVE_BTN"],
    button2 = L["UNSAVED_STAY"],
    button3 = L["UNSAVED_DISCARD"],
    OnAccept = function(_, proceed) Editor:Save(true); proceed() end,
    OnAlt = function(_, proceed) proceed() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Runs proceed() once the user saved or discarded the current edits
function Editor:ConfirmLeave(proceed)
    StaticPopup_Show("MACROFORGE_UNSAVED", nameWidget:GetText() ~= "" and nameWidget:GetText() or L["MACRO_UNNAMED"], nil, proceed)
end

---------------------------------------------------
-- Revert / Clear (embedded editor: no window to close)
---------------------------------------------------
function Editor:Revert()
    if self.isNew or not self.cur then
        self:Clear()
        return
    end
    local P = MF:GetModule("Profiles")
    for _, m in ipairs(P:ReadMacros(self.cur.scope)) do
        if m.index == self.cur.index then return self:Open(m, true) end
    end
    self:Clear()
end

function Editor:Clear()
    self.cur, self.isNew, self.baseline, self.wasDirty = nil, false, nil, false
    MF.editingIndex = nil
    if draftTimer then draftTimer:Cancel(); draftTimer = nil end
    if undoTimer then undoTimer:Cancel(); undoTimer = nil end
    if editorFrame then editorFrame:Hide() end
    local UI = MF:GetModule("UI")
    if UI then UI:Refresh() end
end

-- Main window closed: stop the timers, keep the editor content for next open
function Editor:OnHostHidden()
    if undoTimer then undoTimer:Cancel(); undoTimer = nil end
end

---------------------------------------------------
-- Undo / Redo
---------------------------------------------------
function Editor:Undo()
    if #undoStack < 2 then
        MF:Print(MF.C.grey .. L["NOTHING_TO_UNDO"] .. "|r")
        return
    end
    -- Current state is at top of undoStack
    local current = table.remove(undoStack)
    table.insert(redoStack, current)
    if #redoStack > MAX_UNDO then table.remove(redoStack, 1) end

    local prev = undoStack[#undoStack]
    lastSnapshot = (prev.name or "") .. "\0" .. (prev.body or "")
    nameWidget:SetText(prev.name or "")
    bodyWidget:SetText(prev.body or "")
    if prev.icon and iconButton then
        self.selectedIcon = prev.icon
        iconButton:SetImage(prev.icon)
    end
    self:OnChanged(true) -- skipUndo = true
end

function Editor:Redo()
    if #redoStack == 0 then
        MF:Print(MF.C.grey .. L["NOTHING_TO_REDO"] .. "|r")
        return
    end
    local entry = table.remove(redoStack)
    table.insert(undoStack, entry)
    lastSnapshot = (entry.name or "") .. "\0" .. (entry.body or "")
    nameWidget:SetText(entry.name or "")
    bodyWidget:SetText(entry.body or "")
    if entry.icon and iconButton then
        self.selectedIcon = entry.icon
        iconButton:SetImage(entry.icon)
    end
    self:OnChanged(true) -- skipUndo = true
end

MF.Editor = Editor
MF:RegisterModule("Editor", Editor)
