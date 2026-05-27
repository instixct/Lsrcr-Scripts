forward bool: FoldPlayer(handle, playerid);



forward Poker_StartGame(handle, dealer);

stock SetLastToRaise(handle, playerid)
{
	if(!IsValidTable(handle))
	{
		return 0;
	}
	if(!Iter_Contains(IT_PlayersInGame<handle>, playerid))
	{
		T_SendWarning("[SetLastToRaise] playerid %d is not playing in table ID %d", playerid, handle);
		return 0;
	}
	TableData[handle][E_TABLE_LAST_TO_RAISE] = playerid;
	TableData[handle][E_TABLE_LAST_TO_RAISE_SEAT] = GetPlayerSeat(playerid);
	return 1;
}

stock ResetLabel(handle)
{
	if(!IsValidTable(handle)) return 0;
	new const buy_in = TableData[handle][E_TABLE_BUY_IN];
	new const small_blind = TableData[handle][E_TABLE_SMALL_BLIND];
	UpdateDynamic3DTextLabelTextEx(TableData[handle][E_TABLE_POT_LABEL], COLOR_GREY,
		"Press ENTER To Play Poker\n{FFFFFF}%s Minimum\n%s / %s Blinds", cash_format(buy_in), cash_format(small_blind), cash_format(small_blind * 2));
	return 1;
}

stock GetClosestTableForPlayer(playerid)
{
	new const Float:infinity = Float:0x7F800000;
	new Float:tmpdist = infinity;
	new Float:Pos[3];
	new handle = ITER_NONE;
	GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);
	foreach(new i: IT_Tables)
	{
		new const Float:dist = VectorSize(Pos[0]-TableData[i][E_TABLE_POS_X], Pos[1]-TableData[i][E_TABLE_POS_Y], Pos[2]-TableData[i][E_TABLE_POS_Z]);
		if(dist < tmpdist)
		{
			tmpdist = dist;
			handle = i;
		}
	}
	return handle;
}

stock bool:IsPlayerInRangeOfTable(playerid, handle, Float:range)
{
	if(!IsValidTable(handle)) return false;
	if(IsPlayerInRangeOfPoint(playerid, range, TableData[handle][E_TABLE_POS_X], TableData[handle][E_TABLE_POS_Y], TableData[handle][E_TABLE_POS_Z])) return true;
	return false;
}


/******************************************************************************************
	Actual functions
*******************************************************************************************/

stock CreatePokerTable(buy_in, small_blind, Float: X, Float: Y, Float: Z, seat_count, vworld, interior)
{
	new handle = Iter_Free(IT_Tables);

	if(handle == ITER_NONE)
	{
        static overflow;
        printf("[POKER ERROR] Reached limit of %d blackjack tables, increase to %d to fix.", T_MAX_POKER_TABLES, T_MAX_POKER_TABLES + ( ++ overflow ) );
		return ITER_NONE;
	}
	if(seat_count >= T_MAX_CHAIRS_PER_TABLE)
	{
		T_SendWarning("Max number of chairs per table has been reached. Increase T_MAX_CHAIRS_PER_TABLE.");
		return ITER_NONE;
	}
	if(buy_in <= small_blind || buy_in <= 2 * small_blind)
	{
		T_SendWarning("Buy in cannot be less than the small blind or big blind.");
		return ITER_NONE;
	}
	//TableData[T_MAX_POKER_TABLES] (dummy array)
	memcpy(TableData[handle], TableData[T_MAX_POKER_TABLES], 0, sizeof(TableData[]) * 4, sizeof(TableData[]));


	TableData[handle][E_TABLE_BUY_IN] = buy_in;
	TableData[handle][E_TABLE_SMALL_BLIND] = small_blind;
	TableData[handle][E_TABLE_BIG_BLIND] = small_blind * 2;
	TableData[handle][E_TABLE_TOTAL_SEATS] = seat_count;
	TableData[handle][E_TABLE_VIRTUAL_WORLD] = vworld;
	TableData[handle][E_TABLE_INTERIOR] = interior;

	/* Positions */
	TableData[handle][E_TABLE_POS_X] = X;
	TableData[handle][E_TABLE_POS_Y] = Y;
	TableData[handle][E_TABLE_POS_Z] = Z;

	/* Objects */

	//Table
	TableData[handle][E_TABLE_OBJECT_IDS][0] = CreateDynamicObject(2189, X, Y, Z + T_Z_OFFSET - 0.01, 0.0, 0.0, 0.0, vworld, interior, .priority = 9999);
	TableData[handle][E_TABLE_OBJECT_IDS][1] = CreateDynamicObject(2111, X, Y, Z-0.01, 0.0, 0.0, 0.0, vworld, interior, .priority = 9999);

	//Textures
	Poker_ApplyTableFeltMaterial(TableData[handle][E_TABLE_OBJECT_IDS][0], buy_in);

	//Chairs
	TableData[handle][E_TABLE_POT_LABEL] = CreateDynamic3DTextLabel("-", -1, X+T_CHIP_OFFSET, Y+T_CHIP_OFFSET, Z+0.5, 10.0, .worldid = vworld, .interiorid = interior);

	new Float:angle_step = floatdiv(360.0, float(seat_count));
	for(new i = 0; i < seat_count; i++)
	{
		new const Float:unit_posx = floatcos(float(i) * angle_step, degrees);
		new const Float:unit_posy = floatsin(float(i) * angle_step, degrees);
		new const Float:o_posx = unit_posx * T_CHAIR_RANGE + X;
		new const Float:o_posy = unit_posy * T_CHAIR_RANGE + Y;
		new const Float:c_posz = Z + 0.36;
		TableData[handle][E_TABLE_CHAIR_OBJECT_IDS][i] = CreateDynamicObject(T_CHAIR_MODEL, o_posx, o_posy, Z + 0.25, 0.0, 0.0, angle_step * float(i), vworld, interior, .priority = 9999);
		TableData[handle][E_TABLE_SEAT_POS_X][i] = o_posx;
		TableData[handle][E_TABLE_SEAT_POS_Y][i] = o_posy;
		TableData[handle][E_TABLE_SEAT_POS_Z][i] = Z;
		//Currently invisible
		TableData[handle][E_TABLE_BET_LABELS][i] = CreateDynamic3DTextLabel("$9", T_BET_LABEL_COLOR & ~0xFF,  0.65 * floatcos(float(i) * angle_step, degrees) + X, 0.65 * floatsin(float(i) * angle_step, degrees) + Y,  c_posz, 3.0 , .worldid = vworld, .interiorid = interior);

		CreateChips(handle, i);
	}
	new const Float: or_z = Z + 0.284; //No chips are visible
	new Float: a_s = floatdiv(360.0, float(MAX_CHIP_DIGITS));
	//center chips
	for(new j = 0; j < MAX_CHIP_DIGITS; j++)
	{
		new Float:rad = 0.11;
		new rand = random(20);
		new Float:px = rad * floatcos(float(j) * a_s, degrees) + X + T_CHIP_OFFSET;
		new Float:py = rad * floatsin(float(j) * a_s, degrees) + Y + T_CHIP_OFFSET;
		TableData[handle][E_TABLE_CHIPS][j] = CreateDynamicObject(1902, px, py, or_z + float(rand) * 0.008, 0.0, 0.0, 0.0, vworld, interior, .priority = 9999);
		SetDynamicObjectMaterialText(TableData[handle][E_TABLE_CHIPS][j], 0, " ", .backcolor = colors[j]);
		TableData[handle][E_TABLE_CHIPS_LABEL][j] = CreateDynamicObject(1905, px, py, or_z + float(rand) * 0.008 + 0.1 + 0.025, 0.0, 0.0, 0.0, vworld, interior, .priority = 9999);
		SetDynamicObjectMaterialText(TableData[handle][E_TABLE_CHIPS_LABEL][j],
		0, chip_text[j], 50, "Arial", 44, 1, colors[j], -1, 1 );
	}
	TableData[handle][E_TABLE_CURRENT_STATE] = STATE_IDLE;
	Iter_Clear(IT_TableCardSet[handle]);

	for(new i = 0; i < 52; i++)
		Iter_Add(IT_TableCardSet[handle], i);

	/* Sidepots */
	Iter_Clear(IT_Sidepots[handle]);

	for(new i = 0; i < T_MAX_CHAIRS_PER_TABLE; i++)
	{
		TableData[handle][E_TABLE_POT_CHIPS][i] = 0;
		Iter_Clear(It_SidepotMembers[_IT[handle][i]]);
	}
	/*=================================================*/
	Iter_Add(IT_Tables, handle);
	ResetLabel(handle);
	ResetChips(handle);

	Poker_StreamUpdateNearTable(X, Y, Z);
	return handle;
}


stock SetPotChipsValue(handle, value)
{
	new
		dec_pos = 0,
		Float: base_z = TableData[handle][E_TABLE_POS_Z] + 0.284
	;
	for(new j = 0; j < MAX_CHIP_DIGITS; j++)
	{
		new Float:c_x, Float:c_y, Float:c_z;
		new objectid = TableData[handle][E_TABLE_CHIPS][j];
		GetDynamicObjectPos(objectid, c_x, c_y, c_z);
		SetDynamicObjectPos(objectid, c_x, c_y, base_z);
		SetDynamicObjectPos(TableData[handle][E_TABLE_CHIPS_LABEL][j], c_x, c_y, base_z + 0.12);
	}
	for(new val = value; val != 0; val /= 10)
	{
		if(dec_pos >= MAX_CHIP_DIGITS) break;
		new const digit = val % 10;
		if(!digit)
		{
			dec_pos++;
			continue;
		}
		new Float:c_x, Float:c_y, Float:c_z;
		//Chip object
		new objectid = TableData[handle][E_TABLE_CHIPS][dec_pos];
		GetDynamicObjectPos(objectid, c_x, c_y, c_z);
		SetDynamicObjectPos(objectid, c_x, c_y, base_z + 0.016 * (float(digit)));
		//Chip label:
		SetDynamicObjectPos(TableData[handle][E_TABLE_CHIPS_LABEL][dec_pos], c_x, c_y, 0.125 + base_z + 0.016 * (float(digit)));
		dec_pos++;
	}
	return 1;
}

