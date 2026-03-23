---------------------------------------------------
-- MacroForge — History (Ace3)
-- Save/restore macro versions in AceDB char.history
---------------------------------------------------
local _, MF_NS = ...
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local AceGUI = LibStub("AceGUI-3.0")
local History = {}

---------------------------------------------------
-- Save a snapshot before editing
---------------------------------------------------
function History:SaveSnapshot(macro)
    if not macro or not macro.index then return end
    if not MF.db then return end

    MF.db.char.history = MF.db.char.history or {}
    local key = tostring(macro.index)
    MF.db.char.history[key] = MF.db.char.history[key] or {}
    local versions = MF.db.char.history[key]

    -- Don't save duplicate of last version
    if #versions > 0 then
        local last = versions[#versions]
        if last.body == macro.body and last.name == macro.name then
            return
        end
    end

    local maxHistory = MF.db.profile.maxHistory or 10

    table.insert(versions, {
        name = macro.name or "",
        body = macro.body or "",
        icon = macro.icon or 134400,
        timestamp = date("%Y-%m-%d %H:%M:%S"),
    })

    while #versions > maxHistory do
        table.remove(versions, 1)
    end
end

---------------------------------------------------
-- Get versions for a macro index
---------------------------------------------------
function History:GetVersions(macroIndex)
    if not MF.db or not MF.db.char.history then return {} end
    return MF.db.char.history[tostring(macroIndex)] or {}
end

---------------------------------------------------
-- History Browser UI
---------------------------------------------------
function History:OpenBrowser(macroIndex)
    local versions = self:GetVersions(macroIndex)

    if #versions == 0 then
        MF:Print(MF.C.grey .. L["NO_HISTORY"] .. "|r")
        return
    end

    local f = AceGUI:Create("Frame")
    f:SetTitle("|cff00ccffMacroForge|r - " .. L["HISTORY"])
    f:SetWidth(500)
    f:SetHeight(400)
    f:SetLayout("Fill")
    f:SetCallback("OnClose", function(w) w:Release() end)

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    f:AddChild(scroll)

    local An = MF:GetModule("Analyzer")

    for i = #versions, 1, -1 do
        local v = versions[i]

        local grp = AceGUI:Create("InlineGroup")
        grp:SetFullWidth(true)
        grp:SetTitle(MF.C.gold .. "#" .. i .. "|r  " .. MF.C.grey .. v.timestamp .. "|r  " .. MF.C.white .. v.name .. "|r")
        grp:SetLayout("Flow")

        local preview = AceGUI:Create("Label")
        preview:SetFullWidth(true)
        preview:SetFontObject(GameFontNormalSmall)
        local colored = An and An:ColorizeBody(v.body) or v.body
        preview:SetText(colored)
        grp:AddChild(preview)

        local info = AceGUI:Create("Label")
        info:SetFullWidth(true)
        info:SetFontObject(GameFontNormalSmall)
        info:SetText(MF.C.grey .. format(L["CHARS"], #v.body) .. "|r")
        grp:AddChild(info)

        local btn = AceGUI:Create("Button")
        btn:SetText(L["RESTORE"])
        btn:SetWidth(100)
        btn:SetCallback("OnClick", function()
            local E = MF:GetModule("Editor")
            if E then
                E:LoadContent(v.name, v.body, v.icon)
                MF:Print(MF.C.green .. format(L["VERSION_RESTORED"], i) .. "|r")
            end
            f:Release()
        end)
        grp:AddChild(btn)

        scroll:AddChild(grp)
    end

    f:Show()
end

MF:RegisterModule("History", History)
