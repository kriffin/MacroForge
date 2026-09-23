---------------------------------------------------
-- MacroForge — Icon Picker
-- Editor drawer, like the icon picker next to Blizzard's macro window: the
-- "?" icon and the icons of the macro's own spells on top, then every
-- macro icon in a scrolling grid. A click picks the icon.
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local IP = {}

local ICON_SIZE, GAP = 36, 4
local MAX_PER_ROW = 16
local allIcons
local onPick

-- Every icon the macro UI offers, built once
local function AllIcons()
    if allIcons then return allIcons end
    allIcons = {}
    local list = {}
    if GetMacroIcons then GetMacroIcons(list) end
    if GetMacroItemIcons then GetMacroItemIcons(list) end
    if GetLooseMacroIcons then GetLooseMacroIcons(list) end
    local seen = {}
    for _, icon in ipairs(list) do
        if not seen[icon] then
            seen[icon] = true
            table.insert(allIcons, icon)
        end
    end
    return allIcons
end

-- "?" (dynamic: WoW shows the icon of the spell being cast) + the spells
-- and items named in the code
local function MacroIcons()
    local icons, seen = { MF.Helpers.DYNAMIC_ICON }, { [MF.Helpers.DYNAMIC_ICON] = true }
    local E = MF:GetModule("Editor")
    local _, _, body = E:GetContent()
    for _, name in ipairs(MF.Helpers:ParseSpells(body)) do
        name = (name:match("^([^;,]+)") or name):match("^%s*(.-)%s*$")
        local tex = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(name)
        if not tex and C_Item and C_Item.GetItemInfoInstant then
            tex = select(5, C_Item.GetItemInfoInstant(name))
        end
        if tex and not seen[tex] then
            seen[tex] = true
            table.insert(icons, tex)
        end
    end
    return icons
end

local function Pick(icon)
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
    if onPick then onPick(icon) end
    MF:GetModule("Editor"):CloseDrawer()
end

local function IconButton(parent)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(ICON_SIZE, ICON_SIZE)
    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetAllPoints()
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetScript("OnClick", function(self) Pick(self.icon) end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.icon == MF.Helpers.DYNAMIC_ICON and L["ICON_DYNAMIC"]
            or format(L["ICON_TOOLTIP_ID"], tostring(self.icon)), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    return b
end

local function BuildDrawer(body)
    local W = MF.Widgets
    local mine = W:Text(body, "GameFontNormalSmall", L["ICON_FROM_MACRO"])
    mine:SetPoint("TOPLEFT", 4, 0)
    local top = CreateFrame("Frame", nil, body)
    top:SetPoint("TOPLEFT", mine, "BOTTOMLEFT", 0, -4)
    top:SetPoint("RIGHT", body, "RIGHT")
    top:SetHeight(ICON_SIZE)
    top.buttons = {}
    local all = W:Text(body, "GameFontNormalSmall", L["ICON_ALL"])
    all:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, -10)

    local inset = CreateFrame("Frame", nil, body, "InsetFrameTemplate")
    inset:SetPoint("TOPLEFT", all, "BOTTOMLEFT", -4, -4)
    inset:SetPoint("BOTTOMRIGHT")
    local scrollBox = CreateFrame("Frame", nil, inset, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", 4, -4)
    scrollBox:SetPoint("BOTTOMRIGHT", -18, 4)
    local scrollBar = CreateFrame("EventFrame", nil, inset, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, -2)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 2)

    -- One element = one row of icons, as many as the width allows
    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(ICON_SIZE + GAP)
    view:SetElementInitializer("Frame", function(row, icons)
        row.buttons = row.buttons or {}
        for i = 1, MAX_PER_ROW do
            local b = row.buttons[i]
            if icons[i] and not b then
                b = IconButton(row)
                b:SetPoint("LEFT", (i - 1) * (ICON_SIZE + GAP), 0)
                row.buttons[i] = b
            end
            if b then
                b.icon = icons[i]
                b.tex:SetTexture(icons[i])
                b:SetShown(icons[i] ~= nil)
            end
        end
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    local perRow
    local Fill
    function Fill()
        -- Laid out on the next frame: the width is not known yet
        if not body:IsVisible() then return end
        if scrollBox:GetWidth() < ICON_SIZE then return C_Timer.After(0, Fill) end
        local n = math.max(1, math.min(MAX_PER_ROW, math.floor((scrollBox:GetWidth() + GAP) / (ICON_SIZE + GAP))))
        -- Top row: the macro's own icons
        local mineIcons = MacroIcons()
        for i = 1, math.max(#mineIcons, #top.buttons) do
            local b = top.buttons[i]
            if mineIcons[i] and i <= n and not b then
                b = IconButton(top)
                b:SetPoint("LEFT", (i - 1) * (ICON_SIZE + GAP), 0)
                top.buttons[i] = b
            end
            if b then
                b.icon = mineIcons[i]
                b.tex:SetTexture(mineIcons[i])
                b:SetShown(mineIcons[i] ~= nil and i <= n)
            end
        end
        if n == perRow then return end
        perRow = n
        local rows, row = {}, nil
        for i, icon in ipairs(AllIcons()) do
            if (i - 1) % n == 0 then row = {}; table.insert(rows, row) end
            table.insert(row, icon)
        end
        scrollBox:SetDataProvider(CreateDataProvider(rows))
    end
    scrollBox:HookScript("OnSizeChanged", function() if body:IsVisible() then Fill() end end)
    body.Fill = Fill
end

local registered
-- callback(icon) receives the picked icon
function IP:Toggle(callback)
    onPick = callback
    local E = MF:GetModule("Editor")
    if not registered then
        registered = true
        E:RegisterDrawer("icons", {
            title = L["ICON_PICKER_TITLE"],
            build = BuildDrawer,
            onShow = function(body) body.Fill() end,
        })
    end
    E:ToggleDrawer("icons")
end
IP.Open = IP.Toggle

MF:RegisterModule("IconPicker", IP)