stock CreateChips(handle, i)
{
	new Float:angle_step = floatdiv(360.0, float(TableData[handle][E_TABLE_TOTAL_SEATS]));
	new const Float:c_posz = TableData[handle][E_TABLE_POS_Z] + 0.36;

	new const Float: or_x = 0.70 * floatcos(float(i) * angle_step, degrees) + TableData[handle][E_TABLE_POS_X];
	new const Float: or_y = 0.70 * floatsin(float(i) * angle_step, degrees) + TableData[handle][E_TABLE_POS_Y];
	new const Float: or_z = c_posz - 0.076;

	new Float: a_s = floatdiv(360.0, float(MAX_CHIP_DIGITS));

	for(new j = 0; j < MAX_CHIP_DIGITS; j++)
	{
		new Float:rad = 0.11;
		new rand = random(20);
		TableChips[handle][i][j] = CreateDynamicObject(1902, rad * floatcos(float(j) * a_s, degrees) + or_x , rad * floatsin(float(j)* a_s, degrees) + or_y, or_z + float(rand) * 0.008, 0.0, 0.0, 0.0, TableData[handle][E_TABLE_VIRTUAL_WORLD], TableData[handle][E_TABLE_INTERIOR], .priority = 9999);
		SetDynamicObjectMaterialText(TableChips[handle][i][j], 0, " ", .backcolor = colors[j]);
		TableChipsLabel[handle][i][j] = CreateDynamicObject(1905, rad * floatcos(float(j) * a_s, degrees) + or_x , rad * floatsin(float(j)* a_s, degrees) + or_y, or_z + float(rand) * 0.008 + 0.1 + 0.025, 0.0, 0.0, 0.0, TableData[handle][E_TABLE_VIRTUAL_WORLD], TableData[handle][E_TABLE_INTERIOR], .priority = 9999);
		SetDynamicObjectMaterialText(TableChipsLabel[handle][i][j], 0, chip_text[j], 50, "Arial", 44, 1, colors[j], -1, 1 );
	}

	// update users within premise
	foreach(new playerid : Player) if(IsPlayerInRangeOfPoint(playerid, 35.0, TableData[handle][E_TABLE_POS_X], TableData[handle][E_TABLE_POS_Y], TableData[handle][E_TABLE_POS_Z])) {
		Streamer_Update(playerid);
	}
	return 1;
}

stock ResetChips(handle)
{
	new
		Float: base_z = TableData[handle][E_TABLE_POS_Z] + 0.284
	;
	new seat_count = TableData[handle][E_TABLE_TOTAL_SEATS];
	for(new i = 0; i < seat_count; i++) {
		for(new j = 0; j < MAX_CHIP_DIGITS; j++) {
			DestroyDynamicObject(TableChips[handle][i][j]), TableChips[handle][i][j] = -1;
			DestroyDynamicObject(TableChipsLabel[handle][i][j]), TableChipsLabel[handle][i][j] = -1;
		}
	}
	/*for(new i = 0; i < seats; i++)
	{
		for(new j = 0; j < MAX_CHIP_DIGITS; j++)
		{
			new rand = random(20);
			new Float:c_x, Float:c_y, Float:c_z;
			new objectid = TableChips[handle][i][j];
			GetDynamicObjectPos(objectid, c_x, c_y, c_z);
			SetDynamicObjectPos(objectid, c_x, c_y, (float(rand) * 0.008) + base_z);
			SetDynamicObjectPos(TableChipsLabel[handle][i][j], c_x, c_y, (float(rand) * 0.008) + base_z + 0.125);
		}
	}*/
	for(new j = 0; j < MAX_CHIP_DIGITS; j++)
	{
		new rand = random(20);
		new Float:c_x, Float:c_y, Float:c_z;
		new objectid = TableData[handle][E_TABLE_CHIPS][j];
		GetDynamicObjectPos(objectid, c_x, c_y, c_z);
		SetDynamicObjectPos(objectid, c_x, c_y, (float(rand) * 0.008) + base_z);
		SetDynamicObjectPos(TableData[handle][E_TABLE_CHIPS_LABEL][j], c_x, c_y, (float(rand) * 0.008) + base_z + 0.125);
	}
	return 1;
}
stock SetChipsValue(handle, seat, value)
{
	new
		dec_pos = 0,
		Float: base_z = TableData[handle][E_TABLE_POS_Z] + 0.284
	;
	if (!IsValidDynamicObject(TableChips[handle][seat][0])) CreateChips(handle, seat);
	for(new j = 0; j < MAX_CHIP_DIGITS; j++)
	{
		new Float:c_x, Float:c_y, Float:c_z;
		new objectid = TableChips[handle][seat][j];
		GetDynamicObjectPos(objectid, c_x, c_y, c_z);
		SetDynamicObjectPos(objectid, c_x, c_y, base_z);
		SetDynamicObjectPos(TableChipsLabel[handle][seat][j], c_x, c_y, base_z + 0.12);
	}
	for(new val = value; val != 0; val /= 10)
	{
		if(dec_pos >= MAX_CHIP_DIGITS) break;
		new const digit = val % 10;
		if(!digit)
		{
			dec_pos++;
			continue;
		}
		new Float:c_x, Float:c_y, Float:c_z;
		//Chip object
		new objectid = TableChips[handle][seat][dec_pos];
		GetDynamicObjectPos(objectid, c_x, c_y, c_z);
		SetDynamicObjectPos(objectid, c_x, c_y, base_z + 0.016 * (float(digit)));
		//Chip label:
		SetDynamicObjectPos(TableChipsLabel[handle][seat][dec_pos], c_x, c_y, 0.125 + base_z + 0.016 * (float(digit)));
		dec_pos++;
	}
	return 1;
}

stock DestroyPokertable( handle)
{
	if(!Iter_Contains(IT_Tables, handle)) return 0;

	if(Iter_Count(IT_PlayersTable<handle>))
	{
		foreach (new i : Player) 
		{
			if(Iter_Contains(IT_PlayersTable<handle>, i))
			{
				KickPlayerFromTable(i);
			}
		}
	}
	TableData[handle][E_TABLE_BUY_IN] = 0;
	TableData[handle][E_TABLE_SMALL_BLIND] = 0;
	TableData[handle][E_TABLE_BIG_BLIND] = 0;

	DestroyDynamicObject(TableData[handle][E_TABLE_OBJECT_IDS][0]);
	TableData[handle][E_TABLE_OBJECT_IDS][0] = INVALID_OBJECT_ID;

	DestroyDynamicObject(TableData[handle][E_TABLE_OBJECT_IDS][1]);
	TableData[handle][E_TABLE_OBJECT_IDS][1] = INVALID_OBJECT_ID;

	KillTimer(TableData[handle][E_TABLE_TIMER_ID]);
	TableData[handle][E_TABLE_TIMER_ID] = 0;

	DestroyDynamic3DTextLabel(TableData[handle][E_TABLE_POT_LABEL]);
	for(new i = 0; i < TableData[handle][E_TABLE_TOTAL_SEATS]; i++)
	{
		DestroyDynamicObject(TableData[handle][E_TABLE_CHAIR_OBJECT_IDS][i]);
		TableData[handle][E_TABLE_CHAIR_OBJECT_IDS][i] = INVALID_OBJECT_ID;
		TableData[handle][E_TABLE_SEAT_POS_X][i] = 0.0;
		TableData[handle][E_TABLE_SEAT_POS_Y][i] = 0.0;
		TableData[handle][E_TABLE_SEAT_POS_Z][i] = 0.0;
		for(new j = 0; j < MAX_CHIP_DIGITS; j++)
		{
			DestroyDynamicObject(TableChips[handle][i][j]), TableChips[handle][i][j] = -1;
			DestroyDynamicObject(TableChipsLabel[handle][i][j]), TableChipsLabel[handle][i][j] = -1;
		}
	}
	for(new j = 0; j < MAX_CHIP_DIGITS; j++)
	{
		DestroyDynamicObject(TableData[handle][E_TABLE_CHIPS][j]);
		DestroyDynamicObject(TableData[handle][E_TABLE_CHIPS_LABEL][j]);
	}
	TableData[handle][E_TABLE_TOTAL_SEATS] = 0;
	Iter_Remove(IT_Tables, handle);
	Iter_Clear(IT_TableCardSet[handle]);
	Iter_Clear(IT_PlayersInGame<handle>);
	Iter_Clear(IT_PlayersTable<handle>);
	return 1;
}



stock KickPlayerFromTable(playerid)
{
	if(!GetPVarInt(playerid, "t_is_in_table")) return 0;
	new handle = PlayerData[playerid][E_PLAYER_CURRENT_HANDLE];
	if(!Iter_Contains(IT_PlayersTable<handle>, playerid)) return 0;
	new slot = PlayerData[playerid][E_PLAYER_CURRENT_CHAIR_SLOT];
	new attach_index = PlayerData[playerid][E_PLAYER_CHAIR_ATTACH_INDEX_ID];
	RemovePlayerAttachedObject(playerid, attach_index);
	ClearAnimations(playerid, FORCE_SYNC:true);
	TogglePlayerControllable(playerid, true);
	new const Float:angle_step = floatdiv(360.0, TableData[handle][E_TABLE_TOTAL_SEATS]);
	//Create the chair object again:
	TableData[handle][E_TABLE_CHAIR_OBJECT_IDS][slot] = CreateDynamicObject(T_CHAIR_MODEL, TableData[handle][E_TABLE_SEAT_POS_X][slot], TableData[handle][E_TABLE_SEAT_POS_Y][slot], TableData[handle][E_TABLE_SEAT_POS_Z][slot], 0.0, 0.0, angle_step * float(slot), TableData[handle][E_TABLE_VIRTUAL_WORLD], TableData[handle][E_TABLE_INTERIOR], .priority = 9999);
	Internal_RemoveChairSlot(handle, slot);
	Iter_Remove(IT_PlayersTable<handle>, playerid);
	if(Iter_Contains(IT_PlayersInGame<handle>, playerid)) Iter_Remove(IT_PlayersInGame<handle>, playerid);
	SetPlayerPos(playerid, TableData[handle][E_TABLE_SEAT_POS_X][slot], TableData[handle][E_TABLE_SEAT_POS_Y][slot], TableData[handle][E_TABLE_SEAT_POS_Z][slot]);
	SetCameraBehindPlayer(playerid);

	// remove player chips
	for(new j = 0; j < MAX_CHIP_DIGITS; j++) {
		DestroyDynamicObject(TableChips[handle][slot][j]), TableChips[handle][slot][j] = -1;
		DestroyDynamicObject(TableChipsLabel[handle][slot][j]), TableChipsLabel[handle][slot][j] = -1;
	}

	// hide textdraws
	for(new i = 0; i < TableData[handle][E_TABLE_TOTAL_SEATS]; i++)
	{
		PlayerTextDrawHide(playerid, PlayerData[playerid][E_PLAYER_CARDS_TXT_1][i]);
		PlayerTextDrawHide(playerid, PlayerData[playerid][E_PLAYER_CARDS_TXT_2][i]);
		PlayerTextDrawDestroy(playerid, PlayerData[playerid][E_PLAYER_CARDS_TXT_1][i]);
		PlayerTextDrawDestroy(playerid, PlayerData[playerid][E_PLAYER_CARDS_TXT_2][i]);
	}
	for(new i = 0; i < 5; i++){
		PlayerTextDrawHide(playerid, PlayerData[playerid][E_PLAYER_COMMUNITY_CARDS_TXT][i]);
		PlayerTextDrawDestroy(playerid, PlayerData[playerid][E_PLAYER_COMMUNITY_CARDS_TXT][i]);
		PlayerTextDrawHide(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][i]);
		PlayerTextDrawDestroy(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][i]);
	}
	for(new i = 0; i < 6; i++){
		PlayerTextDrawHide(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][i]);
		PlayerTextDrawDestroy(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][i]);
	}
	DestroyDynamic3DTextLabel(PlayerData[playerid][E_PLAYER_3D_LABEL]);

	UpdateDynamic3DTextLabelText(TableData[handle][E_TABLE_BET_LABELS][slot], 0, " ");

	GivePlayerMoney(playerid, PlayerData[playerid][E_PLAYER_TOTAL_CHIPS]);


	if(PlayerData[playerid][E_PLAYER_TIMER_STARTED])
	{
		KillTimer(PlayerData[playerid][E_PLAYER_TIMER_ID]);
	}
	memcpy(PlayerData[playerid], PlayerData[MAX_PLAYERS], 0, sizeof(PlayerData[]) * 4, sizeof(PlayerData[]));
	#if T_SAVE_PLAYER_POS == true
	SetPlayerPos(playerid, GetPVarFloat(playerid, "t_temp_posX"), GetPVarFloat(playerid, "t_temp_posY"), GetPVarFloat(playerid, "t_temp_posZ"));
	SetPlayerFacingAngle(playerid, GetPVarFloat(playerid, "t_temp_angle"));
	#endif
	SetPVarInt(playerid, "t_is_in_table", 0);
	new Float:X, Float:Y, Float:Z;
	X = TableData[handle][E_TABLE_POS_X];
	Y = TableData[handle][E_TABLE_POS_Y];
	Z = TableData[handle][E_TABLE_POS_Z];
	Poker_StreamUpdateNearTable(X, Y, Z);
	if(!Iter_Count(IT_PlayersTable<handle>))
	{
		ResetLabel(handle);
		ResetChips(handle);
	}
	return 1;
}


