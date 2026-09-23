-- Minimal fake of the WoW macro API + addon env for headless tests
StaticPopupDialogs = {}
local W = { sorted = false, combat = false, events = {}, printed = {}, timers = {} }
_G.W = W
format = string.format
strlenutf8 = function(s) local _, n = s:gsub("[^\128-\191]", ""); return n end
date = os.date
time = os.time
local acct, char = {}, {}
local function list(perChar) return perChar and char or acct end
local function resort(l) if W.sorted then table.sort(l, function(a, b) return a.name:lower() < b.name:lower() end) end end
local function locate(idx)
  if idx > 120 then return char, idx - 120 end
  return acct, idx
end
function W.reset() acct, char = {}, {}; W.bars = {}; W.printed = {}; W.combat = false; W.timers = {} end
function W.fire(ev) W.events[#W.events+1] = ev end
function GetNumMacros() return #acct, #char end
function GetMacroInfo(idx) local l, i = locate(idx); local m = l[i]; if m then return m.name, m.icon, m.body end end
function InCombatLockdown() return W.combat end
function CreateMacro(name, icon, body, perChar)
  assert(not W.combat, "CreateMacro in combat")
  local l = list(perChar); local m = { name = name, icon = icon, body = body }
  l[#l+1] = m; resort(l); W.fire("UPDATE_MACROS")
  for i, x in ipairs(l) do if x == m then return (perChar and 120 or 0) + i end end
end
function EditMacro(idx, name, icon, body)
  assert(not W.combat, "EditMacro in combat")
  local l, i = locate(idx); local m = assert(l[i], "EditMacro bad index " .. idx)
  m.name, m.icon, m.body = name or m.name, icon or m.icon, body or m.body
  resort(l); W.fire("UPDATE_MACROS")
end
function DeleteMacro(idx)
  assert(not W.combat, "DeleteMacro in combat")
  local l, i = locate(idx); local m = assert(l[i], "DeleteMacro bad index " .. idx)
  table.remove(l, i)
  for k, v in pairs(W.bars) do if v == m then W.bars[k] = nil end end
  W.fire("UPDATE_MACROS")
end
-- Put the macro currently at idx on action button k
function W.place(k, idx) local l, i = locate(idx); W.bars[k] = l[i] end
function W.barName(k) return W.bars[k] and W.bars[k].name end
function W.names(perChar) local r = {} for _, m in ipairs(list(perChar)) do r[#r+1] = m.name end return table.concat(r, ",") end
function W.get(perChar, name) for _, m in ipairs(list(perChar)) do if m.name == name then return m end end end

C_Timer = { After = function(_, fn) W.timers[#W.timers+1] = fn end,
  NewTimer = function(_, fn) W.timers[#W.timers+1] = fn; return { Cancel = function() end } end }
function W.runTimers() while #W.timers > 0 do table.remove(W.timers, 1)() end end
UnitClass = function() return "Mage", "MAGE", 8 end
UnitName = function() return "Me" end
W.spec = 62
C_SpecializationInfo = {
  GetSpecialization = function() return W.spec == 62 and 1 or (W.spec == 63 and 2 or 3) end,
  GetSpecializationInfo = function(i) local ids = {62, 63, 64}; local n = {"Arcane", "Fire", "Frost"}; return ids[i], n[i] end,
  GetNumSpecializations = function() return 3 end,
}
GetSpecializationInfoByID = function(id) local n = {[62]="Arcane",[63]="Fire",[64]="Frost"}; return id, n[id] end

local L = setmetatable({}, { __index = function(_, k) return k end })
MF = { C = setmetatable({}, { __index = function() return "" end }), modules = {} }
function MF:Print(m) W.printed[#W.printed+1] = m end
function MF:RegisterModule(n, m) self.modules[n] = m end
function MF:GetModule(n) return self.modules[n] end
function MF:RegisterMessage() end
function MF:SendMessage() end
W.registered = {}
function MF:RegisterEvent(ev, h) W.registered[ev] = h or ev end
function MF:UnregisterEvent(ev) W.registered[ev] = nil end
function W.combatEnd() W.combat = false; local h = W.registered.PLAYER_REGEN_ENABLED; if h then MF[h](MF) end end
GetAddOnMetadata = function() return "test" end
LibStub = function(name)
  if name == "AceAddon-3.0" then return { GetAddon = function() return MF end, NewAddon = function() return MF end } end
  if name == "AceLocale-3.0" then return { GetLocale = function() return L end } end
  return setmetatable({}, { __index = function() return function() end end })
end
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
geterrorhandler = function() return function(e) error(e) end end
dofile(ROOT .. "/Log.lua")
dofile(ROOT .. "/Helpers.lua")
-- Retail build by default; tests can override
function GetBuildInfo() return "12.0.1", "1", "", 120001 end
return W
