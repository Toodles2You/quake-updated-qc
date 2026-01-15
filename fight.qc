/*  Copyright (C) 1996-2022 id Software LLC

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'COPYING', for details.
*/

/*
A monster is in fight mode if it thinks it can effectively attack its enemy.

When it decides it can't attack, it goes into hunt mode.
*/

float(float v) anglemod;

void(vector dest) ChooseTurn;

void() ai_face;

float enemy_vis, enemy_infront, enemy_range, enemy_yaw;

/*
==============================================================================
CheckAttack

The player is in view, so decide to move or launch an attack
Returns FALSE if movement should continue
==============================================================================
*/
float() CheckAttack =
{
	local vector spot1, spot2;
	local entity targ;
	local float chance;

	targ = self.enemy;

	// see if any entities are in the way of the shot
	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;

	traceline (spot1, spot2, FALSE, self);

	if ((trace_ent != targ) && (!self.charmed))
		return FALSE;

	if (trace_inopen && trace_inwater)
		return FALSE; // sight line crossed contents

	if (enemy_range == RANGE_MELEE)
	{
		if (self.th_melee)
		{
			self.th_melee ();
			return TRUE;
		}
	}

	if (!self.th_missile)
		return FALSE;

	if (time < self.attack_finished)
		return FALSE;

	if (enemy_range == RANGE_FAR)
		return FALSE;

	if (enemy_range == RANGE_MELEE)
	{
		chance = 0.9;
		self.attack_finished = 0;
	}
	else if (enemy_range == RANGE_NEAR)
	{
		if (self.th_melee)
			chance = 0.2;
		else
			chance = 0.4;
	}
	else if (enemy_range == RANGE_MID)
	{
		if (self.th_melee)
			chance = 0.05;
		else
			chance = 0.1;
	}
	else
		chance = 0;

	if (random () < chance)
	{
		self.th_missile ();
		SUB_AttackFinished (2 * random ());
		return TRUE;
	}

	return FALSE;
};

void() ai_face =
{
	self.ideal_yaw = vectoyaw (self.enemy.origin - self.origin);
	ChangeYaw ();
};

float(entity targ) visible;
float(entity targ) infront;
float(entity targ) range;

void(float d) ai_charge =
{
	ai_face ();
	movetogoal (d); // done in C code...
};

void() ai_charge_side =
{
	local vector dtemp;
	local float heading;

	// aim to the left of the enemy for a flyby

	self.ideal_yaw = vectoyaw (self.enemy.origin - self.origin);
	ChangeYaw ();

	makevectors (self.angles);
	dtemp = self.enemy.origin - 30 * v_right;
	heading = vectoyaw (dtemp - self.origin);

	walkmove (heading, 20);
};

void() ai_melee =
{
	local vector delta;
	local float ldmg;

	if (!self.enemy)
		return;

	delta = self.enemy.origin - self.origin;

	if (vlen (delta) > 60)
		return;

	ldmg = (random () + random () + random ()) * 3;
	T_Damage (self.enemy, self, self, ldmg);
};

void() ai_melee_side =
{
	local vector delta;
	local float ldmg;

	if (!self.enemy)
		return;

	ai_charge_side ();

	delta = self.enemy.origin - self.origin;

	if (vlen (delta) > 60)
		return;
	if (!CanDamage (self.enemy, self))
		return;
	ldmg = (random () + random () + random ()) * 3;
	T_Damage (self.enemy, self, self, ldmg);
};
