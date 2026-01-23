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
void() movetarget_f;
void() t_movetarget;
void() knight_walk1;
void() knight_bow6;
void() knight_bow1;
void(entity etemp, entity stemp, entity stemp, float dmg) T_Damage;

float MONSTER_AMBUSH = 1;

/*
.enemy
Will be world if not currently angry at anyone.

.movetarget
The next path spot to walk toward.  If .enemy, ignore .movetarget.
When an enemy is killed, the monster will try to return to it's path.

.huntt_ime
Set to time + something when the player is in sight, but movement straight for
him is blocked.  This causes the monster to use wall following code for
movement direction instead of sighting on the player.

.ideal_yaw
A yaw angle of the intended direction, which will be turned towards at up
to 45 deg / state.  If the enemy is in view and hunt_time is not active,
this will be the exact line towards the enemy.

.pausetime
A monster will leave it's stand state and head towards it's .movetarget when
time > .pausetime.

walkmove (angle, speed) primitive is all or nothing
*/

// when a monster becomes angry at a player, that monster will be used
// as the sight target the next frame so that monsters near that one
// will wake up even if they wouldn't have noticed the player
entity sight_entity;
float sight_entity_time;
void() FoundTarget;

float(float v) anglemod =
{
	while (v >= 360)
		v = v - 360;
	while (v < 0)
		v = v + 360;
	return v;
};

/*
==============================================================================

MOVETARGET CODE

The angle of the movetarget effects standing and bowing direction, but has no
effect on movement, which allways heads to the next target.

targetname
must be present.  The name of this movetarget.

target
the next spot to move to.  If not present, stop here for good.

pausetime
The number of seconds to spend standing or bowing for path_stand or path_bow

==============================================================================
*/

void() movetarget_f =
{
	if (self.targetname == "")
	{
		enterror ("no targetname");
		return;
	}

	self.solid = SOLID_TRIGGER;
	self.touch = t_movetarget;
	setsize (self, '-8 -8 -8', '8 8 8');
};

void() path_corner =
{
	movetarget_f ();
};

/*
==============================================================================
t_movetarget

Something has bumped into a movetarget.  If it is a monster
moving towards it, change the next destination and continue.
==============================================================================
*/
void() t_movetarget =
{
	local entity temp;

	if (other.movetarget != self)
		return;

	if (other.enemy)
		return; // fighting, not following a path

	temp = self;
	self = other;
	other = temp;

	if (self.classname == "monster_ogre")
		sound (self, CHAN_VOICE, "ogre/ogdrag.wav", 1, ATTN_IDLE);

	self.movetarget = find (world, targetname, other.target);

	if (self.movetarget)
	{
		self.goalentity = self.movetarget;
		self.ideal_yaw = vectoyaw (self.goalentity.origin - self.origin);

		if (other.delay)
		{
			self.pausetime = time + other.delay;
			self.th_stand ();
		}
	}
	else
	{
		self.pausetime = 0;
		self.th_stand ();
	}
};

/*
=============
t_followtarget

Something has bumped into a followtarget.  If it is a monster
moving towards it, change the next destination and continue.
==============
*/
void() t_followtarget =
{
	local entity temp;
	local vector spot1, spot2;
	local entity targ;
	local entity client;

	if (!(other.flags & FL_MONSTER))
		return;
	if (other.classname == "monster_decoy")
		return;
	if (other.wetsuit_time > time)
		return;
	targ = other.enemy;

	// see if any entities are in the way of the shot
	spot1 = other.origin + other.view_ofs;
	spot2 = targ.origin + targ.view_ofs;

	traceline (spot1, spot2, FALSE, other);
	if (trace_fraction == 1)
		return;

	if (other.enemy)
	{
		// make the monster tame
		other.oldenemy = other.enemy;
		other.enemy = world;
		other.think = other.th_walk;
	}

	temp = self;
	self = other;
	other = temp;

	self.movetarget = find (world, targetname, other.target);

	self.wetsuit_time = time + 2;

	if (self.movetarget)
	{
		self.goalentity = self.movetarget;
		self.ideal_yaw = vectoyaw (self.goalentity.origin - self.origin);
	}
	else
	{
		if (self.oldenemy != world)
		{
			self.enemy = self.oldenemy;
			FoundTarget ();
			return;
		}
		else
		{
			client = checkclient ();
			if (!client)
			{
				self.enemy = client;
				FoundTarget ();
				return;
			}
			self.pausetime = time + 999999;
			self.th_stand ();
		}
	}
};

void() followtarget_f =
{
	self.solid = SOLID_TRIGGER;
	self.touch = t_followtarget;
	setmodel (self, self.model); // set size and link into world
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
};

void() path_follow =
{
	followtarget_f ();
};

