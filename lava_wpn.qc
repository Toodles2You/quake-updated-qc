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

entity(vector org, vector dir) launch_lava_spike =
{
	local entity missile;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;

	missile.angles = vectoangles (dir);

	missile.touch = lavaspike_touch;
	missile.classname = "lava_spike";
	missile.think = SUB_Remove;
	missile.nextthink = time + 6;
	setmodel (missile, "progs/lspike.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, org);

	missile.velocity = dir * 1000;

	return missile;
};

void() W_FireSuperLavaSpikes =
{
	local vector dir;
	local entity missile;

	sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
	self.currentammo = self.ammo_lava_nails = self.ammo_lava_nails - 2;
	UpdateAmmoCounts (self);

	dir = aim (self, 1000);
	missile = launch_lava_spike (self.origin + '0 0 16', dir);
	missile.touch = superlavaspike_touch;

	setsize (missile, '0 0 0', '0 0 0');
	self.punchangle_x = -2;
};

void(float ox) W_FireLavaSpikes =
{
	local vector dir;

	makevectors (self.v_angle);

	if (self.ammo_lava_nails >= 2 && self.weapon == IT_LAVA_SUPER_NAILGUN)
	{
		W_FireSuperLavaSpikes ();
		return;
	}

	if (self.ammo_lava_nails < 1)
	{
		sprint (self, "Out of Lava Nails\n");
		W_SetWeapon (W_BestWeapon ());
		return;
	}

	sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
	self.currentammo = self.ammo_lava_nails = self.ammo_lava_nails - 1;
	UpdateAmmoCounts (self);

	dir = aim (self, 1000);
	launch_lava_spike (self.origin + '0 0 16' + v_right * ox, dir);

	self.punchangle_x = -2;
};

void() lavaspike_touch =
{
	local float old_armortype;
	local float old_armorvalue;
	local float old_armormask;

	if (pointcontents (self.origin) == CONTENT_SKY)
	{
		remove (self);
		return;
	}

	// hit something that bleeds
	if (SUB_ShouldBleed (other))
		spawn_touchblood (9);
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);

		if (self.classname == "wizspike")
			WriteByte (MSG_BROADCAST, TE_WIZSPIKE);
		else if (self.classname == "knightspike")
			WriteByte (MSG_BROADCAST, TE_KNIGHTSPIKE);
		else
			WriteByte (MSG_BROADCAST, TE_SPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	if (other.takedamage)
	{
		if (other.classname == "player")
		{
			old_armortype = other.armortype;
			old_armorvalue = other.armorvalue;
			old_armormask = other.items2 & IT2_ARMOR;
			other.armortype = 0;
			other.armorvalue = 0;
			T_Damage (other, self, self.owner, 9);
			other.armortype = old_armortype;
			other.armorvalue = old_armorvalue;
			other.items2 = other.items2 | old_armormask;
		}
		else // is a monster
		{
			if (other.classname != "monster_lava_man")
			{
				T_Damage (other, self, self.owner, 15);
			}
		}
	}

	remove (self);
};

void() superlavaspike_touch =
{
	local float old_armortype;

	if (pointcontents (self.origin) == CONTENT_SKY)
	{
		remove (self);
		return;
	}

	// hit something that bleeds
	if (SUB_ShouldBleed (other))
		spawn_touchblood (18);
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_SUPERSPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	if (other.takedamage)
	{

		// halve the effectiveness of the armor for players..
		if (other.classname == "player")
		{
			// save the old armor values...
			old_armortype = other.armortype;
			other.armortype = other.armortype * 0.5;
			T_Damage (other, self, self.owner, 18);

			// if the damage didn't wipe out the armor, armortype
			if (other.armortype != 0)
			{
				other.armortype = old_armortype;
			}
		}
		else // is a monster, do 50% more damage
		{
			if (other.classname != "monster_lava_man")
			{
				T_Damage (other, self, self.owner, 30);
			}
		}
	}

	remove (self);
};
