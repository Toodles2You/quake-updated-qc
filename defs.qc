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

/*
==============================================================================

SOURCE FOR GLOBALVARS_T C STRUCTURE

==============================================================================
*/

// system globals
entity self;
entity other;
entity world;
float time;
float frametime;

float force_retouch; // force all entities to touch triggers next frame

string mapname;

float deathmatch;
float coop;
float teamplay;

// propagated from level to level, used to keep track of completed episodes
float serverflags;

float total_secrets;
float total_monsters;

float found_secrets;
float killed_monsters;

// parms are used to encode information about clients across level changes
float parm1, parm2, parm3, parm4, parm5, parm6, parm7, parm8, parm9, parm10;
float parm11, parm12, parm13, parm14, parm15, parm16;

// global variables set by built in functions

// makevectors
vector v_forward, v_up, v_right;

// traceline
float trace_allsolid;
float trace_startsolid;
float trace_fraction;
vector trace_endpos;
vector trace_plane_normal;
float trace_plane_dist;
entity trace_ent;
float trace_inopen;
float trace_inwater;

entity msg_entity; // destination of single entity writes

// required prog functions

void() main; // only for testing

void() StartFrame;

void() PlayerPreThink;
void() PlayerPostThink;

void() ClientKill;
void() ClientConnect;
void() PutClientInServer;
void() ClientDisconnect;

// called when a client first connects to a server.
// sets parms so they can be saved off for restarts
void() SetNewParms;

// call to set parms for self so they can be saved for a level transition
void() SetChangeParms;

void end_sys_globals; // flag for structure dumping

/*
==============================================================================

SOURCE FOR ENTVARS_T C STRUCTURE

==============================================================================
*/

// system fields

.float modelindex;
.vector absmin, absmax;

.float ltime; // local time for entity
.float movetype;
.float solid;

.vector origin;
.vector oldorigin;
.vector velocity;
.vector angles;
.vector avelocity;

.vector punchangle; // temp angle adjust from damage or recoil

.string classname;
.string model;
.float frame;
.float skin;
.float effects;

.vector mins, maxs;
.vector size;

.void() touch;
.void() use;
.void() think;
.void() blocked; // for doors or plats, called when can't push other

.float nextthink;
.entity groundentity;

// stats
.float health;
.float frags;
.float weapon;
.string weaponmodel;
.float weaponframe;
.float currentammo;
.float ammo_shells, ammo_nails, ammo_rockets, ammo_cells;

.float items;

.float takedamage;
.entity chain;
.float deadflag;

.vector view_ofs;

.float button0; // fire
.float button1; // use
.float button2; // jump

.float impulse; // weapon changes

.float fixangle;
.vector v_angle; // view / targeting angle for players
.float idealpitch; // calculated pitch angle for lookup up slopes

.string netname;

.entity enemy;

.float flags;

.float colormap;
.float team;

.float max_health;

.float teleport_time; // don't back up

.float armortype; // save this fraction of incoming damage
.float armorvalue;

.float waterlevel; // 0 = not in, 1 = feet, 2 = wast, 3 = eyes
.float watertype; // a contents value

.float ideal_yaw;
.float yaw_speed;

.entity aiment;

.entity goalentity; // a movetarget or an enemy

.float spawnflags;

.string target;
.string targetname;

// damage is accumulated through a frame. and sent as one single message,
// so the super shotgun doesn't generate huge messages
.float dmg_take;
.float dmg_save;
.entity dmg_inflictor;

.entity owner;
.vector movedir; // mostly for doors, but also used for waterjump

.string message;

.float sounds;

.string noise, noise1, noise2, noise3;

void end_sys_fields; // flag for structure dumping

/*
==============================================================================

VARS NOT REFERENCED BY C CODE

==============================================================================
*/

// constants

float FALSE = 0;
float TRUE = 1;

float FL_FLY = 1;
float FL_SWIM = 2;
float FL_CLIENT = 8;
float FL_INWATER = 16;
float FL_MONSTER = 32;
float FL_GODMODE = 64;
float FL_NOTARGET = 128;
float FL_ITEM = 256; // extra size against players and monsters
float FL_ONGROUND = 512;
float FL_PARTIALGROUND = 1024; // not all corners are valid
float FL_WATERJUMP = 2048; // player jumping out of water
float FL_JUMPRELEASED = 4096;

float MOVETYPE_NONE = 0;
float MOVETYPE_WALK = 3; // player
float MOVETYPE_STEP = 4; // monster
float MOVETYPE_FLY = 5;
float MOVETYPE_TOSS = 6;
float MOVETYPE_PUSH = 7; // ignore world, push and crush
float MOVETYPE_NOCLIP = 8;
float MOVETYPE_FLYMISSILE = 9; // extra size against monsters
float MOVETYPE_BOUNCE = 10;
float MOVETYPE_BOUNCEMISSILE = 11; // extra size against monsters

float SOLID_NOT = 0;
float SOLID_TRIGGER = 1;
float SOLID_BBOX = 2; // missile
float SOLID_SLIDEBOX = 3; // player and monster
float SOLID_BSP = 4;

