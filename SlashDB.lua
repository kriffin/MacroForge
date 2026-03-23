---------------------------------------------------
-- MacroForge — SlashDB
-- Complete categorized slash command database
-- Source: warcraft.wiki.gg/wiki/Macro_commands
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
MF.SlashDB = {}

-- Categories
local CAT = {
    COMBAT   = { id = "combat",   label = L["CAT_COMBAT"],    color = "|cffff4444" },
    TARGET   = { id = "target",   label = L["CAT_TARGET"],    color = "|cff00ccff" },
    PET      = { id = "pet",      label = L["CAT_PET"],       color = "|cff33aa55" },
    CHAT     = { id = "chat",     label = L["CAT_CHAT"],      color = "|cffffff33" },
    CHAR     = { id = "char",     label = L["CAT_CHAR"],      color = "|cffcc66ff" },
    GUILD    = { id = "guild",    label = L["CAT_GUILD"],     color = "|cff00ff88" },
    PARTY    = { id = "party",    label = L["CAT_PARTY"],     color = "|cffff9933" },
    SYSTEM   = { id = "system",   label = L["CAT_SYSTEM"],    color = "|cff888888" },
    PVP      = { id = "pvp",      label = L["CAT_PVP"],       color = "|cffff3333" },
    BATTLEPET = { id = "bpet",   label = L["CAT_BATTLEPET"], color = "|cff66ccff" },
    UI       = { id = "ui",       label = L["CAT_UI"],        color = "|cffffd700" },
}
MF.SlashDB.CAT = CAT

