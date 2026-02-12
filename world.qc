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

void() InitBodyQue;

void() main = {};

float oldserverflags;
entity lastspawn;

void() worldspawn =
{
	oldserverflags = serverflags;
	lastspawn = world;
	InitBodyQue ();

	if (mapname == "e1m8")
		cvar_set ("sv_gravity", "100");
	else
		cvar_set ("sv_gravity", "800");

	W_Precache ();
	RunePrecache ();

	precache_sound ("demon/dland2.wav"); // used in C physics code
	precache_sound ("misc/h2ohit1.wav"); // used in C physics code

	precache_sound ("items/itembk2.wav");
	precache_sound ("player/plyrjmp8.wav");
	precache_sound ("player/land.wav");
	precache_sound ("player/land2.wav");
	precache_sound ("player/drown1.wav");
	precache_sound ("player/drown2.wav");
	precache_sound ("player/gasp1.wav");
	precache_sound ("player/gasp2.wav");
	precache_sound ("player/h2odeath.wav");

	precache_sound ("misc/talk.wav");
	precache_sound ("player/teledth1.wav");
	precache_sound ("misc/r_tele1.wav");
	precache_sound ("misc/r_tele2.wav");
	precache_sound ("misc/r_tele3.wav");
	precache_sound ("misc/r_tele4.wav");
	precache_sound ("misc/r_tele5.wav");
	precache_sound ("weapons/lock4.wav");
	precache_sound ("weapons/pkup.wav");
	precache_sound ("items/armor1.wav");
	precache_sound ("weapons/lhit.wav");
	precache_sound ("weapons/lstart.wav");
	precache_sound ("items/damage3.wav");

	precache_sound ("misc/power.wav");

	precache_sound ("player/gib.wav");
	precache_sound ("player/udeath.wav");
	precache_sound ("player/tornoff2.wav");

	precache_sound ("player/pain1.wav");
	precache_sound ("player/pain2.wav");
	precache_sound ("player/pain3.wav");
	precache_sound ("player/pain4.wav");
	precache_sound ("player/pain5.wav");
	precache_sound ("player/pain6.wav");

	precache_sound ("player/death1.wav");
	precache_sound ("player/death2.wav");
	precache_sound ("player/death3.wav");
	precache_sound ("player/death4.wav");
	precache_sound ("player/death5.wav");

	precache_sound ("weapons/ax1.wav");
	precache_sound ("player/axhit1.wav");
	precache_sound ("player/axhit2.wav");

	precache_sound ("player/h2ojump.wav");
	precache_sound ("player/slimbrn2.wav");
	precache_sound ("player/inh2o.wav");
	precache_sound ("player/inlava.wav");
	precache_sound ("misc/outwater.wav");

	precache_sound ("player/lburn1.wav");
	precache_sound ("player/lburn2.wav");

	precache_sound ("misc/water1.wav");
	precache_sound ("misc/water2.wav");

	precache_sound ("enforcer/enfstop.wav");
	precache_sound ("plasma/explode.wav");
	precache_sound ("plasma/flight.wav");
	precache_sound ("plasma/fire.wav");
	precache_sound ("shield/hit.wav");
	precache_sound ("belt/use.wav");
	precache_sound ("items/damage2.wav");

	precache_model ("progs/player.mdl");
	precache_model ("progs/eyes.mdl");
	precache_model ("progs/h_player.mdl");
	precache_model ("progs/gib1.mdl");
	precache_model ("progs/gib2.mdl");
	precache_model ("progs/gib3.mdl");

	precache_model ("progs/s_bubble.spr");
	precache_model ("progs/s_explod.spr");

	precache_model ("progs/v_axe.mdl");
	precache_model ("progs/v_shot.mdl");
	precache_model ("progs/v_nail.mdl");
	precache_model ("progs/v_rock.mdl");
	precache_model ("progs/v_shot2.mdl");
	precache_model ("progs/v_nail2.mdl");
	precache_model ("progs/v_rock2.mdl");

	precache_model ("progs/v_lava.mdl");
	precache_model ("progs/v_lava2.mdl");
	precache_model ("progs/v_multi.mdl");
	precache_model ("progs/v_multi2.mdl");

	precache_model ("progs/bolt.mdl"); // used in C code
	precache_model ("progs/bolt2.mdl"); // used in C code
	precache_model ("progs/bolt3.mdl"); // used in C code
	precache_model ("progs/lavaball.mdl");

	precache_model ("progs/missile.mdl");
	precache_model ("progs/grenade.mdl");
	precache_model ("progs/spike.mdl");
	precache_model ("progs/s_spike.mdl");

	precache_model ("progs/mervup.mdl");
	precache_model ("progs/rockup.mdl");
	precache_model ("progs/rockup_d.mdl");
	precache_model ("progs/lspike.mdl");
	precache_model ("progs/shield.mdl");
	precache_model ("progs/p_shield.mdl");

	precache_model ("progs/backpack.mdl");

	precache_model ("progs/zom_gib.mdl");

	precache_model ("progs/v_light.mdl");

	precache_model ("progs/plasma.mdl");
	precache_model ("progs/v_plasma.mdl");

	precache_model ("progs/hook.mdl");
	precache_model ("progs/v_grpple.mdl");

	// Setup light animation tables. 'a' is total darkness, 'z' is maxbright.

	// 0 normal
	lightstyle (0, "m");

	// 1 flicker (first variety)
	lightstyle (1, "mmnmmommommnonmmonqnmmo");

	// 2 slow strong pulse
	lightstyle (2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");

	// 3 candle (first variety)
	lightstyle (3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");

	// 4 fast strobe
	lightstyle (4, "mamamamamama");

	// 5 gentle pulse 1
	lightstyle (5, "jklmnopqrstuvwxyzyxwvutsrqponmlkj");

	// 6 flicker (second variety)
	lightstyle (6, "nmonqnmomnmomomno");

	// 7 candle (second variety)
	lightstyle (7, "mmmaaaabcdefgmmmmaaaammmaamm");

	// 8 candle (third variety)
	lightstyle (8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");

	// 9 slow strobe (fourth variety)
	lightstyle (9, "aaaaaaaazzzzzzzz");

	// 10 fluorescent flicker
	lightstyle (10, "mmamammmmammamamaaamammma");

	// 11 slow pulse not fade to black
	lightstyle (11, "abcdefghijklmnopqrrqponmlkjihgfedcba");

	// styles 32-62 are assigned by the light program for switchable lights

	// 63 testing
	lightstyle (63, "a");
};

void() StartFrame =
{
	teamplay = cvar ("teamplay");
	skill = cvar ("skill");

	if (deathmatch)
	{
		timelimit = cvar ("timelimit") * 60;
		fraglimit = cvar ("fraglimit");
	}
};

entity bodyque_head;

// just here so spawn functions don't complain after the world creates bodyques
void() bodyque = {};

void() InitBodyQue =
{
	bodyque_head = spawn ();
	bodyque_head.classname = "bodyque";
	bodyque_head.owner = spawn ();
	bodyque_head.owner.classname = "bodyque";
	bodyque_head.owner.owner = spawn ();
	bodyque_head.owner.owner.classname = "bodyque";
	bodyque_head.owner.owner.owner = spawn ();
	bodyque_head.owner.owner.owner.classname = "bodyque";
	bodyque_head.owner.owner.owner.owner = bodyque_head;
};

// make a body que entry for the given ent so the ent can be respawned elsewhere
void(entity ent) CopyToBodyQue =
{
	bodyque_head.skin = ent.skin;
	bodyque_head.angles_y = ent.angles_y;
	bodyque_head.model = ent.model;
	bodyque_head.modelindex = ent.modelindex;
	bodyque_head.frame = ent.frame;
	bodyque_head.colormap = ent.colormap;
	bodyque_head.movetype = ent.movetype;
	bodyque_head.velocity = ent.velocity;
	bodyque_head.flags = 0;
	setorigin (bodyque_head, ent.origin);
	setsize (bodyque_head, ent.mins, ent.maxs);
	bodyque_head = bodyque_head.owner;
};
