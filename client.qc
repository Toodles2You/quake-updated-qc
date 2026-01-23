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

void() W_WeaponFrame;
void(entity attacker, float damage) player_pain;
void() PlayerStand;
void(vector org) spawn_tfog;
void(vector org, entity death_owner) spawn_tdeath;

float CHANGE_NO_INTERMISSION = 1;

float modelindex_eyes, modelindex_player;

string nextmap;
float intermission_running;
float intermission_exittime;
float restarting;

void() restartlevel =
{
	serverflags = oldserverflags;
	restarting = TRUE;
	changelevel (mapname);
};

void() info_intermission = {};

void() SetChangeParms =
{
	if (restarting)
	{
		setspawnparms (self);
		return;
	}

	if (self.health <= 0)
	{
		SetNewParms ();
		return;
	}

	parm1 = self.items - (self.items & (IT_KEYS | IT_ARTS | IT_SUPERHEALTH));

	if (self.health > 100)
		parm2 = 100;
	else if (self.health < 50)
		parm2 = 50;
	else
		parm2 = self.health;

	parm3 = self.armorvalue;

	if (self.ammo_shells < 25)
		parm4 = 25;
	else
		parm4 = self.ammo_shells;

	parm5 = self.ammo_nails;
	parm6 = self.ammo_rockets;
	parm7 = self.ammo_cells;
	parm8 = self.weapon;
	parm9 = self.armortype * 100;
};

void() SetNewParms =
{
	parm1 = IT_SHOTGUN | IT_AXE;
	parm2 = 100;
	parm3 = 0;
	parm4 = 25;
	parm5 = 0;
	parm6 = 0;
	parm7 = 0;
	parm8 = IT_SHOTGUN;
	parm9 = 0;
};

void() DecodeLevelParms =
{
	if (!deathmatch)
	{
		if (mapname == "start")
			SetNewParms (); // take away all stuff on starting new episode
	}

	self.items = parm1;
	self.health = parm2;
	self.armorvalue = parm3;
	self.ammo_shells = parm4;
	self.ammo_nails = parm5;
	self.ammo_rockets = parm6;
	self.ammo_cells = parm7;
	self.weapon = -1;
	W_SetWeapon (parm8);
	self.armortype = parm9 * 0.01;
};

entity() FindIntermission =
{
	local entity spot;
	local float cyc;

	spot = find (world, classname, "info_intermission");
	if (spot)
	{ // pick a random one
		cyc = random () * 4;
		while (cyc > 1)
		{
			spot = find (spot, classname, "info_intermission");
			if (!spot)
				spot = find (spot, classname, "info_intermission");
			cyc = cyc - 1;
		}
		return spot;
	}

	spot = find (world, classname, "info_player_start");
	if (spot)
		return spot;

	spot = find (world, classname, "testplayerstart");
	if (spot)
		return spot;

	dprint ("FindIntermission: no spot\n");
	return spot;
};

void() SetServerFlags =
{
	if (mapname == "e1m7")
		serverflags = serverflags | SFL_EPISODE_1;
	else if (mapname == "e2m6")
		serverflags = serverflags | SFL_EPISODE_2;
	else if (mapname == "e3m6")
		serverflags = serverflags | SFL_EPISODE_3;
	else if (mapname == "e4m7")
		serverflags = serverflags | SFL_EPISODE_4;
	else if (mapname == "end")
		serverflags = serverflags - (serverflags & SFL_EPISODES);
};

void() GotoNextMap =
{
	restarting = FALSE;
	if (deathmatch)
	{
		SetServerFlags ();
		if (cvar ("samelevel"))
		{
			changelevel (mapname);
			return;
		}
	}
	changelevel (nextmap);
};

