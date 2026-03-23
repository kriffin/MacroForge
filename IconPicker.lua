---------------------------------------------------
-- MacroForge — Icon Picker
-- Grid-based icon selector with search
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local IP = {}
local AceGUI

local function G()
    if not AceGUI then AceGUI = LibStub("AceGUI-3.0") end
    return AceGUI
end

local pickerFrame, iconScroll, searchBox
local allIcons = {}
local iconsBuilt = false
local onSelectCallback = nil

---------------------------------------------------
-- Build icon list (cached)
---------------------------------------------------
local function BuildIconList()
    if iconsBuilt then return end
    iconsBuilt = true
    wipe(allIcons)

    -- Question mark icon always first
    table.insert(allIcons, { id = 134400, name = "INV_Misc_QuestionMark" })

    -- GetMacroIcons and GetLooseMacroIcons
    local macroIcons = {}
    if GetMacroIcons then GetMacroIcons(macroIcons) end
    if GetLooseMacroIcons then GetLooseMacroIcons(macroIcons) end

    for _, icon in ipairs(macroIcons) do
        if type(icon) == "number" then
            table.insert(allIcons, { id = icon, name = tostring(icon) })
        elseif type(icon) == "string" then
            table.insert(allIcons, { id = icon, name = icon })
        end
    end

    -- Limit to first 1000 for performance
    if #allIcons > 1000 then
        local trimmed = {}
        for i = 1, 1000 do trimmed[i] = allIcons[i] end
        allIcons = trimmed
    end
end

---------------------------------------------------
-- Populate icon grid (flow of icon widgets)
---------------------------------------------------
local function PopulateIcons(scroll, query)
    scroll:ReleaseChildren()
    local gui = G()
    local q = (query or ""):lower()
    local count = 0
    local maxIcons = 200

    for _, iconData in ipairs(allIcons) do
        if count >= maxIcons then break end

        local nameMatch = true
        if q ~= "" then
            local name = type(iconData.name) == "string" and iconData.name:lower() or tostring(iconData.id)
            nameMatch = name:find(q, 1, true)
        end

        if nameMatch then
            local iconBtn = gui:Create("Icon")
            iconBtn:SetImage(iconData.id)
            iconBtn:SetImageSize(32, 32)
            iconBtn:SetWidth(40)
            iconBtn:SetHeight(40)
            iconBtn:SetCallback("OnClick", function()
                if onSelectCallback then
                    onSelectCallback(iconData.id)
                end
                PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
                if pickerFrame then pickerFrame:Hide() end
            end)
            iconBtn:SetCallback("OnEnter", function(w)
                GameTooltip:SetOwner(w.frame, "ANCHOR_RIGHT")
                local displayName = type(iconData.name) == "string" and iconData.name or ("ID: " .. tostring(iconData.id))
                GameTooltip:AddLine(displayName, 1, 1, 1)
                GameTooltip:AddLine("|cff00ccff" .. L["ICON_CLICK_SELECT"] .. "|r")
                GameTooltip:Show()
            end)
            iconBtn:SetCallback("OnLeave", function() GameTooltip:Hide() end)

            scroll:AddChild(iconBtn)
            count = count + 1
        end
    end

    if count == 0 then
        local lbl = gui:Create("Label")
        lbl:SetFullWidth(true)
        lbl:SetText(MF.C.grey .. L["ICON_NONE_FOUND"] .. "|r")
        scroll:AddChild(lbl)
    end
end

---------------------------------------------------
-- Create picker frame
---------------------------------------------------
local function CreatePicker()
    if pickerFrame then return end
    local gui = G()

    BuildIconList()

    local f = gui:Create("Frame")
    f:SetTitle("|cff00ccffMacroForge|r - " .. L["ICON_PICKER_TITLE"])
    f:SetWidth(480)
    f:SetHeight(420)
    f:SetLayout("Flow")
    f:SetCallback("OnClose", function(w) w:Hide() end)
    f:EnableResize(true)
    pickerFrame = f

    -- Dark BG
    local bg = f.frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
    bg:SetPoint("TOPLEFT", f.content, -5, 5)
    bg:SetPoint("BOTTOMRIGHT", f.content, 5, -5)

    -- Search
    searchBox = gui:Create("EditBox")
    searchBox:SetLabel("|cffffff33" .. L["ICON_SEARCH"] .. "|r")
    searchBox:SetFullWidth(true)
    searchBox:DisableButton(true)
    searchBox:SetCallback("OnTextChanged", function(w)
        if iconScroll then PopulateIcons(iconScroll, w:GetText()) end
    end)
    f:AddChild(searchBox)

    -- Icon grid scroll
    iconScroll = gui:Create("ScrollFrame")
    iconScroll:SetFullWidth(true)
    iconScroll:SetFullHeight(true)
    iconScroll:SetLayout("Flow")
    f:AddChild(iconScroll)

    PopulateIcons(iconScroll, "")
    f:Hide()
end

---------------------------------------------------
-- API
---------------------------------------------------
function IP:Open(callback)
    onSelectCallback = callback
    CreatePicker()
    if searchBox then searchBox:SetText("") end
    if iconScroll then PopulateIcons(iconScroll, "") end
    pickerFrame:Show()
    if searchBox then searchBox:SetFocus() end
end

function IP:Toggle(callback)
    if pickerFrame and pickerFrame.frame:IsShown() then
        pickerFrame:Hide()
    else
        self:Open(callback)
    end
end

MF:RegisterModule("IconPicker", IP)
