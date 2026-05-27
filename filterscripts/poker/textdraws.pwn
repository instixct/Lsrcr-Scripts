/*
	Poker player textdraws (cards, action buttons, info panel).
*/

static stock Float:Poker_GetSeatLayoutAngle(seat_count)
{
	switch(seat_count)
	{
		case 2: return 120.0;
		case 3: return 180.0;
		case 4: return 210.0;
		case 5, 6: return 240.0;
	}
	return 0.0;
}

static stock PlayerText:Poker_CreateCardBackTD(playerid, Float:x, Float:y)
{
	new PlayerText:td = CreatePlayerTextDraw(playerid, x, y, "LD_POKE:cdback");
	PlayerTextDrawTextSize(playerid, td, T_CARD_X_SIZE, T_CARD_Y_SIZE);
	PlayerTextDrawAlignment(playerid, td, t_TEXT_DRAW_ALIGN:2);
	PlayerTextDrawFont(playerid, td, t_TEXT_DRAW_FONT:4);
	return td;
}

static stock PlayerText:Poker_CreateActionButton(
	playerid,
	Float:x,
	Float:y,
	const text[],
	Float:text_width,
	boxcolor,
	bool:selectable = false
)
{
	new PlayerText:td = CreatePlayerTextDraw(playerid, x, y, text);
	PlayerTextDrawLetterSize(playerid, td, 0.182333, 1.039999);
	PlayerTextDrawTextSize(playerid, td, 10.0, text_width);
	PlayerTextDrawAlignment(playerid, td, t_TEXT_DRAW_ALIGN:2);
	PlayerTextDrawColor(playerid, td, -1);
	PlayerTextDrawUseBox(playerid, td, true);
	PlayerTextDrawBoxColor(playerid, td, boxcolor);
	PlayerTextDrawSetShadow(playerid, td, 0);
	PlayerTextDrawSetOutline(playerid, td, 1);
	PlayerTextDrawBackgroundColor(playerid, td, 255);
	PlayerTextDrawFont(playerid, td, t_TEXT_DRAW_FONT:1);
	PlayerTextDrawSetProportional(playerid, td, true);

	if(selectable)
		PlayerTextDrawSetSelectable(playerid, td, true);

	return td;
}

static stock PlayerText:Poker_CreateInfoLine(playerid, Float:x, Float:y, const text[])
{
	new PlayerText:td = CreatePlayerTextDraw(playerid, x, y, text);
	PlayerTextDrawLetterSize(playerid, td, 0.166999, 1.023407);
	PlayerTextDrawAlignment(playerid, td, t_TEXT_DRAW_ALIGN:1);
	PlayerTextDrawColor(playerid, td, -1);
	PlayerTextDrawBackgroundColor(playerid, td, 255);
	PlayerTextDrawFont(playerid, td, t_TEXT_DRAW_FONT:1);
	PlayerTextDrawSetProportional(playerid, td, true);
	return td;
}

