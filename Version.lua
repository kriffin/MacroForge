---------------------------------------------------
-- MacroForge — Update notice
-- Everyone announces their version to the guild and the group (login,
-- roster changes). Hearing a newer one prints a chat line, once per
-- session, and again at every login until the addon is updated. Hearing
-- an older one whispers ours back, so a player who just logged in with
-- an old version learns about the update from anyone up to date.
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local V = {}

local PREFIX = "MacroForgeVer"
local told = {}          -- sender -> true once our version went to them
local announcedAt = -math.huge
local noticed            -- the newer version already printed this session

-- "7.6.1" -> { 7, 6, 1 }; nil for a dev build ("@project-version@")
function V.Parse(s)
    if type(s) ~= "string" then return nil end
    local a, b, c = s:match("^v?(%d+)%.(%d+)%.?(%d*)")
    if not a then return nil end
    return { tonumber(a), tonumber(b), tonumber(c) or 0 }
end

-- -1, 0 or 1; nil when either side is not a version
function V.Compare(a, b)
    local x, y = V.Parse(a), V.Parse(b)
    if not x or not y then return nil end
    for i = 1, 3 do
        if x[i] ~= y[i] then return x[i] < y[i] and -1 or 1 end
    end
    return 0
end

-- A version worth believing: at most one major ahead of ours
local function Plausible(s)
    local v, mine = V.Parse(s), V.Parse(MF.VERSION)
    return v and mine and v[1] <= mine[1] + 1 and v[2] < 100 and v[3] < 100 or false
end

function V:Enabled()
    return MF.db and MF.db.profile.updateNotice ~= false
end

local function Say(newest)
    MF:Print(MF.C.yellow .. L["UPDATE_AVAILABLE"]:format(MF.C.cyan .. newest .. MF.C.yellow, MF.VERSION) .. "|r")
end

-- A newer version heard: remembered, printed once per session
function V:Noticed(version)
    if V.Compare(version, MF.VERSION) ~= 1 or not Plausible(version) then return false end
    local g = MF.db.global
    if V.Compare(version, g.newestVersion or "0.0.0") == 1 then g.newestVersion = version end
    if self:Enabled() and (not noticed or V.Compare(version, noticed) == 1) then
        noticed = version
        Say(version)
    end
    return true
end

-- At login: the newest version heard before, while we are still behind
function V:LoginCheck()
    local g = MF.db.global
    if g.newestVersion and V.Compare(g.newestVersion, MF.VERSION) ~= 1 then g.newestVersion = nil end
    if g.newestVersion and self:Enabled() and not noticed then
        noticed = g.newestVersion
        Say(g.newestVersion)
    end
end

-- Addon messages are refused inside instances (12.0), and a dev build
-- has nothing to announce
local function CanSend()
    return V.Parse(MF.VERSION) ~= nil and not (IsInInstance and IsInInstance())
end

function V:Send(channel, target)
    if not CanSend() then return end
    pcall(MF.SendCommMessage, MF, PREFIX, "V" .. MF.VERSION, channel, target)
end

-- Guild and group, at most once a minute (rosters change often)
function V:Announce(force)
    local now = GetTime()
    if not force and now - announcedAt < 60 then return end
    if not CanSend() then return end
    announcedAt = now
    if IsInGuild and IsInGuild() then self:Send("GUILD") end
    if IsInGroup and IsInGroup() then self:Send(IsInRaid() and "RAID" or "PARTY") end
end

function V:OnComm(prefix, message, distribution, sender)
    if prefix ~= PREFIX or type(message) ~= "string" then return end
    local version = message:match("^V(%d+%.%d+%.%d+)$")
    if not version then return end
    local cmp = V.Compare(version, MF.VERSION)
    if cmp == 1 then
        self:Noticed(version)
    elseif cmp == -1 and distribution ~= "WHISPER" and sender and not told[sender] then
        -- They are behind: tell them once, a few seconds later so a whole
        -- guild does not answer in the same instant
        told[sender] = true
        C_Timer.After(math.random(2, 6), function() V:Send("WHISPER", sender) end)
    end
end

function V:OnInitialize()
    MF:RegisterComm(PREFIX, function(...) V:OnComm(...) end)
    MF:RegisterEvent("GROUP_ROSTER_UPDATE", function() V:Announce() end)
    -- After the login chatter
    MF:RegisterMessage("MF_LOGIN", function()
        C_Timer.After(8, function()
            V:LoginCheck()
            V:Announce(true)
        end)
    end)
end

MF:RegisterModule("Version", V)
