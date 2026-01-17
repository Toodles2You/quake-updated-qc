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

float USE_PARTICLES = 1;

void(float type) BecomeExplosion;

void() exploder_fire =
{
	local entity temp;

	temp = self;
	SUB_UseTargets ();
	self = temp;
	other = self;
	if (self.dmg < 120)
	{
		sound (self, CHAN_AUTO, "misc/shortexp.wav", self.volume, self.speed);
	}
	else
	{
		sound (self, CHAN_AUTO, "misc/longexpl.wav", self.volume, self.speed);
	}
	T_RadiusDamage (self, self.owner, self.dmg, other);
	if ((self.spawnflags & USE_PARTICLES))
		BecomeExplosion (TE_EXPLOSION);
	else
		BecomeExplosion (0);
};

void() exploder_use =
{
	if (self.delay)
	{
		self.nextthink = time + self.delay;
		self.delay = 0;
		self.think = exploder_fire;
	}
	else
	{
		exploder_fire ();
	}
};

void() func_exploder =
{
	precache_sound ("misc/shortexp.wav");
	precache_sound ("misc/longexpl.wav");
	self.classname = "exploder";
	self.use = exploder_use;
	if (self.dmg == 0)
	{
		self.dmg = 120;
	}
	if (self.dmg < 0)
	{
		self.dmg = 0;
	}
	if (self.speed == 0)
	{
		self.speed = 1;
	}
	if (self.volume == 0)
	{
		self.volume = 1.0;
	}
};

void() multi_exploder_fire =
{
	local entity temp;
	local entity expl;

	self.nextthink = time + self.wait;
	if (self.state == 0)
	{
		self.state = 1;
		self.duration = time + self.duration;
		temp = self;
		SUB_UseTargets ();
		self = temp;
		other = self;
	}
	if (time > self.duration)
	{
		remove (self);
		return;
	}
	expl = spawn ();
	expl.owner = self.owner;
	expl.dmg = self.dmg;
	expl.origin_x =
		self.absmin_x + (random () * (self.absmax_x - self.absmin_x));
	expl.origin_y =
		self.absmin_y + (random () * (self.absmax_y - self.absmin_y));
	expl.origin_z =
		self.absmin_z + (random () * (self.absmax_z - self.absmin_z));
	sound (expl, CHAN_VOICE, "misc/shortexp.wav", self.volume, self.speed);
	T_RadiusDamage (expl, self.owner, self.dmg, other);
	temp = self;
	self = expl;
	if ((self.spawnflags & USE_PARTICLES))
		BecomeExplosion (TE_EXPLOSION);
	else
		BecomeExplosion (0);
	self = temp;
};

void(vector loc, float rad, float damage, float dur, float pause, float vol) multi_explosion =
{
	local entity temp;

	temp = self;
	self = spawn ();
	self.origin = loc;
	self.dmg = damage;
	self.duration = dur;
	self.wait = pause;
	self.owner = world;
	self.absmin = self.origin - (rad * '1 1 1');
	self.absmax = self.origin + (rad * '1 1 1');
	self.think = multi_exploder_fire;
	self.volume = vol;
	multi_exploder_fire ();
	self = temp;
};

void() multi_exploder_use =
{
	if (self.delay)
	{
		self.nextthink = time + self.delay;
		self.delay = 0;
		self.think = multi_exploder_fire;
	}
	else
	{
		self.think = multi_exploder_fire;
		multi_exploder_fire ();
	}
};

void() func_multi_exploder =
{
	precache_sound ("misc/shortexp.wav");
	precache_sound ("misc/longexpl.wav");
	self.classname = "exploder";
	self.use = multi_exploder_use;
	setmodel (self, self.model);
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
	if (self.dmg == 0)
	{
		self.dmg = 120;
	}
	if (self.dmg < 0)
	{
		self.dmg = 0;
	}
	if (self.duration == 0)
		self.duration = 1.0;
	if (self.speed == 0)
		self.speed = 1.0;
	if (self.volume == 0)
		self.volume = 0.5;
	if (self.wait == 0)
		self.wait = 0.25;
	self.state = 0;
};
