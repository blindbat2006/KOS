copypath("0:/lib/functions","1:").
copypath("0:/lib/launch","1:").
copypath("0:/lib/default_ship","1:").
wait until ship:unpacked.
SET TERMINAL:WIDTH to 56.
SET TERMINAL:HEIGHT to 22.
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
run once "functions".
parameter
  compass is 0,
  orbit_height is 80000,
  count is 5,
  second_height is -1,
  second_height_long is -1,
  atmo_end is 70000.

set ship:control:pilotmainthrottle to 0.
if ship:periapsis < 100 and (status = "LANDED" or status = "PRELAUNCH") 
{
	hudtext( "Unpacked. Now loading launch software.", 2, 2, 45, green, true).
	switch to 1.
	set core:bootfilename to "".
	launcher(compass, orbit_height, true, second_height, second_height_long, atmo_end).
	clearscreen.
	SAS OFF.
	RCS ON.
	LOCK STEERING TO SUN:position.
	wait until abs(steeringmanager:yawerror) < 2 and abs(steeringmanager:pitcherror) < 2 and abs(steeringmanager:rollerror) < 1.
	RCS OFF.
	wait 5.
	unlock steering.
	panels on.
	lights on.
	print "launch done.".
	set core:bootfilename to "default_ship.ks".
	print "Rebooting".
	wait 1.
	clearscreen.
	reboot.
}