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
		objerror ("monster_movetarget: no targetname");

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

	if (other.target != "")
	{
		self.movetarget = find (world, targetname, other.target);
		self.goalentity = self.movetarget;
		self.ideal_yaw = vectoyaw (self.goalentity.origin - self.origin);
		if (!self.movetarget)
		{
			self.pausetime = time + 999999;
			self.th_stand ();
			return;
		}
		else if (other.delay)
		{
			self.pausetime = time + other.delay;
			self.th_stand ();
		}
	}
	else
	{
		self.pausetime = time + 999999;
		self.th_stand ();
		return;
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
	self.goalentity = self.movetarget;
	self.ideal_yaw = vectoyaw (self.goalentity.origin - self.origin);
	self.wetsuit_time = time + 2;
	if (!self.movetarget)
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
			//			dprint ("can see ");
			//			dprint (vtos (self.charmer.origin));
			//			dprint ("\n");
			setorigin (targ, self.charmer.origin);
		}
	}
	else
	{
		targ = self.trigger_field;
		setorigin (targ, self.charmer.origin + (d * 300));
	}
};

//============================================================================
void() HuntCharmer =
{
	self.huntingcharmer = 1;
	UpdateCharmerGoal ();
	//	self.goalentity = self.charmer;
	self.think = self.th_walk;
	self.ideal_yaw = vectoyaw (self.goalentity.origin - self.origin);
	self.nextthink = time + 0.1;
};

//============================================================================
void() FleeCharmer =
{
	self.huntingcharmer = 1;
	UpdateCharmerGoal ();
	self.huntingcharmer = 3;
	//	self.goalentity = self.charmer;
	self.think = self.th_walk;
	//	self.ideal_yaw = vectoyaw (self.originself.goalentity.origin -
	//self.origin);
	self.nextthink = time + 0.1;
};

//============================================================================
void() StopHuntingCharmer =
{
	self.goalentity = world;
	if (self.huntingcharmer > 1)
		remove (self.trigger_field);
	self.huntingcharmer = 0;
	self.think = self.th_stand;
	self.nextthink = time + 0.1;
};

void() HuntTarget =
{
	self.goalentity = self.enemy;
	self.think = self.th_run;
	self.ideal_yaw = vectoyaw (self.enemy.origin - self.origin);
	self.nextthink = time + 0.1;
	SUB_AttackFinished (1); // wait a while before first attack
};

