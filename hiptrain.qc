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

void() train_blocked;
void() func_train;
void() hip_train_next;
void() hip_func_train_find;

void() hip_train_use =
{
	if (self.think != hip_func_train_find)
	{
		if (self.velocity != '0 0 0')
			return; // already activated
	}
	hip_train_next ();
};

void() hip_train_wait =
{
	if (self.wait)
	{
		sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
		if (self.wait != -1)
		{
			self.nextthink = self.ltime + self.wait;
			self.wait = 0;
		}
	}
	else
		self.nextthink = self.ltime + 0.1;

	self.think = hip_train_next;
};

void() hip_train_next =
{
	local entity targ;
	local float current;
	local string temp;

	// Get the speed of the current path_corner.
	// (we must save this off at each path change since
	// we don't have a pointer to the current path_corner).
	current = self.cnt;

	targ = find (world, targetname, self.target);

	// Save the speed in cnt for later use
	self.cnt = targ.speed;
	self.target = targ.target;
	if (self.target == "")
	{
		enterror ("hip_train_next: no next target");
		return;
	}

	sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);

	self.wait = targ.wait;
	if (targ.wait)
	{
		self.think = hip_train_wait;
	}
	else
	{
		self.think = hip_train_next;
	}

	if (self.goalentity.event != "")
	{
		// Trigger any events that should happen at the corner.
		temp = self.target;
		self.target = self.goalentity.event;
		self.message = self.goalentity.message;
		SUB_UseTargets ();
		self.target = temp;
		self.message = "";
	}

	// Save the current entity
	self.goalentity = targ;

	if (current == -1)
	{
		// Warp to the next path_corner
		setorigin (self, targ.origin - self.mins);
		self.nextthink = self.ltime + 0.01;
	}
	else
	{
		// check if there's a speed change
		if (current > 0)
			self.speed = current;

		// travel to the next path change
		SUB_CalcMove (targ.origin - self.mins, self.speed, self.think);
	}
};

void() hip_func_train_find =
{
	local entity targ;

	targ = find (world, targetname, self.target);

	// Save the current entity
	self.goalentity = targ;

	// Save the speed in cnt for later use
	self.cnt = targ.speed;

	self.target = targ.target;
	setorigin (self, targ.origin - self.mins);
	if (self.targetname == "")
	{ // not triggered, so start immediately
		self.nextthink = self.ltime + 0.1;
		self.think = hip_train_next;
	}
};

void() func_train2 =
{
	if (!self.speed)
		self.speed = 100;
	if (self.target == "")
	{
		enterror ("func_train without a target");
		return;
	}
	if (!self.dmg)
		self.dmg = 2;

	if (self.noise == "")
	{
		if (self.sounds == 0)
		{
			self.noise = ("misc/null.wav");
		}

		if (self.sounds == 1)
		{
			self.noise = ("plats/train2.wav");
		}
	}
	if (self.noise1 == "")
	{
		if (self.sounds == 0)
		{
			self.noise1 = ("misc/null.wav");
		}
		if (self.sounds == 1)
		{
			self.noise1 = ("plats/train1.wav");
		}
	}

	precache_sound (self.noise);
	precache_sound (self.noise1);

	self.cnt = 1;
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	self.blocked = train_blocked;
	self.use = hip_train_use;
	self.classname = "train2";

	setmodel (self, self.model);
	setsize (self, self.mins, self.maxs);
	setorigin (self, self.origin);

	// start trains on the second frame, to make sure their targets have had
	// a chance to spawn
	self.nextthink = self.ltime + 0.1;
	self.think = hip_func_train_find;
};