hook OnPlayerConnect(playerid)
{
	for(new i = 0; i < MAX_PLAYER_ATTACHED_OBJECTS; i++)
    {
        if(!IsPlayerAttachedObjectSlotUsed(playerid, i)) continue;
        RemovePlayerAttachedObject(playerid, i);
    }
    return 0;
}

stock AddPlayerToTable(playerid, handle)
{
	if(!Iter_Contains(IT_Tables, handle)) return 0;
	if(GetPVarInt(playerid, "t_is_in_table")) return 0;
	new slot = Internal_GetFreeChairSlot(handle);
	if(slot == ITER_NONE)
	{
		SendPokerMessage(playerid, "There aren't currently any unnocupied seats in this table at the moment. You cannot enter it.");
		return 0;
	}

	if(GetPlayerMoney(playerid) < TableData[handle][E_TABLE_BUY_IN]) return SendPokerMessage(playerid, "You don't have enough money to access this table. Buy In: %s", cash_format(TableData[handle][E_TABLE_BUY_IN]));

	new index = Player_GetUnusedAttachIndex(playerid);
	if(index == cellmin)
	{
		SendPokerMessage(playerid, "You cannot access this table in this moment.");
		return 0;
	}
	//Reset player data
	memcpy(PlayerData[playerid], PlayerData[MAX_PLAYERS], 0, sizeof(PlayerData[]) * 4, sizeof(PlayerData[]));


	//Information to set the player's position, angle, etc..
	new Float:Pos[3];
	Pos[0] = TableData[handle][E_TABLE_SEAT_POS_X][slot];
	Pos[1] = TableData[handle][E_TABLE_SEAT_POS_Y][slot];
	Pos[2] = TableData[handle][E_TABLE_SEAT_POS_Z][slot];
	//new const Float:angle_step = floatdiv(360.0, float(TableData[handle][E_TABLE_TOTAL_SEATS]));
	//new Float:facing_angle = (TableData[handle][E_TABLE_TOTAL_SEATS] == 2)  ? (270 - angle_step * float(slot + 1)) : angle_step * float(slot + 1);
	new Float:facing_angle = atan2(TableData[handle][E_TABLE_POS_Y] - Pos[1], TableData[handle][E_TABLE_POS_X] - Pos[0]) - 90.0;
	DestroyDynamicObject(TableData[handle][E_TABLE_CHAIR_OBJECT_IDS][slot]);
	SetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);
	SetPlayerFacingAngle(playerid, facing_angle);

	SetPlayerAttachedObject(playerid, index, T_CHAIR_MODEL, 7, 0.061999, -0.046, 0.095999, 90.6, -171.8, -10.5, 1.0, 1.0, 1.0);
	SetPlayerCameraPos(playerid, TableData[handle][E_TABLE_POS_X], TableData[handle][E_TABLE_POS_Y], TableData[handle][E_TABLE_POS_Z]+T_Z_CAMERA_OFFSET);
	SetPlayerCameraLookAt(playerid, TableData[handle][E_TABLE_POS_X], TableData[handle][E_TABLE_POS_Y], TableData[handle][E_TABLE_POS_Z]);
	ApplyAnimation(playerid, "INT_OFFICE", "OFF_Sit_Bored_Loop", 4.1, true, true, true, false, false, t_FORCE_SYNC:1);
	new tstr[64];
	format(tstr, sizeof(tstr), "%s\n* waiting next game *", ReturnPlayerName(playerid));
	PlayerData[playerid][E_PLAYER_3D_LABEL] = CreateDynamic3DTextLabel(tstr, 0x808080FF, Pos[0], Pos[1], Pos[2], 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid), -1,  5.0);

	//Information that will be used later
	PlayerData[playerid][E_PLAYER_CHAIR_ATTACH_INDEX_ID] = index;
	PlayerData[playerid][E_PLAYER_CURRENT_CHAIR_SLOT] = slot;

	PlayerData[playerid][E_PLAYER_CURRENT_HANDLE] = handle;
	Player_CreateTextdraws(playerid);
	//Iterators
	Internal_AddChairSlot(handle, slot);
	Iter_Add(IT_PlayersTable<handle>, playerid);
	TableData[handle][E_TABLE_CHAIR_PLAYER_ID][slot] = playerid;
	GivePlayerMoney(playerid, -TableData[handle][E_TABLE_BUY_IN]);
	PlayerData[playerid][E_PLAYER_TOTAL_CHIPS] = TableData[handle][E_TABLE_BUY_IN];
	SendPokerMessage(playerid, "You've been charged %s as a result of joining in the table.", cash_format(TableData[handle][E_TABLE_BUY_IN]));
	//Allow players to join a table where a game has already started but there are empty seats remaining (these players will be able to play once the current match finishes)
	if(TableData[handle][E_TABLE_CURRENT_STATE] != STATE_BEGIN)
	{
		if(Iter_Count(IT_PlayersTable<handle>) == 2 && !TableData[handle][E_TABLE_LOADING_GAME]) //Minimum two seats
		{
			if(!TableData[handle][E_TABLE_STING_NEW_GAME])
			{
				SendTableMessage(handle, ""COL_GREY"-- "COL_WHITE"There are currently two players in the table.");
				SendTableMessage(handle, ""COL_GREY"-- "COL_WHITE"Any players interested in being part of this game have "#T_START_DELAY" seconds to join the table.");
				SendTableMessage(handle, ""COL_GREY"-- "COL_WHITE"The game will begin in "#T_START_DELAY" seconds...");
				Iter_Clear(IT_PlayersInGame<handle>);
				TableData[handle][E_TABLE_LOADING_GAME] = true;
				SetTimerEx("Poker_StartGame", T_START_DELAY * 1000, false, "ii", handle, INVALID_PLAYER_ID);
			}
		}
	}
	else
	{
		SendPokerMessage(playerid, "You have entered this poker table but the game has already begun.");
		SendPokerMessage(playerid, "You must wait until this match is finished to play!");
		SendTableMessage(handle, "{25728B}- - Player %s has joined the table... - -", ReturnPlayerName(playerid));
	}

	foreach(new i: Player)
	{
		if(IsPlayerInRangeOfPoint(i, 35.0, Pos[0], Pos[1], Pos[2]))
		{
			Streamer_Update(i);
		}
	}

	#if T_SAVE_PLAYER_POS == true

	GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);
	SetPVarFloat(playerid, "t_temp_posX", Pos[0]);
	SetPVarFloat(playerid, "t_temp_posY", Pos[1]);
	SetPVarFloat(playerid, "t_temp_posZ", Pos[2]);
	GetPlayerFacingAngle(playerid, Pos[0]);
	SetPVarFloat(playerid, "t_temp_angle", Pos[0]);
	#endif

	SetPVarInt(playerid, "t_is_in_table", 1);
	return 1;
}



// purpose: get unattached player object index
stock Player_GetUnusedAttachIndex( playerid )
{
    for ( new i = 0; i < MAX_PLAYER_ATTACHED_OBJECTS; i ++ )
        if ( ! IsPlayerAttachedObjectSlotUsed( playerid, i ) )
            return i;

    return cellmin;
}

