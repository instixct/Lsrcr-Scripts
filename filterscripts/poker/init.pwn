/*
	Poker filterscript bootstrap and default casino tables.
*/

static stock Poker_ResetPlayerData()
{
	PlayerData[MAX_PLAYERS][E_PLAYER_CURRENT_HANDLE] = ITER_NONE;
	PlayerData[MAX_PLAYERS][E_PLAYER_CURRENT_CHAIR_SLOT] = ITER_NONE;
	PlayerData[MAX_PLAYERS][E_PLAYER_CHAIR_ATTACH_INDEX_ID] = ITER_NONE;
	PlayerData[MAX_PLAYERS][E_PLAYER_IS_PLAYING] = false;
	PlayerData[MAX_PLAYERS][E_PLAYER_TIMER_STARTED] = false;
	PlayerData[MAX_PLAYERS][E_PLAYER_CARD_VALUES][0] = ITER_NONE;
	PlayerData[MAX_PLAYERS][E_PLAYER_CARD_VALUES][1] = ITER_NONE;
	PlayerData[MAX_PLAYERS][E_PLAYER_CURRENT_BET] = 0;
	PlayerData[MAX_PLAYERS][E_PLAYER_TOTAL_CHIPS] = 0;
	PlayerData[MAX_PLAYERS][E_PLAYER_FOLDED] = false;
	return 1;
}

static stock Poker_ResetTemplateTable()
{
	new template = T_MAX_POKER_TABLES;

	TableData[template][E_TABLE_STING_NEW_GAME] = false;
	TableData[template][E_TABLE_TOTAL_SEATS] = 0;
	TableData[template][E_TABLE_LOADING_GAME] = false;
	TableData[template][E_TABLE_CHECK_FIRST] = false;
	TableData[template][E_TABLE_FIRST_TURN] = INVALID_PLAYER_ID;
	TableData[template][E_TABLE_CURRENT_STATE] = STATE_IDLE;
	TableData[template][E_TABLE_BUY_IN] = 0;
	TableData[template][E_TABLE_SMALL_BLIND] = 0;
	TableData[template][E_TABLE_BIG_BLIND] = 0;
	TableData[template][E_TABLE_VIRTUAL_WORLD] = 0;
	TableData[template][E_TABLE_INTERIOR] = 0;
	TableData[template][E_TABLE_POS_X] = 0.0;
	TableData[template][E_TABLE_POS_Y] = 0.0;
	TableData[template][E_TABLE_POS_Z] = 0.0;
	TableData[template][E_TABLE_OBJECT_IDS][0] = 0;
	TableData[template][E_TABLE_OBJECT_IDS][1] = 0;

	for(new seat = 0; seat < T_MAX_CHAIRS_PER_TABLE; seat++)
	{
		TableData[template][E_TABLE_CHAIR_OBJECT_IDS][seat] = INVALID_OBJECT_ID;
		TableData[template][E_TABLE_IS_SEAT_TAKEN][seat] = false;
		TableData[template][E_TABLE_CHAIR_PLAYER_ID][seat] = INVALID_PLAYER_ID;
		TableData[template][E_TABLE_SEAT_POS_X][seat] = 0.0;
		TableData[template][E_TABLE_SEAT_POS_Y][seat] = 0.0;
		TableData[template][E_TABLE_SEAT_POS_Z][seat] = 0.0;
		TableChips[template][seat][0] = 0;
		TableChips[template][seat][1] = 0;
		TableChips[template][seat][2] = 0;
		TableChips[template][seat][3] = 0;
	}
	return 1;
}

static stock Poker_LoadDefaultTables()
{
	// // Red Dragons Casino (interior 10, VW 23)
	// CreatePokerTable(1000000, 10000, 1968.395019, 1027.808959, 991.828002, 2, 23, 10);
	// CreatePokerTable(500000,  5000,  1940.795043, 1008.741027, 991.828002, 3, 23, 10);
	// CreatePokerTable(250000,  2500,  1940.795043, 1027.240966, 991.828002, 3, 23, 10);
	// CreatePokerTable(100000,  1000,  1940.795043, 1021.075012, 991.828002, 4, 23, 10);
	// CreatePokerTable(50000,   500,   1940.795043, 1014.908996, 991.828002, 4, 23, 10);
	// CreatePokerTable(25000,   250,   1968.395019, 1014.609008, 991.828002, 5, 23, 10);
	// CreatePokerTable(10000,   100,   1968.395019, 1021.208984, 991.828002, 6, 23, 10);
	// CreatePokerTable(5000,    50,    1968.395019, 1008.008972, 991.828002, 6, 23, 10);

	// // Caligula's Casino (interior 1, VW 82)
	// CreatePokerTable(250000, 2500, 2273.936035, 1597.272949, 1005.568969, 2, 82, 1);
	// CreatePokerTable(125000, 1250, 2252.936035, 1591.272949, 1005.568969, 2, 82, 1);
	// CreatePokerTable(100000, 1000, 2255.936035, 1597.272949, 1005.568969, 3, 82, 1);
	// CreatePokerTable(50000,  500,  2258.936035, 1591.272949, 1005.568969, 4, 82, 1);
	// CreatePokerTable(25000,  250,  2261.936035, 1597.272949, 1005.568969, 5, 82, 1);
	// CreatePokerTable(10000,  100,  2264.936035, 1591.272949, 1005.568969, 5, 82, 1);
	// CreatePokerTable(5000,   50,   2267.936035, 1597.272949, 1005.568969, 6, 82, 1);
	// CreatePokerTable(2500,   25,   2270.936035, 1591.272949, 1005.568969, 6, 82, 1);
	return 1;
}

hook OnFilterScriptExit()
{
	for(new table = 0; table < T_MAX_POKER_TABLES; table++)
	{
		if(!Iter_Contains(IT_Tables, table))
			continue;

		DestroyPokertable(table);
		memcpy(TableData[table], TableData[T_MAX_POKER_TABLES], 0, sizeof(TableData[]) * 4, sizeof(TableData[]));
	}
	return 1;
}

hook OnFilterScriptInit()
{
	Poker_ResetPlayerData();
	Poker_ResetTemplateTable();
	Poker_LoadDefaultTables();
	printf("[Poker] Filterscript loaded %d default tables spawned.", Iter_Count(IT_Tables));
	return 1;
}
