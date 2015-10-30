globals
    // Generated
rect gg_rct_Gebiet_000= null
trigger gg_trg_Nahkampf_Initialisierung= null
string test= "Local\\peasant.mdx"


//JASSHelper struct globals:
constant integer si__abc=1
integer si__abc_F=0
integer si__abc_I=0
integer array si__abc_V

endglobals


//Generated allocator of abc
function s__abc__allocate takes nothing returns integer
 local integer this=si__abc_F
    if (this!=0) then
        set si__abc_F=si__abc_V[this]
    else
        set si__abc_I=si__abc_I+1
        set this=si__abc_I
    endif
    if (this>8190) then
        call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,1000.,"Unable to allocate id for an object of type: abc")
        return 0
    endif

    set si__abc_V[this]=-1
 return this
endfunction

//Generated destructor of abc
function s__abc_deallocate takes integer this returns nothing
    if this==null then
            call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,1000.,"Attempt to destroy a null struct of type: abc")
        return
    elseif (si__abc_V[this]!=-1) then
            call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,1000.,"Double free of type: abc")
        return
    endif
    set si__abc_V[this]=si__abc_F
    set si__abc_F=this
endfunction

//===========================================================================
// 
// Noch eine WARCRAFT-III-Karte
// 
//   Warcraft III map script
//   Generated by the Warcraft III World Editor
//   Date: Fri Oct 30 12:23:56 2015
//   Map Author: Unbekannt
// 
//===========================================================================

//***************************************************************************
//*
//*  Global Variables
//*
//***************************************************************************


function InitGlobals takes nothing returns nothing
endfunction

//***************************************************************************
//*
//*  Unit Creation
//*
//***************************************************************************

//===========================================================================
function CreateUnitsForPlayer0 takes nothing returns nothing
    local player p= Player(0)
    local unit u
    local integer unitID
    local trigger t
    local real life

    set u=CreateUnit(p, 'Hblm', 24.9, - 37.0, 2.626)
endfunction

//===========================================================================
function CreatePlayerBuildings takes nothing returns nothing
endfunction

//===========================================================================
function CreatePlayerUnits takes nothing returns nothing
    call CreateUnitsForPlayer0()
endfunction

//===========================================================================
function CreateAllUnits takes nothing returns nothing
    call CreatePlayerBuildings()
    call CreatePlayerUnits()
endfunction

//***************************************************************************
//*
//*  Regions
//*
//***************************************************************************

function CreateRegions takes nothing returns nothing
    local weathereffect we

    set gg_rct_Gebiet_000=Rect(- 352.0, - 224.0, - 96.0, 160.0)
endfunction

//***************************************************************************
//*
//*  Custom Script Code
//*
//***************************************************************************
//TESH.scrollpos=12
//TESH.alwaysfold=0




///! $J_SCRIPT$ = D:\Warcraft III\Mapping\Tools\jassnewgenpack5d

///! post extractFile $MAP$ war3map.j $J_SCRIPT$

///! post extendor $J_SCRIPT$

///! post objForJass_insertNatives $COMMON_J$ $COMMON_J_NEW$

///! post jasshelper --debug $COMMON_J_NEW$ $BLIZZARD_J$ $MAP$

///! postblock objForJass $MAP$ $WC3$ $FILENAME$
    
///! endpostblock

///! post jassAid_insertNatives $COMMON_J$ $COMMON_J_NEW$

///! post jassAid $MAP$ $WC3$ $COMMON_J_NEW$ $BLIZZARD_J$ example

///! post embedBuildNumber $MAP$ "Hello Build buildNum"

///! post pathFiller $MAP$
//***************************************************************************
//*
//*  Triggers
//*
//***************************************************************************

//===========================================================================
// Trigger: Nahkampf-Initialisierung
//===========================================================================
//TESH.scrollpos=0
//TESH.alwaysfold=0

    function s__abc_onInit takes nothing returns nothing
        call R2I(1 / 0)
    endfunction

function def takes nothing returns nothing
    call BJDebugMsg("def")
    call TriggerSleepAction(2)
    call R2I(0 / 0)
endfunction

function exit takes nothing returns boolean
    local trigger t=CreateTrigger()
    call TriggerAddAction(t, function def)
call BJDebugMsg("exit")
    call TriggerExecute(t)
    //call TriggerEvaluate(GetTriggeringTrigger())
    call R2I(0 / 0)
    return true
endfunction

function lal takes nothing returns nothing
//local trigger t=CreateTrigger()
//call TriggerAddCondition(t, Condition(function exit))
//call BJDebugMsg("A")
    //call TriggerSleepAction(1)

    //call BJDebugMsg("B")
    
    //call TriggerEvaluate(t)
    //call BJDebugMsg("C")

    call TriggerSleepAction(1)

    call R2I(0 / 0)
    //call BJDebugMsg("D")
endfunction

function timed_cond takes nothing returns boolean
    call R2I(1 / 0)
    return true
endfunction

function timed takes nothing returns nothing
    local trigger t=CreateTrigger()
    call TriggerAddCondition(t, Condition(function timed_cond))
    call BJDebugMsg("timed")
    call TriggerEvaluate(t)
    call R2I(0 / 0)
    //call BJDebugMsg("timedB")
    //call TriggerSleepAction(1)
    //call lal()
endfunction

function destCond takes nothing returns boolean
call BJDebugMsg("DESTCOND")
    if GetDestructableTypeId(GetFilterDestructable()) == 'LTlt' then
        call R2I(1 / 0)
    endif
    return true
