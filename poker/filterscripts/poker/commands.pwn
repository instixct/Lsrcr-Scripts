/*
	Poker admin commands.
*/

static stock bool:Poker_RequireAdmin(playerid)
{
	if(!IsPlayerAdmin(playerid))
		return false;

	return true;
}

static stock bool:Poker_ParseTableId(playerid, const params[], &tableid)
{
	if(sscanf(params, "d", tableid))
		return false;

	if(!IsValidTable(tableid))
	{
		SendPokerMessage(playerid, "Invalid poker table ID.");
		return false;
	}
	return true;
}

stock Poker_CommandCreateTable(playerid, const params[])
{
	if(!Poker_RequireAdmin(playerid))
		return 0;

	new seat_count, small_blind, buy_in;
	if(sscanf(params, "ddd", seat_count, small_blind, buy_in))
	{
		SendPokerMessage(playerid, "/createpokertable [seats (2-6)] [small blind] [buy in]");
		SendPokerMessage(playerid, "Alias: /ctable");
		return 1;
	}

	if(!Poker_ValidateTableStakes(buy_in, small_blind, seat_count))
	{
		SendPokerMessage(playerid, "Invalid stakes. Seats: 2-%d. Buy-in must exceed both blinds.", T_MAX_CHAIRS_PER_TABLE - 1);
		return 1;
	}

	new Float:pos[3];
	GetPlayerPos(playerid, pos[0], pos[1], pos[2]);

	new table = CreatePokerTable(
		buy_in,
		small_blind,
		pos[0],
		pos[1],
		pos[2] - T_TABLE_GROUND_OFFSET,
		seat_count,
		GetPlayerVirtualWorld(playerid),
		GetPlayerInterior(playerid)
	);

	if(table == ITER_NONE)
	{
		SendPokerMessage(playerid, "Failed to create poker table. The server may have reached the table limit.");
		return 1;
	}

	SendPokerMessage(playerid, "Created table %d | Seats: %d | Blinds: %s / %s | Buy-in: %s",
		table,
		seat_count,
		cash_format(small_blind),
		cash_format(small_blind * 2),
		cash_format(buy_in)
	);
	return 1;
}

CMD:createpokertable(playerid, params[])
{
	return Poker_CommandCreateTable(playerid, params);
}

CMD:ctable(playerid, params[])
{
	return Poker_CommandCreateTable(playerid, params);
}

CMD:dtable(playerid, params[])
{
	if(!Poker_RequireAdmin(playerid))
		return 0;

	new tableid;
	if(!Poker_ParseTableId(playerid, params, tableid))
	{
		SendPokerMessage(playerid, "/dtable [table ID]");
		return 1;
	}

	SendPokerMessage(playerid, "Deleted poker table %d.", tableid);
	DestroyPokertable(tableid);
	return 1;
}

CMD:agame(playerid, params[])
{
	if(!Poker_RequireAdmin(playerid))
		return 0;

	new tableid;
	if(!Poker_ParseTableId(playerid, params, tableid))
	{
		SendPokerMessage(playerid, "/agame [table ID] - aborts the current hand and ejects players.");
		return 1;
	}

	if(AbortGame(tableid))
		SendPokerMessage(playerid, "Aborted the game on table %d.", tableid);
	else
		SendPokerMessage(playerid, "No active game on table %d.", tableid);

	return 1;
}
