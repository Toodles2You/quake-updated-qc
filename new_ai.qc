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

// ================================================================
// ai_orbit - used to have an object orbit an entity.
//
// destEnt: the entity to orbit
// radius: how large a radius to orbit at (0 will just track)
// offset: center of the orbit. this is added to dest.origin.
//
// Uses self.orbitPosition to determine current destination.
// ================================================================
void(entity destEnt, float radius, vector offset) ai_orbit =
{
	local vector dir;
	local float dist;

	if (self.orbitPosition > 3)
		self.orbitPosition = 0;
	else if (self.orbitPosition < 0)
		self.orbitPosition = 0;

	traceline (self.origin, destEnt.origin + offset, TRUE, world);
	if (trace_fraction < 1)
	{
		setorigin (self, destEnt.origin + offset);
		self.orbitPosition = self.orbitPosition + 1;
		return;
	}

	if (self.orbitPosition == 0)
	{
		dir = (destEnt.origin + offset) - self.origin;
		dir_x = dir_x + radius;
	}
	else if (self.orbitPosition == 1)
	{
		dir = (destEnt.origin + offset) - self.origin;
		dir_y = dir_y + radius;
	}
	else if (self.orbitPosition == 2)
	{
		dir = (destEnt.origin + offset) - self.origin;
		dir_x = dir_x - radius;
	}
	else
	{
		dir = (destEnt.origin + offset) - self.origin;
		dir_y = dir_y - radius;
	}

	dist = vlen (dir);

	if (dist < 8)
	{
		self.orbitPosition = self.orbitPosition + 1;
	}
	else if (dist < 50)
	{
		self.velocity = normalize (dir);
		self.velocity = self.velocity * 150;
	}
	else
	{
		self.velocity = normalize (dir);
		self.velocity = self.velocity * 500;
	}
};

// ================================================================
// ai_track - used to have an object chase/track an enemy. the object
//		flies directly at the destEnt's view_ofs point.
//
// destEnt: the entity to orbit
// trackSpeed: the velocity multiplier (speed) of the object
// ================================================================
void(entity destEnt, float trackSpeed) ai_track =
{
	local vector dir;

	dir = destEnt.origin + destEnt.view_ofs;
	dir = normalize (dir - self.origin);
	self.velocity = dir * trackSpeed;
};

void(string gibname, float dm) AccelerateGib =
{
	local entity gib;

	local float offset1;

	gib = spawn ();
	gib.origin = self.origin;
	setmodel (gib, gibname);
	setsize (gib, '-8 -8 -8', '8 8 8');

	gib.velocity = -1.25 * self.velocity;
	makevectors (gib.velocity);
	offset1 = random () * 300 - 150;
	gib.velocity = gib.velocity + v_right* offset1;
	offset1 = random () * 300 - 150;
	gib.velocity = gib.velocity + v_up* offset1;

	gib.movetype = MOVETYPE_BOUNCE;
	gib.solid = SOLID_NOT;
	gib.avelocity_x = random () * 600;
	gib.avelocity_y = random () * 600;
	gib.avelocity_z = random () * 600;
	gib.think = SUB_Remove;
	gib.ltime = time;
	gib.nextthink = time + 10 + random () * 10;
	gib.frame = 0;
	gib.flags = 0;
};

void(float gibCount) ViolentDeath =
{
	while (gibCount > 0)
	{
		AccelerateGib ("progs/gib1.mdl", (-4 * gibCount));
		AccelerateGib ("progs/gib2.mdl", (-6 * gibCount));
		AccelerateGib ("progs/gib3.mdl", (-8 * gibCount));
		gibCount = gibCount - 3;
	}
};

entity(string gibname) StartGib =
{
	local entity gib;

	gib = spawn ();
	gib.origin = self.origin;
	setmodel (gib, gibname);
	setsize (gib, '0 0 0', '0 0 0');

	gib.movetype = MOVETYPE_BOUNCE;
	gib.solid = SOLID_NOT;
	gib.think = SUB_Remove;
	gib.ltime = time;
	gib.nextthink = time + 10 + random () * 10;
	gib.frame = 0;
	gib.flags = 0;

	return gib;
};
