class X2DLCInfo_WOTCIridarVisibleUtilityWeapons extends X2DownloadableContentInfo;

var config array<name> ExcludeItems;

var private SkeletalMeshSocket GrenadeClip1Socket;
var private SkeletalMeshSocket GrenadeClip2Socket;
var private SkeletalMeshSocket GrenadeClip3Socket;
var private SkeletalMeshSocket GrenadeClip4Socket;



// TODO: Exclude SPARKs and NOn-soldeirs

static event OnPostTemplatesCreated()
{
	local CHHelpers	CHHelpersObj;

	CHHelpersObj = class'CHHelpers'.static.GetCDO();
	if (CHHelpersObj != none)
	{
		CHHelpersObj.AddShouldDisplayMultiSlotItemInStrategyCallback(ShouldDisplayMultiSlotItemInStrategyDelegate, 50);
		CHHelpersObj.AddShouldDisplayMultiSlotItemInTacticalCallback(ShouldDisplayMultiSlotItemInTacticalDelegate, 50);
	}
	class'Help'.static.ResetGrenadeClipSocketCache();
}

static function string DLCAppendSockets(XComUnitPawn Pawn)
{
	local array<SkeletalMeshSocket> NewSockets;
	
	NewSockets.AddItem(default.GrenadeClip1Socket);
	NewSockets.AddItem(default.GrenadeClip2Socket);
	NewSockets.AddItem(default.GrenadeClip3Socket);
	NewSockets.AddItem(default.GrenadeClip4Socket);

	Pawn.Mesh.AppendSockets(NewSockets, true);

	return "";
}

static function UpdateAnimations(out array<AnimSet> CustomAnimSets, XComGameState_Unit UnitState, XComUnitPawn Pawn)
{
	local SkeletalMeshSocket Socket;

	foreach Pawn.Mesh.Sockets(Socket)
	{
		`LOG(UnitState.GetFullName() @ Socket.SocketName @ Socket.BoneName @ string(Socket.Outer));
	}
}


static private function EHLDelegateReturn ShouldDisplayMultiSlotItemInStrategyDelegate(XComGameState_Unit UnitState, XComGameState_Item ItemState, out int bDisplayItem, XComUnitPawn UnitPawn, optional XComGameState CheckGameState)
{
	ShouldDisplayUtilitySlotItem(ItemState, bDisplayItem);
	return EHLDR_NoInterrupt;
}

static private function EHLDelegateReturn ShouldDisplayMultiSlotItemInTacticalDelegate(XComGameState_Unit UnitState, XComGameState_Item ItemState, out int bDisplayItem, XGUnit UnitVisualizer, optional XComGameState CheckGameState)
{
	ShouldDisplayUtilitySlotItem(ItemState, bDisplayItem);
	return EHLDR_NoInterrupt;
}	

static private function bool ShouldDisplayUtilitySlotItem(XComGameState_Item ItemState, out int bDisplayItem)
{
	local X2WeaponTemplate		WeaponTemplate;
	local XComGameState_Unit	UnitState;
	local name					SocketName;

	// Do nothing for non-utility items or excluded items.
	if (ItemState.InventorySlot != eInvSlot_Utility || default.ExcludeItems.Find(ItemState.GetMyTemplateName()) != INDEX_NONE)
		return false;

	WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
	if (WeaponTemplate == none || WeaponTemplate.iItemSize <= 0)
		return false;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ItemState.OwnerStateObject.ObjectID));
	if (UnitState == none || UnitState.InventoryItems.Find('ObjectID', ItemState.ObjectID) == INDEX_NONE)
		return false;

	SocketName = class'Help'.static.GetItemDefaultSocket(ItemState, UnitState);
	if (SocketName == '')
		return false;

	if (SocketName == 'GrenadeClip')
	{
		//Index = class'Help'.static.FindItemSocketIndex(ItemState, UnitState, SocketName);
		//if (Index != INDEX_NONE)
		//{
			`LOG("Displaying item:" @ ItemState.GetMyTemplateName() @ "in socket:" @ SocketName);
			bDisplayItem = 1;
		//}
	}
	else
	{
		bDisplayItem = 1;
	}

	//	Return false to allow following Delegates to override the output of this delegate.
	return false;
}

