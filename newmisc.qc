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

void() light_lantern =
{
	precache_model ("progs/lantern.mdl");
	setmodel (self, "progs/lantern.mdl");
	makestatic (self);
};

void() light_candle =
{
	precache_model ("progs/candle.mdl");
	setmodel (self, "progs/candle.mdl");
	makestatic (self);
};

void() rubble_touch =
{
	if (other.classname == "player" || (other.flags & FL_MONSTER))
	{
		if (vlen (self.velocity) > 0)
		{
			T_Damage (other, self, self, 10);
		}
	}
};

void() rubble_throw =
{
	local vector throw;
	local entity rubble;

	rubble = find (world, targetname, self.target);
	throw = normalize (rubble.origin - self.origin);
	throw_x = throw_x + (random () * 0.2) - 0.1;
	throw_y = throw_y + (random () * 0.2) - 0.1;
	throw_z = throw_z + (random () * 0.2) - 0.1;

	rubble = spawn ();
	rubble.owner = self;
	rubble.classname = "rubble";
	rubble.movetype = MOVETYPE_BOUNCE;
	rubble.solid = SOLID_BBOX;
	rubble.velocity = throw *300;
	setmodel (rubble, "progs/rubble.mdl");
	setsize (rubble, '-16 -16 -16', '16 16 16');
	setorigin (rubble, self.origin);
	rubble.touch = rubble_touch;

	rubble.think = SUB_Remove;
	rubble.nextthink = time + 30;

	if ((self.spawnflags & 1))
		rubble.skin = 1;
	else
		rubble.skin = 0;

	self.think = rubble_throw;
	self.nextthink = time + self.delay;
};

void() rubble_use =
{
	if (self.wait == 0)
	{
		self.think = rubble_throw;
		self.nextthink = time + self.delay;
		self.wait = 1;
	}
	else
	{
		self.nextthink = time - 1;
		self.wait = 0;
	}
};

void() rubble_generator =
{
	if (self.target == "")
	{
		enterror ("rubble_generator has no target!");
		return;
	}

	precache_model ("progs/rubble.mdl");

	if (!self.delay)
		self.delay = 5;

	self.solid = SOLID_NOT;
	self.use = rubble_use;

	if ((self.spawnflags & 2))
		rubble_use ();
};

void() trigEx_die =
{
	SUB_UseTargets ();

	self.touch = SUB_Null;
	self.nextthink = time + 0.1;
	self.think = SUB_Remove;
};

void() trigger_explosion =
{
	InitTrigger ();

	if (!self.health)
		self.health = 20;

	self.max_health = self.health;
	self.th_die = trigEx_die;
	self.takedamage = DAMAGE_YES;
	self.solid = SOLID_BBOX;
	setorigin (self, self.origin);
};
