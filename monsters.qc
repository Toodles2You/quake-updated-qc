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

// name =[framenum,	nexttime, nextthink] {code}
// expands to:
// name ()
// {
//		self.frame=framenum;
//		self.nextthink = time + nexttime;
//		self.think = nextthink
//		<code>
// };

/*
==============================================================================
monster_use

Using a monster makes it angry at the current activator
==============================================================================
*/
void() monster_use =
{
	if (self.enemy)
		return;
	if (self.health <= 0)
		return;
	if (!CanFindTarget (other, FIND_DIRECT))
		return;

	// delay reaction so if the monster is teleported, its sound is still heard
	self.enemy = other;
	self.nextthink = time + 0.1;
	self.think = FoundTarget;
};

/*
==============================================================================
monster_death_use

When a mosnter dies, it fires all of its targets with the current
enemy as activator.
==============================================================================
*/
void() monster_death_use =
{
	// fall to ground
	self.flags = self.flags - (self.flags & (FL_FLY | FL_SWIM));

	if (self.target == "")
		return;

	SUB_UseTargetsEnt (self, self.enemy);
};

void() monster_start_spread =
{
	// spread think times so they don't all happen at same time
	self.nextthink = self.nextthink + random () * 0.5;

	if (self.nextthink < time + 0.1)
		self.nextthink = time + 0.1;
};

void() monster_start_moving =
{
	if (self.target == "")
	{
		self.pausetime = 0;
		self.th_stand ();
		return;
	}

	self.movetarget = find (world, targetname, self.target);

	if (!self.movetarget)
	{
		dprint ("Monster can't find target at ");
		dprint (vtos (self.origin));
		dprint ("\n");

		self.pausetime = 0;
		self.th_stand ();
		return;
	}

	if (self.movetarget.classname != "path_corner")
	{
		self.movetarget = world;
		self.pausetime = 0;
		self.th_stand ();
		return;
	}

	self.goalentity = self.movetarget;
	self.ideal_yaw = vectoyaw (self.goalentity.origin - self.origin);
	self.th_walk ();
};

void() walkmonster_start_go =
{
	self.origin_z = self.origin_z + 1; // raise off floor a bit
	droptofloor ();

	if (!walkmove (0, 0))
	{
		dprint ("walkmonster in wall!\n");
		dprint (self.classname);
		dprint (" at ");
		dprint (vtos (self.origin));
		dprint ("\n");
	}

	self.takedamage = DAMAGE_AIM;

	self.ideal_yaw = self.angles_y;
	if (!self.yaw_speed)
		self.yaw_speed = 20;
	self.view_ofs = '0 0 25';
	self.use = monster_use;

	self.flags = self.flags | FL_MONSTER;

	monster_start_moving ();
	monster_start_spread ();
};

void() walkmonster_start =
{
	// delay drop to floor to make sure all doors have been spawned
	self.think = walkmonster_start_go;
	total_monsters = total_monsters + 1;
	monster_start_spread ();
};

void() flymonster_start_go =
{
	self.takedamage = DAMAGE_AIM;

	self.ideal_yaw = self.angles_y;
	if (!self.yaw_speed)
		self.yaw_speed = 10;
	self.view_ofs = '0 0 25';
	self.use = monster_use;

	self.flags = self.flags | FL_MONSTER | FL_FLY;

	if (!walkmove (0, 0))
	{
		dprint ("flymonster in wall!\n");
		dprint (self.classname);
		dprint (" at ");
		dprint (vtos (self.origin));
		dprint ("\n");
	}

	monster_start_moving ();
};

void() flymonster_start =
{
	self.think = flymonster_start_go;
	total_monsters = total_monsters + 1;
	monster_start_spread ();
};

void() swimmonster_start_go =
{
	self.takedamage = DAMAGE_AIM;

	self.ideal_yaw = self.angles_y;
	if (!self.yaw_speed)
		self.yaw_speed = 10;
	self.view_ofs = '0 0 10';
	self.use = monster_use;

	self.flags = self.flags | FL_MONSTER | FL_SWIM;

	monster_start_moving ();
	monster_start_spread ();
};

void() swimmonster_start =
{
	self.think = swimmonster_start_go;
	total_monsters = total_monsters + 1;
	monster_start_spread ();
};
