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

void() MultiGrenadeTouch;

void() MiniGrenadeExplode =
{
	if (self.owner.classname == "player")
		T_RadiusDamage (self, self.owner, 90, world, "multigrenade");
	else
		T_RadiusDamage (self, self.owner, 60, world, "multigrenade");

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION2);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	WriteByte (MSG_BROADCAST, 230);
	WriteByte (MSG_BROADCAST, 5);

	BecomeExplosion (0);
};

void(float offsetAngle) MiniGrenadeLaunch =
{
	local entity missile;
	local float tempRand;

	missile = spawn ();
	missile.owner = self.owner;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;
	missile.classname = "MiniGrenade";

	missile.v_angle = self.v_angle;
	missile.v_angle_y = missile.v_angle_y + offsetAngle;
	makevectors (missile.v_angle);

	missile.velocity = v_forward * 100 + v_up * 400;
	tempRand = (crandom () * 60) - 30;
	missile.velocity = missile.velocity + tempRand * v_forward;
	tempRand = (crandom () * 40) - 20;
	missile.velocity = missile.velocity + tempRand * v_right;
	tempRand = (crandom () * 60) - 30;
	missile.velocity = missile.velocity + tempRand * v_up;

	missile.avelocity = '300 300 300';
	missile.angles = vectoangles (missile.velocity);
	missile.touch = MultiGrenadeTouch;

	setmodel (missile, "progs/mervup.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin);

	missile.nextthink = time + 1 + (crandom () * 0.5);
	missile.think = MiniGrenadeExplode;
};

void() MultiGrenadeExplode =
{
	MiniGrenadeLaunch (0);
	MiniGrenadeLaunch (72);
	MiniGrenadeLaunch (144);
	MiniGrenadeLaunch (216);
	MiniGrenadeLaunch (288);

	remove (self);
};

void() MultiGrenadeTouch =
{
	if (other.takedamage == DAMAGE_AIM)
	{
		if (self.classname == "MiniGrenade")
			MiniGrenadeExplode ();
		else if (self.owner.classname == "player")
			GrenadeExplode ();
		else
			MiniGrenadeExplode ();
		return;
	}
	sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
};

void() W_FireMultiGrenade =
{
	local entity missile;

	self.currentammo = self.ammo_multi_rockets = self.ammo_multi_rockets - 1;
	UpdateAmmoCounts (self);

	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;
	missile.classname = "MultiGrenade";

	makevectors (self.v_angle);
	if (self.v_angle_x)
		missile.velocity = v_forward * 600 + v_up * 200
						 + crandom () * v_right * 10 + crandom () * v_up * 10;
	else
	{
		missile.velocity = aim (self, 10000);
		missile.velocity = missile.velocity * 600;
		missile.velocity_z = 200;
	}

	missile.avelocity = '300 300 300';
	missile.angles = vectoangles (missile.velocity);
	missile.touch = MultiGrenadeTouch;

	missile.nextthink = time + 1;
	missile.think = MultiGrenadeExplode;

	setmodel (missile, "progs/mervup.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin);
};

void() MultiRocketExplode =
{
	local float damg;

	damg = 60 + random () * 15;

	if (other.health)
	{
		if (other.classname == "monster_shambler")
			damg = damg * 0.5;
		if (other.classname == "monster_dragon")
			damg = damg * 0.5;
		other.deathtype = "multirocket";
		T_Damage (other, self, self.owner, damg);
	}

	T_RadiusDamage (self, self.owner, 75, other, "multirocket");

	self.origin = self.origin - 8 * normalize (self.velocity);

	BecomeExplosion (TE_EXPLOSION);
};

void() MultiRocketTouch =
{
	if (pointcontents (self.origin) == CONTENT_SKY)
	{
		remove (self);
		return;
	}

	MultiRocketExplode ();
};

void() HomingMissileThink =
{
	local vector dir;

	if (!SUB_IsAlive (self.enemy))
	{
		remove (self);
		return;
	}

	dir = normalize (self.enemy.origin - self.origin);
	self.velocity = dir * 1000;
	self.nextthink = time + 0.1;
	self.think = HomingMissileThink;
};

void() HomingMissileAcquire =
{
	local vector oldVelocity;
	local vector aimangle;

	if (self.delay < time)
	{
		MultiRocketExplode ();
		return;
	}

	oldVelocity = self.velocity;
	makevectors (self.v_angle);
	self.velocity = aim (self, 1000);
	self.velocity = self.velocity * 1000;

	aimangle = self.origin + self.velocity;
	traceline (self.origin, aimangle, FALSE, self);
	if (trace_fraction < 1)
	{
		if ((trace_ent.flags & FL_MONSTER))
		{
			self.enemy = trace_ent;
			HomingMissileThink ();
			return;
		}
	}

	self.velocity = oldVelocity;
	self.v_angle = vectoangles (self.velocity);
	self.angles = self.v_angle;
	self.think = HomingMissileAcquire;
	self.nextthink = time + 0.2;
};

void(float offset, float frameNum) MultiRocketLaunch =
{
	local entity missile;
	local vector aimangle;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
	missile.classname = "MultiRocket";
	missile.delay = time + 4;
	missile.frame = frameNum;
	missile.touch = MultiRocketTouch;

	if (deathmatch || coop)
		setmodel (missile, "progs/rockup_d.mdl");
	else
		setmodel (missile, "progs/rockup.mdl");

	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin + v_forward * 8 + '0 0 16');

	if (coop || deathmatch)
	{
		aimangle = self.v_angle;
		aimangle_y = aimangle_y + (offset * 0.66);
		makevectors (aimangle);
		missile.velocity = aim (self, 1000);
		missile.velocity = missile.velocity * 1000;
		missile.angles = vectoangles (missile.velocity);

		missile.think = MultiRocketExplode;
		missile.nextthink = time + 4;
	}
	else
	{
		makevectors (self.v_angle);
		missile.velocity = v_forward * 1000 - v_right * offset * 8;
		missile.angles = vectoangles (missile.velocity);
		missile.v_angle = self.v_angle;

		aimangle = missile.origin + missile.velocity;
		traceline (missile.origin, aimangle, FALSE, self);
		if (trace_fraction < 1)
		{
			if (trace_ent.flags & FL_MONSTER)
			{
				missile.enemy = trace_ent;
				missile.think = HomingMissileThink;
				return;
			}
		}

		missile.think = HomingMissileAcquire;
		missile.nextthink = time + 0.1;
	}
};

void() W_FireMultiRocket =
{
	self.currentammo = self.ammo_multi_rockets = self.ammo_multi_rockets - 1;
	UpdateAmmoCounts (self);

	sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	MultiRocketLaunch (-10, 2);
	MultiRocketLaunch (-5, 3);
	MultiRocketLaunch (5, 0);
	MultiRocketLaunch (10, 1);
};

void(vector p1, vector p2, entity from, float damage) PlasmaDamage =
{
	LightningDamage (p1, p2, from, damage);
};

void(entity current, float doDamage) PlasmaDischarge =
{
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
	WriteEntity (MSG_BROADCAST, current);
	WriteCoord (MSG_BROADCAST, current.origin_x);
	WriteCoord (MSG_BROADCAST, current.origin_y);
	WriteCoord (MSG_BROADCAST, current.origin_z);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	sound (self, CHAN_VOICE, "weapons/lhit.wav", 1, ATTN_NORM);
	if (doDamage == 1)
		PlasmaDamage (self.origin, current.origin, self.owner, 50);
};

void() PlasmaGroundOut =
{
	local entity current, start;
	local float monstersHit;
	local vector org;
	local float dist;

	monstersHit = 0;
	current = nextent (world);
	start = current;
	while (monstersHit < 5)
	{
		if ((current.flags & FL_MONSTER) || current.classname == "player")
		{
			if (current != self.owner)
			{
				org = current.origin + (current.mins + current.maxs) * 0.5;
				dist = vlen (self.origin - org);
				if (dist <= 320)
				{
					traceline (self.origin, current.origin, TRUE, world);
					if (trace_fraction == 1)
					{
						monstersHit = monstersHit + 1;
						PlasmaDischarge (current, 1);
					}
				}
			}
		}
		current = nextent (current);
		if (start == current || !current)
			return;
	}
};

void() PlasmaTouch =
{
	local float damg;

	if (pointcontents (self.origin) == CONTENT_SKY)
	{
		remove (self);
		return;
	}

	damg = 80 + random () * 20;
	sound (self, CHAN_WEAPON, "plasma/explode.wav", 1, ATTN_NORM);

	if (other.health)
	{
		if (other.classname == "monster_shambler")
			damg = damg * 0.5;
		other.deathtype = "plasma";
		T_Damage (other, self, self.owner, damg);
	}

	// don't do radius damage to the other, because all the damage
	// was done in the impact
	T_RadiusDamage (self, self.owner, 70, other, "plasma");

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION2);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	WriteByte (MSG_BROADCAST, 244);
	WriteByte (MSG_BROADCAST, 3);

	PlasmaGroundOut ();
	remove (self);
};

