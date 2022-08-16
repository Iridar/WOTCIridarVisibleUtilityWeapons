class X2DLCInfo_WOTCIridarVisibleUtilityWeapons extends X2DownloadableContentInfo;

var config array<name> ExcludeItems;

var private SkeletalMeshSocket GrenadeClip1Socket;
var private SkeletalMeshSocket GrenadeClip2Socket;
var private SkeletalMeshSocket GrenadeClip3Socket;
var private SkeletalMeshSocket GrenadeClip4Socket;

static event OnPostTemplatesCreated()
{
	local CHHelpers	CHHelpersObj;

	CHHelpersObj = class'CHHelpers'.static.GetCDO();
	if (CHHelpersObj != none)
	{
		CHHelpersObj.AddShouldDisplayMultiSlotItemInStrategyCallback(ShouldDisplayMultiSlotItemInStrategyDelegate, 50);
		CHHelpersObj.AddShouldDisplayMultiSlotItemInTacticalCallback(ShouldDisplayMultiSlotItemInTacticalDelegate, 50);
	}
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
/*
static function UpdateAnimations(out array<AnimSet> CustomAnimSets, XComGameState_Unit UnitState, XComUnitPawn Pawn)
{
	local SkeletalMeshSocket Socket;
	local SkeletalMeshComponent	SkelMesh;

	foreach Pawn.Mesh.Sockets(Socket)
	{
		`LOG("Looking socket:" @ Socket.SocketName);
		foreach Pawn.Mesh.AttachedComponentsOnBone(class'SkeletalMeshComponent', SkelMesh, Socket.SocketName)
		{
			`LOG("Mesh on socket:" @ string(SkelMesh));
		}
		`LOG("---------------------");
	}
}*/



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
	local X2EquipmentTemplate EqTemplate;

	//`LOG(GetFuncName() @ ItemState.GetMyTemplateName());

	if (ItemState.InventorySlot != eInvSlot_Utility)
		return false;
	
	EqTemplate = X2EquipmentTemplate(ItemState.GetMyTemplate());
	if (EqTemplate == none || EqTemplate.iItemSize <= 0)
		return false;

	if (default.ExcludeItems.Find(EqTemplate.DataName) != INDEX_NONE)
		return false;

	if (class'Help'.static.IsItemDefaultSocketGrenadeClip(ItemState))
	{
		if (class'Help'.static.FindGrenadeClipSocketForItem(ItemState) != '')
		{
			bDisplayItem = 1;
		}
	}
	else // Display all utility items that don't use GrenadeClip socket.
	{
		bDisplayItem = 1;
	}

	//`LOG("Displaying item:" @ bDisplayItem == 1);

	//	Return false to allow following Delegates to override the output of this delegate.
	return false;
}

static function WeaponInitialized(XGWeapon WeaponArchetype, XComWeapon Weapon, optional XComGameState_Item InternalWeaponState = none)
{
	local XComGameState_Item			ItemState;
	local name							NewSocketName;
	local AnimSet						Set;
	local AnimSequence					Sequence;
	local XComAnimNotify_ItemAttach		ItemAttach;
	local AnimNotify_ScriptedItemAttach ScriptedItemAttach;
	local AnimNotifyEvent				NotifyEvent;
	local bool							bNotifyFound;
	local int i;

	// #1. Initial checks
	if (Weapon.DefaultSocket != 'GrenadeClip' || InStr(Weapon.WeaponFireAnimSequenceName, "FF_Grenade") == INDEX_NONE)
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

	//`LOG("Weapon:" @ ItemState.GetMyTemplateName() @ "looking for a new socket");

	// #2. THis is a grenade. Find a free socket for it.
	NewSocketName = class'Help'.static.FindGrenadeClipSocketForItem(ItemState);
	if (NewSocketName == '')
		return;

	Weapon.SheathSocket = Weapon.DefaultSocket;
	Weapon.DefaultSocket = NewSocketName;
	
	//`LOG("Moving weapon:" @ InternalWeaponState.GetMyTemplateName() @ "to socket:" @ NewSocketName @ "SheathSocket:" @ Weapon.SheathSocket);
}

static function UpdateAnimations(out array<AnimSet> CustomAnimSets, XComGameState_Unit UnitState, XComUnitPawn Pawn)
{
	local AnimSet						Set;
	local AnimSequence					Sequence;
	local XComAnimNotify_ItemAttach		ItemAttach;
	local AnimNotify_ScriptedItemAttach ScriptedItemAttach;
	local AnimNotifyEvent				NotifyEvent;
	local bool							bNotifyFound;
	local int i;

    foreach Pawn.Mesh.AnimSets(Set)
	{
		foreach Set.Sequences(Sequence)
		{
			if (InStr(Sequence.SequenceName, "FF_Grenade") == INDEX_NONE &&
				InStr(Sequence.SequenceName, "FF_GrenadeUnderhand") == INDEX_NONE)
			{
				continue;
			}

			//`LOG("Patching sequence:" @ Sequence.SequenceName);

			bNotifyFound = false;
			for (i = 0; i < Sequence.Notifies.Length; i++)
			{
				ScriptedItemAttach = AnimNotify_ScriptedItemAttach(Sequence.Notifies[i].Notify);
				if (ScriptedItemAttach != none)
				{
					//`LOG("Notify already exists.");
					bNotifyFound = true;
					break;
				}
			}
			if (!bNotifyFound)
			{
				//`LOG("Injecting notifies");

				ItemAttach = new class'XComAnimNotify_ItemAttach';
				NotifyEvent.Time = 0.05f;
                NotifyEvent.Notify = ItemAttach;
                Sequence.Notifies.InsertItem(0, NotifyEvent);

				ScriptedItemAttach = new class'AnimNotify_ScriptedItemAttach';
				NotifyEvent.Time = 0;
                NotifyEvent.Notify = ScriptedItemAttach;
                Sequence.Notifies.InsertItem(0, NotifyEvent);
			}
		}
	}
}

//static function GetNumUtilitySlotsOverride(out int NumUtilitySlots, XComGameState_Item EquippedArmor, XComGameState_Unit UnitState, XComGameState CheckGameState)
//{
//	NumUtilitySlots = 5;
//}


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



