class Help extends Object abstract config(WOTCIridarVisibleUtilityWeaponsCache);

var config(Game) int MAX_NUM_GRENADE_CLIPS;

var config array<name> ItemsUseGrenadeClip;
var config array<name> ItemsNotUseGrenadeClip;

static private function int GetItemStateIndex(const XComGameState_Item ItemState)
{
	local XComGameState_Unit		UnitState;
	local array<XComGameState_Item> InventoryItems;
	local XComGameState_Item		InventoryItem;
	local int						NumGrenadeClipItems;

	//`LOG(GetScriptTrace());
	//`LOG("Checking Item Index for:" @ ItemState.GetMyTemplateName());

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ItemState.OwnerStateObject.ObjectID));
	if (UnitState == none)
		return INDEX_NONE;

	// Have to get all items instead of just utility items to take into account grenade pocket and all other potential inventory slots
	InventoryItems = UnitState.GetAllInventoryItems(, true); // Exclude PCS
	foreach InventoryItems(InventoryItem)
	{
		if (IsItemDefaultSocketGrenadeClip(InventoryItem))
		{
			NumGrenadeClipItems++;
		}

		if (InventoryItem.ObjectID == ItemState.ObjectID)
		{
			//`LOG("Index:" @ NumGrenadeClipItems);
			return NumGrenadeClipItems;
		}
	}

	//`LOG("idk item not equipped on unit");

	return INDEX_NONE;
}

static final function name FindGrenadeClipSocketForItem(const XComGameState_Item ItemState)
{
	local int Index;

	Index = GetItemStateIndex(ItemState);
	//`LOG("Item index:" @ Index);
	if (Index != INDEX_NONE && Index <= default.MAX_NUM_GRENADE_CLIPS)
	{
		//`LOG("Returning socket:" @ name('GrenadeClip' $ Index));
		return name('GrenadeClip' $ Index);
	}
	//`LOG("no free socket available");
	return '';
}

static final function bool IsItemDefaultSocketGrenadeClip(const XComGameState_Item ItemState)
{
	local XComWeapon			WeaponArchetype;
	local XComGameState_Unit	UnitState;
	local X2EquipmentTemplate	EqTemplate;
	local string				ArchetypePath;

	// #1. Check cached data.
	if (default.ItemsUseGrenadeClip.Find(ItemState.GetMyTemplateName()) != INDEX_NONE)
		return true;

	if (default.ItemsNotUseGrenadeClip.Find(ItemState.GetMyTemplateName()) != INDEX_NONE)
		return false;

	// #2. Cache miss, find it out the hard way.
	EqTemplate = X2EquipmentTemplate(ItemState.GetMyTemplate());
	if (EqTemplate == none)
		return false;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ItemState.OwnerStateObject.ObjectID));
	if (UnitState == none)
		return false;

	ArchetypePath = EqTemplate.DetermineGameArchetypeForUnit(ItemState, UnitState, UnitState.kAppearance);
	if (ArchetypePath == "")
		return false;

	WeaponArchetype = XComWeapon(`CONTENT.RequestGameArchetype(ArchetypePath));
	if (WeaponArchetype == none)
		return false;

	// Cache data before returning the result.
	switch (WeaponArchetype.DefaultSocket)
	{
	case 'GrenadeClip':
		default.ItemsUseGrenadeClip.AddItem(EqTemplate.DataName);
		StaticSaveConfig();
		return true;
	default:
		default.ItemsNotUseGrenadeClip.AddItem(EqTemplate.DataName);
		StaticSaveConfig();
		return false;
	}
	
	return false;
}

/*


static private function bool IsSocketFree(const XComUnitPawn Pawn, const name SocketName)
{
	local SkeletalMeshComponent	SkelMesh;

	`LOG("Checking socket:" @ SocketName);

	foreach Pawn.Mesh.AttachedComponentsOnBone(class'SkeletalMeshComponent', SkelMesh, SocketName)
	{
		`LOG("Socket:" @ SocketName @ "has mesh:" @ string(SkelMesh));
		return false;
	}
	`LOG("Socket:" @ SocketName @ "has no mesh.");
	return true;
}*/
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
*/