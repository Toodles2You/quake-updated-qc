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

float MULTI_USE = 1;
float INVISIBLE = 2;

void() damagethreshold_killed =
{
	self.health = self.max_health;

	//	self.solid = SOLID_NOT;
	self.takedamage = DAMAGE_NO;
	SUB_UseTargets ();
	self.takedamage = DAMAGE_YES;

	if (!(self.spawnflags & MULTI_USE))
	{
		remove (self);
	}
};

void(entity attacker, float damage) damagethreshold_pain =
{
	self.health = self.max_health;
};

void() trigger_damagethreshold =
{
	self.mangle = self.angles;
	self.angles = '0 0 0';

	self.classname = "damagethreshold";
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setorigin (self, self.origin);
	setmodel (self, self.model);
	setsize (self, self.mins, self.maxs);
	if ((self.spawnflags & INVISIBLE))
	{
		self.model = "";
	}

	if (!self.health)
	{
		self.health = 60;
	}
	self.max_health = self.health;
	self.takedamage = DAMAGE_YES;

	self.blocked = SUB_Null;
	self.th_pain = damagethreshold_pain;
	self.th_die = damagethreshold_killed;
};

void() func_breakawaywall =
{
	self.mangle = self.angles;
	self.angles = '0 0 0';

	self.classname = "breakaway";
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setorigin (self, self.origin);
	setmodel (self, self.model);
	setsize (self, self.mins, self.maxs);
	self.use = SUB_Remove;
};
