class Help extends Object abstract config(WOTCIridarVisibleUtilityWeaponsCache);

const MAX_NUM_GRENADE_CLIPS = 4;

var config array<name> ItemsUseGrenadeClip;
var config array<name> ItemsNotUseGrenadeClip;

struct UnitSocketInfoStruct
{
	var int ObjectID;
	var int NumSockets;
};
var config array<UnitSocketInfoStruct> UnitSocketInfos;

static final function name GetItemDefaultSocket(const XComGameState_Item ItemState, const XComGameState_Unit UnitState)
{
	local XComWeapon			WeaponArchetype;
	local X2EquipmentTemplate	EqTemplate;
	local string				ArchetypePath;

	// #1. Check cached data.
	if (default.ItemsUseGrenadeClip.Find(ItemState.GetMyTemplateName()) != INDEX_NONE)
		return 'GrenadeClip';

	if (default.ItemsNotUseGrenadeClip.Find(ItemState.GetMyTemplateName()) != INDEX_NONE)
		return 'NotGrenadeClip';

	// #2. Cache miss, find it out the hard way.
	EqTemplate = X2EquipmentTemplate(ItemState.GetMyTemplate());
	if (EqTemplate == none)
		return '';
		
	ArchetypePath = EqTemplate.DetermineGameArchetypeForUnit(ItemState, UnitState, UnitState.kAppearance);
	if (ArchetypePath == "")
		return '';

	WeaponArchetype = XComWeapon(`CONTENT.RequestGameArchetype(ArchetypePath));
	if (WeaponArchetype == none)
		return '';

	// Cache data before returning the result.
	switch (WeaponArchetype.DefaultSocket)
	{
	case 'GrenadeClip':
		default.ItemsUseGrenadeClip.AddItem(EqTemplate.DataName);
		StaticSaveConfig();
		return 'GrenadeClip';
	default:
		default.ItemsNotUseGrenadeClip.AddItem(EqTemplate.DataName);
		StaticSaveConfig();
		return 'NotGrenadeClip';
	}
	
	return'';
}


static final function name FindFreeGrenadeClipSocket(const XComGameState_Unit UnitState)
{
	local name SocketName;
	local UnitSocketInfoStruct SocketInfo;
	local int Index;

	Index = default.UnitSocketInfos.Find('ObjectID', UnitState.ObjectID);
	if (Index == INDEX_NONE)
	{
		// No cached entry for this unit. Create a new one.
		SocketInfo.ObjectID = UnitState.ObjectID;
		SocketInfo.NumSockets = 1;
		default.UnitSocketInfos.AddItem(SocketInfo);
		return 'GrenadeClip1';
	}
	else
	{
		// Unit has a cached entry.

		// Are there free sockets remaining?
		if (default.UnitSocketInfos[Index].NumSockets < MAX_NUM_GRENADE_CLIPS)
		{
			// Yes, give one, save.
			SocketName = name('GrenadeClip' $ default.UnitSocketInfos[Index].NumSockets);

			default.UnitSocketInfos[Index].NumSockets++;

			return SocketName;
		}
		else
		{
			// No free sockets.
			return '';
		}
	}
}
static final function ResetGrenadeClipSocketCache()
{
	default.UnitSocketInfos.Length = 0;
}

/*
static final function int FindFreeSocketIndex(const XComGameState_Unit UnitState, const name UnitValuePrefix)
{
	local UnitValue	UV;
	local int		Index;
	local name		UVName;
	local int		MaxNumSockets;

	MaxNumSockets = GetMaxSocketValue(UnitValuePrefix);
	for (Index = 0; Index < MaxNumSockets; Index++)
	{
		UVName = name(UnitValuePrefix $ Index);
		if (!UnitState.GetUnitValue(UVName, UV))
		{
			return Index;
		}
	}

	return INDEX_NONE;
}

static final function int FindItemSocketIndex(const XComGameState_Item ItemState, const XComGameState_Unit UnitState, const name UnitValuePrefix)
{
	local UnitValue	UV;
	local int		Index;
	local name		UVName;
	local int		MaxNumSockets;

	MaxNumSockets = GetMaxSocketValue(UnitValuePrefix);
	for (Index = 0; Index < MaxNumSockets; Index++)
	{
		UVName = name(UnitValuePrefix $ Index);

		if (UnitState.GetUnitValue(UVName, UV) && UV.fValue == ItemState.ObjectID)
		{
			return Index;
		}
	}

	return INDEX_NONE;
}

// INTERNAL HELPERS

static private function int GetMaxSocketValue(const name SocketName)
{
	switch (SocketName)
	{
	case 'GrenadeClip':
		return MAX_NUM_GRENADE_CLIPS;
	default:
		return INDEX_NONE;	
	}
	return INDEX_NONE;	
}*/

/*
static private function int GetItemStateIndex(const XComGameState_Item ItemState)
{
	local XComGameState_Unit		UnitState;
	local array<XComGameState_Item> UtilityItems;
	local int						Index;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ItemState.OwnerStateObject.ObjectID));
	if (UnitState == none)
		return INDEX_NONE;

	UtilityItems = UnitState.GetAllItemsInSlot(eInvSlot_Utility);
	for (Index = 0; Index < UtilityItems.Length; Index++)
	{
		if (UtilityItems[Index].ObjectID == ItemState.ObjectID)
		{
			return Index;
		}
	}

	return INDEX_NONE;
}
*/