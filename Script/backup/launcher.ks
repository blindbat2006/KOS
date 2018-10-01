function sane_steering 
{
	local did_something is false.
	if steeringmanager:RollControlAngleRange > 5 {
		set steeringmanager:RollControlAngleRange to 5.
		set did_something to true.
	}
	if steeringmanager:yawpid:Kp = 0 {
		set steeringmanager:yawpid:Kp to 1.
		set steeringmanager:yawpid:Ki to 0.0001.
		set steeringmanager:yawpid:Kd to 0.1.
		set did_something to true.
	}
	if steeringmanager:pitchpid:Kp = 0 {
		set steeringmanager:pitchpid:Kp to 1.
		set steeringmanager:pitchpid:Ki to 0.0001.
		set steeringmanager:pitchid:Kd to 0.1.
		set did_something to true.
	}
	if steeringmanager:rollpid:Kp = 0 {
		set steeringmanager:rollpid:Kp to 1.
		set steeringmanager:rollpid:Ki to 0.0001.
		set steeringmanager:rollpid:Kd to 0.1.
		set did_something to true.
	}
	if did_something {
		print "STEERINGMANAGER SETTINGS WERE NOT SANE.".
		print "JUST SET THEM TO SOMETHING THAT MAY WORK?".
	}
}
function sane_upward 
{
	print "THIS IS SANE_UPWARD:  VANG is " + VANG(ship:facing:vector, ship:up:vector).
	until VANG(ship:facing:vector, ship:up:vector) < 45 {
		hudtext( "PROBE ORIENTATION NOT UPWARD!! PLEASE FIX IT.", 2, 1, 25, white, true).
		getvoice(1):play(list(slidenote(400,500,0.5),slidenote(500,400,0.5))).
		wait 4.
	}
}
function stager 
{
  local did_stage is false.
  local stg_eList is LIST().

  // simple dumb - check if nothing active,
  // then stage:
  if ship:maxthrust = 0 {
    stage.
    set did_stage to true.
  } else {
    list engines in stg_eList.
    for stg_eng in stg_eList { 
      if stg_eng:name <> "sepMotor1" and stg_eng:tag <> "flameout no stage" and stg_eng:flameout {
        stage.
        set did_stage to true.
        break.
      }.
    }.
  }
  return did_stage.
}
function circularize 
{
	print "Circularizing.".
	lock steering to heading(compass_of_vel(ship:velocity:orbit), -(eta_ap_with_neg()/3)).
	print "..Waiting for steering to finish locking in place.".
	local vdraw is vecdraw(v(0,0,0), steering:vector*50, white, "waiting to point here", 1, true).
	wait until abs(steeringmanager:yawerror) < 2 and abs(steeringmanager:pitcherror) < 2 and abs(steeringmanager:rollerror) < 2.
	print "..Steering locked.  Now throttling.".
	set vdraw:show to false.
	lock throttle to 0.02 + (30*ship:obt:eccentricity).
	wait until ship:obt:trueanomaly < 90 or ship:obt:trueanomaly > 270.
	print "Done Circularlizing.".	
	unlock steering.
	unlock throttle.
}
FUNCTION display
{
	print "################ Flight Data v2.0 ################" at (0,1).
    print "       Now running as a function call!" at (0,2).
    print "       ALL ANGLES ARE IN DEGREES" at (5,4).
    LOCAL screenline to 6.
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
	print "Throttle: " + (round(thrott,2) * 100 ) + "       " at (5,screenline).
	set screenline to screenline + 1.
	print "Thrust: "+ round(thrott * ship:availablethrust,2) + "       " at (5,screenline).
	set screenline to screenline + 1.
	print "Thrust to weight: " + round(((thrott * availablethrust)/mass)/10,2) + "       " at (5,screenline).
	set screenline to screenline + 1.
	set screenline to screenline + 1.
	print "Vertical Spd: " + round(ship:VERTICALSPEED, 1) + "          " at (5,screenline).
	set screenline to screenline + 1.
	print "Ground Spd: " + round(ship:groundspeed, 1) + "          " at (5,screenline).
	set screenline to screenline + 1.
	set screenline to screenline + 1.
	print "Pressure: " + round(ship:q, 2) + "          " at (5,screenline).
	set screenline to screenline + 1.
	print "Gravity: " + round(g, 2) + "          " at (5,screenline).
}
function RTantennaON 
{
	FOR antenna IN SHIP:MODULESNAMED("ModuleRTAntenna") {
		IF antenna:HASEVENT("activate") {
			antenna:DOEVENT("activate").
		}
	}
}
function RTantennaOFF 
{
	FOR antenna IN SHIP:MODULESNAMED("ModuleRTAntenna") {
		IF antenna:HASEVENT("deactivate") {
			antenna:DOEVENT("deactivate").
		}
	}
}
function burn_seconds 
{
	parameter dv_mag.  // delta V magnitude (scalar)
	
	// Both force and mass are in 1000x units (kilo-),
	// so the 1000x multiplier cancels out:
	local F is SHIP:AVAILABLETHRUST.  // Force of burn.
	local m0 is SHIP:MASS. // starting mass
	local g0 is 9.802. 
	
	// IF no thrust, return bogus value until there is thrust.
	if F = 0 {
		if time:seconds > burn_seconds_msg_cooldown {
		clearscreen.
		getvoice(0):play(slidenote(250,300,1)).
		hudtext("NO ACTIVE ENGINE - CAN'T Calc BURN seconds", 2, 2, 20, white, true).
		set burn_seconds_msg_cooldown to time:seconds + 3.
		}
		return 0.
	} else if burn_seconds_msg_cooldown > 0 { // clear the message if we had been showing it.
		set burn_seconds_msg_cooldown to 0.
		clearscreen.
	}
	
	// The ISP of first engine found active:
	// (For more accuracy with multiple differing engines,
	// some kind of weighted average would be needed.)
	SET ISP TO isp_calc().
	
	// From rocket equation, and definition of ISP:
	return (g0*ISP*m0/F)*( 1 - e^(-dv_mag/(g0*ISP)) ).
}
function isp_calc 
{    
	LOCAL engineList is LIST().
	LIST ENGINES IN engineList.
	LOCAL totalFlow IS 0.
	LOCAL totalThrust IS 0.
	FOR engine IN engineList {
		IF engine:IGNITION AND NOT engine:FLAMEOUT {
		// the 9.802 term is wrong?: SET totalFlow TO totalFlow + (engine:AVAILABLETHRUST / (engine:ISP * 9.802)).
		SET totalFlow TO totalFlow + (engine:AVAILABLETHRUST / engine:ISP).
		SET totalThrust TO totalThrust + engine:AVAILABLETHRUST.
		}
	}
	IF MAXTHRUST = 0 {
		SET totalThrust TO 1.
		SET totalFlow TO 1.
	}
    RETURN (totalThrust / totalFlow).
}
function compass_of_vel 
{
	parameter pointing. // ship:velocity:orbit or ship:velocity:surface
	local east is east_for(ship).
	
	local trig_x is vdot(ship:north:vector, pointing).
	local trig_y is vdot(east, pointing).
	
	local result is arctan2(trig_y, trig_x).
	
	if result < 0 { 
		return 360 + result.
	} else {
		return result.
	}
}
function east_for 
{
	parameter ves.
	return vcrs(ves:up:vector, ves:north:vector).
}
function eta_ap_with_neg 
{
	local ret_val is eta:apoapsis.
	if ret_val > ship:obt:period / 2 {
		set ret_val to ret_val - ship:obt:period.
	}
	return ret_val.
}

