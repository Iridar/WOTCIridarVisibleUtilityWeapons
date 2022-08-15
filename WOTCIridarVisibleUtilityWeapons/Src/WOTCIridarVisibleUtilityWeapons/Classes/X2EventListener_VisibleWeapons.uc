class X2EventListener_VisibleWeapons extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Create_ListenerTemplate());

	return Templates;
}

/*
'AbilityActivated', AbilityState, SourceUnitState, NewGameState
'PlayerTurnBegun', PlayerState, PlayerState, NewGameState
'PlayerTurnEnded', PlayerState, PlayerState, NewGameState
'UnitDied', UnitState, UnitState, NewGameState
'KillMail', UnitState, Killer, NewGameState
'UnitTakeEffectDamage', UnitState, UnitState, NewGameState
'OnUnitBeginPlay', UnitState, UnitState, NewGameState
'OnTacticalBeginPlay', X2TacticalGameRuleset, none, NewGameState
*/

static function CHEventListenerTemplate Create_ListenerTemplate()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'IRI_X2EventListener_VisibleWeapons');

	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = true;

	Template.AddCHEvent('ItemAddedToSlot', OnItemAddedToSlot, ELD_OnStateSubmitted, 50);
	Template.AddCHEvent('ItemRemovedFromSlot', OnItemRemovedFromSlot, ELD_OnStateSubmitted, 50);

	return Template;
}

static final function EventListenerReturn OnItemAddedToSlot(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
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

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState();
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
		UnitState.SetUnitFloatValue(UVName, ItemState.ObjectID, eCleanup_Never);
		`GAMERULES.SubmitGameState(NewGameState);
	}

    return ELR_NoInterrupt;
}



static final function EventListenerReturn OnItemRemovedFromSlot(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
	local XComGameState_Item	ItemState;
	local XComGameState_Unit	UnitState;
	local name					SocketName;
	local XComGameState			NewGameState;
	local name					UVName;
	local int					Index;

    ItemState = XComGameState_Item(EventData);
	if (ItemState == none)
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none)
		return ELR_NoInterrupt;

	SocketName = class'Help'.static.GetItemDefaultSocket(ItemState, UnitState);
	if (SocketName == '')
		return ELR_NoInterrupt;

	Index = class'Help'.static.FindItemSocketIndex(ItemState, UnitState, SocketName);
	if (Index != INDEX_NONE)
	{
		UVName = name(SocketName $ Index);

		`LOG("Removed item:" @ ItemState.GetMyTemplateName() @ "from socket:" @ UVName);

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState();
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
		UnitState.ClearUnitValue(UVName);
		`GAMERULES.SubmitGameState(NewGameState);
	}

    return ELR_NoInterrupt;
}
