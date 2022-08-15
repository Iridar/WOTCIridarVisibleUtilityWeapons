class AnimNotify_ScriptedItemAttach extends AnimNotify_Scripted;

var XComAnimNotify_ItemAttach ItemAttach;
var name FromSocket;

event Notify(Actor Owner, AnimNodeSequence AnimSeqInstigator)
{
	local XComUnitPawn				Pawn;
	local XComWeapon				ActiveWeapon;

	Pawn = XComUnitPawn(Owner);
    if (Pawn == none)
		return;

	ActiveWeapon = XComWeapon(Pawn.Weapon);
	if (ActiveWeapon == none)
		return;

	ItemAttach.FromSocket = ActiveWeapon.DefaultSocket;
}