static function WeaponInitialized(XGWeapon WeaponArchetype, XComWeapon Weapon, optional XComGameState_Item InternalWeaponState = none)
{
    Local XComGameState_Item			ItemState;
	local XComGameState_Unit			UnitState;
	local name							NewSocketName;
	local AnimSet						Set;
	local AnimSequence					Sequence;
	local XComAnimNotify_ItemAttach		ItemAttach;
	local AnimNotify_ScriptedItemAttach ScriptedItemAttach;
	local AnimNotifyEvent				NotifyEvent;
	local bool							bNotifyFound;
	local int i;

	// #1. Initial checks
	if (Weapon.DefaultSocket != 'GrenadeClip')
		return;

    if (InternalWeaponState == none) 
	{	
		ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponArchetype.ObjectID));
		if (ItemState == none)
			return;
	}
	else ItemState = InternalWeaponState;
	if (ItemState.bMergedOut)
		return;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ItemState.OwnerStateObject.ObjectID));
	if (UnitState == none || UnitState.InventoryItems.Find('ObjectID', ItemState.ObjectID) == INDEX_NONE)
		return;

	// #2. THis is a grenade. Find a free socket for it.
	NewSocketName = class'Help'.static.FindFreeGrenadeClipSocket(UnitState);
	if (NewSocketName == '')
		return;

	Weapon.SheathSocket = Weapon.DefaultSocket;
	Weapon.DefaultSocket = NewSocketName;

	`LOG("WeaponInit: moving item:" @ ItemState.GetMyTemplateName() @ "to socket:" @ NewSocketName);

	foreach Weapon.CustomUnitPawnAnimsets(Set)
	{
		foreach Set.Sequences(Sequence)
		{
			if (InStr(Sequence.SequenceName, Weapon.WeaponFireAnimSequenceName) == INDEX_NONE &&
				InStr(Sequence.SequenceName, Weapon.WeaponFireKillAnimSequenceName) == INDEX_NONE)
			{
				continue;
			}

			bNotifyFound = false;
			for (i = 0; i < Sequence.Notifies.Length; i++)
			{
				ScriptedItemAttach = AnimNotify_ScriptedItemAttach(Sequence.Notifies[i].Notify);
				if (ScriptedItemAttach != none)
				{
					bNotifyFound = true;
				}
			}
			if (!bNotifyFound)
			{
				ItemAttach = new class'XComAnimNotify_ItemAttach';
				NotifyEvent.Time = 0.05f;
                NotifyEvent.Notify = ItemAttach;
                Sequence.Notifies.InsertItem(0, NotifyEvent);

				ScriptedItemAttach = new class'AnimNotify_ScriptedItemAttach';
				ScriptedItemAttach.ItemAttach = ItemAttach;
				NotifyEvent.Time = 0;
                NotifyEvent.Notify = ScriptedItemAttach;
                Sequence.Notifies.InsertItem(0, NotifyEvent);
			}
		}
	}
}

// TODO: Debug only
static function GetNumUtilitySlotsOverride(out int NumUtilitySlots, XComGameState_Item EquippedArmor, XComGameState_Unit UnitState, XComGameState CheckGameState)
{
	NumUtilitySlots = 5;
}



defaultproperties
{
	Begin Object Class=SkeletalMeshSocket Name=DefaultGrenadeClip1Socket
		SocketName = "GrenadeClip1"
		BoneName = "Pelvis"
		RelativeLocation=(X=0.0f,Y=0.0f,Z=20.0f)
	End Object
	GrenadeClip1Socket = DefaultGrenadeClip1Socket;

	Begin Object Class=SkeletalMeshSocket Name=DefaultGrenadeClip2Socket
		SocketName="GrenadeClip2"
		BoneName="Pelvis"
		RelativeLocation=(X=0.0f,Y=5.0f,Z=20.0f)
	End Object
	GrenadeClip2Socket = DefaultGrenadeClip2Socket;

	Begin Object Class=SkeletalMeshSocket Name=DefaultGrenadeClip3Socket
		SocketName="GrenadeClip3"
		BoneName="Pelvis"
		RelativeLocation=(X=0.0f,Y=10.0f,Z=20.0f)
	End Object
	GrenadeClip3Socket = DefaultGrenadeClip3Socket;

	Begin Object Class=SkeletalMeshSocket Name=DefaultGrenadeClip4Socket
		SocketName = "GrenadeClip4"
		BoneName = "Pelvis"
		RelativeLocation=(X=0.0f,Y=-5.0f,Z=20.0f)
	End Object
	GrenadeClip4Socket = DefaultGrenadeClip4Socket;
}