public Poker_StartGame(handle, dealer)
{
	TableData[handle][E_TABLE_STING_NEW_GAME] = false;
	if(Iter_Count(IT_PlayersTable<handle>) < 2)
	{
		TableData[handle][E_TABLE_LOADING_GAME] = false;
		return 0;
	}
	foreach (new i : Player) 
	{
		if(!Iter_Contains(IT_PlayersTable<handle>, i)) continue;
		if(!PlayerData[i][E_PLAYER_TOTAL_CHIPS])
		{
			SendPokerMessage(i, "You don't have any chips left.");
			SendPokerMessage(i, "You may join the table again and pay the buy-in fee to play once again!");
			SendTableMessage(handle, ""COL_GREY"-- "COL_WHITE"%s has been kicked out of the table. [Reason: Ran out of chips]", ReturnPlayerName(i));
			KickPlayerFromTable(i);
		}
	}

	if(Iter_Count(IT_PlayersTable<handle>) < 2)
	{
		SendTableMessage(handle, ""COL_GREY"-- "COL_WHITE"There aren't enough players to start a game");
		TableData[handle][E_TABLE_LOADING_GAME] = false;
		return 0;
	}
	for (new i = 0; i < 5; i ++) {
		TableData[handle][E_TABLE_COM_CARDS_VALUES][i] = ITER_NONE;
	}
	TableData[handle][E_TABLE_LOADING_GAME] = true;
	//Add these two players to (currently playing iterator)
	Iter_Clear(IT_PlayersInGame<handle>);
	Iter_Clear(IT_PlayersAllIn<handle>);
	foreach(new i: IT_PlayersTable<handle>)
	{
		Player_Clearchat(i);
		Iter_Add(IT_PlayersInGame<handle>, i);
		PlayerPlaySound(i, 1058, 0.0, 0.0, 0.0);
		PlayerData[i][E_PLAYER_IS_PLAYING] = true;
		ApplyAnimation(i, "INT_OFFICE", "OFF_Sit_Bored_Loop", 4.1, true, true, true, false, false, t_FORCE_SYNC:1);

	}
	TableData[handle][E_TABLE_CURRENT_STATE] = STATE_BEGIN; //Will prevent players from leaving the table

	foreach(new playerid: IT_PlayersInGame<handle>)
	{
		for(new i = 0; i < TableData[handle][E_TABLE_TOTAL_SEATS]; i++)
		{
			PlayerTextDrawSetString(playerid, PlayerData[playerid][E_PLAYER_CARDS_TXT_1][i], "LD_POKE:cdback");
			PlayerTextDrawSetString(playerid, PlayerData[playerid][E_PLAYER_CARDS_TXT_2][i], "LD_POKE:cdback");
			PlayerTextDrawHide(playerid, PlayerData[playerid][E_PLAYER_CARDS_TXT_1][i]);
			PlayerTextDrawHide(playerid, PlayerData[playerid][E_PLAYER_CARDS_TXT_2][i]);
		}
		for(new i = 0; i < 5; i++){
			PlayerTextDrawHide(playerid, PlayerData[playerid][E_PLAYER_COMMUNITY_CARDS_TXT][i]);
		}
		for(new i = 0; i < 5; i++){
			PlayerTextDrawHide(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][i]);
		}
		for(new i = 0; i < 6; i++){
			PlayerTextDrawHide(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][i]);
		}
	}

	TableData[handle][E_TABLE_POT_CHIPS][MAIN_POT] = 0;

	dealer = GetTurnAfterDealer(handle);
	//Select BB, SB in terms of a random dealer
	dealer = (dealer == INVALID_PLAYER_ID) ? Iter_Random(IT_PlayersInGame<handle>) : dealer;

	new count = Iter_Count(IT_PlayersInGame<handle>);
	if(count < 2)
	{
		return -1;
	}
	else if(count == 2)
	{
		TableData[handle][E_TABLE_PLAYER_DEALER_ID] = dealer;
		TableData[handle][E_TABLE_DEALER_SEAT] = PlayerData[dealer][E_PLAYER_CURRENT_CHAIR_SLOT];
		TableData[handle][E_TABLE_PLAYER_BIG_BLIND_ID] = dealer;
		SendTableMessage(handle, ""COL_GREY"-- "COL_WHITE"Player %s has been chosen to be the dealer and big blind in this first stage of the game!", ReturnPlayerName(dealer));
		UpdateDynamic3DTextLabelTextEx(PlayerData[dealer][E_PLAYER_3D_LABEL], -1, "{7AC72E}%s\n{FD4102}Big Blind + Dealer", ReturnPlayerName(dealer));

		//small blind..
		new next_turn = GetTurnAfterPlayer(handle, dealer);
		UpdateDynamic3DTextLabelTextEx(PlayerData[next_turn][E_PLAYER_3D_LABEL], -1, "{7AC72E}%s\n{FD4102}Small Blind", ReturnPlayerName(next_turn));
		SendTableMessage(handle, ""COL_GREY"-- "COL_WHITE"Player %s has been chosen to be the small blind in this first stage of the game!", ReturnPlayerName(next_turn));
		TableData[handle][E_TABLE_PLAYER_SMALL_BLIND_ID] = next_turn;


	}
	else
	{

		//Dealer
		UpdateDynamic3DTextLabelTextEx(PlayerData[dealer][E_PLAYER_3D_LABEL], -1, "{7AC72E}%s\n{FD4102}Dealer", ReturnPlayerName(dealer));
		SendTableMessage(handle, ""COL_GREY"-- "COL_WHITE"Player %s has been chosen to be the dealer in this first stage of the game!", ReturnPlayerName(dealer));
		TableData[handle][E_TABLE_PLAYER_DEALER_ID] = dealer;
		TableData[handle][E_TABLE_DEALER_SEAT] = PlayerData[dealer][E_PLAYER_CURRENT_CHAIR_SLOT];

		//Big blind
		new next_player = GetTurnAfterPlayer(handle, dealer);
		UpdateDynamic3DTextLabelTextEx(PlayerData[next_player][E_PLAYER_3D_LABEL], -1, "{7AC72E}%s\n{FD4102}Small Blind", ReturnPlayerName(next_player));
		SendTableMessage(handle, ""COL_GREY"-- "COL_WHITE"Player %s has been chosen to be the Small Blind in this first stage of the game!", ReturnPlayerName(next_player));
		TableData[handle][E_TABLE_PLAYER_SMALL_BLIND_ID] = next_player;

		//Small blind
		next_player = GetTurnAfterPlayer(handle, next_player);
		SendTableMessage(handle, ""COL_GREY"-- "COL_WHITE"Player %s has been chosen to be the Big Blind in this first stage of the game!", ReturnPlayerName(next_player));
		UpdateDynamic3DTextLabelTextEx(PlayerData[next_player][E_PLAYER_3D_LABEL], -1, "{7AC72E}%s\n{FD4102}Big Blind", ReturnPlayerName(next_player));
		TableData[handle][E_TABLE_PLAYER_BIG_BLIND_ID] = next_player;
	}


	foreach(new playerid: IT_PlayersInGame<handle>) //loop through the players already in the table
	{
		if(playerid != TableData[handle][E_TABLE_PLAYER_DEALER_ID] && playerid != TableData[handle][E_TABLE_PLAYER_BIG_BLIND_ID] && playerid != TableData[handle][E_TABLE_PLAYER_SMALL_BLIND_ID])
		{
			UpdateDynamic3DTextLabelTextEx(PlayerData[playerid][E_PLAYER_3D_LABEL], 0x7AC72EFF, "%s", ReturnPlayerName(playerid));
		}
		for(new k = 0; k < 6; k++)
		{
			PlayerTextDrawShow(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][k]);
		}
		UpdateInfoTextdrawsForPlayer(playerid);
		Streamer_Update(playerid);
	}

	SendTableMessage(handle, ""COL_GREY"-- "COL_WHITE"Dealer is shuffling the pack of cards. Cards will be handed out in two seconds...!");
	//If everything executes without stop, it wouldn't look that nice for me, so a timer comes handy..
	SetTimerEx("Poker_DealCards", 2000, false, "i", handle);
	return 1;
}


forward Poker_KickPlayers(handle);
public Poker_KickPlayers(handle)
{
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if(!Iter_Contains(IT_PlayersTable<handle>, i)) continue;
		if(!PlayerData[i][E_PLAYER_TOTAL_CHIPS])
		{
			if(GetPlayerMoney(i) < TableData[handle][E_TABLE_BUY_IN])
			{
				SendPokerMessage(i, "You don't have any chips left.");
				SendPokerMessage(i, "You may join the table again and pay the buy-in fee to play once again!");
				SendTableMessage(handle, ""COL_GREY"-- "COL_WHITE"%s has been kicked out of the table. [Reason: Ran out of chips]", ReturnPlayerName(i));
				KickPlayerFromTable(i);
			}
			else
			{
				Dialog_Show(i, BuyInConfirmation, DIALOG_STYLE_MSGBOX, "Buy-In", ""COL_WHITE"You've ran out of chips. Do you want to pay the buy-in fee again to continue playing?", "Yes", "No");
			}
		}
	}
	//Iter_Clear(IT_PlayersInGame<handle>);
	return 1;
}

stock StartNewPokerGame(handle, time)
{
	for (new i = 0; i < 5; i ++) {
		TableData[handle][E_TABLE_COM_CARDS_VALUES][i] = ITER_NONE;
	}

	foreach(new i: IT_PlayersInGame<handle>) {
		HidePlayerChoices(i);
	}

	//This will allow players to leave before the new game begins.
	TableData[handle][E_TABLE_CURRENT_STATE] = STATE_IDLE;
	TableData[handle][E_TABLE_STING_NEW_GAME] = true;

	TableData[handle][E_TABLE_FIRST_TURN] = INVALID_PLAYER_ID;
	TableData[handle][E_TABLE_CHECK_FIRST]  = false;
	TableData[handle][E_TABLE_CURRENT_TURN] = INVALID_PLAYER_ID;
	TableData[handle][E_TABLE_LOADING_GAME] = false;
	ResetLabel(handle);

	Iter_Clear(IT_TableCardSet[handle]);

	for(new i = 0; i < 52; i++)
		Iter_Add(IT_TableCardSet[handle], i);

	//Never change this order
	Iter_Clear(IT_PlayersAllIn<handle>);
	Iter_Clear(IT_Sidepots[handle]);

	SetTimerEx("Poker_KickPlayers", 1000 * (time - 5), false, "i", handle);

	for(new i = 0; i < T_MAX_CHAIRS_PER_TABLE; i++)
	{
		TableData[handle][E_TABLE_POT_CHIPS][i] = 0;
		Iter_Clear(It_SidepotMembers[_IT[handle][i]]);
	}
	Iter_Clear(IT_PlayersInGame<handle>);

	if(Iter_Count(IT_PlayersTable<handle>) >= 2)
	{
		SendTableMessage(handle, ""COL_GREY"-- "COL_WHITE"Starting a new game in %d seconds...", time);
		SetTimerEx("Poker_StartGame", 1000 * time, false, "ii", handle, INVALID_PLAYER_ID);
	}
	else
	{
		SendTableMessage(handle, ""COL_GREY"-- "COL_WHITE"There are not enough players to start a new game!");
	}
	return 1;
}

stock Internal_GetFreeChairSlot(handle)
{
	new seat_count = TableData[handle][E_TABLE_TOTAL_SEATS];
	for(new i = seat_count; i--; )
	{
		if(!TableData[handle][E_TABLE_IS_SEAT_TAKEN][i])
		{
			return i;
		}
	}
	return ITER_NONE;
}
stock Internal_AddChairSlot(handle, slot)
{
	TableData[handle][E_TABLE_IS_SEAT_TAKEN][slot] = true;
	return 1;
}
stock Internal_RemoveChairSlot(handle, slot)
{
	TableData[handle][E_TABLE_IS_SEAT_TAKEN][slot] = false;
	return 1;
}

stock RemoveChipsFromPlayer( forplayer, amount)
{
	PlayerData[forplayer][E_PLAYER_TOTAL_CHIPS] -= amount;
	return 1;
}

stock AbortGame(handle)
{
	if(TableData[handle][E_TABLE_CURRENT_STATE] != STATE_BEGIN) return 0;
	//Could have used Iter_SafeRemove, prefer not to
	for(new playerid = 0; playerid < MAX_PLAYERS; playerid++)
	{
		if(Iter_Contains(IT_PlayersTable<handle>, playerid))
		{
			KickPlayerFromTable(playerid);
		}
		CancelSelectTextDraw(playerid);
	}

	for(new i = 0; i < 5; i++)
	{
		TableData[handle][E_TABLE_COM_CARDS_VALUES][i] = ITER_NONE;
	}
	//This will allow players to leave before the new game begins.
	TableData[handle][E_TABLE_CURRENT_STATE] = STATE_IDLE;
	TableData[handle][E_TABLE_STING_NEW_GAME] = false;

	TableData[handle][E_TABLE_FIRST_TURN] = INVALID_PLAYER_ID;
	TableData[handle][E_TABLE_CHECK_FIRST]  = false;
	TableData[handle][E_TABLE_LOADING_GAME] = false;
	ResetLabel(handle);
	Iter_Clear(IT_TableCardSet[handle]);
	//Never change this order
	Iter_Clear(IT_PlayersAllIn<handle>);
	Iter_Clear(IT_Sidepots[handle]);

	for(new i = 0; i < T_MAX_CHAIRS_PER_TABLE; i++)
	{
		TableData[handle][E_TABLE_POT_CHIPS][i] = 0;
		Iter_Clear(It_SidepotMembers[_IT[handle][i]]);
	}

	for(new i = 0; i < 52; i++)
		Iter_Add(IT_TableCardSet[handle], i);

	TableData[handle][E_TABLE_CURRENT_STATE] = STATE_IDLE;
	return 1;
}