void() path_follow2 =
{
	self.solid = SOLID_TRIGGER;
	self.touch = t_followtarget;
	setsize (self, '-8 -8 -8', '8 8 8');
};

/*
==============================================================================
range

returns the range catagorization of an entity reletive to self
0	melee range, will become hostile even if back is turned
1	visibility and infront, or visibility and show hostile
2	infront and show hostile
3	only triggered by damage
==============================================================================
*/
float(entity targ) range =
{
	local vector spot1, spot2;
	local float r;
	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;

	r = vlen (spot1 - spot2);
	if (r < 120)
		return RANGE_MELEE;
	if (r < 500)
		return RANGE_NEAR;
	if (r < 1000)
		return RANGE_MID;
	return RANGE_FAR;
};

float(entity targ) visible =
{
	local vector spot1, spot2;

	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;
	traceline (spot1, spot2, TRUE, self);

	if (trace_inopen && trace_inwater)
		return FALSE; // sight line crossed contents

	if (trace_fraction == 1)
	{
		visible_distance = vlen (spot2 - spot1);
		return TRUE;
	}
	return FALSE;
};

float(entity targ) infront =
{
	local vector vec;
	local float dot;

	makevectors (self.angles);
	vec = normalize (targ.origin - self.origin);
	dot = vec * v_forward;

	if (dot > 0.3)
	{
		return TRUE;
	}
	return FALSE;
};

void() UpdateCharmerGoal =
{
	local entity targ;
	local vector d;

	d = normalize (self.origin - self.charmer.origin);

	if (self.huntingcharmer == 1)
	{
		targ = spawn ();
		self.trigger_field = targ;
		setorigin (targ, self.charmer.origin);
		self.huntingcharmer = 2;
		self.goalentity = targ;
	}
	if (self.huntingcharmer == 2)
	{
		targ = self.trigger_field;
		traceline (self.origin, self.charmer.origin, TRUE, self);
		if (trace_fraction == 1.0)
		{
			setorigin (targ, self.charmer.origin);
		}
	}
	else
	{
		targ = self.trigger_field;
		setorigin (targ, self.charmer.origin + (d * 300));
	}
};

void() HuntCharmer =
{
	self.huntingcharmer = 1;
	UpdateCharmerGoal ();
	self.think = self.th_walk;
	self.ideal_yaw = vectoyaw (self.goalentity.origin - self.origin);
	self.nextthink = time + 0.1;
};

void() FleeCharmer =
{
	self.huntingcharmer = 1;
	UpdateCharmerGoal ();
	self.huntingcharmer = 3;
	self.think = self.th_walk;
	self.nextthink = time + 0.1;
};

void() StopHuntingCharmer =
{
	self.goalentity = world;
	if (self.huntingcharmer > 1)
		remove (self.trigger_field);
	self.huntingcharmer = 0;
	self.think = self.th_stand;
	self.nextthink = time + 0.1;
};

void(entity client) HuntTarget =
{
	if (self.enemy)
	{
		if (self.enemy.classname == "player")
			self.oldenemy = self.enemy;
	}
	self.enemy = self.goalentity = client;
	self.think = self.th_run;
	self.ideal_yaw = vectoyaw (self.enemy.origin - self.origin);
	self.nextthink = time + 0.1;
	SUB_AttackFinished (1); // wait a while before first attack
};

void(entity client) HuntFoundTarget =
{
	if (client.classname == "player")
	{ // let other monsters see this monster for a while
		if (self.charmed)
		{
			if ((self.charmer == self.enemy) ||
				(self.charmer == self.enemy.charmer))
				{
				self.enemy = world;
				return;
			}
		}

		sight_entity = self;
		sight_entity_time = time;
	}
	else if (self.charmed)
	{
		if ((self.charmer == self.enemy.charmer))
		{
			self.enemy = world;
			return;
		}
	}

	self.show_hostile = time + 1; // wake up other monsters

	HuntTarget (client);

	if (self.th_sight)
		self.th_sight ();
};

void() FoundTarget =
{
	HuntFoundTarget (self.enemy);
};

float(entity client, float method) CanFindTarget =
{
	if (!client)
		return FALSE;
	if (client == self)
		return FALSE;
	if (client == self.enemy)
		return FALSE;
	if (!SUB_IsAlive (client))
		return FALSE;
	if (!(client.flags & (FL_CLIENT | FL_MONSTER)))
		return FALSE;
	if ((client.flags & FL_NOTARGET))
		return FALSE;
	if (self.charmed)
	{
		if (client == self.charmer)
			return FALSE;
		if (client.charmer == self.charmer)
			return FALSE;
		return TRUE;
	}
	if (method == FIND_DAMAGE)
	{
		if (!client.charmed)
		{
			if (self.classname == client.classname &&
				self.classname != "monster_army")
				return FALSE;
		}
	}
	else
	{
		if (method == FIND_DIRECT)
			if (client.invisible_finished > time)
				return FALSE;
		if (client.classname != "player")
			return FALSE;
	}
	return TRUE;
};

