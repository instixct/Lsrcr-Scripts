#define HOLDING(%0)                         ((newkeys & (%0)) == (%0))
#define PRESSED(%0)                         (((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
#define RELEASED(%0)                        (((newkeys & (%0)) != (%0)) && ((oldkeys & (%0)) == (%0)))


stock Player_Clearchat( playerid )
{
    for ( new j = 0; j < 30; j ++ ) {
        SendClientMessage( playerid, -1, " " );
    }
    return 1;
}

stock calculate_hand_worth(const hands[], count = sizeof(hands))
{
    if (count < 1 || count > 7)
        return -1;

    for (new i = 0; i < count; i++)
    {
        if (hands[i] < 0 || hands[i] > 51)
            return -1;
    }

    new ranks[13], suits[4];

    for (new i = 0; i < count; i++)
    {
        new card = hands[i];

        new rank = card % 13;
        new suit = card / 13;

        ranks[rank]++;
        suits[suit]++;
    }

    // Flush
    new bool:isFlush = false;
    for (new i = 0; i < 4; i++)
    {
        if (suits[i] >= 5)
        {
            isFlush = true;
            break;
        }
    }

    // Straight
    new bool:isStraight = false;

    for (new i = 0; i < 9; i++)
    {
        if (
            ranks[i] &&
            ranks[i + 1] &&
            ranks[i + 2] &&
            ranks[i + 3] &&
            ranks[i + 4]
        )
        {
            isStraight = true;
            break;
        }
    }

    // Wheel straight (A2345)
    if (
        ranks[12] &&
        ranks[0] &&
        ranks[1] &&
        ranks[2] &&
        ranks[3]
    )
    {
        isStraight = true;
    }

    new pairs = 0;
    new three = 0;
    new four = 0;

    for (new i = 0; i < 13; i++)
    {
        if (ranks[i] == 4)
            four++;

        else if (ranks[i] == 3)
            three++;

        else if (ranks[i] == 2)
            pairs++;
    }

    // Royal Flush
    if (
        isFlush &&
        ranks[8] && // 10
        ranks[9] && // J
        ranks[10] && // Q
        ranks[11] && // K
        ranks[12] // A
    )
    {
        return 10;
    }

    // Straight Flush
    if (isFlush && isStraight)
        return 9;

    // Four of a Kind
    if (four)
        return 8;

    // Full House
    if (three && pairs)
        return 7;

    // Flush
    if (isFlush)
        return 6;

    // Straight
    if (isStraight)
        return 5;

    // Three of a Kind
    if (three)
        return 4;

    // Two Pair
    if (pairs >= 2)
        return 3;

    // One Pair
    if (pairs == 1)
        return 2;

    // High Card
    return 1;
}