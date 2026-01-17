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

// Rogue Teamplay Variants Message of the Day function
// Feb'97 by ZOID <zoid@threewave.com>
// Under contract to id software for Rogue Entertainment

.float motd_time;
.float motd_count;

void() MOTD =
{
	local string tp;

	if (self.motd_count < 5)
	{
		if (teamplay > 3 && teamplay < 7)
		{
			tp = ftos (teamplay);
			stuffcmd (self, "teamplay ");
			stuffcmd (self, tp);
			stuffcmd (self, "\n");
		}
		self.motd_time = time + 1;
		self.motd_count = self.motd_count + 1;
		if (teamplay == TEAM_DMATCH_TAG)
			centerprint (self, MOTD_TAG);
		else if (teamplay == TEAM_CTF)
			if (self.steam == TEAM1)
				centerprint (self, MOTD_CTF_TEAM1);
			else
				centerprint (self, MOTD_CTF_TEAM2);
		else if (teamplay == TEAM_CTF_ONEFLAG)
			if (self.steam == TEAM1)
				centerprint (self, MOTD_CTF_ONEFLAG_TEAM1);
			else
				centerprint (self, MOTD_CTF_ONEFLAG_TEAM2);
		else if (teamplay == TEAM_CTF_ALT)
			if (self.steam == TEAM1)
				centerprint (self, MOTD_CTF_ALT_TEAM1);
			else if (self.steam == TEAM2)
				centerprint (self, MOTD_CTF_ALT_TEAM2);
			else
				centerprint (self, MOTD_CTF_ALT_TEAM3);
		return;
	}
	self.motd_time = 0;
};

void() CheckMOTD =
{
	if (self.motd_time)
	{
		if (self.motd_time < time)
			MOTD ();
	}
};

void() SetMOTD =
{
	self.motd_time = time + 3;
	if (teamplay == 3)
		self.motd_count = 2;
	else
		self.motd_count = 0;
};