-- Command database: ["/command"] = category
local DB = {
    -- Combat
    ["/cast"]=CAT.COMBAT,["/use"]=CAT.COMBAT,["/castsequence"]=CAT.COMBAT,
    ["/castrandom"]=CAT.COMBAT,["/userandom"]=CAT.COMBAT,
    ["/startattack"]=CAT.COMBAT,["/stopattack"]=CAT.COMBAT,
    ["/stopcasting"]=CAT.COMBAT,["/stopspelltarget"]=CAT.COMBAT,
    ["/cancelaura"]=CAT.COMBAT,["/cancelform"]=CAT.COMBAT,
    ["/cancelqueuedspell"]=CAT.COMBAT,
    ["/changeactionbar"]=CAT.COMBAT,["/swapactionbar"]=CAT.COMBAT,
    ["/usetoy"]=CAT.COMBAT,

    -- Targeting
    ["/target"]=CAT.TARGET,["/targetexact"]=CAT.TARGET,
    ["/targetenemy"]=CAT.TARGET,["/targetenemyplayer"]=CAT.TARGET,
    ["/targetfriend"]=CAT.TARGET,["/targetfriendplayer"]=CAT.TARGET,
    ["/targetparty"]=CAT.TARGET,["/targetraid"]=CAT.TARGET,
    ["/targetlastenemy"]=CAT.TARGET,["/targetlastfriend"]=CAT.TARGET,
    ["/targetlasttarget"]=CAT.TARGET,
    ["/assist"]=CAT.TARGET,["/focus"]=CAT.TARGET,
    ["/clearfocus"]=CAT.TARGET,["/cleartarget"]=CAT.TARGET,

    -- Pet
    ["/petattack"]=CAT.PET,["/petfollow"]=CAT.PET,["/petstay"]=CAT.PET,
    ["/petpassive"]=CAT.PET,["/petdefensive"]=CAT.PET,["/petassist"]=CAT.PET,
    ["/petautocaston"]=CAT.PET,["/petautocastoff"]=CAT.PET,
    ["/petautocasttoggle"]=CAT.PET,["/petdismiss"]=CAT.PET,
    ["/petmoveto"]=CAT.PET,

    -- Chat (including aliases)
    ["/say"]=CAT.CHAT,["/s"]=CAT.CHAT,
    ["/yell"]=CAT.CHAT,["/y"]=CAT.CHAT,
    ["/whisper"]=CAT.CHAT,["/w"]=CAT.CHAT,["/tell"]=CAT.CHAT,["/t"]=CAT.CHAT,
    ["/reply"]=CAT.CHAT,["/r"]=CAT.CHAT,
    ["/party"]=CAT.CHAT,["/p"]=CAT.CHAT,
    ["/raid"]=CAT.CHAT,["/ra"]=CAT.CHAT,
    ["/rw"]=CAT.CHAT,
    ["/instance"]=CAT.CHAT,
    ["/emote"]=CAT.CHAT,["/e"]=CAT.CHAT,["/em"]=CAT.CHAT,["/me"]=CAT.CHAT,
    ["/guild"]=CAT.CHAT,["/g"]=CAT.CHAT,
    ["/officer"]=CAT.CHAT,["/o"]=CAT.CHAT,
    ["/battleground"]=CAT.CHAT,["/bg"]=CAT.CHAT,
    ["/afk"]=CAT.CHAT,["/dnd"]=CAT.CHAT,
    ["/announce"]=CAT.CHAT,["/chatlog"]=CAT.CHAT,["/combatlog"]=CAT.CHAT,
    ["/chatlist"]=CAT.CHAT,["/chatinvite"]=CAT.CHAT,["/chathelp"]=CAT.CHAT,
    ["/join"]=CAT.CHAT,["/leave"]=CAT.CHAT,["/csay"]=CAT.CHAT,
    ["/ban"]=CAT.CHAT,["/unban"]=CAT.CHAT,
    ["/ckick"]=CAT.CHAT,["/moderator"]=CAT.CHAT,["/unmoderator"]=CAT.CHAT,
    ["/mute"]=CAT.CHAT,["/unmute"]=CAT.CHAT,
    ["/owner"]=CAT.CHAT,["/password"]=CAT.CHAT,
    ["/resetchat"]=CAT.CHAT,

    -- Character
    ["/dismount"]=CAT.CHAR,["/equip"]=CAT.CHAR,["/equipset"]=CAT.CHAR,
    ["/equipslot"]=CAT.CHAR,["/follow"]=CAT.CHAR,["/f"]=CAT.CHAR,
    ["/friend"]=CAT.CHAR,["/removefriend"]=CAT.CHAR,
    ["/ignore"]=CAT.CHAR,["/unignore"]=CAT.CHAR,
    ["/inspect"]=CAT.CHAR,["/trade"]=CAT.CHAR,
    ["/leavevehicle"]=CAT.CHAR,["/settitle"]=CAT.CHAR,
    ["/randompet"]=CAT.CHAR,

    -- Guild
    ["/guilddemote"]=CAT.GUILD,["/guilddisband"]=CAT.GUILD,
    ["/guildinfo"]=CAT.GUILD,["/guildinvite"]=CAT.GUILD,
    ["/guildleader"]=CAT.GUILD,["/guildquit"]=CAT.GUILD,
    ["/guildmotd"]=CAT.GUILD,["/guildpromote"]=CAT.GUILD,
    ["/guildroster"]=CAT.GUILD,["/guildremove"]=CAT.GUILD,

    -- Party & Raid
    ["/invite"]=CAT.PARTY,["/uninvite"]=CAT.PARTY,["/kick"]=CAT.PARTY,
    ["/promote"]=CAT.PARTY,["/requestinvite"]=CAT.PARTY,
    ["/readycheck"]=CAT.PARTY,["/raidinfo"]=CAT.PARTY,
    ["/mainassist"]=CAT.PARTY,["/mainassistoff"]=CAT.PARTY,
    ["/maintank"]=CAT.PARTY,["/maintankoff"]=CAT.PARTY,
    ["/targetmarker"]=CAT.PARTY,["/worldmarker"]=CAT.PARTY,
    ["/clearworldmarker"]=CAT.PARTY,
    ["/ffa"]=CAT.PARTY,["/group"]=CAT.PARTY,["/master"]=CAT.PARTY,
    ["/threshold"]=CAT.PARTY,

    -- System
    ["/click"]=CAT.SYSTEM,["/run"]=CAT.SYSTEM,["/script"]=CAT.SYSTEM,
    ["/stopmacro"]=CAT.SYSTEM,["/reload"]=CAT.SYSTEM,
    ["/console"]=CAT.SYSTEM,["/logout"]=CAT.SYSTEM,["/quit"]=CAT.SYSTEM,
    ["/played"]=CAT.SYSTEM,["/time"]=CAT.SYSTEM,["/timetest"]=CAT.SYSTEM,
    ["/random"]=CAT.SYSTEM,["/roll"]=CAT.SYSTEM,
    ["/who"]=CAT.SYSTEM,["/help"]=CAT.SYSTEM,["/macrohelp"]=CAT.SYSTEM,
    ["/dump"]=CAT.SYSTEM,["/eventtrace"]=CAT.SYSTEM,["/etrace"]=CAT.SYSTEM,
    ["/framestack"]=CAT.SYSTEM,["/fstack"]=CAT.SYSTEM,
    ["/api"]=CAT.SYSTEM,["/tableinspect"]=CAT.SYSTEM,
    ["/disableaddons"]=CAT.SYSTEM,["/enableaddons"]=CAT.SYSTEM,

    -- PvP
    ["/duel"]=CAT.PVP,["/forfeit"]=CAT.PVP,["/pvp"]=CAT.PVP,
    ["/wargame"]=CAT.PVP,

    -- Battle pets
    ["/randomfavoritepet"]=CAT.BATTLEPET,["/summonpet"]=CAT.BATTLEPET,
    ["/dismisspet"]=CAT.BATTLEPET,

    -- UI panels
    ["/achievements"]=CAT.UI,["/calendar"]=CAT.UI,["/guildfinder"]=CAT.UI,
    ["/dungeonfinder"]=CAT.UI,["/loot"]=CAT.UI,["/macro"]=CAT.UI,
    ["/raidfinder"]=CAT.UI,["/share"]=CAT.UI,["/stopwatch"]=CAT.UI,
}
MF.SlashDB.DB = DB

function MF.SlashDB:IsKnown(cmd)
    return DB[cmd:lower()] ~= nil
end

function MF.SlashDB:GetCategory(cmd)
    return DB[cmd:lower()]
end

function MF.SlashDB:GetCategoryLabel(cmd)
    local cat = DB[cmd:lower()]
    return cat and cat.label or nil
end

function MF.SlashDB:GetCategoryColor(cmd)
    local cat = DB[cmd:lower()]
    return cat and cat.color or "|cffcccccc"
end

MF:RegisterModule("SlashDB", MF.SlashDB)
