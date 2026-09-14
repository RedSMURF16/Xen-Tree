/*
*
*	Xen Tree by RedSMURF
*
*
*	Description:
*
*	Cvars:
*		None
*
*	Commands:
*       say /xt                    "Opens the Xen Tree menu."
*       say_team /xt               "Opens the Xen Tree menu."
*       xt_reload                  "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT                     32
#define ADMIN_ACCESS                ADMIN_RCON
#define TREE_KEY                    934567
#define TREE_ARRAY_ITEM             pev_iuser1
#define TREE_OWNER                  pev_iuser1
#define TREE_SEQ_IDLE               0
#define TREE_SEQ_ATTACK             1
#define TREE_ATTACK_DURATION        1.19
#define TREE_ATTACK_FACTOR          0.25
#define TREE_TRIGGER_EPSILON        25.0
#define SOUND_NAV                   "buttons/blip1.wav"
#define SOUND_REMOVE                "buttons/button10.wav"
#define SOUND_ALERT                 "buttons/bell1.wav"

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_CONNECT    = 1.0
new const Float:DELAY_ON_LOAD       = 1.0
new const ERROR_FILE[]              = "XenTree_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_TREE
}

enum
{
    DTYPE_INT,
    DTYPE_FLOAT,
    DTYPE_BOOL,
    DTYPE_FLAGS,
    DTYPE_ARRAY_STRING,
    DTYPE_ARRAY_SOUND,
    DTYPE_STRING_MODEL,
    DTYPE_STRING_SOUND,
    DTYPE_STRING_MODEL_ID
}

enum
{
    FLAG_ACTIVE_DELAY       = (1 << 0),
    FLAG_ACTIVE_DURATION    = (1 << 1),
    FLAG_DAMAGE_TRIGGER     = (1 << 2),

    FLAG_SHOW               = (1 << 3),
    FLAG_GHOST              = (1 << 4),
    FLAG_GROUND             = (1 << 5),
    FLAG_ACTIVE             = (1 << 6),
    FLAG_PENDING            = (1 << 7),
    FLAG_SOUND_ATTACK       = (1 << 8),
    FLAG_SOUND_SWING        = (1 << 9)
}

enum
{
    TEAM_NONE,
    TEAM_T,
    TEAM_CT,
    TEAM_BOTH
}

enum
{
    SIZE_NORMAL,
    SIZE_LARGE
}

enum
{
    TARGET_GHOST,
    TARGET_SELECT,
    TARGET_HIDE,
    TARGET_CLEAR
}

enum _:MAIN_SETTINGS
{
    Array:SETTING_DEFAULT_SOUND_ATTACK,
    Array:SETTING_DEFAULT_SOUND_SWING,
    SETTING_DEFAULT_FLAGS,
    SETTING_DEFAULT_TEAM,
    Float:SETTING_DEFAULT_FRAMERATE,
    Float:SETTING_DEFAULT_SPAWN_CHANCE,
    Float:SETTING_DEFAULT_ACTIVE_DELAY[2],
    Float:SETTING_DEFAULT_ACTIVE_DURATION[2],
    Float:SETTING_DEFAULT_ACTIVE_COOLDOWN[2],
    Float:SETTING_DEFAULT_DAMAGE[2],
    SETTING_DEFAULT_DAMAGETYPE,
    Float:SETTING_DEFAULT_PUSH[2],

    SETTING_MODEL_NORMAL[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_LARGE[MAX_RESOURCE_PATH_LENGTH],
    Float:SETTING_MINS_NORMAL[3],
    Float:SETTING_MAXS_NORMAL[3],
    Float:SETTING_MINS_LARGE[3],
    Float:SETTING_MAXS_LARGE[3],
    Float:SETTING_TRIGGER_OFFSET[2],
    Float:SETTING_TRIGGER_MINS_NORMAL[3],
    Float:SETTING_TRIGGER_MAXS_NORMAL[3],
    Float:SETTING_TRIGGER_MINS_LARGE[3],
    Float:SETTING_TRIGGER_MAXS_LARGE[3],
    bool:SETTING_SHOW_BLOOD,
    SETTING_BLOOD_COLOR,
    Float:SETTING_PUNCH_ANGLE[2],

    bool:SETTING_TREE_LOAD,
    Float:SETTING_TREE_CHECK,
    Float:SETTING_TREE_TASK,
    Float:SETTING_OFFSET_BASE,
    Float:SETTING_OFFSET[2],
    Float:SETTING_OFFSET_STEP,
    SETTING_GHOST_ALPHA,
    Float:SETTING_ROTATION_STEP
}

enum _:TREE
{
    TREE_ID,
    TREE_ITEM,
    TREE_FLAGS,
    TREE_TEAM,
    TREE_SIZE,
    TREE_TRIGGER,
    Float:TREE_FRAMERATE,
    TREE_NAME[MAX_VALUE_LENGTH],
    TREE_MODEL[MAX_RESOURCE_PATH_LENGTH],

    Float:TREE_ORIGIN[3],
    Float:TREE_ANGLES[3],
    Float:TREE_MINS[3],
    Float:TREE_MAXS[3],
    Float:TREE_DIRECTION[3],
    Float:TREE_TRIGGER_ORIGIN[3],
    Float:TREE_TRIGGER_MINS[3],
    Float:TREE_TRIGGER_MAXS[3],
    Array:TREE_SOUND_ATTACK,
    Array:TREE_SOUND_SWING,

    Float:TREE_SPAWN_CHANCE,
    Float:TREE_ACTIVE_DELAY[2],
    Float:TREE_ACTIVE_DURATION[2],
    Float:TREE_ACTIVE_COOLDOWN[2],
    Float:TREE_DAMAGE[2],
    TREE_DAMAGETYPE,
    Float:TREE_PUSH[2],

    Float:TREE_NEXT_ENABLE,
    Float:TREE_NEXT_DISABLE,
    Float:TREE_NEXT_IDLE,
    Float:TREE_NEXT_ATTACK
}

enum _:PLAYER_DATA
{
    PDATA_TREE_GHOST,
    PDATA_TREE_MENU,
    bool:PDATA_TREE_ACTION,
    PDATA_ROTATE_SIZE,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,

    PDATA_MENU_TYPE,
    bool:PDATA_MENU_TRACE
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_EDIT,
    MENU_REMOVE,
    MENU_SHOW,
    MENU_STATUS,
    MENU_ROTATE
}

enum
{
    ROOT_CREATE,
    ROOT_EDIT,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_NOCLIP = 5,
    ROOT_GODMODE
}

enum
{
    EDIT_SHOW,
    EDIT_STATUS
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SHOW_NEXT,
    SHOW_BACK,

    SHOW_CURRENT = 3,
    SHOW_ALL_SHOW,
    SHOW_ALL_HIDE
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    ROTATE_UP,
    ROTATE_DOWN,

    ROTATE_GROUND = 3,
    ROTATE_SIZE,
    ROTATE_PLACE
}

new Float:g_fDirections[][] =
{
    {-1.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, -1.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, -1.0},
    {0.0, 0.0, 1.0}
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerEdit",
    "menuHandlerRemove",
    "menuHandlerShow",
    "menuHandlerStatus",
    "menuHandlerRotate"
}

new g_szCN[] = "xen_tree"
new g_szTreeAttackTarget[][] = {"player", "info_target", "xen_tree"}

new Array:g_aTree,
    Array:g_aTreeConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    bool:g_bFileWasRead, g_iActivePlayers,
    g_iFwdUpdateClientData, HamHook:g_iFwdSpawn, HamHook:g_iFwdTouch, HamHook:g_iFwdTakeDamage, HamHook:g_iFwdBloodColor, HamHook:g_iFwdPreThink, HamHook:g_iFwdKilled,
    g_iTree, g_iTreeConfig,
    g_iMaxPlayers

new const g_iColorActive[] = { 0, 255, 0 }
new const g_iColorInactive[] = { 255, 0, 0 }
new g_szRotateSize[][] = {"TREE_ROTATE_NORMAL", "TREE_ROTATE_LARGE"}

public plugin_init()
{
    register_plugin("Xen Tree", PLUGIN_VERSION, "RedSMURF")
    register_cvar("RedSMURF_XenTree", PLUGIN_VERSION, ADMIN_ACCESS)

    register_clcmd("say /xt",       "cmdMenu", ADMIN_ACCESS, "-- Opens the Xen Tree menu.")
    register_clcmd("say_team /xt",  "cmdMenu", ADMIN_ACCESS, "-- Opens the Xen Tree menu.")
    register_concmd("xt_reload",  "cmdReload", ADMIN_ACCESS, "-- Reloads the configuration file")
    register_dictionary("XenTree.txt")

    g_iFwdUpdateClientData = register_forward(FM_UpdateClientData, "fwdUpdateClientData", 1)
    g_iFwdSpawn = RegisterHam(Ham_Spawn, "info_target", "fwdSpawn", 1)
    g_iFwdTouch = RegisterHam(Ham_Touch, "info_target", "fwdTouch")
    g_iFwdTakeDamage = RegisterHam(Ham_TakeDamage, "info_target", "fwdTakeDamage")
    g_iFwdBloodColor = RegisterHam(Ham_BloodColor, "info_target", "fwdBloodColor")
    g_iFwdPreThink = RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    g_iFwdKilled = RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    register_logevent("eventRoundStart", 2, "1=Round_Start")
    DisableForward()
    DisableTree()

    treeInit()
    g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    g_aTree = ArrayCreate(TREE)
    g_aTreeConfig = ArrayCreate(TREE)
    g_eSettings[SETTING_DEFAULT_SOUND_ATTACK] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND_SWING] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)

    ReadFile()
}

public plugin_end()
{
    ArrayDestroy(g_aTree)
    ArrayDestroy(g_aTreeConfig)
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_ATTACK])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_SWING])
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    treeSound(id, SOUND_MENU_NAV)
    treeMenu(id, MENU_ROOT)

    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public eventRoundStart()
{
    if ( !g_iTree )
        return PLUGIN_HANDLED

    new eTree[TREE]
    for ( new i = 0; i < g_iTree; i ++ )
    {
        ArrayGetArray(g_aTree, i, eTree)
        if ( (eTree[TREE_FLAGS] & (FLAG_SHOW | FLAG_ACTIVE)) != (FLAG_SHOW | FLAG_ACTIVE) )
            continue

        treeReset(eTree)
        if ( eTree[TREE_SPAWN_CHANCE] >= random_float(0.0, 1.0) )
        {
            eTree[TREE_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)

            treeSetDelay(eTree)
            treeSetState(eTree)
        }

        ArraySetArray(g_aTree, i, eTree)
    }

    return PLUGIN_HANDLED
}

ReadFile()
{
    if ( g_bFileWasRead )
    {
        for ( new id = 1; id <= g_iMaxPlayers; id ++ )
            if ( is_user_connected(id) )
                UpdateData(id)

        ArrayClear(g_aTreeConfig)
        ArrayClear(g_eSettings[SETTING_DEFAULT_SOUND_ATTACK])
        ArrayClear(g_eSettings[SETTING_DEFAULT_SOUND_SWING])
        g_iTreeConfig = 0
    }

    new szFile[MAX_RESOURCE_PATH_LENGTH], iFile
    get_configsdir(szFile, charsmax(szFile))
    add(szFile, charsmax(szFile), "/XenTree.ini")
    iFile = fopen(szFile, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH], szValue[MAX_VALUE_LENGTH],
        eTree[TREE], iSection = SECTION_NONE, iLine, iPos

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax(szData), "[", "")
                    replace(szData, charsmax(szData), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iTreeConfig )
                            ArrayPushArray(g_aTreeConfig, eTree)

                        copy(eTree[TREE_NAME], charsmax(eTree[TREE_NAME]), szData)
                        eTree[TREE_FLAGS]                   = g_eSettings[SETTING_DEFAULT_FLAGS]
                        eTree[TREE_TEAM]                    = g_eSettings[SETTING_DEFAULT_TEAM]
                        eTree[TREE_FRAMERATE]               = g_eSettings[SETTING_DEFAULT_FRAMERATE]
                        eTree[TREE_SPAWN_CHANCE]            = g_eSettings[SETTING_DEFAULT_SPAWN_CHANCE]
                        eTree[TREE_ACTIVE_DELAY][0]         = g_eSettings[SETTING_DEFAULT_ACTIVE_DELAY][0]
                        eTree[TREE_ACTIVE_DELAY][1]         = g_eSettings[SETTING_DEFAULT_ACTIVE_DELAY][1]
                        eTree[TREE_ACTIVE_DURATION][0]      = g_eSettings[SETTING_DEFAULT_ACTIVE_DURATION][0]
                        eTree[TREE_ACTIVE_DURATION][1]      = g_eSettings[SETTING_DEFAULT_ACTIVE_DURATION][1]
                        eTree[TREE_ACTIVE_COOLDOWN][0]      = g_eSettings[SETTING_DEFAULT_ACTIVE_COOLDOWN][0]
                        eTree[TREE_ACTIVE_COOLDOWN][1]      = g_eSettings[SETTING_DEFAULT_ACTIVE_COOLDOWN][1]
                        eTree[TREE_DAMAGE][0]               = g_eSettings[SETTING_DEFAULT_DAMAGE][0]
                        eTree[TREE_DAMAGE][1]               = g_eSettings[SETTING_DEFAULT_DAMAGE][1]
                        eTree[TREE_DAMAGETYPE]              = g_eSettings[SETTING_DEFAULT_DAMAGETYPE]
                        eTree[TREE_PUSH][0]                 = g_eSettings[SETTING_DEFAULT_PUSH][0]
                        eTree[TREE_PUSH][1]                 = g_eSettings[SETTING_DEFAULT_PUSH][1]
                        eTree[TREE_SOUND_SWING]             = ArrayClone(g_eSettings[SETTING_DEFAULT_SOUND_SWING])
                        eTree[TREE_SOUND_ATTACK]            = ArrayClone(g_eSettings[SETTING_DEFAULT_SOUND_ATTACK])

                        iSection = SECTION_TREE
                        g_iTreeConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                iPos = contain(szValue, "#")
                if ( iPos != -1 )
                    szValue[iPos] = EOS

                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        if ( equali(szKey, "SETTING_DEFAULT_SOUND_ATTACK") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_ATTACK], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_ATTACK]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_SWING") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_SWING], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_SWING]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FLAGS], charsmax(g_eSettings[SETTING_DEFAULT_FLAGS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FRAMERATE], charsmax(g_eSettings[SETTING_DEFAULT_FRAMERATE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SPAWN_CHANCE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SPAWN_CHANCE], charsmax(g_eSettings[SETTING_DEFAULT_SPAWN_CHANCE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_ACTIVE_DELAY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_ACTIVE_DELAY], charsmax(g_eSettings[SETTING_DEFAULT_ACTIVE_DELAY]))
                        else if ( equali(szKey, "SETTING_DEFAULT_ACTIVE_DURATION") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_ACTIVE_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_ACTIVE_DURATION]))
                        else if ( equali(szKey, "SETTING_DEFAULT_ACTIVE_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_ACTIVE_COOLDOWN], charsmax(g_eSettings[SETTING_DEFAULT_ACTIVE_COOLDOWN]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DAMAGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DAMAGE], charsmax(g_eSettings[SETTING_DEFAULT_DAMAGE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DAMAGETYPE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DAMAGETYPE], charsmax(g_eSettings[SETTING_DEFAULT_DAMAGETYPE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_PUSH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_PUSH], charsmax(g_eSettings[SETTING_DEFAULT_PUSH]))
                        else if ( equali(szKey, "SETTING_MODEL_NORMAL") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_NORMAL], charsmax(g_eSettings[SETTING_MODEL_NORMAL]))
                        else if ( equali(szKey, "SETTING_MODEL_LARGE") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_LARGE], charsmax(g_eSettings[SETTING_MODEL_LARGE]))
                        else if ( equali(szKey, "SETTING_MINS_NORMAL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_NORMAL], charsmax(g_eSettings[SETTING_MINS_NORMAL]))
                        else if ( equali(szKey, "SETTING_MAXS_NORMAL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_NORMAL], charsmax(g_eSettings[SETTING_MAXS_NORMAL]))
                        else if ( equali(szKey, "SETTING_MINS_LARGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_LARGE], charsmax(g_eSettings[SETTING_MINS_LARGE]))
                        else if ( equali(szKey, "SETTING_MAXS_LARGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_LARGE], charsmax(g_eSettings[SETTING_MAXS_LARGE]))
                        else if ( equali(szKey, "SETTING_TRIGGER_OFFSET") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_TRIGGER_OFFSET], charsmax(g_eSettings[SETTING_TRIGGER_OFFSET]))
                        else if ( equali(szKey, "SETTING_TRIGGER_MINS_NORMAL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_TRIGGER_MINS_NORMAL], charsmax(g_eSettings[SETTING_TRIGGER_MINS_NORMAL]))
                        else if ( equali(szKey, "SETTING_TRIGGER_MAXS_NORMAL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_TRIGGER_MAXS_NORMAL], charsmax(g_eSettings[SETTING_TRIGGER_MAXS_NORMAL]))
                        else if ( equali(szKey, "SETTING_TRIGGER_MINS_LARGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_TRIGGER_MINS_LARGE], charsmax(g_eSettings[SETTING_TRIGGER_MINS_LARGE]))
                        else if ( equali(szKey, "SETTING_TRIGGER_MAXS_LARGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_TRIGGER_MAXS_LARGE], charsmax(g_eSettings[SETTING_TRIGGER_MAXS_LARGE]))
                        else if ( equali(szKey, "SETTING_SHOW_BLOOD") )
                            parseSetting(DTYPE_BOOL, szValue, charsmax(szValue), g_eSettings[SETTING_SHOW_BLOOD], charsmax(g_eSettings[SETTING_SHOW_BLOOD]))
                        else if ( equali(szKey, "SETTING_BLOOD_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_BLOOD_COLOR], charsmax(g_eSettings[SETTING_BLOOD_COLOR]))
                        else if ( equali(szKey, "SETTING_PUNCH_ANGLE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_PUNCH_ANGLE], charsmax(g_eSettings[SETTING_PUNCH_ANGLE]))
                        else if ( equali(szKey, "SETTING_TREE_LOAD") )
                            parseSetting(DTYPE_BOOL, szValue, charsmax(szValue), g_eSettings[SETTING_TREE_LOAD], charsmax(g_eSettings[SETTING_TREE_LOAD]))
                        else if ( equali(szKey, "SETTING_TREE_CHECK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_TREE_CHECK], charsmax(g_eSettings[SETTING_TREE_CHECK]))
                        else if ( equali(szKey, "SETTING_TREE_TASK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_TREE_TASK], charsmax(g_eSettings[SETTING_TREE_TASK]))
                        else if ( equali(szKey, "SETTING_OFFSET_BASE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_BASE], charsmax(g_eSettings[SETTING_OFFSET_BASE]))
                        else if ( equali(szKey, "SETTING_OFFSET") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET], charsmax(g_eSettings[SETTING_OFFSET]))
                        else if ( equali(szKey, "SETTING_OFFSET_STEP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_STEP], charsmax(g_eSettings[SETTING_OFFSET_STEP]))
                        else if ( equali(szKey, "SETTING_GHOST_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_GHOST_ALPHA], charsmax(g_eSettings[SETTING_GHOST_ALPHA]))
                        else if ( equali(szKey, "SETTING_ROTATION_STEP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_ROTATION_STEP], charsmax(g_eSettings[SETTING_ROTATION_STEP]))
                    }
                    case SECTION_TREE:
                    {
                        if ( equali(szKey, "TREE_SOUND_ATTACK") )
                        {
                            if ( !(eTree[TREE_FLAGS] & FLAG_SOUND_ATTACK) )
                            {
                                ArrayClear(eTree[TREE_SOUND_ATTACK])
                                eTree[TREE_FLAGS] |= FLAG_SOUND_ATTACK
                            }

                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), eTree[TREE_SOUND_ATTACK], charsmax(eTree[TREE_SOUND_ATTACK]))
                        }
                        else if ( equali(szKey, "TREE_SOUND_SWING") )
                        {
                            if ( !(eTree[TREE_FLAGS] & FLAG_SOUND_SWING) )
                            {
                                ArrayClear(eTree[TREE_SOUND_SWING])
                                eTree[TREE_FLAGS] |= FLAG_SOUND_SWING
                            }

                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), eTree[TREE_SOUND_SWING], charsmax(eTree[TREE_SOUND_SWING]))
                        }
                        else if ( equali(szKey, "TREE_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), eTree[TREE_FLAGS], charsmax(eTree[TREE_FLAGS]))
                        else if ( equali(szKey, "TREE_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTree[TREE_TEAM], charsmax(eTree[TREE_TEAM]))
                        else if ( equali(szKey, "TREE_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eTree[TREE_FRAMERATE], charsmax(eTree[TREE_FRAMERATE]))
                        else if ( equali(szKey, "TREE_SPAWN_CHANCE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eTree[TREE_SPAWN_CHANCE], charsmax(eTree[TREE_SPAWN_CHANCE]))
                        else if ( equali(szKey, "TREE_ACTIVE_DELAY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eTree[TREE_ACTIVE_DELAY], charsmax(eTree[TREE_ACTIVE_DELAY]))
                        else if ( equali(szKey, "TREE_ACTIVE_DURATION") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eTree[TREE_ACTIVE_DURATION], charsmax(eTree[TREE_ACTIVE_DURATION]))
                        else if ( equali(szKey, "TREE_ACTIVE_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eTree[TREE_ACTIVE_COOLDOWN], charsmax(eTree[TREE_ACTIVE_COOLDOWN]))
                        else if ( equali(szKey, "TREE_DAMAGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eTree[TREE_DAMAGE], charsmax(eTree[TREE_DAMAGE]))
                        else if ( equali(szKey, "TREE_DAMAGETYPE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTree[TREE_DAMAGETYPE], charsmax(eTree[TREE_DAMAGETYPE]))
                        else if ( equali(szKey, "TREE_PUSH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eTree[TREE_PUSH], charsmax(eTree[TREE_PUSH]))
                    }
                }
            }
        }
    }

    if ( g_iTreeConfig )
        ArrayPushArray(g_aTreeConfig, eTree)
    else
        set_fail_state("No trees were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_authorized(id)
{
    set_task(DELAY_ON_CONNECT, "UpdateData", id)
}

public client_disconnected(id)
{
    new eTree[TREE], iItem
    if ( g_ePlayerData[id][PDATA_TREE_GHOST]
    && (iItem = treeGet(eTree, g_ePlayerData[id][PDATA_TREE_GHOST])) != -1 )
    {
        treeKill(eTree)
        treeRemove(iItem)
    }

    DisableAction(id)
    g_ePlayerData[id][PDATA_TREE_GHOST]  = 0
    g_ePlayerData[id][PDATA_TREE_MENU]   = 0
}

public UpdateData(id)
{
    g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]
}

stock treeInit()
{
    if ( g_eSettings[SETTING_TREE_LOAD] )
        set_task(DELAY_ON_LOAD, "loadData")
}

stock treeTerminate()
{
    new eTree[TREE]
    for ( new i = 0; i < g_iTree; i ++ )
    {
        ArrayGetArray(g_aTree, i, eTree)
        if ( !(eTree[TREE_FLAGS] & FLAG_PENDING) )
            continue

        eTree[TREE_FLAGS] |= FLAG_ACTIVE
        eTree[TREE_FLAGS] &= ~FLAG_PENDING
        ArraySetArray(g_aTree, i, eTree)
    }
}

stock treeMenu(id, iType)
{
    if ( !is_user_connected(id) )
        return PLUGIN_HANDLED

    new szData[256], iMenu
    formatex(szData, charsmax(szData), "%L", id, "TREE_MENU_TITLE", PLUGIN_VERSION)
    iMenu = menu_create(szData, g_szMenuHandler[iType])
    switch( iType )
    {
        case MENU_ROOT:         { menuRoot(id, iMenu); }
        case MENU_CREATE:       { menuCreate(iMenu);            format(szData, charsmax(szData), "%s^n%L", szData, id, "TREE_ROOT_CREATE"); }
        case MENU_EDIT:         { menuEdit(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "TREE_ROOT_EDIT"); }
        case MENU_REMOVE:       { menuRemove(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "TREE_ROOT_REMOVE"); }
        case MENU_SHOW:         { menuShow(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "TREE_ROOT_SHOW"); }
        case MENU_STATUS:       { menuStatus(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "TREE_ROOT_STATUS"); }
        case MENU_ROTATE:       { menuRotate(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "TREE_ROOT_ROTATE"); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szData, charsmax(szData), "%s^n%L", szData, id, "TREE_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szData)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "TREE_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "TREE_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_ROOT_EDIT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_ROOT_NOCLIP", id, get_user_noclip(id) ? "TREE_ON" : "TREE_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_ROOT_GODMODE", id, get_user_godmode(id) ? "TREE_ON" : "TREE_OFF")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iTree >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "TREE_CHAT_TAG", id, "TREE_CHAT_LIMIT", MAX_ENT)

                treeSound(id, SOUND_MENU_REMOVE)
                treeMenu(id, MENU_ROOT)
            }
            else
            {
                treeSound(id, SOUND_MENU_NAV)
                treeMenu(id, MENU_CREATE)
            }
        }
        case ROOT_EDIT:
        {
            if ( !g_iTree )
            {
                client_print_color(id, id, "%L %L", id, "TREE_CHAT_TAG", id, "TREE_CHAT_NO_TREE")

                treeSound(id, SOUND_MENU_REMOVE)
                treeMenu(id, MENU_ROOT)
            }
            else
            {
                treeSound(id, SOUND_MENU_NAV)
                treeMenu(id, MENU_EDIT)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iTree )
            {
                client_print_color(id, id, "%L %L", id, "TREE_CHAT_TAG", id, "TREE_CHAT_NO_TREE")

                treeSound(id, SOUND_MENU_REMOVE)
                treeMenu(id, MENU_ROOT)
            }
            else
            {
                treeSound(id, SOUND_MENU_REMOVE)
                treeMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_NOCLIP:
        {
            treeNoClip(id)
        }
        case ROOT_GODMODE:
        {
            treeGodMode(id)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new eTree[TREE], szItem[64]
    for ( new i = 0; i < g_iTreeConfig; i ++ )
    {
        ArrayGetArray(g_aTreeConfig, i, eTree)

        copy(szItem, charsmax(szItem), eTree[TREE_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    else if ( item == MENU_EXIT )
    {
        treeSound(id, SOUND_MENU_NAV)
        treeMenu(id, MENU_ROOT)

        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    treeCreate(id, item)
    treeSound(id, SOUND_MENU_NAV)
    treeMenu(id, MENU_ROTATE)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuEdit(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "TREE_EDIT_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_EDIT_STATUS")
    menu_additem(iMenu, szItem)
}

public menuHandlerEdit(id, menu, item)
{
    switch( item )
    {
        case EDIT_SHOW:
        {
            treeSound(id, SOUND_MENU_NAV)
            treeMenu(id, MENU_SHOW)
        }
        case EDIT_STATUS:
        {
            treeSound(id, SOUND_MENU_NAV)
            treeMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            treeSound(id, SOUND_MENU_NAV)
            treeMenu(id, MENU_ROOT)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64], eTree[TREE]
    menuNav(id, iMenu)
    ArrayGetArray(g_aTree, g_ePlayerData[id][PDATA_TREE_MENU], eTree)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_REMOVE_CURRENT", eTree[TREE_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    treeSelect(eTree, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_REMOVE
    ArraySetArray(g_aTree, g_ePlayerData[id][PDATA_TREE_MENU], eTree)
}

public menuHandlerRemove(id, menu, item)
{
    new eTree[TREE]
    ArrayGetArray(g_aTree, g_ePlayerData[id][PDATA_TREE_MENU], eTree)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        treeSelect(eTree, eTree[TREE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_TREE_MENU] >= g_iTree - 1 )
                g_ePlayerData[id][PDATA_TREE_MENU] = 0
            else
                g_ePlayerData[id][PDATA_TREE_MENU] ++

            treeSound(id, SOUND_MENU_NAV)
            treeMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_TREE_MENU] <= 0 )
                g_ePlayerData[id][PDATA_TREE_MENU] = g_iTree - 1
            else
                g_ePlayerData[id][PDATA_TREE_MENU] --

            treeSound(id, SOUND_MENU_NAV)
            treeMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            eTree[TREE_FLAGS] &= ~FLAG_ACTIVE
            treeSetState(eTree)
            treeKill(eTree)
            treeRemove(g_ePlayerData[id][PDATA_TREE_MENU])

            client_print_color(id, id, "%L %L", id, "TREE_CHAT_TAG", id, "TREE_CHAT_REMOVE_CURRENT", eTree[TREE_NAME])
            g_ePlayerData[id][PDATA_TREE_MENU] = 0

            treeSound(id, g_iTree > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            treeMenu(id, g_iTree > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iTree )
            {
                ArrayGetArray(g_aTree, 0, eTree)
                eTree[TREE_FLAGS] &= ~FLAG_ACTIVE

                treeSetState(eTree)
                treeKill(eTree)
                treeRemove(0)
            }

            client_print_color(id, id, "%L %L", id, "TREE_CHAT_TAG", id, "TREE_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_TREE_MENU] = 0

            treeSound(id, SOUND_MENU_ALERT)
            treeMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                treeSound(id, SOUND_MENU_NAV)
                treeMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_TREE_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_TREE_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuShow(id, iMenu)
{
    new szItem[64], eTree[TREE]
    menuNav(id, iMenu)
    ArrayGetArray(g_aTree, g_ePlayerData[id][PDATA_TREE_MENU], eTree)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_SHOW_CURRENT",
    eTree[TREE_FLAGS] & FLAG_SHOW ? "\y" : "\r", eTree[TREE_NAME], id, eTree[TREE_FLAGS] & FLAG_SHOW ? "TREE_SHOWN" : "TREE_HIDDEN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_SHOW_ALL_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_SHOW_ALL_HIDE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    treeSelect(eTree, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_SHOW
    ArraySetArray(g_aTree, g_ePlayerData[id][PDATA_TREE_MENU], eTree)
}

public menuHandlerShow(id, menu, item)
{
    new eTree[TREE]
    ArrayGetArray(g_aTree, g_ePlayerData[id][PDATA_TREE_MENU], eTree)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        treeSelect(eTree, eTree[TREE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case SHOW_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_TREE_MENU] >= g_iTree - 1 )
                g_ePlayerData[id][PDATA_TREE_MENU] = 0
            else
                g_ePlayerData[id][PDATA_TREE_MENU] ++

            treeSound(id, SOUND_MENU_NAV)
            treeMenu(id, MENU_SHOW)
        }
        case SHOW_BACK:
        {
            if ( g_ePlayerData[id][PDATA_TREE_MENU] <= 0 )
                g_ePlayerData[id][PDATA_TREE_MENU] = g_iTree - 1
            else
                g_ePlayerData[id][PDATA_TREE_MENU] --

            treeSound(id, SOUND_MENU_NAV)
            treeMenu(id, MENU_SHOW)
        }
        case SHOW_CURRENT:
        {
            eTree[TREE_FLAGS] ^= FLAG_SHOW
            treeSetState(eTree)

            client_print_color(id, id, "%L %L", id, "TREE_CHAT_TAG", id, "TREE_CHAT_SHOW_CURRENT",
            eTree[TREE_NAME], id, eTree[TREE_FLAGS] & FLAG_SHOW ? "TREE_CHAT_SHOWN" : "TREE_CHAT_HIDDEN")
            ArraySetArray(g_aTree, g_ePlayerData[id][PDATA_TREE_MENU], eTree)

            treeSound(id, SOUND_MENU_NAV)
            treeMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_SHOW:
        {
            for ( new i = 0; i < g_iTree; i ++ )
            {
                ArrayGetArray(g_aTree, i, eTree)
                eTree[TREE_FLAGS] |= FLAG_SHOW
                treeSetState(eTree)

                ArraySetArray(g_aTree, i, eTree)
            }

            client_print_color(id, id, "%L %L", id, "TREE_CHAT_TAG", id, "TREE_CHAT_SHOW_ALL_SHOWN")
            treeSound(id, SOUND_MENU_ALERT)
            treeMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_HIDE:
        {
            for ( new i = 0; i < g_iTree; i ++ )
            {
                ArrayGetArray(g_aTree, i, eTree)
                eTree[TREE_FLAGS] &= ~FLAG_SHOW
                treeSetState(eTree)

                ArraySetArray(g_aTree, i, eTree)
            }

            client_print_color(id, id, "%L %L", id, "TREE_CHAT_TAG", id, "TREE_CHAT_SHOW_ALL_HIDDEN")
            treeSound(id, SOUND_MENU_ALERT)
            treeMenu(id, MENU_SHOW)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                treeSound(id, SOUND_MENU_NAV)
                treeMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_TREE_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_TREE_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuStatus(id, iMenu)
{
    new szItem[64], eTree[TREE]
    menuNav(id, iMenu)
    ArrayGetArray(g_aTree, g_ePlayerData[id][PDATA_TREE_MENU], eTree)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_STATUS_CURRENT",
    eTree[TREE_FLAGS] & FLAG_ACTIVE ? "\y" : "\r", eTree[TREE_NAME], id, eTree[TREE_FLAGS] & FLAG_ACTIVE ? "TREE_ENABLED" : "TREE_DISABLED")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_STATUS_ALL_ENABLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_STATUS_ALL_DISABLE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    treeSelect(eTree, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_STATUS
    ArraySetArray(g_aTree, g_ePlayerData[id][PDATA_TREE_MENU], eTree)
}

public menuHandlerStatus(id, menu, item)
{
    new eTree[TREE]
    ArrayGetArray(g_aTree, g_ePlayerData[id][PDATA_TREE_MENU], eTree)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        treeSelect(eTree, eTree[TREE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case STATUS_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_TREE_MENU] >= g_iTree - 1 )
                g_ePlayerData[id][PDATA_TREE_MENU] = 0
            else
                g_ePlayerData[id][PDATA_TREE_MENU] ++

            treeSound(id, SOUND_MENU_NAV)
            treeMenu(id, MENU_STATUS)
        }
        case STATUS_BACK:
        {
            if ( g_ePlayerData[id][PDATA_TREE_MENU] <= 0 )
                g_ePlayerData[id][PDATA_TREE_MENU] = g_iTree - 1
            else
                g_ePlayerData[id][PDATA_TREE_MENU] --

            treeSound(id, SOUND_MENU_NAV)
            treeMenu(id, MENU_STATUS)
        }
        case STATUS_CURRENT:
        {
            eTree[TREE_FLAGS] ^= FLAG_ACTIVE
            treeSetState(eTree)

            client_print_color(id, id, "%L %L", id, "TREE_CHAT_TAG", id, "TREE_CHAT_STATUS_CURRENT",
            eTree[TREE_NAME], id, eTree[TREE_FLAGS] & FLAG_ACTIVE ? "TREE_CHAT_ENABLED" : "TREE_CHAT_DISABLED")
            ArraySetArray(g_aTree, g_ePlayerData[id][PDATA_TREE_MENU], eTree)

            treeSound(id, SOUND_MENU_NAV)
            treeMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_ENABLE:
        {
            for ( new i = 0; i < g_iTree; i ++ )
            {
                ArrayGetArray(g_aTree, i, eTree)
                eTree[TREE_FLAGS] |= FLAG_ACTIVE
                treeSetState(eTree)

                ArraySetArray(g_aTree, i, eTree)
            }

            client_print_color(id, id, "%L %L", id, "TREE_CHAT_TAG", id, "TREE_CHAT_STATUS_ALL_ENABLED")
            treeSound(id, SOUND_MENU_ALERT)
            treeMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_DISABLE:
        {
            for ( new i = 0; i < g_iTree; i ++ )
            {
                ArrayGetArray(g_aTree, i, eTree)
                eTree[TREE_FLAGS] &= ~FLAG_ACTIVE
                treeSetState(eTree)

                ArraySetArray(g_aTree, i, eTree)
            }

            client_print_color(id, id, "%L %L", id, "TREE_CHAT_TAG", id, "TREE_CHAT_STATUS_ALL_DISABLED")
            treeSound(id, SOUND_MENU_ALERT)
            treeMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                treeSound(id, SOUND_MENU_NAV)
                treeMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_TREE_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_TREE_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotate(id, iMenu)
{
    new szItem[64], eTree[TREE]
    if ( treeGet(eTree, g_ePlayerData[id][PDATA_TREE_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_ROTATE_GROUND",
    id, eTree[TREE_FLAGS] & FLAG_GROUND ? "TREE_ON" : "TREE_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_ROTATE_SIZE", id, g_szRotateSize[g_ePlayerData[id][PDATA_ROTATE_SIZE]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TREE_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotate(id, menu, item)
{
    new eTree[TREE], iItem
    if ( (iItem = treeGet(eTree, g_ePlayerData[id][PDATA_TREE_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_UP:
        {
            pev(eTree[TREE_ID], pev_angles, eTree[TREE_ANGLES])
            eTree[TREE_ANGLES][1] -= g_eSettings[SETTING_ROTATION_STEP]
            if ( eTree[TREE_ANGLES][1] < -180.0 ) eTree[TREE_ANGLES][1] += 360.0

            set_pev(eTree[TREE_ID], pev_angles, eTree[TREE_ANGLES])
            ArraySetArray(g_aTree, iItem, eTree)

            treeSound(id, SOUND_MENU_NAV)
            treeMenu(id, MENU_ROTATE)
        }
        case ROTATE_DOWN:
        {
            pev(eTree[TREE_ID], pev_angles, eTree[TREE_ANGLES])
            eTree[TREE_ANGLES][1] += g_eSettings[SETTING_ROTATION_STEP]
            if ( eTree[TREE_ANGLES][1] > 180.0 ) eTree[TREE_ANGLES][1] -= 360.0

            set_pev(eTree[TREE_ID], pev_angles, eTree[TREE_ANGLES])
            ArraySetArray(g_aTree, iItem, eTree)

            treeSound(id, SOUND_MENU_NAV)
            treeMenu(id, MENU_ROTATE)
        }
        case ROTATE_GROUND:
        {
            eTree[TREE_FLAGS] ^= FLAG_GROUND
            ArraySetArray(g_aTree, iItem, eTree)

            treeSound(id, SOUND_MENU_NAV)
            treeMenu(id, MENU_ROTATE)
        }
        case ROTATE_SIZE:
        {
            if ( ++ g_ePlayerData[id][PDATA_ROTATE_SIZE] > SIZE_LARGE )
                g_ePlayerData[id][PDATA_ROTATE_SIZE] = SIZE_NORMAL

            eTree[TREE_SIZE] = g_ePlayerData[id][PDATA_ROTATE_SIZE]
            switch( eTree[TREE_SIZE] )
            {
                case SIZE_NORMAL: engfunc(EngFunc_SetModel, eTree[TREE_ID], g_eSettings[SETTING_MODEL_NORMAL])
                case SIZE_LARGE:  engfunc(EngFunc_SetModel, eTree[TREE_ID], g_eSettings[SETTING_MODEL_LARGE])
            }

            ArraySetArray(g_aTree, iItem, eTree)
            treeSound(id, SOUND_MENU_NAV)
            treeMenu(id, MENU_ROTATE)
        }
        case ROTATE_PLACE:
        {
            treeTrace(eTree, id)
            DisableAction(id)
            g_ePlayerData[id][PDATA_TREE_GHOST] = 0

            eTree[TREE_FLAGS] &= ~FLAG_GHOST
            eTree[TREE_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
            eTree[TREE_ANGLES][0] = -eTree[TREE_ANGLES][0]
            treeSetSize(eTree)
            treeSetDelay(eTree)
            treeSetState(eTree)
            client_print_color(id, id, "%L %L", id, "TREE_CHAT_TAG", id, "TREE_CHAT_CREATE_NEW", eTree[TREE_NAME])

            ArraySetArray(g_aTree, iItem, eTree)
            treeSound(id, SOUND_MENU_NAV)
            treeMenu(id, MENU_CREATE)
        }
        case MENU_EXIT:
        {
            treeKill(eTree)
            treeRemove(iItem)
            DisableAction(id)
            g_ePlayerData[id][PDATA_TREE_GHOST] = 0

            treeSound(id, SOUND_MENU_NAV)
            treeMenu(id, MENU_CREATE)
        }
        default:
        {
            treeKill(eTree)
            treeRemove(iItem)
            DisableAction(id)
            g_ePlayerData[id][PDATA_TREE_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public treeTask()
{
    new eTree[TREE], bool:bModified, Float:fCurrentTime
    fCurrentTime = get_gametime()

    for ( new i = 0; i < g_iTree; i ++ )
    {
        ArrayGetArray(g_aTree, i, eTree)
        bModified = false

        if ( eTree[TREE_FLAGS] & FLAG_SHOW )
        {
            if ( eTree[TREE_FLAGS] & FLAG_ACTIVE )
            {
                if ( eTree[TREE_NEXT_IDLE] > 0.0
                && fCurrentTime >= eTree[TREE_NEXT_IDLE] )
                {
                    eTree[TREE_NEXT_IDLE] = 0.0
                    treeSetSeq(eTree[TREE_ID], eTree[TREE_FRAMERATE], TREE_SEQ_IDLE)

                    bModified = true
                }

                if ( eTree[TREE_NEXT_ATTACK] > 0.0
                && fCurrentTime >= eTree[TREE_NEXT_ATTACK] )
                {
                    eTree[TREE_NEXT_ATTACK] = 0.0
                    treeAttack(eTree)

                    bModified = true
                }

                if ( eTree[TREE_NEXT_DISABLE] > 0.0
                && fCurrentTime >= eTree[TREE_NEXT_DISABLE] )
                {
                    eTree[TREE_FLAGS] &= ~FLAG_ACTIVE
                    eTree[TREE_FLAGS] |= FLAG_PENDING
                    eTree[TREE_NEXT_DISABLE] = 0.0
                    eTree[TREE_NEXT_ENABLE] = fCurrentTime + random_float(eTree[TREE_ACTIVE_COOLDOWN][0], eTree[TREE_ACTIVE_COOLDOWN][1])

                    treeSetState(eTree)
                    bModified = true
                }
            }
            else
            {
                if ( eTree[TREE_NEXT_ENABLE] > 0.0
                && fCurrentTime >= eTree[TREE_NEXT_ENABLE] )
                {
                    eTree[TREE_FLAGS] |= FLAG_ACTIVE
                    eTree[TREE_FLAGS] &= ~FLAG_PENDING
                    eTree[TREE_NEXT_ENABLE] = 0.0
                    if ( eTree[TREE_FLAGS] & FLAG_ACTIVE_DURATION )
                        eTree[TREE_NEXT_DISABLE] = fCurrentTime + random_float(eTree[TREE_ACTIVE_DURATION][0], eTree[TREE_ACTIVE_DURATION][1])

                    treeSetState(eTree)
                    bModified = true
                }
            }
        }

        if ( bModified )
            ArraySetArray(g_aTree, i, eTree)
    }
}

stock treeCreate(id, iItem)
{
    new iEnt = cs_create_entity("info_target")
    if ( !pev_valid(iEnt) )
        return

    new eTree[TREE]
    ArrayGetArray(g_aTreeConfig, iItem, eTree)
    eTree[TREE_ID] = iEnt
    eTree[TREE_ITEM] = iItem
    if ( id )
    {
        EnableAction(id)
        g_ePlayerData[id][PDATA_TREE_GHOST] = eTree[TREE_ID]
        g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]

        eTree[TREE_SIZE] = g_ePlayerData[id][PDATA_ROTATE_SIZE]
        eTree[TREE_FLAGS] |= FLAG_GHOST
    }

    treeSelect(eTree, TARGET_GHOST)
    set_pev(iEnt, pev_classname, g_szCN)
    set_pev(iEnt, pev_impulse, TREE_KEY)
    set_pev(iEnt, TREE_ARRAY_ITEM, g_iTree)
    dllfunc(DLLFunc_Spawn, iEnt)

    switch( eTree[TREE_SIZE] )
    {
        case SIZE_NORMAL: engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_NORMAL])
        case SIZE_LARGE:  engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_LARGE])
    }

    ArrayPushArray(g_aTree, eTree)
    if ( ++ g_iTree == 1 )
    {
        set_task(g_eSettings[SETTING_TREE_TASK], "treeTask", TREE_KEY, .flags = "b")
        EnableTree()
    }
}

stock treeCreateTrigger(eTree[TREE])
{
    new iEnt = cs_create_entity("info_target")
    if ( !pev_valid(iEnt) )
        return

    new szCN[32]
    eTree[TREE_TRIGGER] = iEnt
    formatex(szCN, charsmax(szCN), "%s_trigger", g_szCN)
    set_pev(iEnt, TREE_OWNER, eTree[TREE_ID])
    set_pev(iEnt, pev_classname, szCN)
    dllfunc(DLLFunc_Spawn, iEnt)

    engfunc(EngFunc_AngleVectors, eTree[TREE_ANGLES], eTree[TREE_TRIGGER_ORIGIN], NULL_VECTOR, NULL_VECTOR)
    xs_vec_copy(eTree[TREE_TRIGGER_ORIGIN], eTree[TREE_DIRECTION])
    switch( eTree[TREE_SIZE] )
    {
        case SIZE_NORMAL: { xs_vec_mul_scalar(eTree[TREE_TRIGGER_ORIGIN], g_eSettings[SETTING_TRIGGER_OFFSET][0], eTree[TREE_TRIGGER_ORIGIN]); xs_vec_copy(g_eSettings[SETTING_TRIGGER_MINS_NORMAL], eTree[TREE_TRIGGER_MINS]);    xs_vec_copy(g_eSettings[SETTING_TRIGGER_MAXS_NORMAL], eTree[TREE_TRIGGER_MAXS]); }
        case SIZE_LARGE:  { xs_vec_mul_scalar(eTree[TREE_TRIGGER_ORIGIN], g_eSettings[SETTING_TRIGGER_OFFSET][1], eTree[TREE_TRIGGER_ORIGIN]); xs_vec_copy(g_eSettings[SETTING_TRIGGER_MINS_LARGE], eTree[TREE_TRIGGER_MINS]);     xs_vec_copy(g_eSettings[SETTING_TRIGGER_MAXS_LARGE], eTree[TREE_TRIGGER_MAXS]); }
    }
    xs_vec_add(eTree[TREE_ORIGIN], eTree[TREE_TRIGGER_ORIGIN], eTree[TREE_TRIGGER_ORIGIN])
    engfunc(EngFunc_SetOrigin, iEnt, eTree[TREE_TRIGGER_ORIGIN])
    set_pev(iEnt, pev_solid, SOLID_TRIGGER)
    set_pev(iEnt, pev_movetype, MOVETYPE_NONE)

    engfunc(EngFunc_SetSize, iEnt, eTree[TREE_TRIGGER_MINS], eTree[TREE_TRIGGER_MAXS])
    xs_vec_add(eTree[TREE_TRIGGER_MINS], eTree[TREE_TRIGGER_ORIGIN], eTree[TREE_TRIGGER_MINS])
    xs_vec_add(eTree[TREE_TRIGGER_MAXS], eTree[TREE_TRIGGER_ORIGIN], eTree[TREE_TRIGGER_MAXS])
}

public treeRemove(iItem)
{
    new eTree[TREE]
    ArrayDeleteItem(g_aTree, iItem)

    if ( -- g_iTree == 0 )
    {
        remove_task(TREE_KEY)
        DisableTree()
    }

    for ( new i = iItem; i < g_iTree; i ++ )
    {
        ArrayGetArray(g_aTree, i, eTree)
        set_pev(eTree[TREE_ID], TREE_ARRAY_ITEM, i)
    }
}

public saveData(id)
{
    new eTree[TREE],
        szFile[128], iFile,
        szData[64]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_XenTree.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    treeTerminate()
    for ( new i = 0; i < g_iTree; i ++ )
    {
        ArrayGetArray(g_aTree, i, eTree)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", eTree[TREE_ITEM])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "flags = %d^n", eTree[TREE_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "size = %d^n", eTree[TREE_SIZE])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "origin = %.2f %.2f %.2f^n",
        eTree[TREE_ORIGIN][0], eTree[TREE_ORIGIN][1], eTree[TREE_ORIGIN][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "angles = %.2f %.2f %.2f^n",
        eTree[TREE_ANGLES][0], eTree[TREE_ANGLES][1], eTree[TREE_ANGLES][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "direction = %.2f %.2f %.2f^n",
        eTree[TREE_DIRECTION][0], eTree[TREE_DIRECTION][1], eTree[TREE_DIRECTION][2])
        fputs(iFile, szData)
    }

    client_print_color(id, id, "%L %L", id, "TREE_CHAT_TAG", id, "TREE_CHAT_SAVE", szFile)
    fclose(iFile)

    treeSound(id, SOUND_MENU_NAV)
    treeMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public loadData()
{
    new szFile[128], iFile,
        szData[64], szKey[32], szValue[32],
        Float:fOrigin[3], Float:fAngles[3], iItem, iFlags, iSize, iCount = -1

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_XenTree.ini", szFile)

    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
                LoadDataTree(iItem, iFlags, iSize, fOrigin, fAngles, iCount)

            iCount ++
        }
        else
        {
            strtok(szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "size") )
            {
                iSize = str_to_num(szValue)
            }
            else if ( equal(szKey, "origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[1] = str_to_float(szKey)
                fOrigin[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[1] = str_to_float(szKey)
                fAngles[2] = str_to_float(szValue)
            }
        }
    }

    if ( iCount != -1 )
        LoadDataTree(iItem, iFlags, iSize, fOrigin, fAngles, iCount)

    fclose(iFile)
}

stock LoadDataTree(iItem, iFlags, iSize, Float:fOrigin[3], Float:fAngles[3], iCount)
{
    new eTree[TREE]
    treeCreate(0, iItem)
    ArrayGetArray(g_aTree, iCount, eTree)

    eTree[TREE_FLAGS] = iFlags
    eTree[TREE_SIZE]  = iSize
    xs_vec_copy(fOrigin, eTree[TREE_ORIGIN])
    xs_vec_copy(fAngles, eTree[TREE_ANGLES])
    switch( eTree[TREE_SIZE] )
    {
        case SIZE_NORMAL: engfunc(EngFunc_SetModel, eTree[TREE_ID], g_eSettings[SETTING_MODEL_NORMAL])
        case SIZE_LARGE:  engfunc(EngFunc_SetModel, eTree[TREE_ID], g_eSettings[SETTING_MODEL_LARGE])
    }

    treeSetBox(eTree)
    treeSetSize(eTree)
    treeSetDelay(eTree)
    treeSetState(eTree)
    ArraySetArray(g_aTree, iCount, eTree)
}

public treeNoClip(id)
{
    set_user_noclip(id, !get_user_noclip(id))

    treeSound(id, SOUND_MENU_NAV)
    treeMenu(id, MENU_ROOT)
}

public treeGodMode(id)
{
    set_user_godmode(id, !get_user_godmode(id))

    treeSound(id, SOUND_MENU_NAV)
    treeMenu(id, MENU_ROOT)
}

public fwdUpdateClientData(id, iSendWeapons, iHandle)
{
    if ( g_ePlayerData[id][PDATA_TREE_GHOST] )
    {
        set_cd(iHandle, CD_WeaponAnim, 0)
        set_cd(iHandle, CD_flNextAttack, get_gametime() + 0.1)
    }

    return FMRES_IGNORED
}

public fwdSpawn(iEnt)
{
    if ( !isTree(iEnt) )
        return HAM_IGNORED

    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)

    return HAM_IGNORED
}

public fwdTouch(iEnt, iOther)
{
    new iTree = iEnt
    if ( !isTree(iEnt) )
        iTree = pev(iEnt, TREE_OWNER)
    if ( !isTree(iTree) )
        return HAM_IGNORED

    new eTree[TREE], iItem
    if ( (iItem = treeGet(eTree, iTree)) == -1
    || !(eTree[TREE_FLAGS] & FLAG_ACTIVE)
    || get_gametime() < eTree[TREE_NEXT_IDLE]
    || (iEnt != iTree && !is_user_alive(iOther))
    || (is_user_alive(iOther) && !(CsTeams:eTree[TREE_TEAM] & cs_get_user_team(iOther))) )
        return HAM_IGNORED

    treeSwing(eTree)
    ArraySetArray(g_aTree, iItem, eTree)
    return HAM_IGNORED
}

public fwdTakeDamage(iEnt, iInflictor, iAttacker, Float:fDamage, iDamageBits)
{
    if ( !isTree(iEnt) )
        return HAM_IGNORED

    new eTree[TREE], iItem
    SetHamParamFloat(4, 0.0)
    if ( (iItem = treeGet(eTree, iEnt)) == -1
    || (eTree[TREE_FLAGS] & (FLAG_ACTIVE | FLAG_DAMAGE_TRIGGER)) != (FLAG_ACTIVE | FLAG_DAMAGE_TRIGGER)
    || get_gametime() < eTree[TREE_NEXT_IDLE] )
        return HAM_IGNORED

    treeSwing(eTree)
    ArraySetArray(g_aTree, iItem, eTree)
    return HAM_IGNORED
}

public fwdBloodColor(iEnt)
{
    if ( !isTree(iEnt) )
        return HAM_IGNORED

    SetHamReturnInteger(g_eSettings[SETTING_BLOOD_COLOR])
    return HAM_OVERRIDE
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    static eTree[TREE], iButton, Float:fCurrentTime
    iButton = pev(id, pev_button)
    fCurrentTime = get_gametime()

    if ( treeGet(eTree, g_ePlayerData[id][PDATA_TREE_GHOST]) != -1 )
    {
        if ( g_ePlayerData[id][PDATA_TREE_GHOST] )
        {
            if ( fCurrentTime > g_ePlayerData[id][PDATA_NEXT_OFFSET] )
            {
                if ( iButton & IN_ATTACK )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      += g_eSettings[SETTING_OFFSET_STEP]
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
                else if ( iButton & IN_ATTACK2 )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      -= g_eSettings[SETTING_OFFSET_STEP]
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
            }

            iButton &= ~(IN_ATTACK | IN_ATTACK2)
            set_pev(id, pev_button, iButton)

            treeTrace(eTree, id)
        }
        else if ( g_ePlayerData[id][PDATA_TREE_ACTION] )
        {
            treeCheck(id)
        }
    }

    return HAM_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    DisableAction(id)
    g_ePlayerData[id][PDATA_TREE_MENU]   = 0
    if ( g_ePlayerData[id][PDATA_TREE_GHOST] )
    {
        new eTree[TREE], iItem
        if ( (iItem = treeGet(eTree, g_ePlayerData[id][PDATA_TREE_GHOST])) != -1 )
        {
            treeKill(eTree)
            treeRemove(iItem)
        }

        g_ePlayerData[id][PDATA_TREE_GHOST] = 0
    }
}

stock treeTrace(eTree[TREE], id)
{
    new Float:fVec1[3]
    pev(id, pev_origin, eTree[TREE_ORIGIN])
    pev(id, pev_v_angle, fVec1)
    engfunc(EngFunc_MakeVectors, fVec1)
    global_get(glb_v_forward, fVec1)

    xs_vec_mul_scalar(fVec1, g_ePlayerData[id][PDATA_OFFSET], fVec1)
    xs_vec_add(fVec1, eTree[TREE_ORIGIN], fVec1)

    engfunc(EngFunc_TraceLine, eTree[TREE_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, eTree[TREE_ORIGIN])

    treeSetBox(eTree)
    treeSetOffset(eTree)
    set_pev(eTree[TREE_ID], pev_origin, eTree[TREE_ORIGIN])
}

stock treeCheck(id)
{
    new eTree[TREE], Float:fVec1[3], Float:fVec2[3], Float:fVec3[3], Float:fMins[3], Float:fMaxs[3], Float:fNearest[3]
    new iBest, Float:fBestDist, Float:fDot, Float:fDist

    pev(id, pev_origin, fVec1)
    pev(id, pev_view_ofs, fVec2)
    xs_vec_add(fVec1, fVec2, fVec1)

    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    iBest = -1
    fBestDist = g_eSettings[SETTING_TREE_CHECK]
    for ( new i = 0; i < g_iTree; i ++ )
    {
        ArrayGetArray(g_aTree, i, eTree)
        xs_vec_sub(eTree[TREE_ORIGIN], fVec1, fVec3)
        fDot = xs_vec_dot(fVec2, fVec3)

        if ( fDot < 0.0 )
            continue

        pev(eTree[TREE_ID], pev_absmin, fMins)
        pev(eTree[TREE_ID], pev_absmax, fMaxs)
        xs_vec_mul_scalar(fVec2, fDot, fVec3)
        xs_vec_add(fVec3, fVec1, fVec3)

        fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
        fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
        fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
        fDist = get_distance_f(fVec3, fNearest)
        if ( fDist < fBestDist )
        {
            fBestDist = fDist
            iBest = i
        }
    }

    if ( iBest != -1
    && g_ePlayerData[id][PDATA_TREE_MENU] != iBest )
    {
        ArrayGetArray(g_aTree, g_ePlayerData[id][PDATA_TREE_MENU], eTree)
        treeSelect(eTree, eTree[TREE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

        g_ePlayerData[id][PDATA_MENU_TRACE] = true
        g_ePlayerData[id][PDATA_TREE_MENU] = iBest
        treeMenu(id, g_ePlayerData[id][PDATA_MENU_TYPE])
    }
}

stock treeSwing(eTree[TREE])
{
    new szSound[MAX_RESOURCE_PATH_LENGTH]
    ArrayGetString(eTree[TREE_SOUND_SWING], random(ArraySize(eTree[TREE_SOUND_SWING])), szSound, charsmax(szSound))
    engfunc(EngFunc_EmitSound, eTree[TREE_ID], CHAN_ITEM, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

    treeSetSeq(eTree[TREE_ID], eTree[TREE_FRAMERATE], TREE_SEQ_ATTACK)
    eTree[TREE_NEXT_IDLE] = get_gametime() + (TREE_ATTACK_DURATION / eTree[TREE_FRAMERATE])
    eTree[TREE_NEXT_ATTACK] = get_gametime() + ((TREE_ATTACK_DURATION / eTree[TREE_FRAMERATE]) * TREE_ATTACK_FACTOR)
}

stock treeAttack(eTree[TREE])
{
    new szSound[MAX_RESOURCE_PATH_LENGTH], Float:fVec1[3], Float:fVec2[3], iEnt

    for ( new i = 0; i < sizeof g_szTreeAttackTarget; i ++ )
    {
        iEnt = 0
        while ( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", g_szTreeAttackTarget[i])) )
        {
            if ( iEnt == eTree[TREE_ID]
            || pev(iEnt, pev_takedamage) == DAMAGE_NO )
                continue

            pev(iEnt, pev_origin, fVec1)
            if ( fVec1[0] < eTree[TREE_TRIGGER_MINS][0] - TREE_TRIGGER_EPSILON || fVec1[0] > eTree[TREE_TRIGGER_MAXS][0] + TREE_TRIGGER_EPSILON
            || fVec1[1] < eTree[TREE_TRIGGER_MINS][1] - TREE_TRIGGER_EPSILON || fVec1[1] > eTree[TREE_TRIGGER_MAXS][1] + TREE_TRIGGER_EPSILON
            || fVec1[2] < eTree[TREE_TRIGGER_MINS][2] - TREE_TRIGGER_EPSILON || fVec1[2] > eTree[TREE_TRIGGER_MAXS][2] + TREE_TRIGGER_EPSILON )
                continue

            if ( equal(g_szTreeAttackTarget[i], "player") )
            {
                fVec2[0] = random_float(g_eSettings[SETTING_PUNCH_ANGLE][0], g_eSettings[SETTING_PUNCH_ANGLE][1])
                set_pev(iEnt, pev_punchangle, fVec2)

                ArrayGetString(eTree[TREE_SOUND_ATTACK], random(ArraySize(eTree[TREE_SOUND_ATTACK])), szSound, charsmax(szSound))
                engfunc(EngFunc_EmitSound, iEnt, CHAN_ITEM, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

                pev(iEnt, pev_velocity, fVec1)
                xs_vec_mul_scalar(eTree[TREE_DIRECTION], random_float(eTree[TREE_PUSH][0], eTree[TREE_PUSH][1]), fVec2)
                xs_vec_add(fVec1, fVec2, fVec1)
                set_pev(iEnt, pev_velocity, fVec1)
            }

            ExecuteHamB(Ham_TakeDamage, iEnt, eTree[TREE_ID], eTree[TREE_ID], random_float(eTree[TREE_DAMAGE][0], eTree[TREE_DAMAGE][1]), eTree[TREE_DAMAGETYPE])
        }
    }
}

stock treeSetBox(eTree[TREE])
{
    new Float:fMins[3], Float:fMaxs[3],
        Float:fForward[3], Float:fRight[3], Float:fUp[3],
        Float:fCorners[8][3]

    eTree[TREE_ANGLES][0] = -eTree[TREE_ANGLES][0]
    engfunc(EngFunc_AngleVectors, eTree[TREE_ANGLES], fForward, fRight, fUp)
    switch( eTree[TREE_SIZE] )
    {
        case SIZE_NORMAL:   { xs_vec_copy(g_eSettings[SETTING_MINS_NORMAL], fMins); xs_vec_copy(g_eSettings[SETTING_MAXS_NORMAL], fMaxs); }
        case SIZE_LARGE:    { xs_vec_copy(g_eSettings[SETTING_MINS_LARGE], fMins);  xs_vec_copy(g_eSettings[SETTING_MAXS_LARGE], fMaxs); }
    }

    for ( new i = 0; i < 8; i ++ )
    {
        fCorners[i][0] = (i & 1) ? fMaxs[0] : fMins[0]
        fCorners[i][1] = (i & 2) ? fMaxs[1] : fMins[1]
        fCorners[i][2] = (i & 4) ? fMaxs[2] : fMins[2]

        boxRotate(fCorners[i], fForward, fRight, fUp)
    }

    xs_vec_copy(fCorners[0], fMins)
    xs_vec_copy(fCorners[0], fMaxs)
    for ( new i = 1; i < 8; i ++ )
    {
        fMins[0] = floatmin(fMins[0], fCorners[i][0])
        fMins[1] = floatmin(fMins[1], fCorners[i][1])
        fMins[2] = floatmin(fMins[2], fCorners[i][2])

        fMaxs[0] = floatmax(fMaxs[0], fCorners[i][0])
        fMaxs[1] = floatmax(fMaxs[1], fCorners[i][1])
        fMaxs[2] = floatmax(fMaxs[2], fCorners[i][2])
    }

    xs_vec_copy(fMins, eTree[TREE_MINS])
    xs_vec_copy(fMaxs, eTree[TREE_MAXS])
}

stock boxRotate(Float:fLocal[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
    new Float:fOut[3]
    fOut[0] = fLocal[0] * fForward[0] + fLocal[1] * fRight[0] + fLocal[2] * fUp[0]
    fOut[1] = fLocal[0] * fForward[1] + fLocal[1] * fRight[1] + fLocal[2] * fUp[1]
    fOut[2] = fLocal[0] * fForward[2] + fLocal[1] * fRight[2] + fLocal[2] * fUp[2]

    xs_vec_copy(fOut, fLocal)
}

stock treeSetOffset(eTree[TREE])
{
    new Float:fGaps[6], Float:fVec1[3], Float:fCurrentGap
    fGaps[0] = -eTree[TREE_MINS][0]
    fGaps[1] = eTree[TREE_MAXS][0]
    fGaps[2] = -eTree[TREE_MINS][1]
    fGaps[3] = eTree[TREE_MAXS][1]
    fGaps[4] = -eTree[TREE_MINS][2]
    fGaps[5] = eTree[TREE_MAXS][2]

    if ( eTree[TREE_FLAGS] & FLAG_GROUND )
    {
        xs_vec_sub(eTree[TREE_ORIGIN], Float:{0.0, 0.0, 9999.9}, fVec1)
        engfunc(EngFunc_TraceLine, eTree[TREE_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eTree[TREE_ID], 0)
        get_tr2(0, TR_vecEndPos, eTree[TREE_ORIGIN])
    }

    for ( new i = 5; i >= 0; i -- )
    {
        xs_vec_mul_scalar(g_fDirections[i], 9999.9, fVec1)
        xs_vec_add(fVec1, eTree[TREE_ORIGIN], fVec1)
        engfunc(EngFunc_TraceLine, eTree[TREE_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eTree[TREE_ID], 0)
        get_tr2(0, TR_vecEndPos, fVec1)
        fCurrentGap = xs_vec_distance(eTree[TREE_ORIGIN], fVec1)

        if ( fCurrentGap < fGaps[i] )
        {
            get_tr2(0, TR_vecPlaneNormal, fVec1)
            xs_vec_mul_scalar(fVec1, fGaps[i] - fCurrentGap, fVec1)
            xs_vec_add(eTree[TREE_ORIGIN], fVec1, eTree[TREE_ORIGIN])
        }
    }
}

stock treeSetSeq(iEnt, Float:fFrameRate, iSequence)
{
    set_pev(iEnt, pev_sequence, iSequence)
    set_pev(iEnt, pev_frame, 0.0)
    set_pev(iEnt, pev_framerate, fFrameRate)
    set_pev(iEnt, pev_animtime, get_gametime())
}

stock treeSetSize(eTree[TREE])
{
    treeSelect(eTree, TARGET_CLEAR)
    engfunc(EngFunc_SetOrigin, eTree[TREE_ID], eTree[TREE_ORIGIN])
    set_pev(eTree[TREE_ID], pev_angles, eTree[TREE_ANGLES])
    set_pev(eTree[TREE_ID], pev_solid, eTree[TREE_FLAGS] & FLAG_SHOW ? SOLID_BBOX : SOLID_NOT)
    set_pev(eTree[TREE_ID], pev_movetype, MOVETYPE_NONE)
    set_pev(eTree[TREE_ID], pev_health, 100.0)

    eTree[TREE_ANGLES][0] = -eTree[TREE_ANGLES][0]
    engfunc(EngFunc_SetSize, eTree[TREE_ID], eTree[TREE_MINS], eTree[TREE_MAXS])
    treeCreateTrigger(eTree)
}

stock treeSetDelay(eTree[TREE])
{
    if ( eTree[TREE_FLAGS] & FLAG_ACTIVE )
    {
        new Float:fCurrentTime
        fCurrentTime = get_gametime()

        if ( eTree[TREE_FLAGS] & FLAG_ACTIVE_DELAY )
        {
            eTree[TREE_FLAGS] &= ~FLAG_ACTIVE
            eTree[TREE_NEXT_ENABLE] = fCurrentTime + random_float(eTree[TREE_ACTIVE_DELAY][0], eTree[TREE_ACTIVE_DELAY][1])

            treeSetState(eTree)
        }
        else
        {
            if ( eTree[TREE_FLAGS] & FLAG_ACTIVE_DURATION )
                eTree[TREE_NEXT_DISABLE] = fCurrentTime + random_float(eTree[TREE_ACTIVE_DURATION][0], eTree[TREE_ACTIVE_DURATION][1])
        }
    }
}

stock treeSetState(eTree[TREE])
{
    eTree[TREE_NEXT_IDLE] = 0.0
    treeSetSeq(eTree[TREE_ID], eTree[TREE_FRAMERATE], TREE_SEQ_IDLE)

    if ( eTree[TREE_FLAGS] & FLAG_SHOW )
    {
        set_pev(eTree[TREE_ID], pev_solid, SOLID_BBOX)
        set_pev(eTree[TREE_ID], pev_takedamage, DAMAGE_YES)
        treeSelect(eTree, TARGET_CLEAR)
    }
    else
    {
        set_pev(eTree[TREE_ID], pev_solid, SOLID_NOT)
        set_pev(eTree[TREE_ID], pev_takedamage, DAMAGE_NO)
        treeSelect(eTree, TARGET_HIDE)
    }
}

stock treeSelect(eTree[TREE], iAction)
{
    new iRender, iRenderFx, iRenderColor[3], iRenderAmt

    iRenderFx = kRenderFxNone
    if ( iAction == TARGET_SELECT )
    {
        if ( eTree[TREE_FLAGS] & FLAG_ACTIVE )  { iRenderColor[0] = g_iColorActive[0];      iRenderColor[1] = g_iColorActive[1];     iRenderColor[2] = g_iColorActive[2]; }
        else                                    { iRenderColor[0] = g_iColorInactive[0];    iRenderColor[1] = g_iColorInactive[1];   iRenderColor[2] = g_iColorInactive[2]; }

        iRender = kRenderTransColor
        iRenderFx = kRenderFxGlowShell
        iRenderAmt = 16
    }
    else if ( iAction == TARGET_GHOST )
    {
        iRender = kRenderTransAlpha
        iRenderAmt = g_eSettings[SETTING_GHOST_ALPHA]
    }
    else if ( iAction == TARGET_HIDE )
    {
        iRender = kRenderTransAlpha
        iRenderAmt = 0
    }
    else if ( iAction == TARGET_CLEAR )
    {
        iRender = kRenderNormal
        iRenderAmt = 255
    }

    set_ent_rendering(eTree[TREE_ID], iRenderFx, iRenderColor[0], iRenderColor[1], iRenderColor[2], iRender, iRenderAmt)
}

stock treeSound(iEnt, iSound, bool:bPlayer = true)
{
    new szSample[64]
    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), SOUND_NAV)
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), SOUND_REMOVE)
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), SOUND_ALERT)
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, CHAN_ITEM, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

stock treeReset(eTree[TREE])
{
    eTree[TREE_FLAGS] &= ~(FLAG_SHOW | FLAG_ACTIVE)
    eTree[TREE_NEXT_ENABLE] = 0.0
    eTree[TREE_NEXT_DISABLE] = 0.0
    eTree[TREE_NEXT_IDLE] = 0.0
    eTree[TREE_NEXT_ATTACK] = 0.0

    treeSetState(eTree)
}

stock treeGet(eTree[TREE], iEnt)
{
    new iItem
    iItem = pev(iEnt, TREE_ARRAY_ITEM)
    if ( iItem < 0 || iItem >= g_iTree )
        return -1

    ArrayGetArray(g_aTree, iItem, eTree)
    return iItem
}

stock bool:isTree(iEnt)
{
    return pev(iEnt, pev_impulse) == TREE_KEY
}

stock treeKill(eTree[TREE])
{
    if ( pev_valid(eTree[TREE_ID]) )
        set_pev(eTree[TREE_ID], pev_flags, pev(eTree[TREE_ID], pev_flags) | FL_KILLME)

    if ( pev_valid(eTree[TREE_TRIGGER]) )
        set_pev(eTree[TREE_TRIGGER], pev_flags, pev(eTree[TREE_TRIGGER], pev_flags) | FL_KILLME)
}

stock parseSetting(iType, szValue[], iValueLen, any:aOutput[], iOutputLength)
{
    switch ( iType )
    {
        case DTYPE_INT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_num(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLOAT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_float(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_BOOL:
        {
            aOutput[0] = bool:str_to_num(szValue)
        }
        case DTYPE_FLAGS:
        {
            aOutput[0] = read_flags(szValue)
        }
        case DTYPE_ARRAY_STRING:
        {
            replace_all(szValue, iValueLen, "^"", " ")
            replace_all(szValue, iValueLen, "^^n", "^n")
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_SOUND:
        {
            ArrayPushString(aOutput[0], szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_model(szValue)
        }
        case DTYPE_STRING_SOUND:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                aOutput[0] = precache_model(szValue)
        }
    }
}

stock EnableAction(id)
{
    if ( !g_ePlayerData[id][PDATA_TREE_ACTION] )
    {
        new eTree[TREE]
        for ( new i = 0; i < g_iTree; i ++ )
        {
            ArrayGetArray(g_aTree, i, eTree)
            if ( eTree[TREE_FLAGS] & FLAG_SHOW )
                continue

            treeSelect(eTree, TARGET_GHOST)
        }

        g_ePlayerData[id][PDATA_TREE_ACTION] = true
        if ( ++ g_iActivePlayers == 1 )
            EnableForward()
    }
}

stock DisableAction(id)
{
    if ( g_ePlayerData[id][PDATA_TREE_ACTION] )
    {
        new eTree[TREE]
        for ( new i = 0; i < g_iTree; i ++ )
        {
            ArrayGetArray(g_aTree, i, eTree)
            if ( eTree[TREE_FLAGS] & FLAG_SHOW )
                continue

            treeSelect(eTree, TARGET_HIDE)
        }

        g_ePlayerData[id][PDATA_TREE_ACTION] = false
        if ( -- g_iActivePlayers == 0 )
            DisableForward()
    }
}

stock EnableForward()
{
    g_iFwdUpdateClientData = register_forward(FM_UpdateClientData, "fwdUpdateClientData", 1)
    EnableHamForward(g_iFwdSpawn)
    EnableHamForward(g_iFwdPreThink)
    EnableHamForward(g_iFwdKilled)
}

stock DisableForward()
{
    unregister_forward(FM_UpdateClientData, g_iFwdUpdateClientData, 1)
    DisableHamForward(g_iFwdSpawn)
    DisableHamForward(g_iFwdPreThink)
    DisableHamForward(g_iFwdKilled)
}

stock EnableTree()
{
    EnableHamForward(g_iFwdTouch)
    EnableHamForward(g_iFwdTakeDamage)

    if ( g_eSettings[SETTING_SHOW_BLOOD] )
        EnableHamForward(g_iFwdBloodColor)
}

stock DisableTree()
{
    DisableHamForward(g_iFwdTouch)
    DisableHamForward(g_iFwdTakeDamage)
    DisableHamForward(g_iFwdBloodColor)
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}