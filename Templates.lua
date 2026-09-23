---------------------------------------------------
-- MacroForge — Templates
-- Multi-class macro templates, auto-detect player class
---------------------------------------------------
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
MF.Templates = {}

---------------------------------------------------
-- Categories
---------------------------------------------------
MF.Templates.CATEGORIES = {
    { id = "universal",  name = "|cffffffff" .. L["TPL_CAT_UNIVERSAL"] .. "|r" },
    { id = "interrupt",  name = "|cff33ccff" .. L["TPL_CAT_INTERRUPT"] .. "|r" },
    { id = "offensive",  name = "|cffff6633" .. L["TPL_CAT_OFFENSIVE"] .. "|r" },
    { id = "defensive",  name = "|cff66ccff" .. L["TPL_CAT_DEFENSIVE"] .. "|r" },
    { id = "cc",         name = "|cffcc33ff" .. L["TPL_CAT_CC"] .. "|r" },
    { id = "utility",    name = "|cffaaaaaa" .. L["TPL_CAT_UTILITY"] .. "|r" },
    { id = "pvp",        name = "|cffff3333" .. L["TPL_CAT_PVP"] .. "|r" },
    { id = "tank",       name = "|cff3399ff" .. L["TPL_CAT_TANK"] .. "|r" },
    { id = "healer",     name = "|cff33ff99" .. L["TPL_CAT_HEALER"] .. "|r" },
}

---------------------------------------------------
-- Class Colors (for display)
---------------------------------------------------
local CLASS_COLORS = {
    WARRIOR     = "|cffc79c6e",
    PALADIN     = "|cfff58cba",
    HUNTER      = "|cffabd473",
    ROGUE       = "|cfffff569",
    PRIEST      = "|cffffffff",
    DEATHKNIGHT = "|cffc41f3b",
    SHAMAN      = "|cff0070de",
    MAGE        = "|cff69ccf0",
    WARLOCK     = "|cff9482c9",
    MONK        = "|cff00ff96",
    DRUID       = "|cffff7d0a",
    DEMONHUNTER = "|cffa330c9",
    EVOKER      = "|cff33937f",
}

---------------------------------------------------
-- Template Data — Universal
---------------------------------------------------
local UNIVERSAL = {
    {
        category = "universal", name = "Mouseover Cast",
        description = L["TPL_DESC_MOUSEOVER_HEAL_CAST"],
        body = "#showtooltip\n/cast [@mouseover,help,nodead][] {ph:SORT}",
    },
    {
        category = "universal", name = "Focus Interrupt",
        description = L["TPL_DESC_FOCUS_INTERRUPT"],
        body = "#showtooltip\n/cast [@focus,harm,nodead][] {ph:SORT}",
    },
    {
        category = "universal", name = "Mouseover Harm",
        description = L["TPL_DESC_MOUSEOVER_HARM"],
        body = "#showtooltip\n/cast [@mouseover,harm,nodead][] {ph:SORT}",
    },
    {
        category = "universal", name = "Trinket 1",
        description = L["TPL_DESC_TRINKET_1"],
        body = "#showtooltip\n/use 13",
    },
    {
        category = "universal", name = "Trinket 2",
        description = L["TPL_DESC_TRINKET_2"],
        body = "#showtooltip\n/use 14",
    },
    {
        category = "universal", name = "Mount Smart",
        description = L["TPL_DESC_MOUNT_SMART"],
        body = "#showtooltip\n/dismount [mounted]\n/cast [advflyable] {ph:MONTURE_VOL}; {ph:MONTURE_SOL}",
    },
    {
        category = "universal", name = "Cancelaura+Cast",
        description = L["TPL_DESC_CANCELAURA_CAST"],
        body = "#showtooltip\n/cancelaura {ph:NOM_BUFF}\n/cast {ph:SORT}",
    },
    {
        category = "universal", name = "Attack + Cast",
        description = L["TPL_DESC_STARTATTACK_CAST"],
        body = "#showtooltip\n/startattack\n/cast {ph:SORT}",
    },
    {
        category = "universal", name = "Shift/Ctrl/Alt",
        description = L["TPL_DESC_MOD_SHIFT_CTRL_ALT"],
        body = "#showtooltip\n/cast [mod:shift] {ph:SORT_SHIFT}; [mod:ctrl] {ph:SORT_CTRL}; {ph:SORT_NORMAL}",
    },
    {
        category = "universal", name = "Cast Sequence",
        description = L["TPL_DESC_CAST_SEQUENCE"],
        body = "#showtooltip\n/castsequence reset=target {ph:SORT1}, {ph:SORT2}, {ph:SORT3}",
    },
    {
        category = "universal", name = "Stopcast + Cast",
        description = L["TPL_DESC_STOPCASTING_CAST"],
        body = "#showtooltip\n/stopcasting\n/cast {ph:SORT}",
    },
    {
        category = "utility", name = "Focus Set/Clear",
        description = L["TPL_DESC_FOCUS_SET_CLEAR"],
        body = "/focus [@focus,exists] [nomod]\n/clearfocus [@focus,exists] [mod:shift]",
    },
    {
        category = "pvp", name = "Arena Target 1",
        description = L["TPL_DESC_ARENA_TARGET_1"],
        body = "#showtooltip\n/cast [@arena1] {ph:SORT}",
    },
    {
        category = "pvp", name = "Arena Target 2",
        description = L["TPL_DESC_ARENA_TARGET_2"],
        body = "#showtooltip\n/cast [@arena2] {ph:SORT}",
    },
    {
        category = "pvp", name = "Arena Target 3",
        description = L["TPL_DESC_ARENA_TARGET_3"],
        body = "#showtooltip\n/cast [@arena3] {ph:SORT}",
    },
    {
        category = "pvp", name = "PvP Trinket",
        description = L["TPL_DESC_PVP_TRINKET"],
        body = "#showtooltip\n/use 14",
    },
    {
        category = "healer", name = "Mouseover Heal",
        description = L["TPL_DESC_MOUSEOVER_HEAL"],
        body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] {ph:SORT_HEAL}",
    },
    {
        category = "healer", name = "Dispel Mouseover",
        description = L["TPL_DESC_DISPEL_MOUSEOVER"],
        body = "#showtooltip\n/cast [@mouseover,help,nodead][] {ph:SORT_DISPEL}",
    },
    {
        category = "tank", name = "Taunt Mouseover",
        description = L["TPL_DESC_TAUNT_MOUSEOVER"],
        body = "#showtooltip\n/cast [@mouseover,harm,nodead][] {ph:SORT_TAUNT}",
    },
    {
        category = "tank", name = "Defensive + Mod",
        description = L["TPL_DESC_DEFENSIVE_MOD"],
        body = "#showtooltip\n/cast [mod:shift] {ph:GROS_DEF}; {ph:PETIT_DEF}",
    },
}