endfunction

function dest takes nothing returns nothing
    call BJDebugMsg("DEST")
    call R2I(1 / 0)
endfunction

function lal2 takes nothing returns nothing
    call BJDebugMsg("lal2")
    call EnumDestructablesInRect(GetWorldBounds(), Condition(function destCond), function dest)
endfunction

function eval2 takes nothing returns boolean
    local trigger t=CreateTrigger()
    call TriggerAddCondition(t, Condition(function timed_cond))
    call TriggerEvaluate(t)
    call R2I(1 / 0)
    return true
endfunction

function cycle takes nothing returns nothing
    //call cycleT(4, "abc")
endfunction

function cycleT takes integer a,string b returns nothing
    call cycle()
endfunction

function Trig_Nahkampf_Initialisierung_Actions takes nothing returns nothing
    //call BJDebugMsg(objForJass_readStringLv('Ainf', 'atar', 1))
    //call BJDebugMsg(objForJass_readStringLv('A000', 'atar', 1))
//call cycleT(2, "def")
//call TimerStart(CreateTimer(), 0, false, function Player)
call R2I(1 / 0)
call Player(16)
    //local trigger t=CreateTrigger()
    //call TriggerAddCondition(t, Condition(function eval2))
    //call TriggerEvaluate(t)
    //call TimerStart(CreateTimer(), 1, false, function timed)
    //call lal()
    //call R2I(1/0)
endfunction

function OrA takes nothing returns boolean
    call BJDebugMsg("OrA")
    call R2I(1 / 0)
    return false
endfunction

function OrB takes nothing returns boolean
    call BJDebugMsg("OrB")
    //call R2I(1/0)
    return true
endfunction

//===========================================================================
function InitTrig_Nahkampf_Initialisierung takes nothing returns nothing
local region r=CreateRegion()
call RegionAddRect(r, gg_rct_Gebiet_000)
    set gg_trg_Nahkampf_Initialisierung=CreateTrigger()
    call TriggerRegisterPlayerEventEndCinematic(gg_trg_Nahkampf_Initialisierung, Player(0))
    call TriggerAddAction(gg_trg_Nahkampf_Initialisierung, function Trig_Nahkampf_Initialisierung_Actions)
    //call TriggerAddCondition( gg_trg_Nahkampf_Initialisierung, Or(Condition(function OrA), Condition(function OrB)) )

    //call TriggerRegisterEnterRegion(gg_trg_Nahkampf_Initialisierung, r, Or(Condition(function OrA), Condition(function OrB)))
    //call objForJass_init_autoRun()
endfunction

//===========================================================================
function InitCustomTriggers takes nothing returns nothing
    call InitTrig_Nahkampf_Initialisierung()
endfunction

//***************************************************************************
//*
//*  Players
//*
//***************************************************************************

function InitCustomPlayerSlots takes nothing returns nothing

    // Player 0
    call SetPlayerStartLocation(Player(0), 0)
    call SetPlayerColor(Player(0), ConvertPlayerColor(0))
    call SetPlayerRacePreference(Player(0), RACE_PREF_HUMAN)
    call SetPlayerRaceSelectable(Player(0), true)
    call SetPlayerController(Player(0), MAP_CONTROL_USER)

endfunction

function InitCustomTeams takes nothing returns nothing
    // Force: TRIGSTR_002
    call SetPlayerTeam(Player(0), 0)

endfunction

//***************************************************************************
//*
//*  Main Initialization
//*
//***************************************************************************

//===========================================================================
function main takes nothing returns nothing
    call SetCameraBounds(- 3328.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), - 3584.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM), 3328.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), 3072.0 - GetCameraMargin(CAMERA_MARGIN_TOP), - 3328.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), 3072.0 - GetCameraMargin(CAMERA_MARGIN_TOP), 3328.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), - 3584.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM))
    call SetDayNightModels("Environment\\DNC\\DNCLordaeron\\DNCLordaeronTerrain\\DNCLordaeronTerrain.mdl", "Environment\\DNC\\DNCLordaeron\\DNCLordaeronUnit\\DNCLordaeronUnit.mdl")
    call NewSoundEnvironment("Default")
    call SetAmbientDaySound("LordaeronSummerDay")
    call SetAmbientNightSound("LordaeronSummerNight")
    call SetMapMusic("Music", true, 0)
    call CreateRegions()
    call CreateAllUnits()
    call InitBlizzard()

call ExecuteFunc("jasshelper__initstructs10281386")

    call InitGlobals()
    call InitCustomTriggers()

endfunction

//***************************************************************************
//*
//*  Map Configuration
//*
//***************************************************************************

function config takes nothing returns nothing
    call SetMapName("Noch eine WARCRAFT-III-Karte")
    call SetMapDescription("Unbeschrieben")
    call SetPlayers(1)
    call SetTeams(1)
    call SetGamePlacement(MAP_PLACEMENT_USE_MAP_SETTINGS)

    call DefineStartLocation(0, 2304.0, - 448.0)

    // Player setup
    call InitCustomPlayerSlots()
    call SetPlayerSlotAvailable(Player(0), MAP_CONTROL_USER)
    call InitGenericPlayerSlots()
endfunction




//Struct method generated initializers/callers:

function jasshelper__initstructs10281386 takes nothing returns nothing


    call ExecuteFunc("s__abc_onInit")
endfunction
