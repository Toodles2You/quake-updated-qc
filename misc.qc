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

void() info_null =
{
	remove (self);
};

void() info_notnull = {};

float START_OFF = 1;

void() light_use =
{
	if (self.spawnflags & START_OFF)
	{
		lightstyle (self.style, "m");
		self.spawnflags = self.spawnflags - START_OFF;
	}
	else
	{
		lightstyle (self.style, "a");
		self.spawnflags = self.spawnflags + START_OFF;
	}
};

void() light =
{
	if (self.targetname == "")
	{
		remove (self);
		return;
	}

	if (self.style >= 32)
	{
		self.use = light_use;
		if (self.spawnflags & START_OFF)
			lightstyle (self.style, "a");
		else
			lightstyle (self.style, "m");
	}
};

void() light_fluoro =
{
	if (self.style >= 32)
	{
		self.use = light_use;
		if (self.spawnflags & START_OFF)
			lightstyle (self.style, "a");
		else
			lightstyle (self.style, "m");
	}

	precache_sound ("ambience/fl_hum1.wav");
	ambientsound (self.origin, "ambience/fl_hum1.wav", 0.5, ATTN_STATIC);
};

void() light_fluorospark =
{
	if (!self.style)
		self.style = 10;

	precache_sound ("ambience/buzz1.wav");
	ambientsound (self.origin, "ambience/buzz1.wav", 0.5, ATTN_STATIC);
};

void() light_globe =
{
	precache_model ("progs/s_light.spr");
	setmodel (self, "progs/s_light.spr");
	makestatic (self);
};

void() FireAmbient =
{
	precache_sound ("ambience/fire1.wav");
	// attenuate fast
	ambientsound (self.origin, "ambience/fire1.wav", 0.5, ATTN_STATIC);
};

void() light_torch_small_walltorch =
{
	precache_model ("progs/flame.mdl");
	setmodel (self, "progs/flame.mdl");
	FireAmbient ();
	makestatic (self);
};

void() light_flame_large_yellow =
{
	precache_model ("progs/flame2.mdl");
	setmodel (self, "progs/flame2.mdl");
	self.frame = 1;
	FireAmbient ();
	makestatic (self);
};

void() light_flame_small_yellow =
{
	precache_model ("progs/flame2.mdl");
	setmodel (self, "progs/flame2.mdl");
	FireAmbient ();
	makestatic (self);
};

void() light_flame_small_white =
{
	precache_model ("progs/flame2.mdl");
	setmodel (self, "progs/flame2.mdl");
	FireAmbient ();
	makestatic (self);
};

void() fire_fly;
void() fire_touch;

void() misc_fireball =
{
	precache_model ("progs/lavaball.mdl");
	self.classname = "fireball";
	self.nextthink = time + (random () * 5);
	self.think = fire_fly;
	if (!self.speed)
		self.speed = 1000;
};

void() fire_fly =
{
	local entity fireball;

	fireball = spawn ();
	fireball.solid = SOLID_TRIGGER;
	fireball.movetype = MOVETYPE_TOSS;
	fireball.velocity = '0 0 1000';
	fireball.velocity_x = (random () * 100) - 50;
	fireball.velocity_y = (random () * 100) - 50;
	fireball.velocity_z = self.speed + (random () * 200);
	fireball.classname = "fireball";
	setmodel (fireball, "progs/lavaball.mdl");
	setsize (fireball, '0 0 0', '0 0 0');
	setorigin (fireball, self.origin);
	fireball.nextthink = time + 5;
	fireball.think = SUB_Remove;
	fireball.touch = fire_touch;

	self.nextthink = time + (random () * 5) + 3;
	self.think = fire_fly;
};

void() fire_touch =
{
	T_Damage (other, self, self, 20);
	remove (self);
};

void() barrel_explode =
{
	self.takedamage = DAMAGE_NO;
	self.classname = "explo_box";
	T_RadiusDamage (self, self, 160, world);
	particle (self.origin, '0 0 0', 75, 255);

	self.origin_z = self.origin_z + 32;
	BecomeExplosion (TE_EXPLOSION);
};

void() misc_explobox =
{
	local float oldz;

	self.solid = SOLID_BBOX;
	self.movetype = MOVETYPE_NONE;
	precache_model ("maps/b_explob.bsp");
	setmodel (self, "maps/b_explob.bsp");
	self.health = 20;
	self.th_die = barrel_explode;
	self.takedamage = DAMAGE_AIM;

	self.origin_z = self.origin_z + 2;
	oldz = self.origin_z;
	droptofloor (0, 0);
	if (oldz - self.origin_z > 250)
	{
		dprint ("item fell out of level at ");
		dprint (vtos (self.origin));
		dprint ("\n");
		remove (self);
	}
};

