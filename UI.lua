---------------------------------------------------
-- MacroForge — UI (Ace3)
-- Compact macro list with search, context menu, drag
---------------------------------------------------
local _, MF_NS = ...
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local AceGUI = LibStub("AceGUI-3.0")
local UI = {}

local function G()
    return AceGUI
end

local mainFrame, activeTab, searchQuery
activeTab = "character"
searchQuery = ""

---------------------------------------------------
-- Context menu (right-click) — WoW 11.0+ API
---------------------------------------------------
local function ShowContextMenu(macro)
    MenuUtil.CreateContextMenu(UIParent, function(_, rootDescription)
        rootDescription:CreateTitle(macro.name or "Macro")

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
                E:Open(macro)
                C_Timer.After(0.2, function() E:OpenExport() end)
            end
        end)

        rootDescription:CreateButton("|cffff9933" .. L["DRAG_ACTIONBAR"] .. "|r", function()
            if not InCombatLockdown() then
                PickupMacro(macro.index)
            end
        end)

        rootDescription:CreateButton("|cffff4444" .. L["DELETE"] .. "|r", function()
            StaticPopupDialogs["MACROFORGE_DELETE_CONFIRM"] = {
                text = format(L["DELETE_CONFIRM"], macro.name or "?"),
                button1 = L["DELETE_YES"],
                button2 = L["DELETE_NO"],
                OnAccept = function()
                    local P = MF:GetModule("Profiles")
                    if P then P:DeleteMacroByIndex(macro.index) end
                    C_Timer.After(0.2, function() UI:Refresh() end)
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopup_Show("MACROFORGE_DELETE_CONFIRM")
        end)
    end)
end

---------------------------------------------------
-- Filter macros by search query
---------------------------------------------------
local function FilterMacros(macros, query)
    if not query or query == "" then return macros end
    local q = query:lower()
    local filtered = {}
    for _, m in ipairs(macros) do
        local nameMatch = m.name and m.name:lower():find(q, 1, true)
        local bodyMatch = m.body and m.body:lower():find(q, 1, true)
        if nameMatch or bodyMatch then
            table.insert(filtered, m)
        end
    end
    return filtered
end

---------------------------------------------------
-- Populate scroll with compact rows
---------------------------------------------------
local function PopulateScroll(scroll, macros)
    scroll:ReleaseChildren()
    local gui = G()
    local An = MF:GetModule("Analyzer")

    if #macros == 0 then
        local lbl = gui:Create("Label")
        lbl:SetFullWidth(true)
        lbl:SetFontObject(GameFontNormal)
        lbl:SetText(MF.C.grey .. L["NO_MACRO"] .. "|r")
        scroll:AddChild(lbl)
        return
    end

    for i, macro in ipairs(macros) do
        local res = An and An:Analyze(macro.body, macro.name)
        local sc = res and res.score or 100

        -- Safe name: trim, no fallback
        local dn = macro.name and macro.name:match("^%s*(.-)%s*$") or ""
        -- Ensure dn is single-line
        if dn ~= "" then dn = dn:match("^([^\n]+)") or dn end

        local condensed = MF.Helpers:CondenseBody(macro.body)

        -- Highlight if this macro is currently being edited
        local isActive = MF.editingIndex and MF.editingIndex == macro.index

        -- Build display text
        local prefix = isActive and MF.C.gold .. "> |r" or "  "
        local nameColor = isActive and MF.C.gold or MF.C.white
        local display = prefix
        if dn ~= "" then
            display = display .. nameColor .. dn .. "|r  "
        end
        display = display .. MF.C.grey .. condensed .. "|r"
        -- Only show score if not 100%
        if sc < 100 then
            display = display .. "  " .. MF.C.red .. sc .. "%|r"
        end

        local row = gui:Create("InteractiveLabel")
        row:SetFullWidth(true)
        row:SetFontObject(isActive and GameFontHighlight or GameFontNormal)
        row:SetText(display)

        -- Icon
        local iconTex = (macro.icon and macro.icon ~= 0) and macro.icon or 134400
        row:SetImage(iconTex)
        row:SetImageSize(20, 20)

        -- Click to edit, Right-click for context menu, Shift+drag for pickup
        row:SetCallback("OnClick", function(_, _, button)
            if button == "RightButton" then
                ShowContextMenu(macro)
            elseif IsShiftKeyDown() then
                -- Drag to actionbar
                if not InCombatLockdown() then
                    PickupMacro(macro.index)
                end
            else
                PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
                local E = MF:GetModule("Editor")
                if E then E:Open(macro) end
            end
        end)

        -- Tooltip with explanation
        row:SetCallback("OnEnter", function(w)
            GameTooltip:SetOwner(w.frame, "ANCHOR_RIGHT")
            GameTooltip:AddLine(dn, 0, 0.8, 1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(format(L["QUALITY"], sc), 1, 0.84, 0)
            if macro.body then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(macro.body, 0.7, 0.7, 0.7, true)
            end
            if res and #res.issues > 0 then
                GameTooltip:AddLine(" ")
                for _, iss in ipairs(res.issues) do
                    GameTooltip:AddLine(An:FmtSev(iss.severity) .. " " .. iss.message, 1, 1, 1, true)
                end
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["CLICK_EDIT"] .. "  " .. L["CLICK_SHIFT_DRAG"] .. "  " .. L["CLICK_RIGHT_MENU"])
            GameTooltip:Show()
        end)
        row:SetCallback("OnLeave", function() GameTooltip:Hide() end)

        scroll:AddChild(row)
    end
