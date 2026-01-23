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

void() push_use =
{
	local vector delta;
	local float x;
	local float y;

	makevectors (other.angles);

	x = fabs (other.velocity_x);
	y = fabs (other.velocity_y);
	dprint (ftos (x));
	dprint (", ");
	dprint (ftos (y));
	if (x > y)
	{
		dprint (" x move\n\n\n\n");
		if (other.velocity_x > 0)
		{
			walkmove (0, 16 * frametime);
		}
		else
		{
			walkmove (180, 16 * frametime);
		}
	}
	else
	{
		dprint (" y move\n\n\n\n");
		if (other.velocity_y > 0)
		{
			walkmove (90, 16 * frametime);
		}
		else
		{
			walkmove (270, 16 * frametime);
		}
	}

	delta = self.origin - self.oldorigin;
	setorigin (self.owner, self.owner.oldorigin + delta);
};

void() func_pushable =
{
	local entity proxy;
	local vector newsize;

	self.mangle = self.angles;
	self.angles = '0 0 0';

	self.classname = "pushablewall";
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setmodel (self, self.model);
	setorigin (self, self.origin);
	setsize (self, self.mins, self.maxs);
	self.oldorigin = self.origin;

	proxy = spawn ();
	proxy.owner = self;
	proxy.mangle = self.mangle;
	proxy.angles = self.angles;

	proxy.classname = "pushablewallproxy";
	proxy.solid = SOLID_BBOX;
	proxy.movetype = MOVETYPE_STEP;
	proxy.origin = (self.mins + self.maxs) * 0.5 + '0 0 1';
	newsize = (self.maxs - self.mins) * 0.5;
	proxy.mins = '-1 -1 0' - newsize;
	proxy.maxs = '1 1 -2' + newsize;
	setsize (proxy, proxy.mins, proxy.maxs);
	setorigin (proxy, proxy.origin);
	proxy.oldorigin = proxy.origin;
	proxy.touch = push_use;
};
