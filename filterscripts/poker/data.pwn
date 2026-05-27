/*
	Poker data: limits, enums, iterators, and global state.
*/

#define T_SendWarning(%0) (printf(" * [Poker]: " %0))

// Limits
#define T_MAX_POKER_TABLES          36
#define T_MAX_CHAIRS_PER_TABLE      7
#define T_CHAIR_MODEL               2120
#define T_MAX_CHIPS_PER_CHAIR       4
#define T_MAX_WAIT_TIME             20
#define T_START_DELAY               5
#define T_SAVE_PLAYER_POS           true
#define MAX_CHIP_DIGITS             7
#define T_TABLE_TICK_INTERVAL       500
#define T_POT_FEE_RATE              0.02

// Layout
#define T_Z_OFFSET                  0.442852
#define T_CHAIR_RANGE               1.250000
#define T_Z_CAMERA_OFFSET           3.0
#define T_CHIP_OFFSET               0.13
#define T_CARD_X_SIZE               23.0
#define T_CARD_Y_SIZE               31.0
#define T_TWO_CARD_DISTANCE         23.904725
#define T_CARDS_RADIAL_DISTANCE     144.00000
#define T_SCREEN_CENTER_X           320.00000
#define T_SCREEN_CENTER_Y           215.00000
#define T_CHIPS_DISTANCE            0.6582
#define T_RADIUS                    0.971977
#define T_BET_LABEL_COLOR           0x0080FFFF
#define T_JOIN_TABLE_RANGE          2.5
#define T_TABLE_GROUND_OFFSET       0.6

// UI slots
#define MAIN_POT    0
#define CALL        2
#define RAISE       3
#define FOLD        4

// Chat colours
#define COLOR_GREY  0xAFAFAFAA
#define COL_GREY    "{C0C0C0}"
#define COL_WHITE   "{ffffff}"
#define COLOR_RED   0xFF0000FF

#define IsPlayerPlayingPoker(%0) (GetPVarInt(%0, "t_is_in_table"))

// Iterators
new Iterator:IT_Tables<T_MAX_POKER_TABLES>;
new Iterator:IT_TableCardSet[T_MAX_POKER_TABLES]<52>;

new Iterator:IT_PlayersTable<T_MAX_POKER_TABLES, MAX_PLAYERS>;
new Iterator:IT_PlayersInGame<T_MAX_POKER_TABLES, MAX_PLAYERS>;
new Iterator:IT_PlayersAllIn<T_MAX_POKER_TABLES, MAX_PLAYERS>;

new Iterator:It_SidepotMembers[T_MAX_POKER_TABLES * T_MAX_CHAIRS_PER_TABLE]<MAX_PLAYERS>;
new Iterator:IT_Sidepots[T_MAX_POKER_TABLES]<T_MAX_CHAIRS_PER_TABLE>;

#define _IT[%0][%1] (%0 * T_MAX_CHAIRS_PER_TABLE + %1)
#define IsValidTable(%0) ((0 <= %0 < T_MAX_POKER_TABLES) && Iter_Contains(IT_Tables, %0))

enum E_TABLE_STATES
{
	STATE_IDLE,
	STATE_BEGIN
};

new const HAND_RANKS[][] =
{
	{"Undefined"},
	{"High Card"},
	{"Pair"},
	{"Two Pair"},
	{"Three of a Kind"},
	{"Straight"},
	{"Flush"},
	{"Full House"},
	{"Four of a Kind"},
	{"Straight Flush"},
	{"Royal Flush"}
};

enum E_CARD_SUITS
{
	SUIT_SPADES,
	SUIT_HEARTS,
	SUIT_CLUBS,
	SUIT_DIAMONDS
};

enum E_CARD_DATA
{
	E_CARD_TEXTDRAW[48],
	E_CARD_NAME[48],
	E_CARD_SUITS:E_CARD_SUIT,
	E_CARD_RANK
};

#define GetCardNativeIndex(%0) ((4 * ((%0) % 13)) + _:CardData[(%0)][E_CARD_SUIT])

