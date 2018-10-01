copypath("0:/lib/functions","1:").
set sn to ship:name.
wait until not (ship:name = sn).
SET TERMINAL:WIDTH to 56.
SET TERMINAL:HEIGHT to 22.
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
run functions.
set ship:name to "Return Stage".
unlock steering.
SET SHIP:CONTROL:NEUTRALIZE to TRUE.
set STEERINGMANAGER:pitchtorquefactor to 5.
set STEERINGMANAGER:yawtorquefactor to 5.
set STEERINGMANAGER:rolltorquefactor to 5.
set STEERINGMANAGER:MAXSTOPPINGTIME to 1. //default=2
LOCK thrott TO 0.
LOCK THROTTLE TO thrott.
set steering to prograde.
wait until abs(steeringmanager:yawerror) < 2 and abs(steeringmanager:pitcherror) < 2.
RCS ON.
SAS Off.
SET SHIP:CONTROL:FORE to -1. // Seperate from the upper stage
wait 5.
SET SHIP:CONTROL:FORE to 0.
RCS OFF.
wait until kuniverse:activevessel = vessel("Return Stage").
until stage:number = 0
{
	stage.
}
wait 10.
RCS ON.
set steering to retrograde.
wait until abs(steeringmanager:yawerror) < 2 and abs(steeringmanager:pitcherror) < 2.
until ship:periapsis < 1000 or ship:maxthrust = 0
{
	set thrott to 1.
}
set thrott to 0.
ParaLand().