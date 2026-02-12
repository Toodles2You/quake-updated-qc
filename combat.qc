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

.float healamount, healtype;

void() T_MissileTouch;
void() info_player_start;
void(entity targ, entity attacker) ClientObituary;

void() monster_death_use;

float(entity targ, entity inflictor) CanDamage =
{
	local vector center;

	// bmodels need special checking because their origin is 0,0,0
	if (targ.movetype == MOVETYPE_PUSH)
	{
		center = 0.5 * (targ.absmin + targ.absmax);
		traceline (inflictor.origin, center, TRUE, inflictor);
		if (trace_fraction == 1)
			return TRUE;
		if (trace_ent == targ)
			return TRUE;
		return FALSE;
	}

	traceline (inflictor.origin, targ.origin, TRUE, inflictor);
	if (trace_fraction == 1)
		return TRUE;
	traceline (inflictor.origin, targ.origin + '15 15 0', TRUE, inflictor);
	if (trace_fraction == 1)
		return TRUE;
	traceline (inflictor.origin, targ.origin + '-15 -15 0', TRUE, inflictor);
	if (trace_fraction == 1)
		return TRUE;
	traceline (inflictor.origin, targ.origin + '-15 15 0', TRUE, inflictor);
	if (trace_fraction == 1)
		return TRUE;
	traceline (inflictor.origin, targ.origin + '15 -15 0', TRUE, inflictor);
	if (trace_fraction == 1)
		return TRUE;

	return FALSE;
};

void() Killed =
{
	if (self.health > 0)
		self.health = 0;
	else if (self.health < -99)
		self.health = -99;

	if (self.movetype == MOVETYPE_PUSH || self.movetype == MOVETYPE_NONE)
	{
		// doors, triggers, etc
		self.th_die ();
		return;
	}

	if ((self.flags & FL_MONSTER))
	{
		self.enemy = other;
		self.oldenemy = world;

		killed_monsters = killed_monsters + 1;
		WriteByte (MSG_ALL, SVC_KILLEDMONSTER);
	}

	ClientObituary (self, other);

	self.takedamage = DAMAGE_NO;
	self.touch = SUB_Null;
	self.effects = 0;

	monster_death_use ();
	self.th_die ();
};

/*
==============================================================================
TakeDamage

The damage is coming from inflictor, but get mad at attacker
This should be the only function that ever reduces health.
==============================================================================
*/
void(entity inflictor, float damage) TakeDamage =
{
	local vector dir;
	local float save, take;

	if (!self.takedamage)
		return;

	if (other.super_damage_finished > time)
		if (inflictor.classname != "door")
			damage = damage * 4;

	save = ceil (self.armortype * damage);
	if (save > self.armorvalue)
		save = self.armorvalue;

	take = ceil (damage - save);

	// add to the damage total for clients, which will be sent as a single
	// message at the end of the frame
	if ((self.flags & FL_CLIENT))
	{
		self.dmg_take = self.dmg_take + take;
		self.dmg_save = self.dmg_save + save;
		self.dmg_inflictor = inflictor;
	}

	if (self.movetype == MOVETYPE_WALK)
		if (inflictor)
		{
			dir = self.origin - (inflictor.absmin + inflictor.absmax) * 0.5;
			dir = normalize (dir);
			self.velocity = self.velocity + dir * damage * 8;
		}

	if ((self.flags & FL_GODMODE))
		return;
	if (self.invincible_finished >= time)
	{
		if (self.invincible_sound < time)
		{
			sound (self, CHAN_ITEM, "items/protect3.wav", 1, ATTN_NORM);
			self.invincible_sound = time + 2;
		}
		return;
	}

// team play damage avoidance
	if ((teamplay == 1) && (self.team == other.team) &&
		(other.classname == "player") && (other.team != 0) &&
		inflictor.classname != "door")
		return;

	if ((teamplay == 3) && (self.team == other.team) &&
		(other.classname == "player") && (other.team != 0) &&
		(self != other) && inflictor.classname != "door")
		return;

	self.armorvalue = self.armorvalue - save;
	if (self.armorvalue <= 0)
	{
		self.armorvalue = 0;
		self.armortype = 0;
		self.items = self.items - (self.items & IT_ARMOR);
	}

	self.health = self.health - take;

	if (self.health <= 0)
	{
		Killed ();
		return;
	}

	if ((self.flags & FL_MONSTER))
		if (CanFindTarget (other, FIND_DAMAGE))
			HuntFoundTarget (other);

	if (self.th_pain)
		if (self.th_pain != SUB_NullPain)
		{
			self.th_pain (other, take);
			if (skill == 3)
				self.pain_finished = time + 5;
		}
};

void(entity ent, entity inflictor, entity attacker, float damage) T_Damage =
{
	local entity oldself, oldother;

	oldself = self;
	oldother = other;
	self = ent;
	other = attacker;
	TakeDamage (inflictor, damage);
	self = oldself;
	other = oldother;
};

void(entity inflictor, entity attacker, float damage, entity ignore, string dtype) T_RadiusDamage =
{
	local entity oldself, oldother;
	local float points, radius, attacker_points;
	local vector org;

	oldself = self;
	oldother = other;
	self = nextent (world);
	other = attacker;

	radius = damage + 40;
	attacker_points = 0;

	while (self)
	{
		if (self.solid)
			if (self != ignore)
				if (self.takedamage)
				{
					org = self.origin + (self.mins + self.maxs) * 0.5;
					points = vlen (inflictor.origin - org);
					if (points <= radius)
					{
						points = 0.5 * points;
						if (points < 0)
							points = 0;
						points = damage - points;
						if (points > 0)
							if (CanDamage (self, inflictor))
							{
								if (self.classname == "monster_shambler")
									points = points * 0.5;
								if (self == attacker)
									attacker_points = points;
								else
								{
									self.deathtype = dtype;
									TakeDamage (inflictor, points);
								}
							}
					}
				}
		self = nextent (self);
	}

	if (attacker_points > 0)
	{
		points = attacker_points * 0.5;
		self = attacker;
		self.deathtype = dtype;
		TakeDamage (inflictor, points);
	}

	self = oldself;
	other = oldother;
};

/*
==============================================================================
T_Heal

add health to an entity, limiting health to max_health
mega will ignore max_health limit
==============================================================================
*/
float(entity ent, float heal, float mega) T_Heal =
{
	local float healmax, give;

	if (ent.health <= 0)
		return FALSE;

	if (mega)
		healmax = ent.max_health * 2.5;
	else
		healmax = ent.max_health;
	if (ent.health >= healmax)
		return FALSE;

	give = ceil (heal);
	ent.health = ent.health + give;
	if (ent.health > healmax)
		ent.health = healmax;

	if (mega)
		if (ent.health > ent.max_health)
		{
			// rot down the player's super health
			if (!ent.healamount)
			{
				ent.healtype = time + 5;
				ent.items = ent.items | IT_SUPERHEALTH;
			}
			ent.healamount = ent.healamount + 1;
		}

	return TRUE;
};
