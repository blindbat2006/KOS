copypath("0:/lib/functions","1:").
copypath("0:/lib/default_ship","1:").
set sn to ship:name.
wait until not (ship:name = sn).
wait 0.01.
set ship:name to "roverlander".
wait 1.
set sn to ship:name.
SET TERMINAL:WIDTH to 56.
SET TERMINAL:HEIGHT to 22.
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
wait 1.
set core:bootfilename to "default_ship.ks".
unlock steering.
SET SHIP:CONTROL:NEUTRALIZE to TRUE.
run functions.
clearscreen.
set ag9 to false.
PRINT "Rover Lander setup ready.........".
wait 1.
Print "Press AG9 to start power landing".
wait until ag9.
powerland().
SAS OFF.
lock steering to ship:facing.
rcs on.
LOCK thrott to 0.
lock throttle to thrott.
until SHIP:VERTICALSPEED > 0.1
{
	set throttle to throttle + 0.01.
	wait 0.1.
}
stage.
set thrott to 1.
wait 2.
lock steering to heading(90,80).
wait 20.
set throttle to 0.