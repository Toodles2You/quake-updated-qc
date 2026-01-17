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

void(entity ent, entity activator) SUB_UseTargetsEnt;

void() SUB_Null = {};

void(entity attacker, float damage) SUB_NullPain = {};

void() SUB_Remove = { remove (self); };

void(string s) entwarn =
{
	local vector org;

	org = self.origin + (self.mins + self.maxs) * 0.5;
	org_x = rint (org_x);
	org_y = rint (org_y);
	org_z = rint (org_z);

	dprint (self.classname);
	dprint (" near ");
	dprint (vtos (org));
	dprint (": ");
	dprint (s);
	dprint ("\n");
};

void(string s) enterror =
{
	entwarn (s);
	remove (self);
};

/*
QuakeEd only writes a single float for angles (bad idea), so up and down are
just constant angles.
*/
void() SetMovedir =
{
	if (self.angles == '0 -1 0')
		self.movedir = '0 0 1';
	else if (self.angles == '0 -2 0')
		self.movedir = '0 0 -1';
	else
	{
		makevectors (self.angles);
		self.movedir = v_forward;
	}

	self.angles = '0 0 0';
};

void() InitTrigger =
{
	// trigger angles are used for one-way touches.  An angle of 0 is assumed to
	// mean no restrictions, so use a yaw of 360 instead.
	if (self.angles != '0 0 0')
		SetMovedir ();
	self.solid = SOLID_TRIGGER;
	setmodel (self, self.model); // set size and link into world
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
};

/*
==============================================================================
SUB_Think

inline entity think
==============================================================================
*/
void(entity ent, void() func) SUB_Think =
{
	local entity oldself;

	oldself = self;
	self = ent;
	func ();
	self = oldself;
};

/*
==============================================================================
SUB_Interact

thy precious "self" and "other" art not but lies and deceit
==============================================================================
*/
void(entity thy, entity thou, void() func) SUB_Interact =
{
	local entity oldself, oldother;

	oldself = self;
	oldother = other;
	self = thy;
	other = thou;
	func ();
	self = oldself;
	other = oldother;
};

/*
==============================================================================
SUB_CalcMove

calculate self.velocity and self.nextthink to reach dest from
self.origin traveling at speed
==============================================================================
*/
void(entity ent, vector tdest, float tspeed, void() func) SUB_CalcMoveEnt =
{
	local entity oldself;

	oldself = self;
	self = ent;
	SUB_CalcMove (tdest, tspeed, func);
	self = oldself;
};

void(vector tdest, float tspeed, void() func) SUB_CalcMove =
{
	local vector vdestdelta;
	local float len, traveltime;

	if (!tspeed)
	{
		entwarn ("No speed is defined!");
		return;
	}

	self.think1 = func;
	self.finaldest = tdest;
	self.think = SUB_CalcMoveDone;

	if (tdest == self.origin)
	{
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}

	// set destdelta to the vector needed to move
	vdestdelta = tdest - self.origin;

	// calculate length of vector
	len = vlen (vdestdelta);

	// divide by speed to get time to reach dest
	traveltime = len / tspeed;

	if (traveltime < 0.1)
	{
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}

	// set nextthink to trigger a think when dest is reached
	self.nextthink = self.ltime + traveltime;

	// scale the destdelta vector by the time spent traveling to get velocity
	self.velocity = vdestdelta * (1 / traveltime); // qcc won't take vec/float
};

void() SUB_CalcMoveDone =
{
	setorigin (self, self.finaldest);
	self.velocity = '0 0 0';
	self.nextthink = -1;
	if (self.think1)
		self.think1 ();
};

/*
==============================================================================
SUB_CalcAngleMove

calculate self.avelocity and self.nextthink to reach destangle from self.angles
rotating

The calling function should make sure self.think is valid
==============================================================================
*/
void(entity ent, vector destangle, float tspeed, void() func) SUB_CalcAngleMoveEnt =
{
	local entity oldself;

	oldself = self;
	self = ent;
	SUB_CalcAngleMove (destangle, tspeed, func);
	self = oldself;
};

void(vector destangle, float tspeed, void() func) SUB_CalcAngleMove =
{
	local vector destdelta;
	local float len, traveltime;

	if (!tspeed)
	{
		entwarn ("No speed is defined!");
		return;
	}

	// set destdelta to the vector needed to move
	destdelta = destangle - self.angles;

	// calculate length of vector
	len = vlen (destdelta);

	// divide by speed to get time to reach dest
	traveltime = len / tspeed;

	// set nextthink to trigger a think when dest is reached
	self.nextthink = self.ltime + traveltime;

	// scale the destdelta vector by the time spent traveling to get velocity
	self.avelocity = destdelta * (1 / traveltime);

	self.think1 = func;
	self.finalangle = destangle;
	self.think = SUB_CalcAngleMoveDone;
};