new const CardData[52][E_CARD_DATA] =
{
	{"LD_CARD:cd2s",  "Two of Spades",    SUIT_SPADES,   0},
	{"LD_CARD:cd3s",  "Three of Spades",  SUIT_SPADES,   1},
	{"LD_CARD:cd4s",  "Four of Spades",   SUIT_SPADES,   2},
	{"LD_CARD:cd5s",  "Five of Spades",   SUIT_SPADES,   3},
	{"LD_CARD:cd6s",  "Six of Spades",    SUIT_SPADES,   4},
	{"LD_CARD:cd7s",  "Seven of Spades",  SUIT_SPADES,   5},
	{"LD_CARD:cd8s",  "Eight of Spades",  SUIT_SPADES,   6},
	{"LD_CARD:cd9s",  "Nine of Spades",   SUIT_SPADES,   7},
	{"LD_CARD:cd10s", "Ten of Spades",    SUIT_SPADES,   8},
	{"LD_CARD:cd11s", "Jack of Spades",   SUIT_SPADES,   9},
	{"LD_CARD:cd12s", "Queen of Spades",  SUIT_SPADES,  10},
	{"LD_CARD:cd13s", "King of Spades",   SUIT_SPADES,  11},
	{"LD_CARD:cd1s",  "Ace of Spades",    SUIT_SPADES,  12},
	{"LD_CARD:cd2h",  "Two of Hearts",    SUIT_HEARTS,   0},
	{"LD_CARD:cd3h",  "Three of Hearts",  SUIT_HEARTS,   1},
	{"LD_CARD:cd4h",  "Four of Hearts",   SUIT_HEARTS,   2},
	{"LD_CARD:cd5h",  "Five of Hearts",   SUIT_HEARTS,   3},
	{"LD_CARD:cd6h",  "Six of Hearts",    SUIT_HEARTS,   4},
	{"LD_CARD:cd7h",  "Seven of Hearts",  SUIT_HEARTS,   5},
	{"LD_CARD:cd8h",  "Eight of Hearts",  SUIT_HEARTS,   6},
	{"LD_CARD:cd9h",  "Nine of Hearts",   SUIT_HEARTS,   7},
	{"LD_CARD:cd10h", "Ten of Hearts",    SUIT_HEARTS,   8},
	{"LD_CARD:cd11h", "Jack of Hearts",   SUIT_HEARTS,   9},
	{"LD_CARD:cd12h", "Queen of Hearts",  SUIT_HEARTS,  10},
	{"LD_CARD:cd13h", "King of Hearts",   SUIT_HEARTS,  11},
	{"LD_CARD:cd1h",  "Ace of Hearts",    SUIT_HEARTS,  12},
	{"LD_CARD:cd2c",  "Two of Clubs",     SUIT_CLUBS,    0},
	{"LD_CARD:cd3c",  "Three of Clubs",   SUIT_CLUBS,    1},
	{"LD_CARD:cd4c",  "Four of Clubs",    SUIT_CLUBS,    2},
	{"LD_CARD:cd5c",  "Five of Clubs",    SUIT_CLUBS,    3},
	{"LD_CARD:cd6c",  "Six of Clubs",     SUIT_CLUBS,    4},
	{"LD_CARD:cd7c",  "Seven of Clubs",   SUIT_CLUBS,    5},
	{"LD_CARD:cd8c",  "Eight of Clubs",   SUIT_CLUBS,    6},
	{"LD_CARD:cd9c",  "Nine of Clubs",    SUIT_CLUBS,    7},
	{"LD_CARD:cd10c", "Ten of Clubs",     SUIT_CLUBS,    8},
	{"LD_CARD:cd11c", "Jack of Clubs",    SUIT_CLUBS,    9},
	{"LD_CARD:cd12c", "Queen of Clubs",   SUIT_CLUBS,   10},
	{"LD_CARD:cd13c", "King of Clubs",    SUIT_CLUBS,   11},
	{"LD_CARD:cd1c",  "Ace of Clubs",     SUIT_CLUBS,   12},
	{"LD_CARD:cd2d",  "Two of Diamonds",  SUIT_DIAMONDS, 0},
	{"LD_CARD:cd3d",  "Three of Diamonds",SUIT_DIAMONDS, 1},
	{"LD_CARD:cd4d",  "Four of Diamonds", SUIT_DIAMONDS, 2},
	{"LD_CARD:cd5d",  "Five of Diamonds", SUIT_DIAMONDS, 3},
	{"LD_CARD:cd6d",  "Six of Diamonds",  SUIT_DIAMONDS, 4},
	{"LD_CARD:cd7d",  "Seven of Diamonds",SUIT_DIAMONDS, 5},
	{"LD_CARD:cd8d",  "Eight of Diamonds",SUIT_DIAMONDS, 6},
	{"LD_CARD:cd9d",  "Nine of Diamonds", SUIT_DIAMONDS, 7},
	{"LD_CARD:cd10d", "Ten of Diamonds",  SUIT_DIAMONDS, 8},
	{"LD_CARD:cd11d", "Jack of Diamonds", SUIT_DIAMONDS, 9},
	{"LD_CARD:cd12d", "Queen of Diamonds",SUIT_DIAMONDS,10},
	{"LD_CARD:cd13d", "King of Diamonds", SUIT_DIAMONDS,11},
	{"LD_CARD:cd1d",  "Ace of Diamonds",  SUIT_DIAMONDS,12}
};

new const TableRotCorrections[][] =
{
	{-1, -1, -1, -1, -1, -1},
	{-1, -1, -1, -1, -1, -1},
	{ 1,  0, -1, -1, -1, -1},
	{ 1,  0,  2, -1, -1, -1},
	{ 1,  0,  3,  2, -1, -1},
	{ 1,  0,  4,  3,  2, -1},
	{ 1,  0,  5,  4,  3,  2}
};

new const colors[MAX_CHIP_DIGITS] =
{
	0xFF0080C0,
	0xFF008000,
	0xFF324A4E,
	0xFF7C4303,
	0xFF63720E,
	0xFFE2C241,
	0xFFE4603F
};