float() FindTargetCharmed =
{
	local entity client, head;
	local float r, dist;

	self.effects = self.effects | EF_DIMLIGHT;

	if (self.huntingcharmer > 0)
	{
		UpdateCharmerGoal ();
		r = vlen (self.origin - self.goalentity.origin);
		if (r < MIN_CHARMER_DISTANCE)
		{
			if (self.huntingcharmer == 3)
			{
				if (r > TOOCLOSE_CHARMER_DISTANCE)
					return FALSE;
			}
			StopHuntingCharmer ();
			return TRUE;
		}
	}
	else
	{
		r = vlen (self.origin - self.charmer.origin);
		if (r > MAX_CHARMER_DISTANCE)
		{
			HuntCharmer ();
			return FALSE;
		}
		else if (r < TOOCLOSE_CHARMER_DISTANCE)
		{
			FleeCharmer ();
			return FALSE;
		}
	}

	client = world;
	dist = CHARMED_RADIUS;
	head = findradius (self.origin, CHARMED_RADIUS);
	while (head)
	{
		if (CanFindTarget (head, FIND_DIRECT))
		{
			if (visible (head))
			{
				if (visible_distance < dist)
				{
					client = head;
					dist = visible_distance;
				}
			}
		}
		head = head.chain;
	}
	if (!client)
		return FALSE;

	HuntFoundTarget (client);

	return TRUE;
};

/*
==============================================================================
FindTarget

Self is currently not attacking anything, so try to find a target

Returns TRUE if an enemy was sighted

When a player fires a missile, the point of impact becomes a fakeplayer so
that monsters that see the impact will respond as if they had seen the
player.

To avoid spending too much time, only a single client (or fakeclient) is
checked each frame.  This means multi player games will have slightly
slower noticing monsters.
==============================================================================
*/
float() FindTarget =
{
	local entity client, sight;
	local float method, r;

	if (self.charmed)
		return FindTargetCharmed ();

	if (!(self.spawnflags & MONSTER_AMBUSH) &&
		(sight_entity_time >= time - 0.1))
	{
		sight = sight_entity;
		client = sight_entity.enemy;
		method = FIND_INFORM;
	}
	else
	{
		client = sight = checkclient ();
		method = FIND_DIRECT;
	}

	if (!CanFindTarget (client, method))
		return FALSE;

	r = range (sight);
	if (r == RANGE_FAR)
		return FALSE;

	if (!visible (sight))
		return FALSE;

	if (r == RANGE_NEAR)
	{
		if (sight.show_hostile < time && !infront (sight))
			return FALSE;
	}
	else if (r == RANGE_MID)
	{
		if (!infront (sight))
			return FALSE;
	}

	HuntFoundTarget (client);

	return TRUE;
};

void(float dist) ai_forward =
{
	walkmove (self.angles_y, dist);
};

void(float dist) ai_back =
{
	walkmove ((self.angles_y + 180), dist);
};

void(float dist) ai_pain =
{
	walkmove ((self.angles_y + 180), dist);
};

void(float dist) ai_painforward =
{
	walkmove (self.angles_y, dist);
};

void(float dist) ai_walk =
{
	// check for noticing a player
	if (FindTarget ())
		return;

	if (self.huntingcharmer)
	{
		movetogoal (dist);
		self.nextthink = time + ((self.nextthink - time) / 2);
	}
	else
		movetogoal (dist);
};

void() ai_stand =
{
	if (FindTarget ())
		return;

	if (self.pausetime)
	{
		if (time > self.pausetime)
			self.th_walk ();
	}
};

void() ai_turn =
{
	if (FindTarget ())
		return;

	ChangeYaw ();
};

void() ai_turn_in_place =
{
	local float delta;

	self.nextthink = time + 0.1;
	enemy_yaw = vectoyaw (self.enemy.origin - self.origin);
	delta = fabs (self.angles_y - enemy_yaw);
	if (delta > MIN_ANGLE_DELTA)
	{
		self.ideal_yaw = enemy_yaw;
		ChangeYaw ();
	}
	else
	{
		self.think = self.th_run;
	}
};

void(vector dest3) ChooseTurn =
{
	local vector dir, newdir;

	dir = self.origin - dest3;

	newdir_x = trace_plane_normal_y;
	newdir_y = 0 - trace_plane_normal_x;
	newdir_z = 0;

	if (dir * newdir > 0)
	{
		dir_x = 0 - trace_plane_normal_y;
		dir_y = trace_plane_normal_x;
	}
	else
	{
		dir_x = trace_plane_normal_y;
		dir_y = 0 - trace_plane_normal_x;
	}

	dir_z = 0;
	self.ideal_yaw = vectoyaw (dir);
};

