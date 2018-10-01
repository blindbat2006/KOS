set sn to ship:name.
wait until not (ship:name = sn).
unlock steering.
SET SHIP:CONTROL:NEUTRALIZE to TRUE.
LOCK thrott TO 0.
LOCK THROTTLE TO thrott.
RCS ON.
set steering to ship:facing.
SET SHIP:CONTROL:FORE to -1. // Seperate from the upper stage
wait 20.
SET SHIP:CONTROL:FORE to 0.
wait 1.
set steering to retrograde.
wait 5.
wait until abs(steeringmanager:yawerror) < 2 and abs(steeringmanager:pitcherror) < 2.
until ship:periapsis < 32000 or stage:ready
{
	set thrott to 1.
}