---------------------------------------------------
-- Template Data — Class-Specific
---------------------------------------------------
local CLASS_TEMPLATES = {
    ROGUE = {
        {
            category = "interrupt", name = "Kick Priority",
            description = L["TPL_DESC_ROGUE_KICK_PRIORITY"],
            body = "#showtooltip\n/cast [mod:shift,@focus,harm,nodead][mod:shift,@mouseover,harm,nodead][mod:shift] {spell:1776:Gouge}\n/cast [mod:ctrl,@focus,harm,nodead][mod:ctrl] {spell:408:Kidney Shot}\n/cast [nomod,@focus,harm,nodead][nomod,@mouseover,harm,nodead][nomod] {spell:1766:Kick}",
        },
        {
            category = "offensive", name = "Opener Burst",
            description = L["TPL_DESC_ROGUE_OPENER_BURST"],
            body = "#showtooltip {spell:185313:Shadow Dance}\n/startattack\n/use 13\n/cast {spell:212283:Symbols of Death}\n/cast {spell:121471:Shadow Blades}\n/cast {spell:185313:Shadow Dance}\n/cast {spell:185438:Shadowstrike}",
        },
        {
            category = "offensive", name = "Builder Smart",
            description = L["TPL_DESC_ROGUE_BUILDER_SMART"],
            body = "#showtooltip\n/cast [stealth] {spell:185438:Shadowstrike}; {spell:53:Backstab}",
        },
        {
            category = "offensive", name = "Finisher Multi",
            description = L["TPL_DESC_ROGUE_FINISHER_MULTI"],
            body = "#showtooltip\n/cast [mod:shift,@focus,harm,nodead][mod:shift] {spell:408:Kidney Shot}\n/cast [mod:ctrl] {spell:315496:Slice and Dice}\n/cast [nomod] {spell:196819:Eviscerate}",
        },
        {
            category = "cc", name = "CC Smart",
            description = L["TPL_DESC_ROGUE_CC_SMART"],
            body = "#showtooltip\n/cast [stealth] {spell:1833:Cheap Shot}; {spell:2094:Blind}",
        },
        {
            category = "defensive", name = "Defensives",
            description = L["TPL_DESC_ROGUE_DEFENSIFS"],
            body = "#showtooltip\n/cast [mod:shift] {spell:31224:Cloak of Shadows}\n/cast [mod:ctrl] {spell:1966:Feint}\n/cast [nomod] {spell:5277:Evasion}",
        },
        {
            category = "defensive", name = "Vanish",
            description = L["TPL_DESC_ROGUE_VANISH"],
            body = "#showtooltip {spell:1856:Vanish}\n/stopattack\n/cast {spell:1856:Vanish}",
        },
    },
    WARRIOR = {
        {
            category = "interrupt", name = "Pummel Priority",
            description = L["TPL_DESC_WARRIOR_PUMMEL_PRIORITY"],
            body = "#showtooltip\n/cast [mod:shift] {spell:5246:Intimidating Shout}\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:6552:Pummel}",
        },
        {
            category = "offensive", name = "Charge + Attack",
            description = L["TPL_DESC_WARRIOR_CHARGE_ATTACK"],
            body = "#showtooltip {spell:100:Charge}\n/startattack\n/cast {spell:100:Charge}",
        },
        {
            category = "defensive", name = "Def Multi",
            description = L["TPL_DESC_WARRIOR_DEF_MULTI"],
            body = "#showtooltip\n/cast [mod:shift] {spell:184364:Enraged Regeneration}\n/cast [mod:ctrl] {spell:97462:Rallying Cry}\n/cast [nomod] {spell:871:Shield Wall}",
        },
    },
    PALADIN = {
        {
            category = "interrupt", name = "Rebuke Priority",
            description = L["TPL_DESC_PALADIN_REBUKE_PRIORITY"],
            body = "#showtooltip\n/cast [mod:shift,@focus,harm,nodead][mod:shift] {spell:853:Hammer of Justice}\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:96231:Rebuke}",
        },
        {
            category = "healer", name = "Heal Smart",
            description = L["TPL_DESC_PALADIN_HEAL_SMART"],
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] {spell:82326:Holy Light}",
        },
        {
            category = "defensive", name = "Bubble + Cancel",
            description = L["TPL_DESC_PALADIN_BUBBLE_CANCEL"],
            body = "#showtooltip {spell:642:Divine Shield}\n/cast [nomod] {spell:642:Divine Shield}\n/cancelaura [mod:shift] {spell:642:Divine Shield}",
        },
    },
    MAGE = {
        {
            category = "interrupt", name = "CS Priority",
            description = L["TPL_DESC_MAGE_COUNTERSPELL_PRIORITY"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:2139:Counterspell}",
        },
        {
            category = "cc", name = "Polymorph Focus",
            description = L["TPL_DESC_MAGE_POLYMORPH_FOCUS"],
            body = "#showtooltip {spell:118:Polymorph}\n/cast [@focus,exists,nodead][mod:shift] {spell:118:Polymorph}",
        },
        {
            category = "defensive", name = "Ice Block Cancel",
            description = L["TPL_DESC_MAGE_ICE_BLOCK_CANCEL"],
            body = "#showtooltip {spell:45438:Ice Block}\n/cast [nomod] {spell:45438:Ice Block}\n/cancelaura [mod:shift] {spell:45438:Ice Block}",
        },
    },
    HUNTER = {
        {
            category = "interrupt", name = "Counter Shot",
            description = L["TPL_DESC_HUNTER_COUNTER_SHOT_PRIORITY"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:147362:Counter Shot}",
        },
        {
            category = "utility", name = "Pet Control",
            description = L["TPL_DESC_HUNTER_PET_CONTROL"],
            body = "#showtooltip\n/petpassive [mod:shift]\n/petfollow [mod:ctrl]\n/petattack [nomod]",
        },
        {
            category = "cc", name = "Trap Mouseover",
            description = L["TPL_DESC_HUNTER_TRAP_MOUSEOVER"],
            body = "#showtooltip {spell:187650:Freezing Trap}\n/cast [@cursor] {spell:187650:Freezing Trap}",
        },
    },
    PRIEST = {
        {
            category = "healer", name = "Heal Mouseover",
            description = L["TPL_DESC_PRIEST_HEAL_MOUSEOVER"],
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] {spell:2061:Flash Heal}",
        },
        {
            category = "healer", name = "Dispel Smart",
            description = L["TPL_DESC_PRIEST_DISPEL_SMART"],
            body = "#showtooltip\n/cast [@mouseover,help,nodead][] {spell:213634:Purify Disease}",
        },
        {
            category = "defensive", name = "Fade + Shield",
            description = L["TPL_DESC_PRIEST_FADE_SHIELD"],
            body = "#showtooltip\n/cast [mod:shift,@player] {spell:17:Power Word: Shield}\n/cast [nomod] {spell:586:Fade}",
        },
    },
    DRUID = {
        {
            category = "interrupt", name = "Skull Bash",
            description = L["TPL_DESC_DRUID_SKULL_BASH_PRIORITY"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:106839:Skull Bash}",
        },
        {
            category = "healer", name = "Rejuv Mouseover",
            description = L["TPL_DESC_DRUID_REJUV_MOUSEOVER"],
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] {spell:774:Rejuvenation}",
        },
        {
            category = "utility", name = "Cancel Form+Cast",
            description = L["TPL_DESC_DRUID_FORM_CANCEL_CAST"],
            body = "#showtooltip\n/cancelform [form:1/2/3/4]\n/cast {ph:SORT}",
        },
    },
    DEATHKNIGHT = {
        {
            category = "interrupt", name = "Mind Freeze",
            description = L["TPL_DESC_DEATHKNIGHT_MIND_FREEZE_PRIORITY"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:47528:Mind Freeze}",
        },
        {
            category = "offensive", name = "Grip + Attack",
            description = L["TPL_DESC_DEATHKNIGHT_DEATH_GRIP_ATTACK"],
            body = "#showtooltip {spell:49576:Death Grip}\n/startattack\n/cast {spell:49576:Death Grip}",
        },
    },
    SHAMAN = {
        {
            category = "interrupt", name = "Wind Shear",
            description = L["TPL_DESC_SHAMAN_WIND_SHEAR_PRIORITY"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:57994:Wind Shear}",
        },
        {
            category = "healer", name = "Healing Surge MO",
            description = L["TPL_DESC_SHAMAN_HEALING_SURGE_MO"],
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] {spell:8004:Healing Surge}",
        },
    },
    WARLOCK = {
        {
            category = "interrupt", name = "Spelllock Pet",
            description = L["TPL_DESC_WARLOCK_SPELLLOCK_PET"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][] {spell:19647:Spell Lock}",
        },
        {
            category = "utility", name = "Pet Sacrifice",
            description = L["TPL_DESC_WARLOCK_PET_SACRIFICE"],
            body = "#showtooltip\n/cast [mod:shift] {spell:108416:Dark Pact}\n/cast [nomod] {spell:108503:Grimoire of Sacrifice}",
        },
    },
    MONK = {
        {
            category = "interrupt", name = "Spear Hand",
            description = L["TPL_DESC_MONK_SPEAR_HAND_PRIORITY"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:116705:Spear Hand Strike}",
        },
        {
            category = "healer", name = "Vivify MO",
            description = L["TPL_DESC_MONK_VIVIFY_MO"],
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] {spell:116670:Vivify}",
        },
    },
    DEMONHUNTER = {
        {
            category = "interrupt", name = "Disrupt Priority",
            description = L["TPL_DESC_DEMONHUNTER_DISRUPT_PRIORITY"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:183752:Disrupt}",
        },
        {
            category = "offensive", name = "Fel Rush+Attack",
            description = L["TPL_DESC_DEMONHUNTER_FEL_RUSH_ATTACK"],
            body = "#showtooltip {spell:195072:Fel Rush}\n/startattack\n/cast {spell:195072:Fel Rush}",
        },
    },
    EVOKER = {
        {
            category = "interrupt", name = "Quell Priority",
            description = L["TPL_DESC_EVOKER_QUELL_PRIORITY"],
            body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:351338:Quell}",
        },
        {
            category = "healer", name = "Dream Breath MO",
            description = L["TPL_DESC_EVOKER_DREAM_BREATH_MO"],
            body = "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] {spell:355936:Dream Breath}",
        },
    },
}

