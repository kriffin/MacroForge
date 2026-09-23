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
local nameWidget, bodyWidget, errorsGroup, explainLabel
local editorRoot       -- top AceGUI container, relaid out when the issue list changes
local issuesShown      -- signature of the issues on screen: rebuild only on change
local RenderIssues     -- defined next to OnChanged
local iconButton, _iconTexture
local testLabel        -- "what would happen now" result of the Test button
local testButton       -- toolbar button, reads "Stop test" while the test is live
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
-- A macro must have a name: a single space reads as "no name" in game
local DEFAULT_NAME = " "

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
-- Toolbar (native): Blizzard text buttons for what you insert, one menu
-- for the rest. Text over icons: an icon for "insert command" is a guess.
---------------------------------------------------
local TOOLBAR_HEIGHT = 34

local function CreateToolbar(pane)
    local toolbar = CreateFrame("Frame", nil, pane)
    toolbar:SetPoint("TOPLEFT", pane, "TOPLEFT", 0, -2)
    toolbar:SetPoint("TOPRIGHT", pane, "TOPRIGHT", 0, -2)
    toolbar:SetHeight(TOOLBAR_HEIGHT - 4)

    local last
    local function TextButton(label, tipTitle, tipText, width, onClick)
        local b = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
        b:SetSize(width, 24)
        b:SetText(label)
        b:SetScript("OnClick", onClick)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:AddLine(tipTitle, 1, 1, 1)
            if tipText then GameTooltip:AddLine(tipText, nil, nil, nil, true) end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", GameTooltip_Hide)
        if last then
            b:SetPoint("LEFT", last, "RIGHT", 4, 0)
        else
            b:SetPoint("LEFT", toolbar, "LEFT", 2, 0)
        end
        last = b
        return b
    end

    TextButton(L["TOOLBAR_SPELL"], L["INSERT_SPELL_BTN"], L["TOOL_SPELL_DESC"], 84, function()
        local CP = MF:GetModule("CommandPalette")
        if CP then CP:OpenSpells() end
    end)
    TextButton(L["TOOLBAR_CMD"], L["INSERT_CMD_BTN"], L["TOOL_CMD_DESC"], 104, function()
        local CP = MF:GetModule("CommandPalette")
        if CP then CP:OpenCommands() end
    end)
    TextButton(L["TOOLBAR_COND"], L["BUILDER"], L["TOOLS_BUILDER_DESC"], 104, function()
        local B = MF:GetModule("Builder")
        if B then B:Toggle() end
    end)
    TextButton(L["SHORTEN_BTN"], L["SHORTEN_BTN"], L["TOOL_SHORTEN_DESC"], 100, function()
        Editor:Shorten()
    end)
    testButton = TextButton(L["TEST_BTN"], L["TEST_BTN"], L["TOOL_TEST_DESC"], 84, function()
        Editor:RunTest()
    end)

    -- Everything else: one menu, so the bar stays readable
    local more = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
    more:SetSize(90, 24)
    more:SetPoint("LEFT", last, "RIGHT", 10, 0)
    more:SetText(L["MORE_BTN"])
    more:SetScript("OnClick", function(self)
        MenuUtil.CreateContextMenu(self, function(_, root)
            local snippets = root:CreateButton(L["INSERT_SNIPPET_LABEL"])
            for _, sn in ipairs(SNIPPETS) do
                snippets:CreateButton(sn.label, function() Editor:InsertText(sn.text) end)
            end

            local font = root:CreateButton(L["OPT_FONTSIZE"])
            for size = 12, 20 do
                font:CreateButton(size .. "px", function()
                    currentFontSize = size
                    Editor:ApplyFontSize(size)
                end)
            end

            root:CreateDivider()
            -- One Share page: export shows the code and the plain text to copy
            root:CreateButton(L["EXPORT_BTN"] .. " / " .. L["COPY_BTN"], function() Editor:OpenExport() end)
            root:CreateButton(L["SEND_MACRO"], function() MF:GetModule("Share"):OpenSend() end)
            root:CreateButton(L["IMPORT_BTN"], function() MF:GetModule("Share"):OpenImport() end)
            root:CreateDivider()
            root:CreateButton(L["HISTORY_BTN"], function()
                local H = MF:GetModule("History")
                if H and Editor.cur and Editor.cur.index then
                    H:OpenBrowser(Editor.cur)
                else
                    MF:Print(MF.C.yellow .. L["OPEN_MACRO_FIRST"] .. "|r")
                end
            end)
            root:CreateButton(L["DRAG_TO_BAR_BTN"], function()
                if Editor.cur and Editor.cur.index then
                    MF.Helpers:PickupMacro(Editor.cur.index)
                elseif Editor.isNew then
                    MF:Print(MF.C.yellow .. L["SAVE_FIRST_DRAG"] .. "|r")
                end
            end)
        end)
    end)

    toolbar:Hide()
    return toolbar