stock Player_CreateTextdraws(playerid)
{
	new handle = PlayerData[playerid][E_PLAYER_CURRENT_HANDLE];
	new seat_count = TableData[handle][E_TABLE_TOTAL_SEATS];
	new Float:layout_angle = Poker_GetSeatLayoutAngle(seat_count);
	new Float:angle_step = 360.0 / float(seat_count);
	new Float:px, Float:py;

	for(new seat = 0; seat < seat_count; seat++)
	{
		px = (T_CARDS_RADIAL_DISTANCE * floatcos(float(seat) * angle_step + layout_angle, degrees)) + T_SCREEN_CENTER_X;
		py = (T_CARDS_RADIAL_DISTANCE * floatsin(float(seat) * angle_step + layout_angle, degrees)) + T_SCREEN_CENTER_Y + 25.0;

		PlayerData[playerid][E_PLAYER_CARDS_TXT_1][seat] = Poker_CreateCardBackTD(playerid, px, py);
		PlayerData[playerid][E_PLAYER_CARDS_TXT_2][seat] = Poker_CreateCardBackTD(playerid, px + T_TWO_CARD_DISTANCE, py);
	}

	for(new card = 0; card < 5; card++)
	{
		px = card * T_TWO_CARD_DISTANCE + T_SCREEN_CENTER_X - 58.0;
		py = T_SCREEN_CENTER_Y + 10.0;
		PlayerData[playerid][E_PLAYER_COMMUNITY_CARDS_TXT][card] = Poker_CreateCardBackTD(playerid, px, py);
	}

	// Options panel background
	PlayerData[playerid][E_PLAYER_CHOICES_TXT][0] = CreatePlayerTextDraw(playerid, 613.000122, 109.940643, "box");
	PlayerTextDrawLetterSize(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][0], 0.0, 8.599979);
	PlayerTextDrawTextSize(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][0], 0.0, 57.0);
	PlayerTextDrawAlignment(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][0], t_TEXT_DRAW_ALIGN:2);
	PlayerTextDrawColor(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][0], -1);
	PlayerTextDrawUseBox(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][0], true);
	PlayerTextDrawBoxColor(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][0], 177);
	PlayerTextDrawBackgroundColor(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][0], 169);
	PlayerTextDrawFont(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][0], t_TEXT_DRAW_FONT:1);
	PlayerTextDrawSetProportional(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][0], true);

	PlayerData[playerid][E_PLAYER_CHOICES_TXT][1] = CreatePlayerTextDraw(playerid, 612.000122, 110.770355, "Options");
	PlayerTextDrawLetterSize(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][1], 0.182333, 1.039999);
	PlayerTextDrawTextSize(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][1], 0.0, 53.0);
	PlayerTextDrawAlignment(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][1], t_TEXT_DRAW_ALIGN:2);
	PlayerTextDrawColor(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][1], -1);
	PlayerTextDrawUseBox(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][1], true);
	PlayerTextDrawBoxColor(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][1], -1061109505);
	PlayerTextDrawSetOutline(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][1], 1);
	PlayerTextDrawBackgroundColor(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][1], 255);
	PlayerTextDrawFont(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][1], t_TEXT_DRAW_FONT:1);
	PlayerTextDrawSetProportional(playerid, PlayerData[playerid][E_PLAYER_CHOICES_TXT][1], true);

	PlayerData[playerid][E_PLAYER_CHOICES_TXT][CALL] = Poker_CreateActionButton(playerid, 615.999755, 131.511154, "Call", 49.0, -2139094785);
	PlayerData[playerid][E_PLAYER_CHOICES_TXT][RAISE] = Poker_CreateActionButton(playerid, 615.999755, 148.518554, "Raise", 49.0, -1378294017, true);
	PlayerData[playerid][E_PLAYER_CHOICES_TXT][FOLD] = Poker_CreateActionButton(playerid, 615.999755, 165.525954, "Fold", 49.0, -1523963137, true);

	// Info panel
	PlayerData[playerid][E_PLAYER_INFO_TXT][0] = CreatePlayerTextDraw(playerid, 597.333435, 253.051803, "box");
	PlayerTextDrawLetterSize(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][0], 0.000000, 7.366664);
	PlayerTextDrawTextSize(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][0], 0.000000, 84.000000);
	PlayerTextDrawAlignment(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][0], 2);
	PlayerTextDrawColor(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][0], -1);
	PlayerTextDrawUseBox(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][0], 1);
	PlayerTextDrawBoxColor(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][0], 193);
	PlayerTextDrawBackgroundColor(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][0], 255);
	PlayerTextDrawFont(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][0], 1);
	PlayerTextDrawSetProportional(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][0], 1);

	PlayerData[playerid][E_PLAYER_INFO_TXT][1] = CreatePlayerTextDraw(playerid, 597.999694, 253.466537, "INFORMATION");
	PlayerTextDrawLetterSize(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][1], 0.265333, 1.093926);
	PlayerTextDrawTextSize(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][1], 0.000000, 84.000000);
	PlayerTextDrawAlignment(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][1], 2);
	PlayerTextDrawColor(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][1], -1);
	PlayerTextDrawUseBox(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][1], 1);
	PlayerTextDrawBoxColor(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][1], -2139062017);
	PlayerTextDrawSetOutline(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][1], 1);
	PlayerTextDrawBackgroundColor(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][1], 255);
	PlayerTextDrawFont(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][1], 2);
	PlayerTextDrawSetProportional(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][1], 1);

	PlayerData[playerid][E_PLAYER_INFO_TXT][2] = Poker_CreateInfoLine(playerid, 559.666687, 268.814849, "Chips:_0");
	PlayerData[playerid][E_PLAYER_INFO_TXT][3] = Poker_CreateInfoLine(playerid, 559.666687, 279.600128, "Pot:_0");
	PlayerData[playerid][E_PLAYER_INFO_TXT][4] = Poker_CreateInfoLine(playerid, 559.666687, 290.385407, "Last_bet:_$0");
	PlayerData[playerid][E_PLAYER_INFO_TXT][5] = Poker_CreateInfoLine(playerid, 559.666687, 301.170686, "Your_bet:_$0");

	return 1;
}

stock UpdateInfoTextdrawsForPlayer(playerid)
{
	new handle = PlayerData[playerid][E_PLAYER_CURRENT_HANDLE];
	new line[64];

	format(line, sizeof line, "~g~Chips:_~w~%s", cash_format(PlayerData[playerid][E_PLAYER_TOTAL_CHIPS]));
	PlayerTextDrawSetString(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][2], line);

	format(line, sizeof line, "~y~Pot:_~w~%s", cash_format(TableData[handle][E_TABLE_POT_CHIPS][MAIN_POT]));
	PlayerTextDrawSetString(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][3], line);

	format(line, sizeof line, "~r~Last_bet:_~w~%s", cash_format(TableData[handle][E_TABLE_LAST_BET]));
	PlayerTextDrawSetString(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][4], line);

	format(line, sizeof line, "~r~Your_bet:_~w~%s", cash_format(PlayerData[playerid][E_PLAYER_CURRENT_BET]));
	PlayerTextDrawSetString(playerid, PlayerData[playerid][E_PLAYER_INFO_TXT][5], line);

	return 1;
}