void() SUB_CalcAngleMoveDone =
{
	self.angles = self.finalangle;
	self.avelocity = '0 0 0';
	self.nextthink = -1;
	if (self.think1)
		self.think1 ();
};

void() DelayThink =
{
	SUB_UseTargetsEnt (self, self.enemy);
	remove (self);
};

float(entity t) IsCounterTarget =
{
	if (t.classname == "particlefield")
		return TRUE;
	if (t.classname == "oncount")
		return TRUE;
	if (t.classname == "trigger_command")
		return TRUE;
	return FALSE;
};

void(entity ent, entity activator) UseTargetsCounter =
{
	local entity t;

	t = find (world, targetname, ent.target);
	while (t)
	{
		if (t.use)
			if (t.use != SUB_Null)
			{
				if (t.delay > 0) // won't work anyway
					SUB_Interact (t, activator, t.use);
				else if (IsCounterTarget (t))
				{
					// print the message here
					if (activator.classname == "player" && t.message != "")
					{
						centerprint (activator, t.message);
						if (t.noise == "")
							sound (activator, CHAN_VOICE, "misc/talk.wav", 1, ATTN_NORM);
					}

					SUB_Interact (t, ent, t.use);
				}
				else
					SUB_Interact (t, activator, t.use);
			}
		t = find (t, targetname, ent.target);
	}
};

/*
==============================================================================
SUB_UseTargetsEnt

the "activator" should be set to the entity that initiated the firing.

If self.delay is set, a DelayedUse entity will be created that will actually
do the SUB_UseTargets after that many seconds have passed.

Centerprints any self.message to the activator.

Removes all entities with a targetname that match self.killtarget,
and removes them, so some events can remove other triggers.

Search for (string)targetname in all entities that
match (string)self.target and call their .use function

==============================================================================
*/
void(entity ent, entity activator) SUB_UseTargetsEnt =
{
	local entity t;

	// check for a delay
	if (ent.delay > 0)
	{
		// create an entity to fire at a later time
		t = spawn ();
		t.classname = "DelayedUse";
		t.nextthink = time + ent.delay;
		t.think = DelayThink;
		t.enemy = activator;
		t.message = ent.message;
		t.killtarget = ent.killtarget;
		t.target = ent.target;
		return;
	}

	// print the message
	if (activator.classname == "player" && ent.message != "")
	{
		centerprint (activator, ent.message);
		if (ent.noise == "")
			sound (activator, CHAN_VOICE, "misc/talk.wav", 1, ATTN_NORM);
	}

	// kill the killtagets
	if (ent.killtarget != "")
	{
		t = find (world, targetname, ent.killtarget);
		while (t)
		{
			remove (t);
			t = find (t, targetname, ent.killtarget);
		}
	}

	// fire targets
	if (ent.target != "")
	{
		if (ent.classname == "counter")
		{
			UseTargetsCounter (ent, activator);
			return;
		}

		t = find (world, targetname, ent.target);
		while (t)
		{
			if (t.use)
				if (t.use != SUB_Null)
					SUB_Interact (t, activator, t.use);
			t = find (t, targetname, ent.target);
		}
	}
};

void() SUB_UseTargets =
{
	SUB_UseTargetsEnt (self, other);
};

/*
in nightmare mode, all attack_finished times become 0 some monsters refire
twice automatically
*/

void(float normal) SUB_AttackFinished =
{
	self.cnt = 0; // refire count for nightmare
	if (skill != 3)
		self.attack_finished = time + normal;
};

float(entity targ) visible;

void(void() thinkst) SUB_CheckRefire =
{
	if (skill != 3)
		return;
	if (self.cnt == 1)
		return;
	if (!visible (self.enemy))
		return;
	self.cnt = 1;
	self.think = thinkst;
};

void(float chance, string samp, float atten) SUB_CheckIdle =
{
	if (random () < chance)
	{
		if (self.enemy)
		{
			if (self.show_hostile >= time - 0.9)
				return;
		}
		sound (self, CHAN_VOICE, samp, 1, atten);
	}
};

float(entity targ) SUB_ShouldBleed =
{
	if (targ.takedamage)
		return TRUE;
	if ((targ.flags & (FL_CLIENT | FL_MONSTER)))
		return TRUE;
	return FALSE;
};

float(entity targ) SUB_IsAlive =
{
	if (targ.health <= 0)
		return FALSE;
	if (!targ.solid)
		return FALSE;
	return TRUE;
};