end

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
    editorRoot = f
    f.frame:SetParent(pane)
    f.frame:ClearAllPoints()
    f.frame:SetPoint("TOPLEFT", pane, "TOPLEFT", 0, -TOOLBAR_HEIGHT)
    local function Fit()
        f:SetWidth(pane:GetWidth())
        f:SetHeight(pane:GetHeight() - TOOLBAR_HEIGHT)
        -- Grow the code box with the window: name row, counter, buttons and
        -- margins take about 150px, a line is ~14px at the default size
        if bodyWidget then
            local lines = math.max(8, math.floor((pane:GetHeight() - 190) / 14))
            if lines ~= bodyWidget.mfLines then
                bodyWidget.mfLines = lines
                bodyWidget:SetNumLines(lines)
                f:DoLayout()
            end
        end
    end
    Editor.FitPane = Fit
    pane:HookScript("OnSizeChanged", Fit)
    Fit()

    -- Header: scope + name of the macro being edited
    local header = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", pane, "TOPLEFT", 4, 18)
    header:SetJustifyH("LEFT")

    local toolbar = CreateToolbar(pane)

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
            toolbar:Show()
            header:Show()
            UI:ShowEditorContent(true)
            UI:Show()
        end,
        Hide = function()
            f.frame:Hide()
            toolbar:Hide()
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
    -- Two columns: code (left) | analysis + detected spells (right)
    ---------------------------------------------------
    local columns = gui:Create("SimpleGroup")
    columns:SetFullWidth(true)
    columns:SetLayout("Flow")

    -- Flow centers a row's children on alignoffset (height/2 by default):
    -- zero it so both columns start at the top of the row
    local leftCol = gui:Create("SimpleGroup")
    leftCol:SetRelativeWidth(0.6)
    leftCol:SetLayout("List")
    leftCol.alignoffset = 0
    columns:AddChild(leftCol)

    local rightCol = gui:Create("SimpleGroup")
    rightCol:SetRelativeWidth(0.39)
    rightCol:SetLayout("List")
    rightCol.alignoffset = 0
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
    if Editor.FitPane then Editor.FitPane() end

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
    -- Errors: one clickable row per issue (go to the line), plus a fix row
    -- when the analyzer knows the correction
    errorsGroup = gui:Create("SimpleGroup")
    errorsGroup:SetFullWidth(true)
    errorsGroup:SetLayout("List")
    rightCol:AddChild(errorsGroup)

    -- Algorithmic explanation
    explainLabel = gui:Create("Label")
    explainLabel:SetFullWidth(true)
    explainLabel:SetFontObject(GameFontHighlightSmall)
    explainLabel:SetText("")
    rightCol:AddChild(explainLabel)

    -- What the macro would do right now (Test button)
    testLabel = gui:Create("Label")
    testLabel:SetFullWidth(true)
    testLabel:SetFontObject(GameFontHighlightSmall)
    testLabel:SetText("")
    rightCol:AddChild(testLabel)

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
    -- Ctrl shortcuts while typing: the fields forward them to the main
    -- window's key handler (UI:HandleKey), which owns every shortcut.
    ---------------------------------------------------
    local function ForwardCtrl(_, key)
        if IsControlKeyDown() then MF:GetModule("UI"):HandleKey(key) end
    end
    local nameEB = nameWidget.editBox or nameWidget.editbox
    if nameEB then nameEB:HookScript("OnKeyDown", ForwardCtrl) end
    local bodyEB = bodyWidget.editBox or bodyWidget.editbox
    if bodyEB then bodyEB:HookScript("OnKeyDown", ForwardCtrl) end

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
-- Copy / Export: the Share page, with what is typed in the editor
---------------------------------------------------
-- name, icon, body currently in the editor, or nil when nothing is open
function Editor:GetContent()
    if not (bodyWidget and (self.cur or self.isNew)) then return nil end
    return nameWidget:GetText(), self.selectedIcon or 134400, bodyWidget:GetText()