float() FacingIdeal =
{
	local float delta;

	delta = anglemod (self.angles_y - self.ideal_yaw);
	if (delta > 45 && delta < 315)
		return FALSE;
	return TRUE;
};

void() ai_run_melee =
{
	self.ideal_yaw = enemy_yaw;
	ChangeYaw ();
	if (FacingIdeal ())
	{
		self.th_melee ();
		self.attack_state = AS_STRAIGHT;
	}
};

void() ai_run_missile =
{
	self.ideal_yaw = enemy_yaw;
	ChangeYaw ();
	if (FacingIdeal ())
	{
		self.th_missile ();
		self.attack_state = AS_STRAIGHT;
	}
};

void(float dist) ai_run_slide =
{
	local float ofs;

	self.ideal_yaw = enemy_yaw;
	ChangeYaw ();
	if (self.lefty)
		ofs = 90;
	else
		ofs = -90;

	if (walkmove (self.ideal_yaw + ofs, dist))
		return;

	self.lefty = 1 - self.lefty;

	walkmove (self.ideal_yaw - ofs, dist);
};

/*
=============
ai_run_dodge

Strafe sideways, but continue moving towards the enemy
Used by the Scourge.
=============
*/
void(float dist) ai_run_dodge =
{
	local float ofs;
	local float newyaw;

	self.nextthink = time + 0.1;
	if (self.lefty)
		ofs = 40;
	else
		ofs = -40;

	if (time > self.ltime)
	{
		self.lefty = 1 - self.lefty;
		self.ltime = time + 0.8;
	}

	newyaw = enemy_yaw + ofs;
	self.ideal_yaw = enemy_yaw;
	if (walkmove (newyaw, dist))
	{
		ChangeYaw ();
		return;
	}

	self.lefty = 1 - self.lefty;
	self.ltime = time + 0.8;
	newyaw = enemy_yaw - ofs;
	self.ideal_yaw = enemy_yaw;
	walkmove (newyaw, dist);
	ChangeYaw ();
};

/*
==============================================================================
ai_run

The monster has an enemy it is trying to kill
==============================================================================
*/
float RUN_STRAIGHT;
void(float dist) ai_run =
{
	local entity client;
	local float axis;
	local float angledelta;

	// see if the enemy is dead
	if (!SUB_IsAlive (self.enemy))
	{
		client = self.oldenemy;
		self.enemy = world;
		self.oldenemy = world;
		if (self.charmed)
		{
			HuntCharmer ();
			return;
		}
		if (CanFindTarget (client, FIND_DIRECT))
			HuntTarget (client);
		else if (self.movetarget)
		{
			self.goalentity = self.movetarget;
			self.ideal_yaw = vectoyaw (self.goalentity.origin - self.origin);
			self.th_walk ();
			return;
		}
		else
		{
			self.pausetime = 0;
			self.th_stand ();
			return;
		}
	}

	// check knowledge of enemy
	enemy_vis = visible (self.enemy);
	if (enemy_vis)
		self.search_time = time + 5;

	// look for other coop players
	if (coop && self.search_time < time && !self.charmed)
	{
		if (FindTarget ())
			return;
	}

	enemy_infront = infront (self.enemy);
	enemy_range = range (self.enemy);
	enemy_yaw = vectoyaw (self.enemy.origin - self.origin);

	if (self.th_turn)
	{
		angledelta = fabs (self.angles_y - enemy_yaw);
		if (angledelta > MIN_ANGLE_DELTA)
		{
			self.th_turn ();
			return;
		}
	}

	if (self.attack_state == AS_MISSILE)
	{
		ai_run_missile ();
		return;
	}
	if (self.attack_state == AS_MELEE)
	{
		ai_run_melee ();
		return;
	}

	if (enemy_vis)
	{
		if (self.th_checkattack)
		{
			if (self.th_checkattack ())
				return;
		}
		else if (CheckAttack ())
			return;
	}

	if (self.attack_state == AS_SLIDING)
	{
		ai_run_slide (dist);
		return;
	}

	if (self.attack_state == AS_DODGING)
	{
		ai_run_dodge (dist);
		return;
	}

	if (RUN_STRAIGHT && time > self.endtime)
	{
		RUN_STRAIGHT = 0;
		axis = walkmove (self.angles_y, dist);
		if (!axis)
		{
			self.endtime = time + 3;
			movetogoal (dist); // done in C code...
		}
	}
	else
	{
		// head straight in
		movetogoal (dist); // done in C code...
	}
};
