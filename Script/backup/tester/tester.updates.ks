RCS ON.
SAS OFF.
LOCK thrott TO 0.
LOCK THROTTLE TO thrott.
lock steering to heading(270,85).
set aposet to 10000.
clearscreen.
print "Up to " + aposet.
until ship:apoapsis > aposet
{
	set thrott to 1.
}
gear on.
gear off.
set thrott to 0.
clearscreen.
print aposet + " Apo hit".
wait until ship:verticalspeed < -2.
clearscreen.
Print "Powerland".
powerland().