---------------------------------------------------
-- MacroForge — Share (Ace3)
-- AceSerializer + LibDeflate for encoding
-- AceComm for direct player-to-player sending
---------------------------------------------------
local _, MF_NS = ...
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local LibDeflate = LibStub("LibDeflate")

local Share = {}

---------------------------------------------------
-- Encode / Decode macros (AceSerializer + LibDeflate)
-- Format: MF7:<LibDeflate compressed + EncodeForPrint>
---------------------------------------------------
local PREFIX = "MF7:"
local LEGACY_PREFIXES = { "MF5:", "MF6:" }

function Share:Encode(name, icon, body)
    local data = { name = name or "", icon = icon or 134400, body = body or "" }
    local serialized = MF:Serialize(data)
    local compressed = LibDeflate:CompressDeflate(serialized, { level = 9 })
    local encoded = LibDeflate:EncodeForPrint(compressed)
    return PREFIX .. encoded
end

-- Share codes are short: anything bigger is junk or a decompression bomb
local MAX_CODE_LENGTH = 4096

function Share:Decode(encoded)
    if type(encoded) ~= "string" then return nil, L["SHARE_INVALID"] end
    encoded = encoded:match("^%s*(.-)%s*$")
    if #encoded > MAX_CODE_LENGTH then return nil, L["SHARE_INVALID"] end
    local macro, err = self:DecodeRaw(encoded)
    if macro then macro, err = MF.Helpers:SanitizeMacro(macro) end
    if not macro then MF:Debug("share", "decode failed: %s", err) end
    return macro, err
end

