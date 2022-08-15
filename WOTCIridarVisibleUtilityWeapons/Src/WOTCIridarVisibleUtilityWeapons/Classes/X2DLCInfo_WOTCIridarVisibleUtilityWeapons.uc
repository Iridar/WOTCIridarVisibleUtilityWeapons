class X2DLCInfo_WOTCIridarVisibleUtilityWeapons extends X2DownloadableContentInfo;

var config array<name> ExcludeItems;

var private SkeletalMeshSocket GrenadeClip0Socket;
var private SkeletalMeshSocket GrenadeClip1Socket;
var private SkeletalMeshSocket GrenadeClip2Socket;
var private SkeletalMeshSocket GrenadeClip3Socket;

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
}

static function string DLCAppendSockets(XComUnitPawn Pawn)
{
	local array<SkeletalMeshSocket> NewSockets;

	NewSockets.AddItem(default.GrenadeClip0Socket);
	NewSockets.AddItem(default.GrenadeClip1Socket);
	NewSockets.AddItem(default.GrenadeClip2Socket);
	NewSockets.AddItem(default.GrenadeClip3Socket);

	Pawn.Mesh.AppendSockets(NewSockets, true);

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
	local X2WeaponTemplate		WeaponTemplate;
	local XComGameState_Unit	UnitState;
	local name					SocketName;
	local int					Index;

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

	Index = class'Help'.static.FindItemSocketIndex(ItemState, UnitState, SocketName);
	if (Index != INDEX_NONE)
	{
		`LOG("Displaying item:" @ ItemState.GetMyTemplateName() @ "in socket:" @ SocketName);
		bDisplayItem = 1;
	}
	
	//	Return false to allow following Delegates to override the output of this delegate.
	return false;
}

static function WeaponInitialized(XGWeapon WeaponArchetype, XComWeapon Weapon, optional XComGameState_Item InternalWeaponState = none)
{
    Local XComGameState_Item	ItemState;
	local XComGameState_Unit	UnitState;
	local int					Index;
	local AnimSet				Set;
	local AnimSequence			Sequence;

	local XComAnimNotify_ItemAttach		ItemAttach;
	local AnimNotify_ScriptedItemAttach ScriptedItemAttach;
	local AnimNotifyEvent				NotifyEvent;
	local bool							bNotifyFound;
	local int i;

	if (Weapon.DefaultSocket != 'GrenadeClip' /* && Weapon.DefaultSocket != 'R_Hip'*/)
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

	Index = class'Help'.static.FindItemSocketIndex(ItemState, UnitState, Weapon.DefaultSocket);
	if (Index == INDEX_NONE)
		return;
	
	Weapon.DefaultSocket = name(Weapon.DefaultSocket $ Index);

	foreach Weapon.CustomUnitPawnAnimsets(Set)
	{
		foreach Set.Sequences(Sequence)
		{
			if (InStr(Sequence.SequenceName, "FF_Grenade") == INDEX_NONE &&
				InStr(Sequence.SequenceName, "FF_GrenadeUnderhand") == INDEX_NONE &&
				InStr(Sequence.SequenceName, Weapon.WeaponFireAnimSequenceName) == INDEX_NONE &&
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
				ItemAttach.ToSocket = 'GrenadeClip';
				NotifyEvent.Time = 0.05f;
                NotifyEvent.Notify = ItemAttach;
                Sequence.Notifies.InsertItem(0, NotifyEvent);

				ScriptedItemAttach = new class'AnimNotify_ScriptedItemAttach';
				ScriptedItemAttach.ItemAttach = ItemAttach;
				ScriptedItemAttach.FromSocket = Weapon.DefaultSocket;
				NotifyEvent.Time = 0;
                NotifyEvent.Notify = ScriptedItemAttach;
                Sequence.Notifies.InsertItem(0, NotifyEvent);
			}
		}
	}
}

static function UpdateAnimations(out array<AnimSet> CustomAnimSets, XComGameState_Unit UnitState, XComUnitPawn Pawn)
{
    local AnimSet Set;
    local AnimSequence Sequence;
    local AnimNotifyEvent NotifyEvent;
    local AnimNotify_FireWeaponVolley TestNotify;
    local int i;

    foreach Pawn.Mesh.AnimSets(Set)
    {
        foreach Set.Sequences(Sequence)
        {
            if (InStr(Sequence.SequenceName, "FF_Grenade") != INDEX_NONE ||
				InStr(Sequence.SequenceName, "FF_GrenadeUnderhand") != INDEX_NONE)
            {
                `log(`showvar(Sequence.SequenceName));
                for (i = 0; i<Sequence.Notifies.Length; i++)
                {
                    TestNotify = AnimNotify_FireWeaponVolley(Sequence.Notifies[i].Notify);
                    if (TestNotify==none) continue;
                    if (TestNotify!=none && TestNotify.PerkAbilityName == "MCDetonate") return;
                    if (TestNotify!=none && TestNotify.PerkAbilityName == "Fuse")
                    {
                        `log(`showvar(TestNotify.PerkAbilityName));
                        `log(`showvar(TestNotify.bPerkVolley));
                        NotifyEvent.Time = Sequence.Notifies[i].Time;
                        NotifyEvent.Notify = new class'AnimNotify_FireWeaponVolley'(TestNotify);
                        AnimNotify_FireWeaponVolley(NotifyEvent.Notify).PerkAbilityName = "MCDetonate";
                        `log(`showvar(AnimNotify_FireWeaponVolley(NotifyEvent.Notify).bPerkVolley));
                        Sequence.Notifies.InsertItem(i++, NotifyEvent);
                        //break;
                    }
                }
            }
        }
    }
}

/// <summary>
/// This method is run when the player loads a saved game directly into Strategy while this DLC is installed
/// </summary>
static event OnLoadedSavedGameToStrategy()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = `XCOMHQ;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState();
	CreateItemSocketUnitValues(XComHQ, NewGameState);
	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMHISTORY.AddGameStateToHistory(NewGameState);
	}
	else
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}
}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed. When a new campaign is started the initial state of the world
/// is contained in a strategy start state. Never add additional history frames inside of InstallNewCampaign, add new state objects to the start state
/// or directly modify start state objects
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{
	local XComGameState_HeadquartersXCom XComHQ;

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}
	if (XComHQ != none)
	{
		CreateItemSocketUnitValues(XComHQ, StartState);
	}
}

static private function CreateItemSocketUnitValues(XComGameState_HeadquartersXCom XComHQ, XComGameState NewGameState)
{
	local XComGameState_Item	ItemState;
	local XComGameState_Unit	UnitState;
	local name					SocketName;
	local XComGameState			NewGameState;
	local name					UVName;
	local int					Index;

	ItemState = XComGameState_Item(EventData);
	if (ItemState == none || ItemState.bMergedOut)
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none || UnitState.InventoryItems.Find('ObjectID', ItemState.ObjectID) == INDEX_NONE)
		return ELR_NoInterrupt;

	SocketName = class'Help'.static.GetItemDefaultSocket(ItemState, UnitState);
	if (SocketName == '')
		return ELR_NoInterrupt;

	Index = class'Help'.static.FindFreeSocketIndex(UnitState, SocketName);
	if (Index != INDEX_NONE)
	{
		UVName = name(SocketName $ Index);

		`LOG("Equipped item:" @ ItemState.GetMyTemplateName() @ "into socket:" @ UVName);

		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
		UnitState.SetUnitFloatValue(UVName, ItemState.ObjectID, eCleanup_Never);
	}

    return ELR_NoInterrupt;
}

// TODO: Debug only
static function GetNumUtilitySlotsOverride(out int NumUtilitySlots, XComGameState_Item EquippedArmor, XComGameState_Unit UnitState, XComGameState CheckGameState)
{
	NumUtilitySlots = 5;
}

defaultproperties
{
	Begin Object Class=SkeletalMeshSocket Name=DefaultGrenadeClip0Socket
		SocketName = "GrenadeClip0"
		BoneName = "Pelvis"
		RelativeLocation=(X=0.0f,Y=-5.0f,Z=20.0f)
	End Object
	GrenadeClip0Socket = DefaultGrenadeClip0Socket;

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
}