end

---------------------------------------------------
-- Tab content
---------------------------------------------------
local function RefreshTab(container, tab)
    container:ReleaseChildren()
    activeTab = tab
    local gui = G()
    local P = MF:GetModule("Profiles")

    ---------------------------------------------------
    -- Search bar
    ---------------------------------------------------
    local searchRow = gui:Create("SimpleGroup")
    searchRow:SetFullWidth(true)
    searchRow:SetLayout("Flow")

    local searchEB = gui:Create("EditBox")
    searchEB:SetLabel("")
    searchEB:SetWidth(420)
    searchEB:DisableButton(true)
    searchEB:SetText(searchQuery or "")
    searchEB:SetCallback("OnTextChanged", function(w)
        searchQuery = w:GetText()
        -- Refresh the scroll below
        local macros = P and (tab == "character" and P:ReadCharacterMacros() or P:ReadAccountMacros()) or {}
        macros = FilterMacros(macros, searchQuery)
        if UI._currentScroll then
            PopulateScroll(UI._currentScroll, macros)
        end
    end)
    searchRow:AddChild(searchEB)

    -- Clear search button
    local btnClear = gui:Create("Button")
    btnClear:SetText(L["CLEAR"])
    btnClear:SetWidth(80)
    btnClear:SetCallback("OnClick", function()
        searchQuery = ""
        searchEB:SetText("")
        local macros = P and (tab == "character" and P:ReadCharacterMacros() or P:ReadAccountMacros()) or {}
        if UI._currentScroll then
            PopulateScroll(UI._currentScroll, macros)
        end
    end)
    searchRow:AddChild(btnClear)

    container:AddChild(searchRow)

    ---------------------------------------------------
    -- Status info row (spec, macro counts, version)
    ---------------------------------------------------
    local P2 = MF:GetModule("Profiles")
    local specID = P2 and P2:GetCurrentSpecID()
    local specName = P2 and P2:GetSpecName(specID) or "?"
    local na, nc = GetNumMacros()

    local infoRow = gui:Create("SimpleGroup")
    infoRow:SetFullWidth(true)
    infoRow:SetLayout("Flow")

    local infoLabel = gui:Create("Label")
    infoLabel:SetFullWidth(true)
    infoLabel:SetFontObject(GameFontNormalSmall)
    infoLabel:SetText(MF.C.cyan .. specName .. "|r  |  "
        .. format(L["MACROS_COUNT"], nc, na))
    infoRow:AddChild(infoLabel)

    container:AddChild(infoRow)

    -- Spacing separator
    local sep = gui:Create("Heading")
    sep:SetFullWidth(true)
    sep:SetText("")
    container:AddChild(sep)

    ---------------------------------------------------
    -- Scroll
    ---------------------------------------------------
    local scroll = gui:Create("ScrollFrame")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    scroll:SetLayout("List")
    UI._currentScroll = scroll

    local macros = P and (tab == "character" and P:ReadCharacterMacros() or P:ReadAccountMacros()) or {}
    macros = FilterMacros(macros, searchQuery)
    PopulateScroll(scroll, macros)
    container:AddChild(scroll)