-- WoW Forever (vanilla spells). Names and descriptions are localized:
-- the name becomes the macro name. flavor = "forever" hides them on retail.
local FOREVER_TEMPLATES = {
    WARRIOR = {
        { flavor = "forever", category = "offensive", name = L["TPL_N_WAR_CHARGE"], description = L["TPL_D_WAR_CHARGE"],
          body = "#showtooltip\n/cast [stance:1] {spell:100:Charge}; [stance:3] {spell:20252:Intercept}; {spell:2457:Battle Stance}" },
        { flavor = "forever", category = "interrupt", name = L["TPL_N_WAR_KICK"], description = L["TPL_D_WAR_KICK"],
          body = "#showtooltip\n/cast [stance:3,@focus,harm,nodead][stance:3] {spell:6552:Pummel}; [@focus,harm,nodead][] {spell:72:Shield Bash}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_WAR_OVERPOWER"], description = L["TPL_D_WAR_OVERPOWER"],
          body = "#showtooltip {spell:7384:Overpower}\n/cast [stance:1] {spell:7384:Overpower}; {spell:2457:Battle Stance}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_WAR_EXECUTE"], description = L["TPL_D_WAR_EXECUTE"],
          body = "#showtooltip {spell:5308:Execute}\n/cast [stance:2] {spell:2457:Battle Stance}; {spell:5308:Execute}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_WAR_HS"], description = L["TPL_D_WAR_HS"],
          body = "#showtooltip\n/startattack\n/cast [mod:shift] {spell:845:Cleave}; {spell:78:Heroic Strike}" },
        { flavor = "forever", category = "tank", name = L["TPL_N_WAR_TAUNT"], description = L["TPL_D_WAR_TAUNT"],
          body = "#showtooltip\n/cast [mod:shift,@mouseover,harm,nodead][mod:shift] {spell:694:Mocking Blow}; [@mouseover,harm,nodead][] {spell:355:Taunt}" },
        { flavor = "forever", category = "defensive", name = L["TPL_N_WAR_WALL"], description = L["TPL_D_WAR_WALL"],
          body = "#showtooltip\n/cast [mod:shift] {spell:12975:Last Stand}; [stance:2] {spell:871:Shield Wall}; {spell:71:Defensive Stance}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_WAR_RAGE"], description = L["TPL_D_WAR_RAGE"],
          body = "#showtooltip\n/cast [stance:3] {spell:18499:Berserker Rage}; {spell:2687:Bloodrage}" },
        { flavor = "forever", category = "pvp", name = L["TPL_N_WAR_HAMSTRING"], description = L["TPL_D_WAR_HAMSTRING"],
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] {spell:1715:Hamstring}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_WAR_SHOUTS"], description = L["TPL_D_WAR_SHOUTS"],
          body = "#showtooltip\n/cast [mod:shift] {spell:1160:Demoralizing Shout}; {spell:6673:Battle Shout}" },
        { flavor = "forever", category = "tank", name = L["TPL_N_WAR_THREAT"], description = L["TPL_D_WAR_THREAT"],
          body = "#showtooltip\n/startattack\n/cast [stance:2] {spell:6572:Revenge}\n/cast {spell:7386:Sunder Armor}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_WAR_SPEC"], description = L["TPL_D_WAR_SPEC"],
          body = "#showtooltip\n/cast [known:12294] {spell:12294:Mortal Strike}; [known:23881] {spell:23881:Bloodthirst}; {spell:23922:Shield Slam}" },
        { flavor = "forever", category = "pvp", name = L["TPL_N_WAR_DISARM"], description = L["TPL_D_WAR_DISARM"],
          body = "#showtooltip\n/cast [@focus,harm,nodead][] {spell:676:Disarm}" },
        { flavor = "forever", category = "cc", name = L["TPL_N_WAR_FEAR"], description = L["TPL_D_WAR_FEAR"],
          body = "#showtooltip {spell:5246:Intimidating Shout}\n/stopattack\n/cast {spell:5246:Intimidating Shout}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_WAR_AOE"], description = L["TPL_D_WAR_AOE"],
          body = "#showtooltip\n/cast [mod:shift] {spell:845:Cleave}; [stance:1] {spell:6343:Thunder Clap}; {spell:2457:Battle Stance}" },
    },
    PALADIN = {
        { flavor = "forever", category = "cc", name = L["TPL_N_PAL_HOJ"], description = L["TPL_D_PAL_HOJ"],
          body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:853:Hammer of Justice}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_PAL_FLASH"], description = L["TPL_D_PAL_FLASH"],
          body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:19750:Flash of Light}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_PAL_HOLY"], description = L["TPL_D_PAL_HOLY"],
          body = "#showtooltip\n/cast [mod:shift,@player][@mouseover,help,nodead][help,nodead][@player] {spell:635:Holy Light}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_PAL_CLEANSE"], description = L["TPL_D_PAL_CLEANSE"],
          body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:4987:Cleanse}" },
        { flavor = "forever", category = "defensive", name = L["TPL_N_PAL_BUBBLE"], description = L["TPL_D_PAL_BUBBLE"],
          body = "#showtooltip\n/stopcasting\n/cast [mod:shift,@player] {spell:633:Lay on Hands}; {spell:642:Divine Shield}" },
        { flavor = "forever", category = "defensive", name = L["TPL_N_PAL_BOP"], description = L["TPL_D_PAL_BOP"],
          body = "#showtooltip\n/cast [mod:shift,@mouseover,help,nodead][mod:shift] {spell:1044:Blessing of Freedom}; [@mouseover,help,nodead][] {spell:1022:Blessing of Protection}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_PAL_SEAL"], description = L["TPL_D_PAL_SEAL"],
          body = "#showtooltip {spell:20271:Judgement}\n/castsequence reset=8 {spell:20154:Seal of Righteousness}, {spell:20271:Judgement}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_PAL_BLESS"], description = L["TPL_D_PAL_BLESS"],
          body = "#showtooltip\n/cast [mod:shift,@mouseover,help,nodead][mod:shift] {spell:19740:Blessing of Might}; [mod:ctrl,@mouseover,help,nodead][mod:ctrl] {spell:19742:Blessing of Wisdom}; [@mouseover,help,nodead][] {spell:20217:Blessing of Kings}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_PAL_SALV"], description = L["TPL_D_PAL_SALV"],
          body = "#showtooltip\n/cast [mod:shift,@mouseover,help,nodead][mod:shift] {spell:6940:Blessing of Sacrifice}; [@mouseover,help,nodead][] {spell:1038:Blessing of Salvation}" },
        { flavor = "forever", category = "tank", name = L["TPL_N_PAL_CONSEC"], description = L["TPL_D_PAL_CONSEC"],
          body = "#showtooltip {spell:26573:Consecration}\n/startattack\n/cast {spell:26573:Consecration}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_PAL_SHOCK"], description = L["TPL_D_PAL_SHOCK"],
          body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead] {spell:20473:Holy Shock}; [@mouseover,harm,nodead][harm] {spell:20473:Holy Shock}" },
        { flavor = "forever", category = "cc", name = L["TPL_N_PAL_REPENT"], description = L["TPL_D_PAL_REPENT"],
          body = "#showtooltip\n/cast [@focus,harm,nodead][] {spell:20066:Repentance}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_PAL_UNDEAD"], description = L["TPL_D_PAL_UNDEAD"],
          body = "#showtooltip\n/cast [mod:shift] {spell:2812:Holy Wrath}; {spell:879:Exorcism}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_PAL_HOW"], description = L["TPL_D_PAL_HOW"],
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] {spell:24275:Hammer of Wrath}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_PAL_PURIFY"], description = L["TPL_D_PAL_PURIFY"],
          body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:1152:Purify}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_PAL_CRUSADER"], description = L["TPL_D_PAL_CRUSADER"],
          body = "#showtooltip {spell:20271:Judgement}\n/castsequence reset=8 {spell:21082:Seal of the Crusader}, {spell:20271:Judgement}" },
    },
    HUNTER = {
        { flavor = "forever", category = "offensive", name = L["TPL_N_HUN_OPEN"], description = L["TPL_D_HUN_OPEN"],
          body = "#showtooltip {spell:1130:Hunter's Mark}\n/cast [@target,harm,nodead] {spell:1130:Hunter's Mark}\n/petattack\n/cast !{spell:75:Auto Shot}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_HUN_PET"], description = L["TPL_D_HUN_PET"],
          body = "#showtooltip\n/cast [nopet] {spell:883:Call Pet}; [@pet,dead] {spell:982:Revive Pet}; {spell:136:Mend Pet}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_HUN_PETCTL"], description = L["TPL_D_HUN_PETCTL"],
          body = "/petattack [nomod,harm]\n/petfollow [mod:shift]\n/petpassive [mod:ctrl]" },
        { flavor = "forever", category = "defensive", name = L["TPL_N_HUN_FD"], description = L["TPL_D_HUN_FD"],
          body = "#showtooltip {spell:5384:Feign Death}\n/stopattack\n/petfollow\n/cast {spell:5384:Feign Death}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_HUN_ASPECT"], description = L["TPL_D_HUN_ASPECT"],
          body = "#showtooltip\n/cast [mod:shift] {spell:13163:Aspect of the Monkey}; [combat] {spell:13165:Aspect of the Hawk}; {spell:5118:Aspect of the Cheetah}" },
        { flavor = "forever", category = "cc", name = L["TPL_N_HUN_SCATTER"], description = L["TPL_D_HUN_SCATTER"],
          body = "#showtooltip\n/cast [mod:shift,@focus,harm,nodead][mod:shift] {spell:5116:Concussive Shot}; [@focus,harm,nodead][] {spell:19503:Scatter Shot}" },
        { flavor = "forever", category = "pvp", name = L["TPL_N_HUN_TRANQ"], description = L["TPL_D_HUN_TRANQ"],
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][@focus,harm,nodead][] {spell:19801:Tranquilizing Shot}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_HUN_AIMED"], description = L["TPL_D_HUN_AIMED"],
          body = "#showtooltip {spell:19434:Aimed Shot}\n/cast {spell:19434:Aimed Shot}\n/cast !{spell:75:Auto Shot}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_HUN_SHOTS"], description = L["TPL_D_HUN_SHOTS"],
          body = "#showtooltip\n/cast [mod:shift] {spell:1978:Serpent Sting}; {spell:3044:Arcane Shot}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_HUN_MULTI"], description = L["TPL_D_HUN_MULTI"],
          body = "#showtooltip\n/cast [mod:shift] {spell:1510:Volley}; {spell:2643:Multi-Shot}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_HUN_MELEE"], description = L["TPL_D_HUN_MELEE"],
          body = "#showtooltip\n/startattack\n/cast [mod:shift] {spell:2974:Wing Clip}; {spell:2973:Raptor Strike}" },
        { flavor = "forever", category = "defensive", name = L["TPL_N_HUN_DISENGAGE"], description = L["TPL_D_HUN_DISENGAGE"],
          body = "#showtooltip {spell:781:Disengage}\n/petattack\n/cast {spell:781:Disengage}" },
        { flavor = "forever", category = "cc", name = L["TPL_N_HUN_TRAPS"], description = L["TPL_D_HUN_TRAPS"],
          body = "#showtooltip\n/cast [mod:shift] {spell:13795:Immolation Trap}; [mod:ctrl] {spell:13813:Explosive Trap}; {spell:1499:Freezing Trap}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_HUN_RAPID"], description = L["TPL_D_HUN_RAPID"],
          body = "#showtooltip {spell:3045:Rapid Fire}\n/petattack\n/cast {spell:3045:Rapid Fire}" },
        { flavor = "forever", category = "cc", name = L["TPL_N_HUN_INTIM"], description = L["TPL_D_HUN_INTIM"],
          body = "#showtooltip\n/cast [@focus,harm,nodead][] {spell:19577:Intimidation}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_HUN_FEED"], description = L["TPL_D_HUN_FEED"],
          body = "#showtooltip\n/cast [mod:shift] {spell:1462:Beast Lore}; {spell:6991:Feed Pet}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_HUN_DISTRACT"], description = L["TPL_D_HUN_DISTRACT"],
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] {spell:20736:Distracting Shot}" },
    },
    ROGUE = {
        { flavor = "forever", category = "offensive", name = L["TPL_N_ROG_BUILD"], description = L["TPL_D_ROG_BUILD"],
          body = "#showtooltip\n/cast [stealth] {spell:8676:Ambush}; {spell:1752:Sinister Strike}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_ROG_FINISH"], description = L["TPL_D_ROG_FINISH"],
          body = "#showtooltip\n/cast [mod:shift] {spell:408:Kidney Shot}; [mod:ctrl] {spell:5171:Slice and Dice}; {spell:2098:Eviscerate}" },
        { flavor = "forever", category = "cc", name = L["TPL_N_ROG_SAP"], description = L["TPL_D_ROG_SAP"],
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] {spell:6770:Sap}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_ROG_PICK"], description = L["TPL_D_ROG_PICK"],
          body = "#showtooltip\n/castsequence reset=target {spell:921:Pick Pocket}, {spell:6770:Sap}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_ROG_STEALTH"], description = L["TPL_D_ROG_STEALTH"],
          body = "#showtooltip {spell:1784:Stealth}\n/cast [nostealth] {spell:1784:Stealth}" },
        { flavor = "forever", category = "defensive", name = L["TPL_N_ROG_DEF"], description = L["TPL_D_ROG_DEF"],
          body = "#showtooltip\n/cast [mod:shift] {spell:1856:Vanish}; [mod:ctrl] {spell:1966:Feint}; {spell:5277:Evasion}" },
        { flavor = "forever", category = "cc", name = L["TPL_N_ROG_GOUGE"], description = L["TPL_D_ROG_GOUGE"],
          body = "#showtooltip\n/cast [@focus,harm,nodead][] {spell:1776:Gouge}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_ROG_OPENER"], description = L["TPL_D_ROG_OPENER"],
          body = "#showtooltip\n/cast [mod:shift] {spell:703:Garrote}; [stealth] {spell:1833:Cheap Shot}; {spell:53:Backstab}" },
        { flavor = "forever", category = "cc", name = L["TPL_N_ROG_BLIND"], description = L["TPL_D_ROG_BLIND"],
          body = "#showtooltip\n/cast [@focus,harm,nodead][] {spell:2094:Blind}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_ROG_DISTRACT"], description = L["TPL_D_ROG_DISTRACT"],
          body = "#showtooltip\n/cast [@cursor] {spell:1725:Distract}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_ROG_BURST"], description = L["TPL_D_ROG_BURST"],
          body = "#showtooltip {spell:13750:Adrenaline Rush}\n/cast {spell:13750:Adrenaline Rush}\n/cast {spell:13877:Blade Flurry}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_ROG_COLD"], description = L["TPL_D_ROG_COLD"],
          body = "#showtooltip {spell:2098:Eviscerate}\n/cast {spell:14177:Cold Blood}\n/cast {spell:2098:Eviscerate}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_ROG_HEMO"], description = L["TPL_D_ROG_HEMO"],
          body = "#showtooltip\n/cast [mod:shift] {spell:8647:Expose Armor}; {spell:16511:Hemorrhage}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_ROG_PREMED"], description = L["TPL_D_ROG_PREMED"],
          body = "#showtooltip {spell:8676:Ambush}\n/cast {spell:14183:Premeditation}\n/cast {spell:8676:Ambush}" },
    },
    PRIEST = {
        { flavor = "forever", category = "healer", name = L["TPL_N_PRI_SHIELD"], description = L["TPL_D_PRI_SHIELD"],
          body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:17:Power Word: Shield}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_PRI_RENEW"], description = L["TPL_D_PRI_RENEW"],
          body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:139:Renew}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_PRI_FLASH"], description = L["TPL_D_PRI_FLASH"],
          body = "#showtooltip\n/cast [mod:shift,@player][@mouseover,help,nodead][help,nodead][@player] {spell:2061:Flash Heal}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_PRI_DISPEL"], description = L["TPL_D_PRI_DISPEL"],
          body = "#showtooltip\n/cast [@mouseover,exists,nodead][] {spell:527:Dispel Magic}" },
        { flavor = "forever", category = "defensive", name = L["TPL_N_PRI_PANIC"], description = L["TPL_D_PRI_PANIC"],
          body = "#showtooltip\n/cast [mod:shift] {spell:586:Fade}; {spell:8122:Psychic Scream}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_PRI_SHADOW"], description = L["TPL_D_PRI_SHADOW"],
          body = "#showtooltip\n/castsequence reset=target {spell:589:Shadow Word: Pain}, {spell:8092:Mind Blast}, {spell:15407:Mind Flay}" },
        { flavor = "forever", category = "interrupt", name = L["TPL_N_PRI_SILENCE"], description = L["TPL_D_PRI_SILENCE"],
          body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:15487:Silence}" },
        { flavor = "forever", category = "cc", name = L["TPL_N_PRI_SHACKLE"], description = L["TPL_D_PRI_SHACKLE"],
          body = "#showtooltip\n/cast [@focus,harm,nodead][] {spell:9484:Shackle Undead}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_PRI_GREATER"], description = L["TPL_D_PRI_GREATER"],
          body = "#showtooltip {spell:2060:Greater Heal}\n/cast [mod:shift] {spell:14751:Inner Focus}\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:2060:Greater Heal}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_PRI_DISEASE"], description = L["TPL_D_PRI_DISEASE"],
          body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:528:Cure Disease}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_PRI_BUFFS"], description = L["TPL_D_PRI_BUFFS"],
          body = "#showtooltip\n/cast [mod:shift] {spell:588:Inner Fire}; [@mouseover,help,nodead][] {spell:1243:Power Word: Fortitude}" },
        { flavor = "forever", category = "cc", name = L["TPL_N_PRI_MC"], description = L["TPL_D_PRI_MC"],
          body = "#showtooltip\n/cast [@focus,harm,nodead][] {spell:605:Mind Control}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_PRI_PI"], description = L["TPL_D_PRI_PI"],
          body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:10060:Power Infusion}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_PRI_FORM"], description = L["TPL_D_PRI_FORM"],
          body = "#showtooltip {spell:15473:Shadowform}\n/cast [noform] {spell:15473:Shadowform}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_PRI_SMITE"], description = L["TPL_D_PRI_SMITE"],
          body = "#showtooltip\n/cast [mod:shift] {spell:14914:Holy Fire}; {spell:585:Smite}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_PRI_REZ"], description = L["TPL_D_PRI_REZ"],
          body = "#showtooltip\n/cast [@mouseover,help,dead][] {spell:2006:Resurrection}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_PRI_WARD"], description = L["TPL_D_PRI_WARD"],
          body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:6346:Fear Ward}" },
    },
    SHAMAN = {
        { flavor = "forever", category = "interrupt", name = L["TPL_N_SHA_KICK"], description = L["TPL_D_SHA_KICK"],
          body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:8042:Earth Shock}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_SHA_SHOCKS"], description = L["TPL_D_SHA_SHOCKS"],
          body = "#showtooltip\n/cast [mod:shift] {spell:8056:Frost Shock}; [mod:ctrl] {spell:8050:Flame Shock}; {spell:8042:Earth Shock}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_SHA_HEAL"], description = L["TPL_D_SHA_HEAL"],
          body = "#showtooltip\n/cast [mod:shift,@player] {spell:8004:Lesser Healing Wave}; [@mouseover,help,nodead][help,nodead][@player] {spell:331:Healing Wave}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_SHA_CHAIN"], description = L["TPL_D_SHA_CHAIN"],
          body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:1064:Chain Heal}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_SHA_NS"], description = L["TPL_D_SHA_NS"],
          body = "#showtooltip {spell:16188:Nature's Swiftness}\n/cast {spell:16188:Nature's Swiftness}\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:331:Healing Wave}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_SHA_PURGE"], description = L["TPL_D_SHA_PURGE"],
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] {spell:370:Purge}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_SHA_WOLF"], description = L["TPL_D_SHA_WOLF"],
          body = "#showtooltip {spell:2645:Ghost Wolf}\n/cast [noform] {spell:2645:Ghost Wolf}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_SHA_TOTEMS"], description = L["TPL_D_SHA_TOTEMS"],
          body = "#showtooltip\n/castsequence reset=combat {spell:5394:Healing Stream Totem}, {spell:8071:Stoneskin Totem}, {spell:8075:Strength of Earth Totem}" },
        { flavor = "forever", category = "pvp", name = L["TPL_N_SHA_TREMOR"], description = L["TPL_D_SHA_TREMOR"],
          body = "#showtooltip\n/cast [mod:shift] {spell:8177:Grounding Totem}; {spell:8143:Tremor Totem}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_SHA_BOLT"], description = L["TPL_D_SHA_BOLT"],
          body = "#showtooltip\n/cast [mod:shift] {spell:421:Chain Lightning}; {spell:403:Lightning Bolt}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_SHA_WEAPON"], description = L["TPL_D_SHA_WEAPON"],
          body = "#showtooltip\n/cast [mod:shift] {spell:8024:Flametongue Weapon}; [mod:ctrl] {spell:8017:Rockbiter Weapon}; {spell:8232:Windfury Weapon}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_SHA_POISON"], description = L["TPL_D_SHA_POISON"],
          body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:526:Cure Poison}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_SHA_STORM"], description = L["TPL_D_SHA_STORM"],
          body = "#showtooltip {spell:17364:Stormstrike}\n/startattack\n/cast {spell:17364:Stormstrike}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_SHA_FIRE"], description = L["TPL_D_SHA_FIRE"],
          body = "#showtooltip\n/cast [mod:shift] {spell:2484:Earthbind Totem}; {spell:3599:Searing Totem}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_SHA_AIR"], description = L["TPL_D_SHA_AIR"],
          body = "#showtooltip\n/cast [mod:shift] {spell:6495:Sentry Totem}; {spell:8512:Windfury Totem}" },
    },
    MAGE = {
        { flavor = "forever", category = "interrupt", name = L["TPL_N_MAG_CS"], description = L["TPL_D_MAG_CS"],
          body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:2139:Counterspell}" },
        { flavor = "forever", category = "cc", name = L["TPL_N_MAG_POLY"], description = L["TPL_D_MAG_POLY"],
          body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:118:Polymorph}" },
        { flavor = "forever", category = "defensive", name = L["TPL_N_MAG_BLOCK"], description = L["TPL_D_MAG_BLOCK"],
          body = "#showtooltip {spell:11958:Ice Block}\n/stopcasting\n/cancelaura {spell:11958:Ice Block}\n/cast {spell:11958:Ice Block}" },
        { flavor = "forever", category = "defensive", name = L["TPL_N_MAG_BLINK"], description = L["TPL_D_MAG_BLINK"],
          body = "#showtooltip\n/stopcasting [mod:shift]\n/cast [mod:shift] {spell:1953:Blink}; {spell:122:Frost Nova}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_MAG_POM"], description = L["TPL_D_MAG_POM"],
          body = "#showtooltip {spell:11366:Pyroblast}\n/cast {spell:12043:Presence of Mind}\n/stopcasting\n/cast {spell:11366:Pyroblast}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_MAG_FOOD"], description = L["TPL_D_MAG_FOOD"],
          body = "#showtooltip\n/cast [mod:shift] {spell:587:Conjure Food}; {spell:5504:Conjure Water}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_MAG_ARMOR"], description = L["TPL_D_MAG_ARMOR"],
          body = "#showtooltip\n/cast [mod:shift] {spell:6117:Mage Armor}; {spell:7302:Ice Armor}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_MAG_DECURSE"], description = L["TPL_D_MAG_DECURSE"],
          body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:475:Remove Lesser Curse}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_MAG_NUKE"], description = L["TPL_D_MAG_NUKE"],
          body = "#showtooltip\n/cast [mod:shift] {spell:133:Fireball}; {spell:116:Frostbolt}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_MAG_BLAST"], description = L["TPL_D_MAG_BLAST"],
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] {spell:2136:Fire Blast}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_MAG_AOE"], description = L["TPL_D_MAG_AOE"],
          body = "#showtooltip\n/cast [mod:shift] {spell:10:Blizzard}; [mod:ctrl] {spell:120:Cone of Cold}; {spell:1449:Arcane Explosion}" },
        { flavor = "forever", category = "defensive", name = L["TPL_N_MAG_SHIELDS"], description = L["TPL_D_MAG_SHIELDS"],
          body = "#showtooltip\n/cast [mod:shift] {spell:1463:Mana Shield}; {spell:11426:Ice Barrier}" },
        { flavor = "forever", category = "defensive", name = L["TPL_N_MAG_SNAP"], description = L["TPL_D_MAG_SNAP"],
          body = "#showtooltip {spell:12472:Cold Snap}\n/cast {spell:12472:Cold Snap}\n/cast {spell:11426:Ice Barrier}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_MAG_INT"], description = L["TPL_D_MAG_INT"],
          body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:1459:Arcane Intellect}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_MAG_FALL"], description = L["TPL_D_MAG_FALL"],
          body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:130:Slow Fall}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_MAG_ARCANE"], description = L["TPL_D_MAG_ARCANE"],
          body = "#showtooltip {spell:12042:Arcane Power}\n/cast {spell:12042:Arcane Power}\n/cast {spell:12043:Presence of Mind}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_MAG_EVOC"], description = L["TPL_D_MAG_EVOC"],
          body = "#showtooltip {spell:12051:Evocation}\n/stopcasting\n/cast {spell:12051:Evocation}" },
    },
    WARLOCK = {
        { flavor = "forever", category = "cc", name = L["TPL_N_WLK_FEAR"], description = L["TPL_D_WLK_FEAR"],
          body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:5782:Fear}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_WLK_DOT"], description = L["TPL_D_WLK_DOT"],
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] {spell:172:Corruption}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_WLK_CURSE"], description = L["TPL_D_WLK_CURSE"],
          body = "#showtooltip\n/cast [mod:shift,@mouseover,harm,nodead][mod:shift] {spell:1714:Curse of Tongues}; [mod:ctrl,@mouseover,harm,nodead][mod:ctrl] {spell:704:Curse of Recklessness}; [@mouseover,harm,nodead][] {spell:980:Curse of Agony}" },
        { flavor = "forever", category = "defensive", name = L["TPL_N_WLK_COIL"], description = L["TPL_D_WLK_COIL"],
          body = "#showtooltip\n/cast [mod:shift] {spell:5484:Howl of Terror}; [@focus,harm,nodead][] {spell:6789:Death Coil}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_WLK_PETS"], description = L["TPL_D_WLK_PETS"],
          body = "#showtooltip\n/cast [mod:shift] {spell:712:Summon Succubus}; [mod:ctrl] {spell:691:Summon Felhunter}; [mod:alt] {spell:688:Summon Imp}; {spell:697:Summon Voidwalker}" },
        { flavor = "forever", category = "interrupt", name = L["TPL_N_WLK_LOCK"], description = L["TPL_D_WLK_LOCK"],
          body = "#showtooltip {spell:19244:Spell Lock}\n/cast [@focus,harm,nodead][] {spell:19244:Spell Lock}" },
        { flavor = "forever", category = "cc", name = L["TPL_N_WLK_SEDUCE"], description = L["TPL_D_WLK_SEDUCE"],
          body = "#showtooltip {spell:6358:Seduction}\n/cast [@focus,harm,nodead][] {spell:6358:Seduction}" },
        { flavor = "forever", category = "cc", name = L["TPL_N_WLK_BANISH"], description = L["TPL_D_WLK_BANISH"],
          body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:710:Banish}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_WLK_BOLT"], description = L["TPL_D_WLK_BOLT"],
          body = "#showtooltip\n/cast [mod:shift] {spell:5676:Searing Pain}; {spell:686:Shadow Bolt}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_WLK_CONFLAG"], description = L["TPL_D_WLK_CONFLAG"],
          body = "#showtooltip\n/castsequence reset=target {spell:348:Immolate}, {spell:17962:Conflagrate}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_WLK_DRAIN"], description = L["TPL_D_WLK_DRAIN"],
          body = "#showtooltip\n/cast [mod:shift] {spell:1120:Drain Soul}; {spell:689:Drain Life}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_WLK_TAP"], description = L["TPL_D_WLK_TAP"],
          body = "#showtooltip\n/cast [mod:shift] {spell:755:Health Funnel}; {spell:1454:Life Tap}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_WLK_AOE"], description = L["TPL_D_WLK_AOE"],
          body = "#showtooltip\n/cast [mod:shift] {spell:1949:Hellfire}; {spell:5740:Rain of Fire}" },
        { flavor = "forever", category = "pvp", name = L["TPL_N_WLK_SLOW"], description = L["TPL_D_WLK_SLOW"],
          body = "#showtooltip\n/cast [mod:shift,@mouseover,harm,nodead][mod:shift] {spell:18223:Curse of Exhaustion}; [@mouseover,harm,nodead][] {spell:702:Curse of Weakness}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_WLK_ARMOR"], description = L["TPL_D_WLK_ARMOR"],
          body = "#showtooltip\n/cast [mod:shift] {spell:687:Demon Skin}; {spell:706:Demon Armor}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_WLK_STONES"], description = L["TPL_D_WLK_STONES"],
          body = "#showtooltip\n/cast [mod:shift] {spell:693:Create Soulstone}; {spell:6201:Create Healthstone}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_WLK_FELDOM"], description = L["TPL_D_WLK_FELDOM"],
          body = "#showtooltip {spell:18708:Fel Domination}\n/cast {spell:18708:Fel Domination}\n/cast {spell:691:Summon Felhunter}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_WLK_BURN"], description = L["TPL_D_WLK_BURN"],
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] {spell:17877:Shadowburn}" },
    },
    DRUID = {
        { flavor = "forever", category = "cc", name = L["TPL_N_DRU_ROOTS"], description = L["TPL_D_DRU_ROOTS"],
          body = "#showtooltip\n/cast [@focus,harm,nodead][@mouseover,harm,nodead][] {spell:339:Entangling Roots}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_DRU_REJUV"], description = L["TPL_D_DRU_REJUV"],
          body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:774:Rejuvenation}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_DRU_HT"], description = L["TPL_D_DRU_HT"],
          body = "#showtooltip {spell:5185:Healing Touch}\n/cancelform [form]\n/cast [mod:shift,@player][@mouseover,help,nodead][help,nodead][@player] {spell:5185:Healing Touch}" },
        { flavor = "forever", category = "tank", name = L["TPL_N_DRU_BEAR"], description = L["TPL_D_DRU_BEAR"],
          body = "#showtooltip\n/startattack\n/cast [noform:1] {spell:5487:Bear Form}; [mod:shift] {spell:779:Swipe}; {spell:6807:Maul}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_DRU_CAT"], description = L["TPL_D_DRU_CAT"],
          body = "#showtooltip\n/cast [noform:3] {spell:768:Cat Form}; [stealth] {spell:6785:Ravage}; {spell:1082:Claw}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_DRU_PROWL"], description = L["TPL_D_DRU_PROWL"],
          body = "#showtooltip {spell:5215:Prowl}\n/cast [noform:3] {spell:768:Cat Form}; [nostealth] {spell:5215:Prowl}" },
        { flavor = "forever", category = "interrupt", name = L["TPL_N_DRU_BASH"], description = L["TPL_D_DRU_BASH"],
          body = "#showtooltip {spell:5211:Bash}\n/cast [noform:1] {spell:5487:Bear Form}; [@focus,harm,nodead][] {spell:5211:Bash}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_DRU_TRAVEL"], description = L["TPL_D_DRU_TRAVEL"],
          body = "#showtooltip\n/cast [swimming] {spell:1066:Aquatic Form}; [outdoors] {spell:783:Travel Form}; {spell:768:Cat Form}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_DRU_REBIRTH"], description = L["TPL_D_DRU_REBIRTH"],
          body = "#showtooltip\n/cast [@mouseover,help,dead][] {spell:20484:Rebirth}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_DRU_INNERV"], description = L["TPL_D_DRU_INNERV"],
          body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:29166:Innervate}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_DRU_NS"], description = L["TPL_D_DRU_NS"],
          body = "#showtooltip {spell:17116:Nature's Swiftness}\n/cancelform [form]\n/cast {spell:17116:Nature's Swiftness}\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:5185:Healing Touch}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_DRU_MOON"], description = L["TPL_D_DRU_MOON"],
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] {spell:8921:Moonfire}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_DRU_REGROWTH"], description = L["TPL_D_DRU_REGROWTH"],
          body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell:8936:Regrowth}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_DRU_BUFFS"], description = L["TPL_D_DRU_BUFFS"],
          body = "#showtooltip\n/cast [mod:shift,@mouseover,help,nodead][mod:shift] {spell:467:Thorns}; [@mouseover,help,nodead][] {spell:1126:Mark of the Wild}" },
        { flavor = "forever", category = "healer", name = L["TPL_N_DRU_CLEANSE"], description = L["TPL_D_DRU_CLEANSE"],
          body = "#showtooltip\n/cast [mod:shift,@mouseover,help,nodead][mod:shift] {spell:2893:Abolish Poison}; [@mouseover,help,nodead][help,nodead][@player] {spell:2782:Remove Curse}" },
        { flavor = "forever", category = "cc", name = L["TPL_N_DRU_HIBERNATE"], description = L["TPL_D_DRU_HIBERNATE"],
          body = "#showtooltip\n/cast [@focus,harm,nodead][] {spell:2637:Hibernate}" },
        { flavor = "forever", category = "offensive", name = L["TPL_N_DRU_FINISH"], description = L["TPL_D_DRU_FINISH"],
          body = "#showtooltip\n/cast [mod:shift] {spell:1079:Rip}; {spell:22568:Ferocious Bite}" },
        { flavor = "forever", category = "utility", name = L["TPL_N_DRU_FF"], description = L["TPL_D_DRU_FF"],
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] {spell:770:Faerie Fire}" },
        { flavor = "forever", category = "defensive", name = L["TPL_N_DRU_DEF"], description = L["TPL_D_DRU_DEF"],
          body = "#showtooltip\n/cast [form:1] {spell:22842:Frenzied Regeneration}; {spell:22812:Barkskin}" },
    },
}
for cls, list in pairs(FOREVER_TEMPLATES) do
    CLASS_TEMPLATES[cls] = CLASS_TEMPLATES[cls] or {}
    for _, tmpl in ipairs(list) do table.insert(CLASS_TEMPLATES[cls], tmpl) end
