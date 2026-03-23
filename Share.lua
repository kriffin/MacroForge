---------------------------------------------------
-- MacroForge — Share (Ace3)
-- AceSerializer + LibDeflate for encoding
-- AceComm for direct player-to-player sending
---------------------------------------------------
local _, MF_NS = ...
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local LibDeflate = LibStub("LibDeflate")
local AceGUI = LibStub("AceGUI-3.0")

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

function Share:Decode(encoded)
    if not encoded then return nil, L["SHARE_INVALID"] end

    -- Try new MF7: format first
    if encoded:sub(1, 4) == "MF7:" then
        local raw = encoded:sub(5)
        local decoded = LibDeflate:DecodeForPrint(raw)
        if not decoded then return nil, L["SHARE_DECODE_FAIL"] end
        local decompressed = LibDeflate:DecompressDeflate(decoded)
        if not decompressed then return nil, L["SHARE_DECODE_FAIL"] end
        local success, data = MF:Deserialize(decompressed)
        if not success or not data then return nil, L["SHARE_BAD_STRUCT"] end
        return {
            name = data.name or "",
            icon = tonumber(data.icon) or 134400,
            body = data.body or "",
        }
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

---------------------------------------------------
-- Share Export UI
---------------------------------------------------
function Share:OpenExport(name, icon, body)
    local encoded = self:Encode(name, icon, body)

    local f = AceGUI:Create("Frame")
    f:SetTitle("|cff00ccffMacroForge|r - " .. L["SHARE_EXPORT_TITLE"])
    f:SetWidth(480)
    f:SetHeight(280)
    f:SetLayout("Flow")
    f:SetCallback("OnClose", function(w) w:Release() end)

    local bg = f.frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
    bg:SetPoint("TOPLEFT", f.content, -5, 5)
    bg:SetPoint("BOTTOMRIGHT", f.content, 5, -5)

    local infoLbl = AceGUI:Create("Label")
    infoLbl:SetFullWidth(true)
    infoLbl:SetFontObject(GameFontNormal)
    infoLbl:SetText(MF.C.gold .. name .. "|r — " .. MF.C.grey .. #body .. " chars|r")
    f:AddChild(infoLbl)

    local helpLbl = AceGUI:Create("Label")
    helpLbl:SetFullWidth(true)
    helpLbl:SetFontObject(GameFontNormalSmall)
    helpLbl:SetText(MF.C.cyan .. L["SHARE_COPY_HELP"] .. "|r\n" ..
        MF.C.grey .. L["SHARE_IMPORT_HELP"] .. "|r")
    f:AddChild(helpLbl)

    local eb = AceGUI:Create("MultiLineEditBox")
    eb:SetLabel(L["SHARE_CODE_LABEL"])
    eb:SetFullWidth(true)
    eb:SetNumLines(5)
    eb:SetText(encoded)
    eb:DisableButton(true)
    f:AddChild(eb)

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
-- Share Import UI
---------------------------------------------------
function Share:OpenImport()
    local f = AceGUI:Create("Frame")
    f:SetTitle("|cff00ccffMacroForge|r - " .. L["SHARE_IMPORT_TITLE"])
    f:SetWidth(480)
    f:SetHeight(350)
    f:SetLayout("Flow")
    f:SetCallback("OnClose", function(w) w:Release() end)

    local bg = f.frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
    bg:SetPoint("TOPLEFT", f.content, -5, 5)
    bg:SetPoint("BOTTOMRIGHT", f.content, 5, -5)

    local helpLbl = AceGUI:Create("Label")
    helpLbl:SetFullWidth(true)
    helpLbl:SetFontObject(GameFontNormalSmall)
    helpLbl:SetText(MF.C.cyan .. L["SHARE_PASTE_HELP"] .. "|r")
    f:AddChild(helpLbl)

    local eb = AceGUI:Create("MultiLineEditBox")
    eb:SetLabel(L["SHARE_CODE_LABEL"])
    eb:SetFullWidth(true)
    eb:SetNumLines(4)
    eb:DisableButton(true)
    f:AddChild(eb)

    local pvHeading = AceGUI:Create("Heading")
    pvHeading:SetFullWidth(true)
    pvHeading:SetText("Apercu")
    f:AddChild(pvHeading)

    local pvLabel = AceGUI:Create("Label")
    pvLabel:SetFullWidth(true)
    pvLabel:SetFontObject(GameFontNormalSmall)
    pvLabel:SetText(MF.C.grey .. L["SHARE_PREVIEW"] .. "|r")
    f:AddChild(pvLabel)

    local decodedMacro = nil

    eb:SetCallback("OnTextChanged", function(w)
        local text = w:GetText()
        if text and (text:match("^MF%d+:") or text:match("^MF5:") or text:match("^MF6:") or text:match("^MF7:")) then
            local macro, err = Share:Decode(text)
            if macro then
                decodedMacro = macro
                local An = MF:GetModule("Analyzer")
                local colored = An and An:ColorizeBody(macro.body) or macro.body
                pvLabel:SetText(MF.C.gold .. macro.name .. "|r\n" .. colored)
            else
                decodedMacro = nil
                pvLabel:SetText(MF.C.red .. (err or "Erreur") .. "|r")
            end
        else
            decodedMacro = nil
            pvLabel:SetText(MF.C.grey .. L["SHARE_PREVIEW"] .. "|r")
        end
    end)

    local btnRow = AceGUI:Create("SimpleGroup")
    btnRow:SetFullWidth(true)
    btnRow:SetLayout("Flow")

    local btnEditor = AceGUI:Create("Button")
    btnEditor:SetText(L["SHARE_OPEN_EDITOR"])
    btnEditor:SetWidth(180)
    btnEditor:SetCallback("OnClick", function()
        if decodedMacro then
            local E = MF:GetModule("Editor")
            if E then
                E:OpenNew(true)
                C_Timer.After(0.1, function()
                    E:LoadContent(decodedMacro.name, decodedMacro.body, decodedMacro.icon)
                end)
            end
            f:Release()
        else
            MF:Print(MF.C.red .. L["SHARE_NO_DECODED"] .. "|r")
        end
    end)
    btnRow:AddChild(btnEditor)

    local btnCreate = AceGUI:Create("Button")
    btnCreate:SetText(L["SHARE_CREATE_DIRECT"])
    btnCreate:SetWidth(150)
    btnCreate:SetCallback("OnClick", function()
        if decodedMacro then
            local P = MF:GetModule("Profiles")
            if P then
                P:CreateNewMacro(decodedMacro.name, decodedMacro.icon, decodedMacro.body, true)
                local UI = MF:GetModule("UI")
                if UI then C_Timer.After(0.3, function() UI:Refresh() end) end
                MF:Print(MF.C.green .. format(L["SHARE_IMPORTED"], decodedMacro.name) .. "|r")
            end
            f:Release()
        else
            MF:Print(MF.C.red .. L["SHARE_NO_DECODED"] .. "|r")
        end
    end)
    btnRow:AddChild(btnCreate)

    f:AddChild(btnRow)
    f:Show()
end

---------------------------------------------------
-- Direct send via AceComm (Point 6)
---------------------------------------------------
function Share:OpenSend()
    local E = MF:GetModule("Editor")
    if not E or not E.cur then
        MF:Print(MF.C.yellow .. L["OPEN_MACRO_FIRST"] .. "|r")
        return
    end

    local f = AceGUI:Create("Frame")
    f:SetTitle("|cff00ccffMacroForge|r - " .. L["SEND_MACRO"])
    f:SetWidth(400)
    f:SetHeight(180)
    f:SetLayout("Flow")
    f:SetCallback("OnClose", function(w) w:Release() end)

    local bg = f.frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
    bg:SetPoint("TOPLEFT", f.content, -5, 5)
    bg:SetPoint("BOTTOMRIGHT", f.content, 5, -5)

    local lbl = AceGUI:Create("Label")
    lbl:SetFullWidth(true)
    lbl:SetFontObject(GameFontNormal)
    lbl:SetText(MF.C.gold .. (E.cur.name or "?") .. "|r")
    f:AddChild(lbl)

    local targetEB = AceGUI:Create("EditBox")
    targetEB:SetLabel(L["SEND_TARGET"])
    targetEB:SetFullWidth(true)
    targetEB:DisableButton(true)
    f:AddChild(targetEB)

    local btnSend = AceGUI:Create("Button")
    btnSend:SetText(L["SEND_MACRO"])
    btnSend:SetWidth(150)
    btnSend:SetCallback("OnClick", function()
        local target = targetEB:GetText()
        if not target or target == "" then
            MF:Print(MF.C.red .. L["SEND_NO_TARGET"] .. "|r")
            return
        end
        local data = {
            name = E.cur.name or "",
            icon = E.cur.icon or 134400,
            body = E.cur.body or "",
        }
        local serialized = MF:Serialize(data)
        MF:SendCommMessage("MacroForge", serialized, "WHISPER", target)
        MF:Print(MF.C.green .. format(L["SEND_SUCCESS"], target) .. "|r")
        f:Release()
    end)
    f:AddChild(btnSend)

    f:Show()
end

MF:RegisterModule("Share", Share)
