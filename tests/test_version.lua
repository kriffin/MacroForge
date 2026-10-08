-- Update notice: version announces, replies and the chat line
local W = dofile(ROOT .. "/tests/wow_stub.lua")
MF.VERSION = "7.6.1"
MF.db = { profile = {}, global = {} }
local sent = {}
function MF:SendCommMessage(prefix, msg, channel, target)
    assert(prefix == "MacroForgeVer")
    sent[#sent + 1] = channel .. ":" .. msg .. (target and ("@" .. target) or "")
end
function MF:RegisterComm() end
W.now, W.group, W.instance = 0, false, false
GetTime = function() return W.now end
IsInInstance = function() return W.instance end
IsInGuild = function() return true end
IsInGroup = function() return W.group end
IsInRaid = function() return false end

local function load()
    dofile(ROOT .. "/Version.lua")
    local V = MF.modules.Version
    V:OnInitialize()
    return V
end
local V = load()
assert(W.registered.GROUP_ROSTER_UPDATE, "announces on roster changes")

-- Versions compare as numbers, a dev build is not a version
assert(V.Compare("7.6.1", "7.6.1") == 0)
assert(V.Compare("7.10.0", "7.9.9") == 1 and V.Compare("7.9.9", "7.10.0") == -1)
assert(V.Compare("7.6", "7.6.0") == 0 and V.Compare("v8.0.0", "7.99.99") == 1)
assert(V.Compare("@project-version@", "7.6.1") == nil and V.Compare("7.6.1", nil) == nil)

-- Announce: guild at login, the group when in one, once a minute, never
-- inside an instance
V:Announce(true)
assert(#sent == 1 and sent[1] == "GUILD:V7.6.1", sent[1])
W.group = true
V:Announce()
assert(#sent == 1, "throttled")
W.now = 61
V:Announce()
assert(#sent == 3 and sent[2] == "GUILD:V7.6.1" and sent[3] == "PARTY:V7.6.1", sent[3])
W.instance = true; W.now = 200
V:Announce()
assert(#sent == 3, "nothing from inside an instance")
W.instance = false

-- A newer version heard: one chat line per session, remembered
V:OnComm("MacroForgeVer", "V7.7.0", "GUILD", "Bob-Realm")
assert(#W.printed == 1 and MF.db.global.newestVersion == "7.7.0")
V:OnComm("MacroForgeVer", "V7.7.0", "PARTY", "Carl")
assert(#W.printed == 1, "once per session")
V:OnComm("MacroForgeVer", "V7.8.0", "GUILD", "Carl")
assert(#W.printed == 2 and MF.db.global.newestVersion == "7.8.0", "an even newer one is said")
V:OnComm("MacroForgeVer", "V7.7.5", "GUILD", "Dan")
assert(#W.printed == 2, "not an older one")
-- Absurd versions are not believed
V:OnComm("MacroForgeVer", "V99.0.0", "GUILD", "Troll")
assert(#W.printed == 2 and MF.db.global.newestVersion == "7.8.0")
-- Garbage and other prefixes are ignored
V:OnComm("MacroForgeVer", "hello", "GUILD", "x")
V:OnComm("MacroForgeVer", "V7", "GUILD", "x")
V:OnComm("Other", "V9.9.9", "GUILD", "x")
assert(#W.printed == 2 and #sent == 3)

-- Our own version: nothing. An older one: ours whispered back, once per
-- player, after a delay; a whispered old version gets no reply
V:OnComm("MacroForgeVer", "V7.6.1", "GUILD", "Me")
V:OnComm("MacroForgeVer", "V7.5.0", "GUILD", "Old-Realm")
assert(#sent == 3, "reply is delayed")
W.runTimers()
assert(#sent == 4 and sent[4] == "WHISPER:V7.6.1@Old-Realm", sent[4])
V:OnComm("MacroForgeVer", "V7.5.0", "GUILD", "Old-Realm")
W.runTimers()
assert(#sent == 4, "told once")
V:OnComm("MacroForgeVer", "V7.5.0", "WHISPER", "Other")
W.runTimers()
assert(#sent == 4, "no reply to a whisper")

-- Login: the version heard last time is repeated until we catch up
V = load(); W.printed = {}
V:LoginCheck()
assert(#W.printed == 1 and MF.db.global.newestVersion == "7.8.0")
V:LoginCheck()
assert(#W.printed == 1, "once per session")
MF.VERSION = "7.8.0"
V = load(); W.printed = {}
V:LoginCheck()
assert(#W.printed == 0 and MF.db.global.newestVersion == nil, "updated: forgotten")

-- Turned off: nothing printed, the version is still remembered
MF.db.profile.updateNotice = false
V = load(); W.printed = {}
V:OnComm("MacroForgeVer", "V7.9.0", "GUILD", "Bob")
V:LoginCheck()
assert(#W.printed == 0 and MF.db.global.newestVersion == "7.9.0")

-- A dev build announces nothing
MF.VERSION = "@project-version@"
V = load(); W.now = 1000
V:Announce(true)
assert(#sent == 4)
print("ok version: compare, announce, reply, notice")