void() misc_explobox2 =
{
	local float oldz;

	self.solid = SOLID_BBOX;
	self.movetype = MOVETYPE_NONE;
	precache_model2 ("maps/b_exbox2.bsp");
	setmodel (self, "maps/b_exbox2.bsp");
	self.health = 20;
	self.th_die = barrel_explode;
	self.takedamage = DAMAGE_AIM;

	self.origin_z = self.origin_z + 2;
	oldz = self.origin_z;
	droptofloor (0, 0);
	if (oldz - self.origin_z > 250)
	{
		dprint ("item fell out of level at ");
		dprint (vtos (self.origin));
		dprint ("\n");
		remove (self);
	}
};

float SPAWNFLAG_SUPERSPIKE = 1;
float SPAWNFLAG_LASER = 2;

void(vector org, vector vec) LaunchLaser;

void() spikeshooter_use =
{
	if (self.spawnflags & SPAWNFLAG_LASER)
	{
		sound (self, CHAN_VOICE, "enforcer/enfire.wav", 1, ATTN_NORM);
		LaunchLaser (self.origin, self.movedir);
	}
	else
	{
		sound (self, CHAN_VOICE, "weapons/spike2.wav", 1, ATTN_NORM);
		launch_spike (self.origin, self.movedir);
		newmis.velocity = self.movedir * 500;
		if (self.spawnflags & SPAWNFLAG_SUPERSPIKE)
			newmis.touch = superspike_touch;
	}
};

void() shooter_think =
{
	spikeshooter_use ();
	self.nextthink = time + self.wait;
	newmis.velocity = self.movedir * 500;
};

void() trap_spikeshooter =
{
	SetMovedir ();
	self.use = spikeshooter_use;
	if (self.spawnflags & SPAWNFLAG_LASER)
	{
		precache_model2 ("progs/laser.mdl");

		precache_sound2 ("enforcer/enfire.wav");
		precache_sound2 ("enforcer/enfstop.wav");
	}
	else
		precache_sound ("weapons/spike2.wav");
};

void() trap_shooter =
{
	trap_spikeshooter ();

	if (self.wait == 0)
		self.wait = 1;
	self.nextthink = self.nextthink + self.wait + self.ltime;
	self.think = shooter_think;
};

void() make_bubbles;
void() bubble_remove;
void() bubble_bob;

void() air_bubbles =
{
	if (deathmatch)
	{
		remove (self);
		return;
	}
	precache_model ("progs/s_bubble.spr");
	self.nextthink = time + 1;
	self.think = make_bubbles;
};

void() make_bubbles =
{
	local entity bubble;

	bubble = spawn ();
	setmodel (bubble, "progs/s_bubble.spr");
	setorigin (bubble, self.origin);
	bubble.movetype = MOVETYPE_NOCLIP;
	bubble.solid = SOLID_NOT;
	bubble.velocity = '0 0 15';
	bubble.nextthink = time + 0.5;
	bubble.think = bubble_bob;
	bubble.touch = bubble_remove;
	bubble.classname = "bubble";
	bubble.frame = 0;
	bubble.cnt = 0;
	setsize (bubble, '-8 -8 -8', '8 8 8');
	self.nextthink = time + random () + 0.5;
	self.think = make_bubbles;
};

void() bubble_split =
{
	local entity bubble;
	bubble = spawn ();
	setmodel (bubble, "progs/s_bubble.spr");
	setorigin (bubble, self.origin);
	bubble.movetype = MOVETYPE_NOCLIP;
	bubble.solid = SOLID_NOT;
	bubble.velocity = self.velocity;
	bubble.nextthink = time + 0.5;
	bubble.think = bubble_bob;
	bubble.touch = bubble_remove;
	bubble.classname = "bubble";
	bubble.frame = 1;
	bubble.cnt = 10;
	setsize (bubble, '-8 -8 -8', '8 8 8');
	self.frame = 1;
	self.cnt = 10;
	if (self.waterlevel != 3)
		remove (self);
};

void() bubble_remove =
{
	if (other.classname == self.classname)
	{
		return;
	}
	remove (self);
};

