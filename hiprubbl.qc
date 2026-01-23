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

void() hipRubbleTouch =
{
	if (self.ltime < self.pausetime)
		return;

	if (other.takedamage)
	{
		T_Damage (other, self, self.owner, 10);
		sound (self, CHAN_WEAPON, "zombie/z_hit.wav", 1, ATTN_NORM);
		self.pausetime = self.ltime + 0.1;
	}
};

void(string rubblename) hipThrowRubble =
{
	local entity rubble;

	rubble = spawn ();
	rubble.origin = self.origin;
	setmodel (rubble, rubblename);
	setsize (rubble, '0 0 0', '0 0 0');
	rubble.velocity_x = 70 * crandom ();
	rubble.velocity_y = 70 * crandom ();
	rubble.velocity_z = 140 + 70 * random ();
	rubble.movetype = MOVETYPE_BOUNCE;
	rubble.solid = SOLID_BBOX;
	rubble.avelocity_x = random () * 600;
	rubble.avelocity_y = random () * 600;
	rubble.avelocity_z = random () * 600;
	rubble.think = SUB_Remove;
	rubble.touch = hipRubbleTouch;
	rubble.ltime = time;
	rubble.nextthink = time + 13 + random () * 10;
	self.pausetime = time;
	rubble.frame = 0;
	rubble.flags = 0;
};

void() rubble_use =
{
	local float which;
	local float index;

	index = 0;

	do {
		which = self.cnt;
		if (self.cnt == 0)
		{
			which = 1 + 3 * random ();
			which = floor (which);
		}
		if (which == 1)
		{
			hipThrowRubble ("progs/rubble1.mdl");
		}
		else if (which == 2)
		{
			hipThrowRubble ("progs/rubble3.mdl");
		}
		else
		{
			hipThrowRubble ("progs/rubble2.mdl");
		}
		index = index + 1;
	} while (index < self.count);
};

void() func_rubble =
{
	precache_model ("progs/rubble1.mdl");
	precache_model ("progs/rubble2.mdl");
	precache_model ("progs/rubble3.mdl");
	precache_sound ("zombie/z_hit.wav");
	self.classname = "rubble";
	self.cnt = 0;
	self.use = rubble_use;
};

void() func_rubble1 =
{
	precache_model ("progs/rubble1.mdl");
	precache_sound ("zombie/z_hit.wav");
	self.classname = "rubble1";
	self.cnt = 1;
	self.use = rubble_use;
};

void() func_rubble2 =
{
	precache_model ("progs/rubble3.mdl");
	precache_sound ("zombie/z_hit.wav");
	self.classname = "rubble2";
	self.cnt = 2;
	self.use = rubble_use;
};

void() func_rubble3 =
{
	precache_model ("progs/rubble2.mdl");
	precache_sound ("zombie/z_hit.wav");
	self.classname = "rubble3";
	self.cnt = 3;
	self.use = rubble_use;
};