end

MF.Templates.CLASS_TEMPLATES = CLASS_TEMPLATES
MF.Templates.UNIVERSAL = UNIVERSAL

---------------------------------------------------
-- API
---------------------------------------------------
function MF.Templates:GetByCategory(categoryId)
    local result = {}
    for _, t in ipairs(UNIVERSAL) do
        if categoryId == "" or t.category == categoryId then
            table.insert(result, t)
        end
    end
    return result
end

function MF.Templates:GetPlayerClass()
    local _, cls = UnitClass("player")
    return cls or "WARRIOR"
end

local GetSpellName = C_Spell and C_Spell.GetSpellName
    or function(id) return (GetSpellInfo(id)) end

-- A template only shows when every spell it names exists in this client:
-- retail spells are missing from WoW Forever and the other way round, and
-- a name that falls back to English would never cast.
local available = setmetatable({}, { __mode = "k" })
local IS_FOREVER = select(4, GetBuildInfo()) < 20000  -- WoW Forever: 16001
function MF.Templates:IsAvailable(tmpl)
    if available[tmpl] == nil then
        local ok = tmpl.flavor ~= "forever" or IS_FOREVER
        for id in (tmpl.body or ""):gmatch("{spell:(%d+):") do
            if not GetSpellName(tonumber(id)) then ok = false; break end
        end
        available[tmpl] = ok
    end
    return available[tmpl]
