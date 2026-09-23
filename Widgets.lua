---------------------------------------------------
-- MacroForge — Widgets
-- Small native kit for the pages of the main window: Blizzard templates
-- only (UIPanelButtonTemplate, InsetFrameTemplate, WowScrollBoxList,
-- UIPanelScrollFrameTemplate, InputBoxTemplate), no AceGUI.
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local W = {}
MF.Widgets = W

function W:Button(parent, text, width, onClick, tip)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width or 140, 22)
    b:SetText(text)
    if onClick then b:SetScript("OnClick", onClick) end
    if tip then
        b:SetScript("OnEnter", function(owner)
            GameTooltip:SetOwner(owner, "ANCHOR_TOP")
            GameTooltip:AddLine(tip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", GameTooltip_Hide)
    end
    return b
end

function W:Text(parent, font, text, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    fs:SetJustifyH(justify or "LEFT")
    if text then fs:SetText(text) end
    return fs
end

-- Single-line input (InputBoxTemplate), Enter and Escape drop the focus
function W:Input(parent, width)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(width or 180, 20)
    eb:SetAutoFocus(false)
    eb:SetScript("OnEnterPressed", eb.ClearFocus)
    eb:SetScript("OnEscapePressed", eb.ClearFocus)
    return eb
end

-- Multi-line text box in an inset, scrolling. readOnly boxes select all
-- on focus so Ctrl+C copies everything.
function W:CodeBox(parent, readOnly)
    local inset = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    local sf = CreateFrame("ScrollFrame", nil, inset, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 8, -6)
    sf:SetPoint("BOTTOMRIGHT", -28, 6)
    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    eb:SetFontObject(ChatFontNormal)
    eb:SetTextInsets(2, 2, 2, 2)
    eb:SetScript("OnEscapePressed", eb.ClearFocus)
    sf:SetScrollChild(eb)
    sf:HookScript("OnSizeChanged", function(_, w) eb:SetWidth(math.max(40, w)) end)
    eb:SetScript("OnCursorChanged", function(_, _, y, _, h)
        -- Keep the cursor visible while typing
        local offset, height = sf:GetVerticalScroll(), sf:GetHeight()
        y = -y
        if y < offset then sf:SetVerticalScroll(y)
        elseif y + h > offset + height then sf:SetVerticalScroll(y + h - height) end
    end)
    -- Clicking the empty part of the box focuses the text
    inset:EnableMouse(true)
    inset:SetScript("OnMouseDown", function() eb:SetFocus() end)
    if readOnly then
        local value = ""
        eb:SetScript("OnTextChanged", function(box, user)
            if user then box:SetText(value); box:HighlightText() end
        end)
        eb:SetScript("OnEditFocusGained", function(box) box:HighlightText() end)
        inset.SetText = function(_, text) value = text or ""; eb:SetText(value) end
    else
        inset.SetText = function(_, text) eb:SetText(text or "") end
    end
    inset.GetText = function() return eb:GetText() end
    inset.SelectAll = function() eb:SetFocus(); eb:HighlightText() end
    inset.OnChange = function(_, fn)
        eb:HookScript("OnTextChanged", function(_, user) if user then fn(eb:GetText()) end end)
    end
    inset.editBox = eb
    return inset
end

-- List in an inset (WowScrollBoxList + MinimalScrollBar), one row per item:
-- icon, name, sub-line, badge. opts: { width, icon(row), name(row),
-- sub(row), badge(row), onSelect(row), empty = text }
function W:List(parent, opts)
    local list = { selected = nil }
    local inset = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    if opts.width then inset:SetWidth(opts.width) end
    local scrollBox = CreateFrame("Frame", nil, inset, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", 4, -4)
    scrollBox:SetPoint("BOTTOMRIGHT", -18, 4)
    local scrollBar = CreateFrame("EventFrame", nil, inset, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, -2)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 2)
    local emptyText = W:Text(inset, "GameFontDisable", opts.empty, "CENTER")
    emptyText:SetPoint("TOPLEFT", 16, -24)
    emptyText:SetPoint("TOPRIGHT", -16, -24)

    local function Select(row)
        list.selected = row
        scrollBox:ForEachFrame(function(b, r) b.mfSelected:SetShown(r == list.selected) end)
        if opts.onSelect then opts.onSelect(row) end
    end

    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(30)
    view:SetElementInitializer("Button", function(btn, row)
        if not btn.mfIcon then
            btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            btn.mfSelected = btn:CreateTexture(nil, "BACKGROUND")
            btn.mfSelected:SetAllPoints()
            btn.mfSelected:SetColorTexture(0.2, 0.6, 1, 0.18)
            btn.mfIcon = btn:CreateTexture(nil, "ARTWORK")
            btn.mfIcon:SetSize(24, 24)
            btn.mfIcon:SetPoint("LEFT", 6, 0)
            btn.mfBadge = W:Text(btn, "GameFontNormalSmall", nil, "RIGHT")
            btn.mfBadge:SetPoint("RIGHT", -6, 0)
            btn.mfName = W:Text(btn, "GameFontHighlight")
            btn.mfName:SetPoint("TOPLEFT", btn.mfIcon, "TOPRIGHT", 8, 1)
            btn.mfName:SetPoint("RIGHT", btn.mfBadge, "LEFT", -6, 0)
            btn.mfName:SetWordWrap(false)
            btn.mfSub = W:Text(btn, "GameFontDisableSmall")
            btn.mfSub:SetPoint("BOTTOMLEFT", btn.mfIcon, "BOTTOMRIGHT", 8, -1)
            btn.mfSub:SetPoint("RIGHT", btn.mfBadge, "LEFT", -6, 0)
            btn.mfSub:SetWordWrap(false)
        end
        local icon = opts.icon and opts.icon(row)
        btn.mfIcon:SetShown(icon ~= nil)
        btn.mfIcon:SetTexture(icon)
        btn.mfName:SetText(opts.name(row))
        btn.mfSub:SetText(opts.sub and opts.sub(row) or "")
        btn.mfBadge:SetText(opts.badge and opts.badge(row) or "")
        btn.mfSelected:SetShown(row == list.selected)
        btn:SetScript("OnClick", function()
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
            Select(row)
        end)
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    -- Replaces the rows; keeps the selection when the same row is still
    -- there, otherwise selects the first one
    list.SetRows = function(_, rows, same)
        local keep
        for _, r in ipairs(rows) do
            if list.selected and (r == list.selected or (same and same(r, list.selected))) then keep = r end
        end
        list.selected = keep or rows[1]
        emptyText:SetShown(#rows == 0)
        scrollBox:SetDataProvider(CreateDataProvider(rows), ScrollBoxConstants.RetainScrollPosition)
        if opts.onSelect then opts.onSelect(list.selected) end
    end
    list.frame = inset
    return list
end

-- Two-pane page body: list on the left, card on the right, both between
-- top (y offset below the page's own top row) and the bottom button row
function W:ListAndCard(page, opts, top)
    local list = W:List(page, opts)
    list.frame:SetPoint("TOPLEFT", 0, -(top or 0))
    list.frame:SetPoint("BOTTOMLEFT", 0, 30)
    list.frame:SetWidth(opts.width or 270)
    local card = CreateFrame("Frame", nil, page, "InsetFrameTemplate")
    card:SetPoint("TOPLEFT", list.frame, "TOPRIGHT", 8, 0)
    card:SetPoint("BOTTOMRIGHT", 0, 30)
    return list, card
end

MF:RegisterModule("Widgets", W)