void() SightSound =
{
	local float rsnd;

	if (self.classname == "monster_ogre")
		sound (self, CHAN_VOICE, "ogre/ogwake.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_knight")
		sound (self, CHAN_VOICE, "knight/ksight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_shambler")
		sound (self, CHAN_VOICE, "shambler/ssight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_demon1")
		sound (self, CHAN_VOICE, "demon/sight2.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_wizard")
		sound (self, CHAN_VOICE, "wizard/wsight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_zombie")
		sound (self, CHAN_VOICE, "zombie/z_idle.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_dog")
		sound (self, CHAN_VOICE, "dog/dsight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_hell_knight")
		sound (self, CHAN_VOICE, "hknight/sight1.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_tarbaby")
		sound (self, CHAN_VOICE, "blob/sight1.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_enforcer")
	{
		rsnd = rint (random () * 3);
		if (rsnd == 1)
			sound (self, CHAN_VOICE, "enforcer/sight1.wav", 1, ATTN_NORM);
		else if (rsnd == 2)
			sound (self, CHAN_VOICE, "enforcer/sight2.wav", 1, ATTN_NORM);
		else if (rsnd == 0)
			sound (self, CHAN_VOICE, "enforcer/sight3.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "enforcer/sight4.wav", 1, ATTN_NORM);
	}
	else if (self.classname == "monster_army")
		sound (self, CHAN_VOICE, "soldier/sight1.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_shalrath")
		sound (self, CHAN_VOICE, "shalrath/sight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_gremlin")
	{
		if (self.stoleweapon == 0)
			sound (self, CHAN_VOICE, "grem/sight1.wav", 1, ATTN_NORM);
	}
	else if (self.classname == "monster_scourge")
		sound (self, CHAN_VOICE, "scourge/sight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_armagon")
		sound (self, CHAN_VOICE, "armagon/sight.wav", 1, 0.1);
};

void() FoundTarget =
{
	if (self.enemy.classname == "player")
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

	SightSound ();
	HuntTarget ();
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
	local entity client;
	local float r;
	local entity head;
	local entity selected;
	local float dist;

	// if the first spawnflag bit is set, the monster will only wake up on
	// really seeing the player, not another monster getting angry

	// spawnflags & 3 is a big hack, because zombie crucified used the first
	// spawn flag prior to the ambush flag, and I forgot about it, so the second
	// spawn flag works as well

	if (self.charmed)
	{
		self.effects = self.effects | EF_DIMLIGHT;
		if (self.huntingcharmer > 0)
		{
			UpdateCharmerGoal ();
			//			self.goalentity = self.charmer;
			r = vlen (self.origin - self.goalentity.origin);
			if (r < MIN_CHARMER_DISTANCE)
			{
				//				dprint ("stopping\n");
				if ((self.huntingcharmer == 3) &&
					(r > TOOCLOSE_CHARMER_DISTANCE))
					return FALSE;
				//				self.huntingcharmer = 0;
				StopHuntingCharmer ();
				return TRUE;
			}
		}
		else if (vlen (self.origin - self.charmer.origin) >
				 MAX_CHARMER_DISTANCE)
		{
			//			self.huntingcharmer = 1;
			//			dprint ("hunting\n");
			HuntCharmer ();
			return FALSE;
		}
		else if (vlen (self.origin - self.charmer.origin) <
				 TOOCLOSE_CHARMER_DISTANCE)
		{
			//			self.huntingcharmer = 1;
			//			dprint ("fleeing\n");
			FleeCharmer ();
			return FALSE;
		}
	}
	if (sight_entity_time >= time - 0.1 && !(self.spawnflags & 3)
	 && !(self.charmed))
	{
		client = sight_entity;
		if (client.enemy == self.enemy)
			return FALSE;
	}
	else if (self.charmed)
	{
		selected = world;
		dist = CHARMED_RADIUS;
		head = findradius (self.origin, CHARMED_RADIUS);
		while (head)
		{
			if (!(head.flags & FL_NOTARGET) && (head.flags & FL_MONSTER))
			{
				if (visible (head) && (visible_distance < dist) &&
					(head.health > 0))
					{
					if ((head != self) && (head != self.charmer) &&
						(head.charmer != self.charmer))
						{
						selected = head;
						dist = visible_distance;
					}
				}
			}
			head = head.chain;
		}
		if (selected == world)
			return FALSE;

		client = selected;
	}
	else
	{
		client = checkclient ();
		if (!client)
			return FALSE; // current check entity isn't in PVS
	}

	if (client == self.enemy)
		return FALSE;

	if (!self.charmed)
	{
		if (client.flags & FL_NOTARGET)
			return FALSE;
	}
	if (client.items & IT_INVISIBILITY)
		return FALSE;

	r = range (client);
	if (r == RANGE_FAR)
		return FALSE;

	if (!visible (client))
		return FALSE;

	if (!self.charmed)
	{
		if (r == RANGE_NEAR)
		{
			if (client.show_hostile < time && !infront (client))
				return FALSE;
		}
		else if (r == RANGE_MID)
		{
			if (/*client.show_hostile < time ||*/ !infront (client))
				return FALSE;
		}
	}

	// got one
	self.enemy = client;

	if ((!self.charmed) && (!self.enemy.charmed))
	{
		if (self.enemy.classname != "player")
		{
			self.enemy = self.enemy.enemy;
			if (self.enemy.classname != "player")
			{
				self.enemy = world;
				return FALSE;
			}
		}
	}

	FoundTarget ();

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
	ai_back (dist);
};

void(float dist) ai_painforward =
{
	walkmove (self.ideal_yaw, dist);
};

void(float dist) ai_walk =
{
	movedist = dist;

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

	if (time > self.pausetime)
	{
		self.th_walk ();
		return;
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

float() WizardCheckAttack;
float() DogCheckAttack;
float() GremlinCheckAttack;
float() ScourgeCheckAttack;
float() ArmagonCheckAttack;

float() CheckAnyAttack =
{
	if (!enemy_vis)
		return FALSE;
	if (self.classname == "monster_army")
		return SoldierCheckAttack ();
	if (self.classname == "monster_ogre")
		return OgreCheckAttack ();
	if (self.classname == "monster_shambler")
		return ShamCheckAttack ();
	if (self.classname == "monster_demon1")
		return DemonCheckAttack ();
	if (self.classname == "monster_dog")
		return DogCheckAttack ();
	if (self.classname == "monster_wizard")
		return WizardCheckAttack ();
	if (self.classname == "monster_gremlin")
		return GremlinCheckAttack ();
	if (self.classname == "monster_scourge")
		return ScourgeCheckAttack ();
	if (self.classname == "monster_armagon")
		return ArmagonCheckAttack ();
	return CheckAttack ();
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

void() ai_run_slide =
{
	local float ofs;

	self.ideal_yaw = enemy_yaw;
	ChangeYaw ();
	if (self.lefty)
		ofs = 90;
	else
		ofs = -90;

	if (walkmove (self.ideal_yaw + ofs, movedist))
		return;

	self.lefty = 1 - self.lefty;

	walkmove (self.ideal_yaw - ofs, movedist);
};

/*
=============
ai_run_dodge

Strafe sideways, but continue moving towards the enemy
Used by the Scourge.
=============
*/
void() ai_run_dodge =
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
	if (walkmove (newyaw, movedist))
	{
		ChangeYaw ();
		return;
	}

	self.lefty = 1 - self.lefty;
	self.ltime = time + 0.8;
	newyaw = enemy_yaw - ofs;
	self.ideal_yaw = enemy_yaw;
	walkmove (newyaw, movedist);
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
	local float axis;
	local float angledelta;

	movedist = dist;
	// see if the enemy is dead
	if (self.enemy.health <= 0 ||
		(self.charmed && (self.charmer == self.enemy)))
	{
		self.enemy = world;
		if (self.charmed)
		{
			HuntCharmer ();
			return;
		}
		if (self.oldenemy.health > 0)
		{
			self.enemy = self.oldenemy;
			HuntTarget ();
		}
		else
		{
			if (self.movetarget)
				self.th_walk ();
			else
				self.th_stand ();
			return;
		}
	}

	self.show_hostile = time + 1; // wake up other monsters

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

	if (CheckAnyAttack ())
	{
		return;
	}

	if (self.attack_state == AS_SLIDING)
	{
		ai_run_slide ();
		return;
	}

	if (self.attack_state == AS_DODGING)
	{
		ai_run_dodge ();
		return;
	}

	if (RUN_STRAIGHT && time > self.endtime)
	{
		RUN_STRAIGHT = 0;
		axis = walkmove (self.angles_y, movedist);
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