float RANGE_MELEE = 0;
float RANGE_NEAR = 1;
float RANGE_MID = 2;
float RANGE_FAR = 3;

float FIND_DIRECT = 0;
float FIND_INFORM = 1;
float FIND_DAMAGE = 2;

float DEAD_NO = 0;
float DEAD_DYING = 1;
float DEAD_DEAD = 2;
float DEAD_RESPAWNABLE = 3;

float DAMAGE_NO = 0;
float DAMAGE_YES = 1;
float DAMAGE_AIM = 2;

float IT_AXE = 4096;
float IT_SHOTGUN = 1;
float IT_SUPER_SHOTGUN = 2;
float IT_NAILGUN = 4;
float IT_SUPER_NAILGUN = 8;
float IT_GRENADE_LAUNCHER = 16;
float IT_ROCKET_LAUNCHER = 32;
float IT_LIGHTNING = 64;
float IT_EXTRA_WEAPON = 128;

float IT_SHELLS = 256;
float IT_NAILS = 512;
float IT_ROCKETS = 1024;
float IT_CELLS = 2048;

float IT_ARMOR1 = 8192;
float IT_ARMOR2 = 16384;
float IT_ARMOR3 = 32768;
float IT_SUPERHEALTH = 65536;

float IT_KEY1 = 131072;
float IT_KEY2 = 262144;

float IT_INVISIBILITY = 524288;
float IT_INVULNERABILITY = 1048576;
float IT_SUIT = 2097152;
float IT_QUAD = 4194304;

float IT_WEAPONS = 4223;
float IT_AMMO = 3840;
float IT_ARMOR = 57344;
float IT_KEYS = 393216;
float IT_ARTS = 7864320;

float CONTENT_EMPTY = -1;
float CONTENT_SOLID = -2;
float CONTENT_WATER = -3;
float CONTENT_SLIME = -4;
float CONTENT_LAVA = -5;
float CONTENT_SKY = -6;

float STATE_TOP = 0;
float STATE_BOTTOM = 1;
float STATE_UP = 2;
float STATE_DOWN = 3;

vector VEC_HULL_MIN = '-16 -16 -24';
vector VEC_HULL_MAX = '16 16 32';

vector VEC_HULL2_MIN = '-32 -32 -24';
vector VEC_HULL2_MAX = '32 32 64';

// protocol bytes
float SVC_TEMPENTITY = 23;
float SVC_KILLEDMONSTER = 27;
float SVC_FOUNDSECRET = 28;
float SVC_INTERMISSION = 30;
float SVC_FINALE = 31;
float SVC_CDTRACK = 32;
float SVC_SELLSCREEN = 33;

float TE_SPIKE = 0;
float TE_SUPERSPIKE = 1;
float TE_GUNSHOT = 2;
float TE_EXPLOSION = 3;
float TE_TAREXPLOSION = 4;
float TE_LIGHTNING1 = 5;
float TE_LIGHTNING2 = 6;
float TE_WIZSPIKE = 7;
float TE_KNIGHTSPIKE = 8;
float TE_LIGHTNING3 = 9;
float TE_LAVASPLASH = 10;
float TE_TELEPORT = 11;

// sound channels
// channel 0 never willingly overrides
// other channels (1-7) allways override a playing sound on that channel
float CHAN_AUTO = 0;
float CHAN_WEAPON = 1;
float CHAN_VOICE = 2;
float CHAN_ITEM = 3;
float CHAN_BODY = 4;

float ATTN_NONE = 0;
float ATTN_NORM = 1;
float ATTN_IDLE = 2;
float ATTN_STATIC = 3;

float EF_BRIGHTFIELD = 1;
float EF_MUZZLEFLASH = 2;
float EF_BRIGHTLIGHT = 4;
float EF_DIMLIGHT = 8;

// server flags
float SFL_EPISODE_1 = 1;
float SFL_EPISODE_2 = 2;
float SFL_EPISODE_3 = 4;
float SFL_EPISODE_4 = 8;
float SFL_EPISODES = 15;

float MSG_BROADCAST = 0; // unreliable to all
float MSG_ONE = 1; // reliable to one (msg_entity)
float MSG_ALL = 2; // reliable to all
float MSG_INIT = 3; // write to the init string

float FINALE_EMPTY = 0;
float FINALE_SHAREWARE = 1;
float FINALE_EPISODE_1 = 2;
float FINALE_EPISODE_2 = 3;
float FINALE_EPISODE_3 = 4;
float FINALE_EPISODE_4 = 5;
float FINALE_EPISODES = 6;
float FINALE_END = 7;

// globals

float gameover; // set when a rule exits

float skill;

float timelimit, fraglimit;

// world (FIXME: make globals)
.string wad;
.string map;
.float worldtype;

.string killtarget;

// quakeed
.float light_lev; // not used by game
.float style;

// monsters
.void() th_stand;
.void() th_walk;
.void() th_run;
.void() th_missile;
.void() th_melee;
.void(entity attacker, float damage) th_pain;
.void() th_die;
.void() th_sight;
.float() th_checkattack;

.entity oldenemy; // mad at this player before taking damage

.float speed;

.float lefty;

.float search_time;
.float attack_state;