void() ExitIntermission =
{
	if (deathmatch)
	{
		GotoNextMap ();
		return;
	}

	intermission_exittime = time + 1;
	intermission_running = intermission_running + 1;

	// run some text if at the end of an episode
	if (intermission_running == 2)
	{
		if (mapname == "e1m7")
		{
			if (!cvar ("registered"))
				SetFinale (FINALE_SHAREWARE, 2);
			else
				SetFinale (FINALE_EPISODE_1, 2);
			return;
		}
		else if (mapname == "e2m6")
		{
			SetFinale (FINALE_EPISODE_2, 2);
			return;
		}
		else if (mapname == "e3m6")
		{
			SetFinale (FINALE_EPISODE_3, 2);
			return;
		}
		else if (mapname == "e4m7")
		{
			SetFinale (FINALE_EPISODE_4, 2);
			return;
		}
	}
	else if (intermission_running == 3)
	{
		if (!cvar ("registered"))
		{
			// shareware episode has been completed, go to sell screen
			WriteByte (MSG_ALL, SVC_SELLSCREEN);
			return;
		}
		else if ((serverflags & SFL_EPISODES) == SFL_EPISODES)
		{
			SetFinale (FINALE_EPISODES, 0);
			return;
		}
	}

	GotoNextMap ();
};

void() IntermissionThink =
{
	if (time < intermission_exittime)
		return;

	if (!self.button0 && !self.button1 && !self.button2)
		return;

	ExitIntermission ();
};

void() execute_changelevel =
{
	local entity pos;

	intermission_running = 1;

	// enforce a wait time before allowing changelevel
	if (deathmatch)
		intermission_exittime = time + 5;
	else
		intermission_exittime = time + 2;

	WriteByte (MSG_ALL, SVC_CDTRACK);
	WriteByte (MSG_ALL, 3);
	WriteByte (MSG_ALL, 3);

	pos = FindIntermission ();

	other = find (world, classname, "player");
	while (other)
	{
		other.view_ofs = '0 0 0';
		other.angles = pos.mangle;
		other.fixangle = TRUE;
		other.think = SUB_Null;
		other.nextthink = 0;
		other.takedamage = DAMAGE_NO;
		other.solid = SOLID_NOT;
		other.movetype = MOVETYPE_NONE;
		other.modelindex = 0;
		setorigin (other, pos.origin);
		other = find (other, classname, "player");
	}

	WriteByte (MSG_ALL, SVC_INTERMISSION);
};

void() changelevel_touch =
{
	local float noexit;

	if (other.classname != "player")
		return;

	if (deathmatch)
	{
		noexit = cvar ("noexit");

		if ((noexit == 1) || ((noexit == 2) && (mapname != "start")))
		{
			T_Damage (other, self, self, 50000);
			return;
		}
	}

	if (coop || deathmatch)
	{
		bprint (other.netname);
		bprint (" exited the level\n");
	}

	nextmap = self.map;

	SUB_UseTargets ();

	if ((self.spawnflags & CHANGE_NO_INTERMISSION) && !deathmatch)
	{
		GotoNextMap ();
		return;
	}

	self.touch = SUB_Null;

	// we can't move people right now, because touch functions are called in the
	// middle of C movement code, so set a think time to do it
	self.think = execute_changelevel;
	self.nextthink = time + 0.1;
};

void() trigger_changelevel =
{
	if (self.map == "")
	{
		enterror ("no map");
		return;
	}

	InitTrigger ();
	self.touch = changelevel_touch;
};

void() set_suicide_frame;

void() respawn =
{
	if (coop)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQue (self);
		// get the spawn parms as they were at level start
		setspawnparms (self);
		PutClientInServer ();
	}
	else if (deathmatch)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQue (self);
		SetNewParms ();
		PutClientInServer ();
	}
	else
	{
		restartlevel ();
	}
};

void() ClientKill =
{
	local entity oldother;

	if (intermission_running)
		return;
	if (!self.view_ofs_z)
		return;

	oldother = other;
	other = self;
	self.deathtype = "suicide";
	Killed ();
	self.deathtype = "";
	other = oldother;

	set_suicide_frame ();

	if (deathmatch)
		respawn ();
};

