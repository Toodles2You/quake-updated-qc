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

void() trigger_reactivate =
{
	self.solid = SOLID_TRIGGER;
};

float SPAWNFLAG_NOMESSAGE = 1;
float SPAWNFLAG_NOTOUCH = 1;

// the wait time has passed, so set back up for another activation
void() multi_wait =
{
	if (self.max_health)
	{
		self.health = self.max_health;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
	}
};

// the trigger was just touched/killed/used
void() multi_trigger =
{
	if (self.nextthink > time)
		return;

	if (self.classname == "trigger_secret")
	{
		if (other.classname != "player")
			return;
		found_secrets = found_secrets + 1;
		WriteByte (MSG_ALL, SVC_FOUNDSECRET);
	}

	if (self.noise != "")
		sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);

	// don't trigger again until reset
	self.takedamage = DAMAGE_NO;

	SUB_UseTargets ();

	if (self.wait > 0)
	{
		self.think = multi_wait;
		self.nextthink = time + self.wait;
		if (self.cnt <= 0)
			return;
		self.cnt = self.cnt - 1;
		if (self.cnt > 0)
			return;
	}

	// we can't just remove (self) here, because this is a touch function
	// called wheil C code is looping through area links...
	self.touch = SUB_Null;
	self.nextthink = time + 0.1;
	self.think = SUB_Remove;
};

void() multi_killed =
{
	multi_trigger ();
};

void() multi_use =
{
	multi_trigger ();
};

void() multi_touch =
{
	if (other.classname != "player")
		return;

	// if the trigger has an angles field, check player's facing direction
	if (self.movedir != '0 0 0')
	{
		makevectors (other.angles);
		if (v_forward * self.movedir < 0)
			return;
	}

	multi_trigger ();
};

void() trigger_multiple =
{
	if (self.sounds == 1)
	{
		precache_sound ("misc/secret.wav");
		self.noise = "misc/secret.wav";
	}
	else if (self.sounds == 2)
	{
		precache_sound ("misc/talk.wav");
		self.noise = "misc/talk.wav";
	}
	else if (self.sounds == 3)
	{
		precache_sound ("misc/trigger1.wav");
		self.noise = "misc/trigger1.wav";
	}

	if (!self.wait)
		self.wait = 0.2;
	self.use = multi_use;

	InitTrigger ();

	if (self.health)
	{
		if ((self.spawnflags & SPAWNFLAG_NOTOUCH))
		{
			enterror ("health and notouch don't make sense");
			return;
		}
		self.max_health = self.health;
		self.th_die = multi_killed;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
		setorigin (self, self.origin); // make sure it links into the world
	}
	else
	{
		if (!(self.spawnflags & SPAWNFLAG_NOTOUCH))
		{
			self.touch = multi_touch;
		}
	}
	if (self.cnt == 0)
		self.cnt = -1;
};

void() trigger_once =
{
	self.wait = -1;
	trigger_multiple ();
};

void() trigger_relay =
{
	self.use = SUB_UseTargets;
};

void() trigger_secret =
{
	total_secrets = total_secrets + 1;
	self.wait = -1;
	if (self.message == "")
		self.message = "You found a secret area!";
	if (!self.sounds)
		self.sounds = 1;

	if (self.sounds == 1)
	{
		precache_sound ("misc/secret.wav");
		self.noise = "misc/secret.wav";
	}
	else if (self.sounds == 2)
	{
		precache_sound ("misc/talk.wav");
		self.noise = "misc/talk.wav";
	}

	trigger_multiple ();
};

void() counter_use =
{
	self.count = self.count - 1;

	if (self.count)
	{
		if (self.count < 0)
			return;

		if (!(self.spawnflags & SPAWNFLAG_NOMESSAGE))
			if (other.classname == "player")
			{
				if (self.count >= 4)
					centerprint (other, "There are more to go...");
				else if (self.count == 3)
					centerprint (other, "Only 3 more to go...");
				else if (self.count == 2)
					centerprint (other, "Only 2 more to go...");
				else
					centerprint (other, "Only 1 more to go...");
			}
		return;
	}

	if (!(self.spawnflags & SPAWNFLAG_NOMESSAGE))
		if (other.classname == "player")
			centerprint (other, "Sequence completed!");

	multi_trigger ();
};