parameter dest_compass.
parameter first_dest_ap.
parameter do_circ is true.
parameter second_dest_ap is -1. // second destination apoapsis.
parameter second_dest_long is -1. // second destination longitude.
parameter atmo_end is ship:body:atm:height.

SAS off.
LOCK dir to dest_compass.
if second_dest_ap < 0 { set second_dest_ap to first_dest_ap. }
LOCK thrott to 1.
lock throttle to thrott.
LOCK all_fairings TO ship:modulesnamed("ModuleProceduralFairing").
LOCK fairings TO LIST().
for f_mod in all_fairings {
	if f_mod:hasevent("deploy") 
	{
		if f_mod:part:tag:contains("manual") {
			print "Will *NOT* Deploy fairing part: " + f_mod:part:name.
		} else {
			fairings:add(f_mod).
		}
	}
}
if fairings:length > 0 {
	print fairings:length + " Part(s) needing fairing deployment found.".
	print "Will engage fairings at high altitude.".
}
sane_steering().
sane_upward().
LOCK alt_divisor TO atmo_end*(6.0/7.0).
wait 1.
SET count TO 5.
until count = 0 {
  hudtext("T minus " + count + "s", 2, 2, 45, yellow, true).
  wait 1.
  set count to count - 1.
}.
stager().
hudtext("Launch!", 2, 2, 50, yellow, true).
LOCK m to ship:mass.
LOCK g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
LOCK w to m * g.
//LOCK p to ship:sensors:pres / 100.
LOCK t to ship:maxthrustat(ship:q).
LOCK low_atmo_pending TO true.
SET targetPitch To 0.
SET burn_seconds_msg_cooldown TO 0.
SET e to constant():e.
SET pi to constant():pi.

