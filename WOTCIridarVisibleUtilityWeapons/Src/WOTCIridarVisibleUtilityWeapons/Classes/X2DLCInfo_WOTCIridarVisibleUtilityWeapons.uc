class X2DLCInfo_WOTCIridarVisibleUtilityWeapons extends X2DownloadableContentInfo;

var config array<name> PatchAnimations;
var config array<name> ExcludeItems;
var config array<name> ExcludeItemCategories;
var config array<name> ExcludeWeaponCategories;


var private SkeletalMeshSocket GrenadeClip1Socket;
var private SkeletalMeshSocket GrenadeClip2Socket;
var private SkeletalMeshSocket GrenadeClip3Socket;
var private SkeletalMeshSocket GrenadeClip4Socket;
var private SkeletalMeshSocket GrenadeClip5Socket;

var private SkeletalMeshSocket GrenadeClip1Socket_Female;
var private SkeletalMeshSocket GrenadeClip2Socket_Female;
var private SkeletalMeshSocket GrenadeClip3Socket_Female;
var private SkeletalMeshSocket GrenadeClip4Socket_Female;
var private SkeletalMeshSocket GrenadeClip5Socket_Female;

// TODO: Manually spawn weapon mesh for merged out items?
// TODO: cache default socket of all items to allow equipping only one item into each non-grenade socket.

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
	local XComHumanPawn				HumanPawn;

	HumanPawn = XComHumanPawn(Pawn);
	if (HumanPawn == none)
		return "";

	if (HumanPawn.m_kAppearance.iGender == eGender_Female)
	{
		NewSockets.AddItem(default.GrenadeClip1Socket_Female);
		NewSockets.AddItem(default.GrenadeClip2Socket_Female);
		NewSockets.AddItem(default.GrenadeClip3Socket_Female);
		NewSockets.AddItem(default.GrenadeClip4Socket_Female);
		NewSockets.AddItem(default.GrenadeClip5Socket_Female);
	}
	else
	{
		NewSockets.AddItem(default.GrenadeClip1Socket);
		NewSockets.AddItem(default.GrenadeClip2Socket);
		NewSockets.AddItem(default.GrenadeClip3Socket);
		NewSockets.AddItem(default.GrenadeClip4Socket);
		NewSockets.AddItem(default.GrenadeClip5Socket);
	}

	Pawn.Mesh.AppendSockets(NewSockets, false);

	return "";
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
	local X2EquipmentTemplate EqTemplate;

	//`LOG(GetFuncName() @ ItemState.GetMyTemplateName());

	EqTemplate = X2EquipmentTemplate(ItemState.GetMyTemplate());
	if (EqTemplate == none || EqTemplate.iItemSize <= 0)
		return false;

	// This allows grenades in grenade slot to pass.
	if (ItemState.InventorySlot != eInvSlot_Utility && EqTemplate.InventorySlot != eInvSlot_Utility)
		return false;

	if (default.ExcludeItems.Find(EqTemplate.DataName) != INDEX_NONE)
		return false;

	if (default.ExcludeItemCategories.Find(EqTemplate.ItemCat) != INDEX_NONE)
		return false;

	if (default.ExcludeWeaponCategories.Find(ItemState.GetWeaponCategory()) != INDEX_NONE)
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
	local XComGameState_Item	ItemState;
	local name					NewSocketName;
	local X2EquipmentTemplate	EqTemplate;

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

	EqTemplate = X2EquipmentTemplate(ItemState.GetMyTemplate());
	if (EqTemplate == none || EqTemplate.iItemSize <= 0)
		return;

	if (default.ExcludeItems.Find(EqTemplate.DataName) != INDEX_NONE)
		return;

	if (default.ExcludeItemCategories.Find(EqTemplate.ItemCat) != INDEX_NONE)
		return;

	if (default.ExcludeWeaponCategories.Find(ItemState.GetWeaponCategory()) != INDEX_NONE)
		return;

	//`LOG("Weapon:" @ ItemState.GetMyTemplateName() @ "looking for a new socket");

	// #2. THis is a grenade-like item. Find a free socket for it.
	NewSocketName = class'Help'.static.FindGrenadeClipSocketForItem(ItemState);
	if (NewSocketName == '')
		return;

	if (default.PatchAnimations.Find(Weapon.WeaponFireAnimSequenceName) == INDEX_NONE)
	{
		default.PatchAnimations.AddItem(Weapon.WeaponFireAnimSequenceName);
	}

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
	local name							PatchAnimation;
	local bool							bPatchAnimation;
	local int i;

    foreach Pawn.Mesh.AnimSets(Set)
	{
		foreach Set.Sequences(Sequence)
		{
			bPatchAnimation = false;
			foreach default.PatchAnimations(PatchAnimation)
			{
				if (InStr(Sequence.SequenceName, PatchAnimation) != INDEX_NONE)
				{
					bPatchAnimation = true;
					break;
				}
			}
			if (!bPatchAnimation)
				continue;

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

static function GetNumUtilitySlotsOverride(out int NumUtilitySlots, XComGameState_Item EquippedArmor, XComGameState_Unit UnitState, XComGameState CheckGameState)
{
	NumUtilitySlots = 5;
}


defaultproperties
{
	Begin Object Class=SkeletalMeshSocket Name=DefaultGrenadeClip1Socket
		SocketName="GrenadeClip1"
		BoneName="Pelvis"
		RelativeLocation=(X=2.206445,Y=3.444289,Z=13.893759)
		RelativeRotation=(Pitch=546,Yaw=12561,Roll=-16384)
	End Object
	GrenadeClip1Socket = DefaultGrenadeClip1Socket;

	Begin Object Class=SkeletalMeshSocket Name=DefaultGrenadeClip2Socket
		SocketName="GrenadeClip2"
		BoneName="Pelvis"
		RelativeLocation=(X=2.201149,Y=-3.475295,Z=14.840501)
		RelativeRotation=(Pitch=1820,Yaw=12561,Roll=-16384)
	End Object
	GrenadeClip2Socket = DefaultGrenadeClip2Socket;

	Begin Object Class=SkeletalMeshSocket Name=DefaultGrenadeClip3Socket
		SocketName="GrenadeClip3"
		BoneName="Pelvis"
		RelativeLocation=(X=2.265384,Y=-9.862941,Z=11.735182)
		RelativeRotation=(Pitch=4551,Yaw=12561,Roll=-16384)
	End Object
	GrenadeClip3Socket = DefaultGrenadeClip3Socket;

	Begin Object Class=SkeletalMeshSocket Name=DefaultGrenadeClip4Socket
		SocketName="GrenadeClip4"
		BoneName="Pelvis"
		RelativeLocation=(X=2.723464,Y=-9.743815,Z=-11.780566)
		RelativeRotation=(Pitch=-4551,Yaw=12561,Roll=-16384)
	End Object
	GrenadeClip4Socket = DefaultGrenadeClip4Socket;

	Begin Object Class=SkeletalMeshSocket Name=DefaultGrenadeClip5Socket
		SocketName="GrenadeClip5"
		BoneName="Pelvis"
		RelativeLocation=(X=2.329639,Y=-3.263483,Z=-14.908339)
		RelativeRotation=(Pitch=-4551,Yaw=12561,Roll=-16384)
	End Object
	GrenadeClip5Socket = DefaultGrenadeClip5Socket;


	Begin Object Class=SkeletalMeshSocket Name=DefaultGrenadeClip1Socket_Female
		SocketName="GrenadeClip1"
		BoneName="Pelvis"
		RelativeLocation=(X=2.211112,Y=3.456443,Z=13.644358)
		RelativeRotation=(Pitch=546,Yaw=12561,Roll=-16384)
	End Object
	GrenadeClip1Socket_Female = DefaultGrenadeClip1Socket_Female;

	Begin Object Class=SkeletalMeshSocket Name=DefaultGrenadeClip2Socket_Female
		SocketName="GrenadeClip2"
		BoneName="Pelvis"
		RelativeLocation=(X=2.269285,Y=-3.297851,Z=13.762257)
		RelativeRotation=(Pitch=1820,Yaw=12561,Roll=-16384)
	End Object
	GrenadeClip2Socket_Female = DefaultGrenadeClip2Socket_Female;

	Begin Object Class=SkeletalMeshSocket Name=DefaultGrenadeClip3Socket_Female
		SocketName="GrenadeClip3"
		BoneName="Pelvis"
		RelativeLocation=(X=2.534360,Y=-9.162449,Z=10.124779)
		RelativeRotation=(Pitch=4551,Yaw=12561,Roll=-16384)
	End Object
	GrenadeClip3Socket_Female = DefaultGrenadeClip3Socket_Female;

	Begin Object Class=SkeletalMeshSocket Name=DefaultGrenadeClip4Socket_Female
		SocketName="GrenadeClip4"
		BoneName="Pelvis"
		RelativeLocation=(X=3.038204,Y=-8.924140,Z=-9.898050)
		RelativeRotation=(Pitch=-4551,Yaw=12561,Roll=-16384)
	End Object
	GrenadeClip4Socket_Female = DefaultGrenadeClip4Socket_Female;

	Begin Object Class=SkeletalMeshSocket Name=DefaultGrenadeClip5Socket_Female
		SocketName="GrenadeClip5"
		BoneName="Pelvis"
		RelativeLocation=(X=2.521074,Y=-2.764932,Z=-13.763337)
		RelativeRotation=(Pitch=-4551,Yaw=12561,Roll=-16384)
	End Object
	GrenadeClip5Socket_Female = DefaultGrenadeClip5Socket_Female;
}