forward Poker_DealCards(handle);
public Poker_DealCards(handle)
{
	foreach(new playerid: IT_PlayersTable<handle>) //loop through the players already in the table
	{
		if(Iter_Contains(IT_PlayersInGame<handle>, playerid))
		{
			new seat = TableRotCorrections[TableData[PlayerData[playerid][E_PLAYER_CURRENT_HANDLE]][E_TABLE_TOTAL_SEATS]][ PlayerData[playerid][E_PLAYER_CURRENT_CHAIR_SLOT]];
			new card1 = Iter_Random(IT_TableCardSet[handle]);
			Iter_Remove(IT_TableCardSet[handle], card1);


			new card2 = Iter_Random(IT_TableCardSet[handle]);
			Iter_Remove(IT_TableCardSet[handle], card2);

			PlayerTextDrawSetString(playerid, PlayerData[playerid][E_PLAYER_CARDS_TXT_1][seat], CardData[card1][E_CARD_TEXTDRAW]);
			PlayerTextDrawSetString(playerid, PlayerData[playerid][E_PLAYER_CARDS_TXT_2][seat], CardData[card2][E_CARD_TEXTDRAW]);
			PlayerData[playerid][E_PLAYER_CARD_VALUES][0] = card1;
			PlayerData[playerid][E_PLAYER_CARD_VALUES][1] = card2;

			foreach(new p: IT_PlayersInGame<handle>)
			{
				seat = TableRotCorrections[TableData[PlayerData[p][E_PLAYER_CURRENT_HANDLE]][E_TABLE_TOTAL_SEATS]][ PlayerData[p][E_PLAYER_CURRENT_CHAIR_SLOT]];
				PlayerTextDrawShow(playerid, PlayerData[playerid][E_PLAYER_CARDS_TXT_1][seat]);
				PlayerTextDrawShow(playerid, PlayerData[playerid][E_PLAYER_CARDS_TXT_2][seat]);
				PlayerPlaySound(playerid, 1145, 0.0, 0.0, 0.0 );
			}

			PlayerData[playerid][E_PLAYER_CURRENT_BET] = 0;
		}
		else
		{
			for(new i = 0; i < TableData[handle][E_TABLE_TOTAL_SEATS]; i++)
			{
				PlayerTextDrawSetString(playerid, PlayerData[playerid][E_PLAYER_CARDS_TXT_1][i], "LD_POKE:cdback");
				PlayerTextDrawSetString(playerid, PlayerData[playerid][E_PLAYER_CARDS_TXT_2][i], "LD_POKE:cdback");
				PlayerTextDrawShow(playerid, PlayerData[playerid][E_PLAYER_CARDS_TXT_1][i]);
				PlayerTextDrawShow(playerid, PlayerData[playerid][E_PLAYER_CARDS_TXT_2][i]);
			}
		}

	}
	//Set variables

	TableData[handle][E_TABLE_CURRENT_ROUND] = ROUND_PRE_FLOP;




	new big_blind = TableData[handle][E_TABLE_PLAYER_BIG_BLIND_ID];
	new small_blind = TableData[handle][E_TABLE_PLAYER_SMALL_BLIND_ID];

	new bool: b_big_blind = (PlayerData[big_blind][E_PLAYER_TOTAL_CHIPS] > TableData[handle][E_TABLE_BIG_BLIND]);
	new bool: b_small_blind = (PlayerData[small_blind][E_PLAYER_TOTAL_CHIPS] > TableData[handle][E_TABLE_SMALL_BLIND]);
	if(b_big_blind && b_small_blind)
	{
		PlayerData[big_blind][E_PLAYER_CURRENT_BET] = TableData[handle][E_TABLE_BIG_BLIND];
		PlayerData[small_blind][E_PLAYER_CURRENT_BET] = TableData[handle][E_TABLE_SMALL_BLIND];
		SendTableMessage(handle, "{2DD9A9} * * %s posts a small blind of %s.. * *", ReturnPlayerName(TableData[handle][E_TABLE_PLAYER_SMALL_BLIND_ID]), cash_format(TableData[handle][E_TABLE_SMALL_BLIND]));
		SendTableMessage(handle, "{2DD9A9}  * * %s posts a big blind of %s.. * *", ReturnPlayerName(TableData[handle][E_TABLE_PLAYER_BIG_BLIND_ID]), cash_format(TableData[handle][E_TABLE_BIG_BLIND]));
		new next_turn = GetTurnAfterPlayer(handle, TableData[handle][E_TABLE_PLAYER_BIG_BLIND_ID]);
		TableData[handle][E_TABLE_LAST_BET] = TableData[handle][E_TABLE_BIG_BLIND];
		SetLastToRaise(handle, next_turn);
		RemoveChipsFromPlayer( big_blind, TableData[handle][E_TABLE_BIG_BLIND]);
		RemoveChipsFromPlayer( small_blind, TableData[handle][E_TABLE_SMALL_BLIND]);
		TableData[handle][E_TABLE_FIRST_TURN] = next_turn;
		TableData[handle][E_TABLE_CHECK_FIRST] = true;
		SendTurnMessage(handle, next_turn);

		UpdateTable(handle);
	}
	else
	{
		new next_turn = GetTurnAfterPlayer(handle, TableData[handle][E_TABLE_PLAYER_BIG_BLIND_ID]);
		SetLastToRaise(handle, next_turn);
		if(!b_small_blind)
		{

			ForcePlayerAllIn(small_blind, handle, false);
		}
		else
		{
			SendTableMessage(handle, "{2DD9A9} * * %s posts a small blind of %s.. * *", ReturnPlayerName(TableData[handle][E_TABLE_PLAYER_SMALL_BLIND_ID]), cash_format(TableData[handle][E_TABLE_SMALL_BLIND]));
			RemoveChipsFromPlayer( small_blind, TableData[handle][E_TABLE_SMALL_BLIND]);
			PlayerData[small_blind][E_PLAYER_CURRENT_BET] = TableData[handle][E_TABLE_SMALL_BLIND];
		}

		if(!b_big_blind)
		{
			TableData[handle][E_TABLE_LAST_TO_RAISE] = big_blind;
			TableData[handle][E_TABLE_LAST_BET] = PlayerData[big_blind][E_PLAYER_TOTAL_CHIPS];
			ForcePlayerAllIn(big_blind, handle, false);

			if(!b_small_blind && GetTurnAfterPlayerEx(handle, next_turn) == small_blind)
			{
				SetLastToRaise(handle, small_blind);
			}
		}
		else
		{

			SendTableMessage(handle, "{2DD9A9}  * * %s posts a big blind of %s.. * *", ReturnPlayerName(TableData[handle][E_TABLE_PLAYER_BIG_BLIND_ID]), cash_format(TableData[handle][E_TABLE_BIG_BLIND]));
			RemoveChipsFromPlayer( big_blind, TableData[handle][E_TABLE_BIG_BLIND]);
			PlayerData[big_blind][E_PLAYER_CURRENT_BET] = TableData[handle][E_TABLE_BIG_BLIND];
			TableData[handle][E_TABLE_LAST_BET] = TableData[handle][E_TABLE_BIG_BLIND];
		}

		if(Iter_Contains(IT_PlayersAllIn<handle>, next_turn))
		{
			CheckPotAndNextTurn(next_turn, handle);
		}
		else
		{
			SendTurnMessage(handle, next_turn);
		}
		UpdateTable(handle);

	}

	return 1;
}



static stock UpdateTable(handle)
{
	foreach(new playerid: IT_PlayersInGame<handle>)
	{
		UpdateInfoTextdrawsForPlayer(playerid);
		new const seat = PlayerData[playerid][E_PLAYER_CURRENT_CHAIR_SLOT];
		new str[128	];
		format(str, sizeof(str), "{34c5db}Chips: {db8d34}%s\n{db3a34}Last bet: {db8d34}%s", cash_format(PlayerData[playerid][E_PLAYER_TOTAL_CHIPS]), cash_format(PlayerData[playerid][E_PLAYER_CURRENT_BET]));
		UpdateDynamic3DTextLabelText(TableData[handle][E_TABLE_BET_LABELS][seat], T_BET_LABEL_COLOR, str);
		SetChipsValue(handle, PlayerData[playerid][E_PLAYER_CURRENT_CHAIR_SLOT], PlayerData[playerid][E_PLAYER_TOTAL_CHIPS]);

	}
	new str[256];
	new tmp[10];
	format(str, sizeof(str), "{59cdff}Main Pot: {ff9059}%s\n", cash_format(TableData[handle][E_TABLE_POT_CHIPS][MAIN_POT]));
	SetPotChipsValue(handle, TableData[handle][E_TABLE_POT_CHIPS][MAIN_POT]);
	if(Iter_Count(IT_Sidepots[handle] > 1))
	{
		strcat(str, "{008000}Side Pot:\n{008080}");
		foreach(new i: IT_Sidepots[handle])
		{
			if(i == MAIN_POT) continue;
			format(tmp, sizeof(tmp), "%s\n", cash_format(TableData[handle][E_TABLE_POT_CHIPS][i]));
			strcat(str, tmp);
		}
	}
	str[strlen(str)-1] = EOS;
	UpdateDynamic3DTextLabelText(TableData[handle][E_TABLE_POT_LABEL], T_BET_LABEL_COLOR, str);

	return 1;
}
static stock ShowChoicesToPlayer(playerid)
{
	new handle = PlayerData[playerid][E_PLAYER_CURRENT_HANDLE];
	//Call or check
	if(TableData[handle][E_TABLE_LAST_BET] == PlayerData[playerid][E_PLAYER_CURRENT_BET]) //check
	{
		PlayerTextDrawSetString(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][CALL], "Check");
	}
	else //call
	{
		PlayerTextDrawSetString(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][CALL], "Call");
	}

	//Bet, raise or all in
	if(TableData[handle][E_TABLE_LAST_BET] == 0)
	{
		PlayerTextDrawSetString(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][RAISE], "Bet");
		PlayerData[playerid][E_PLAYER_RCHOICE] = E_RAISE_BET;
	}
	else if(PlayerData[playerid][E_PLAYER_TOTAL_CHIPS] > TableData[handle][E_TABLE_LAST_BET] + PlayerData[playerid][E_PLAYER_CURRENT_BET])
	{
		PlayerTextDrawSetString(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][RAISE], "Raise");
		PlayerData[playerid][E_PLAYER_RCHOICE] = E_RAISE_RAISE;
	}
	else //player doesn't have enough money, only option is to go all in
	{
		PlayerTextDrawSetString(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][RAISE], "All In");
		PlayerData[playerid][E_PLAYER_RCHOICE] = E_RAISE_ALL_IN;
	}

	if(PlayerData[playerid][E_PLAYER_TOTAL_CHIPS] + PlayerData[playerid][E_PLAYER_CURRENT_BET] <= TableData[handle][E_TABLE_LAST_BET])
	{
		//all in and fold are the only options available
		PlayerTextDrawSetSelectable(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][CALL], false);
		PlayerTextDrawColor(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][CALL], COLOR_RED);
	}
	else
	{
		PlayerTextDrawSetSelectable(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][CALL], true);
		PlayerTextDrawColor(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][CALL], -1);
	}
	for(new i = 0; i < 5; i++)
	{
		PlayerTextDrawShow(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][i]);
	}


	SelectTextDraw(playerid, 0x00FF00FF);
	return 1;
}

static stock HidePlayerChoices(playerid)
{
	for(new i = 0; i < 5; i++)
	{
		PlayerTextDrawHide(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][i]);
	}
    CancelSelectTextDraw(playerid);
	return 1;
}