end

-- Classes of this client that have at least one usable template
function MF.Templates:GetClasses()
    local playable = {}
    for _, c in ipairs(MF.Helpers:PlayableClasses()) do playable[c.file] = true end
    local classes = {}
    for cls, list in pairs(CLASS_TEMPLATES) do
        if not next(playable) or playable[cls] then
            for _, tmpl in ipairs(list) do
                if self:IsAvailable(tmpl) then table.insert(classes, cls); break end
            end
        end
    end
    return classes
end

-- Universal templates + those of a class (the player's by default)
function MF.Templates:GetTemplatesForPlayer(categoryFilter, cls)
    cls = cls or self:GetPlayerClass()
    local result = {}
    -- Universal first
    for _, t in ipairs(UNIVERSAL) do
        if (not categoryFilter or categoryFilter == "" or t.category == categoryFilter) and self:IsAvailable(t) then
            t._source = "universal"
            table.insert(result, t)
        end
    end
    -- Class-specific
    local cTemplates = CLASS_TEMPLATES[cls]
    if cTemplates then
        for _, t in ipairs(cTemplates) do
            if (not categoryFilter or categoryFilter == "" or t.category == categoryFilter) and self:IsAvailable(t) then
                t._source = cls
                table.insert(result, t)
            end
        end
    end
    return result
end

---------------------------------------------------
-- Body resolution
-- Template bodies never hold localized spell names: WoW matches /cast by
-- name in the client's language. Markers are resolved when a template is
-- previewed, loaded or created:
--   {spell:ID:Name}  spell name in the client language (Name if the spell
--                    does not exist in this client, e.g. another flavor)
--   {ph:KEY}         placeholder to replace by hand (L["TPL_PH_KEY"])
---------------------------------------------------

function MF.Templates:ResolveBody(body)
    if not body then return "" end
    body = body:gsub("{spell:(%d+):([^}]*)}", function(id, fallback)
        return GetSpellName(tonumber(id)) or fallback
    end)
    return (body:gsub("{ph:([%w_]+)}", function(key)
        return L["TPL_PH_" .. key]
    end))
end

---------------------------------------------------
-- Templates page (native): search + filter on top, the list on the left,
-- the selected template on the right, like Blizzard's two-pane panels.
-- Shown in the main window's right pane (UI:OpenPage), never a window.
---------------------------------------------------
local function TemplateIcon(tmpl)
    local id = tmpl.body and tonumber(tmpl.body:match("{spell:(%d+):"))
    local tex = id and C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
    return tex or 134400
end

local function StripColor(text)
    return (text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

local function ClassName(cls)
    local names = LOCALIZED_CLASS_NAMES_MALE
    return (names and names[cls]) or cls
end

local function ColoredClass(cls)
    return (CLASS_COLORS[cls] or "|cffffffff") .. ClassName(cls) .. "|r"
end

local function CategoryName(id)
    for _, cat in ipairs(MF.Templates.CATEGORIES) do
        if cat.id == id then return StripColor(cat.name) end
    end
    return id or ""
end

function MF.Templates:BuildPage(page)
    local T = self
    local playerClass = self:GetPlayerClass()
    local state = { cat = "", src = "", query = "", class = playerClass }

    -- Top row: search and filter
    local search = CreateFrame("EditBox", nil, page, "SearchBoxTemplate")
    search:SetSize(230, 20)
    search:SetPoint("TOPLEFT", 8, -2)
    -- Any class: browsing the rogue's macros from a priest is allowed
    local classButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    classButton:SetSize(140, 22)
    classButton:SetPoint("LEFT", search, "RIGHT", 10, 0)
    local filter = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    filter:SetSize(140, 22)
    filter:SetPoint("LEFT", classButton, "RIGHT", 6, 0)

    -- Left: the list
    local listInset = CreateFrame("Frame", nil, page, "InsetFrameTemplate")
    listInset:SetPoint("TOPLEFT", 0, -28)
    listInset:SetPoint("BOTTOMLEFT", 0, 30)
    listInset:SetWidth(270)
    local scrollBox = CreateFrame("Frame", nil, listInset, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", 4, -4)
    scrollBox:SetPoint("BOTTOMRIGHT", -18, 4)
    local scrollBar = CreateFrame("EventFrame", nil, listInset, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, -2)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 2)
    local emptyText = listInset:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyText:SetPoint("TOPLEFT", 16, -24)
    emptyText:SetPoint("TOPRIGHT", -16, -24)
    emptyText:SetText(L["TPL_EMPTY"])

    -- Right: the selected template
    local card = CreateFrame("Frame", nil, page, "InsetFrameTemplate")
    card:SetPoint("TOPLEFT", listInset, "TOPRIGHT", 8, 0)
    card:SetPoint("BOTTOMRIGHT", 0, 30)
    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(40, 40)
    icon:SetPoint("TOPLEFT", 14, -14)
    local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
    title:SetPoint("RIGHT", card, "RIGHT", -14, 0)
    title:SetJustifyH("LEFT")
    local tag = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tag:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    local desc = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -14)
    desc:SetPoint("RIGHT", card, "RIGHT", -14, 0)
    desc:SetJustifyH("LEFT")
    local previewTitle = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    previewTitle:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
    previewTitle:SetText(L["BUILDER_PREVIEW"])
    local previewBg = CreateFrame("Frame", nil, card, "InsetFrameTemplate")
    previewBg:SetPoint("TOPLEFT", previewTitle, "BOTTOMLEFT", -4, -6)
    previewBg:SetPoint("RIGHT", card, "RIGHT", -10, 0)
    previewBg:SetHeight(150)
    local preview = previewBg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    preview:SetPoint("TOPLEFT", 10, -10)
    preview:SetPoint("BOTTOMRIGHT", -10, 10)
    preview:SetJustifyH("LEFT")
    preview:SetJustifyV("TOP")

    -- Actions, bottom right like Blizzard panels
    local btnEdit = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    btnEdit:SetSize(150, 22)
    btnEdit:SetPoint("BOTTOMRIGHT", 0, 0)
    btnEdit:SetText(L["TPL_OPEN_EDITOR"])
    local btnCreate = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    btnCreate:SetSize(150, 22)
    btnCreate:SetPoint("RIGHT", btnEdit, "LEFT", -6, 0)
    btnCreate:SetText(L["TPL_CREATE_DIRECT"])

    local selected
    local function ShowCard(tmpl)
        selected = tmpl
        card:SetShown(tmpl ~= nil)
        btnEdit:SetEnabled(tmpl ~= nil)
        btnCreate:SetEnabled(tmpl ~= nil)
        if not tmpl then return end
        icon:SetTexture(TemplateIcon(tmpl))
        title:SetText(tmpl.name or "?")
        tag:SetText((tmpl._source == "universal" and (MF.C.grey .. L["TPL_SRC_UNIVERSAL"] .. "|r")
            or ColoredClass(tmpl._source)) .. MF.C.grey .. "  -  " .. CategoryName(tmpl.category) .. "|r")
        desc:SetText(tmpl.description or "")
        local An = MF:GetModule("Analyzer")
        local body = T:ResolveBody(tmpl.body)
        preview:SetText(An and An:ColorizeBody(body) or body)
    end

    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(30)
    view:SetElementInitializer("Button", function(btn, tmpl)
        if not btn.mfIcon then
            btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            btn.mfSelected = btn:CreateTexture(nil, "BACKGROUND")
            btn.mfSelected:SetAllPoints()
            btn.mfSelected:SetColorTexture(0.2, 0.6, 1, 0.18)
            btn.mfIcon = btn:CreateTexture(nil, "ARTWORK")
            btn.mfIcon:SetSize(24, 24)
            btn.mfIcon:SetPoint("LEFT", 6, 0)
            btn.mfName = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            btn.mfName:SetPoint("TOPLEFT", btn.mfIcon, "TOPRIGHT", 8, 1)
            btn.mfName:SetPoint("RIGHT", -6, 0)
            btn.mfName:SetJustifyH("LEFT")
            btn.mfName:SetWordWrap(false)
            btn.mfSub = btn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            btn.mfSub:SetPoint("BOTTOMLEFT", btn.mfIcon, "BOTTOMRIGHT", 8, -1)
            btn.mfSub:SetPoint("RIGHT", -6, 0)
            btn.mfSub:SetJustifyH("LEFT")
            btn.mfSub:SetWordWrap(false)
        end
        btn.mfIcon:SetTexture(TemplateIcon(tmpl))
        btn.mfName:SetText(tmpl.name or "?")
        btn.mfSub:SetText(CategoryName(tmpl.category))
        btn.mfSelected:SetShown(tmpl == selected)
        btn:SetScript("OnClick", function()
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
            ShowCard(tmpl)
            scrollBox:ForEachFrame(function(b, t) b.mfSelected:SetShown(t == selected) end)
        end)
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    local function Matches(tmpl)
        if state.src == "universal" and tmpl._source ~= "universal" then return false end
        if state.src == "class" and tmpl._source == "universal" then return false end
        if state.query == "" then return true end
        local q = state.query:lower()
        for _, field in ipairs({ tmpl.name, tmpl.description, T:ResolveBody(tmpl.body) }) do
            if field and field:lower():find(q, 1, true) then return true end
        end
        return false
    end

    local function Populate()
        local rows = {}
        for _, tmpl in ipairs(T:GetTemplatesForPlayer(state.cat, state.class)) do
            if Matches(tmpl) then table.insert(rows, tmpl) end
        end
        filter:SetText(state.cat == "" and L["TPL_ALL"] or CategoryName(state.cat))
        classButton:SetText(ColoredClass(state.class))
        emptyText:SetShown(#rows == 0)
        local keep
        for _, t in ipairs(rows) do if t == selected then keep = t end end
        selected = keep or rows[1]
        scrollBox:SetDataProvider(CreateDataProvider(rows), ScrollBoxConstants.RetainScrollPosition)
        ShowCard(selected)
    end

    search:HookScript("OnTextChanged", function(box)
        state.query = (box:GetText() or ""):match("^%s*(.-)%s*$")
        Populate()
    end)
    filter:SetScript("OnClick", function(btn)
        MenuUtil.CreateContextMenu(btn, function(_, root)
            root:CreateTitle(L["TPL_CATEGORY"])
            local cats = { { id = "", name = L["TPL_ALL"] } }
            for _, cat in ipairs(T.CATEGORIES) do table.insert(cats, cat) end
            for _, cat in ipairs(cats) do
                root:CreateRadio(StripColor(cat.name), function() return state.cat == cat.id end,
                    function() state.cat = cat.id; Populate() end)
            end
            root:CreateDivider()
            root:CreateTitle(L["TPL_SOURCE"])
            for _, src in ipairs({ { "", L["TPL_ALL"] }, { "universal", L["TPL_SRC_UNIVERSAL"] }, { "class", ColoredClass(state.class) } }) do
                root:CreateRadio(src[2], function() return state.src == src[1] end,
                    function() state.src = src[1]; Populate() end)
            end
        end)
    end)

    classButton:SetScript("OnClick", function(btn)
        MenuUtil.CreateContextMenu(btn, function(_, root)
            root:CreateTitle(L["TPL_CLASS"])
            local classes = T:GetClasses()
            table.sort(classes, function(a, b) return ClassName(a) < ClassName(b) end)
            for _, c in ipairs(classes) do
                local label = ColoredClass(c) .. (c == playerClass and (MF.C.grey .. "  " .. L["TPL_YOUR_CLASS"] .. "|r") or "")
                root:CreateRadio(label, function() return state.class == c end,
                    function() state.class = c; Populate() end)
            end
        end)
    end)

    btnEdit:SetScript("OnClick", function()
        local tmpl = selected
        if not tmpl then return end
        local E = MF:GetModule("Editor")
        E:OpenNew(true, nil, function()
            E:LoadContent(tmpl.name or "", T:ResolveBody(tmpl.body), 134400)
        end)
    end)
    btnCreate:SetScript("OnClick", function()
        local tmpl = selected
        if not tmpl then return end
        MF:GetModule("Profiles"):CreateNewMacro(tmpl.name or "Template", 134400, T:ResolveBody(tmpl.body), true)
        C_Timer.After(0.3, function() MF:GetModule("UI"):Refresh() end)
    end)

    page.Populate = Populate
end

function MF.Templates:OpenBrowser()
    local UI = MF:GetModule("UI")
    if not self.pageRegistered then
        self.pageRegistered = true
        UI:RegisterPage("templates", {
            title = L["TEMPLATES"],
            build = function(page) MF.Templates:BuildPage(page) end,
            onShow = function(page) page.Populate() end,
        })
    end
    UI:OpenPage("templates")
end

MF:RegisterModule("Templates", MF.Templates)
