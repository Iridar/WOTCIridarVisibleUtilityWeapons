class AnimNotify_ScriptedItemAttach extends AnimNotify_Scripted;

// This Notify will instruct inlaid ItemAttach Notify to move the weapon mesh from weapon's new DefaultSocket to the weapon's old DefaultSocket,
// which we store in the weapon's SheathSocket, since - hoping really hard there - grenades don't have sheath. Even if they did, 
// sheath are usually done as default attachment, since this field in the weapon archetype is broken.

event Notify(Actor Owner, AnimNodeSequence AnimSeqInstigator)
{
	local XComAnimNotify_ItemAttach	ItemAttach;
	local XComUnitPawn				Pawn;
	local XComWeapon				ActiveWeapon;
	local XComGameState_Item		ItemState;
	local int i;

	//`LOG("Running notify for sequence:" @ AnimSeqInstigator.AnimSeq.SequenceName);
	
	Pawn = XComUnitPawn(Owner);
    if (Pawn == none)
		return;

	ActiveWeapon = XComWeapon(Pawn.Weapon);
	if (ActiveWeapon == none)
		return;

	for (i = 0; i < AnimSeqInstigator.AnimSeq.Notifies.Length; i++)
	{
		//`LOG(i @ "Notify:" @ AnimSeqInstigator.AnimSeq.Notifies[i].Notify.Class @ AnimSeqInstigator.AnimSeq.Notifies[i].Time);
		ItemAttach = XComAnimNotify_ItemAttach(AnimSeqInstigator.AnimSeq.Notifies[i].Notify);
		if (ItemAttach != none)
		{
			ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ActiveWeapon.m_kGameWeapon.ObjectID));
			if (ItemState != none && class'Help'.static.IsItemDefaultSocketGrenadeClip(ItemState))
			{
				ItemAttach.ToSocket = ActiveWeapon.SheathSocket;
				ItemAttach.FromSocket = ActiveWeapon.DefaultSocket;
				//`LOG("Moving from" @ ItemAttach.FromSocket @ "to:" @ ItemAttach.ToSocket);
			}
			else
			{
				ItemAttach.ToSocket = '';
				ItemAttach.FromSocket = '';
				//`LOG("Not grenade clip sheath socket");
			}
			break;
		}
	}
}

