clearscreen.
declare parameter orb.
declare parameter pdir.
function init_autofairing {
set auto_fairing_done to FALSE .
if not (defined ignore_autofairing) { global ignore_autofairing to false.}
 WHEN NOT auto_fairing_done AND NOT ignore_autofairing AND SHIP:ALTITUDE > (BODY:ATM:HEIGHT * 0.7)  THEN {
        FOR module IN SHIP:MODULESNAMED("ModuleProceduralFairing") {
            module:DOEVENT("deploy").
            HUDTEXT("Fairing Utility: Aproaching edge of atmosphere; Deploying Fairings", 3, 2, 30, YELLOW, FALSE).
        }.
        FOR module IN SHIP:MODULESNAMED("ProceduralFairingDecoupler") {
            module:DOEVENT("jettison").
            HUDTEXT("Fairing Utility: Approaching edge of atmosphere; Jettisoning Fairings", 3, 2, 30, YELLOW, FALSE).
        }.
        SET auto_fairing_done TO TRUE.
		set ignore_autofairing to TRUE.
    }
}.
function init_launch_autofunctions {
	init_autofairing().
	checkStages().
}
FUNCTION display{
	print "################ Flight Data v2.0 ################" at (0,1).
    print "       Now running as a function call!" at (0,2).
    print "       ALL ANGLES ARE IN DEGREES" at (5,4).
    set screenline to 6.
	print "Apoapsis height: " + round(apoapsis, 2) + "       " at (5,screenline).
	set screenline to screenline + 1.
	print "ETA to Apoapsis: " + round(ETA:APOAPSIS) + "       " at (5,screenline).
	set screenline to screenline + 1.
	print "Current Altitude: " + round(altitude, 2) + "       " at (5,screenline).
	set screenline to screenline + 1.
	set screenline to screenline + 1.
	print "Heading " + (dir) + "       " at (5,screenline).
	set screenline to screenline + 1.
	print "Target Pitch: " + round(targetPitch, 2) + "       " at (5,screenline).
	set screenline to screenline + 1.
	set screenline to screenline + 1.
	print "Throttle: " + (round(tset,2) * 100 ) + "       " at (5,screenline).
	set screenline to screenline + 1.
	print "Thrust: "+ round(tset * ship:availablethrust,2) + "       " at (5,screenline).
	set screenline to screenline + 1.
  print "Thrust to weight: " + round(((tset * availablethrust)/mass)/10,2) + "       " at (5,screenline).
	set screenline to screenline + 1.
	set screenline to screenline + 1.
	print "Vertical Spd: " + round(ship:VERTICALSPEED, 1) + "          " at (5,screenline).
  set screenline to screenline + 1.
  print "Ground Spd: " + round(ship:groundspeed, 1) + "          " at (5,screenline).
  set screenline to screenline + 1.
}
if pdir = 0 {
	set dir to "North".
}
if pdir = 90 {
	set dir to "East".
}
if pdir = 180 {
	set dir to "South".
}
if pdir = 270 {
	set dir to "West".
}
else{
	set dir to pdir.
}
//set vari
set targetPitch to 0.
lock throttle to tset.
set tset to 0.
set heregrav to body:mu / ((ship:altitude + body:radius)^2).
//Main
PRINT "Counting down:".
FROM {local countdown is 10.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
    WAIT 1.
}
lock steering to heading(90,90).
set tset to 1.
lock throttle to tset.
wait 1.
init_launch_autofunctions().
//This is new bit for mystaging & my autostaging
if ship:status = "PRELAUNCH" {
	clearscreen.
	print ship:status.
	stage.
	wait 1.
	clearscreen.
	if stage:resourceslex:haskey("SolidFuel") {
		set ignore_mystaging to false.
	}
	else{print "No solid fuel".}
	wait 3.
}
else{
	clearscreen.
	lock steering to heading(90,90).
	set tset to 1.
	wait 1.
	print "Are status is : " + ship:status.
}
clearscreen.
PRINT "Liftoff".
PRINT "At 1Km we will turn heading " + (dir) .
clearscreen.
UNTIL SHIP:APOAPSIS > orb {
	IF SHIP:ALTITUDE > 1000 {
    set targetPitch to max( 10, 90 * (1 - ALT:RADAR / (orb / 2))).
    lock steering to heading (pdir, targetPitch).
		wait 0.2.
    set m to ship:mass.
    set g to ship:body:mu / ship:body:position:mag ^ 2.
    set w to m * g.
    set p to ship:sensors:pres / 100.
    set t to ship:maxthrustat(p).
		if SHIP:ALTITUDE < (BODY:ATM:HEIGHT * 0.7) or SHIP:APOAPSIS > (orb * 0.90){
			set tset to (1.5 * w) / t.
		}
		if SHIP:ALTITUDE > (BODY:ATM:HEIGHT * 0.7) and SHIP:APOAPSIS < (orb * 0.90){
			set tset to (3 * w) / t.
		}
	}
  checkStages().
	display().
	set heregrav to body:mu / ((ship:altitude + body:radius)^2).
}
clearscreen.
PRINT (orb/1000)+"km apoapsis reached, cutting throttle".
set tset to 0.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
wait until SHIP:ALTITUDE > (BODY:ATM:HEIGHT * 0.8).
lock steering to prograde.
RTantenna("on").
wait 5.
panels on.
wait until SHIP:ALTITUDE > (BODY:ATM:HEIGHT * 1.1).