function Share:DecodeRaw(encoded)

    -- Try new MF7: format first
    if encoded:sub(1, 4) == "MF7:" then
        local raw = encoded:sub(5)
        local decoded = LibDeflate:DecodeForPrint(raw)
        if not decoded then return nil, L["SHARE_DECODE_FAIL"] end
        local decompressed = LibDeflate:DecompressDeflate(decoded)
        if not decompressed or #decompressed > MAX_CODE_LENGTH then return nil, L["SHARE_DECODE_FAIL"] end
        local success, data = MF:Deserialize(decompressed)
        if not success or not data then return nil, L["SHARE_BAD_STRUCT"] end
        return data
    end

    -- Legacy support for MF5:/MF6: (old Base64 format)
    local matchedPrefix
    for _, p in ipairs(LEGACY_PREFIXES) do
        if encoded:sub(1, #p) == p then matchedPrefix = p; break end
    end
    if matchedPrefix then
        return self:DecodeLegacy(encoded, matchedPrefix)
    end

    return nil, L["SHARE_NOT_MF"]
end

---------------------------------------------------
-- Legacy Base64 decode (backward compat for MF5:/MF6:)
---------------------------------------------------
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function Base64Decode(data)
    data = data:gsub("[^" .. B64 .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (B64:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

function Share:DecodeLegacy(encoded, prefix)
    local SEPARATOR = "\30"
    local b64 = encoded:sub(#prefix + 1)
    local raw = Base64Decode(b64)
    if not raw or raw == "" then
        return nil, L["SHARE_DECODE_FAIL"]
    end
    local name, icon, body = raw:match("^(.-)%" .. SEPARATOR .. "(.-)%" .. SEPARATOR .. "(.*)$")
    if not name then
        return nil, L["SHARE_BAD_STRUCT"]
    end
    return {
        name = name,
        icon = tonumber(icon) or 134400,
        body = body,
    }
end

-- One entry point for everything pasted: a share code, or plain macro text
-- (a guide, a forum). Returns macro, err, kind ("code" or "text").
function Share:ParseImport(text)
    text = type(text) == "string" and text:match("^%s*(.-)%s*$") or ""
    if text == "" then return nil end
    if text:match("^MF%d+:") then
        local macro, err = self:Decode(text)
        return macro, err, "code"
    end
    local macro, err = MF.Helpers:ParseMacroText(text)
    return macro, err, "text"
end

---------------------------------------------------
-- Share page (main window): Import and Export tabs
--   Import: paste a share code or plain macro text, preview, open or create
--   Export: share code + plain text (select all, Ctrl+C), send to a player
---------------------------------------------------
local function BuildSharePage(page)
    local W = MF.Widgets
    local state = { macro = nil, decoded = nil }

    -- Tabs, like the main window's sidebar
    local tabHost = CreateFrame("Frame", nil, page)
    tabHost:SetPoint("TOPLEFT", 4, 0)
    tabHost:SetSize(300, 30)
    tabHost.Tabs = {}
    local panes = {}
    local function SelectTab(i)
        PanelTemplates_SetTab(tabHost, i)
        for k, pane in ipairs(panes) do pane:SetShown(k == i) end
        page.tab = i
    end
    for i, label in ipairs({ L["IMPORT_BTN"], L["EXPORT_BTN"] }) do
        local tab = CreateFrame("Button", nil, tabHost, "PanelTopTabButtonTemplate")
        tab:SetID(i)
        tab:SetText(label)
        if i == 1 then tab:SetPoint("TOPLEFT") else tab:SetPoint("LEFT", tabHost.Tabs[i - 1], "RIGHT", 0, 0) end
        tab:SetScript("OnClick", function()
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
            SelectTab(i)
        end)
        tabHost.Tabs[i] = tab
        PanelTemplates_TabResize(tab, 0)
    end
    PanelTemplates_SetNumTabs(tabHost, 2)

    for i = 1, 2 do
        local pane = CreateFrame("Frame", nil, page)
        pane:SetPoint("TOPLEFT", 0, -34)
        pane:SetPoint("BOTTOMRIGHT", 0, 0)
        panes[i] = pane
    end

    -- Import
    local imp = panes[1]
    local help = W:Text(imp, "GameFontHighlight", L["SHARE_PASTE_HELP"])
    help:SetPoint("TOPLEFT", 4, -4)
    help:SetPoint("RIGHT", imp, "RIGHT", -4, 0)
    local input = W:CodeBox(imp)
    input:SetPoint("TOPLEFT", help, "BOTTOMLEFT", -4, -8)
    input:SetPoint("RIGHT", imp, "RIGHT", 0, 0)
    input:SetHeight(140)
    local pvTitle = W:Text(imp, "GameFontNormal", L["BUILDER_PREVIEW"])
    pvTitle:SetPoint("TOPLEFT", input, "BOTTOMLEFT", 4, -12)
    local preview = W:Text(imp, "GameFontHighlight")
    preview:SetPoint("TOPLEFT", pvTitle, "BOTTOMLEFT", 0, -6)
    preview:SetPoint("RIGHT", imp, "RIGHT", -4, 0)
    preview:SetJustifyV("TOP")
    local btnOpen = W:Button(imp, L["SHARE_OPEN_EDITOR"], 170, function()
        local macro = state.decoded
        if not macro then return end
        local E = MF:GetModule("Editor")
        E:OpenNew(true, nil, function() E:LoadContent(macro.name, macro.body, macro.icon) end)
    end)
    btnOpen:SetPoint("BOTTOMRIGHT", 0, 0)
    local btnCreate = W:Button(imp, L["SHARE_CREATE_DIRECT"], 170, function()
        local macro = state.decoded
        if not macro then return end
        MF:GetModule("Profiles"):CreateNewMacro(macro.name, macro.icon, macro.body, true)
        C_Timer.After(0.3, function() MF:GetModule("UI"):Refresh() end)
    end)
    btnCreate:SetPoint("RIGHT", btnOpen, "LEFT", -6, 0)

    local function RenderImport(text)
        local macro, err, kind = Share:ParseImport(text)
        state.decoded = macro
        btnOpen:SetEnabled(macro ~= nil)
        btnCreate:SetEnabled(macro ~= nil)
        if macro then
            local An = MF:GetModule("Analyzer")
            preview:SetText(MF.C.grey .. L[kind == "code" and "IMPORT_KIND_CODE" or "IMPORT_KIND_TEXT"] .. "|r\n"
                .. MF.C.gold .. macro.name .. "|r\n" .. (An and An:ColorizeBody(macro.body) or macro.body))
        elseif kind then
            preview:SetText(MF.C.red .. (err or L["SHARE_ERROR"]) .. "|r")
        else
            preview:SetText(MF.C.grey .. L["SHARE_PREVIEW"] .. "|r")
        end
    end
    input:OnChange(RenderImport)

    -- Export
    local exp = panes[2]
    local macroTitle = W:Text(exp, "GameFontNormalLarge")
    macroTitle:SetPoint("TOPLEFT", 4, -4)
    local codeLabel = W:Text(exp, "GameFontNormal", L["EXPORT_CODE_LABEL"])
    codeLabel:SetPoint("TOPLEFT", macroTitle, "BOTTOMLEFT", 0, -12)
    local codeHelp = W:Text(exp, "GameFontHighlightSmall", L["SHARE_COPY_HELP"] .. " " .. L["SHARE_IMPORT_HELP"])
    codeHelp:SetPoint("LEFT", codeLabel, "RIGHT", 10, 0)
    codeHelp:SetPoint("RIGHT", exp, "RIGHT", -4, 0)
    codeHelp:SetWordWrap(false)
    local code = W:CodeBox(exp, true)
    code:SetPoint("TOPLEFT", codeLabel, "BOTTOMLEFT", -4, -6)
    code:SetPoint("RIGHT", exp, "RIGHT", 0, 0)
    code:SetHeight(70)
    local textLabel = W:Text(exp, "GameFontNormal", L["EXPORT_TEXT_LABEL"])
    textLabel:SetPoint("TOPLEFT", code, "BOTTOMLEFT", 4, -12)
    local raw = W:CodeBox(exp, true)
    raw:SetPoint("TOPLEFT", textLabel, "BOTTOMLEFT", -4, -6)
    raw:SetPoint("RIGHT", exp, "RIGHT", 0, 0)
    raw:SetHeight(110)
    local sendLabel = W:Text(exp, "GameFontNormal", L["SEND_TARGET"])
    sendLabel:SetPoint("TOPLEFT", raw, "BOTTOMLEFT", 4, -16)
    local target = W:Input(exp, 180)
    target:SetPoint("LEFT", sendLabel, "RIGHT", 12, 0)
    local btnSend = W:Button(exp, L["SEND_MACRO"], 150)
    btnSend:SetPoint("LEFT", target, "RIGHT", 8, 0)
    local noMacro = W:Text(exp, "GameFontDisableLarge", L["OPEN_MACRO_FIRST_SHARE"], "CENTER")
    noMacro:SetPoint("CENTER")

    local function Send()
        local who = (target:GetText() or ""):match("^%s*(.-)%s*$")
        if not state.macro then return end
        if who == "" then return MF:Notify(MF.C.red .. L["SEND_NO_TARGET"] .. "|r") end
        MF:SendCommMessage("MacroForge", MF:Serialize(state.macro), "WHISPER", who)
        MF:Notify(MF.C.green .. format(L["SEND_SUCCESS"], who) .. "|r")
    end
    btnSend:SetScript("OnClick", Send)
    target:SetScript("OnEnterPressed", function(box) box:ClearFocus(); Send() end)

    local exportParts = { macroTitle, codeLabel, codeHelp, code, textLabel, raw, sendLabel, target, btnSend }
    function page.Fill(arg)
        arg = arg or {}
        if arg.macro then state.macro = arg.macro end
        local m = state.macro
        for _, part in ipairs(exportParts) do part:SetShown(m ~= nil) end
        noMacro:SetShown(m == nil)
        if m then
            macroTitle:SetText(MF.C.gold .. ((m.name or ""):match("^%s*$") and L["MACRO_UNNAMED"] or m.name)
                .. "|r  " .. MF.C.grey .. format(L["SHARE_CHARS"], #m.body) .. "|r")
            code:SetText(Share:Encode(m.name, m.icon, m.body))
            raw:SetText(((m.name or ""):match("^%s*$") and "" or (m.name .. "\n")) .. m.body)
        end
        RenderImport(input:GetText())
        SelectTab(arg.mode == "export" and 2 or arg.mode == "import" and 1 or page.tab or 1)
        if arg.mode == "export" and m then
            if arg.send then target:SetFocus() else code:SelectAll() end
        end
    end
end

local function OpenSharePage(arg)
    local UI = MF:GetModule("UI")
    if not Share.pageRegistered then
        Share.pageRegistered = true
        UI:RegisterPage("share", {
            title = L["SHARE_EXPORT_TITLE"],
            build = BuildSharePage,
            onShow = function(page, a) page.Fill(a) end,
        })
    end
    UI:OpenPage("share", arg)
end

function Share:OpenImport()
    OpenSharePage({ mode = "import" })
end

-- name/icon/body of the macro to share (the editor passes what is typed)
function Share:OpenExport(name, icon, body)
    OpenSharePage({ mode = "export", macro = { name = name or "", icon = icon or 134400, body = body or "" } })
end

function Share:OpenSend()
    local E = MF:GetModule("Editor")
    local name, icon, body = E:GetContent()
    if not body then return MF:Notify(MF.C.yellow .. L["OPEN_MACRO_FIRST"] .. "|r") end
    OpenSharePage({ mode = "export", send = true, macro = { name = name, icon = icon, body = body } })
end

MF:RegisterModule("Share", Share)