if atmo_end = 0 {
	set alt_divisor to first_dest_ap / 3.
}
if ship:body = "Kerbin"
{	
	until SHIP:ALTITUDE > 1000
	{
		lock steering to heading(90,90).
		wait 0.1.
	}
}
else
{
	until alt:radar > 200
	{
		lock steering to heading(90,90).
		wait 0.1.
	}
	BRAKES off.
	GEAR off.
}
clearscreen.
until ship:apoapsis > first_dest_ap 
{
	display().
	LOCAL englist to LIST().
	list engines in englist.
	local flameout is false.
	for eng in englist {
		if eng:name <> "sepMotor1" and eng:tag <> "flameout no stage" and eng:flameout {
			set flameout to true. 
		}
	}
	if low_atmo_pending and ship:Q < 0.003 and ship:altitude > atmo_end/2 
	{
		set low_atmo_pending to false. // Never execute this again.
		wait 0.
		if fairings:length > 0 {
		for fairing in fairings 
		{
			if fairing:hasevent("deploy") 
			{
				print "!!Deploying a fairing part!!".
				fairing:doevent("deploy").
			}
		}
		set fairings to LIST().  // Make it empty so it won't re-trigger this.
		}
	} 
	else if stage:ready and (flameout or maxthrust = 0) 
	{
		stage.
		steeringmanager:resetpids().
	}
	set m to ship:mass.
	SET g to constant:g * body:mass / body:radius^2.
	set w to m * g.
	set t to ship:maxthrustat(ship:q).
	if SHIP:ALTITUDE < (BODY:ATM:HEIGHT * 0.7) or SHIP:APOAPSIS > (first_dest_ap * 0.90)
	{
		set thrott to (1.5 * w) / t.
	}
	if SHIP:ALTITUDE > (BODY:ATM:HEIGHT * 0.7) and SHIP:APOAPSIS < (first_dest_ap * 0.90)
	{
		set thrott to (3 * w) / t.
	}
	SET targetPitch to max( 20, 90 * (1 - ALT:RADAR / (first_dest_ap / 2))).
	lock steering to heading (dest_compass, targetPitch).
	wait 0.1.
}
SET targetPitch To 0.
clearscreen.
print "Apoapsis now " + first_dest_ap + ".".
print "Going into low thrust to just maintain Ap.".
lock throttle to (first_dest_ap - ship:apoapsis) / 5000.
wait until ship:altitude > atmo_end.
set steeringmanager:pitchtorquefactor to 1.
set steeringmanager:yawtorquefactor to 1.
print "Coasting to Ap.".
lock throttle to 0.
RTantennaON().
PANELS on.
lock steering to heading(compass_of_vel(ship:velocity:orbit), 0).
local V_ap_have is velocityAt(ship, eta:apoapsis + time:seconds):orbit:mag.
local V_ap_want is sqrt(ship:body:mu / ship:body:radius + ship:apoapsis).
local halfCircTime is burn_seconds((V_ap_want-V_ap_have) / 2).
print "Circ burn will start at ETA:Apoapais = "+ round(halfCircTime,1) + "s".
wait until eta:apoapsis < halfCircTime.
if do_circ {
	circularize().
} else {
	print "Circularization not requested.".
}
lights on.
if second_dest_long >= 0 {
	lock steering to prograde.
	print "Waiting for second destination burn start longitude.".
	until abs(ship:longitude - second_dest_long) < 1 {
	print "current long = " + round(ship:longitude,3) + ", desired long = " + round(second_dest_long,3) + "    " at (0,0).
	wait 0.001.
	}
	print "Now starting second destination burn.".
	lock throttle to 0.01 + (second_dest_ap - ship:apoapsis) / 5000.
	print "Now waiting for apoapsis to reach " + second_dest_ap.
	wait until ship:apoapsis >= second_dest_ap.
	print "Now re-circularizing at the new apoapsis...".
	circularize().
}


set staging_on to false.
wait 0.01. // make sure there's one run through the trigger to unpreserve it.
clearscreen.
SAS OFF.
RCS ON.
LOCK STEERING TO SUN:position.
wait until abs(steeringmanager:yawerror) < 2 and abs(steeringmanager:pitcherror) < 2 and abs(steeringmanager:rollerror) < 1.
RCS OFF.
wait 5.