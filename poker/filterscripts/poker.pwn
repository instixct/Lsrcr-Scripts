/*
    ============================================================
        instixct Poker Script (SFCNR Edited)
        Poker System Filterscript
    ============================================================

    Loading:
        Load via config.json -> pawn.side_scripts

    Notes:
        - AntiCheat: redefine GivePlayerMoney -> AC_GivePlayerCash

    Admin Commands (IsPlayerAdmin required):

        /createpokertable (/ctable)
            [seats 2-6] [small blind] [buy-in]
            Creates table at player position

        /dtable [tableid]
            Deletes poker table

        /agame [tableid]
            Aborts current hand & ejects players

    Internal:
        - Poker_RequireAdmin() -> admin check
        - Poker_ParseTableId() -> validates table existence
        - Tables use Poker_ValidateTableStakes()
        - Spawned at player pos (Z offset applied)
    ============================================================
*/


#define FILTERSCRIPT
#define MIXED_SPELLINGS

#pragma warning disable 217
#pragma warning disable 213

/* ========================= Includes ========================= */

#include <open.mp>
#include <streamer>

#include <YSI\y_hooks>
#include <YSI_Data\y_iterate>
#include <YSI_Coding\y_va>

#include <zcmd>
#include <sscanf2>
#include <easyDialog>

/* ====================== Poker Modules ======================= */

#include "poker/helpers.pwn"
#include "poker/defines.pwn"
#include "poker/data.pwn"
#include "poker/util.pwn"
#include "poker/turns.pwn"
#include "poker/textdraws.pwn"
#include "poker/core.pwn"
#include "poker/commands.pwn"
#include "poker/init.pwn"

main()
{
    return 1;
}