end

---------------------------------------------------
-- Create / Toggle
---------------------------------------------------
function UI:CreateMainFrame()
    if mainFrame then return end
    local gui = G()
    local f = gui:Create("Frame")
    f:SetTitle("|cff00ccffMacro|r|cffffd700Forge|r  v" .. MF.VERSION)
    f:SetWidth(580)
    f:SetHeight(520)
    f:SetLayout("Fill")
    f:SetCallback("OnClose", function(w) w:Hide() end)

    -- Register with UISpecialFrames for Escape key support
    f.frame:SetScript("OnShow", function(self)
        _G["MacroForgeListFrame"] = self
        tinsert(UISpecialFrames, "MacroForgeListFrame")
        self.obj:Fire("OnShow")
    end)
    f.frame:SetScript("OnHide", function(self)
        for i = #UISpecialFrames, 1, -1 do
            if UISpecialFrames[i] == "MacroForgeListFrame" then
                table.remove(UISpecialFrames, i)
            end
        end
        self.obj:Fire("OnClose")
    end)
    f:EnableResize(true)
    mainFrame = f
    self.mainFrame = f

    -- Opaque dark background for readability
    local bg = f.frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.92)
    bg:SetPoint("TOPLEFT", f.content, -5, 5)
    bg:SetPoint("BOTTOMRIGHT", f.content, 5, -5)

    local na, nc = GetNumMacros()

    local tabs = gui:Create("TabGroup")
    tabs:SetFullWidth(true)
    tabs:SetFullHeight(true)
    tabs:SetLayout("Flow")
    tabs:SetTabs({
        { value = "character", text = format(L["PERSO_TAB"], nc) },
        { value = "account", text = format(L["COMPTE_TAB"], na) },
    })
    tabs:SetCallback("OnGroupSelected", function(container, _, tab)
        searchQuery = ""
        RefreshTab(container, tab)
    end)
    tabs:SelectTab("character")
    f:AddChild(tabs)
    self.tabs = tabs

    -- Persistent action buttons in the status bar area
    local btnNew = CreateFrame("Button", nil, f.frame, "UIPanelButtonTemplate")
    btnNew:SetSize(100, 22)
    btnNew:SetPoint("BOTTOMLEFT", f.frame, "BOTTOMLEFT", 20, 17)
    btnNew:SetText(MF.C.green .. L["CREATE"] .. "|r")
    btnNew:SetScript("OnClick", function()
        local E = MF:GetModule("Editor")
        if E then E:OpenNew(activeTab == "character") end
    end)

    local btnImport = CreateFrame("Button", nil, f.frame, "UIPanelButtonTemplate")
    btnImport:SetSize(100, 22)
    btnImport:SetPoint("LEFT", btnNew, "RIGHT", 4, 0)
    btnImport:SetText(L["IMPORT"])
    btnImport:SetScript("OnClick", function()
        local E = MF:GetModule("Editor")
        if E then
            E:OpenNew(activeTab == "character")
            C_Timer.After(0.2, function() E:OpenImport() end)
        end
    end)

    -- Hide the status bar entirely so it doesn't overlap buttons
    -- statusbg is the parent of statustext (not stored on widget directly)
    if f.statustext then
        local statusbg = f.statustext:GetParent()
        if statusbg then statusbg:Hide() end
        f.statustext:Hide()
    end

    f:Hide()
end

function UI:Refresh()
    if not mainFrame then self:CreateMainFrame() end
    local na, nc = GetNumMacros()
    if self.tabs then
        self.tabs:SetTabs({
            { value = "character", text = format(L["PERSO_TAB"], nc) },
            { value = "account", text = format(L["COMPTE_TAB"], na) },
        })
        self.tabs:SelectTab(activeTab or "character")
    end
end

function UI:Toggle()
    if not mainFrame then self:CreateMainFrame() end
    if mainFrame.frame:IsShown() then mainFrame:Hide()
    else self:Refresh(); mainFrame:Show() end
end

MF.UI = UI
MF:RegisterModule("UI", UI)