new const chip_text[MAX_CHIP_DIGITS][8] =
{
	{"$1"},
	{"$10"},
	{"$100"},
	{"$1K"},
	{"$10K"},
	{"$100K"},
	{"$1M"}
};

enum E_TABLE_ROUNDS
{
	ROUND_PRE_FLOP,
	ROUND_FLOP,
	ROUND_TURN,
	ROUND_RIVER
};

enum e_TABLE
{
	E_TABLE_BUY_IN,
	E_TABLE_SMALL_BLIND,
	E_TABLE_BIG_BLIND,
	E_TABLE_LAST_TO_RAISE,
	E_TABLE_LAST_TO_RAISE_SEAT,
	E_TABLE_CURRENT_TURN,
	E_TABLE_LAST_BET,
	E_TABLE_STATES:E_TABLE_CURRENT_STATE,
	E_TABLE_PLAYER_DEALER_ID,
	E_TABLE_PLAYER_BIG_BLIND_ID,
	E_TABLE_PLAYER_SMALL_BLIND_ID,
	bool:E_TABLE_CHECK_FIRST,
	E_TABLE_FIRST_TURN,
	E_TABLE_POT_CHIPS[T_MAX_CHAIRS_PER_TABLE],
	bool:E_TABLE_TIMER_STARTED,
	E_TABLE_OBJECT_IDS[2],
	Float:E_TABLE_POS_X,
	Float:E_TABLE_POS_Y,
	Float:E_TABLE_POS_Z,
	E_TABLE_ROUNDS:E_TABLE_CURRENT_ROUND,
	E_TABLE_DEALER_SEAT,
	E_TABLE_TOTAL_SEATS,
	E_TABLE_TIMER_ID,
	bool:E_TABLE_LOADING_GAME,
	bool:E_TABLE_STING_NEW_GAME,
	E_TABLE_COM_CARDS_VALUES[5],
	Text3D:E_TABLE_POT_LABEL,
	E_TABLE_VIRTUAL_WORLD,
	E_TABLE_INTERIOR,
	Text3D:E_TABLE_BET_LABELS[T_MAX_CHAIRS_PER_TABLE],
	E_TABLE_CHAIR_OBJECT_IDS[T_MAX_CHAIRS_PER_TABLE],
	bool:E_TABLE_IS_SEAT_TAKEN[T_MAX_CHAIRS_PER_TABLE],
	E_TABLE_CHAIR_PLAYER_ID[T_MAX_CHAIRS_PER_TABLE],
	Float:E_TABLE_SEAT_POS_X[T_MAX_CHAIRS_PER_TABLE],
	Float:E_TABLE_SEAT_POS_Y[T_MAX_CHAIRS_PER_TABLE],
	Float:E_TABLE_SEAT_POS_Z[T_MAX_CHAIRS_PER_TABLE],
	E_TABLE_CHIPS[MAX_CHIP_DIGITS],
	E_TABLE_CHIPS_LABEL[MAX_CHIP_DIGITS]
};

new TableData[T_MAX_POKER_TABLES + 1][e_TABLE];
new TableChips[T_MAX_POKER_TABLES + 1][T_MAX_CHAIRS_PER_TABLE][MAX_CHIP_DIGITS];
new TableChipsLabel[T_MAX_POKER_TABLES + 1][T_MAX_CHAIRS_PER_TABLE][MAX_CHIP_DIGITS];

#define SetTableFirstTurn(%0,%1) (TableData[(%0)][E_TABLE_FIRST_TURN] = %1)
#define GetTableFirstTurn(%0)    (TableData[(%0)][E_TABLE_FIRST_TURN])
#define GetPlayerSeat(%0)        (PlayerData[(%0)][E_PLAYER_CURRENT_CHAIR_SLOT])

enum E_RAISE_CHOICES
{
	E_RAISE_BET,
	E_RAISE_RAISE,
	E_RAISE_ALL_IN
};

enum e_PLAYER
{
	bool:E_PLAYER_IS_PLAYING,
	E_PLAYER_CURRENT_HANDLE,
	E_PLAYER_CURRENT_BET,
	E_PLAYER_CARD_VALUES[2],
	E_PLAYER_TOTAL_CHIPS,
	bool:E_PLAYER_CLICKED_TXT,
	E_PLAYER_TIMER_ID,
	bool:E_PLAYER_TIMER_STARTED,
	bool:E_PLAYER_FOLDED,
	E_RAISE_CHOICES:E_PLAYER_RCHOICE,
	PlayerText:E_PLAYER_COMMUNITY_CARDS_TXT[5],
	PlayerText:E_PLAYER_CARDS_TXT_1[T_MAX_CHAIRS_PER_TABLE],
	PlayerText:E_PLAYER_CARDS_TXT_2[T_MAX_CHAIRS_PER_TABLE],
	PlayerText:E_PLAYER_CHOICES_TXT[5],
	PlayerText:E_PLAYER_INFO_TXT[6],
	Text3D:E_PLAYER_3D_LABEL,
	E_PLAYER_CURRENT_CHAIR_SLOT,
	E_PLAYER_CHAIR_ATTACH_INDEX_ID
};

new PlayerData[MAX_PLAYERS + 1][e_PLAYER];