float AS_STRAIGHT = 1;
float AS_SLIDING = 2;
float AS_MELEE = 3;
float AS_MISSILE = 4;

// player
.float walkframe;

.float attack_finished;
.float pain_finished;

.float invincible_finished;
.float invisible_finished;
.float super_damage_finished;
.float radsuit_finished;

.float invincible_time, invincible_sound;
.float invisible_time, invisible_sound;
.float super_time, super_sound;
.float rad_time;
.float fly_sound;

.float axhitme;

// set to time + 1 whenever a client fires a weapon or takes damage.
// Used to alert monsters that otherwise would let the player go
.float show_hostile;

.float jump_flag;
.float swim_flag;
.float air_finished; // when time > air_finished, start drowning
.float bubble_count;
.string deathtype;

.string mdl;
.vector mangle;

.float t_length, t_width;

// doors, etc
.vector dest, dest1, dest2;
.float wait; // time from firing to restarting
.float delay; // time from activation to firing
.entity trigger_field;
.string noise4;

// monsters
.float pausetime;
.entity movetarget;

// doors
.float aflag;
.float dmg;

.float cnt;

.void() think1;
.vector finaldest, finalangle;

.float count;

// plats / doors / buttons
.float lip;
.float state;
.vector pos1, pos2; // top and bottom positions
.float height;

.float waitmin, waitmax;
.float distance;
.float volume;

// builtin functions

void(vector ang) makevectors = #1; // sets v_forward, v_right, v_up
void(entity e, vector o) setorigin = #2;
void(entity e, string m) setmodel = #3;
void(entity e, vector min, vector max) setsize = #4;
void() break = #6;
float() random = #7; // returns 0 - 1
void(entity e, float chan, string samp, float vol, float atten) sound = #8;
vector(vector v) normalize = #9;
void(string e) error = #10;
void(string e) objerror = #11;
float(vector v) vlen = #12;
float(vector v) vectoyaw = #13;
entity() spawn = #14;
void(entity e) remove = #15;

// sets trace_* globals
// nomonsters can be:
// An entity will also be ignored for testing if forent == test,
// forent->owner == test, or test->owner == forent
// a forent of world is ignored
void(vector v1, vector v2, float nomonsters, entity forent) traceline = #16;

entity() checkclient = #17; // returns a client to look for
entity(entity start, .string fld, string match) find = #18;
string(string s) precache_sound = #19;
string(string s) precache_model = #20;
void(entity client, string s) stuffcmd = #21;
entity(vector org, float rad) findradius = #22;
void(string s) bprint = #23;
void(entity client, string s) sprint = #24;
void(string s) dprint = #25;
string(float f) ftos = #26;
string(vector v) vtos = #27;
void() coredump = #28; // prints all edicts
void() traceon = #29; // turns statment trace on
void() traceoff = #30;
void(entity e) eprint = #31;
float(float yaw, float dist) walkmove = #32;
float() droptofloor = #34; // true if landed on floor
void(float style, string value) lightstyle = #35;
float(float v) rint = #36;
float(float v) floor = #37;
float(float v) ceil = #38;
float(entity e) checkbottom = #40;
float(vector v) pointcontents = #41;
float(float f) fabs = #43;
vector(entity e, float speed) aim = #44; // returns the auto-aim vector
float(string s) cvar = #45;
void(string s) localcmd = #46;
entity(entity e) nextent = #47; // for looping through all ents

void(vector o, vector d, float color, float count) particle = #48;

void() ChangeYaw = #49; // turn towards self.ideal_yaw at self.yaw_speed

vector(vector v) vectoangles = #51;

void(float to, float f) WriteByte = #52;
void(float to, float f) WriteChar = #53;
void(float to, float f) WriteShort = #54;
void(float to, float f) WriteLong = #55;
void(float to, float f) WriteCoord = #56;
void(float to, float f) WriteAngle = #57;
void(float to, string s) WriteString = #58;
void(float to, entity s) WriteEntity = #59;

void(float step) movetogoal = #67;

string(string s) precache_file = #68; // no effect except for -copy
void(entity e) makestatic = #69;
void(string s) changelevel = #70;

void(string var, string val) cvar_set = #72;

void(entity client, string s) centerprint = #73;

void(vector pos, string samp, float vol, float atten) ambientsound = #74;

// registered version only
string(string s) precache_model2 = #75;
string(string s) precache_sound2 = #76;
string(string s) precache_file2 = #77;

// set parms to the values at level start for coop respawn
void(entity e) setspawnparms = #78;

void(vector tdest, float tspeed, void() func) SUB_CalcMove;
void(entity ent, vector tdest, float tspeed, void() func) SUB_CalcMoveEnt;
void(vector destangle, float tspeed, void() func) SUB_CalcAngleMove;
void() SUB_CalcMoveDone;
void() SUB_CalcAngleMoveDone;
void() SUB_Null;
void() SUB_UseTargets;
void() SUB_Remove;

void(entity targ, entity inflictor, entity attacker, float damage) T_Damage;

float(entity e, float healamount, float ignore) T_Heal;

float(entity targ, entity inflictor) CanDamage;
