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

---------------------------------------------------
-- Snippets database
---------------------------------------------------
local SNIPPETS = {
    { label = "#showtooltip",           text = "#showtooltip\n" },
    { label = "#showtooltip Sort",      text = "#showtooltip " },
    { label = "/cast [cond] Sort",      text = "/cast " },
    { label = "/use [cond] Objet",      text = "/use " },
    { label = "/castsequence reset=",   text = "/castsequence reset=target " },
    { label = "/stopcasting",           text = "/stopcasting\n" },
    { label = "/stopattack",            text = "/stopattack\n" },
    { label = "/startattack",           text = "/startattack\n" },
    { label = "/cancelaura Sort",       text = "/cancelaura " },
    { label = "/cancelform",            text = "/cancelform\n" },
    { label = "/dismount",              text = "/dismount\n" },
    { label = "/target @focus",         text = "/target [@focus] " },
    { label = "/stopmacro [cond]",      text = "/stopmacro " },
    { label = "/click BoutonSecure",    text = "/click " },
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

    local f = gui:Create("Frame")
    f:SetTitle("|cff00ccffMacroForge|r - " .. L["EDITOR_TITLE"])
    f:SetWidth(880)
    f:SetHeight(620)
    f:SetLayout("Flow")
    f:SetCallback("OnClose", function(w)
        w:Hide()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
        MF.editingIndex = nil
        -- Cancel pending timers
        if draftTimer then draftTimer:Cancel(); draftTimer = nil end
        if undoTimer then undoTimer:Cancel(); undoTimer = nil end
        -- Remove from UISpecialFrames
        for i = #UISpecialFrames, 1, -1 do
            if UISpecialFrames[i] == "MacroForgeEditorFrame" then
                table.remove(UISpecialFrames, i)
            end
        end
        -- Show macro list again
        local UI = MF:GetModule("UI")
        if UI then
            UI:Refresh()
            if UI.mainFrame then UI.mainFrame:Show() end
        end
    end)

    -- Name the frame for UISpecialFrames Escape support
    f.frame:SetScript("OnShow", function(self)
        _G["MacroForgeEditorFrame"] = self
        tinsert(UISpecialFrames, "MacroForgeEditorFrame")
        self.obj:Fire("OnShow")
    end)
    f.frame:SetScript("OnHide", function(self)
        for i = #UISpecialFrames, 1, -1 do
            if UISpecialFrames[i] == "MacroForgeEditorFrame" then
                table.remove(UISpecialFrames, i)
            end
        end
        self.obj:Fire("OnClose")
    end)
    f:EnableResize(true)
    -- Prevent resizing below minimum to protect two-column layout
    if f.frame.SetResizeBounds then
        f.frame:SetResizeBounds(820, 700)
    elseif f.frame.SetMinResize then
        f.frame:SetMinResize(820, 700)
    end
    editorFrame = f

    -- Add opaque dark background to the content area
    local bg = f.frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.92)
    bg:SetPoint("TOPLEFT", f.content, -5, 5)
    bg:SetPoint("BOTTOMRIGHT", f.content, 5, -5)

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
            end)
        end
    end)
    nameRow:AddChild(iconButton)

    -- Name
    nameWidget = gui:Create("EditBox")
    nameWidget:SetLabel(L["MACRO_NAME_LABEL"])
    nameWidget:SetWidth(600)
    nameWidget:SetMaxLetters(16)
    nameWidget:DisableButton(true)
    nameWidget:SetCallback("OnTextChanged", function() Editor:OnChanged() end)
    nameRow:AddChild(nameWidget)

    mainCol:AddChild(nameRow)

    ---------------------------------------------------
    -- Editor action bar (contextual buttons above body)
    ---------------------------------------------------
    local editorBar = gui:Create("SimpleGroup")
    editorBar:SetFullWidth(true)
    editorBar:SetLayout("Flow")

    -- + Insert spell
    local btnInsert = gui:Create("Button")
    btnInsert:SetText(L["INSERT_SPELL_BTN"])
    btnInsert:SetWidth(120)
    btnInsert:SetCallback("OnClick", function()
        local CP = MF:GetModule("CommandPalette")
        if CP then CP:OpenSpells() end
    end)
    editorBar:AddChild(btnInsert)

    -- + Insert command
    local btnInsertCmd = gui:Create("Button")
    btnInsertCmd:SetText(L["INSERT_CMD_BTN"])
    btnInsertCmd:SetWidth(140)
    btnInsertCmd:SetCallback("OnClick", function()
        local CP = MF:GetModule("CommandPalette")
        if CP then CP:OpenCommands() end
    end)
    editorBar:AddChild(btnInsertCmd)

    -- Snippets dropdown
    local snippetDD = gui:Create("Dropdown")
    snippetDD:SetWidth(160)
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
    editorBar:AddChild(snippetDD)

    -- Raccourcir
    local btnShorten = gui:Create("Button")
    btnShorten:SetText(L["SHORTEN_BTN"])
    btnShorten:SetWidth(95)
    btnShorten:SetCallback("OnClick", function() Editor:Shorten() end)
    editorBar:AddChild(btnShorten)

    -- Font size dropdown
    local fontDD = gui:Create("Dropdown")
    fontDD:SetWidth(80)
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
    editorBar:AddChild(fontDD)

    -- Annuler
    local btnCancel = gui:Create("Button")
    btnCancel:SetText(L["CANCEL_BTN"])
    btnCancel:SetWidth(80)
    btnCancel:SetCallback("OnClick", function() editorFrame:Hide() end)
    editorBar:AddChild(btnCancel)

    mainCol:AddChild(editorBar)

    -- Body
    bodyWidget = gui:Create("MultiLineEditBox")
    bodyWidget:SetLabel(L["MACRO_BODY_LABEL"])
    bodyWidget:SetFullWidth(true)
    bodyWidget:SetNumLines(12)
    bodyWidget:SetMaxLetters(255)
    bodyWidget:DisableButton(true)
    bodyWidget:SetCallback("OnTextChanged", function() Editor:OnChanged() end)
    mainCol:AddChild(bodyWidget)

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

            -- Hook ChatEdit_InsertLink so Shift+Click on spells/items
            -- inserts the spell name into our EditBox when it has focus
            if not MF:IsHooked("ChatEdit_InsertLink") then
                MF:RawHook("ChatEdit_InsertLink", function(text, ...)
                    if text and eb and eb:IsVisible() and eb:HasFocus() then
                        -- Extract spell/item name from link: [Name] or |h[Name]|h
                        local name = text:match("%[(.-)%]") or text
                        eb:Insert(name)
                        return true
                    end
                    return MF.hooks.ChatEdit_InsertLink(text, ...)
                end, true)
            end
        end
    end)

    -- Section: Fichier (save / share / actions)
    local fileHeading = gui:Create("Heading")
    fileHeading:SetFullWidth(true)
    fileHeading:SetText("|cffffff33" .. L["FILE_HEADING"] .. "|r")
    mainCol:AddChild(fileHeading)

    local btnGroup = gui:Create("SimpleGroup")
    btnGroup:SetFullWidth(true)
    btnGroup:SetLayout("Flow")

    local btnSave = gui:Create("Button")
    btnSave:SetText(L["SAVE_BTN"])
    btnSave:SetWidth(120)
    btnSave:SetCallback("OnClick", function() Editor:Save() end)
    btnGroup:AddChild(btnSave)

    local btnCopy = gui:Create("Button")
    btnCopy:SetText(L["COPY_BTN"])
    btnCopy:SetWidth(75)
    btnCopy:SetCallback("OnClick", function() Editor:OpenCopy() end)
    btnGroup:AddChild(btnCopy)

    local btnImport = gui:Create("Button")
    btnImport:SetText(L["IMPORT_BTN"])
    btnImport:SetWidth(85)
    btnImport:SetCallback("OnClick", function() Editor:OpenImport() end)
    btnGroup:AddChild(btnImport)

    local btnExport = gui:Create("Button")
    btnExport:SetText(L["EXPORT_BTN"])
    btnExport:SetWidth(85)
    btnExport:SetCallback("OnClick", function() Editor:OpenExport() end)
    btnGroup:AddChild(btnExport)

    -- Drag to action bar button
    local btnDrag = gui:Create("Button")
    btnDrag:SetText(L["DRAG_TO_BAR_BTN"])
    btnDrag:SetWidth(120)
    btnDrag:SetCallback("OnClick", function()
        if Editor.cur and Editor.cur.index and not InCombatLockdown() then
            PickupMacro(Editor.cur.index)
        elseif Editor.isNew then
            MF:Print(MF.C.yellow .. L["SAVE_FIRST_DRAG"] .. "|r")
        end
    end)
    btnGroup:AddChild(btnDrag)

    mainCol:AddChild(btnGroup)

    -------------------------------------------------
    -- ANALYSIS — Errors + Explanation below editor
    -------------------------------------------------
    local analysisHeading = gui:Create("Heading")
    analysisHeading:SetFullWidth(true)
    analysisHeading:SetText("|cffffff33" .. L["ANALYSIS_HEADING"] .. "|r")
    mainCol:AddChild(analysisHeading)

    -- Hint text at top
    local hintLabel = gui:Create("Label")
    hintLabel:SetFullWidth(true)
    hintLabel:SetFontObject(GameFontNormalSmall)
    hintLabel:SetText(MF.C.grey .. L["ANALYSIS_LIVE_HINT"] .. "|r")
    mainCol:AddChild(hintLabel)

    -- Errors display (hidden when clean)
    errorsLabel = gui:Create("Label")
    errorsLabel:SetFullWidth(true)
    errorsLabel:SetFontObject(GameFontNormalSmall)
    errorsLabel:SetText("")
    mainCol:AddChild(errorsLabel)

    -- Algorithmic explanation
    explainLabel = gui:Create("Label")
    explainLabel:SetFullWidth(true)
    explainLabel:SetFontObject(GameFontNormal)
    explainLabel:SetText("")
    mainCol:AddChild(explainLabel)

    -- Spell/Item icons row (native Blizzard tooltips)
    local spellHeading = gui:Create("Heading")
    spellHeading:SetFullWidth(true)
    spellHeading:SetText("|cffffff33" .. L["DETECTED_SPELLS_HEADING"] .. "|r")
    mainCol:AddChild(spellHeading)

    local spellHint = gui:Create("Label")
    spellHint:SetFullWidth(true)
    spellHint:SetFontObject(GameFontNormalSmall)
    spellHint:SetText(MF.C.grey .. L["SPELL_ICON_HINT"] .. "|r")
    mainCol:AddChild(spellHint)

    spellIconGroup = gui:Create("SimpleGroup")
    spellIconGroup:SetFullWidth(true)
    spellIconGroup:SetLayout("Flow")
    mainCol:AddChild(spellIconGroup)

    f:AddChild(mainCol)

    ---------------------------------------------------
    -- Keyboard shortcuts (Ctrl+S, Ctrl+Z, Ctrl+Y)
    ---------------------------------------------------
    f.frame:EnableKeyboard(true)
    f.frame:SetPropagateKeyboardInput(true)
    f.frame:SetScript("OnKeyDown", function(self, key)
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

    f:Hide()
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
function Editor:Open(macro)
    CreateEditor()
    self.isNew = false; self.cur = macro
    self.selectedIcon = macro.icon
    MF.editingIndex = macro.index

    -- Reset undo/redo stacks
    wipe(undoStack); wipe(redoStack)
    lastSnapshot = nil

    local dn = macro.name or "(Sans nom)"
    if dn:match("^%s*$") then dn = MF.Helpers:ParseShowTooltip(macro.body) or "(Sans nom)" end
    dn = dn:match("^([^\n]+)") or dn

    local scope = macro.scope == "character" and MF.C.cyan .. L["CHARACTER_SCOPE"] or MF.C.yellow .. L["ACCOUNT_SCOPE"]
    editorFrame:SetStatusText(scope .. "|r " .. MF.C.white .. dn .. "|r  #" .. (macro.index or "?"))

    -- Check for auto-saved draft
    local draft = MF.db and MF.db.char and MF.db.char.draft
    if draft and draft.index == macro.index and draft.body ~= macro.body then
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

    -- Hide macro list and show editor
    local UI = MF:GetModule("UI")
    if UI and UI.mainFrame then UI.mainFrame:Hide() end
    editorFrame:Show()
end

---------------------------------------------------
-- Open (new)
---------------------------------------------------
function Editor:OpenNew(perChar)
    CreateEditor()
    self.isNew = true; self.newPerChar = perChar; self.cur = nil
    self.selectedIcon = 134400
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

    -- Hide macro list and show editor
    local UI = MF:GetModule("UI")
    if UI and UI.mainFrame then UI.mainFrame:Hide() end
    editorFrame:Show()
    nameWidget:SetFocus()
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
            local itemName, itemLink, _, _, _, _, _, _, _, itemIcon = GetItemInfo(spellName)
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

    -- Auto-save draft (throttled 2s) — uses AceDB char namespace
    if MF.db and MF.db.profile.autoSaveDraft then
        if draftTimer then draftTimer:Cancel() end
        draftTimer = C_Timer.NewTimer(2, function()
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
function Editor:Save()
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
        -- Save history snapshot before overwriting
        local H = MF:GetModule("History")
        if H then H:SaveSnapshot(self.cur) end
        EditMacro(self.cur.index, name, icon, body)
        MF:Print(MF.C.green .. L["MACRO_SAVED"]:format(MF.C.cyan .. name .. MF.C.r))
    end

    -- Clear draft on save
    if MF.db and MF.db.char then MF.db.char.draft = nil end
    if draftTimer then draftTimer:Cancel(); draftTimer = nil end

    local UI = MF:GetModule("UI")
    MF.editingIndex = nil
    if UI then C_Timer.After(0.3, function() UI:Refresh() end) end
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
    editorFrame:Hide()
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
