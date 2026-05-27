/*
	Poker turn order: find the next active player around the table.
*/

static stock Poker_FindNextActivePlayer(handle, slot, bool:skip_all_in)
{
	new total_seats = TableData[handle][E_TABLE_TOTAL_SEATS];

	for(new i = 0; i < total_seats; i++)
	{
		if(slot < 0)
			slot = total_seats - 1;

		new target = TableData[handle][E_TABLE_CHAIR_PLAYER_ID][slot];
		if(Iter_Contains(IT_PlayersInGame<handle>, target))
		{
			if(!skip_all_in || !Iter_Contains(IT_PlayersAllIn<handle>, target))
				return target;
		}
		slot--;
	}
	return INVALID_PLAYER_ID;
}

static stock Poker_NormalizeSeat(handle, seat)
{
	if(seat < 0)
		return TableData[handle][E_TABLE_TOTAL_SEATS] - 1;

	return seat;
}

stock GetTurnAfterSeat(handle, seat)
{
	seat = Poker_NormalizeSeat(handle, seat - 1);
	new target = Poker_FindNextActivePlayer(handle, seat, true);

	if(target == INVALID_PLAYER_ID)
		return INVALID_PLAYER_ID;

	return target;
}

stock GetTurnAfterDealer(handle)
{
	new target = GetTurnAfterSeat(handle, TableData[handle][E_TABLE_DEALER_SEAT]);
	if(target == INVALID_PLAYER_ID)
		printf("[Poker] GetTurnAfterDealer failed for table %d", handle);

	return target;
}

stock GetTurnAfterPlayer(handle, playerid)
{
	new slot = Poker_NormalizeSeat(handle, PlayerData[playerid][E_PLAYER_CURRENT_CHAIR_SLOT] - 1);
	return Poker_FindNextActivePlayer(handle, slot, true);
}

stock GetTurnAfterPlayerEx(handle, playerid)
{
	new slot = Poker_NormalizeSeat(handle, PlayerData[playerid][E_PLAYER_CURRENT_CHAIR_SLOT] - 1);
	return Poker_FindNextActivePlayer(handle, slot, false);
}