entity() SelectSpawnPoint =
{
	local entity spot;
	local entity thing;
	local float pcount;

	spot = find (world, classname, "testplayerstart");
	if (spot)
		return spot;

	if (coop)
	{
		lastspawn = find (lastspawn, classname, "info_player_coop");
		if (!lastspawn)
			lastspawn = find (lastspawn, classname, "info_player_start");
		if (lastspawn)
			return lastspawn;
	}
	else if (deathmatch)
	{
		spot = lastspawn;
		while (1)
		{
			spot = find (spot, classname, "info_player_deathmatch");
			if (spot)
			{
				if (spot == lastspawn)
					return lastspawn;
				pcount = 0;
				thing = findradius (spot.origin, 32);
				while (thing)
				{
					if (thing.classname == "player")
						pcount = pcount + 1;
					thing = thing.chain;
				}
				if (pcount == 0)
				{
					lastspawn = spot;
					return spot;
				}
			}
		}
	}

	if ((serverflags & SFL_EPISODES))
	{
		// return with a rune to start
		spot = find (world, classname, "info_player_start2");
		if (spot)
			return spot;
	}

	spot = find (world, classname, "info_player_start");
	if (!spot)
		dprint ("PutClientInServer: no info_player_start on level\n");

	return spot;
};

void() PlayerDie;

void() PutClientInServer =
{
	local entity spot;

	spot = SelectSpawnPoint ();

	self.classname = "player";
	self.health = 100;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	self.show_hostile = 0;
	self.max_health = 100;
	self.flags = FL_CLIENT;
	self.air_finished = time + 12;
	self.dmg = 2; // initial water damage
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.effects = 0;
	self.invincible_time = 0;

	DecodeLevelParms ();

	self.attack_finished = time;
	self.th_pain = player_pain;
	self.th_die = PlayerDie;

	self.deadflag = DEAD_NO;

	self.healamount = 0;
	self.healtype = 0;

	self.origin = spot.origin + '0 0 1';
	self.oldorigin = self.origin;
	self.angles = spot.angles;
	self.fixangle = TRUE;

	// oh, this is a hack!
	setmodel (self, "progs/eyes.mdl");
	modelindex_eyes = self.modelindex;

	setmodel (self, "progs/player.mdl");
	modelindex_player = self.modelindex;

	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);

	self.view_ofs = '0 0 22';

	self.velocity = '0 0 0';
	self.jump_flag = 0;

	PlayerStand ();

	if (deathmatch || coop)
	{
		makevectors (self.angles);
		spawn_tfog (self.origin + v_forward * 20);
	}

	spawn_tdeath (self.origin, self);
};

void() info_player_start = {};

void() info_player_start2 = {};

void() testplayerstart = {};

void() info_player_deathmatch = {};

void() info_player_coop = {};

// for deathmatch; only called if a time or frag limit has expired
void() NextLevel =
{
	local entity o;

	if (mapname == "start")
	{
		o = spawn ();

		if (!cvar ("registered") || !(serverflags & SFL_EPISODE_1))
			o.map = "e1m1";
		else if (!(serverflags & SFL_EPISODE_2))
			o.map = "e2m1";
		else if (!(serverflags & SFL_EPISODE_3))
			o.map = "e3m1";
		else if (!(serverflags & SFL_EPISODE_4))
			o.map = "e4m1";
		else if ((serverflags & SFL_EPISODES) == SFL_EPISODES)
			o.map = "end";
	}
	else
	{
		o = find (world, classname, "trigger_changelevel");

		if (!o)
		{
			o = spawn ();
			o.map = "start";
		}
	}

	nextmap = o.map;
	gameover = TRUE;

	if (o.nextthink < time)
	{
		o.think = execute_changelevel;
		o.nextthink = time + 0.1;
	}
};

void() CheckRules =
{
	local float timelimit, fraglimit;

	if (!deathmatch)
		return;
	if (gameover)
		return;

	timelimit = cvar ("timelimit") * 60;
	fraglimit = cvar ("fraglimit");

	if (timelimit && time >= timelimit)
	{
		NextLevel ();
		return;
	}

	if (fraglimit && self.frags >= fraglimit)
	{
		NextLevel ();
		return;
	}
};

void() PlayerDeathThink =
{
	local float forward;

	if ((self.flags & FL_ONGROUND))
	{
		forward = vlen (self.velocity);
		forward = forward - 1200 * frametime;
		if (forward <= 0)
			self.velocity = '0 0 0';
		else
			self.velocity = forward * normalize (self.velocity);
	}

	// wait for all buttons released
	if (self.deadflag != DEAD_RESPAWNABLE)
	{
		if (self.pain_finished > time)
			return;
		if (self.button2 || self.button1 || self.button0)
			return;
		self.deadflag = DEAD_RESPAWNABLE;
		return;
	}

	if (!self.button2 && !self.button1 && !self.button0)
		return;

	self.button0 = 0;
	self.button1 = 0;
	self.button2 = 0;
	respawn ();
};

