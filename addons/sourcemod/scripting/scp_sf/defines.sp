#pragma semicolon 1
#pragma newdecls required

#define FAR_FUTURE	100000000.0
#define MAXENTITIES	2048

#define MAXANGLEPITCH	45.0
#define MAXANGLEYAW	90.0

#define PREFIX		"{red}[SCP]{default} "

#define ITEM_TYPE_MISC 0
#define ITEM_TYPE_WEAPON 1
#define ITEM_TYPE_KEYCARD 2
#define ITEM_TYPE_MEDICAL 3
#define ITEM_TYPE_RADIO 4
#define ITEM_TYPE_SCP 5
#define ITEM_TYPE_ARMOR 6
#define ITEM_TYPE_GRENADE 7

#define ITEM_INDEX_MICROHID 594
#define ITEM_INDEX_O5 30012
#define ITEM_INDEX_SCP18 30018
#define ITEM_INDEX_DISARMER 954

#define DEFINDEX_UNDEFINED (-1 & 0xFFFF)

#define LOADOUT_POSITION_ACTION 9

float TRIPLE_D[3] = { 0.0, 0.0, 0.0 };