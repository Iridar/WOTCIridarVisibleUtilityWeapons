class AnimNotify_ScriptedItemAttach extends AnimNotify_Scripted;

var XComAnimNotify_ItemAttach ItemAttach;
var name FromSocket;

// This Notify will instruct inlaid ItemAttach Notify to move the weapon mesh from weapon's new DefaultSocket to the weapon's old DefaultSocket,
// which we store in the weapon's SheathSocket, since - hoping really hard there - grenades don't have sheath. Even if they did, 
// sheath are usually done as default attachment, since this field in the weapon archetype is broken.

event Notify(Actor Owner, AnimNodeSequence AnimSeqInstigator)
{
	local XComUnitPawn	Pawn;
	local XComWeapon	ActiveWeapon;

	Pawn = XComUnitPawn(Owner);
    if (Pawn == none)
		return;

	ActiveWeapon = XComWeapon(Pawn.Weapon);
	if (ActiveWeapon == none)
		return;

	ItemAttach.ToSocket = ActiveWeapon.SheathSocket;
	ItemAttach.FromSocket = ActiveWeapon.DefaultSocket;
}

