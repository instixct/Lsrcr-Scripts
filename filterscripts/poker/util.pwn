/*
	Poker messaging and small shared helpers.
*/

stock SetPlayerChatBubbleEx(playerid, color, Float:drawdistance, expiretime, const format[], va_args<>)
{
	return SetPlayerChatBubble(playerid, va_return(format, va_start<5>), color, drawdistance, expiretime);
}

stock UpdateDynamic3DTextLabelTextEx(STREAMER_TAG_3D_TEXT_LABEL:id, color, const format[], va_args<>)
{
	return UpdateDynamic3DTextLabelText(id, color, va_return(format, va_start<3>));
}

stock SendClientMessageFormatted(playerid, colour, const format[], va_args<>)
{
	static out[144];
	va_format(out, sizeof out, format, va_start<3>);

	if(playerid == INVALID_PLAYER_ID)
		return SendClientMessageToAll(colour, out);

	return SendClientMessage(playerid, colour, out);
}

stock SendPokerMessage(playerid, const message_format[], va_args<>)
{
	static body[144];
	static prefixed[160];
	va_format(body, sizeof body, message_format, va_start<2>);
	format(prefixed, sizeof prefixed, "{D4AF37}Poker: {FFFFFF}%s", body);
	return SendClientMessage(playerid, 0xD4AF37FF, prefixed);
}

stock SendTableMessage(handle, const format[], va_args<>)
{
	new message[164];
	va_format(message, sizeof message, format, va_start<2>);

	foreach(new playerid: IT_PlayersTable<handle>)
		SendClientMessage(playerid, 0xD4AF37FF, message);

	return 1;
}

stock SetPlayerClickedTxt(playerid, bool:choice)
{
	PlayerData[playerid][E_PLAYER_CLICKED_TXT] = choice;
	return 1;
}

#define GetPlayerClickedTxt(%0) (PlayerData[(%0)][E_PLAYER_CLICKED_TXT])

stock Poker_StreamUpdateNearTable(Float:x, Float:y, Float:z)
{
	foreach(new playerid: Player)
	{
		if(IsPlayerInRangeOfPoint(playerid, 35.0, x, y, z))
			Streamer_Update(playerid);
	}
	return 1;
}

stock Poker_ApplyTableFeltMaterial(objectid, buy_in)
{
	if(buy_in >= 10000000)
		SetDynamicObjectMaterial(objectid, 0, 2189, "poker_tbl", "roulette_6_256", -52310);
	else if(buy_in >= 1000000)
		SetDynamicObjectMaterial(objectid, 0, 2189, "poker_tbl", "roulette_6_256", -16737793);
	else if(buy_in >= 100000)
		SetDynamicObjectMaterial(objectid, 0, 2189, "poker_tbl", "roulette_6_256", -65485);

	return 1;
}

stock bool:Poker_ValidateTableStakes(buy_in, small_blind, seat_count)
{
	if(seat_count < 2 || seat_count >= T_MAX_CHAIRS_PER_TABLE)
		return false;
	if(small_blind <= 0 || buy_in <= 0)
		return false;
	if(buy_in <= small_blind || buy_in <= (small_blind * 2))
		return false;

	return true;
}
