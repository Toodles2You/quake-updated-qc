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

void() sphere_impact =
{
	if (other.health)
	{
		T_Damage (other, self, self, 1000);
	}

	// don't do radius damage to the other, because all the damage
	// was done in the impact
	T_RadiusDamage (self, self, 300, other, "");

	self.origin = self.origin - 8 * normalize (self.velocity);

	BecomeExplosion (TE_EXPLOSION);
};

void(entity ownerEntity) sphere_remove =
{
	local entity theSphere;

	theSphere = find (world, classname, "Vengeance");
	while (theSphere != world)
	{
		if (theSphere.owner == self)
		{
			bprint (theSphere.owner.netname);
			bprint (" is denied vengeance\n");
			remove (theSphere);
			theSphere = find (world, classname, "Vengeance");
		}
		else
			theSphere = find (theSphere, classname, "Vengeance");
	}
};

void() sphere_attack =
{
	self.solid = SOLID_TRIGGER;
	self.touch = sphere_impact;

	if (!SUB_IsAlive (self.enemy))
	{
		sprint (self.owner, "You are denied vengeance");
		remove (self);
		return;
	}

	ai_track (self.enemy, 650);
	self.nextthink = time + 0.1;
	self.think = sphere_attack;
};

void() sphere_think =
{
	if (self.shieldSoundTime < time)
	{
		sound (self, CHAN_VOICE, "sphere/sphere.wav", 1, ATTN_NORM);
		self.shieldSoundTime = time + 4;
	}

	if (time > self.delay)
	{
		if ((self.owner.items2 & IT2_V_SPHERE))
			self.owner.items2 = self.owner.items2 - IT2_V_SPHERE;
		sprint (self.owner, "Vengeance Sphere lost\n");
		remove (self);
		return;
	}

	if (!SUB_IsAlive (self.owner))
	{
		if ((self.owner.items2 & IT2_V_SPHERE))
			self.owner.items2 = self.owner.items2 - IT2_V_SPHERE;
		if (self.owner.enemy.classname == "player")
		{
			self.enemy = self.owner.enemy;
			sphere_attack ();
			return;
		}
		if (self.owner.enemy.owner.classname == "player")
		{
			self.enemy = self.owner.enemy.owner;
			sphere_attack ();
			return;
		}
		remove (self);
		return;
	}

	ai_orbit (self.owner, 16, '0 0 48');

	self.think = sphere_think;
	self.nextthink = time + 0.1;
};

void() sphere_spawn =
{
	local entity missile;

	missile = spawn ();
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_NOT;
	missile.classname = "Vengeance";
	missile.owner = other;
	missile.weapon = 0;
	missile.delay = time + 30;
	setmodel (missile, "progs/sphere.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin);
	missile.avelocity = '40 40 40';
	missile.think = sphere_think;
	missile.nextthink = time + 0.1;
};

void() item_sphere =
{
	if (!deathmatch)
	{
		remove (self);
		return;
	}

	precache_model ("progs/sphere.mdl");
	precache_sound ("sphere/sphere.wav");

	self.noise = "sphere/sphere.wav";
	self.netname = "Vengeance Sphere";
	self.touch = newitems_touch;

	setmodel (self, "progs/sphere.mdl");
	setsize (self, '-8 -8 -8', '8 8 8');
	self.avelocity = '40 40 40';
	StartItem ();
};
