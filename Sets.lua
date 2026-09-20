---------------------------------------------------
-- MacroForge — Sets (Ace3)
-- Browser for the named macro sets stored by Profiles.lua:
-- save, apply, rename, delete, bind to specs.
---------------------------------------------------
local _, MF_NS = ...
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local AceGUI = LibStub("AceGUI-3.0")
local Sets = {}

local frame
local MAX_LISTED_MACROS = 12

---------------------------------------------------
-- Popups (data = callback)
---------------------------------------------------
StaticPopupDialogs["MACROFORGE_SET_CONFIRM"] = {
    text = "%s",
    button1 = YES,
    button2 = NO,
    OnAccept = function(_, onAccept) onAccept() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function PopupEditBox(popup)
    return popup.GetEditBox and popup:GetEditBox() or popup.editBox
end

StaticPopupDialogs["MACROFORGE_SET_RENAME"] = {
    text = L["SET_RENAME_PROMPT"],
    hasEditBox = true,
    maxLetters = 32,
    button1 = ACCEPT,
    button2 = CANCEL,
    OnShow = function(self, data)
        local eb = PopupEditBox(self)
        eb:SetText(data.name)
        eb:HighlightText()
    end,
    OnAccept = function(self, data)
        data.onRename(PopupEditBox(self):GetText())
    end,
    EditBoxOnEnterPressed = function(self, data)
        local popup = self:GetParent()
        data.onRename(self:GetText())
        popup:Hide()
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function Confirm(text, onAccept)
    StaticPopup_Show("MACROFORGE_SET_CONFIRM", text, nil, onAccept)
end

---------------------------------------------------
-- Content
---------------------------------------------------
local function MacroSummary(set)
    local parts = {}
    for i, m in ipairs(set.macros or {}) do
        if i > MAX_LISTED_MACROS then
            table.insert(parts, MF.C.grey .. format(L["SET_MORE"], #set.macros - MAX_LISTED_MACROS) .. "|r")
            break
        end
        table.insert(parts, "|T" .. (m.icon or 134400) .. ":14:14|t " .. m.name)
    end
    if #parts == 0 then return MF.C.grey .. L["SET_EMPTY"] .. "|r" end
    return table.concat(parts, "   ")
end

local function AddButton(parent, text, width, onClick)
    local btn = AceGUI:Create("Button")
    btn:SetText(text)
    btn:SetWidth(width)
    btn:SetCallback("OnClick", onClick)
    parent:AddChild(btn)
    return btn
end

local function BuildSetGroup(P, name, specChoices)
    local set = P:GetSets()[name]
    local isActive = name == P:GetActiveSet()

    local grp = AceGUI:Create("InlineGroup")
    grp:SetFullWidth(true)
    grp:SetLayout("Flow")
    grp:SetTitle(MF.C.white .. name .. "|r"
        .. (isActive and ("  " .. MF.C.green .. L["SET_ACTIVE_TAG"] .. "|r") or "")
        .. "  " .. MF.C.grey .. format(L["MACROS_N"], #(set.macros or {}))
        .. (set.updated and (" — " .. date("%Y-%m-%d %H:%M", set.updated)) or "") .. "|r")

    local summary = AceGUI:Create("Label")
    summary:SetFullWidth(true)
    summary:SetFontObject(GameFontHighlightSmall)
    summary:SetText(MacroSummary(set))
    grp:AddChild(summary)

    -- Spec binding: the dropdown only writes; the list is rebuilt on close
    -- because binding a spec here unbinds it from any other set.
    local list, order = {}, {}
    for _, c in ipairs(specChoices) do
        list[c.key] = c.name
        table.insert(order, c.key)
    end
    local dd = AceGUI:Create("Dropdown")
    dd:SetLabel(L["SET_SPECS"])
    dd:SetWidth(180)
    dd:SetMultiselect(true)
    dd:SetList(list, order)
    for _, key in ipairs(order) do
        dd:SetItemValue(key, set.specs and set.specs[key] or false)
    end
    dd:SetCallback("OnValueChanged", function(_, _, key, checked)
        P:BindSpec(name, key, checked)
    end)
    dd:SetCallback("OnClosed", function()
        C_Timer.After(0, function() P:RefreshUI() end)
    end)
    grp:AddChild(dd)

    AddButton(grp, L["SET_APPLY"], 90, function()
        Confirm(format(L["SET_APPLY_CONFIRM"], name), function() P:ApplySet(name) end)
    end)
    AddButton(grp, L["SET_UPDATE"], 110, function()
        Confirm(format(L["SET_UPDATE_CONFIRM"], name), function() P:SaveSet(name) end)
    end)
    AddButton(grp, L["SET_RENAME"], 90, function()
        StaticPopup_Show("MACROFORGE_SET_RENAME", nil, nil, {
            name = name,
            onRename = function(newName)
                if not P:RenameSet(name, newName) then
                    MF:Print(MF.C.red .. L["SET_RENAME_FAIL"] .. "|r")
                end
            end,
        })
    end)
    AddButton(grp, MF.C.red .. L["DELETE"] .. "|r", 90, function()
        Confirm(format(L["SET_DELETE_CONFIRM"], name), function() P:DeleteSet(name) end)
    end)
    return grp
end

local function Build(f)
    local P = MF:GetModule("Profiles")
    local specID = P:GetCurrentSpecID()
    local active = P:GetActiveSet()

    local info = AceGUI:Create("Label")
    info:SetFullWidth(true)
    info:SetFontObject(GameFontNormal)
    info:SetText(format(L["SET_INFO"],
        MF.C.cyan .. P:GetSpecName(specID) .. "|r",
        active and (MF.C.green .. active .. "|r") or (MF.C.grey .. L["SET_NO_ACTIVE"] .. "|r"),
        MF.db.profile.autoSwap and (MF.C.green .. L["STATE_ON"] .. "|r") or (MF.C.red .. L["STATE_OFF"] .. "|r")))
    f:AddChild(info)

    local nameEB = AceGUI:Create("EditBox")
    nameEB:SetLabel(L["SET_NEW_NAME"])
    nameEB:SetWidth(220)
    nameEB:SetMaxLetters(32)
    nameEB:DisableButton(true)
    f:AddChild(nameEB)

    local function SaveNew()
        local name = (nameEB:GetText() or ""):match("^%s*(.-)%s*$")
        if name == "" then
            MF:Print(MF.C.yellow .. L["SET_NAME_REQUIRED"] .. "|r")
            return
        end
        local exists = P:GetSets()[name]
        local function doSave()
            P:SaveSet(name)
            if not exists and specID and not P:GetSetForSpec(specID) then
                P:BindSpec(name, specID, true)
                Sets:Refresh()
            end
        end
        if exists then
            Confirm(format(L["SET_UPDATE_CONFIRM"], name), doSave)
        else
            doSave()
        end
    end
    nameEB:SetCallback("OnEnterPressed", SaveNew)
    AddButton(f, L["SET_SAVE_CURRENT"], 220, SaveNew)

    local hint = AceGUI:Create("Label")
    hint:SetFullWidth(true)
    hint:SetFontObject(GameFontNormalSmall)
    hint:SetText(MF.C.grey .. L["SET_HINT"] .. "|r")
    f:AddChild(hint)

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    scroll:SetLayout("List")
    f:AddChild(scroll)

    local names = P:GetSetNames()
    if #names == 0 then
        local empty = AceGUI:Create("Label")
        empty:SetFullWidth(true)
        empty:SetText(MF.C.grey .. L["SET_NONE"] .. "|r")
        scroll:AddChild(empty)
        return
    end
    local specChoices = P:GetSpecChoices()
    for _, name in ipairs(names) do
        scroll:AddChild(BuildSetGroup(P, name, specChoices))
    end
end

---------------------------------------------------
-- Open / Toggle / Refresh
---------------------------------------------------
function Sets:Open()
    if frame then
        self:Refresh()
        return
    end
    frame = MF.Helpers:CreateDarkFrame("|cff00ccffMacroForge|r - " .. L["SETS"], 620, 520, "Flow")
    frame:SetCallback("OnClose", function(w)
        w:Release()
        frame = nil
    end)
    Build(frame)
    frame:Show()
end

function Sets:Toggle()
    if frame then
        frame:Release()
        frame = nil
    else
        self:Open()
    end
end

function Sets:Refresh()
    if not frame then return end
    frame:ReleaseChildren()
    Build(frame)
end

---------------------------------------------------
-- Embedded views (main window right pane)
---------------------------------------------------
-- Full sets view: info, "save current macros as" form, every set
function Sets:BuildOverview(container)
    Build(container)
end

-- One set: info line + its group (summary, bound specs, actions)
-- Added straight to the container: a ScrollFrame gets no height in the
-- pane's Flow layout, and one set never needs to scroll
function Sets:BuildDetail(container, name)
    local P = MF:GetModule("Profiles")
    local hint = AceGUI:Create("Label")
    hint:SetFullWidth(true)
    hint:SetFontObject(GameFontNormalSmall)
    hint:SetText(MF.C.grey .. L["SET_HINT"] .. "|r")
    container:AddChild(hint)
    container:AddChild(BuildSetGroup(P, name, P:GetSpecChoices()))
end

function Sets:ConfirmApply(name)
    Confirm(format(L["SET_APPLY_CONFIRM"], name), function()
        MF:GetModule("Profiles"):ApplySet(name)
    end)
end

MF:RegisterModule("Sets", Sets)
