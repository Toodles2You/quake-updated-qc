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
void(entity targ, entity inflictor, entity attacker, float damage) T_Damage;
void() player_run;
void(entity bomb, entity attacker, float rad, entity ignore) T_RadiusDamage;
void(vector org, vector vel, float damage) SpawnBlood;
void() SuperDamageSound;

// called by worldspawn
void() W_Precache =
{
	precache_sound ("weapons/r_exp3.wav"); // used in C code
	precache_sound ("weapons/rocket1i.wav");
	precache_sound ("weapons/sgun1.wav");
	precache_sound ("weapons/guncock.wav");
	precache_sound ("weapons/ric1.wav"); // used in C code
	precache_sound ("weapons/ric2.wav"); // used in C code
	precache_sound ("weapons/ric3.wav"); // used in C code
	precache_sound ("weapons/spike2.wav");
	precache_sound ("weapons/tink1.wav"); // used in C code
	precache_sound ("weapons/grenade.wav");
	precache_sound ("weapons/bounce.wav");
	precache_sound ("weapons/shotgn2.wav");
};

float() crandom =
{
	return 2 * (random () - 0.5);
};

void() W_FireAxe =
{
	local vector source;
	local entity hit;
	local vector org;

	makevectors (self.v_angle);
	source = self.origin + '0 0 16';
	traceline (source, source + v_forward * 64, FALSE, self);
	if (trace_fraction == 1.0)
		return;

	hit = trace_ent;
	org = trace_endpos - v_forward * 4;

	if (SUB_ShouldBleed (hit))
	{
		hit.axhitme = TRUE;
		SpawnBlood (org, '0 0 0', 20);
		T_Damage (hit, self, self, 20);
		hit.axhitme = FALSE;
	}
	else
	{ // hit wall
		sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
};

vector() wall_velocity =
{
	local vector vel;

	vel = normalize (self.velocity);
	vel = vel + v_up * (random () - 0.5) + v_right * (random () - 0.5);
	vel = normalize (vel);
	vel = vel + 2 * trace_plane_normal;
	vel = vel * 200;

	return vel;
};

void(vector org, vector vel) SpawnMeatSpray =
{
	local entity missile;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_NOT;

	makevectors (self.angles);

	missile.velocity = vel;
	missile.velocity_z = missile.velocity_z + 250 + 50 * random ();

	missile.avelocity = '3000 1000 2000';

	missile.nextthink = time + 1;
	missile.think = SUB_Remove;

	setmodel (missile, "progs/zom_gib.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, org);
};

void(vector org, vector vel, float damage) SpawnBlood =
{
	particle (org, vel * 0.1, 73, damage * 2);
};

void(float damage) spawn_touchblood =
{
	local vector vel;

	vel = wall_velocity () * 0.2;
	SpawnBlood (self.origin + vel * 0.01, vel, damage);
};

void(vector org, vector vel) SpawnChunk =
{
	particle (org, vel * 0.02, 0, 10);
};

/*
==============================================================================
MULTI-DAMAGE

Collects multiple small damages into a single damage
==============================================================================
*/

entity multi_ent;
float multi_damage;

void() ClearMultiDamage =
{
	multi_ent = world;
	multi_damage = 0;
};

void() ApplyMultiDamage =
{
	if (!multi_ent)
		return;
	T_Damage (multi_ent, self, self, multi_damage);
};

void(entity hit, float damage) AddMultiDamage =
{
	if (!hit)
		return;

	if (hit != multi_ent)
	{
		ApplyMultiDamage ();
		multi_damage = damage;
		multi_ent = hit;
	}
	else
		multi_damage = multi_damage + damage;
};

void(float damage, vector dir) TraceAttack =
{
	local vector vel, org;

	vel = normalize (dir + v_up * crandom () + v_right * crandom ());
	vel = vel + 2 * trace_plane_normal;
	vel = vel * 200;

	org = trace_endpos - dir * 4;

	if (SUB_ShouldBleed (trace_ent))
	{
		SpawnBlood (org, vel * 0.2, damage);
		AddMultiDamage (trace_ent, damage);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
};

/*
==============================================================================
FireBullets

Used by shotgun, super shotgun, and enemy soldier firing
Go to the trouble of combining multiple pellets into a single damage call.
==============================================================================
*/
void(float shotcount, vector dir, vector spread) FireBullets =
{
	local vector direction;
	local vector src;

	makevectors (self.v_angle);

	src = self.origin + v_forward * 10;
	src_z = self.absmin_z + self.size_z * 0.7;

	ClearMultiDamage ();
	while (shotcount > 0)
	{
		direction = dir + crandom () * spread_x * v_right
				  + crandom () * spread_y * v_up;

		traceline (src, src + direction * 2048, FALSE, self);
		if (trace_fraction != 1.0)
			TraceAttack (4, direction);

		shotcount = shotcount - 1;
	}
	ApplyMultiDamage ();
};

void() W_FireShotgun =
{
	local vector dir;

	sound (self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	self.currentammo = self.ammo_shells = self.ammo_shells - 1;
	dir = aim (self, 100000);
	FireBullets (6, dir, '0.04 0.04 0');
};

void() W_FireSuperShotgun =
{
	local vector dir;

	if (self.ammo_shells < 2)
	{
		W_FireShotgun ();
		return;
	}

	sound (self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);

	self.punchangle_x = -4;

	self.currentammo = self.ammo_shells = self.ammo_shells - 2;
	dir = aim (self, 100000);
	FireBullets (14, dir, '0.14 0.08 0');
};

void() s_explode1 = [0, s_explode2] {};
void() s_explode2 = [1, s_explode3] {};
void() s_explode3 = [2, s_explode4] {};
void() s_explode4 = [3, s_explode5] {};
void() s_explode5 = [4, s_explode6] {};
void() s_explode6 = [5, SUB_Remove] {};

void(float type) BecomeExplosion =
{
	if (type)
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, type);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};

void() T_MissileTouch =
{
	local float damg;

	if (pointcontents (self.origin) == CONTENT_SKY)
	{
		remove (self);
		return;
	}

	damg = 100 + random () * 20;

	if (other.health)
	{
		if (other.classname == "monster_shambler")
			damg = damg * 0.5;
		T_Damage (other, self, self.owner, damg);
	}

	// don't do radius damage to the other, because all the damage
	// was done in the impact
	T_RadiusDamage (self, self.owner, 120, other);

	self.origin = self.origin - 8 * normalize (self.velocity);

	BecomeExplosion (TE_EXPLOSION);
};

void() W_FireRocket =
{
	local entity missile;

	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;

	sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
	missile.classname = "missile";

	makevectors (self.v_angle);
	missile.velocity = aim (self, 1000);
	missile.velocity = missile.velocity * 1000;
	missile.angles = vectoangles (missile.velocity);

	missile.touch = T_MissileTouch;

	missile.nextthink = time + 5;
	missile.think = SUB_Remove;

	setmodel (missile, "progs/missile.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin + v_forward * 8 + '0 0 16');
};

void(vector p1, vector p2, entity from, float damage) LightningDamage =
{
	local entity e1, e2, e3;
	local vector f;
	local float t;

	f = p2 - p1;
	f = normalize (f);
	t = f_x;
	f_x = 0 - f_y;
	f_y = t;
	f_z = 0;
	f = f * 16;

	e1 = e2 = e3 = world;

	traceline (p1, p2, FALSE, from);
	e1 = trace_ent;
	if (SUB_ShouldBleed (e1))
	{
		particle (trace_endpos, '0 0 100', 225, damage * 4);
		T_Damage (e1, from, from, damage);
		if (from.classname == "player")
		{
			if (e1.classname == "player")
				e1.velocity_z = e1.velocity_z + 400;
		}
	}

	traceline (p1 + f, p2 + f, FALSE, from);
	e2 = trace_ent;
	if (e2 != e1 && SUB_ShouldBleed (e2))
	{
		particle (trace_endpos, '0 0 100', 225, damage * 4);
		T_Damage (e2, from, from, damage);
	}

	traceline (p1 - f, p2 - f, FALSE, from);
	e3 = trace_ent;
	if (e3 != e1 && e3 != e2 && SUB_ShouldBleed (e3))
	{
		particle (trace_endpos, '0 0 100', 225, damage * 4);
		T_Damage (e3, from, from, damage);
	}
};

void() W_FireLightning =
{
	local vector org;
	local float cells;

	if (self.ammo_cells < 1)
	{
		W_SetWeapon (W_BestWeapon ());
		return;
	}

	// explode if under water
	if (self.waterlevel > 1)
	{
		cells = self.ammo_cells;
		self.ammo_cells = 0;
		W_SetWeapon (W_BestWeapon ());
		T_RadiusDamage (self, self, 35 * cells, world);
		return;
	}

	if (self.t_width < time)
	{
		sound (self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
		self.t_width = time + 0.6;
	}
	self.punchangle_x = -2;

	self.currentammo = self.ammo_cells = self.ammo_cells - 1;

	org = self.origin + '0 0 16';

	traceline (org, org + v_forward * 600, TRUE, self);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
	WriteEntity (MSG_BROADCAST, self);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
	WriteCoord (MSG_BROADCAST, trace_endpos_x);
	WriteCoord (MSG_BROADCAST, trace_endpos_y);
	WriteCoord (MSG_BROADCAST, trace_endpos_z);

	LightningDamage (self.origin, trace_endpos + v_forward * 4, self, 30);
};

void() GrenadeExplode =
{
	T_RadiusDamage (self, self.owner, 120, world);
	BecomeExplosion (TE_EXPLOSION);
};

void() GrenadeTouch =
{
	if (other.takedamage == DAMAGE_AIM)
	{
		GrenadeExplode ();
		return;
	}
	sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
};

void() W_FireGrenade =
{
	local entity missile;

	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;

	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;
	missile.classname = "grenade";

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

	missile.touch = GrenadeTouch;

	missile.nextthink = time + 2.5;
	missile.think = GrenadeExplode;

	setmodel (missile, "progs/grenade.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin);
};

void() spike_touch;
void() superspike_touch;

void(vector org, vector dir) launch_spike =
{
	newmis = spawn ();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;

	newmis.angles = vectoangles (dir);

	newmis.touch = spike_touch;
	newmis.classname = "spike";
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 6;
	setmodel (newmis, "progs/spike.mdl");
	setsize (newmis, '0 0 0', '0 0 0');
	setorigin (newmis, org);

	newmis.velocity = dir * 1000;
};

void() W_FireSuperSpikes =
{
	local vector dir;

	sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
	self.currentammo = self.ammo_nails = self.ammo_nails - 2;
	dir = aim (self, 1000);
	launch_spike (self.origin + '0 0 16', dir);
	newmis.touch = superspike_touch;
	setmodel (newmis, "progs/s_spike.mdl");
	setsize (newmis, '0 0 0', '0 0 0');
	self.punchangle_x = -2;
};

void(float ox) W_FireSpikes =
{
	local vector dir;

	makevectors (self.v_angle);

	if (self.ammo_nails >= 2 && self.weapon == IT_SUPER_NAILGUN)
	{
		W_FireSuperSpikes ();
		return;
	}

	if (self.ammo_nails < 1)
	{
		W_SetWeapon (W_BestWeapon ());
		return;
	}

	sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
	self.currentammo = self.ammo_nails = self.ammo_nails - 1;
	dir = aim (self, 1000);
	launch_spike (self.origin + '0 0 16' + v_right * ox, dir);

	self.punchangle_x = -2;
};

void() spike_touch =
{
	if (pointcontents (self.origin) == CONTENT_SKY)
	{
		remove (self);
		return;
	}

	// hit something that bleeds
	if (SUB_ShouldBleed (other))
	{
		spawn_touchblood (9);
		T_Damage (other, self, self.owner, 9);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);

		if (self.classname == "wizspike")
			WriteByte (MSG_BROADCAST, TE_WIZSPIKE);
		else if (self.classname == "knightspike")
			WriteByte (MSG_BROADCAST, TE_KNIGHTSPIKE);
		else
			WriteByte (MSG_BROADCAST, TE_SPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	remove (self);
};

void() superspike_touch =
{
	if (pointcontents (self.origin) == CONTENT_SKY)
	{
		remove (self);
		return;
	}

	// hit something that bleeds
	if (SUB_ShouldBleed (other))
	{
		spawn_touchblood (18);
		T_Damage (other, self, self.owner, 18);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_SUPERSPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	remove (self);
};

void() W_SetCurrentAmmo =
{
	self.items = self.items - (self.items & IT_AMMO);

	if (self.weapon == IT_AXE)
		self.currentammo = 0;
	else if (self.weapon == IT_SHOTGUN ||
			 self.weapon == IT_SUPER_SHOTGUN)
	{
		self.currentammo = self.ammo_shells;
		self.items = self.items | IT_SHELLS;
	}
	else if (self.weapon == IT_NAILGUN ||
			 self.weapon == IT_SUPER_NAILGUN)
	{
		self.currentammo = self.ammo_nails;
		self.items = self.items | IT_NAILS;
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER ||
			 self.weapon == IT_ROCKET_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_LIGHTNING)
	{
		self.currentammo = self.ammo_cells;
		self.items = self.items | IT_CELLS;
	}
	else
		self.currentammo = 0;
};

void(float weap) W_SetWeapon =
{
	if (self.weapon == weap)
	{
		W_SetCurrentAmmo ();
		return;
	}

	player_run (); // get out of any weapon firing states

	self.weapon = weap;

	if (self.weapon == IT_AXE)
		self.weaponmodel = "progs/v_axe.mdl";
	else if (self.weapon == IT_SHOTGUN)
		self.weaponmodel = "progs/v_shot.mdl";
	else if (self.weapon == IT_SUPER_SHOTGUN)
		self.weaponmodel = "progs/v_shot2.mdl";
	else if (self.weapon == IT_NAILGUN)
		self.weaponmodel = "progs/v_nail.mdl";
	else if (self.weapon == IT_SUPER_NAILGUN)
		self.weaponmodel = "progs/v_nail2.mdl";
	else if (self.weapon == IT_GRENADE_LAUNCHER)
		self.weaponmodel = "progs/v_rock.mdl";
	else if (self.weapon == IT_ROCKET_LAUNCHER)
		self.weaponmodel = "progs/v_rock2.mdl";
	else if (self.weapon == IT_LIGHTNING)
		self.weaponmodel = "progs/v_light.mdl";
	else
		self.weaponmodel = "";

	self.weaponframe = 0;

	W_SetCurrentAmmo ();
};

float() W_BestWeapon =
{
	local float it;

	it = self.items;

	if (self.waterlevel <= 1 && self.ammo_cells >= 1 && (it & IT_LIGHTNING))
		return IT_LIGHTNING;
	if (self.ammo_nails >= 2 && (it & IT_SUPER_NAILGUN))
		return IT_SUPER_NAILGUN;
	if (self.ammo_shells >= 2 && (it & IT_SUPER_SHOTGUN))
		return IT_SUPER_SHOTGUN;
	if (self.ammo_nails >= 1 && (it & IT_NAILGUN))
		return IT_NAILGUN;
	if (self.ammo_shells >= 1 && (it & IT_SHOTGUN))
		return IT_SHOTGUN;
	return IT_AXE;
};

float() W_CheckNoAmmo =
{
	if (self.currentammo > 0)
		return TRUE;

	if (self.weapon == IT_AXE)
		return TRUE;

	W_SetWeapon (W_BestWeapon ());

	if (self.currentammo > 0)
		return TRUE;

	if (self.weapon == IT_AXE)
		return TRUE;

	return FALSE;
};

void() player_axe1;
void() player_axeb1;
void() player_axec1;
void() player_axed1;
void() player_shot1;
void() player_nail1;
void() player_light1;
void() player_rocket1;

void() W_Attack =
{
	local float r;

	if (!W_CheckNoAmmo ())
		return;

	makevectors (self.v_angle);
	self.show_hostile = time + 1; // wake monsters up

	if (self.weapon == IT_AXE)
	{
		sound (self, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM);
		r = random ();
		if (r < 0.25)
			player_axe1 ();
		else if (r < 0.5)
			player_axeb1 ();
		else if (r < 0.75)
			player_axec1 ();
		else
			player_axed1 ();
		self.attack_finished = time + 0.5;
	}
	else if (self.weapon == IT_SHOTGUN)
	{
		player_shot1 ();
		W_FireShotgun ();
		self.attack_finished = time + 0.5;
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
		player_shot1 ();
		W_FireSuperShotgun ();
		self.attack_finished = time + 0.7;
	}
	else if (self.weapon == IT_NAILGUN)
	{
		player_nail1 ();
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
		player_nail1 ();
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		player_rocket1 ();
		W_FireGrenade ();
		self.attack_finished = time + 0.6;
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		player_rocket1 ();
		W_FireRocket ();
		self.attack_finished = time + 0.8;
	}
	else if (self.weapon == IT_LIGHTNING)
	{
		player_light1 ();
		self.attack_finished = time + 0.1;
		sound (self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM);
	}
};

void() W_ChangeWeapon =
{
	local float it, am, fl;

	it = self.items;
	am = 0;
	fl = 0;

	if (self.impulse == 1)
	{
		fl = IT_AXE;
	}
	else if (self.impulse == 2)
	{
		fl = IT_SHOTGUN;
		if (self.ammo_shells < 1)
			am = 1;
	}
	else if (self.impulse == 3)
	{
		fl = IT_SUPER_SHOTGUN;
		if (self.ammo_shells < 2)
			am = 1;
	}
	else if (self.impulse == 4)
	{
		fl = IT_NAILGUN;
		if (self.ammo_nails < 1)
			am = 1;
	}
	else if (self.impulse == 5)
	{
		fl = IT_SUPER_NAILGUN;
		if (self.ammo_nails < 2)
			am = 1;
	}
	else if (self.impulse == 6)
	{
		fl = IT_GRENADE_LAUNCHER;
		if (self.ammo_rockets < 1)
			am = 1;
	}
	else if (self.impulse == 7)
	{
		fl = IT_ROCKET_LAUNCHER;
		if (self.ammo_rockets < 1)
			am = 1;
	}
	else if (self.impulse == 8)
	{
		fl = IT_LIGHTNING;
		if (self.ammo_cells < 1)
			am = 1;
	}

	if (!(self.items & fl))
	{
		sprint (self, "No weapon\n");
		return;
	}

	if (am)
	{
		sprint (self, "Not enough ammo\n");
		return;
	}

	W_SetWeapon (fl);
};

void() CheatCommand =
{
	if (deathmatch || coop)
		return;

	self.ammo_rockets = 100;
	self.ammo_nails = 200;
	self.ammo_shells = 100;
	self.ammo_cells = 100;
	self.items = self.items | IT_WEAPONS | IT_KEYS;

	W_SetWeapon (IT_ROCKET_LAUNCHER);
};

/*
==============================================================================
CycleWeaponCommand

Go to the next weapon with ammo
==============================================================================
*/
void() CycleWeaponCommand =
{
	local float am, fl;

	fl = self.weapon;

	while (1)
	{
		am = 0;

		if (fl == IT_LIGHTNING)
		{
			fl = IT_AXE;
		}
		else if (fl == IT_AXE)
		{
			fl = IT_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (fl == IT_SHOTGUN)
		{
			fl = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2)
				am = 1;
		}
		else if (fl == IT_SUPER_SHOTGUN)
		{
			fl = IT_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
		}
		else if (fl == IT_NAILGUN)
		{
			fl = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2)
				am = 1;
		}
		else if (fl == IT_SUPER_NAILGUN)
		{
			fl = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (fl == IT_GRENADE_LAUNCHER)
		{
			fl = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (fl == IT_ROCKET_LAUNCHER)
		{
			fl = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;
		}

		if ((self.items & fl) && am == 0)
		{
			W_SetWeapon (fl);
			return;
		}
	}
};

/*
==============================================================================
CycleWeaponReverseCommand

Go to the prev weapon with ammo
==============================================================================
*/
void() CycleWeaponReverseCommand =
{
	local float am, fl;

	fl = self.weapon;

	while (1)
	{
		am = 0;

		if (fl == IT_LIGHTNING)
		{
			fl = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (fl == IT_ROCKET_LAUNCHER)
		{
			fl = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (fl == IT_GRENADE_LAUNCHER)
		{
			fl = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2)
				am = 1;
		}
		else if (fl == IT_SUPER_NAILGUN)
		{
			fl = IT_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
		}
		else if (fl == IT_NAILGUN)
		{
			fl = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2)
				am = 1;
		}
		else if (fl == IT_SUPER_SHOTGUN)
		{
			fl = IT_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (fl == IT_SHOTGUN)
		{
			fl = IT_AXE;
		}
		else if (fl == IT_AXE)
		{
			fl = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;
		}

		if ((self.items & fl) && am == 0)
		{
			W_SetWeapon (fl);
			return;
		}
	}
};

void() ServerflagsCommand =
{
	serverflags = serverflags * 2 + 1;
};

void() QuadCheat =
{
	if (deathmatch || coop)
		return;
	self.super_time = 1;
	self.super_damage_finished = time + 30;
	self.items = self.items | IT_QUAD;
};

void() ImpulseCommands =
{
	if (self.impulse >= 1 && self.impulse <= 8)
		W_ChangeWeapon ();
	if (self.impulse == 9)
		CheatCommand ();
	else if (self.impulse == 10)
		CycleWeaponCommand ();
	else if (self.impulse == 11)
		ServerflagsCommand ();
	else if (self.impulse == 12)
		CycleWeaponReverseCommand ();
	else if (self.impulse == 255)
		QuadCheat ();

	self.impulse = 0;
};

void() W_WeaponFrame =
{
	if (time < self.attack_finished)
		return;

	if (self.impulse)
		ImpulseCommands ();

	// check for attack
	if (self.button0)
	{
		SuperDamageSound ();
		W_Attack ();
	}
};

void() SuperDamageSound =
{
	if (self.super_damage_finished > time)
	{
		if (self.super_sound < time)
		{
			self.super_sound = time + 1;
			sound (self, CHAN_BODY, "items/damage3.wav", 1, ATTN_NORM);
		}
	}
};