void() PlasmaLaunch =
{
	self.velocity = normalize (self.velocity);
	self.velocity = self.velocity * 1250;

	self.nextthink = time + 5;
	self.think = SUB_Remove;
};

void(vector org, vector dir) launch_plasma =
{
	local entity missile;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
	missile.classname = "plasma";

	missile.velocity = dir * 0.01;
	missile.avelocity = '300 300 300';
	missile.angles = vectoangles (missile.velocity);
	missile.touch = PlasmaTouch;

	setmodel (missile, "progs/plasma.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, org);

	sound (missile, CHAN_WEAPON, "plasma/flight.wav", 1, ATTN_NORM);
	if (!deathmatch && !coop)
		missile.effects = EF_BRIGHTLIGHT;

	missile.think = PlasmaLaunch;
	missile.nextthink = time + 0.1;
};

void() W_FirePlasma =
{
	local float cells;
	local vector dir;

	if (self.ammo_plasma < 1)
	{
		W_SetWeapon (W_BestWeapon ());
		return;
	}

	// explode if under water
	if (self.waterlevel > 1)
	{
		cells = self.ammo_plasma;
		self.ammo_plasma = 0;
		W_SetWeapon (W_BestWeapon ());
		T_RadiusDamage (self, self, 35 * cells, world, "discharge");
		return;
	}
	self.currentammo = self.ammo_plasma = self.ammo_plasma - 1;
	UpdateAmmoCounts (self);
	sound (self, CHAN_WEAPON, "plasma/fire.wav", 0.5, ATTN_NORM);
	self.punchangle_x = -2;

	makevectors (self.v_angle);
	dir = aim (self, 1000);
	launch_plasma (self.origin + v_forward * 24 + '0 0 16', dir);
};
