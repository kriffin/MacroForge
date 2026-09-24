---------------------------------------------------
-- MacroForge Bridge (dev only, not part of the addon)
-- tools/bridge.sh writes Queue.lua (MFBridgeQueue = { id, code }) and
-- presses CTRL-SHIFT-F9 (bound here to ReloadUI) twice:
--   1st reload: this file runs the query and keeps the result in MFBridgeDB
--   2nd reload: the client writes MFBridgeDB to SavedVariables, read off disk
-- Inside the query: out(...) records values, dump(v) serializes a table.
---------------------------------------------------
local MAX_DEPTH, MAX_ITEMS = 4, 300
local STALE_AFTER = 300  -- seconds

local function Dump(v, depth, seen)
    depth, seen = depth or 0, seen or {}
    local ok, t = pcall(type, v)
    if not ok then return "<secret>" end
    if t == "string" then return string.format("%q", v) end
    if t ~= "table" then
        local okS, s = pcall(tostring, v)
        return okS and s or "<secret>"
    end
    if seen[v] then return "<cycle>" end
    if depth >= MAX_DEPTH then return "{...}" end
    seen[v] = true
    local parts, n = {}, 0
    for k, val in pairs(v) do
        n = n + 1
        if n > MAX_ITEMS then table.insert(parts, "..."); break end
        table.insert(parts, "[" .. Dump(k, depth + 1, seen) .. "]=" .. Dump(val, depth + 1, seen))
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end

local reload = CreateFrame("Button", "MFBridgeReload")
reload:SetScript("OnClick", function() ReloadUI() end)

local function Run()
    MFBridgeDB = MFBridgeDB or {}
    local q = MFBridgeQueue
    if not q or not q.id or q.id == MFBridgeDB.id then return end
    -- The id is bridge.sh's `date +%s%N`: a query left behind by a run whose
    -- result never reached disk (client closed first) must not replay at the
    -- next normal login and pop the UI open
    local born = tonumber(q.id:sub(1, 10))
    if not born or time() - born > STALE_AFTER then return end
    local out = {}
    local env = setmetatable({
        out = function(...)
            local row = {}
            for i = 1, select("#", ...) do row[i] = Dump((select(i, ...))) end
            table.insert(out, table.concat(row, "\t"))
        end,
        dump = Dump,
    }, { __index = _G })
    local fn, err = loadstring(q.code, "bridge")
    local result = { id = q.id, time = date("%Y-%m-%d %H:%M:%S"), out = out }
    if not fn then
        result.error = err
    else
        setfenv(fn, env)
        local rets = { xpcall(fn, function(e) return tostring(e) .. "\n" .. debugstack(2) end) }
        if rets[1] then
            for i = 2, #rets do out[#out + 1] = "return " .. Dump(rets[i]) end
        else
            result.error = rets[2]
        end
    end
    MFBridgeDB = result
    print("|cff00ccffMF Bridge|r query " .. q.id .. (result.error and " |cffff4444failed|r" or " done"))
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
    SetOverrideBindingClick(self, true, "CTRL-SHIFT-F9", "MFBridgeReload")
    -- Give the client a moment to load spells, items and the like
    C_Timer.After(2, Run)
end)
