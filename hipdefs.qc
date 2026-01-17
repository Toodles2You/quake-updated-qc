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

entity nullentity;
entity bulletholes;
entity lastbullet;
float numbulletholes;

float IT_MJOLNIR = 128;
float IT_PROXIMITY_GUN = 65536;
float IT_LASER_CANNON = 8388608;

float HIP_IT_WETSUIT = 2;
float HIP_IT_EMPATHY_SHIELDS = 4;
float HIP_IT_HORN_OF_CONJURING = 8;
float HIP_IT_ARTS = 14;

float SVC_UPDATESTAT = 3;
float SVC_CUTSCENE = 34;

float STAT_TOTALMONSTERS = 12;
float STAT_TOTALSECRETS = 11;

.void() th_turn;

float AS_DODGING = 5;

float CHARMED_RADIUS = 1500;
float MAX_CHARMER_DISTANCE = 200;
float MIN_CHARMER_DISTANCE = 150;
float TOOCLOSE_CHARMER_DISTANCE = 120;

float visible_distance;
entity damage_inflictor;
float footsteps;

float MIN_ANGLE_DELTA = 10;

.float wetsuit_finished;
.float wetsuit_time;
.float empathy_finished;
.float empathy_time;
.float empathy_sound;
.float color;

.float items2;

// gremlin
.float gorging;
.float stoleweapon;
.entity lastvictim;

.void() spawnfunction;
.string spawnclassname;
.float spawnsolidtype;
.string spawnmodel;
.void() spawnthink;
.entity spawnmaster;
.vector spawnmins;
.vector spawnmaxs;
.float spawnsilent;
.float spawnmulti;

// horn of conjuring
.float charmed;
.entity charmer;
.float huntingcharmer;
float horn_active;
entity horn_charmer;

.vector old_velocity;

.float duration;

.entity next_ent;

.float struck_by_mjolnir;

// teleport invulnerability
.float last_teleport_time;

// rotation
.vector neworigin;
.vector rotate;
.float endtime;
.float rotate_type;
.string path;
.string group;
.string event;

.float gravity;

float discharged;
entity hipdecoy;

void() StopEarthQuake;
void(float value) EarthQuakeTime;
void() earthquake_postthink;
void() earthquake_prethink;
float(entity counter) counter_GetCount;
vector(vector ang) SUB_NormalizeAngles;
void(entity srcent, entity destent) SUB_CopyEntity;
void(vector loc, float rad, float damage, float dur, float pause, float vol) multi_explosion;
void(string targ, vector orig) become_decoy;

void() RotateTargets;
void() RotateTargetsFinal;
void() SetTargetOrigin;
void() LinkRotateTargets;