end

function Editor:OpenExport()
    local name, icon, body = self:GetContent()
    if not body then return MF:Notify(MF.C.yellow .. L["OPEN_MACRO_FIRST"] .. "|r") end
    MF:GetModule("Share"):OpenExport(name, icon, body)
end
Editor.OpenCopy = Editor.OpenExport

---------------------------------------------------
-- Open (edit existing)
---------------------------------------------------
-- The edit box can drop a trailing newline: compare bodies without it, or
-- merely opening a macro would leave a "draft" that differs from it.
local function SameBody(a, b)
    return (a or ""):gsub("%s+$", "") == (b or ""):gsub("%s+$", "")
end

-- Drops the auto-saved draft and any pending write of it
function Editor:DropDraft()
    if draftTimer then draftTimer:Cancel(); draftTimer = nil end
    if MF.db and MF.db.char then MF.db.char.draft = nil end
end

-- Proposes to put a draft back into the open editor
local function OfferDraft(draft)
    -- The editor was just filled with the saved text: that must not
    -- overwrite the draft while the question is on screen
    if draftTimer then draftTimer:Cancel(); draftTimer = nil end
    StaticPopupDialogs["MACROFORGE_DRAFT"] = {
        text = L["DRAFT_FOUND"],
        button1 = L["RESTORE_BTN"],
        button2 = L["IGNORE_BTN"],
        OnAccept = function()
            if draft.isNew and Editor.isNew then
                Editor.newPerChar = draft.perChar and true or false
                editorFrame:SetStatusText(Editor.newPerChar
                    and MF.C.cyan .. L["CHARACTER_SCOPE"] .. "|r" or MF.C.yellow .. L["ACCOUNT_SCOPE"] .. "|r")
            end
            nameWidget:SetText(draft.name or "")
            bodyWidget:SetText(draft.body or "")
            if draft.icon and iconButton then
                Editor.selectedIcon = draft.icon
                iconButton:SetImage(draft.icon)
            end
            Editor:OnChanged()
            MF:Notify(MF.C.green .. L["DRAFT_RESTORED_MSG"] .. "|r")
        end,
        OnCancel = function() Editor:DropDraft() end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    StaticPopup_Show("MACROFORGE_DRAFT")
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

    nameWidget:SetText(macro.name or "")
    bodyWidget:SetText(macro.body or "")
    local iconTex = (macro.icon and macro.icon ~= 0) and macro.icon or 134400
    if iconButton then iconButton:SetImage(iconTex) end
    self:OnChanged()

    -- Auto-saved draft left on this macro (reload, crash, disconnect)
    local draft = MF.db and MF.db.char and MF.db.char.draft
    if MF.Helpers:DraftBelongsTo(draft, macro) then
        if SameBody(draft.body, macro.body) and (draft.name or macro.name) == macro.name then
            self:DropDraft()
        else
            OfferDraft(draft)
        end
    end

    self:StopTest()

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
    self:StopTest()
    CreateEditor()
    self.isNew = true; self.newPerChar = perChar; self.cur = nil
    self.selectedIcon = 134400
    -- Unnamed by default: WoW needs a name, a single space acts as none
    self.baseline = { name = DEFAULT_NAME, body = "#showtooltip\n/cast ", icon = 134400 }
    MF.editingIndex = nil

    -- Reset undo/redo stacks
    wipe(undoStack); wipe(redoStack)
    lastSnapshot = nil

    editorFrame:SetTitle(MF.C.green .. L["NEW_MACRO_TITLE"] .. "|r")
    editorFrame:SetStatusText(perChar and MF.C.cyan .. L["CHARACTER_SCOPE"] .. "|r" or MF.C.yellow .. L["ACCOUNT_SCOPE"] .. "|r")

    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
    nameWidget:SetText(DEFAULT_NAME)
    bodyWidget:SetText("#showtooltip\n/cast ")
    if iconButton then iconButton:SetImage(134400) end
    self:OnChanged()

    -- Push initial state
    PushUndo(DEFAULT_NAME, "#showtooltip\n/cast ", 134400)

    local draft = MF.db and MF.db.char and MF.db.char.draft
    if draft and draft.isNew then OfferDraft(draft) end

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
-- Selects line n in the code box
function Editor:GoToLine(n)
    local eb = bodyWidget and (bodyWidget.editBox or bodyWidget.editbox)
    local s, e = MF.Helpers:LineSpan(bodyWidget and bodyWidget:GetText(), n)
    if not eb or not s then return end
    eb:SetFocus()
    eb:SetCursorPosition(e)
    eb:HighlightText(s, e)
end

function Editor:ApplyFix(issue)
    local body, name = MF.Helpers:ApplyIssueFix(bodyWidget:GetText(), nameWidget:GetText(), issue)
    if not body then return end
    if name ~= nameWidget:GetText() then nameWidget:SetText(name) end
    if body ~= bodyWidget:GetText() then bodyWidget:SetText(body) end
    self:OnChanged()
    if issue.line and issue.line > 0 then self:GoToLine(issue.line) end
end

local MAX_ISSUES_SHOWN = 6

local function IssueRow(text, font, onClick, tip)
    local row = AceGUI:Create("InteractiveLabel")
    row:SetFullWidth(true)
    row:SetFontObject(font)
    row:SetText(text)
    if onClick then
        row:SetHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row:SetCallback("OnClick", onClick)
    end
    if tip then
        row:SetCallback("OnEnter", function(w)
            GameTooltip:SetOwner(w.frame, "ANCHOR_LEFT")
            GameTooltip:AddLine(tip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        row:SetCallback("OnLeave", GameTooltip_Hide)
    end
    errorsGroup:AddChild(row)
end

RenderIssues = function(issues)
    local An = MF:GetModule("Analyzer")
    local sig = {}
    for i, iss in ipairs(issues) do
        if i > MAX_ISSUES_SHOWN then break end
        sig[#sig + 1] = iss.severity .. iss.line .. iss.message .. (iss.fix or "")
    end
    sig = table.concat(sig, "\0") .. "#" .. #issues
    if sig == issuesShown then return end
    issuesShown = sig

    errorsGroup:PauseLayout()
    errorsGroup:ReleaseChildren()
    for idx, iss in ipairs(issues) do
        if idx > MAX_ISSUES_SHOWN then
            IssueRow(MF.C.grey .. L["AND_MORE_ISSUES"]:format(#issues - MAX_ISSUES_SHOWN) .. "|r", GameFontNormalSmall)
            break
        end
        local ln = iss.line > 0 and (MF.C.grey .. "L" .. iss.line .. "|r ") or ""
        local text = An:FmtSev(iss.severity) .. " " .. ln .. iss.message
        if iss.fixType == "spell" then
            text = text .. "  " .. MF.C.yellow .. L["CHECK_GRIMOIRE_HINT"] .. "|r"
        end
        if iss.line > 0 then
            IssueRow(text, GameFontNormalSmall, function() Editor:GoToLine(iss.line) end, L["ISSUE_GOTO_TIP"])
        else
            IssueRow(text, GameFontNormalSmall)
        end
        if iss.fix and (iss.fixType == "name" or iss.fixFrom) then
            IssueRow("    " .. MF.C.green .. format(L["ISSUE_FIX"], iss.fix) .. "|r", GameFontNormalSmall,
                function() Editor:ApplyFix(iss) end, L["ISSUE_FIX_TIP"])
        end
    end
    errorsGroup:ResumeLayout()
    errorsGroup:DoLayout()
    if editorRoot then editorRoot:DoLayout() end
end

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

    RenderIssues(res.issues)

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
        if UI then
            UI:Refresh()
            if dirty then UI:ShowTip("dirty") end
        end
    end

    -- Auto-save draft (throttled 2s) — uses AceDB char namespace. What it
    -- belongs to is captured now: another macro may be open when it fires.
    if MF.db and MF.db.profile.autoSaveDraft then
        if draftTimer then draftTimer:Cancel() end
        local cur, isNew, perChar, icon = self.cur, self.isNew, self.newPerChar, self.selectedIcon
        draftTimer = C_Timer.NewTimer(2, function()
            draftTimer = nil
            local old = MF.db.char.draft
            if not dirty then
                -- Back to the saved text: drop only this macro's draft
                if old and ((isNew and old.isNew) or MF.Helpers:DraftBelongsTo(old, cur)) then
                    MF.db.char.draft = nil
                end
                return
            end
            MF.db.char.draft = {
                name = name, body = body, icon = icon,
                isNew = isNew or nil,
                perChar = isNew and perChar or nil,
                scope = cur and cur.scope, key = cur and cur.name, index = cur and cur.index,
                timestamp = date("%Y-%m-%d %H:%M:%S"),
            }
        end)
    end
end

---------------------------------------------------
-- Save
---------------------------------------------------
-- Returns true when the macro was written (or queued until combat ends);
-- on failure the edits and the draft are kept.
function Editor:Save(noReopen)
    if not nameWidget or not (self.cur or self.isNew) then return false end
    local name = nameWidget:GetText()
    local body = bodyWidget:GetText()
    if not name or name == "" then name = DEFAULT_NAME end

    local icon = self.selectedIcon or 134400
    -- Ctrl+S on an unchanged macro: say so, write nothing
    if not self.isNew and not self:IsDirty() then
        MF:Notify(MF.C.grey .. L["NOTHING_TO_SAVE"] .. "|r")
        return true
    end
    local P = MF:GetModule("Profiles")
    if self.isNew then
        -- nil out of combat = refused (slot limit); in combat it is queued
        local created = P and P:CreateNewMacro(name, icon, body, self.newPerChar)
        if not created and not InCombatLockdown() then return false end
    else
        if not self.cur or not self.cur.index then
            MF:Print(MF.C.red .. L["MISSING_INDEX"] .. "|r"); return false
        end
        -- Nothing can move macro slots during combat, so the index stays valid
        local cur = self.cur
        MF:RunOutOfCombat("save" .. cur.index, function()
            -- Save history snapshot before overwriting
            local H = MF:GetModule("History")
            if H then H:SaveSnapshot(cur) end
            EditMacro(cur.index, name, icon, body)
            MF:Notify(MF.C.green .. L["MACRO_SAVED"]:format(MF.C.cyan .. name .. MF.C.r))
        end)
    end

    self:DropDraft()

    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
    -- Stay on the saved macro: find it again once the client has written it
    -- (a new macro gets a slot, a renamed one may move)
    self.baseline = { name = name, body = body, icon = icon }
    self:OnChanged()
    if noReopen then return true end
    local scope = self.isNew and (self.newPerChar and "character" or "account") or self.cur.scope
    C_Timer.After(0.3, function()
        local P = MF:GetModule("Profiles")
        local saved
        for _, m in ipairs(P:ReadMacros(scope)) do
            if m.name == name and m.body == body then saved = m; break end
        end
        -- Saving keeps a live test running on the saved macro
        local live = Editor:IsTestLive()
        if saved then Editor:Open(saved, true) else Editor:Clear() end
        if saved and live then Editor:RunTest() end
    end)
    return true
end

---------------------------------------------------
-- Test: run the conditions against the current state
-- SecureCmdOptionParse picks the clause WoW would pick right now, so held
-- modifiers, the current target and the unit under the cursor all count.
---------------------------------------------------
local TESTABLE = {
    ["/cast"] = true, ["/use"] = true, ["/castsequence"] = true, ["/castrandom"] = true,
    ["/target"] = true, ["/focus"] = true, ["/cancelaura"] = true, ["/stopmacro"] = true,
    ["/petattack"] = true, ["/click"] = true, ["/startattack"] = true,
}

local function TestResult()
    local lines = {}
    for line in (bodyWidget:GetText() or ""):gmatch("[^\n]+") do
        local cmd, rest = line:match("^%s*(/%S+)%s*(.*)$")
        if cmd and TESTABLE[cmd:lower()] then
            local result, target
            if rest ~= "" then result, target = SecureCmdOptionParse(rest) end
            if result and result ~= "" then
                table.insert(lines, MF.C.cyan .. cmd .. "|r " .. MF.C.white .. result .. "|r"
                    .. (target and (" " .. MF.C.grey .. "@" .. target .. "|r") or ""))
            else
                table.insert(lines, MF.C.cyan .. cmd .. "|r " .. MF.C.grey .. L["TEST_NOTHING"] .. "|r")
            end
        end
    end
    local text = #lines > 0 and table.concat(lines, "\n") or (MF.C.grey .. L["TEST_NOTHING"] .. "|r")
    return "|cffffff33" .. L["TEST_TITLE"] .. "|r\n" .. text .. "\n" .. MF.C.grey .. L["TEST_HINT"] .. "|r"
end

-- Live test: re-resolved while it is on, so changing target, holding Shift
-- or hovering a unit shows the clause that would fire without a click. A
-- short ticker also catches what has no event (the cursor leaving a unit,
-- auras, range); the label is only touched when the result changes.
local testTicker, lastTestText
local testEvents = CreateFrame("Frame")
testEvents:SetScript("OnEvent", function() Editor:RenderTest() end)
local TEST_EVENTS = { "MODIFIER_STATE_CHANGED", "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED",
    "UPDATE_MOUSEOVER_UNIT", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }

function Editor:RenderTest()
    if not testTicker or not testLabel then return end
    if not (editorFrame and editorFrame:IsShown() and editorFrame.frame:IsVisible()) then
        return self:StopTest()
    end
    local text = TestResult()
    if text ~= lastTestText then
        lastTestText = text
        testLabel:SetText(text)
    end
end

function Editor:StopTest()
    if testTicker then testTicker:Cancel(); testTicker = nil end
    testEvents:UnregisterAllEvents()
    lastTestText = nil
    if testLabel then testLabel:SetText("") end
    if testButton then testButton:SetText(L["TEST_BTN"]) end
end

function Editor:IsTestLive() return testTicker ~= nil end

-- The Test button toggles the live test
function Editor:RunTest()
    if not bodyWidget or not SecureCmdOptionParse then return end
    if testTicker then return self:StopTest() end
    testTicker = C_Timer.NewTicker(0.2, function() Editor:RenderTest() end)
    for _, ev in ipairs(TEST_EVENTS) do pcall(testEvents.RegisterEvent, testEvents, ev) end
    if testButton then testButton:SetText(L["TEST_STOP_BTN"]) end
    self:RenderTest()
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
    -- A failed save (empty name, slot limit) keeps the user on the macro
    OnAccept = function(_, proceed) if Editor:Save(true) then proceed() end end,
    OnAlt = function(_, proceed) Editor:DropDraft(); proceed() end,
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
    self:DropDraft()
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

function Editor:FocusBody()
    local eb = bodyWidget and (bodyWidget.editBox or bodyWidget.editbox)
    if eb and editorFrame and editorFrame:IsShown() then eb:SetFocus() end
end

function Editor:Clear()
    self.cur, self.isNew, self.baseline, self.wasDirty = nil, false, nil, false
    MF.editingIndex = nil
    self:StopTest()
    if draftTimer then draftTimer:Cancel(); draftTimer = nil end
    if undoTimer then undoTimer:Cancel(); undoTimer = nil end
    if editorFrame then editorFrame:Hide() end
    local UI = MF:GetModule("UI")
    if UI then UI:Refresh() end
end

-- Main window closed: stop the timers, keep the editor content for next open
function Editor:OnHostHidden()
    if undoTimer then undoTimer:Cancel(); undoTimer = nil end
    self:StopTest()
end

---------------------------------------------------
-- Undo / Redo
---------------------------------------------------
function Editor:Undo()
    if not bodyWidget then return end
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
    if not bodyWidget then return end
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