void() bubble_bob =
{
	local float rnd1, rnd2, rnd3;

	self.cnt = self.cnt + 1;
	if (self.cnt == 4)
		bubble_split ();
	if (self.cnt == 20)
		remove (self);

	rnd1 = self.velocity_x + (-10 + (random () * 20));
	rnd2 = self.velocity_y + (-10 + (random () * 20));
	rnd3 = self.velocity_z + 10 + random () * 10;

	if (rnd1 > 10)
		rnd1 = 5;
	if (rnd1 < -10)
		rnd1 = -5;

	if (rnd2 > 10)
		rnd2 = 5;
	if (rnd2 < -10)
		rnd2 = -5;

	if (rnd3 < 10)
		rnd3 = 15;
	if (rnd3 > 30)
		rnd3 = 25;

	self.velocity_x = rnd1;
	self.velocity_y = rnd2;
	self.velocity_z = rnd3;

	self.nextthink = time + 0.5;
	self.think = bubble_bob;
};

void() viewthing =
{
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	precache_model ("progs/player.mdl");
	setmodel (self, "progs/player.mdl");
};

void() func_wall_use =
{ // change to alternate textures
	self.frame = 1 - self.frame;
};

void() func_wall =
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;
	self.solid = SOLID_BSP;
	self.use = func_wall_use;
	setmodel (self, self.model);
};

void() func_illusionary =
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	setmodel (self, self.model);
	makestatic (self);
};

void() func_episodegate =
{
	if (!(serverflags & self.spawnflags))
		return;
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;
	self.solid = SOLID_BSP;
	self.use = func_wall_use;
	setmodel (self, self.model);
};

void() func_bossgate =
{
	if ((serverflags & 15) == 15)
		return;
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;
	self.solid = SOLID_BSP;
	self.use = func_wall_use;
	setmodel (self, self.model);
};

void() ambient_suck_wind =
{
	precache_sound ("ambience/suck1.wav");
	ambientsound (self.origin, "ambience/suck1.wav", 1, ATTN_STATIC);
};

void() ambient_drone =
{
	precache_sound ("ambience/drone6.wav");
	ambientsound (self.origin, "ambience/drone6.wav", 0.5, ATTN_STATIC);
};

void() ambient_flouro_buzz =
{
	precache_sound ("ambience/buzz1.wav");
	ambientsound (self.origin, "ambience/buzz1.wav", 1, ATTN_STATIC);
};

void() ambient_drip =
{
	precache_sound ("ambience/drip1.wav");
	ambientsound (self.origin, "ambience/drip1.wav", 0.5, ATTN_STATIC);
};

void() ambient_comp_hum =
{
	precache_sound ("ambience/comp1.wav");
	ambientsound (self.origin, "ambience/comp1.wav", 1, ATTN_STATIC);
};

void() ambient_thunder =
{
	precache_sound ("ambience/thunder1.wav");
	ambientsound (self.origin, "ambience/thunder1.wav", 0.5, ATTN_STATIC);
};

void() ambient_light_buzz =
{
	precache_sound ("ambience/fl_hum1.wav");
	ambientsound (self.origin, "ambience/fl_hum1.wav", 0.5, ATTN_STATIC);
};

void() ambient_swamp1 =
{
	precache_sound ("ambience/swamp1.wav");
	ambientsound (self.origin, "ambience/swamp1.wav", 0.5, ATTN_STATIC);
};

void() ambient_swamp2 =
{
	precache_sound ("ambience/swamp2.wav");
	ambientsound (self.origin, "ambience/swamp2.wav", 0.5, ATTN_STATIC);
};

void() noise_think =
{
	self.nextthink = time + 0.5;
	sound (self, 1, "enforcer/enfire.wav", 1, ATTN_NORM);
	sound (self, 2, "enforcer/enfstop.wav", 1, ATTN_NORM);
	sound (self, 3, "enforcer/sight1.wav", 1, ATTN_NORM);
	sound (self, 4, "enforcer/sight2.wav", 1, ATTN_NORM);
	sound (self, 5, "enforcer/sight3.wav", 1, ATTN_NORM);
	sound (self, 6, "enforcer/sight4.wav", 1, ATTN_NORM);
	sound (self, 7, "enforcer/pain1.wav", 1, ATTN_NORM);
};

void() misc_noisemaker =
{
	precache_sound2 ("enforcer/enfire.wav");
	precache_sound2 ("enforcer/enfstop.wav");
	precache_sound2 ("enforcer/sight1.wav");
	precache_sound2 ("enforcer/sight2.wav");
	precache_sound2 ("enforcer/sight3.wav");
	precache_sound2 ("enforcer/sight4.wav");
	precache_sound2 ("enforcer/pain1.wav");
	precache_sound2 ("enforcer/pain2.wav");
	precache_sound2 ("enforcer/death1.wav");
	precache_sound2 ("enforcer/idle1.wav");

	self.nextthink = time + 0.1 + random ();
	self.think = noise_think;
};