void() trigger_counter =
{
	self.wait = -1;
	if (!self.count)
		self.count = 2;

	self.use = counter_use;
};

float PLAYER_ONLY = 1;
float SILENT = 2;

void() play_teleport =
{
	local float v;
	local string tmpstr;

	v = random () * 5;
	if (v < 1)
		tmpstr = "misc/r_tele1.wav";
	else if (v < 2)
		tmpstr = "misc/r_tele2.wav";
	else if (v < 3)
		tmpstr = "misc/r_tele3.wav";
	else if (v < 4)
		tmpstr = "misc/r_tele4.wav";
	else
		tmpstr = "misc/r_tele5.wav";

	sound (self, CHAN_VOICE, tmpstr, 1, ATTN_NORM);
	remove (self);
};

void(vector org) spawn_tfog =
{
	local entity s;

	s = spawn ();
	s.origin = org;
	s.nextthink = time + 0.2;
	s.think = play_teleport;

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_TELEPORT);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
};

void() tdeath_touch =
{
	entity oldowner;

	if (other == self.owner)
		return;

	if (other.classname == "player")
	{
		if (self.owner.classname != "player")
		{
			// monsters explode
			T_Damage (self.owner, self, self, 50000);
			return;
		}

		if (other.invincible_finished > time)
		{
			// frag anyone who teleports in on top of an invincible player
			if (self.owner.invincible_finished > time)
			{
				self.classname = "teledeath3";

				other.invincible_finished = 0;
				self.owner.invincible_finished = 0;

				T_Damage (other, self, self, 50000);
			}
			else
				self.classname = "teledeath2";

			oldowner = self.owner;
			self.owner = other;

			T_Damage (oldowner, self, self, 50000);

			self.classname = "teledeath";
			self.owner = oldowner;

			return;
		}
	}

	if (other.health)
	{
		T_Damage (other, self, self, 50000);
	}
};

void(vector org, entity death_owner) spawn_tdeath =
{
	local entity death;

	death = spawn ();
	death.classname = "teledeath";
	death.movetype = MOVETYPE_NONE;
	death.solid = SOLID_TRIGGER;
	death.angles = '0 0 0';
	setsize (death, death_owner.mins - '1 1 1', death_owner.maxs + '1 1 1');
	setorigin (death, org);
	death.touch = tdeath_touch;
	death.nextthink = time + 0.2;
	death.think = SUB_Remove;
	death.owner = death_owner;

	force_retouch = 2; // make sure even still objects get hit
};

void() teleport_touch =
{
	local entity t;
	local vector org;

	if (self.targetname != "")
		if (self.nextthink < time)
			return; // not fired yet

	if ((self.spawnflags & PLAYER_ONLY))
		if (other.classname != "player")
			return;

	// only teleport living creatures
	if (other.health <= 0 || other.solid != SOLID_SLIDEBOX)
		return;

	t = find (world, targetname, self.target);
	if (!t)
		return;

	SUB_UseTargets ();

	// put a tfog where the player was
	spawn_tfog (other.origin);

	// spawn a tfog flash in front of the destination
	makevectors (t.mangle);
	org = t.origin + 32 * v_forward;

	spawn_tfog (org);
	spawn_tdeath (t.origin, other);

	// move the player and lock him down for a little while

	setorigin (other, t.origin);
	other.angles = t.mangle;
	if (other.classname == "player")
	{
		other.fixangle = TRUE;
		other.teleport_time = time + 0.7;
		other.velocity = v_forward * 300;
	}
	other.flags = other.flags - (other.flags & FL_ONGROUND);
};

void() info_teleport_destination =
{
	if (self.targetname == "")
	{
		enterror ("no targetname");
		return;
	}
	// this does nothing, just serves as a target spot
	self.mangle = self.angles;
	self.angles = '0 0 0';
	self.model = "";
	self.origin = self.origin + '0 0 27';
};

void() teleport_use =
{
	self.nextthink = time + 0.2;
	force_retouch = 2; // make sure even still objects get hit
	self.think = SUB_Null;
};