static stock SendTurnMessage(handle, playerid)
{
	SetPlayerClickedTxt(playerid, false);
	SendTableMessage(handle, "{008080}It's %s{008080}'s turn...", ReturnPlayerName(playerid));
	SendPokerMessage(playerid, "It's your turn. You have "#T_MAX_WAIT_TIME" seconds to make a decision.");
	TableData[handle][E_TABLE_CURRENT_TURN] = playerid;
	PlayerData[playerid][E_PLAYER_TIMER_STARTED] = true;
	PlayerData[playerid][E_PLAYER_TIMER_ID] = SetTimerEx("Timer_FoldPlayer", T_MAX_WAIT_TIME * 1000, false, "ii", handle, playerid);
	ShowChoicesToPlayer(playerid);
	return 1;
}

stock KillPlayerTurnTimer(playerid, bool: callback = false)
{
	new handle = PlayerData[playerid][E_PLAYER_CURRENT_HANDLE];
	if(!IsValidTable(handle))
	{
		//T_SendWarning("[KillPlayerTurnTimer] Invalid handle passed (%d) for playerid: %d", handle, playerid);
		return 0;
	}
	if(!Iter_Contains(IT_PlayersInGame<handle>, playerid))
	{
		//T_SendWarning("[KillPlayerTurnTimer] Invalid playerid passed: %d, handle: %d, player is not in the game.", playerid, handle);
		return 0;
	}
	if(!PlayerData[playerid][E_PLAYER_TIMER_STARTED]) return 0;

	PlayerData[playerid][E_PLAYER_TIMER_STARTED] = false;
	if(!callback)
		KillTimer(PlayerData[playerid][E_PLAYER_TIMER_ID]);

	return 1;
}
forward Timer_FoldPlayer(handle, playerid);
public Timer_FoldPlayer(handle, playerid)
{
	if(TableData[handle][E_TABLE_CURRENT_TURN] == playerid && PlayerData[playerid][E_PLAYER_TIMER_STARTED])
	{
		TableData[handle][E_TABLE_CURRENT_TURN] = INVALID_PLAYER_ID;
		HidePlayerChoices(playerid);
		Dialog_Show(playerid, 18, DIALOG_STYLE_INPUT, " ", " ", " ", " ");
		KillPlayerTurnTimer(playerid, true);
		if(!FoldPlayer(handle, playerid))
			CheckPotAndNextTurn(playerid, handle);
	}
	return 1;
}
/*

	GetTurnAfterPlayer(handle, playerid); //Returns the playerid of the next turn (skips players that have gone all in)
	GetTurnAfterPlayerEx(handle, playerid); //Returns the playerid of the next turn (does not skip players that went all in)
*/

forward CheckRounds(handle, bool: start_showdown);
public CheckRounds(handle, bool: start_showdown)
{
	new next_turn = INVALID_PLAYER_ID;
	//we can proceed to another round
	switch(TableData[handle][E_TABLE_CURRENT_ROUND])
	{
		case ROUND_PRE_FLOP:
		{
			//Display 3 cards now
			TableData[handle][E_TABLE_CURRENT_ROUND] = ROUND_FLOP;
			for(new i = 0; i < 3; i++)
			{
				new card = Iter_Random(IT_TableCardSet[handle]);
				Iter_Remove(IT_TableCardSet[handle], card);
				TableData[handle][E_TABLE_COM_CARDS_VALUES][i] = card;
				foreach(new k:  IT_PlayersTable<handle>)
				{
					//for(new j = 0; j < 15; j++) SendTableMessage(k, " ");

					PlayerTextDrawSetString(k, PlayerData[k][E_PLAYER_COMMUNITY_CARDS_TXT][i], CardData[card][E_CARD_TEXTDRAW]);
					PlayerTextDrawShow(k, PlayerData[k][E_PLAYER_COMMUNITY_CARDS_TXT][i]);
					PlayerData[k][E_PLAYER_CURRENT_BET] = 0;
					PlayerPlaySound(k, 1145, 0.0, 0.0, 0.0 );
				}
			}

			SendTableMessage(handle, "{D07035}======================================================================================");
			SendTableMessage(handle, "{D07035}									  The Flop 											");
			SendTableMessage(handle, "{D07035}======================================================================================");
			TableData[handle][E_TABLE_LAST_BET] = 0;

			if(start_showdown)
			{
				SetTimerEx("CheckRounds", 2000, false, "ib", handle, true);
			}
			else
			{
				//Player next to the dealer
				next_turn = GetTurnAfterDealer(handle);
				SetLastToRaise(handle, next_turn);
				//player next to the dealer is the next turn
				SendTurnMessage(handle, next_turn);
			}



		}
		case ROUND_FLOP:
		{
			//Display 1 card
			TableData[handle][E_TABLE_CURRENT_ROUND] = ROUND_TURN;
			new card = Iter_Random(IT_TableCardSet[handle]);
			Iter_Remove(IT_TableCardSet[handle], card);
			TableData[handle][E_TABLE_COM_CARDS_VALUES][3] = card;
			foreach(new k:  IT_PlayersTable<handle>)
			{
				//for(new j = 0; j < 15; j++) SendTableMessage(k, " ");

				PlayerData[k][E_PLAYER_CURRENT_BET] = 0;
				PlayerTextDrawSetString(k, PlayerData[k][E_PLAYER_COMMUNITY_CARDS_TXT][3], CardData[card][E_CARD_TEXTDRAW]);
				PlayerTextDrawShow(k, PlayerData[k][E_PLAYER_COMMUNITY_CARDS_TXT][3]);
				PlayerPlaySound(k, 1145, 0.0, 0.0, 0.0 );
			}
			TableData[handle][E_TABLE_LAST_BET] = 0;

			SendTableMessage(handle, "{D07035}======================================================================================");
			SendTableMessage(handle, "{D07035}									  The Turn 											");
			SendTableMessage(handle, "{D07035}======================================================================================");


			if(start_showdown)
			{
				SetTimerEx("CheckRounds", 2000, false, "ib", handle, true);
			}
			else
			{
				//Player next to the dealer
				next_turn = GetTurnAfterDealer(handle);
				SetLastToRaise(handle, next_turn);
				//player next to the dealer is the next turn
				SendTurnMessage(handle, next_turn);
			}

		}
		case ROUND_TURN:
		{
			//Display 1 more card
			TableData[handle][E_TABLE_CURRENT_ROUND] = ROUND_RIVER;
			new card = Iter_Random(IT_TableCardSet[handle]);
			Iter_Remove(IT_TableCardSet[handle], card);
			TableData[handle][E_TABLE_COM_CARDS_VALUES][4] = card;
			foreach(new k:  IT_PlayersTable<handle>)
			{
				//for(new j = 0; j < 15; j++) SendTableMessage(k, " ");
				PlayerData[k][E_PLAYER_CURRENT_BET] = 0;
				PlayerTextDrawSetString(k, PlayerData[k][E_PLAYER_COMMUNITY_CARDS_TXT][4], CardData[card][E_CARD_TEXTDRAW]);
				PlayerTextDrawShow(k, PlayerData[k][E_PLAYER_COMMUNITY_CARDS_TXT][4]);
				PlayerPlaySound(k, 1145, 0.0, 0.0, 0.0 );
			}
			TableData[handle][E_TABLE_LAST_BET] = 0;

			SendTableMessage(handle, "{D07035}======================================================================================");
			SendTableMessage(handle, "{D07035}									  The River 										");
			SendTableMessage(handle, "{D07035}======================================================================================");
			//SendTableMessage(handle, ""COL_GREY"-- "COL_WHITE"%s, %s, %s", CardData[TableData[handle][T_COM_CARDS_VALUES][0]][E_CARD_NAME], CardData[TableData[handle][T_COM_CARDS_VALUES][1]][E_CARD_NAME], CardData[TableData[handle][T_COM_CARDS_VALUES][2]][E_CARD_NAME]);
			if(start_showdown)
			{
				SetTimerEx("CheckRounds", 2000, false, "ib", handle, false);
			}
			else
			{
				//Player next to the dealer
				next_turn = GetTurnAfterDealer(handle);
				SetLastToRaise(handle, next_turn);
				//player next to the dealer is the next turn
				SendTurnMessage(handle, next_turn);
			}
		}
		case ROUND_RIVER:
		{
			CheckShowdown(handle);
			//Start a new game
			StartNewPokerGame(handle, 8);

			//Show down
		}
	}
	return 1;
}

stock CheckShowdown(handle)
{
	SendTableMessage(handle, "{F25B13}======================================================================================");
	SendTableMessage(handle, "{F25B13}									  Showdown 											");
	SendTableMessage(handle, "{F25B13}======================================================================================");

	foreach(new p: IT_PlayersTable<handle>) //loop through the players already in the table
	{
		foreach(new k: IT_PlayersInGame<handle>) //loop through the players already in the table
		{
			new seat = TableRotCorrections[TableData[PlayerData[k][E_PLAYER_CURRENT_HANDLE]][E_TABLE_TOTAL_SEATS]][ PlayerData[k][E_PLAYER_CURRENT_CHAIR_SLOT]];
			new card1 = PlayerData[k][E_PLAYER_CARD_VALUES][0];
			new card2 = PlayerData[k][E_PLAYER_CARD_VALUES][1];

			PlayerTextDrawSetString(p, PlayerData[p][E_PLAYER_CARDS_TXT_1][seat], CardData[card1][E_CARD_TEXTDRAW]);
			PlayerTextDrawSetString(p, PlayerData[p][E_PLAYER_CARDS_TXT_2][seat], CardData[card2][E_CARD_TEXTDRAW]);
		}
	}
	if(!Iter_Contains(IT_Sidepots[handle], MAIN_POT))
	{
		Iter_Add(IT_Sidepots[handle], MAIN_POT);
		foreach(new k: IT_PlayersInGame<handle>) //loop through the players already in the table
		{
			Iter_Add(It_SidepotMembers[_IT[handle][MAIN_POT]], k);
		}
	}
	foreach(new pot_id: IT_Sidepots[handle])
	{
		new highest_rank = -0x7FFFFFFF;
		new PlayerRanks[MAX_PLAYERS];
		new high_id = INVALID_PLAYER_ID;
		foreach(new p: It_SidepotMembers[_IT[handle][pot_id]])
		{
			if(!Iter_Contains(IT_PlayersInGame<handle>, p)) continue;
			new card[7];
			card[0] = GetCardNativeIndex(PlayerData[p][E_PLAYER_CARD_VALUES][0]);
			card[1] = GetCardNativeIndex(PlayerData[p][E_PLAYER_CARD_VALUES][1]);
			card[2] = GetCardNativeIndex(TableData[handle][E_TABLE_COM_CARDS_VALUES][0]);
			card[3] = GetCardNativeIndex(TableData[handle][E_TABLE_COM_CARDS_VALUES][1]);
			card[4] = GetCardNativeIndex(TableData[handle][E_TABLE_COM_CARDS_VALUES][2]);
			card[5] = GetCardNativeIndex(TableData[handle][E_TABLE_COM_CARDS_VALUES][3]);
			card[6] = GetCardNativeIndex(TableData[handle][E_TABLE_COM_CARDS_VALUES][4]);

			PlayerRanks[p] = calculate_hand_worth(card, 7);

			if(PlayerRanks[p] > highest_rank)
			{
				highest_rank = PlayerRanks[p];
				high_id = p;
			}
		}
		new count = 0;
		foreach(new p: It_SidepotMembers[_IT[handle][pot_id]])
		{
			if(!Iter_Contains(IT_PlayersInGame<handle>, p)) continue;
			if(PlayerRanks[p] == highest_rank)
			{
				count++;
			}
		}
		if(count == 1)
		{
			foreach(new p: It_SidepotMembers[_IT[handle][pot_id]])
			{
				if(!Iter_Contains(IT_PlayersInGame<handle>, p)) continue;
				if(p == high_id) continue;
				ApplyAnimation(p, "INT_OFFICE", "OFF_Sit_Crash", 4.1, false, true, true, true, false, t_FORCE_SYNC:1);
			}
			new w_chips = floatround(float(TableData[handle][E_TABLE_POT_CHIPS][pot_id]) * (1.0 - T_POT_FEE_RATE));
			SendTableMessage(handle, "{9FCF30}****************************************************************************************");
			SendTableMessage(handle, "{9FCF30}Player {FF8000}%s {9FCF30}has won with a {377CC8}%s", ReturnPlayerName(high_id), HAND_RANKS[highest_rank >> 12]);
			SendTableMessage(handle, "{9FCF30}Prize: {377CC8}%s | -%0.0f%s percent fee.", cash_format(w_chips), T_POT_FEE_RATE * 100.0, "%%");
			SendTableMessage(handle, "{9FCF30}****************************************************************************************");
			if (strmatch(HAND_RANKS[highest_rank >> 12], "Royal Flush")) printf("****\nRoyal Flush Player %s\n****\n", ReturnPlayerName(high_id));
			PlayerData[high_id][E_PLAYER_TOTAL_CHIPS] += w_chips;
		}
		else
		{
			SendTableMessage(handle, "{9FCF30}****************************************************************************************");
			SendTableMessage(handle, "{9FCF30}Draw! These players have won with a {377CC8}%s:", HAND_RANKS[highest_rank >> 12]);
			new w_chips = floatround(float(TableData[handle][E_TABLE_POT_CHIPS][pot_id]) * (1.0 - T_POT_FEE_RATE));
			new amount = w_chips / count;
			foreach(new p: It_SidepotMembers[_IT[handle][pot_id]])
			{
				if(!Iter_Contains(IT_PlayersInGame<handle>, p)) continue;
				if(PlayerRanks[p] == highest_rank)
				{
					SendTableMessage(handle, "{9FCF30}%s", ReturnPlayerName(p));
					PlayerData[p][E_PLAYER_TOTAL_CHIPS] += amount;
				}
				else
				{
					ApplyAnimation(p, "INT_OFFICE", "OFF_Sit_Crash", 4.1, false, true, true, true, false, t_FORCE_SYNC:1);
				}
			}
			SendTableMessage(handle, "{9FCF30}Each receives 1/%d of the total pot available. | -%0.0f%s percent fee", count, T_POT_FEE_RATE * 100.0, "%%");
			SendTableMessage(handle, "{9FCF30}****************************************************************************************");
		}
		UpdateTable(handle);
	}
	return 1;
}
stock CheckPotAndNextTurn(playerid, handle)
{
	if(GetPVarInt(playerid, "t_Clicked"))
	{
		SetPVarInt(playerid, "t_Clicked", 0);
	}
	HidePlayerChoices(playerid);
	new bool: is_cycle_complete = false;

	new next_turn = GetTurnAfterPlayer(handle, playerid);
	new last_to_raise = TableData[handle][E_TABLE_LAST_TO_RAISE];


	if(next_turn == INVALID_PLAYER_ID){
		is_cycle_complete = true;
	}

	if(!is_cycle_complete)
	{
		if(next_turn == last_to_raise || next_turn == playerid)
		{
			is_cycle_complete = true;
		}
		else
		{
			//further checking
			if(Iter_Count(IT_PlayersAllIn<handle>))
			{
				new next_player = INVALID_PLAYER_ID;
				new last_player = playerid;
				for(new i = 0; i < Iter_Count(IT_PlayersInGame<handle>); i++)
				{
					next_player = GetTurnAfterPlayerEx(handle, last_player);
					if(!Iter_Contains(IT_PlayersAllIn<handle>, next_player)) break;
					if(next_player == last_to_raise)
					{
						is_cycle_complete = true;
						break;
					}
					last_player = next_player;
				}
			}

		}

		if(!is_cycle_complete)
		{
			if(!Iter_Contains(IT_PlayersInGame<handle>, last_to_raise))
			{
				new const total_seats = TableData[handle][E_TABLE_TOTAL_SEATS];
				new slot = GetPlayerSeat(playerid) - 1;
				if(slot < 0) slot = total_seats - 1;
				new next_slot = ITER_NONE;
				for(new i = 0; i < total_seats; i++)
				{
					if(slot < 0) slot = total_seats - 1;
					next_slot = slot;
					new player = TableData[handle][E_TABLE_CHAIR_PLAYER_ID][next_slot];
					if(Iter_Contains(IT_PlayersInGame<handle>, player)) break;

					if(next_slot == TableData[handle][E_TABLE_LAST_TO_RAISE_SEAT])
					{
						is_cycle_complete = true;
						break;
					}
					slot--;
				}
			}

		}
	}

	/*if(TableData[handle][E_TABLE_FIRST_TURN] == playerid && TableData[handle][E_TABLE_CHECK_FIRST] && PlayerData[playerid][E_PLAYER_FOLDED])
	{
		new turn = GetTurnAfterPlayer(handle, playerid);
		SetLastToRaise(handle, turn);
		is_cycle_complete = false;
		TableData[handle][E_TABLE_FIRST_TURN] = INVALID_PLAYER_ID;
		TableData[handle][E_TABLE_CHECK_FIRST] = false;
	}*/

	PlayerData[playerid][E_PLAYER_FOLDED] = false;
	if(is_cycle_complete)
	{
		if(Iter_Count(IT_PlayersAllIn<handle>))
		{
			/*==================================================================================================
				Main pot and sidepot creation
			==================================================================================================*/

			for(new i = 0; i < Iter_Count(IT_PlayersInGame<handle>); i++)
			{
				new p_count = 0;
				new min_bet = cellmax;
				foreach(new player: IT_PlayersInGame<handle>)
				{
					new const player_bet = PlayerData[player][E_PLAYER_CURRENT_BET];
					if(!player_bet) continue;
					if(player_bet < min_bet)
					{
						min_bet = player_bet;
					}
					p_count++;
				}
				if(!p_count || p_count == 1)
				{
					break;
				}
				else //greater than two players
				{
					new pot_id = Iter_Free(IT_Sidepots[handle]);
					TableData[handle][E_TABLE_POT_CHIPS][pot_id] += min_bet * p_count;
					foreach(new player: IT_PlayersInGame<handle>)
					{
						if(!PlayerData[player][E_PLAYER_CURRENT_BET]) continue;
						PlayerData[player][E_PLAYER_CURRENT_BET] -= min_bet;
						Iter_Add(It_SidepotMembers[_IT[handle][pot_id]], player);
					}
					Iter_Add(IT_Sidepots[handle], pot_id);
				}
			}
			//Return any excess
			foreach(new player: IT_PlayersInGame<handle>)
			{
				if(!PlayerData[player][E_PLAYER_CURRENT_BET]) continue;
				PlayerData[player][E_PLAYER_TOTAL_CHIPS] += PlayerData[player][E_PLAYER_CURRENT_BET];
			}
		}
		else
		{
			foreach(new player: IT_PlayersInGame<handle>)
			{
				TableData[handle][E_TABLE_POT_CHIPS][MAIN_POT] += PlayerData[player][E_PLAYER_CURRENT_BET];
			}
			UpdateTable(handle);
		}

		new const all_in = Iter_Count(IT_PlayersAllIn<handle>);
		new const current_players = Iter_Count(IT_PlayersInGame<handle>);
		if(all_in == current_players || all_in == current_players - 1)
		{
			CheckRounds(handle, true);
		}
		else
		{
			CheckRounds(handle, false);
		}
	}
	else
	{
		SendTurnMessage(handle, next_turn);
	}
	UpdateTable(handle);
	return 1;
}

stock bool: FoldPlayer(handle, playerid)
{
	ApplyAnimation(playerid, "INT_OFFICE", "OFF_Sit_Crash", 4.1, false, true, true, true, false, t_FORCE_SYNC:1);
	PlayerData[playerid][E_PLAYER_FOLDED] = true;
	KillPlayerTurnTimer(playerid);
	SendTableMessage(handle, "{2DD9A9}  * * %s folds.. * *", ReturnPlayerName(playerid));
	SetPlayerChatBubbleEx(playerid, -1, 30.0, 2000, "{D6230A}** FOLDS ** ");

	PlayerData[playerid][E_PLAYER_IS_PLAYING] = false;
	TableData[handle][E_TABLE_POT_CHIPS][MAIN_POT] += PlayerData[playerid][E_PLAYER_CURRENT_BET];
	HidePlayerChoices(playerid);
	Iter_Remove(IT_PlayersInGame<handle>, playerid);
	new count = Iter_Count(IT_PlayersInGame<handle>);
	if(count == 1)
	{
		Iter_Remove(IT_PlayersInGame<handle>, playerid);
		new winner = Iter_First(IT_PlayersInGame<handle>);
		HidePlayerChoices(winner);
		SendTableMessage(handle, "{D4AF37}****************************************************************************************");
		SendTableMessage(handle, "{D4AF37}Player {FFFFFF}%s {D4AF37}has won the game!", ReturnPlayerName(winner));
		new w_chips = floatround(float(TableData[handle][E_TABLE_POT_CHIPS][MAIN_POT]) * (1.0 - T_POT_FEE_RATE));
		SendTableMessage(handle, "{D4AF37}Prize: {FFFFFF}%s | {D4AF37}-%0.0f percent fee", cash_format(w_chips), T_POT_FEE_RATE * 100.0);
		SendTableMessage(handle, "{D4AF37}****************************************************************************************");
		PlayerData[winner][E_PLAYER_TOTAL_CHIPS]  += w_chips;
		PlayerData[winner][E_PLAYER_TOTAL_CHIPS]  += PlayerData[winner][E_PLAYER_CURRENT_BET];
		UpdateTable(handle);
		StartNewPokerGame(handle, 8);
		TableData[handle][E_TABLE_CURRENT_TURN] = INVALID_PLAYER_ID;
		return true;
	}
	else if(!count)
	{
		Iter_Remove(IT_PlayersInGame<handle>, playerid);
		//Might happen if all the players disconnect
		AbortGame(handle);
		return true;
	}
	else if(TableData[handle][E_TABLE_CURRENT_TURN] == playerid)
	{
		KillTimer(PlayerData[playerid][E_PLAYER_TIMER_ID]);
		PlayerData[playerid][E_PLAYER_TIMER_STARTED] = false;
		return false;
	}
	else
	{
		return false;
	}
}
hook OnPlayerClickPlayerTD(playerid, PlayerText:playertextid)
{
	if(PlayerData[playerid][E_PLAYER_IS_PLAYING])
	{

		if(GetPlayerClickedTxt(playerid)) return 1;
		new handle = PlayerData[playerid][E_PLAYER_CURRENT_HANDLE];
		if(TableData[handle][E_TABLE_CURRENT_TURN] != playerid) {
			HidePlayerChoices(playerid);
			return 1;
		}
		if(playertextid == PlayerData[playerid][E_PLAYER_CHOICES_TXT][FOLD])
		{
			//Fold
			SetPlayerClickedTxt(playerid, true);
			if(!FoldPlayer(handle, playerid))
				CheckPotAndNextTurn(playerid, handle);
		}
		else if(playertextid ==  PlayerData[playerid][E_PLAYER_CHOICES_TXT][CALL])
		{
			//Call or check
			if(TableData[handle][E_TABLE_LAST_BET] == PlayerData[playerid][E_PLAYER_CURRENT_BET]) //check
			{
				SetPlayerClickedTxt(playerid, true);
				KillPlayerTurnTimer(playerid);
				SendTableMessage(handle, "{2DD9A9}  * * %s checks .. * *", ReturnPlayerName(playerid));
				SetPlayerChatBubbleEx(playerid, -1, 30.0, 2000, "{22B1BD}** CHECKS ** ");
			}
			else //call
			{
				new dif = TableData[handle][E_TABLE_LAST_BET] - PlayerData[playerid][E_PLAYER_CURRENT_BET];
				if(PlayerData[playerid][E_PLAYER_TOTAL_CHIPS] >= dif)
				{
					KillPlayerTurnTimer(playerid);
					SendTableMessage(handle, "{2DD9A9}  * * %s calls %s .. * *", ReturnPlayerName(playerid), cash_format(dif));
					SetPlayerChatBubbleEx(playerid, -1, 30.0, 2000, "{22B1BD}** CALLS %s ** ", cash_format(dif));
					RemoveChipsFromPlayer( playerid, dif);
					PlayerData[playerid][E_PLAYER_CURRENT_BET] = TableData[handle][E_TABLE_LAST_BET];
					SetPlayerClickedTxt(playerid, true);
				}
				else
				{
					SendPokerMessage(playerid, "ERROR: You can't call as you don't have enough chips. You have two possible options: going all in or folding.");
					return 1;
				}

			}
			CheckPotAndNextTurn(playerid, handle);
		}
		else if(playertextid ==  PlayerData[playerid][E_PLAYER_CHOICES_TXT][RAISE])
		{
			switch(PlayerData[playerid][E_PLAYER_RCHOICE])
			{
				case E_RAISE_BET:
				{
					SendPokerMessage(playerid, "Please enter an amount to bet, the total amount of chips you current have is: %d", PlayerData[playerid][E_PLAYER_TOTAL_CHIPS]);
					ShowPlayerRaiseDialog(playerid);
					HidePlayerChoices(playerid);
				}
				case E_RAISE_RAISE:
				{
					SendPokerMessage(playerid, "Please enter an amount to raise, the total amount of chips you current have is: %d", PlayerData[playerid][E_PLAYER_TOTAL_CHIPS]);
					HidePlayerChoices(playerid);
					ShowPlayerRaiseDialog(playerid);
				}
				case E_RAISE_ALL_IN:
				{
					ForcePlayerAllIn(playerid, handle);
					SetPlayerClickedTxt(playerid, true);
				}
			}
		}
	}
	return 1;
}


stock ForcePlayerAllIn(playerid, handle, bool:checkpot = true)
{
	ApplyAnimation(playerid, "INT_OFFICE", "OFF_Sit_Idle_Loop", 4.1, true, true, true, false, false, t_FORCE_SYNC:1);
	KillPlayerTurnTimer(playerid);
	Iter_Add(IT_PlayersAllIn<handle>, playerid);
	new raise = PlayerData[playerid][E_PLAYER_TOTAL_CHIPS] + PlayerData[playerid][E_PLAYER_CURRENT_BET];
	PlayerData[playerid][E_PLAYER_CURRENT_BET] = raise;
	SendTableMessage(handle, "{2DD9A9}  * * %s goes all in with %s .. * *", ReturnPlayerName(playerid), cash_format(raise));
	SetPlayerChatBubbleEx(playerid, -1, 30.0, 2000, "{9512CD}** ALL IN with %s ** ", cash_format(raise));
	PlayerData[playerid][E_PLAYER_TOTAL_CHIPS] = 0;
	if(checkpot)
		CheckPotAndNextTurn(playerid, handle);
	return 1;
}

stock ShowPlayerRaiseDialog(playerid)
{
new dialogStr[256]; format(dialogStr, sizeof(dialogStr), "{FFFFFF}Please input the desired amount of chips: \n{FFFFFF}You may type {FF8000}%d {FFFFFF} if you want to go All In\n", PlayerData[playerid][E_PLAYER_TOTAL_CHIPS]); return Dialog_Show(playerid, RaiseInput, DIALOG_STYLE_INPUT, "{FF8000}Input", dialogStr, "Submit", "Cancel");
}

Dialog:BuyInConfirmation(playerid, response, listitem, inputtext[])
{
    new handle = PlayerData[playerid][E_PLAYER_CURRENT_HANDLE];
    if (!IsValidTable(handle)) return 1;
    if (!Iter_Contains(IT_PlayersTable<handle>, playerid)) return 1;

    if (response)
    {
        GivePlayerMoney(playerid, -TableData[handle][E_TABLE_BUY_IN]);
        PlayerData[playerid][E_PLAYER_TOTAL_CHIPS] = TableData[handle][E_TABLE_BUY_IN];
        SendTableMessage(handle, COL_GREY"-- "COL_WHITE"%s has paid the buy-in fee of %s chips to keep playing.", ReturnPlayerName(playerid), cash_format(TableData[handle][E_TABLE_BUY_IN]));
    }
    else
    {
        SendTableMessage(handle, COL_GREY"-- "COL_WHITE"%s has been kicked out of the table. [Reason: Failure to pay the buy-in fee]", ReturnPlayerName(playerid));
        KickPlayerFromTable(playerid);
    }

    return 1;
}


Dialog:RaiseInput(playerid, response, listitem, inputtext[])
{
    new handle = PlayerData[playerid][E_PLAYER_CURRENT_HANDLE];
    if (!IsValidTable(handle)) return 0;
    if (!Iter_Contains(IT_PlayersTable<handle>, playerid)) return 1;

    if (response)
    {
        if (TableData[handle][E_TABLE_CURRENT_STATE] != STATE_BEGIN)
            return SendPokerMessage(playerid, "There isn't any active game at the moment."), 0;

        if (!Iter_Contains(IT_PlayersInGame<handle>, playerid))
            return 0;

        new raise;
        if (sscanf(inputtext, "d", raise))
            return SendPokerMessage(playerid, "Input must be numeric."), ShowPlayerRaiseDialog(playerid), 1;

        if (raise < 0)
            return SendPokerMessage(playerid, "Input must be greater than 0."), ShowPlayerRaiseDialog(playerid), 1;

        if (raise > PlayerData[playerid][E_PLAYER_TOTAL_CHIPS])
            return SendPokerMessage(playerid, "You don't have that many chips available."), ShowPlayerRaiseDialog(playerid), 1;

        if (raise <= TableData[handle][E_TABLE_LAST_BET])
            return SendPokerMessage(playerid, "Value must be greater than the last bet: %s", cash_format(TableData[handle][E_TABLE_LAST_BET])), ShowPlayerRaiseDialog(playerid), 1;

        KillPlayerTurnTimer(playerid);

        if (raise == PlayerData[playerid][E_PLAYER_TOTAL_CHIPS])
        {
            ApplyAnimation(playerid, "INT_OFFICE", "OFF_Sit_Idle_Loop", 4.1, true, true, true, false, false, t_FORCE_SYNC:1);
            SendTableMessage(handle, "{2DD9A9}  * * %s goes all in with %s .. * *", ReturnPlayerName(playerid), cash_format(raise));
            SetPlayerChatBubbleEx(playerid, -1, 30.0, 2000, "{9512CD}** ALL IN with %s **", cash_format(raise));
            Iter_Add(IT_PlayersAllIn<handle>, playerid);
        }
        else
        {
            new dif = raise - PlayerData[playerid][E_PLAYER_CURRENT_BET];
            if (PlayerData[playerid][E_PLAYER_RCHOICE] == E_RAISE_BET)
            {
                SendTableMessage(handle, "{2DD9A9}  * * %s bets %s .. * *", ReturnPlayerName(playerid), cash_format(raise));
                SetPlayerChatBubbleEx(playerid, -1, 30.0, 2000, "{31CA15}** BETS %s **", cash_format(raise));
            }
            else
            {
                SendTableMessage(handle, "{2DD9A9}  * * %s raises to %s .. * *", ReturnPlayerName(playerid), cash_format(raise));
                SetPlayerChatBubbleEx(playerid, -1, 30.0, 2000, "{31CA15}** RAISES to %s **", cash_format(raise));
            }
            RemoveChipsFromPlayer(playerid, dif);
        }

        SetLastToRaise(handle, playerid);
        PlayerData[playerid][E_PLAYER_CURRENT_BET] = raise;
        TableData[handle][E_TABLE_LAST_BET] = raise;
        CheckPotAndNextTurn(playerid, handle);
    }
    else
    {
        if (TableData[handle][E_TABLE_CURRENT_TURN] == playerid)
        {
            SetPlayerClickedTxt(playerid, false);
            ShowChoicesToPlayer(playerid);
        }
        else Dialog_Show(playerid, -1, DIALOG_STYLE_INPUT, " ", " ", " ", " ");
    }

    return 1;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(PRESSED(KEY_SECONDARY_ATTACK))
	{
		new handle = GetClosestTableForPlayer(playerid);
		if(handle != ITER_NONE)
		{
			if(TableData[handle][E_TABLE_VIRTUAL_WORLD] == GetPlayerVirtualWorld(playerid) && TableData[handle][E_TABLE_INTERIOR] == GetPlayerInterior(playerid))
			{
				if(!Iter_Contains(IT_PlayersTable<handle>, playerid))
				{
					if(IsPlayerInRangeOfTable(playerid, handle, T_JOIN_TABLE_RANGE))
					{
						AddPlayerToTable(playerid, handle);
					}
				}
				else
				{
					if((Iter_Contains(IT_PlayersInGame<handle>, playerid) && TableData[handle][E_TABLE_CURRENT_STATE] == STATE_BEGIN)
					|| TableData[T_MAX_POKER_TABLES][E_TABLE_LOADING_GAME])
					{
						SendPokerMessage(playerid, "You cannot exit this table as there's currently an active match under process.");
						return 0;
					}
					KickPlayerFromTable(playerid);
				}
			}
		}
	}
	return 1;

}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath(playerid, killerid, reason)
#endif
{
	Player_CheckPokerGame(playerid, "Died");
	return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
	Player_CheckPokerGame(playerid, "Disconnected");
	return 1;
}

stock Player_CheckPokerGame(playerid, const reason[])
{
	if(GetPVarInt(playerid, "t_is_in_table"))
    {
        new handle = PlayerData[playerid][E_PLAYER_CURRENT_HANDLE];
        if(Iter_Contains(IT_PlayersInGame<handle>, playerid)) {
            if(!FoldPlayer(handle, playerid)) {
                CheckPotAndNextTurn(playerid, handle);
            }
        }

        SendTableMessage(handle, "%s(%d) has been kicked out from the table (Reason: %s).", ReturnPlayerName(playerid), playerid, reason);
        KickPlayerFromTable(playerid);
    }
    return 1;
}