void() PlayerJump =
{
	if ((self.flags & FL_WATERJUMP))
		return;

	if (self.waterlevel >= 2)
	{
		if (self.watertype == CONTENT_WATER)
			self.velocity_z = 100;
		else if (self.watertype == CONTENT_SLIME)
			self.velocity_z = 80;
		else
			self.velocity_z = 50;

		if (self.swim_flag < time)
		{
			self.swim_flag = time + 1;
			if (random () < 0.5)
				sound (self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
			else
				sound (self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
		}

		return;
	}

	if (!(self.flags & FL_ONGROUND))
		return;
	if (!(self.flags & FL_JUMPRELEASED))
		return;

	self.flags = self.flags - (FL_ONGROUND | FL_JUMPRELEASED);

	self.button2 = 0;
	sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
	self.velocity_z = self.velocity_z + 270;
};

.float dmgtime;

void() CheckWaterJump =
{
	local vector start, end;

	// check for a jump-out-of-water
	start = self.origin;
	start_z = start_z + 8;
	v_forward_z = 0;
	normalize (v_forward);
	end = start + v_forward * 24;
	traceline (start, end, TRUE, self);
	if (trace_fraction == 1)
		return;

	// solid at waist

	start_z = start_z + self.maxs_z - 8;
	end = start + v_forward * 24;
	self.movedir = trace_plane_normal * -50;
	traceline (start, end, TRUE, self);
	if (trace_fraction != 1)
		return;

	// open at eye level

	self.flags = self.flags | FL_WATERJUMP;
	self.velocity_z = 225;
	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
	self.teleport_time = time + 2; // safety net
};

void() WaterMove =
{
	local float waterfriction;

	if (self.movetype == MOVETYPE_NOCLIP)
		self.waterlevel = 0;

	if (self.waterlevel != 3)
	{
		if (self.air_finished < time)
			sound (self, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM);
		else if (self.air_finished < time + 9)
			sound (self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM);
		self.air_finished = time + 12;
		self.dmg = 2;
	}
	else if (self.air_finished < time)
	{
		if (self.pain_finished < time)
		{
			self.dmg = self.dmg + 2;
			if (self.dmg > 15)
				self.dmg = 10;
			T_Damage (self, world, world, self.dmg);
			self.pain_finished = time + 1;
		}
	}

	if (!self.waterlevel)
	{
		if ((self.flags & FL_INWATER))
		{
			sound (self, CHAN_BODY, "misc/outwater.wav", 1, ATTN_NORM);
			self.flags = self.flags - FL_INWATER;
		}
		return;
	}

	if (self.watertype == CONTENT_LAVA)
	{
		if (self.dmgtime < time)
		{
			if (self.radsuit_finished > time)
				self.dmgtime = time + 1;
			else
				self.dmgtime = time + 0.2;

			T_Damage (self, world, world, 10 * self.waterlevel);
		}
	}
	else if (self.watertype == CONTENT_SLIME)
	{
		if (self.dmgtime < time && self.radsuit_finished < time)
		{
			self.dmgtime = time + 1;
			T_Damage (self, world, world, 4 * self.waterlevel);
		}
	}

	if (!(self.flags & FL_INWATER))
	{
		if (self.watertype == CONTENT_LAVA)
			sound (self, CHAN_BODY, "player/inlava.wav", 1, ATTN_NORM);
		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_BODY, "player/inh2o.wav", 1, ATTN_NORM);
		if (self.watertype == CONTENT_SLIME)
			sound (self, CHAN_BODY, "player/slimbrn2.wav", 1, ATTN_NORM);

		self.flags = self.flags | FL_INWATER;
		self.dmgtime = 0;
	}

	if (self.waterlevel == 2)
		CheckWaterJump ();

	if (!(self.flags & FL_WATERJUMP))
	{
		waterfriction = 0.8 * self.waterlevel * frametime;
		self.velocity = self.velocity - waterfriction * self.velocity;
	}
};

void() PlayerHealthThink =
{
	if (!self.healamount)
		return;
	if (self.healtype > time)
		return;

	if (self.health > self.max_health)
	{
		self.health = self.health - 1;
		self.healtype = time + 1 / self.healamount;

		if (self.health > self.max_health)
			return;
	}

	self.healamount = 0;
	self.healtype = 0;
	self.items = self.items - (self.items & IT_SUPERHEALTH);

	RespawnMegaHealth ();
};

/*
==============================================================================
PlayerPreThink

Called every frame before physics are run
==============================================================================
*/
void() PlayerPreThink =
{
	if (intermission_running)
	{
		IntermissionThink ();
		return;
	}
	if (!self.view_ofs_z)
		return;

	CheckRules ();

	makevectors (self.v_angle);

	if (self.health <= 0)
	{
		if (self.deadflag >= DEAD_DEAD)
			PlayerDeathThink ();
		return;
	}

	PlayerHealthThink ();

	WaterMove ();

	if (self.button2)
		PlayerJump ();
	else
		self.flags = self.flags | FL_JUMPRELEASED;
};

void() CheckLanding =
{
	// check to see if player landed and play landing sound
	if (!(self.flags & FL_ONGROUND))
	{
		self.jump_flag = self.velocity_z;
		return;
	}

	if (self.jump_flag < -300)
	{
		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM);
		else if (self.jump_flag < -650)
		{
			self.deathtype = "falling";
			T_Damage (self, world, world, 5);
			self.deathtype = "";

			sound (self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM);
		}
		else
			sound (self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM);
	}
	self.jump_flag = 0;
};