void() trigger_teleport =
{
	local vector o;

	InitTrigger ();

	if (!(self.spawnflags & SILENT))
	{
		precache_sound ("ambience/hum1.wav");
		o = (self.mins + self.maxs) * 0.5;
		ambientsound (o, "ambience/hum1.wav", 0.5, ATTN_STATIC);
	}

	if (self.target == "")
	{
		enterror ("no target");
		return;
	}

	self.touch = teleport_touch;
	self.use = teleport_use;
};

void() trigger_skill_touch =
{
	if (other.classname != "player")
		return;

	cvar_set ("skill", self.message);
};

void() trigger_setskill =
{
	InitTrigger ();
	self.touch = trigger_skill_touch;
};

void() trigger_onlyregistered_touch =
{
	if (other.classname != "player")
		return;
	if (self.attack_finished > time)
		return;

	self.attack_finished = time + 2;
	if (cvar ("registered"))
	{
		self.message = "";
		SUB_UseTargets ();
		remove (self);
	}
	else
	{
		if (self.message != "")
		{
			centerprint (other, self.message);
			sound (other, CHAN_BODY, "misc/talk.wav", 1, ATTN_NORM);
		}
	}
};

void() trigger_onlyregistered =
{
	precache_sound ("misc/talk.wav");
	InitTrigger ();
	self.touch = trigger_onlyregistered_touch;
};

void(entity ent, float amount) hurt_setdamage =
{
	ent.dmg = amount;
	if (!amount)
	{
		ent.solid = SOLID_NOT;
	}
	else
	{
		ent.solid = SOLID_TRIGGER;
	}
	ent.nextthink = -1;
};

void() hurt_on =
{
	self.solid = SOLID_TRIGGER;
	self.nextthink = -1;
};

void() hurt_touch =
{
	if (!other.takedamage)
		return;

	if (time != self.dmgtime)
		if (time < self.nextthink)
			return;

	T_Damage (other, self, self, self.dmg);

	self.think = hurt_on;
	self.nextthink = time + 1;
	self.dmgtime = time;

	if (self.cnt <= 0)
		return;
	self.cnt = self.cnt - 1;
	if (self.cnt > 0)
		return;
	self.touch = SUB_Null;
	self.nextthink = time + 0.1;
	self.think = SUB_Remove;
};

void() trigger_hurt =
{
	InitTrigger ();
	self.touch = hurt_touch;
	if (!self.dmg)
		self.dmg = 5;
	if (self.cnt == 0)
		self.cnt = -1;
};

float PUSH_ONCE = 1;

void() trigger_push_touch =
{
	if (other.classname == "grenade")
		other.velocity = self.speed * self.movedir * 10;
	else if (other.health > 0)
	{
		other.velocity = self.speed * self.movedir * 10;
		if (other.classname == "player")
		{
			if (other.fly_sound < time)
			{
				other.fly_sound = time + 1.5;
				sound (other, CHAN_AUTO, "ambience/windfly.wav", 1, ATTN_NORM);
			}
		}
	}
	if ((self.spawnflags & PUSH_ONCE))
		remove (self);
};

void() trigger_push =
{
	InitTrigger ();
	precache_sound ("ambience/windfly.wav");
	self.touch = trigger_push_touch;
	if (!self.speed)
		self.speed = 1000;
};

void() trigger_monsterjump_touch =
{
	if ((other.flags & (FL_MONSTER | FL_FLY | FL_SWIM)) != FL_MONSTER)
		return;

	// set XY even if not on ground, so the jump will clear lips
	other.velocity_x = self.movedir_x * self.speed;
	other.velocity_y = self.movedir_y * self.speed;

	if (!(other.flags & FL_ONGROUND))
		return;

	other.flags = other.flags - FL_ONGROUND;

	other.velocity_z = self.height;
	if (self.cnt > 0)
	{
		self.cnt = self.cnt - 1;
		if (self.cnt == 0)
		{
			self.touch = SUB_Null;
			self.nextthink = time + 0.1;
			self.think = SUB_Remove;
		}
	}
};

void() trigger_monsterjump =
{
	if (!self.speed)
		self.speed = 200;
	if (!self.height)
		self.height = 200;
	if (self.angles == '0 0 0')
		self.angles = '0 360 0';
	if (self.cnt == 0)
		self.cnt = -1;
	InitTrigger ();
	self.touch = trigger_monsterjump_touch;
};