void() CheckPowerups =
{
	// sound and screen flash when items start to run out

	// invisibility
	if (self.invisible_finished)
	{
		if (self.invisible_sound < time)
		{
			sound (self, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE);
			self.invisible_sound = time + ((random () * 3) + 1);
		}

		if (self.invisible_finished < time + 3)
		{
			if (self.invisible_time == 1)
			{
				sprint (self, "Ring of Shadows magic is fading\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/inv2.wav", 1, ATTN_NORM);
				self.invisible_time = time + 1;
			}

			if (self.invisible_time < time)
			{
				self.invisible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.invisible_finished < time)
		{
			self.items = self.items - (self.items & IT_INVISIBILITY);
			self.invisible_finished = 0;
			self.invisible_time = 0;
		}

		self.frame = 0;
		self.modelindex = modelindex_eyes;
	}
	else
		self.modelindex = modelindex_player;

	// invincibility
	if (self.invincible_finished)
	{
		if (self.invincible_finished < time + 3)
		{
			if (self.invincible_time == 1)
			{
				sprint (self, "Protection is almost burned out\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NORM);
				self.invincible_time = time + 1;
			}

			if (self.invincible_time < time)
			{
				self.invincible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.invincible_finished < time)
		{
			self.items = self.items - (self.items & IT_INVULNERABILITY);
			self.invincible_time = 0;
			self.invincible_finished = 0;
		}
		if (self.invincible_finished > time)
			self.effects = self.effects | EF_DIMLIGHT;
		else
			self.effects = self.effects - (self.effects & EF_DIMLIGHT);
	}

	// super damage
	if (self.super_damage_finished)
	{
		if (self.super_damage_finished < time + 3)
		{
			if (self.super_time == 1)
			{
				sprint (self, "Quad Damage is wearing off\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/damage2.wav", 1, ATTN_NORM);
				self.super_time = time + 1;
			}

			if (self.super_time < time)
			{
				self.super_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.super_damage_finished < time)
		{
			self.items = self.items - (self.items & IT_QUAD);
			self.super_damage_finished = 0;
			self.super_time = 0;
		}
		if (self.super_damage_finished > time)
			self.effects = self.effects | EF_DIMLIGHT;
		else
			self.effects = self.effects - (self.effects & EF_DIMLIGHT);
	}

	// suit
	if (self.radsuit_finished)
	{
		self.air_finished = time + 12;

		if (self.radsuit_finished < time + 3)
		{
			if (self.rad_time == 1)
			{
				sprint (self, "Air supply in Biosuit expiring\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
				self.rad_time = time + 1;
			}

			if (self.rad_time < time)
			{
				self.rad_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.radsuit_finished < time)
		{
			self.items = self.items - (self.items & IT_SUIT);
			self.rad_time = 0;
			self.radsuit_finished = 0;
		}
	}
};

/*
==============================================================================
PlayerPostThink

Called every frame after physics are run
==============================================================================
*/
void() PlayerPostThink =
{
	if (intermission_running)
		return;
	if (!self.view_ofs_z)
		return;
	if (self.health <= 0)
		return;

	W_WeaponFrame ();

	if (self.health <= 0)
		return;

	CheckLanding ();

	if (self.health <= 0)
		return;

	CheckPowerups ();
};

void() ClientConnect =
{
	bprint (self.netname);
	bprint (" entered the game\n");

	// a client connecting during an intermission can cause problems
	if (intermission_running)
		GotoNextMap ();
};

void() ClientDisconnect =
{
	if (!intermission_running)
	{
		bprint (self.netname);
		bprint (" left the game");
		if (deathmatch)
		{
			bprint (" with ");
			bprint (ftos (self.frags));
			bprint (" frags");
		}
		bprint ("\n");
		sound (self, CHAN_BODY, "player/tornoff2.wav", 1, ATTN_NONE);

		if (self.health > 0)
		{
			if (coop || deathmatch)
				DropBackpack ();

			RespawnMegaHealth ();

			set_suicide_frame ();
		}

		CopyToBodyQue (self);
	}

	self.classname = "";
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.takedamage = DAMAGE_NO;
	self.model = "";
	self.modelindex = 0;
	self.flags = self.flags - (self.flags & FL_CLIENT);
};

void(entity targ, entity attacker) ClientObituary =
{
	local float rnum;
	local string deathstring, deathstring2;
	rnum = random ();
	deathstring = "";
	deathstring2 = "";

	if (targ.classname == "player")
	{
		if (attacker.classname == "teledeath")
		{
			bprint (targ.netname);
			bprint (" was telefragged by ");
			bprint (attacker.owner.netname);
			bprint ("\n");

			attacker.owner.frags = attacker.owner.frags + 1;
			return;
		}

		if (attacker.classname == "teledeath2")
		{
			bprint ("Satan's power deflects ");
			bprint (targ.netname);
			bprint ("'s telefrag\n");

			targ.frags = targ.frags - 1;
			return;
		}

		if (attacker.classname == "player")
		{
			if (targ == attacker)
			{
				attacker.frags = attacker.frags - 1;
				bprint (targ.netname);

				if (targ.deathtype == "suicide")
				{
					targ.frags = targ.frags - 1;
					bprint (" suicides\n");
				}
				else if (targ.weapon == IT_LIGHTNING && targ.waterlevel > 1)
					bprint (" discharges into the water\n");
				else if (targ.weapon == IT_GRENADE_LAUNCHER)
					bprint (" tries to put the pin back in\n");
				else if (rnum > 0.4)
					bprint (" becomes bored with life\n");
				else
					bprint (" checks if his weapon is loaded\n");
				return;
			}
			else if ((teamplay == 2) && (targ.team > 0) &&
					 (targ.team == attacker.team))
			{
				if (rnum < 0.25)
					deathstring = " mows down a teammate\n";
				else if (rnum < 0.50)
					deathstring = " checks his glasses\n";
				else if (rnum < 0.75)
					deathstring = " gets a frag for the other team\n";
				else
					deathstring = " loses another friend\n";
				bprint (attacker.netname);
				bprint (deathstring);
				attacker.frags = attacker.frags - 1;
				return;
			}
			else
			{
				attacker.frags = attacker.frags + 1;

				rnum = attacker.weapon;
				if (rnum == IT_AXE)
				{
					deathstring = " was ax-murdered by ";
					deathstring2 = "\n";
				}
				else if (rnum == IT_SHOTGUN)
				{
					deathstring = " chewed on ";
					deathstring2 = "'s boomstick\n";
				}
				else if (rnum == IT_SUPER_SHOTGUN)
				{
					deathstring = " ate 2 loads of ";
					deathstring2 = "'s buckshot\n";
				}
				else if (rnum == IT_NAILGUN)
				{
					deathstring = " was nailed by ";
					deathstring2 = "\n";
				}
				else if (rnum == IT_SUPER_NAILGUN)
				{
					deathstring = " was punctured by ";
					deathstring2 = "\n";
				}
				else if (rnum == IT_GRENADE_LAUNCHER)
				{
					deathstring = " eats ";
					deathstring2 = "'s pineapple\n";
					if (targ.health < -40)
					{
						deathstring = " was gibbed by ";
						deathstring2 = "'s grenade\n";
					}
				}
				else if (rnum == IT_ROCKET_LAUNCHER)
				{
					deathstring = " rides ";
					deathstring2 = "'s rocket\n";
					if (targ.health < -40)
					{
						deathstring = " was gibbed by ";
						deathstring2 = "'s rocket\n";
					}
				}
				else if (rnum == IT_LIGHTNING)
				{
					deathstring = " accepts ";
					if (attacker.waterlevel > 1)
						deathstring2 = "'s discharge\n";
					else
						deathstring2 = "'s shaft\n";
				}
				bprint (targ.netname);
				bprint (deathstring);
				bprint (attacker.netname);
				bprint (deathstring2);
			}
			return;
		}
		else
		{
			targ.frags = targ.frags - 1;
			bprint (targ.netname);

			if ((attacker.flags & FL_MONSTER))
			{
				if (attacker.classname == "monster_army")
					bprint (" was shot by a Grunt\n");
				else if (attacker.classname == "monster_demon1")
					bprint (" was eviscerated by a Fiend\n");
				else if (attacker.classname == "monster_dog")
					bprint (" was mauled by a Rottweiler\n");
				else if (attacker.classname == "monster_enforcer")
					bprint (" was blasted by an Enforcer\n");
				else if (attacker.classname == "monster_fish")
					bprint (" was fed to the Rotfish\n");
				else if (attacker.classname == "monster_hell_knight")
					bprint (" was slain by a Death Knight\n");
				else if (attacker.classname == "monster_knight")
					bprint (" was slashed by a Knight\n");
				else if (attacker.classname == "monster_ogre")
					bprint (" was destroyed by an Ogre\n");
				else if (attacker.classname == "monster_oldone")
					bprint (" became one with Shub-Niggurath\n");
				else if (attacker.classname == "monster_shalrath")
					bprint (" was exploded by a Vore\n");
				else if (attacker.classname == "monster_shambler")
					bprint (" was smashed by a Shambler\n");
				else if (attacker.classname == "monster_tarbaby")
					bprint (" was slimed by a Spawn\n");
				else if (attacker.classname == "monster_wizard")
					bprint (" was scragged by a Scrag\n");
				else if (attacker.classname == "monster_zombie")
					bprint (" joins the Zombies\n");

				return;
			}

			// tricks and traps
			if (attacker.classname == "explo_box")
			{
				bprint (" blew up\n");
				return;
			}
			if (attacker.solid == SOLID_BSP)
				if (attacker)
				{
					bprint (" was squished\n");
					return;
				}
			if (attacker.classname == "trap_shooter" ||
				attacker.classname == "trap_spikeshooter")
			{
				bprint (" was spiked\n");
				return;
			}
			if (attacker.classname == "fireball")
			{
				bprint (" ate a lavaball\n");
				return;
			}
			if (attacker.classname == "trigger_changelevel")
			{
				bprint (" tried to leave\n");
				return;
			}

			if (targ.watertype == CONTENT_WATER)
			{
				if (random () < 0.5)
					bprint (" sleeps with the fishes\n");
				else
					bprint (" sucks it down\n");
				return;
			}
			else if (targ.watertype == CONTENT_SLIME)
			{
				if (random () < 0.5)
					bprint (" gulped a load of slime\n");
				else
					bprint (" can't exist on slime alone\n");
				return;
			}
			else if (targ.watertype == CONTENT_LAVA)
			{
				if (targ.health < -15)
				{
					bprint (" burst into flames\n");
					return;
				}
				if (random () < 0.5)
					bprint (" turned into hot slag\n");
				else
					bprint (" visits the Volcano God\n");
				return;
			}

			if (targ.deathtype == "falling")
			{
				bprint (" fell to his death\n");
				return;
			}

			// hell if I know; he's just dead!!!
			bprint (" died\n");
		}
	}
};
