@LAZYGLOBAL OFF.
GLOBAL sn to ship:name.
GLOBAL atmToDens to 1.2230948554874 .
GLOBAL e to constant():e.
GLOBAL pi to constant():pi.
GLOBAL g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
GLOBAL gConst to constant():g.
GLOBAL bigNum to 10.0^35. 
GLOBAL nearZero to 10.0^(-35).
GLOBAL burn_seconds_msg_cooldown is 0.
GLOBAL dport is 0.
GLOBAL clamp_pitch_cooldown is 0.
GLOBAL thrott to 0.
GLOBAL looping TO 0.
GLOBAL RCD to false.
GLOBAL RCA to false.
GLOBAL targetPitch IS 0.
GLOBAL steeringDir TO 90.
GLOBAL dest_compass TO 0.
GLOBAL dir TO 0.
GLOBAL shipPitch TO 90.
GLOBAL genoutputmessage TO "".
GLOBAL LandTarget TO Kerbin:GEOPOSITIONLATLNG(-0.1165805,-74.5463040).
GLOBAL steeringPitch TO 90.	
GLOBAL geoDist TO 0.
GLOBAL orbitAngle TO 0.
GLOBAL targetDir TO 0.
GLOBAL impactDist TO 0.
GLOBAL distAltToStartBreak TO 90.
GLOBAL step TO "end".
GLOBAL LandAltitude TO 115.
GLOBAL hoverPID TO PIDLOOP(1, 0.01, 0.0, -50, 50). 
GLOBAL climbPID TO PIDLOOP(0.1, 0.3, 0.005, 0, 1). 
GLOBAL eastVelPID TO PIDLOOP(3, 0.01, 0.0, -20, 20).
GLOBAL northVelPID TO PIDLOOP(3, 0.01, 0.0, -20, 20). 
GLOBAL eastPosPID TO PIDLOOP(1700, 0, 100, -40,40).
GLOBAL northPosPID TO PIDLOOP(1700, 0, 100, -40,40).
GLOBAL distAltitude TO 0.
GLOBAL maxDescendSpeed TO 0.
GLOBAL MaxHorizSpeed TO 0.
GLOBAL MaxSteerAngle TO 0.
GLOBAL terrainAlt TO SHIP:ALTITUDE-ALT:RADAR.
GLOBAL radarOffset to 0.	 				// The value of alt:radar when landed (on gear)
GLOBAL trueRadar to alt:radar - (radarOffset*2).			// Offset radar to get distance from gear to ground
GLOBAL maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
GLOBAL stopDist to ((ship:verticalspeed^2 / (2 * maxDecel)) + ship:groundspeed).		// The distance the burn will require
GLOBAL impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
GLOBAL staging_on is true.
GLOBAL debugall to false.
GLOBAL posCur to ship:geoposition.
GLOBAL impPosFut to ship:geoposition.
GLOBAL vec1 is 0.
GLOBAL vec2 is 0.
GLOBAL vec3 is 0.
GLOBAL angL is 0.
GLOBAL axis is 0.
GLOBAL ui_announce is 0.
GLOBAL ui_announceMsg is "".
GLOBAL ui_debug     is true.  // Debug messages on console and screen
GLOBAL ui_debugNode is true. // Explain node planning
GLOBAL ui_debugAxes is false. // Explain 3-axis navigation e.g. docking
GLOBAL logconsole   is false. //Save console to log.txt / 0:/<CRAFT NAME>.txt
GLOBAL ui_DebugStb is vecdraw(v(0,0,0), v(0,0,0), GREEN, "Stb", 1, false).
GLOBAL ui_DebugUp is vecdraw(v(0,0,0), v(0,0,0), BLUE, "Up", 1, false).
GLOBAL ui_DebugFwd is vecdraw(v(0,0,0), v(0,0,0), RED, "Fwd", 1, false).
GLOBAL ui_myPort is vecdraw(v(0,0,0), v(0,0,0), YELLOW, "Ship", 1, false).
GLOBAL ui_hisPort is vecdraw(v(0,0,0), v(0,0,0), PURPLE, "Dock", 1, false).
GLOBAL LandingSite is "PAD1".

if not (defined stagingConsumed)
{
	global stagingConsumed is list("SolidFuel", "LiquidFuel", "Oxidizer").
}
if not (defined stagingTankFuels)
{
	global stagingTankFuels is list("SolidFuel", "LiquidFuel"). //Oxidizer intentionally not included (would need extra logic)
}
if not (defined stagingDecouplerModules)
{
	global stagingDecouplerModules is list("ModuleDecouple", "ModuleAnchoredDecoupler").
}
if not (defined isp_g0)
{
	global isp_g0 is kerbin:mu/kerbin:radius^2. // exactly 9.81 in KSP 1.3.1, 9.80665 for Earth
}
global stagingNumber	is -1.		// stage:number when last calling stagingPrepare()
global stagingMaxStage	is 0.		// stop staging if stage:number is lower or same as this
global stagingResetMax	is true.	// reset stagingMaxStage to 0 if we passed it (search for next "noauto")
global stagingEngines	is list().	// list of engines that all need to flameout to stage
global stagingTanks		is list().	// list of tanks that all need to be empty to stage
global stageAvgIsp		is 0.		// average ISP in seconds
global stageStdIsp		is 0.		// average ISP in N*s/kg (stageAvgIsp*isp_g0)
global stageDryMass		is 0.		// dry mass just before staging
global stageBurnTime	is 0.		// updated in stageDeltaV()

//GLOBAL steerDir to 0.
GLOBAL accel TO 0.
GLOBAL vel to 0.
GLOBAL velR to 0.
GLOBAL velT to 0.
GLOBAL geo_diff is v(0,0,0).
// Constant docking parameters
global dock_scale is 25.   // alignment speed scaling factor (m)
global dock_start is 30.   // ideal start distance (m) & approach speed scaling factor
global dock_final is 1.    // final-approach distance (m)
global dock_algnV is 2.5.  // max alignment speed (m/s)
global dock_apchV is 1.    // max approach speed (m/s)
global dock_dockV is 0.1.  // final approach speed (m/s)
global dock_predV is 0.01. // pre dock speed (m/s)
//global dock_Z is pidloop(1.4, 0, 0.4, -1, 1).
// Velocity controllers (during alignment)
global dock_X1 is pidloop(1.4, 0, 0.4, -1, 1).
global dock_Y1 is pidloop(1.4, 0, 0.4, -1, 1).
// Position controllers (during approach)
global dock_X2 is pidloop(0.4, 0, 1.2, -1, 1).
global dock_Y2 is pidloop(0.4, 0, 1.2, -1, 1).
// Shared velocity controller
global dock_Z is pidloop(1.4, 0.2, 0.4, -1, 1).

function updateReadouts
{
	print "Step: "+step+"          " AT(0,0).
	print "Steering Direction = "+round(steeringDir,3)+"          " AT(0,2).
	print "Pitch = "+round(shipPitch,3)+"          " AT(0,3).
	print "Ground speed = "+round(SHIP:GROUNDSPEED,3)+"          " AT(0,4).
	print genoutputmessage+"                           " AT(0,6).
}
function setHoverPIDLOOPS
{
	//Controls altitude by changing climbPID setpoint
	SET hoverPID TO PIDLOOP(1, 0.01, 0.0, -50, 50). 
	//Controls vertical speed
	SET climbPID TO PIDLOOP(0.1, 0.3, 0.005, 0, 1). 
	//Controls horizontal speed by tilting rocket
	SET eastVelPID TO PIDLOOP(3, 0.01, 0.0, -20, 20).
	SET northVelPID TO PIDLOOP(3, 0.01, 0.0, -20, 20). 
	//controls horizontal position by changing velPID setpoints
	SET eastPosPID TO PIDLOOP(1700, 0, 100, -40,40).
	SET northPosPID TO PIDLOOP(1700, 0, 100, -40,40).
}
function sProj 
{ //Scalar projection of two vectors.
	parameter a.
	parameter b.
	if b:mag = 0 { PRINT "sProj: Divide by 0. Returning 1". RETURN 1. }
	RETURN VDOT(a, b) * (1/b:MAG).
}
function cVel 
{
	local v IS SHIP:VELOCITY:SURFACE.
	local eVect is VCRS(UP:VECTOR, NORTH:VECTOR).
	local eComp IS sProj(v, eVect).
	local nComp IS sProj(v, NORTH:VECTOR).
	local uComp IS sProj(v, UP:VECTOR).
	RETURN V(eComp, uComp, nComp).
}
function updateHoverSteering
{
	LOCAL cVelLast TO cVel().
	SET eastVelPID:SETPOINT TO eastPosPID:UPDATE(TIME:SECONDS, SHIP:GEOPOSITION:LNG).
	SET northVelPID:SETPOINT TO northPosPID:UPDATE(TIME:SECONDS,SHIP:GEOPOSITION:LAT).
	//SET eastVelPID:SETPOINT TO eastPosPID:UPDATE(TIME:SECONDS, ADDONS:TR:IMPACTPOS:LNG).
	//SET northVelPID:SETPOINT TO northPosPID:UPDATE(TIME:SECONDS,ADDONS:TR:IMPACTPOS:LAT).
	LOCAL eastVelPIDOut IS eastVelPID:UPDATE(TIME:SECONDS, cVelLast:X).
	LOCAL northVelPIDOut IS northVelPID:UPDATE(TIME:SECONDS, cVelLast:Z).
	LOCAL eastPlusNorth is MAX(ABS(eastVelPIDOut), ABS(northVelPIDOut)).
	SET steeringPitch TO 90 - eastPlusNorth.
	LOCAL steeringDirNonNorm IS ARCTAN2(eastVelPID:OUTPUT, northVelPID:OUTPUT). //might be negative
	if steeringDirNonNorm >= 0 {
		SET steeringDir TO steeringDirNonNorm.
	} else {
		SET steeringDir TO 360 + steeringDirNonNorm.
	}
	LOCK STEERING TO HEADING(steeringDir,steeringPitch).
}
function setHoverTarget
{
	parameter lat.
	parameter lng.
	SET eastPosPID:SETPOINT TO lng.
	SET northPosPID:SETPOINT TO lat.
}
function setHoverAltitude
{ //set just below landing altitude to touchdown smoothly
	parameter a.
	SET hoverPID:SETPOINT TO a.
}
function setHoverDescendSpeed
{
	parameter a.
	SET hoverPID:MAXOUTPUT TO a.
	SET hoverPID:MINOUTPUT TO -1*a.
	SET climbPID:SETPOINT TO hoverPID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE). //control descent speed with throttle
	SET thrott TO climbPID:UPDATE(TIME:SECONDS, SHIP:VERTICALSPEED).	
}
function setHoverMaxSteerAngle
{
	parameter a.
	SET eastVelPID:MAXOUTPUT TO a.
	SET eastVelPID:MINOUTPUT TO -1*a.
	SET northVelPID:MAXOUTPUT TO a.
	SET northVelPID:MINOUTPUT TO -1*a.
}
function setHoverMaxHorizSpeed
{
	parameter a.
	set eastPosPID:MAXOUTPUT TO a.
	set eastPosPID:MINOUTPUT TO -1*a.
	set northPosPID:MAXOUTPUT TO a.
	set northPosPID:MINOUTPUT TO -1*a.
}
function setThrottleSensitivity
{
	parameter a.
	SET climbPID:KP TO a.
}
function calcDistance 
{ //Approx in meters
	parameter geo1.
	parameter geo2.
	return (geo1:POSITION - geo2:POSITION):MAG.
}
function geoDir 
{
	parameter geo1.
	parameter geo2.
	return ARCTAN2(geo1:LNG - geo2:LNG, geo1:LAT - geo2:LAT).
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
function tts 
{
	clearscreen.
	SAS off.
	LOCAL result to 0.
	LOCAL done to 0.
	LOCAL sp to sun:position.
	lock steering to sp.
	wait until abs(steeringmanager:yawerror) < 2 and abs(steeringmanager:pitcherror) < 2 and abs(steeringmanager:rollerror) < 2.
	LOCAL NoSolList TO LIST().
	LOCAL SolList TO LIST().
	LOCAL partList TO LIST().
	list parts in partList.
	for parts in partList {
	  for module in parts:modules {
	    if module = "ModuleDeployableSolarPanel" {
			SolList:add(parts).
	    }
	    else{
	       NoSolList:add(parts).
	    }
	   }
	}
	LOCAL bx to SolList[0]:GETMODULE("ModuleDeployableSolarPanel"):GETFIELD("status").
	clearscreen.
	if bx = "Direct Sunlight" 
	{
		LOCAL result to SolList[0]:GETMODULE("ModuleDeployableSolarPanel"):GETFIELD("sun exposure").
		print "Sun Exposure: " + round (result * 100, 2) + "%".
	}
	else 
	{
		print "We are being blocked or".
		print "the solar panels are retracted".
	}
	print "Unlocking steering".
	unlock steering.
}

function launcher 
{
	parameter dest_compass.
	parameter first_dest_ap.
	parameter do_circ is true.
	parameter second_dest_ap is -1. // second destination apoapsis.
	parameter second_dest_long is -1. // second destination longitude.
	parameter atmo_end is ship:body:atm:height.

	SAS OFF.
	RCS ON.
	set dir to dest_compass.
	
	if second_dest_ap < 0 { set second_dest_ap to first_dest_ap. }
	local all_fairings is ship:modulesnamed("ModuleProceduralFairing").
	local fairings is LIST().
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
	local alt_divisor is atmo_end*(6.0/7.0).
	wait 1.
	SET e to constant():e.
	SET pi to constant():pi.
	set g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
	LOCAL m to ship:mass.
	LOCAL w to m * g.
	LOCAL t to ship:maxthrustat(ship:q).
	local low_atmo_pending is true.
	if atmo_end = 0 
	{
		set alt_divisor to first_dest_ap / 3.
	}
	clearscreen.
	LOCAL count is 5.
	until count = 0 {
	hudtext("T minus " + count + "s", 2, 2, 45, yellow, true).
	wait 1.
	set count to count - 1.
	}.
	hudtext("Launch!", 2, 2, 50, yellow, true).
	LOCK thrott to 1.
	lock throttle to thrott.
	lock steering to r(up:pitch,up:yaw,facing:roll).
	stager().
	until SHIP:ALTITUDE > 1000 and SHIP:VERTICALSPEED > 100
	{
		lock steering to ship:facing.
		wait 0.1.
		
		if BRAKES {BRAKES OFF.}
		if GEAR {GEAR OFF.}
		clearscreen.
	}
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
		SET m to ship:mass.
		SET g to constant:g * body:mass / body:radius^2.
		SET w to m * g.
		SET t to ship:maxthrustat(ship:q).
		if SHIP:ALTITUDE < (BODY:ATM:HEIGHT * 0.7) or SHIP:APOAPSIS > (first_dest_ap * 0.90)
		{
			set thrott to max(0,(1.5 * w) / t).
		}
		if SHIP:ALTITUDE > (BODY:ATM:HEIGHT * 0.7) and SHIP:APOAPSIS < (first_dest_ap * 0.90)
		{
			set thrott to max(0,(3 * w) / t).
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
	UNLOCK STEERING.
	wait 1.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}
FUNCTION ParaLand
{
	clearscreen.
	PRINT "Waiting until under 70000".
	set RCD to false.
	set RCA to false.
	set looping TO TRUE.
	LOCK thrott TO 0.
	LOCK THROTTLE TO thrott.
	wait until ship:altitude < 70000.
	set LandTarget TO Kerbin:GEOPOSITIONLATLNG(-0.1165805,-74.5463040).
	set STEERING TO SRFRETROGRADE.
	PANELS OFF.
	BAYS OFF.
	LADDERS OFF.
	GEAR OFF.
	RADIATORS OFF.
	LEGS OFF.
	LIGHTS OFF.
	clearscreen.
	UNTIL looping = false
	{
		if (SHIP:ALTITUDE > 10000) and (SHIP:ALTITUDE < 35000) 
		{
			when (ship:q > 0.34) then 
			{
				for m in ship:modulesnamed("ModuleAnimateGeneric") {
					if m:hasevent("deploy fins") m:doevent("deploy fins").
				}
				brakes on.
			}
			if SHIP:AIRSPEED > 1450 {set thrott to thrott + 0.01.}else{set thrott to 0.}
		}
		if (SHIP:ALTITUDE < 10000) and (SHIP:ALTITUDE > 5000)
		{
			if (SHIP:AIRSPEED < 400) and (SHIP:AIRSPEED > 250) and (RCD = false)
			{
				chutedeploy().
				set RCD to true.
			}
		}
		if (SHIP:ALTITUDE < 5000) and (ALT:RADAR > 2000)
		{
			until stage:number = 1
			{
				stage.
				wait 3.
			}
			chutearm().
			lock steering to r(up:pitch,up:yaw,facing:roll).
		}
		if SHIP:AIRSPEED < 250 and ALT:RADAR < 2000 and (RCA = false)
		{
			chutedeploy().
			set RCA to true.
			SET STEERING TO UP.
			SAS OFF.
			BRAKES ON.
			LEGS ON.
			LIGHTS ON.
		}
		if (ship:status = "Landed" or ship:status = "Splashed")
		{
			lock steering to r(up:pitch,up:yaw,facing:roll).
			WAIT 5.
			UNLOCK STEERING.
			wait 1.
			SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
			WAIT 1.
			RCS OFF.
			WAIT 1.
			SAS ON.
			SET looping TO false.
		}
		if (partsPercentEC() < 2)
		{
			chutearm().
			chutedeploy().
			SET STEERING TO UP.
		}
		
		//SET impactDist TO calcDistance(LandTarget, ship:geoposition).
		print "Current Altitude: " + round(altitude, 2) + "       " AT (0,0).
		print "Vertical Spd: " + round(ship:VERTICALSPEED, 1) + "          " AT (0,1).
		print "Ground Spd: " + round(ship:groundspeed, 1) + "          " AT (0,2).
		print "Pressure: " + round(ship:q, 2) + "          " AT (0,3).
		print "Gravity: " + round(g, 2) + "          " AT (0,4).
		print "Impact dist from target: "+ROUND(calcDistance(LandTarget, ship:geoposition),2) AT(0,6).
		SET STEERING TO SRFRETROGRADE.
		wait 0.01.
	}
}
FUNCTION dumbland
{
	parameter step.

	clearscreen.
	SET RCD to false.
	SET RCA to false.
	LOCK thrott TO 0.
	LOCK THROTTLE TO thrott.
	SET genoutputmessage TO "".
	SET orbitAngle TO 0.
	if ADDONS:TR:HASIMPACT 
	{
		ADDONS:TR:SETTARGET(LandTarget).
	}
	SAS OFF.
	LOCK STEERING TO SHIP:RETROGRADE.
	lock steeringdir to 0.
	lock shippitch to 0.
	set LandTarget TO Kerbin:GEOPOSITIONLATLNG(-0.1165805,-74.5463040).
	set looping TO TRUE.
	UNTIL looping = false 
	{
		
		updateReadouts().
		if (stage:ready) and (maxthrust = 0)
		{
			LOCK STEERING TO SHIP:RETROGRADE.
			SET step to "ParaLand".
		}
		if (SHIP:ALTITUDE > 70000) and (SHIP:ALTITUDE < 71000)
		{
			RTantennaOFF().
			LIGHTS OFF.
			BRAKES OFF.
			GEAR OFF.
		}
		
		if(step="Return")
		{
			RCS ON.
			SAS off.
			LOCK STEERING TO SHIP:RETROGRADE.
			SET step TO "ReturnTurn".
		}
		
		if(step="ReturnTurn")
		{
			SET orbitAngle TO VANG(SHIP:PROGRADE:VECTOR, LandTarget:POSITION). // point prograde
			
			LOCK geoDist TO calcDistance(LandTarget, SHIP:GEOPOSITION).
			SET kuniverse:timewarp:mode to "RAILS".
			SET kuniverse:timewarp:warp to 4.
			SET genoutputmessage TO "KSC Distance: "+CEILING(geoDist)+", angToKSC: "+CEILING(orbitAngle).
			if(geoDist<900000 AND geoDist>800000 and orbitAngle<55)
			{
				SET kuniverse:timewarp:warp to 0.
				until kuniverse:timewarp:issettled 
				{
					wait 1.
				}
				SET step TO "RetroBurnWait".		
			}
			//updateReadouts().
		}
	
		if(step="RetroBurnWait")
		{
			LOCK STEERING TO SHIP:RETROGRADE.
			wait 5.
			wait until abs(steeringmanager:yawerror) < 2 and abs(steeringmanager:pitcherror) < 2 and abs(steeringmanager:rollerror) < 2.
			RCS ON.
			SET geoDist TO calcDistance(LandTarget, SHIP:GEOPOSITION).
			if(geoDist<700000){	
				SET thrott TO 1.
				
				until(ADDONS:TR:HASIMPACT)
				{ 
					wait 0.2.
				}
				WAIT 0.2.
				SET step TO "ReentryBurn".			
			}
			SET genoutputmessage TO "KSC Distance: "+CEILING(geoDist).
		}
		
		if(step="ReentryBurn")
		{
			ADDONS:TR:SETTARGET(LandTarget).
			LOCK targetDir TO geoDir(ADDONS:TR:IMPACTPOS, LandTarget).
			LOCK impactDist TO calcDistance(LandTarget, ADDONS:TR:IMPACTPOS).
			LOCK steeringDir TO targetDir - 180.
			LOCK STEERING TO HEADING(steeringDir,0).
			if(impactDist > 100000){
				SET thrott TO (thrott + 0.01).
			}
			if(impactDist < 100000 and impactDist > 50000){
				SET thrott TO 0.5.
			}
			if(impactDist < 30000){
				SET thrott TO 0.
				SET step TO "Reentry".
			}
			SET genoutputmessage TO "Impact dist: "+CEILING(impactDist).
		}
		
		if(step="Reentry")
		{
			SET geoDist TO calcDistance(LandTarget, SHIP:GEOPOSITION).
			SET targetDir TO geoDir(ADDONS:TR:IMPACTPOS, LandTarget).
			SET impactDist TO calcDistance(LandTarget, ADDONS:TR:IMPACTPOS).
			SET steeringDir TO targetDir - 180.
			set shipPitch TO max(10, 90 * (1 - ALT:RADAR / (100000 / 2))).
			
			if(SHIP:ALTITUDE<30000)
			{
				if (SHIP:GROUNDSPEED > 1350 and impactDist > 20000)
				{
					SET STEERING TO HEADING(steeringDir,0).
					SET thrott TO (thrott + 0.01).
				}else if (SHIP:GROUNDSPEED > 1350 and impactDist < 20000 and impactDist > 10000)
				{
					SET STEERING TO HEADING(steeringDir,shipPitch).
					SET thrott TO 0.5.					
				}else if (SHIP:GROUNDSPEED > 1350 and impactDist < 10000 and impactDist > 5000)
				{
					SET STEERING TO HEADING(steeringDir,shipPitch).
					SET thrott TO 0.3.
				}
				else if (SHIP:GROUNDSPEED < 1350)
				{
					SET STEERING TO HEADING(steeringDir,shipPitch).
					SET thrott TO 0.
					SET step TO "LandBurn".
				}
			}else
			{
				SET thrott TO 0.
			}
			
			SET genoutputmessage TO "Impact from target: "+CEILING(impactDist).
		}	
		
		if(step="LandBurn")
		{
			SET targetDir TO geoDir(ADDONS:TR:IMPACTPOS, LandTarget).
			SET impactDist TO calcDistance(LandTarget, ADDONS:TR:IMPACTPOS).
			SET steeringDir TO targetDir - 180.
			set shipPitch TO max(10, 90 * (1 - ALT:RADAR / (100000 / 2))).
			SET STEERING TO HEADING(steeringDir,shipPitch).
			RCS ON.
			if(impactDist<4000){ //overshoot just a little
				SET thrott TO 0.
				SET STEERING TO SHIP:RETROGRADE.
				SET step TO "ParaLand".
			}else if(impactDist>4000 and impactDist < 5000){
				SET thrott TO 0.5.
			}else{
				SET thrott TO (thrott + 0.01).
			}
			
			SET genoutputmessage TO "Impact dist from target: "+ROUND(impactDist,2).
		}
		
		if(step="ParaLand")
		{
			ParaLand().
			SET step TO "end".
		}
		if(step="end")
		{
			SET looping TO false.
		}		
	}
	clearscreen.
	print ship:status.
	RTantennaON().
}
FUNCTION powerland
{
	RCS ON.
	SAS OFF.
	LOCK thrott TO 0.
	LOCK THROTTLE TO thrott.
	lock steering to srfretrograde.
	wait until abs(steeringmanager:yawerror) < 3 and abs(steeringmanager:pitcherror) < 3 and abs(steeringmanager:rollerror) < 3.
	SET radarOffset to 10.
	setHoverPIDLOOPS().
	SET MaxHorizSpeed TO 0.
	SET MaxSteerAngle TO 35.
	setHoverMaxSteerAngle(MaxSteerAngle).
	setHoverMaxHorizSpeed(MaxHorizSpeed).
	until ship:groundspeed < 30
	{
		SET thrott to 1.
		LOCK STEERING TO VXCL(UP:VECTOR, -VELOCITY:SURFACE).
	}
	SET thrott to 0.
	Print "20 Secs to prep for Landing".
	wait 15.
	Print "Land prep locked in. EDL begins in 5 secs".
	wait 5.
	LIGHTS ON.
	clearscreen.
	print "Land Phase".
	//RTantennaOFF().
	lock steering to srfretrograde.
	set looping to true.
	UNTIL looping = false
	{
		if trueRadar < stopDist 
		{
			clearscreen.
			set looping to false.
		}
		else
		{
			SET g to constant:g * body:mass / body:radius^2.
			SET trueRadar to (landRadarAltimeter() - radarOffset).
			SET maxDecel to ((ship:AVAILABLETHRUST) / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
			SET stopDist to ((ship:verticalspeed^2 / (2 * maxDecel)) + ship:groundspeed).		// The distance the burn will require
			SET impactTime to trueRadar / abs(ship:verticalspeed).	
			
			clearscreen.
			print "True Radar " + trueRadar at (0,0).
			print "Max Decel " + maxDecel at (0,1).
			print "Stop Dist " + stopDist at (0,2).
			print "Impact Time " + impactTime at (0,3).
			
			if trueRadar < (stopDist + 200) and ship:groundspeed > 10
			{
				set thrott TO (ship:groundspeed/100).
			}else
			{
				set thrott TO 0.
				setHoverDescendSpeed(350).
			}
		}
		wait 0.1.
	}
	UNTIL (ship:status = "Landed" or ship:status = "Splashed")
	{
		clearscreen.
		if alt:radar < 200 {BRAKES ON.GEAR ON.}
		set maxDescendSpeed TO MAX(5,sqrt(landRadarAltimeter() - radarOffset)).
		setHoverDescendSpeed(maxDescendSpeed).
		print maxDescendSpeed.
		if ship:groundspeed < 3
		{
			setHoverAltitude((landRadarAltimeter()) - radarOffset).
			lock steering to r(up:pitch,up:yaw,facing:roll).
		}
		else
		{
			lock steering to srfretrograde.
			setHoverAltitude((landRadarAltimeter()) +30).
		}
		
		wait 0.1.
	}
	SET thrott TO 0.
	lock steering to r(up:pitch,up:yaw,facing:roll).
	WAIT 5.
	UNLOCK STEERING.
	wait 1.
	BRAKES off.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	WAIT 1.
	SAS ON.
	RCS OFF.
	WAIT 1.
	RTantennaON().
	CLEARSCREEN.
}
FUNCTION dock
{
	/////////////////////////////////////////////////////////////////////////////
	// Dock
	/////////////////////////////////////////////////////////////////////////////
	// Docks with the target.
	//
	// Chooses an arbitrary docking port on the vessel, then finds a compatible
	// port on the target (or uses the selected port if a port is already
	// selected).
	//
	// Once a port is chosen, moves the docking ports into alignment and then
	// approaches at a slow speed.
	/////////////////////////////////////////////////////////////////////////////
	parameter dport is 0.
	PANELS off.
	Print "Engines shutting down".
	LOCAL englist to LIST().
	list engines in englist.
	FOR eng IN englist
	{ // loop through the engines
		IF eng:STAGE = stage:number { // compare engine's stage to current stage
			eng:shutdown. // tell it to git fugged
		}
	}
	wait 3.	
	if not dport = 0 {set target to target:PARTSDUBBED(dport)[0].}	
	local DockingDone is False.
	local MaxDistanceToApproach is 5000.
	local TargetVessel is 0.
	if hastarget and target:istype("Vessel") set TargetVessel to Target.
	else if hastarget and target:istype("DockingPort") set TargetVessel to target:ship.
	until DockingDone 
	{
	
		if hastarget and ship:status = "ORBITING" and TargetVessel:Distance < KUNIVERSE:DEFAULTLOADDISTANCE:ORBIT:UNPACK 
		{
			global dock_myPort is dockChoosePorts().
			global dock_hisPort is target.
			if dock_myPort <> 0 
			{	
				global dock_station is dock_hisPort:ship.
				uiBanner("Dock", "Dock with " + dock_station:name).
				dockPrepare(dock_myPort, target).
			
				until dockComplete(dock_myPort) or not hastarget or target <> dock_hisPort {
			
				local rawD is target:position - dock_myPort:position.
				local sense is ship:facing.
			
				local dockD is V(
					vdot(rawD, sense:starvector),
					vdot(rawD, sense:upvector),
					vdot(rawD, sense:vector)
				).
				local rawV is dock_station:velocity:orbit - ship:velocity:orbit.
				local dockV is V(
					vdot(rawV, sense:starvector),
					vdot(rawV, sense:upvector),
					vdot(rawV, sense:vector)
				).
				local needAlign is (abs(dockD:x) > abs(dockD:z)/10) or (abs(dockD:y) > abs(dockD:z)/10).
			
				// Avoid errors just after docking complete; hastarget is unreliable
				// (maybe due to preemptible VM) and so we also put in a distance-based
				// safeguard.
				if hastarget and dockD:mag > 1 {
					uiShowPorts(dock_myPort, target, dock_start / 2, not needAlign).
					uiShowPorts(dock_myPort, target, dock_start / 2, not needAlign).
					uiDebugAxes(dock_myPort:position, sense, v(10,10,10)).
					uiDebugAxes(dock_myPort:position, sense, v(10,10,10)).
				}
			
				if dockD:Z < 0 {
					dockBack(dockD, dockV).
				} else if needAlign or dockD:Z > dock_start {
					dockAlign(dockD, dockV).
				} else {
					dockApproach(dockD, dockV,dock_myPort).
				}
				wait 0.
				}
			
				uiBanner("Dock", "Docking complete").
				dockFinish().
			} 
			else 
			{	
				uiError("Dock", "No suitable docking port; try moving closer?").
			}
			DockingDone on.
		}
		else if hastarget and TargetVessel:Distance >= MaxDistanceToApproach 
		{
			uiError("Dock","Target too far, RUN RENDEZVOUS instead.").
			DockingDone on.
		}
		else 
		{
			uiError("Dock","No target selected").
			DockingDone on.
		}
	
	}
}
FUNCTION approach
{
	parameter skips. // number of steps to skip over.
	
	LOCAL intersect_ta to 0.
	LOCAL intersect_eta to 0.
	LOCAL intersect_first_utime to 0.
	LOCAL ta_offset_from_other to 0.
	LOCAL other_intersect_ta to 0.
	LOCAL other_intersect_eta to  0.
	LOCAL rendezvous_utimes to list().
	LOCAL wait_left to 99999.
	LOCAL rendezvous_tolerance_1 to 50. // (seconds).
	LOCAL rendezvous_tolerance_2 to 5. // (seconds).
	LOCAL rendezvous_tolerance_3 to 1. // (seconds).
	LOCAL found to false.
	LOCAL my_rendezvous_utime to 0. // will calculate later in the loop.
	LOCAL num_orbits to 0. // how many orbits until a hit.
	LOCAL burn_start_time to time:seconds.
	LOCAL other_predict_V to 0.
	LOCAL my_predict_V to 0.
	LOCAL my_rendezvous_pre_time to 0.
	LOCAL rendezvous_eta to 99999.
	LOCAL rel_spd to -99999.
	LOCAL deltaV to 0.
	
	
	SAS OFF.
	RCS ON.
	set ship:control:pilotmainthrottle to 0.
	clearscreen.
	print " ".
	print " ".
	print " ".
	set intersect_ta to orbit_cross_ta(ship:obt, target:obt, 10, 0.01).
	
	if skips = 0 
	{
		if intersect_ta < 0 
		{
			node_inc().
			run_node().
			if target:periapsis < ship:periapsis
			{
				node_peri(target:periapsis - 1000).
				run_node.
			}
			else if target:periapsis > ship:periapsis
			{
				node_peri(target:periapsis * 1.12).
				run_node.
			}
			wait 1.
			//print "No intersect point in the orbits yet.".
			//print "Waiting for periapsis to correct this.".
			//wait until eta:periapsis < 5*(warp+1)^2.
			//set warp to 0.
			// May have to enlarge or shink the orbit:
			if ship:obt:semimajoraxis < target:obt:semimajoraxis 
			{
				lock steering to prograde.
				print "Will enlarge my orbit when at periapsis.".
			} else 
			{
				lock steering to retrograde.
				print "Will shrink my orbit when at periapsis.".
			}
			wait until ship:obt:trueanomaly >= 0 and ship:obt:trueanomaly < 90.
			print "Burning until there's a crossing point.".
			lock throttle to 1.
			until intersect_ta >= 0 
			{
				// using cruder, faster approximation for this repeated check:
				set intersect_ta to orbit_cross_ta(ship:obt, target:obt, 10, 2).
			}.
			unlock throttle.
			unlock steering.
			// Now use the more precise measure once we know it will work:
			set intersect_ta to orbit_cross_ta(ship:obt, target:obt, 10, 0.01).
		}
	}
	
	if skips <= 1 
	{
		set intersect_eta to eta_to_ta(ship:obt, intersect_ta).
		set intersect_first_utime to time:seconds + intersect_eta.
		set ta_offset_from_other to ta_offset(ship:obt, target:obt).
		set other_intersect_ta to intersect_ta + ta_offset_from_other.
		set other_intersect_eta to  eta_to_ta(target:obt, other_intersect_ta).
		print "intersect_ta is " + round(intersect_ta,1) + " deg    ".
		print "    other_ta is " + round(other_intersect_ta,1) + " deg    ".
		print "intersect_eta is " + round(intersect_eta,0) + " seconds   ".
		print "    other_eta is " + round(other_intersect_eta,1) + " seconds   ".
		// Obtain a list of the next 5 utimes that the target will cross
		// the intersect point:
		set rendezvous_utimes to list().
		local i is 0.
		from {local i is 0.} until i = 4 step {set i to i+1.} do 
		{
			rendezvous_utimes:add(time:seconds + other_intersect_eta + target:obt:period*i).
		}
		print "Now waiting until hitting the intersect point.".
		set wait_left to 99999.
		until wait_left <= 0 
		{
			set wait_left to intersect_first_utime - time:seconds.
			print "Wait " + round(wait_left,0) + " s   " at (5,0).
			if wait_left < 20 
			{
				if warp > 0 
				{
					set warp to 0.
				}
				lock steering to prograde.
			}
		}
		print "Embiggenig orbit until matching a rendezvous time.".
		print " ".
		print " ".
		print " ".
		print " ".
		print " ".
		print " ".
		set rendezvous_tolerance_1 to 50. // (seconds).
		set rendezvous_tolerance_2 to 5. // (seconds).
		set rendezvous_tolerance_3 to 1. // (seconds).
		set found to false.
		set my_rendezvous_utime to 0. // will calculate later in the loop.
		set num_orbits to 0. // how many orbits until a hit.
		set burn_start_time to time:seconds.
		LOCK THROTTLE to 1.
		until found 
		{
			wait 0.1.
			local i is 0.
			until found or i = 4 
			{
				set my_rendezvous_utime to burn_start_time + ship:obt:period * i.
				print "[" + i + "], mine =" + round(my_rendezvous_utime,1) + " s    " at (2,10+i).
				local j is 0.
				until found or j = 4 
				{
					local other_rendezvous_utime is rendezvous_utimes[j].
					local time_diff is my_rendezvous_utime - other_rendezvous_utime.
					print "other =" + round(other_rendezvous_utime,1)+" s      " at (25,10+j).
					if abs(time_diff) < rendezvous_tolerance_1 
					{
						LOCK THROTTLE to 0.1.
					}
					if abs(time_diff) < rendezvous_tolerance_2 
					{
						LOCK THROTTLE to 0.01.
					}
					if abs(time_diff) < rendezvous_tolerance_3 
					{
						LOCK THROTTLE to 0.
						set found to true.
						set num_orbits to i.
					}
					set j to j+1.
				}
				set i to i+1.
			}
		}
	
	}
	
	if skips <= 2 
	{
		// Adjust utime a bit to account for how much deltaV burn.
		set other_predict_V to velocityat(target, my_rendezvous_utime):orbit.
		set my_predict_V to velocityat(ship, my_rendezvous_utime):orbit.
		set deltaV to other_predict_V - my_predict_V.
		set my_rendezvous_pre_time to my_rendezvous_utime - burn_seconds(deltaV:mag/2).
		print "Found a matching time within " + num_orbits + " orbit(s)".
		set rendezvous_eta to 99999.
		until rendezvous_eta <= 0 
		{
			set rendezvous_eta to my_rendezvous_pre_time - time:seconds.
			print "Wait " + round(rendezvous_eta,0) + " s   " at (5,0).
			if rendezvous_eta < 20 
			{
				if warp > 0 
				{
					set warp to 0.
				}
				lock steering to target:velocity:orbit - ship:velocity:orbit.
			}
		}.
		print "Burning until rel vel killed.".
		LOCK THROTTLE to 1.
		set	rel_spd to -99999.
		// Burn until either hitting zero rel vel, or rel vel starts
		// getting bigger:
		print "rel spd is now        m/s" at (5,0).
		until rel_spd >= 0 
		{
			print round(rel_spd,1) + "  " at (20,0).
			wait 0.01.
			set rel_spd to VDOT((ship:velocity:orbit - target:velocity:orbit), ship:facing:vector).
		}.
		LOCK THROTTLE to 0.
		print "Done".
	}
	
	if skips <= 3 
	{
		//
		// Now get close.
		//
		print "Now easing closer to target.".
		
		set maxDecel to (ship:availablethrust / ship:mass).
		
		local mysteer is target:position+(40*ship:north:vector).
		lock steering to mysteer.
		lock rel_vel to ship:velocity:orbit - target:velocity:orbit.
		until target:position:mag < 350 
		{
			// Push toward until drifting fast enough at other:
			print "... Pushing toward target faster".
			set mysteer to target:position+(40*ship:north:vector).
			wait until vang(target:position, ship:facing:forevector) < 2.
			LOCK THROTTLE to 1/(0.01*maxDecel).
			wait until vdot(rel_vel,target:position:normalized) > 4+(target:position:mag/100).
		
			// While drifting, get ready by aiming retro:
			print "... Drifting toward target, aiming retro now".
			LOCK THROTTLE to 0.
			set mysteer to -rel_vel.
			wait until vang(rel_vel, target:position) > 80 or target:distance < 350.
			// Kill all speed once angle to target > 70 deg from my velocity.
			set mysteer to - rel_vel:vec.
			LOCK THROTTLE to rel_vel:mag/(0.05+maxDecel).
			print "... Killing relative speed to zero.".
			
			wait until vdot(mysteer, rel_vel:normalized) > -0.1.
			LOCK THROTTLE to 0.		
			// Repeat the above step until close enough.
		}
	}
	unlock steering.
	unlock throttle.
	set ship:control:neutralize to true.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	print "Rendezvous program ending.".
}
FUNCTION spacex
{
	//parameter LandingSite.
	
	//set STEERINGMANAGER:pitchtorquefactor to 5.
	//set STEERINGMANAGER:yawtorquefactor to 5.
	//set STEERINGMANAGER:rolltorquefactor to 5.
	//set STEERINGMANAGER:MAXSTOPPINGTIME to 1. //default=2
	sane_steering().
	
	//set LandingSite to false. //For testing landing back at KSC.
	//set step to "XLand".
	clearscreen.
	LOCK thrott TO 0.
	LOCK THROTTLE TO thrott.
	//set steeringDir TO 0.
	//set shipPitch TO 0.
	set genoutputmessage TO "".
	
	//if (landingSite = "Barge")
	//{
	//	set LandTarget to Kerbin:GEOPOSITIONLATLNG(-0.1165805,-65.0021184).
	//	SET step to "Barge".
	//}
	//else
	//{
		SET LandTarget TO Kerbin:GEOPOSITIONLATLNG(-0.1165805,-74.5463040).
		SET step to "BoostBack".
		//set step to "XLand".
	//}	
	if ADDONS:TR:HASIMPACT 
	{
		ADDONS:TR:SETTARGET(LandTarget).
		LOCK targetDir TO geoDir(ADDONS:TR:IMPACTPOS, LandTarget).
		LOCK impactDist TO calcDistance(LandTarget, ADDONS:TR:IMPACTPOS).
	}
	LOCAL LandDist to 0.
	local land is false.
	LOCAL overshoot is 150.
	local posError is 0.
	local st is facing:vector.
	if (debugall)
	{
		set vec1 to vecdraw(ship:position, impPosFut:position, rgb(1,0,0), "Imp", 1, true).
		set vec2 to vecdraw(v(0,0,0),v(0,0,0), rgb(0,1,0), "Steer", 1, true).
		set vec3 to vecdraw(ship:position, LandTarget:position, rgb(1,1,1), "LP", 1, true).
	}
	
	LOCAL strength is 0.
	LOCAL strength2 is 0.
	//LOCAL LOCK angL to -min(15,geo_diff:mag / 3) * strength * strength2.
	//LOCAL LOCK axis to vcrs(-velocity:surface,geo_diff).
	
	RCS ON.
	SAS OFF.
	SET SHIP:CONTROL:FORE to -1. // Seperate from the upper stage
	wait 3.	
	LOCK geoDist TO calcDistance(LandTarget, SHIP:GEOPOSITION).
	LOCK steeringDir TO targetDir - 180.
	LOCK STEERING TO HEADING(steeringDir,15).
	SET SHIP:CONTROL:FORE to 0.
	set thrott to 0.1.
	wait until abs(steeringmanager:yawerror) < 4 and abs(steeringmanager:pitcherror) < 4.
	set looping TO TRUE.
	UNTIL looping = false 
	{
		
		if (ship:status = "Landed" or ship:status = "Splashed")
		{
			SET step TO "end".
		}
		//LOCK geoDist TO calcDistance(LandTarget, SHIP:GEOPOSITION).
		LOCK shipPitch TO max(10, 90 * (1 - ALT:RADAR / (100000 / 2))).
		LOCK terrainAlt TO SHIP:ALTITUDE-ALT:RADAR.
		//LOCK posCur to ship:geoposition.
		if ADDONS:TR:HASIMPACT 
		{
			LOCK posError to LandTarget:position - addons:tr:impactpos:position.
		}
		//LOCK geo_diff to geo_diff * 0.8 + 0.2 * vxcl(LandTarget:position - body:position, posError).
		LOCK vdist_offset to min(100,max(0,vxcl(up:vector,velocity:surface):mag - 2) * 0.1).
		LOCK vdist to altitude - max(0,max(0,LandTarget:terrainheight)) - 33.4 - vdist_offset.
		LOCK offset to vxcl(LandTarget:position-body:position,LandTarget:position).
		updateReadouts().
		
		

		if(step="BoostBack")
		{
			set steeringmanager:maxstoppingtime to 2.
			set steeringmanager:rolltorquefactor to 3.
			LOCK impactDist TO calcDistance(LandTarget, ADDONS:TR:IMPACTPOS).
			SET impPosFut to ADDONS:TR:impactpos.
			LOCK targetDir TO geoDir(ADDONS:TR:IMPACTPOS, LandTarget).
			LOCK steeringDir TO targetDir - 180.
			LOCK STEERING TO HEADING(steeringDir,15).
			if(impactDist > 10000)
			{
				SET thrott TO 1.
			}
			else if(impactDist < 10000 and impactDist > 2000)
			{
				SET thrott TO 0.5.
			}
			else if (impactDist < 1500)
			{
				SET thrott TO 0.
				SET step TO "Boost+".
			}
			SET genoutputmessage TO "KSC Distance: "+CEILING(geoDist).	
		}
		if(step="Boost+")
		{
			//set STEERING TO HEADING(targetDir,0).
			//wait until abs(steeringmanager:yawerror) < 2 and abs(steeringmanager:pitcherror) < 2 and abs(steeringmanager:rollerror) < 2.
			SET impactDist TO calcDistance(LandTarget, ADDONS:TR:IMPACTPOS).
			set impPosFut to ADDONS:TR:impactpos.
			SET steeringDir TO targetDir - 180.
			SET targetDir TO geoDir(ADDONS:TR:IMPACTPOS, LandTarget).
			SET impactDist TO calcDistance(LandTarget, ADDONS:TR:IMPACTPOS).
			set LandDist to impactDist.
			set thrott to 0.1.
			wait 1.
			set thrott to 0.
			if LandDist > (calcDistance(LandTarget, ADDONS:TR:IMPACTPOS))
			{
				//set STEERING TO HEADING(targetDir,0).
				until impactDist > 1500
				{
					SET impPosFut to ADDONS:TR:impactpos.
					SET impactDist TO calcDistance(LandTarget, ADDONS:TR:IMPACTPOS).
					SET thrott TO 0.2.
				}
				SET thrott TO 0.
				SET step TO "SlowDown".
			}
			else
			{
				set STEERING TO HEADING(steeringDir,0).
				SET step TO "SlowDown".
			}
			SET genoutputmessage TO "KSC Distance: "+CEILING(geoDist).
		}
		if(step="Barge")
		{
			set steeringmanager:maxstoppingtime to 2.
			set steeringmanager:rolltorquefactor to 3.
			SET impactDist TO calcDistance(LandTarget, ADDONS:TR:IMPACTPOS).
			set impPosFut to ADDONS:TR:impactpos.
			SET steeringDir TO targetDir - 180.
			SET targetDir TO geoDir(ADDONS:TR:IMPACTPOS, LandTarget).
			SET STEERING TO HEADING(steeringDir,5).
			wait until abs(steeringmanager:yawerror) < 2 and abs(steeringmanager:pitcherror) < 2 and abs(steeringmanager:rollerror) < 2.
			if(impactDist > 10000)
			{
				SET thrott TO 1.
			}
			else if(impactDist < 10000 and impactDist > 4000)
			{
				SET thrott TO 0.2.
			}
			else if (impactDist < 4000)
			{
				SET thrott TO 0.
				SET step TO "SlowDown".
			}
			SET genoutputmessage TO "Barge Distance: "+CEILING(geoDist).
		}
		if(step="SlowDown")
		{
			set impPosFut to ADDONS:TR:impactpos.
			LOCK impactDist TO calcDistance(LandTarget, ADDONS:TR:IMPACTPOS).
			LOCK geo_diff to vxcl(up:vector, (LandTarget:position + offset * 0.7) - addons:tr:impactpos:position).
			LOCK strength to min(50,abs(400 - velocity:surface:mag))/ 50.
			LOCK axis to vcrs(-velocity:surface,geo_diff).
			LOCK strength2 to 1 / max(1,velocity:surface:mag/400).
			LOCK angL to -min(90,geo_diff:mag / 3) * strength * strength2.
			LOCK STEERING to -velocity:surface * angleaxis(angL,axis).
			when altitude < body:atm:height and verticalspeed < 0 then 
			{
				for m in ship:modulesnamed("ModuleAnimateGeneric") {
					if m:hasevent("deploy fins") m:doevent("deploy fins").
				}
				brakes on.
				return false.
			}
			//if(SHIP:ALTITUDE > 5000 and impactDist > 500)
			if SHIP:ALTITUDE < 30000
			{
				if impactDist > 300
				{
					//if (impactDist < (SHIP:ALTITUDE /20))
					//{
						
					//	set thrott to 0.
					//}
					//else 
					//{
						//set STEERING TO HEADING(targetDir,0).
						set thrott to thrott + 0.01.
					
					//}
					
				}else 
				{
					setHoverPIDLOOPS(). //you can manually set them, but these are some good defaults.
					SET thrott TO 0.
					LOCK STEERING to -velocity:surface * angleaxis(angL,axis).
					SET step TO "XBurn".
				}
			}
			SET genoutputmessage TO "Impact from target: "+CEILING(impactDist).
		}	
		if(step="XBurn")
		{
			SET g to constant:g * body:mass / body:radius^2.
			SET trueRadar to (landRadarAltimeter() - LandAltitude).
			SET maxDecel to (ship:AVAILABLETHRUST / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
			SET stopDist to (ship:verticalspeed^2 / (2 * maxDecel)).		// The distance the burn will require
			
			set impPosFut to ADDONS:TR:impactpos.
			SET impactDist TO calcDistance(LandTarget, ADDONS:TR:IMPACTPOS).
			SET geo_diff to vxcl(up:vector, (LandTarget:position + offset * 0.7) - addons:tr:impactpos:position).
			SET strength to min(50,abs(400 - velocity:surface:mag))/ 50.
			SET axis to vcrs(-velocity:surface,geo_diff).
			SET geo_diff to geo_diff + 2 * vxcl(up:vector,vxcl(velocity:surface,posError)). //increase sideways correction in final burn
			SET angL to min(45,geo_diff:mag / 3) * strength.
			
			if (trueRadar < (stopDist + 200))
			{
				set land to false.
				SET step TO "XLand".
			}
			LOCK STEERING to -velocity:surface * angleaxis(angL,axis).
			//SET genoutputmessage TO "Impact dist from target: "+ROUND(impactDist,2).
			SET genoutputmessage TO "Impact from target: "+CEILING(impactDist).
		}
		if(step="XLand")
		{

			SET g to constant:g * body:mass / body:radius^2.
			SET trueRadar to (landRadarAltimeter() - LandAltitude).
			SET maxDecel to (ship:AVAILABLETHRUST / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
			SET stopDist to (ship:verticalspeed^2 / (2 * maxDecel)).		// The distance the burn will require
			SET impactTime to trueRadar / abs(ship:verticalspeed).
			LOCK strength to min(50,abs(300 - velocity:surface:mag))/ 50.
			LOCK strength2 to 1 / max(1,velocity:surface:mag/400).
			LOCK angL to -min(15,geo_diff:mag / 3) * strength * strength2.
			LOCK axis to vcrs(-velocity:surface,geo_diff).
			set geo_diff to geo_diff + 2 * vxcl(up:vector,vxcl(velocity:surface,posError)). //increase sideways correction in final burn
			LOCK STEERING to -velocity:surface * angleaxis(angL,axis).
			if ADDONS:TR:HASIMPACT 
			{
				set impPosFut to ADDONS:TR:impactpos.
			}
			if (trueRadar < stopDist) and not (land) 
			{	
				setHoverTarget(LandTarget:LAT,LandTarget:LNG).
				set land to true.
			}
			if land
			{
				if (ship:status = "Landed" or ship:status = "Splashed")
				{
					SET step to "end".
				}
				if ship:groundspeed > 3 and geoDist > 10
				{
					SET MaxHorizSpeed TO 3.
					SET MaxSteerAngle TO 10.
					setHoverMaxSteerAngle(MaxSteerAngle).
					setHoverMaxHorizSpeed(MaxHorizSpeed).
					updateHoverSteering().	
				}
				else if ship:groundspeed < 3 and geoDist < 10
				{
					SET MaxHorizSpeed TO 3.
					SET MaxSteerAngle TO 5.
					setHoverMaxSteerAngle(MaxSteerAngle).
					setHoverMaxHorizSpeed(MaxHorizSpeed).
					setHoverAltitude(terrainAlt - 30).
					updateHoverSteering().	
				}
				SET maxDescendSpeed TO max(5,min(terrainAlt,15)).
				setHoverDescendSpeed(maxDescendSpeed).
				updateHoverSteering().	
			}
			if ALT:RADAR < 200
			{
				GEAR ON.
			}
			//updateHoverSteering().			
			SET genoutputmessage TO "Distance from target: "+CEILING(geoDist).
		}
		if(step="end")
		{
			SET thrott TO 0.
			SET STEERING TO UP.
			WAIT 1.
			UNLOCK STEERING.
			wait 1.
			BRAKES off.
			SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
			WAIT 1.
			RCS OFF.
			WAIT 1.
			if (debugall)
			{
				set vec1:show to false.
				set vec2:show to false.
				set vec3:show to false.
			}
			set debugall to false.
			SET looping TO false.
		}
		if (debugall)
		{
			set vec1 to vecdraw(ship:position, impPosFut:position, rgb(1,0,0), "Imp", 1, true).
			set vec3 to vecdraw(ship:position, LandTarget:position, rgb(1,1,1), "LP", 1, true).
			set vec2:vec to geo_diff.
		}
	}
	clearscreen.
	print ship:status.
	RTantennaON().
}
FUNCTION landvac
{
	/////////////////////////////////////////////////////////////////////////////
	// Land
	/////////////////////////////////////////////////////////////////////////////
	// Make groundfall. Try to avoid a rapid unplanned disassemble. 
	// Warranty void if used with air
	//
	// Usage: RUN LANDVAC(<mode>,<latitude>,<longitude>).
	//
	//       Parameters:
	//          <mode>: Can be TARG, COOR or SHIP.
	//                  -TARG (default) will try to land on the selected target. 
	//                  If has no valid target falls back to SHIP.
	//                  -COOR will try to land on <latitude> and <longitude>. 
	//                  -SHIP will try to land in the coordinates that ship is
	//                  flying over when the program start.
	/////////////////////////////////////////////////////////////////////////////
	
	
	// General logic:
	// 0) Be in a circular, zero inclination orbit.
	// 1) Calculate a Hohmann Transfer with:
	//    - Target altitude = 1% of body radius above ground
	// 2) Calculate a phase angle so the periapsis of the new orbit will be right over the landing site
	// 3) Take a point 270ยบ before the landing site and do the plane change 
	// 4) Do the deorbit burn
	
	// LandMode defines how this program will work
	PARAMETER LandMode is "TARG".
	PARAMETER LandLat is ship:geoposition:lat.  
	PARAMETER LandLng is ship:geoposition:lng.
	
	SAS OFF.
	BAYS OFF.
	GEAR OFF.
	LADDERS OFF.
	
	local DrawDebugVectors is false.
	
	
	
	// ************
	// MAIN PROGRAM
	// ************
	
	
	// DEORBIT SEQUENCE
	if ship:status = "ORBITING" {
	
		if body:atm:exists uiWarning("Deorbit","Warning: Warranty void, used with atmosphere!").
	
		// Zero the orbit inclination
		IF abs(OBT:INCLINATION) > 0.1 {
			uiBanner("Deorbit","Setting an equatorial orbit").
			//RUNPATH("node_inc_equ.ks",0).
			//RUNPATH("node.ks").
		}
		// Circularize the orbit
		if obt:eccentricity > 0.01 {
			uiBanner("Deorbit","Circularizing the orbit").
			//run circ.
		}
	
		// Find where to land
		if LandMode:contains("TARG") { 
			if hastarget and TARGET:BODY = SHIP:BODY { // Make sure have a target in the same planet at least! Note it doesn't check if target is landed/splashed, will just use it's position, for all it cares.
				set LandLat to utilLongitudeTo360(TARGET:GEOPOSITION:LAT).
				set LandLng to utilLongitudeTo360(TARGET:GEOPOSITION:LNG).
			}
			else {
				set LandLat to utilLongitudeTo360(ship:geoposition:lat).
				set LandLng to utilLongitudeTo360(ship:geoposition:lng).
			}
		}
		else if LandMode:contains("COOR") {
			set LandLat to utilLongitudeTo360(LandLat).
			set LandLng to utilLongitudeTo360(LandLng).
		}
		else if LandMode:contains("SHIP") {
			set LandLat to utilLongitudeTo360(ship:geoposition:lat).
			set LandLng to utilLongitudeTo360(ship:geoposition:lng).
		}
		else {
			uiFatal("Land","Invalid mode").
		}
	
		LOCK LandingSite to LATLNG(LandLat,LandLng).
	
		//Define the deorbit periapsis
		local DeorbitRad to max(5000+ship:body:radius,(ship:body:radius*1.02 + LandingSite:terrainheight)).
	
		// Find a phase angle for the landing
		// The landing burning is like a Hohmann transfer, but to an orbit close to the body surface
		local r1 is ship:orbit:semimajoraxis.                               //Orbit now
		local r2 is DeorbitRad .                                            // Target orbit
		local pt is 0.5 * ((r1+r2) / (2*r2))^1.5.                           // How many orbits of a target in the target (deorbit) orbit will do.
		local sp is sqrt( ( 4 * constant:pi^2 * r2^3 ) / body:mu ).         // Period of the target orbit.
		local DeorbitTravelTime is pt*sp.                                   // Transit time 
		local phi is (DeorbitTravelTime/ship:body:rotationperiod) * 360.    // Phi in this case is not the angle between two orbits, but the angle the body rotates during the transit time
		local IncTravelTime is ship:obt:period / 4. // Travel time between change of inclinationa and lower perigee
		local phiIncManeuver is (IncTravelTime/ship:body:rotationperiod) * 360.
	
		// Deorbit and plane change longitudes
		LOCAL Deorbit_Long is utilLongitudeTo360(LandLng - 180).
		LOCAL PlaneChangeLong is utilLongitudeTo360(LandLng - 270).
	
		// Plane change for landing site
		local vel is velocityat(ship, landTimeToLong(PlaneChangeLong)):orbit.
		local inc is LandingSite:lat.
		local TotIncDV is 2 * vel:mag * sin(inc / 2).
		local nDv is vel:mag * sin(inc).
		local pDV is vel:mag * (cos(inc) - 1 ).
	
		if TotIncDV > 0.1 { // Only burn if it matters.
			uiBanner("Deorbit","Burning dV of " + round(TotIncDV,1) + " m/s @ anti-normal to change plane.").
			LOCAL nd IS NODE(time:seconds + landTimeToLong(PlaneChangeLong+phiIncManeuver), 0, -nDv, pDv).
			add nd. run_node().
		}
	
		// Lower orbit over landing site
		local Deorbit_dV is landDeorbitDeltaV(DeorbitRad-body:radius).
		uiBanner("Deorbit","Burning dV of " + round(Deorbit_dV,1) + " m/s retrograde to deorbit.").
		LOCAL nd IS NODE(time:seconds + landTimeToLong(Deorbit_Long+phi) , 0, 0, Deorbit_dV).
		add nd. run_node(). 
		uiBanner("Deorbit","Deorbit burn done"). 
		wait 5. // Let's have some time to breath and look what's happening 
	
		// Brake the ship to finally deorbit.
		LOCAL BreakingDeltaV is VELOCITYAT(ship,time:seconds+eta:periapsis):orbit:mag.
		uiBanner("Deorbit","Burning dV of " + round(BreakingDeltaV,1) + " m/s retrograde to brake ship.").
		SET ND TO NODE(time:seconds + eta:periapsis , 0, 0, -BreakingDeltaV).
		add nd.
		RUN_NODE().
		uiBanner("Deorbit","Brake burn done").
	
	}
	ELSE IF SHIP:STATUS = "SUB_ORBITAL" {
		LOCK LandingSite TO SHIP:GEOPOSITION.
	}
	
	// Try to land
	if ship:status = "SUB_ORBITAL" or ship:status = "FLYING" {
		LOCAL TouchdownSpeed is 2.
	
		//PID Throttle
		LOCK ThrottlePID to PIDLOOP(0.04,0.001,0.01). // Kp, Ki, Kd
		SET ThrottlePID:MAXOUTPUT TO 1.
		SET ThrottlePID:MINOUTPUT TO 0.
		SET ThrottlePID:SETPOINT TO 0. 
	
		SAS OFF.
		RCS OFF.
		LIGHTS ON. //We want the Kerbals to see where they are going right?
		LEGS ON.   //This is important!
	
		// Throttle and Steering
		local tVal is 0.
		lock Throttle to tVal.
		local sDir is ship:up.
		lock steering to sDir.
	
		// Main landing loop
		UNTIL SHIP:STATUS = "LANDED" OR SHIP:STATUS = "SPLASHED" {
			WAIT 0.
			// Steer the rocket
			LOCK ShipVelocity TO SHIP:velocity:surface.
			LOCK ShipHVelocity to vxcl(SHIP:UP:VECTOR,ShipVelocity).
			LOCAL DFactor TO 0.08. // How much the target position matters when steering. Higher values make landing more precise, but also may make the ship land with too much horizontal speed.
			LOCK TargetVector to vxcl(SHIP:UP:VECTOR,LandingSite:Position*DFactor).
			LOCK SteerVector to -ShipVelocity - ShipHVelocity + TargetVector.
			if DrawDebugVectors {
				SET DRAWSV TO VECDRAW(v(0,0,0),SteerVector, red, "Steering", 1, true, 1).
				SET DRAWV TO VECDRAW(v(0,0,0),ShipVelocity, green, "Velocity", 1, true, 1).
				SET DRAWHV TO VECDRAW(v(0,0,0),ShipHVelocity, YELLOW, "Horizontal Velocity", 1, true, 1).
				SET DRAWTV TO VECDRAW(v(0,0,0),TargetVector, Magenta, "Target", 1, true, 1).
			}
				
			set sDir TO SteerVector:Direction. 
	
			// Throttle the rocket
			LOCK TargetVSpeed to MAX(TouchdownSpeed,sqrt(landRadarAltimeter())).
	
			IF abs(SHIP:VERTICALSPEED) > TargetVSpeed {
				set tVal TO ThrottlePID:UPDATE(TIME:seconds,(SHIP:VERTICALSPEED + TargetVSpeed)).
			}
			ELSE
			{
				set tVal TO 0.
			}
			PRINT "Vertical speed " + abs(Ship:VERTICALSPEED) + "                           " at (0,0).
			Print "Target Vspeed  " + TargetVSpeed            + "                           " at (0,1).
			print "Throttle       " + tVal                    + "                           " at (0,2).
			print "Ship Velocity  " + ShipVelocity:MAG        + "                           " at (0,3).
			print "Ship height    " + landRadarAltimeter()        + "                           " at (0,4).
			print "                                                                    " at (0,5).
			wait 0.1.
		}
	
		UNLOCK THROTTLE. UNLOCK STEERING.
		SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
		clearvecdraws().
		LADDERS ON.
		SAS ON. // Helps to don't tumble after landing
	}
	else if ship:status = "ORBITING" uiError("Land","This ship is still in orbit!?").
	else if ship:status = "LANDED" or ship:status = "SPLASHED" uiError("Land","We are already landed, nothing to do here, move along").
	else uiError("Land","Can't land from " + ship:status).

}
FUNCTION rover
{
	parameter turnfactor is 8. // Allow for passing the turnfactor for different rovers.
	parameter maxspeed is 39. // Allow for passing the speedlimit. Default is 39 m/s, almost 88mph ;)

	LOCAL speedlimit to maxspeed. //All speeds are in m/s 
	lock turnlimit to min(1, turnfactor / GROUNDSPEED). //Scale the turning radius based on current speed
	LOCAL looptime to 0.01.
	LOCAL loopEndTime to TIME:SECONDS.
	LOCAL eWheelThrottle to 0. // Error between target speed and actual speed
	LOCAL iWheelThrottle to 0. // Accumulated speed error
	LOCAL wtVAL to 0. //Wheel Throttle Value
	LOCAL kTurn to 0. //Wheel turn value.
	LOCAL targetspeed to 0. //Cruise control starting speed

	DECLARE LOCAL speed_pid IS pidloop().
	SET speed_pid:minoutput TO -1.0.
	SET speed_pid:maxoutput TO 1.0.
	SET speed_pid:setpoint TO 0.0.
	LOCK wheelthrottle TO speed_pid:update(time:seconds,ship:groundspeed).
	// Create a GUI window
	LOCAL gui IS GUI(250).
	SET gui:x TO 30.
	SET gui:y TO 100.
	LOCAL labelMode IS gui:ADDLABEL("").
	SET labelMode:STYLE:ALIGN TO "CENTER".
	SET labelMode:STYLE:HSTRETCH TO True. 
	LOCAL apsettings to gui:ADDVLAYOUT().
	//SPEED Settings
	LOCAL labelSPDTitle IS apsettings:ADDLABEL("<b><size=15>Desidered Speed</size></b>").
	SET labelSPDTitle:STYLE:ALIGN TO "CENTER".
	SET labelSPDTitle:STYLE:HSTRETCH TO True. 
	LOCAL SPDsettings to apsettings:ADDHBOX().
	LOCAL ButtonSPDM TO SPDsettings:ADDBUTTON("▼").
	SET ButtonSPDM:Style:WIDTH TO 40.
	SET ButtonSPDM:Style:HEIGHT TO 25.
	LOCAL LabelSPD TO SPDsettings:ADDLABEL("").
	SET LabelSPD:Style:HEIGHT TO 25.
	SET LabelSPD:STYLE:ALIGN TO "CENTER".
	LOCAL ButtonSPDP TO SPDsettings:ADDBUTTON("▲").
	SET ButtonSPDP:Style:WIDTH TO 40.
	SET ButtonSPDP:Style:HEIGHT TO 25.
	SET ButtonSPDM:ONCLICK  TO { 
		SET targetspeed TO ROUND(targetspeed) -1.
	}.
	SET ButtonSPDP:ONCLICK  TO { 
		SET targetspeed TO ROUND(targetspeed) +1.
	}.
	//Dashboard
	LOCAL dashboard to gui:ADDHBOX().
	LOCAL DashLeft to dashboard:ADDVLAYOUT().
	LOCAL LabelDashSpeed to DashLeft:ADDLABEL("").
	SET LabelDashSpeed:STYLE:ALIGN TO "LEFT".
	SET LabelDashSpeed:STYLE:HSTRETCH TO True. 
	SET LabelDashSpeed:STYLE:TEXTCOLOR TO Yellow.  
	LOCAL LabelDashEC to DashLeft:ADDLABEL("").
	SET LabelDashEC:STYLE:ALIGN TO "LEFT".
	SET LabelDashEC:STYLE:HSTRETCH TO True. 
	SET LabelDashEC:STYLE:TEXTCOLOR TO Yellow.  
	LOCAL LabelDashLFO to DashLeft:ADDLABEL("").
	SET LabelDashLFO:STYLE:ALIGN TO "LEFT".
	SET LabelDashLFO:STYLE:HSTRETCH TO True. 
	SET LabelDashLFO:STYLE:TEXTCOLOR TO Yellow.  
	LOCAL SliderSteering to DashLeft:ADDHSLIDER(0,1,-1).
	LOCAL LabelControls  to DashLeft:ADDLABEL("<color=#aaaaaa88>▲ Steering | Throttle ▶</color>").
	SET LabelControls:STYLE:ALIGN TO "RIGHT".
	SET LabelControls:STYLE:HSTRETCH TO True. 
	LOCAL SliderThrottle to Dashboard:ADDVSLIDER(0,1,-1).
	LOCAL ButtonStop TO gui:ADDBUTTON("Stop script").
	SET ButtonStop:ONCLICK TO { set runmode to -1 . WAIT 0.}.
	LOCAL ok TO gui:ADDBUTTON("Reboot kOS").
	SET ok:ONCLICK TO {
		gui:HIDE().
		SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
		reboot.
	}.
	gui:SHOW().
	
	// Main program
	clearscreen.
	sas off.
	rcs off.
	lights on.
	lock throttle to 0.
	LOCAL runmode to 0.
	if ship:status = "ORBITING" 
	{
		set runmode to -1.
	}
	partsDisableReactionWheels().
	until runmode = -1 
	{
		if runmode = 0 
		{ //Govern the rover 
		
			//Wheel Throttle:
			set targetspeed to targetspeed + 0.05 * SHIP:CONTROL:PILOTWHEELTHROTTLE.
			set targetspeed to max(-1, min( speedlimit, targetspeed)).
			
			if targetspeed > 0 
			{ //If we should be going forward
				if ship:groundspeed < 1 
				{
					brakes off.
				}
				set eWheelThrottle to targetspeed - GROUNDSPEED.
				set iWheelThrottle to min( 1, max( -1, iWheelThrottle + (looptime * eWheelThrottle))).
				set wtVAL to eWheelThrottle + iWheelThrottle.//PI controler
				if GROUNDSPEED < 5 
				{
					//Safety adjustment to help reduce roll-back at low speeds
					set wtVAL to min( 1, max( -0.2, wtVAL)).
					}
			}
			else if targetspeed < 0 
			{ //Else if we're going backwards
				set wtVAL to SHIP:CONTROL:PILOTWHEELTHROTTLE.
				set targetspeed to 0. //Manual reverse throttle
				set iWheelThrottle to 0.
			}
			else 
			{ // If value is out of range or zero, stop.
				set wtVAL to 0.
				brakes on.
			}
			if brakes 
			{ //Disable cruise control if the brakes are turned on.
				set targetspeed to 0.
			}        
			set kturn to turnlimit * SHIP:CONTROL:PILOTWHEELSTEER.
			//Detect rollover
			if abs(vang(vxcl(ship:facing:vector,ship:facing:upvector),TerrainNormal())) > 5 
			{
				set turnfactor to max(1,turnfactor * 0.9). //Reduce turnfactor
				//set runmode to 2. //Engage Stability control
			}
		}    
		//Here it really control the rover.
		set wtVAL to min(1,(max(-1,wtVAL))).
		set kTurn to min(1,(max(-1,kTurn))).
		set SHIP:CONTROL:WHEELTHROTTLE to WTVAL.
		set SHIP:CONTROL:WHEELSTEER to kTurn.
		
		// Update the GUI
		if runmode = 0 
		{
			SET LabelSPD:TEXT to "<b>" + round( targetspeed, 1) + " m/s | "+ round (MSTOKMH(targetspeed),1) + " km/h</b>".
		}
		else if runmode = 1 
		{
			SET LabelSPD:TEXT to "<b>- m/s | - km/h</b>".
		}
		SET LabelDashSpeed:TEXT to "<b>Speed: </b>" + round( ship:groundspeed, 1) + " m/s | "+ round (MSTOKMH(ship:groundspeed),1) + " km/h".
		SET LabelDashEC:TEXT to "<b>Charge: </b>" + ROUND(partsPercentEC()) + "%".
		SET LabelDashLFO:TEXT to "<b>Fuel: </b>" + ROUND(partsPercentLFO()) + "%".
		SET SliderSteering:VALUE to kTurn.
		SET SliderThrottle:VALUE to wtVAL. 
		SET speed_pid:setpoint TO WTVAL.
		set looptime to TIME:SECONDS - loopEndTime.
		set loopEndTime to TIME:SECONDS.
		wait 0. // Waits for next physics tick.
	}
	
	
	//Clear before end
	CLEARGUIS().
	UNLOCK Throttle.
	UNLOCK Steering.
	SET ship:control:translation to v(0,0,0).
	SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}
FUNCTION iss_returner
{
	set ag9 to false.
	SAS OFF.
	RCS OFF.
	clearscreen.
	print "Standing by for decouple".
	set sn to ship:name.
	wait until not (ship:name = sn).
	clearscreen.
	wait 1.
	set sn to ship:name.
	SET KUniverse:ACTIVEVESSEL TO VESSEL(sn).
	SET TERMINAL:WIDTH to 56.
	SET TERMINAL:HEIGHT to 22.
	CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
	print "Returning stage".
	unlock steering.
	SET SHIP:CONTROL:NEUTRALIZE to TRUE.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	unlock throttle.
	LOCK thrott TO 0.
	LOCK THROTTLE TO thrott.
	SET thrott to 0.
	RCS ON.
	set steering to ship:facing.
	SET SHIP:CONTROL:FORE to -1. // Seperate from the upper stage
	wait 20.
	SET SHIP:CONTROL:FORE to 0.
	wait 1.
	set steering to retrograde.
	wait 5.
	Print "Engines starting up".
	LOCAL englist to LIST().
	list engines in englist.
	FOR eng IN englist 
	{ // loop through the engines
		eng:ACTIVATE. 
	}
	wait 5.
	PANELS on.
	wait until abs(steeringmanager:yawerror) < 2 and abs(steeringmanager:pitcherror) < 2.
	print "Boost back".
	set thrott to 1.
	wait until ship:periapsis < 32000.
	set thrott to 0.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}

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
	if not stage:number = 0
	{
		if ship:maxthrust = 0 
		{
			stage.
			set did_stage to true.
			wait 3.
		} 
		else 
		{
			list engines in stg_eList.
			for stg_eng in stg_eList 
			{ 
				if stg_eng:name <> "sepMotor1" and stg_eng:tag <> "flameout no stage" and stg_eng:flameout 
				{
					stage.
					set did_stage to true.
					break.
				}
			}
		}
	}
  return did_stage.
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
	local ISP is isp_calc().
	
	// From rocket equation, and definition of ISP:
	return (g0*ISP*m0/F)*( 1 - e^(-dv_mag/(g0*ISP)) ).
}
function do_burn_with_display 
{
	parameter
		uTime, // desired universal time to start burn.
		want_dV,  // desired deltaV (as a vector).
		col, // desired location to print message.
		row. // desired location to print message.
	
	
	local want_steer is want_dV.
	lock steering to lookdirup(want_steer,ship:facing:topvector).
	until time:seconds >= uTime {
		print  "Burn Start in " + round(uTime-time:seconds,0) + " seconds  " at (col,row).
		stager().
		local prev_top is ship:facing:topvector.
		local prev_fore is ship:facing:forevector.
		wait 0.01.
	}.
	local start_vel is ship:velocity:orbit.
	local dv_to_go is 9999999.
	
	// Throttle at max most of the way, but start throttling
	// back when it seems like there's about 1.2 seconds left to thust:
	local avail_accel is ship:availablethrust / ship:mass.
	lock thrott to min(1, 0.01 + dv_to_go/(1.2*avail_accel)).
	lock throttle to thrott.
	
	print  "Burn dV remaining:         m/s" at (col,row).
	local prev_dv_to_go is dv_to_go + 1.
	local dv_burnt is 0.
	local prev_sec is time:seconds.
	local sec is 0.
	until dv_to_go <= 0 or (dv_to_go >= prev_dv_to_go) {
		set prev_dv_to_go to dv_to_go.
		set sec to time:seconds.
		set dv_burnt to dv_burnt + (sec-prev_sec)*(ship:availablethrust*thrott / ship:mass).
		set prev_sec to sec.
		wait 0.01.
		set dv_to_go to want_dv:mag - dv_burnt.
		print round(dV_to_go,1) + "m/s     " at (col+19,row).
		print "dv_burnt: " + round(dv_burnt,2) + "m/s    " at (col+19,row+1).
		print "thrott: " + round(thrott,2) + "    " at (col+19,row+2).
		stager().
		until ship:availablethrust > 0 {
		set prev_dv_to_go to 99999999.
		stager().
		}
	}
	lock thrott to 0.
	lock throttle to 0.
	unlock steering.
}
function obey_node_mode 
{
	parameter
		quit_condition,  // pass in a delegate that will return boolean true when you want it to end.
		node_edit is "n/a".       // pass in a delegate that will edit precise nodes if called.
	
	until quit_condition:call() {
		clearscreen.
		print "Type 'P' for precise node editor.".
		if not hasnode {
		hudtext("Waiting for a node to exist...", 10, 2, 30, red, true).
		until hasnode or quit_condition:call() {
			wait 0.
			just_obey_p_check(node_edit).
		}
		}
		hudtext("I See a Node.  Waiting until just before it's supposed to burn.", 5, 2, 30, red, true).
	
		// The user will be fiddling with the node just after adding it,
		// so this has to keep re-calculating whether or not it's time to 
		// drop from time warp based on the new changes the user is doing:
		local half_burn_length is 0.
		local full_burn_length is 0.
		local dv_mag is 0.
		until (not hasnode) // escape early if the user deleted the node
			or
			(nextnode:eta < 120 + half_burn_length) {
		set dv_mag to nextnode:deltaV:mag.
		set half_burn_length to burn_seconds(dv_mag/ 2).
		set full_burn_length to burn_seconds(dv_mag).
		print "Dv: " + round(dv_mag,2) + " m/s  " at (0,7).
		print "Est Full Dv Burn: " + round(full_burn_length,1) + " s  " at (0,8).
		print "Est Half Dv Burn: " + round(half_burn_length,1) + " s  " at (0,9).
		just_obey_p_check(node_edit).
		wait 0.2. // Don't re-calculate burn_seconds() more often than needed.
		}
		if hasnode { // just in case the user deleted the node - don't want to crash.
		set warp to 0.
		hudtext("Execution of node now set in stone.", 5, 2, 30, red, true).
		wait 0.
		local n is nextnode.
		local utime is time:seconds + n:eta - half_burn_length.
		do_burn_with_display(utime, n:deltav, 5, 10).
		hudtext("Node done, removing node.", 10, 5, 20, red, true).
		remove(n).
		}
		just_obey_p_check(node_edit).
	}
}
function just_obey_p_check 
{
	parameter node_edit. // a delegate to call when P is hit.
	
	if node_edit:istype("Delegate") {
		if terminal:input:haschar {
		if terminal:input:getchar() = "p" {
			node_edit:call().
		}
		}
	}
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
function countdown 
{
	parameter count.
	sane_steering().
	sane_upward().
	from { local i is count. } until i = 0 step { set i to i - 1. } do 
	{
		hudtext( "T minus " + i + "s" , 1, 1, 25, white, true).
		wait 1.
	}
}
function clamp_pitch 
{
	parameter in_pitch.
	parameter give_msg is false.
	
	local cur_pitch is srf_pitch_for_vel(ship).
	local max_off_allow is 2.5 / (ship:Q + 0.001).
	
	local out_pitch is min(max(in_pitch, cur_pitch - max_off_allow), cur_pitch + max_off_allow).
	
	if give_msg and in_pitch <> out_pitch and time:seconds > clamp_pitch_cooldown {
		hudtext("Q="+round(ship:q,4)+" Pitch clamping: Want="+round(in_pitch,1)+" Allow="+round(out_pitch,1),
				5, 2, 16, yellow, true).
		set clamp_pitch_cooldown to time:seconds + 6.
	}
	return out_pitch.
}
function use_alt 
{
	local rad_alt is alt:radar.
	if rad_alt > 0 and rad_alt < 2000 
	{
		return rad_alt.
	}else{
		return altitude.
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
function srf_pitch_for_vel 
{
	parameter ves.
	return 90 - vang(ves:up:vector, ves:velocity:surface).
}
function circularize 
{
	set looping TO TRUE.
	print "Circularizing.".
	lock steering to heading(compass_of_vel(ship:velocity:orbit), -(eta_ap_with_neg()/3)).
	print "..Waiting for steering to finish locking in place.".
	local vdraw is vecdraw(v(0,0,0), steering:vector*50, white, "waiting to point here", 1, true).
	wait until abs(steeringmanager:yawerror) < 2 and abs(steeringmanager:pitcherror) < 2 and abs(steeringmanager:rollerror) < 2.
	print "..Steering locked.  Now throttling.".
	set vdraw:show to false.
	lock throttle to 0.02 + (30*ship:obt:eccentricity).
	until ship:obt:trueanomaly < 90 or ship:obt:trueanomaly > 270
	{
		stager().
	}
	print "Done Circularlizing.".
	unlock steering.
	unlock throttle.
}
FUNCTION chutesetup 
{
	LOCAL para is LIST().
	LOCAL drog is LIST().
	LOCAL partlist is LIST().
	LIST parts in partList.
	for parts in partList 
	{
		for module in parts:modules 
		{
			if module = "RealChuteModule" 
			{
				if parts:name = "radialDrogue" 
				{
					drog:add(parts).
				}else
				{
					para:add(parts).
				}
			}
		}
	}
	print "Normal Chutes = " + para.
	print "Drog Chutes = " + drog.
}
FUNCTION chutearm
{ 	
	LOCAL partlist is LIST().
	LIST parts in partList.
	for parts in partList 
	{
		for module in parts:modules 
		{
			if module = "RealChuteModule" 
			{
				if parts:getmodule(module):HASEVENT("Arm parachute") 
				{
					parts:GETMODULE(module):DOEVENT("Arm parachute").
				}
			}
		}
	}
}
FUNCTION chutedeploy
{ 	
	LOCAL para is LIST().
	LOCAL drog is LIST().
	LOCAL partlist is LIST().
	LIST parts in partList.
	for parts in partList 
	{
		for module in parts:modules 
		{
			if module = "RealChuteModule" 
			{
				if parts:name = "radialDrogue" 
				{
					if parts:getmodule(module):HASEVENT("deploy chute") and SHIP:AIRSPEED < 400
					{
						parts:GETMODULE(module):DOEVENT("deploy chute").
					}
				}
				else
				{
					if parts:getmodule(module):HASEVENT("deploy chute") and SHIP:AIRSPEED < 250
					{
						parts:GETMODULE(module):DOEVENT("deploy chute").
					}
				}
			}
		}
	}
}
FUNCTION node_alt
{
	parameter alt.
	parameter nodetime is time:seconds + 120.
	
	local mu is body:mu.
	local br is body:radius.
	
	// present orbit properties
	local vom is ship:velocity:orbit:mag.  // current velocity
	local r is br + altitude.  // current radius
	local v1 is velocityat(ship, nodetime):orbit:mag. // velocity at burn time
	local sma1 is orbit:semimajoraxis.
	
	// future orbit properties
	local r2 is br + ship:body:altitudeof(positionat(ship, nodetime)).
	local sma2 is (alt + br + r2)/2.
	local v2 is sqrt( vom^2 + (mu * (2/r2 - 2/r + 1/sma1 - 1/sma2 ) ) ).
	
	// create node
	local deltav is v2 - v1.
	local nd is node(nodetime, 0, 0, deltav).
	add nd.
}
FUNCTION node_apo
{
	parameter alt.
	parameter nodetime is time:seconds + eta:periapsis.
	
	node_alt(alt, nodetime).
}
FUNCTION node_peri
{
	parameter alt.
	parameter nodetime is time:seconds + eta:apoapsis.
	
	node_alt(alt, nodetime).
}
FUNCTION run_node
{
	parameter nodeCreator is false. // delegate to re-create node if needed
	parameter burnTime is 0. // estimated burn time, lib_staging:burnTimeForDt used if zero
	
	stagingPrepare().
	
	// Configuration constants; these are pre-set for automated missions; if you
	// have a ship that turns poorly, you may need to decrease these and perform
	// manual corrections.
	if not (defined node_bestFacing)
	global node_bestFacing is 5.   // ~5  degrees error (10 degree cone)
	if not (defined node_okFacing)
	global node_okFacing   is 20.  // ~20 degrees error (40 degree cone)
	
	local sstate is sas. // save SAS state
	local rstate is rcs. // save RCS state
	
	// quo vadis?
	if not hasNode {
		if nodeCreator:istype("delegate") nodeCreator().
		if not hasNode uiFatal("Node", "No node to execute").
	}
	local nn is nextnode.
	
	// keep ship pointed at node
	sas off.
	lock steerDir to lookdirup(nn:deltav, positionAt(ship,time:seconds+nn:eta)-body:position).
	lock steering to steerDir.
	
	// estimate burn direction & duration
	local resetBurnTime is burnTime = 0.
	if resetBurnTime set burnTime to burnTimeForDv(nn:deltav:mag).
	local dt is burnTime/2.
	
	local warpLoop is 2.
	until false {
		// If have time, wait to ship almost align with maneuver node.
		// If have little time, wait at least to ship face in general direction of node
		// This prevents backwards burns, but still allows steering via engine thrust.
		// If ship is not rotating for some reason, will proceed anyway. (Maybe only torque source is engine gimbal?)
		wait 0.
		local warped to false.
		until utilIsShipFacing(steerDir,node_bestFacing,0.5) or
			nn:eta <= dt and utilIsShipFacing(steerDir,node_okFacing,5) or
			ship:angularvel:mag < 0.0001 and rcs = true
		{
			if ship:angularvel:mag < 0.01 rcs on.
			stagingCheck().
			if not warped { set warped to true. physWarp(1). }
			wait 0.
		}
		if warped resetWarp().
		if warpLoop = 0 break.
		if warpLoop > 1 {
			if (warpSeconds(nn:eta - dt - 60) > 600 and nodeCreator:istype("delegate")) {
			//	recreate node if warped more than 10 minutes and we have node creator delegate
				unlock steering. // release references before deleting nodes
				unlock steerDir.
				set nn to false.
				utilRemoveNodes().
				nodeCreator().
				wait 0.
				set nn to nextnode.
				if resetBurnTime set burnTime to burnTimeForDv(nn:deltav:mag).
				set dt to burnTime/2.
				sas off.
				lock steerDir to lookdirup(nn:deltav, positionAt(ship,time:seconds+nn:eta)-body:position).
				lock steering to steerDir.
			}
			set warpLoop to 1.
		} else {
			warpSeconds(nn:eta - dt - 10).
			break.
		}
	}
	
	local dv0 is nn:deltav.
	local dvMin is dv0:mag.
	local minThrottle is 0.
	local maxThrottle is 0.
	lock throttle to min(maxThrottle,max(minThrottle,min(dvMin,nn:deltav:mag)*ship:mass/max(1,availableThrust))).
	lock steerDir to lookdirup(nn:deltav,ship:position-body:position).
	
	local almostThere to 0.
	local choked to 0.
	local warned to false.
	
	if nn:eta-dt > 5 {
		physWarp(1).
		wait until nn:eta-dt <= 2.
		resetWarp().
	}
	wait until nn:eta-dt <= 1.
	until dvMin < 0.05
	{
		if stagingCheck() uiWarning("Node", "Stage " + stage:number + " separation during burn").
		wait 0. //Let a physics tick run each loop.
	
		local dv is nn:deltav:mag.
		if dv < dvMin set dvMin to dv.
	
		if ship:availablethrust > 0 {
			if utilIsShipFacing(steerDir,node_okFacing,2) {
				set minThrottle to 0.01.
				set maxThrottle to 1.
			} else {
				// we are not facing correctly! cut back thrust to 10% so gimbaled
				// engine will push us back on course
				set minThrottle to 0.1.
				set maxThrottle to 0.1.
				rcs on.
			}
			if vdot(dv0, nn:deltaV) < 0 break.	// overshot (node delta vee is pointing opposite from initial)
			if dv > dvMin + 0.1 break.			// burn DV increases (off target due to wobbles)
			if dv <= 0.2 {						// burn DV gets too small for main engines to cope with
				if almostThere = 0 set almostThere to time:seconds.
				if time:seconds-almostThere > 5 break.
				if dv <= 0.05 break.
			}
			set choked to 0.
		} else {
			if choked = 0 set choked to time:seconds.
			if not warned and time:seconds-choked > 3 {
				set warned to true.
				uiWarn("Node", "No acceleration").
			}
			if time:seconds-choked > 30
				uiFatal("Node", "No acceleration").
		}
	}
	
	set ship:control:pilotMainThrottle to 0.
	unlock throttle.
	
	// Make fine adjustments using RCS (for up to 15 seconds)
	//if nn:deltaV:mag > 0.1 utilRCSCancelVelocity({return nn:deltaV.},0.1,15).
	//else 
	wait 1.
	
	// Fault if remaining dv > 5% of initial AND mag is > 0.1 m/s
	if nn:deltaV:mag > dv0:mag * 0.05 and nn:deltaV:mag > 0.1 {
	uiFatal("Node", "BURN FAULT " + round(nn:deltaV:mag, 1) + " m/s").
	} else if nn:deltaV:mag > 0.1 {
	uiWarning("Node", "BURN FAULT " + round(nn:deltaV:mag, 1) + " m/s").
	}
	
	remove nn.
	// Release all controls to be safe.
	UNLOCK THROTTLE.
	UNLOCK STEERING.
	set ship:control:pilotMainThrottle to 0.
	set ship:control:neutralize to true.
	set sas to sstate.
	set rcs to rstate.
}
function uiConsole 
{
	parameter prefix.
	parameter msg.
	
	local logtext is "T+" + round(time:seconds) + " " + prefix + ": " + msg.
	print logtext.
	
	if logconsole {
		LOG logtext to "log.txt".
		IF HOMECONNECTION:ISCONNECTED {
		COPYPATH("log.txt","0:/logs/"+SHIP:NAME+".txt").
		}
	}
}
function uiBanner 
{
	parameter prefix.
	parameter msg.
	parameter sound is 1. // Sound to play when show the message: 1 = Beep, 2 = Chime, 3 = Alert
	
	if (time:seconds - ui_announce > 60) or (ui_announceMsg <> msg) {
		uiConsole(prefix, msg).
		hudtext(msg, 10, 2, 24, GREEN, false).
		set ui_announce to time:seconds.
		set ui_announceMsg to msg.
		// Select a sound.
		if      sound = 1 uiBeep().
		else if sound = 2 uiChime().
		else if sound = 3 uiAlarm().
	}
}
function uiWarning 
{
  parameter prefix.
  parameter msg.

  uiConsole(prefix, msg).
  hudtext(msg, 10, 4, 36, YELLOW, false).
  uiAlarm().
}
function uiError 
{
  parameter prefix.
  parameter msg.

  uiConsole(prefix, msg).
  hudtext(msg, 10, 4, 36, RED, false).
  uiAlarm().
}
function uiShowPorts 
{
	parameter myPort.
	parameter hisPort.
	parameter dist.
	parameter ready.
	
	if myPort <> 0 {
		set ui_myPort:start to myPort:position.
		set ui_myPort:vec to myPort:portfacing:vector*dist.
		if ready {
		set ui_myPort:color to GREEN.
		} else {
		set ui_myPort:color to RED.
		}
		set ui_myPort:show to true.
	} else {
		set ui_myPort:show to false.
	}
	
	if hisPort <> 0 {
		set ui_hisPort:start to hisPort:position.
		set ui_hisPort:vec to hisPort:portfacing:vector*dist.
		set ui_hisPort:show to true.
	} else {
		set ui_hisPort:show to false.
	}
}
function uiFatal 
{
  parameter prefix.
  parameter message.

  uiError(prefix, message + " - RESUME CONTROL").
  wait 3.
  reboot.
}
function uiAssertAccel 
{
	parameter prefix.
	
	local uiAccel is ship:availablethrust / ship:mass. // kN over tonnes; 1000s cancel
	
	if uiAccel <= 0 {
		uiFatal("Maneuver", "ENGINE FAULT").
	} else {
		return uiAccel.
	}
}
function uiDebug 
{
  parameter msg.

  if ui_debug {
    uiConsole("Debug", msg).
    hudtext(msg, 3, 3, 24, WHITE, false).
  }
}
function uiDebugNode 
{
	parameter T.
	parameter mdv.
	parameter msg.
	
	if ui_debugNode {
		local nd is node(T, mdv:x, mdv:y, mdv:z).
		add(nd).
		uiDebug(msg).
		wait(0.25).
		remove(nd).
	}
}
function uiDebugAxes 
{
	parameter origin.
	parameter dir.
	parameter length.
	
	if ui_debugAxes = true {
		if length:x <> 0 {
		set ui_DebugStb:start to origin.
		set ui_DebugStb:vec to dir:starvector*length:x.
		set ui_DebugStb:show to true.
		} else {
		set ui_DebugStb:show to false.
		}
	
		if length:y <> 0 {
		set ui_DebugUp:start to origin.
		set ui_DebugUp:vec to dir:upvector*length:y.
		set ui_DebugUp:show to true.
		} else {
		set ui_DebugUp:show to false.
		}
	
		if length:z <> 0 {
		set ui_DebugFwd:start to origin.
		set ui_DebugFwd:vec to dir:vector*length:z.
		set ui_DebugFwd:show to true.
		} else {
		set ui_DebugFwd:show to false.
		}
	}
}
FUNCTION uiAlarm 
{
    local vAlarm TO GetVoice(0).
    set vAlarm:wave to "TRIANGLE".
    set vAlarm:volume to 0.5.
      vAlarm:PLAY(
          LIST(
              NOTE("A#4", 0.2,  0.25), 
              NOTE("A4",  0.2,  0.25), 
              NOTE("A#4", 0.2,  0.25), 
              NOTE("A4",  0.2,  0.25),
              NOTE("R",   0.2,  0.25),
              NOTE("A#4", 0.2,  0.25), 
              NOTE("A4",  0.2,  0.25), 
              NOTE("A#4", 0.2,  0.25), 
              NOTE("A4",  0.2,  0.25)
          )
      ).
}
FUNCTION uiBeep 
{
  local vBeep to GetVoice(0).
  set vBeep:volume to 0.35.
  set vBeep:wave to "SQUARE".
  vBeep:PLAY(NOTE("A4",0.1, 0.1)).
}
FUNCTION uiChime 
{
  local vChimes to GetVoice(0).
  set vChimes:volume to 0.25.
  set vChimes:wave to "SINE". 
  vChimes:PLAY(
      LIST(
        NOTE("E5",0.8, 1),
        NOTE("C5",1,1.2)
        )).
}
function uiTerminalMenu 
{
  // Shows a menu in the terminal window and waits for user input.
  // The parameter is a lexicon of a key to be pressed and a text to be show.
  // ie.: 
  // LOCAL MyOptions IS LEXICON("Y","Yes","N","No").
  // LOCAL myVal is uiTerminalMenu(MyOptions).
  //
  // That code will produce a menu with two options, Stay or Go, and will return 1 or 2 depending which key user press.

	parameter Options.
	local Choice is 0.
	local Term is Terminal:Input().
	local ValidSelection is false.
	Until ValidSelection {
    uiBanner("Terminal","Please choose an option in Terminal.",2).
		print " ".
		print "=================".
		Print "Choose an option:".
		Print "=================".
		print " ".
		for Opt in Options:keys {
			print Opt + ") - " + Options[Opt].
		}
		print "?>".

		Term:CLEAR().
		set Choice to Term:GETCHAR().
		if Options:HASKEY(Choice) {
			set ValidSelection to true.
      print "===> " + Options[Choice].
		}
		else print "Invalid selection".
	}
	return Choice.
}
function uiTerminalList 
{
  // Shows a menu in the terminal window and waits for user input.
  
	parameter Options.

	local Choice is 0.
  local page is 0.
  local KeyPressed is 0.
	local Term is Terminal:Input().
	local ValidSelection is false.

  uiBanner("Terminal","Please make a choice in the Terminal.",2).
	Until ValidSelection {
    clearscreen.
		print " ".
		print "=================".
		Print "Choose an option:".
		Print "=================".
		print " ".
		from { local i is 10*page. } until i = min(10+(10*page),Options:length) step { set i to i+1. } do {
			print (i-(10*page)) + ") - " + Options[i].
		}
		print "Showing " + min(Options:Length,10+(10*Page)) + " of " + Options:Length() + " options.".
    print "Use arrows < and > to change pages".

		Term:CLEAR().
		set KeyPressed to Term:GETCHAR().
    if KeyPressed = Term:RightCursorOne {
      if Options:Length > 10+(10*Page) set Page to Page + 1.
    }
    else if KeyPressed = Term:LeftCursorOne {
      if Page > 0 set Page to Page - 1.
    }
    else if "0123456789":Contains(KeyPressed) {
      set choice to KeyPressed:ToNumber()+(10*Page).
      if choice < Options:Length {
        set ValidSelection to true.
        print "===> " + Options[Choice].
      }
    }
		else print "Invalid selection".
	}
	return Choice.
}
FUNCTION uiMSTOKMH 
{ 
    // Return m/s in km/h. 
    PARAMETER MS.
    RETURN MS * 3.6.
}
function utilClosestApproach 
{
	parameter ship1.
	parameter ship2.
	
	local Tmin is time:seconds.
	local Tmax is Tmin + 2 * max(ship1:obt:period, ship2:obt:period).
	local Rbest is (ship1:position - ship2:position):mag.
	local Tbest is 0.
	
	until Tmax - Tmin < 5 {
		local dt2 is (Tmax - Tmin) / 2.
		local Rl is utilCloseApproach(ship1, ship2, Tmin, Tmin + dt2).
		local Rh is utilCloseApproach(ship1, ship2, Tmin + dt2, Tmax).
		if Rl < Rh {
		set Tmax to Tmin + dt2.
		} else {
		set Tmin to Tmin + dt2.
		}
	}
	
	return (Tmax+Tmin) / 2.
}
function utilCloseApproach 
{
  parameter ship1.
  parameter ship2.
  parameter Tmin.
  parameter Tmax.

  local Rbest is (ship1:position - ship2:position):mag.
  local Tbest is 0.
  local dt is (Tmax - Tmin) / 32.

  local T is Tmin.
  until T >= Tmax {
    local X is (positionat(ship1, T)) - (positionat(ship2, T)).
    if X:mag < Rbest {
      set Rbest to X:mag.
    }
    set T to T + dt.
  }

  return Rbest.
}
FUNCTION utilFaceBurn 
{

// This function is intended to use with shuttles and spaceplanes that have engines not in line with CoM.
// Usage: LOCK STEERING TO utilFaceBurn(THEDIRECTIONYOUWANTTOSTEER).
// Example: LOCK STEERING TO utilFaceBurn(PROGRADE).

	PARAMETER DIRTOSTEER. // The direction you want the ship to steer to
	LOCAL NEWDIRTOSTEER IS DIRTOSTEER. // Return value. Defaults to original direction.
	LOCAL OSS IS LEXICON(). // Used to store all persistent data
	LOCAL trueacc IS 0. // Used to store ship acceleration vector
	
	FUNCTION HasSensors 
	{ 
		// Checks if ship have required sensors:
		// - Accelerometer (Double-C Seismic Accelerometer) 
		// - Gravity Sensor (GRAVMAX Negative Gravioli Detector)
		LOCAL HasA IS False.
		LOCAL HasG IS False.
		LOCAL SENSELIST is LIST().
		LIST SENSORS IN SENSELIST.
		FOR S IN SENSELIST {
		IF S:TYPE = "ACC" { SET HasA to True. }
		IF S:TYPE = "GRAV" { SET HasG to True. }
		}
		IF HasA AND HasG { RETURN TRUE. }
		ELSE { RETURN FALSE. }
	}
	
	FUNCTION InitOSS {
		// Initialize persistent data.
		LOCAL OSS IS LEXICON().
		OSS:add("t0",time:seconds).
		OSS:add("pitch_angle",0).
		OSS:add("pitch_sum",0).
		OSS:add("yaw_angle",0).
		OSS:add("yaw_sum",0).
		OSS:add("Average_samples",0).
		OSS:add("Average_Interval",1).
		OSS:add("Average_Interval_Max",5).
		OSS:add("Ship_Name",SHIP:NAME:TOSTRING).
		OSS:add("HasSensors",HasSensors()).
		
		RETURN OSS.
	}
	
	IF EXISTS("oss.json") { // Looks for saved data
		SET OSS TO READJSON("oss.json"). 
		IF OSS["Ship_Name"] <> SHIP:NAME:TOSTRING {
		SET OSS TO InitOSS(). 
		}
	}
	ELSE {
		SET OSS TO InitOSS(). 
	}
	
	IF OSS["HasSensors"] { // Checks for sensors
		LOCK trueacc TO ship:sensors:acc - ship:sensors:grav.
	}
	ELSE { // If ship have no sensors, just returns direction without any correction
		RETURN DIRTOSTEER. 
	}
	
	
	// Only account for offset thrust if there is thrust!
	if throttle > 0.1 { 
		local dt to time:seconds - OSS["t0"]. // Delta Time
		if dt > OSS["Average_Interval"]  {
			// This section takes the average of the offset, reset the average counters and reset the timer.
			SET OSS["t0"] TO TIME:SECONDS.
			if OSS["Average_samples"] > 0 {
			// Pitch 
			SET OSS["pitch_angle"] TO OSS["pitch_sum"] / OSS["Average_samples"]. 
			SET OSS["pitch_sum"] to OSS["pitch_angle"].
			// Yaw
			SET OSS["yaw_angle"] TO OSS["yaw_sum"] / OSS["Average_samples"]. 
			SET OSS["yaw_sum"] to OSS["yaw_angle"].
			// Sample count
			SET OSS["Average_samples"] TO 1.
			// Increases the Average interval to try to keep the adjusts more smooth.
			if OSS["Average_Interval"] < OSS["Average_Interval_Max"] { 
				SET OSS["Average_Interval"] to max(OSS["Average_Interval_Max"], (OSS["Average_Interval"] + dt)) .
			} 
			}
		}
		else { // Accumulate the thrust offset error to be averaged by the section above
			
			// Thanks to reddit.com/user/ElWanderer_KSP
			// exclude the left/right vector to leave only forwards and up/down
			LOCAL pitch_error_vec IS VXCL(FACING:STARVECTOR,trueacc).
			LOCAL pitch_error_ang IS VANG(FACING:VECTOR,pitch_error_vec).
			If VDOT(FACING:TOPVECTOR,pitch_error_vec) > 0{
				SET pitch_error_ang TO -pitch_error_ang.
			}
	
			// exclude the up/down vector to leave only forwards and left/right
			LOCAL yaw_error_vec IS VXCL(FACING:TOPVECTOR,trueacc).
			LOCAL yaw_error_ang IS VANG(FACING:VECTOR,yaw_error_vec).
			IF VDOT(FACING:STARVECTOR,yaw_error_vec) < 0{
				SET yaw_error_ang TO -yaw_error_ang.
			}
			//LOG "P: " + pitch_error_ang TO "0:/oss.txt".
			//LOG "Y: " + yaw_error_ang TO "0:/oss.txt".
			set OSS["pitch_sum"] to OSS["pitch_sum"] + pitch_error_ang.
			set OSS["yaw_sum"] to OSS["yaw_sum"] + yaw_error_ang.
			SET OSS["Average_samples"] TO OSS["Average_samples"] + 1.
		}
		// Set the return value to original direction combined with the thrust offset
		//SET NEWDIRTOSTEER TO r(0-OSS["pitch_angle"],OSS["yaw_angle"],0) * DIRTOSTEER.
		SET NEWDIRTOSTEER TO DIRTOSTEER.
		IF ABS(OSS["pitch_angle"]) > 1 { // Don't bother correcting small errors
			SET NEWDIRTOSTEER TO ANGLEAXIS(-OSS["pitch_angle"],SHIP:FACING:STARVECTOR) * NEWDIRTOSTEER.
		}
		IF ABS(OSS["yaw_angle"]) > 1 { // Don't bother correcting small errors
			SET NEWDIRTOSTEER TO ANGLEAXIS(OSS["yaw_angle"],SHIP:FACING:UPVECTOR) * NEWDIRTOSTEER.
		}
	} 
	// This function is pretty processor intensive, make sure it don't execute too much often.
	WAIT 0.2.
	// Saves the persistent values to a file.
	WRITEJSON(OSS,"oss.json").
	RETURN NEWDIRTOSTEER.
}
FUNCTION utilRCSCancelVelocity 
{
	parameter CancelVec. 
	parameter residualSpeed is 0.01. // Admissible residual speed.
	parameter MaximumTime is 15. // Maximum time to achieve results.
	
	lock tgtVel to -CancelVec@.
	local rstatus is rcs. 
	local sstatus is sas.
	sas off.
	lock steering to ship:facing. 
	uiDebug("Fine tune with RCS").
	rcs on.
	local t0 is time.
	until tgtVel:mag < residualSpeed or (time - t0):seconds > MaximumTime 
	{
		local sense is ship:facing.
		local dirV is V(
		vdot(tgtVel, sense:starvector),
		vdot(tgtVel, sense:upvector),
		vdot(tgtVel, sense:vector)
		).
		set ship:control:translation to dirV:normalized.
		wait 0.
	}

	set ship:control:translation to v(0,0,0).
	set ship:control:neutralize to true.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	UNLOCK STEERING.
	UNLOCK THROTTLE.
	set rcs to rstatus.
	set sas to sstatus.  
}
function utilIsShipFacing 
{ 
	parameter face.
	parameter maxDeviationDegrees is 8.
	parameter maxAngularVelocity is 0.01.
	
	if face:istype("direction") set face to face:vector.
	return vdot(face:normalized, ship:facing:forevector:normalized) >= cos(maxDeviationDegrees) and ship:angularvel:mag < maxAngularVelocity. 
}
FUNCTION utilLongitudeTo360 
{ 
    PARAMETER lng.
    RETURN MOD(lng + 360, 360).
}
function utilReduceTo360 
{
  parameter ang.
  return ang - 360 * floor(ang/360).
}
function utilCompassHeading 
{
  // Returns the same HDG number that Kerbal shows in bottom of Nav Ball
  local northPole is latlng( 90, 0). //Reference heading
  if northPole:bearing <= 0 {
        return ABS(northPole:bearing).
    }
    else {
        return (180 - northPole:bearing) + 180.
    }
}
function utilHeadingToBearing 
{
  parameter hdg.
  if hdg > 180 return hdg-360.
  else if hdg < -180 return hdg+360.
  else return hdg.
}
function utilRemoveNodes 
{
	if not hasNode return.
	for n in allNodes remove n.
	wait 0.
}
function utilAngleTo360 
{
	parameter a.
	set a to mod(a, 360).
	if a < 0 set a to a + 360.
	return a.
}
function utilMeanFromTrue 
{
	parameter a.
	parameter obt is orbit.
	set e to obt:eccentricity.
	if e < 0.001 return a. //circular, no need for conversion
	if e >= 1 { print "ERROR: meanFromTrue("+round(a,2)+") with e=" + round(e,5). return a. }
	set a to a*.5.
	set a to 2*arctan2(sqrt(1-e)*sin(a),sqrt(1+e)*cos(a)).
	return a - e * sin(a) * 180/constant:pi.
}
function utilDtMean 
{
	parameter a.
	parameter obt is orbit.
	return utilAngleTo360(a - utilMeanFromTrue(obt:trueAnomaly)) / 360 * obt:period.
}
function utilDtTrue 
{
	parameter a.
	parameter obt is orbit.
	return utilAngleTo360(utilMeanFromTrue(a) - utilMeanFromTrue(obt:trueAnomaly)) / 360 * obt:period.
}
function resetWarp 
{
	kUniverse:timeWarp:cancelWarp().
	set warp to 0.
	wait 0.
	wait until kUniverse:timeWarp:isSettled.
	set warpMode to "RAILS".
	wait until kUniverse:timeWarp:isSettled.
}
function railsWarp 
{
	parameter w.
	if warpMode <> "RAILS"
		resetWarp().
	set warp to w.
}
function physWarp 
{
	parameter w.
	if warpMode <> "PHYSICS" {
		kUniverse:timeWarp:cancelWarp().
		wait until kUniverse:timeWarp:isSettled.
		set warpMode to "PHYSICS".
	}
	set warp to w.
}
function warpSeconds 
{
	parameter seconds.
	if seconds <= 1 return 0.
	local t1 is time:seconds+seconds.
	until time:seconds >= t1-1 {
		resetWarp().
		if time:seconds < t1-10 {
			warpTo(t1).
			wait 1.
			wait until time:seconds >= t1-1 or (warp = 0 and kUniverse:timeWarp:isSettled).
		} else
		{// warpTo will not warp 10 seconds and less
			if time:seconds < t1-3 {
				physWarp(4).
				wait until time:seconds >= t1-3.
			}
			if time:seconds < t1-2 {
				physWarp(3).
				wait until time:seconds >= t1-2.
			}
			if time:seconds < t1-1 {
				physWarp(2).
				wait until time:seconds >= t1-1.
			}
			resetWarp().
			break.
		}
	}
	resetWarp().
	wait until time:seconds >= t1.
	return seconds.
}
function stagingDecoupledIn 
{
	parameter part.

	local function partIsDecoupler {
		parameter part.
		for m in stagingDecouplerModules if part:modules:contains(m) {
			if part:tag:matchesPattern("\bnoauto\b") and part:stage+1 >= stagingMaxStage
				set stagingMaxStage to part:stage+1.
			return true.
		}
		return false.
	}
	until partIsDecoupler(part) {
		if not part:hasParent return -1.
		set part to part:parent.
	}
	return part:stage.
}
function stagingPrepare 
{

	wait until stage:ready.
	set stagingNumber to stage:number.
	if stagingResetMax and stagingMaxStage >= stagingNumber
		set stagingMaxStage to 0.
	stagingEngines:clear().
	stagingTanks:clear().

	// prepare list of tanks that are to be decoupled and have some fuel
	LOCAL parts is LIST().
	list parts in parts.
	for p in parts {
		local amount is 0.
		for r in p:resources if stagingTankFuels:contains(r:name)
			set amount to amount + r:amount.
		if amount > 0.01 and stagingDecoupledIn(p) = stage:number-1
			stagingTanks:add(p).
	}

	// prepare list of engines that are to be decoupled by staging
	// and average ISP for stageDeltaV()
	LOCAL engines is LIST().
	list engines in engines.
	local thrust is 0.
    local flow is 0.
	for e in engines if e:ignition and e:isp > 0
	{
		if stagingDecoupledIn(e) = stage:number-1
			stagingEngines:add(e).

		local t is e:availableThrust.
		set thrust to thrust + t.
		set flow to flow + t / e:isp. // thrust=isp*g0*dm/dt => flow = sum of thrust/isp
	}
	set stageAvgIsp to 0.
    if flow > 0 set stageAvgIsp to thrust/flow.
	set stageStdIsp to stageAvgIsp * isp_g0.

	// prepare dry mass for stageDeltaV()
    local fuelMass is 0.
    for r in stage:resources if stagingConsumed:contains(r:name)
		set fuelMass to fuelMass + r:amount*r:density.
	set stageDryMass to ship:mass-fuelMass.
}
function stagingCheck 
{
	wait until stage:ready.
	if stage:number <> stagingNumber
		stagingPrepare().
	if stage:number <= stagingMaxStage
		return.

	// need to stage because all engines are without fuel?
	local function checkEngines {
		if stagingEngines:empty return false.
		for e in stagingEngines if not e:flameout
			return false.
		return true.
	}

	// need to stage because all tanks are empty?
	local function checkTanks {
		if stagingTanks:empty return false.
		for t in stagingTanks {
			local amount is 0.
			for r in t:resources if stagingTankFuels:contains(r:name)
				set amount to amount + r:amount.
			if amount > 0.01 return false.
		}
		return true.
	}

	// check staging conditions and return true if staged, false otherwise
	if availableThrust = 0 or checkEngines() or checkTanks() {
		stage.
		// this is optional and unnecessary if TWR does not change much,
		// but can prevent weird steering behaviour after staging
		steeringManager:resetPids().
		// prepare new data
		stagingPrepare().
		return true.
	}
	return false.
}
function stageDeltaV 
{
	if stageAvgIsp = 0 or availableThrust = 0 {
		set stageBurnTime to 0.
		return 0.
	}

	set stageBurnTime to stageStdIsp*(ship:mass-stageDryMass)/availableThrust.
	return stageStdIsp*ln(ship:mass / stageDryMass).
}
function burnTimeForDv 
{
	parameter dv.
	return stageStdIsp*ship:mass*(1-constant:e^(-dv/stageStdIsp))/availableThrust.
}
function thrustToWeight 
{
	return availableThrust/(ship:mass*body:mu)*(body:radius+altitude)^2.
}
FUNCTION HMtransfer
{

	if ship:body <> target:body {
	uiError("Transfer", "Target outside of SoI").
	wait 5.
	reboot.
	}
	
	local ri is abs(obt:inclination - target:obt:inclination).
	
	if ri > 0.25 
	{
		uiBanner("Transfer", "Align planes with " + target:name).
		node_inc().
		run_node().
	}
	
	node_hoh().
	uiBanner("Transfer", "Transfer injection burn").
	run_node().
	SAS off.
	clearscreen.
	set ag9 to false.
	lock steering to sun:position.
	print "Warp speed if you wish".
	LOCAL whoiam to ship:body.
	print "Press 9 to warp just before SOI change".
	until eta:transition < 10
	{
		if ag9 {FNwarp(eta:transition-120).}else{wait 1.}
	}
	set ag9 to false.
	wait until not (ship:body = whoiam).
	clearscreen.
	Print "5 Secs to get any data".
	wait 5.
	unlock steering.
	wait 2.
	// Deal with collisions and retrograde orbits (sorry this script can't do free return)
	local minperi is (body:atm:height + (body:radius * 0.3)).
	
	if ship:periapsis < minperi or ship:obt:inclination > 90 
	{
		sas off.
		LOCK STEERING TO heading(90,0).
		wait 10.
		LOCK deltaPct TO (ship:periapsis - minperi) / minperi.
		LOCK throttle TO max(1,min(0.1,deltaPct)).
		Wait Until ship:periapsis > minperi.
		LOCK throttle to 0.
		UNLOCK throttle.
		UNLOCK STEERING.
		sas on.
	}
	
	uiBanner("Transfer", "Transfer braking burn").
}
function hm_return 
{
	declare local parameter target_periapsis.
	local r1 to (BODY:OBT:SEMIMAJORAXIS - 1.5*SHIP:OBT:SEMIMAJORAXIS).
	local r2 to (BODY:BODY:RADIUS + target_periapsis ).
	local dv_hx_kerbin is BODY:OBT:VELOCITY:ORBIT:MAG * (sqrt((2*r2)/(r1 + r2)) -1).
	local transfer_time to constant:pi * sqrt((((r1 + r2)^3)/(8*BODY:BODY:MU))).
	local r1 is SHIP:OBT:SEMIMAJORAXIS.
	local r2 is BODY:SOIRADIUS.
	local v2 is dv_hx_kerbin.
	local mu to BODY:MU.
	local ejection_vel is sqrt((r1*(r2*v2^2 - 2 * mu) + 2*r2*mu ) / (r1*r2) ).
	local delta_v to  abs(SHIP:OBT:VELOCITY:ORBIT:MAG-ejection_vel).
	local vel_vector is SHIP:VELOCITY:ORBIT:VEC.
	set vel_vector:MAG to (vel_vector:MAG + delta_v).
	local ship_pos_orbit_vector is SHIP:Position - BODY:Position.
	local angular_momentum_h is (vcrs(vel_vector,ship_pos_orbit_vector)):MAG.
	local spec_energy is ((vel_vector:MAG^2)/2) - (BODY:MU/SHIP:OBT:SEMIMAJORAXIS).
	local ecc is sqrt(1 + ((2*spec_energy*angular_momentum_h^2)/BODY:MU^2)).
	local launch_angle is arcsin(1/ecc).
	local body_orbit_direction is BODY:ORBIT:VELOCITY:ORBIT:DIRECTION:YAW.
	local ship_orbit_direction is SHIP:ORBIT:VELOCITY:ORBIT:DIRECTION:YAW.
	local launch_point_dir is (body_orbit_direction - 180 + launch_angle).
	local node_eta is mod((360+ ship_orbit_direction - launch_point_dir),360)/360 * SHIP:OBT:PERIOD.
	local my_node to NODE(time:seconds + node_eta, 0, 0, delta_v).
	ADD my_node.
	//local lock current_peri to ORBITAT(SHIP,time+transfer_time):PERIAPSIS.
	//until abs (current_peri - target_periapsis) < 300 {
	//	if current_peri < target_periapsis {
	//		set my_node:PROGRADE to my_node:PROGRADE - 0.05.
	//	} else {
	//		set my_node:PROGRADE to my_node:PROGRADE + 0.05.
	//	}
	//}
	wait 5.
}
FUNCTION node_hoh
{
	parameter MaxOrbitsToTransfer is 5.
	parameter MinLeadTime is 30.
	
	// Compute prograde delta-vee required to achieve Hohmann transfer; < 0 means
	// retrograde burn.
	function hohmannDv 
	{
		parameter r1 is (ship:obt:semimajoraxis + ship:obt:semiminoraxis) / 2.
		parameter r2 is (target:obt:semimajoraxis + target:obt:semiminoraxis) / 2.
		
		return sqrt(body:mu / r1) * (sqrt( (2*r2) / (r1+r2) ) - 1).
	}
	
	// Compute time of Hohmann transfer window.
	function hohmannDt 
	{
		local r1 is ship:obt:semimajoraxis.
		local r2 is target:obt:semimajoraxis.
		
		local pt is 0.5 * ((r1+r2) / (2*r2))^1.5.
		local ft is pt - floor(pt).
		
		// angular distance that target will travel during transfer
		local theta is 360 * ft.
		// necessary phase angle for vessel burn
		local phi is 180 - theta.
		
		uiDebug("Phi:" + phi).
		
		// Angles to universal reference direction. (Solar prime)
		LOCAL sAng to ship:obt:lan+obt:argumentofperiapsis+obt:trueanomaly. 
		LOCAL tAng to target:obt:lan+target:obt:argumentofperiapsis+target:obt:trueanomaly. 
		
		local timeToHoH is 0.
		LOCAL pAng is 0.
		LOCAL DeltaAng is 0.
		
		
		// Target and ship's angular speed.
		local tAngSpd is 360 / target:obt:period.
		local sAngSpd is 360 / ship:obt:period.
		
		// Phase angle rate of change, 
		local phaseAngRoC is tAngSpd - sAngSpd. 
		
		// Loop conditions variables
		local HasAcceptableTransfer is false.
		local IsStranded is false.
		local tries is 0.
		until HasAcceptableTransfer or IsStranded 
		{
		
			// Phase angle now.
			set pAng to utilReduceTo360(tAng - sAng).
			uiDebug("pAng: " + pAng).
			
			if r1 < r2 
			{ // Target orbit is higher
				set DeltaAng to utilReduceTo360(pAng - phi).
			}
			else 
			{ // Target orbit is lower
				set DeltaAng to utilReduceTo360(phi - pAng).
			}
			set timeToHoH to abs(DeltaAng / phaseAngRoC).
			uiDebug("TTHoh:" + timeToHoH).
		
			if timeToHoH > ship:obt:period * MaxOrbitsToTransfer set IsStranded to true.
			else if timeToHoH > MinLeadTime set HasAcceptableTransfer to true.
			else 
			{
				// Predict values in future
				set tAng to tAng + MinLeadTime*tAngSpd.
				set sAng to sAng + MinLeadTime*sAngSpd.
			}
			set tries to tries + 1.
			if tries > 1000 set IsStranded to true.
			if IsStranded break.
		}
		if IsStranded return "Stranded".
		else return timeToHoH + time:seconds.  
	}
	
	if body <> target:body 
	{
		uiWarning("Node", "Incompatible orbits").
	}
	if ship:obt:eccentricity > 0.01 
	{
		uiWarning("Node", "Eccentric ship e=" + round(ship:obt:eccentricity, 1)).
	}
	if target:obt:eccentricity > 0.01 
	{
		uiWarning("Node", "Eccentric target e=" +  + round(target:obt:eccentricity, 1)).
	}
	
	global node_ri is obt:inclination - target:obt:inclination.
	if abs(node_ri) > 0.2 
	{
		uiWarning("Node", "Bad alignment ri=" + round(node_ri, 1)).
	}
	
	uiDebug("Hohmann time").
	global node_T is hohmannDt().
	
	if node_T = "Stranded" 
	{
		uiError("Node", "STRANDED").
	}
	else 
	{
		uiDebug("Hohmann delta V").
		uiDebug("Transfer eta=" + round(node_T - time:seconds, 0)).
		uiDebug("Transfer dv0=" + round(hohmannDv, 1)).
		
		local r1 is (positionat(ship,node_T)-body:position):mag.
		global node_dv is hohmannDv(r1).
		uiDebug("Transfer dv1=" + round(node_dv, 1) + ", r1=" + round(r1)).
		
		local nd is node(node_T, 0, 0, node_dv).
		add nd.
		
		local r2 is (positionat(target,node_T+nd:orbit:period/2)-body:position):mag.
		set node_dv to hohmannDv(r1,r2).
		set nd:prograde to node_dv.
		uiDebug("Transfer dv2=" + round(node_dv, 1) + ", r2=" + round(r2)).
	}

}
FUNCTION FNwarp
{
	declare parameter dt.
	
	LOCAL TW to kuniverse:timewarp.
	
	if dt > 0 
	{
		set TW:MODE to "RAILS".
		tw:warpto(time:seconds + dt).
		wait dt.
		wait until tw:warp = 0 and tw:ISSETTLED.
	}
}
FUNCTION landRadarAltimeter 
{
    Return ship:altitude - ship:geoposition:terrainheight.
}
FUNCTION node_inc
{
	parameter incl is "".

	utilRemoveNodes().
	
	local di is 0. // inclination difference (target-current)
	local ta is 0. // angle from periapsis to DN (burn in normal direction here)
	local t0 is time:seconds.
	local i0 is orbit:inclination.
	
	if incl <> "" or not hasTarget
	{
		local i1 is 0.
		if incl <> "" set i1 to incl.
		set di to i1-i0.
		set ta to -orbit:argumentOfPeriapsis.
	}
	else
	{
		local i1 is target:orbit:inclination.
		local sp is ship:position-body:position.
		local tp is target:position-body:position.
		local sv is ship:velocity:orbit.
		local tv is target:velocity:orbit.
		local sn is vcrs(sv, sp). // our normal vector
		local tn is vcrs(tv, tp). // its normal vector
		local ln is vcrs(tn, sn). // from AN to DN
		set di to vang(sn, tn).
		set ta to vang(sp, ln).
		if vang(vcrs(sp,ln),sn) < 90 set ta to -ta.
		set ta to ta + orbit:trueAnomaly.
	}
	
	set ta to utilAngleTo360(ta).
	if ta < orbit:trueAnomaly { set ta to ta+180. set di to -di. }
	local dt is utilDtTrue(ta).
	local t1 is t0+dt.
	
	local v is velocityAt(ship, t1):orbit:mag.
	local nv is v * sin(di).
	local pv is v *(cos(di)-1).
	add node(t1, 0, nv, pv).
}
FUNCTION circ_alt
{
	parameter alt.
	
	if obt:eccentricity < 0.001 
	{ // For (almost) circular orbits, just change the altitude and recircularize
		node_alt(alt).
		local prograde is nextnode:prograde.
		run_node().
		
		if prograde < 0 
		{ // Means it raised the apoapsis
			node_apo(obt:periapsis).
			run_node().
		} else 
		{
			node_peri(obt:apoapsis).
			run_node().
		}
	} else 
	{ // For eliptical orbits
		//Added by FellipeC
		if alt > obt:periapsis 
		{
			// Decrease apoapsis
			node_apo(alt).
			run_node().
			node_peri(alt).
			run_node().
		}
		else 
		{
			// Decresase periapsis
			node_peri(alt).
			run_node().
			node_apo(alt).
			run_node().
		}
	}
}
FUNCTION node_inc_equ
{
	parameter target_inclination is 0.
	node_inc(target_inclination).
}

//Try to control from the specified docking port.
function partsControlFromDockingPort 
{
	parameter cPart. //The docking port you want to control from.
	local success is false.

	// Try to control from the port
	if cPart:modules:contains("ModuleDockingNode") {
		local m is cPart:getModule("ModuleDockingNode").
		for Event in m:allEventNames() {
			if Event:contains("Control") { m:DOEVENT(Event). success on. }
		}.
	}

	// Try to open/deploy the port
	if cPart:modules:contains("ModuleAnimateGeneric") {
		local m is cPart:getModule("ModuleAnimateGeneric").
		for Event in m:allEventNames() {
			if Event:contains("open") or Event:contains("deploy") or Event:contains("extend") { m:DOEVENT(Event). }
		}.
	}

	Return success.
}
function dockPrepare 
{
  parameter myPort, hisPort.

  // Control from myPort
  partsControlFromDockingPort(myPort).

  sas off.
  lock steering to lookdirup(-hisPort:portfacing:forevector, hisPort:portfacing:upvector).
  local t0 to time:seconds.
  wait until vdot(myPort:portfacing:forevector, hisPort:portfacing:forevector) < -0.996 
             or (time:seconds - t0 > 15).
  rcs on.
}
// Finish docking
function dockFinish 
{
  unlock steering.
  rcs off.
  sas on.
  uiShowPorts(0, 0, 0, false).
  uiDebugAxes(0,0, v(0,0,0)).
  clearvecdraws().
}
// Back off from target in order to approach from the correct side.
function dockBack 
{
  parameter backPos, backVel.

  //Move away from the station when backing more than start distance
  if backPos:z < -dock_start {
    if abs(backPos:x) < 50 {
      local vWantX is (backPos:X / abs(backPos:X)) * max(dock_dockV, 0.5).
      set dock_X1:setpoint to vWantX.
    }
    else set dock_X1:setpoint to 0.
    set ship:control:starboard to -1 * dock_X1:update(time:seconds, backVel:X).
  }

  set dock_Z:setpoint to dock_algnV.
  set ship:control:fore to -dock_Z:update(time:seconds, backVel:Z).
}
// Center docking ports in X/Y while slowly moving forward
function dockAlign 
{
  parameter alignPos, alignVel.

  // Taper X/Y/Z speed according to distance from target
  local vScaleX is min(abs(alignPos:X / dock_scale), dock_algnV).
  local vScaleY is min(abs(alignPos:Y / dock_scale), dock_algnV).
  local vScaleZ is min(abs(alignPos:Z / dock_start), dock_algnV).

  // Never align slower than final-approach speed
  local vWantX is -(alignPos:X / abs(alignPos:X)) * max(dock_dockV, dock_algnV * vScaleX).
  local vWantY is -(alignPos:Y / abs(alignPos:Y)) * max(dock_dockV, dock_algnV * vScaleY).
  local vWantZ is 0.

  if alignPos:Z >= dock_start {
    // Move forward at a distance-dependent speed between
    // approach and final-approach
    set vWantZ to -max(dock_dockV, dock_apchV*vScaleZ).
  } else {
    // Halt at approach-start distance
    set vWantZ to 0.
  }

  // Drift into alignment
  set dock_X1:setpoint to vWantX.
  set dock_Y1:setpoint to vWantY.
  set dock_Z:setpoint to vWantZ.
  set ship:control:starboard to -1 * dock_X1:update(time:seconds, alignVel:X).
  set ship:control:top to -1 * dock_Y1:update(time:seconds, alignVel:Y).
  set ship:control:fore to -1 * dock_Z:update(time:seconds, alignVel:Z).
}
// Close remaining distance to the target, slowing drastically near
// the end.
function dockApproach 
{
  parameter aprchPos, aprchVel, dockPort.
  if not dockComplete(dockPort) {

    // Taper Z speed according to distance from target
    local vScaleZ is min(abs(aprchPos:Z / dock_start), dock_scale).
    local vWantZ is 0.

    if aprchPos:Z < dock_final {
      if not dockPending(dockPort) {
        // Final approach: barely inch forward!
        set vWantZ to -dock_dockV.
      }
      else {
        set vWantZ to -dock_predV.
      }
    } else {
      // Move forward at a distance-dependent speed between
      // approach and final-approach
      set vWantZ to -max(dock_dockV, dock_apchV*vScaleZ).
    }

    set dock_Z:setpoint to vWantZ.
    set ship:control:fore to -dock_Z:update(time:seconds, aprchVel:Z).

    // Stay aligned
    set dock_X2:setpoint to 0.
    set dock_Y2:setpoint to 0.
    set ship:control:starboard to -1 * dock_X2:update(time:seconds, aprchPos:X).
    set ship:control:top to -1 * dock_Y2:update(time:seconds, aprchPos:Y).
  }
}
// Find suitable docking ports on self and target. Works using a heuristic:
//   - if current control part is a port, use it.
//   - if target is a vessel, find an unoccupied port that matches one in our ship
//   - (else target is already a port)
//   - find port on ship that fits the target port
function dockChoosePorts 
{
  local myPort is 0.
  local hisPort is 0.
  local hisPorts is list().
  local myPorts is list().

  // Docking port is already targeted
  if target:istype("DockingPort") 
     and target:state = "Ready" { 
    hisPorts:add(target).
  }
  else if target:istype("Vessel") { // ship is targeted; list all free ports.
    for port in target:dockingports { 
      if port:state = "Ready" hisPorts:add(port).
    }
  }

  // List all my ship ports not occupied. 
  if SHIP:CONTROLPART:istype("DockingPort") and 
  not SHIP:CONTROLPART:STATE:CONTAINS("docked") myPorts:add(SHIP:CONTROLPART).
  else {  
    for port in ship:dockingports {
      if not port:state:contains("docked") myPorts:add(port).
    }
  }

  // Checks if both ships have ports. 
  if myPorts:LENGTH = 0 OR hisPorts:LENGTH = 0 {
    return 0.
  }

  // Iterates through my ship ports and try to match with a port in target ship.
  if hisPort = 0 { 
    for myP in myPorts {
      if myPort = 0 {
        for hisP in hisPorts {
          if hisPort = 0 and hisP:NODETYPE = myP:NODETYPE {
            set myPort to myP.
            set hisPort to hisP.
          }
        }
      }
    }
  }
  else{ // Target port was pre-selected. Just find a suitable port in my ship
    for myP in myPorts {
      if myPort = 0 and hisPort:NODETYPE = myP:NODETYPE {
        set myPort to myP. 
      }
    }
  }

  if hisPort <> 0 and myPort <> 0 {
    set target to hisPort.
    return myPort.
  } else {
    return 0.
  }
}
function dockPending 
{
  parameter port.

  if port:state = "Acquire" {
    return true.
  } else {
    return false.
  }
}
// Determine whether chosen port is docked
function dockComplete 
{
  parameter port.

  if port:state:contains("Docked") {
    return true.
  } else {
    return false.
  }
}
// Cancel most velocity with respect to target. Leave residual speed
function dockMatchVelocity 
{
  parameter residual.

  set residual to max(0.1, residual). // Minimum residual value allowed.
  set RCSTheresold to 1. // Below this speed will use RCS

  // Don't let unbalanced RCS mess with our velocity
  rcs off.
  sas off.

  local matchStation is 0.
  if target:istype("Part") {
    set matchStation to target:ship.
  } else {
    set matchStation to target.
  }

  local matchAccel is uiAssertAccel("Dock").
  local lock matchVel to (ship:velocity:orbit - matchStation:velocity:orbit).

  if matchVel:mag > residual + RCSTheresold {
    // Point away from relative velocity vector
    local lock steerDir to utilFaceBurn(lookdirup(-matchVel, ship:facing:upvector)).
    lock steering to steerDir.
    wait until utilIsShipFacing(steerDir:vector).

    // Cancel velocity
    local v0 is matchVel:mag.
    lock throttle to min(matchVel:mag / matchAccel, 1.0).
    wait 0.1. // Let some time pass so the difference in speed is correcly acounted.
    // Stops the engines if reach near residual speed or if speed starts increasing. (May happens with some cases where the ship is not perfecly aligned with matchVel and residual is very low)
    until (matchVel:mag <= (residual + RCSTheresold)) or (matchVel:mag > v0) {
      set v0 to matchVel:mag.
      wait 0.1. //Assure measurements are made some time apart. 
    }

    lock throttle to 0.
    unlock throttle.
  }
  // Use RCS to cancel remaining dv
  unlock steering.
  utilRCSCancelVelocity(matchVel,residual,15).

  unlock matchVel.
}
// Undock functions
function dockChooseDeparturePort 
{
  for port in core:element:dockingPorts {
    if dockComplete(port) {
      return port.
    }
  }
  return 0.
}
Function dockControlFromCore 
{
    parameter ControlPart is ship:rootpart.

    if ControlPart:HasSuffix("CONTROLFROM") ControlPart:ControlFrom().
    else {
        for P in SHIP:PARTS {
            if not p:istype("DockingPort") and p:HasSuffix("CONTROLFROM") {
                P:ControlFrom().
                Break.
            }
        }.
    }
}
Function dockDefaultControlPart 
{
    Local CParts is SHIP:PARTSTAGGED("Control").
    if CParts:Length() = 1 Return CParts[0].
    else Return ship:rootpart.
}
function BrakeForEncounter 
{
  //Turn back to brake 
  local lock steerDir to utilFaceBurn(lookdirup(-vel:normalized, ship:facing:upvector)).
  lock steering to steerDir.
  wait until utilIsShipFacing(steerDir:vector) .
  local stopDistance is 0.5 * accel * (vel:mag / accel)^2.
  local dt is ((target:position:mag - stopDistance) / vel:mag) - 5.
  if dt > 0 {
    if dt > 60 {
      uiBanner("Maneuver", "Warping to brake").
      FNwarp(dt).
    }
    else {
      uiBanner("Maneuver", "Waiting " + round(dt) + " seconds to brake").
      wait dt.
    }
  }

  uiBanner("Maneuver", "Braking.").
  dockMatchVelocity(max(1.0, min(5.0, target:position:mag / 60.0))).
  unlock throttle.
  unlock steering.
}
FUNCTION node_vel_tgt
{
	// Figure out some basics
	local T is utilClosestApproach(ship, target).
	local Vship is velocityat(ship, T):orbit.
	local Vtgt is velocityat(target, T):orbit.
	local Pship is positionat(ship, T) - body:position.
	local dv is Vtgt - Vship.
	
	// project dv onto the radial/normal/prograde direction vectors to convert it
	// from (X,Y,Z) into burn parameters. Estimate orbital directions by looking
	// at position and velocity of ship at T.
	local r is Pship:normalized.
	local p is Vship:normalized.
	local n is vcrs(r, p):normalized.
	local sr is vdot(dv, r).
	local sn is vdot(dv, n).
	local sp is vdot(dv, p).
	
	// figure out the ship's braking time
	local accel is uiAssertAccel("Node").
	local dt is dv:mag / accel.
	
	// Time the burn so that we end thrusting just as we reach the point of closest
	// approach. Assumes the burn program will perform half of its burn before
	// T, half afterward
	add node(T-(dt/2), sr, sn, sp).
}
function eta_to_ta 
{
  parameter
    orbit_in, // orbit to predict for.
    ta_deg.   // true anomaly we're looking for, in degrees.

  local targetTime is time_pe_to_ta(orbit_in, ta_deg).
  local curTime is time_pe_to_ta(orbit_in, orbit_in:trueanomaly).

  local ta is targetTime - curTime.

  // If negative so we already passed it this orbit,
  // then get the one from the next orbit:
  if ta < 0 { set ta to ta + orbit_in:period.  }

  return ta.
}
function time_pe_to_ta 
{
  parameter
    orbit_in, // orbit to predict for
    ta_deg.   // in degrees

  local ecc is orbit_in:eccentricity.
  local sma is orbit_in:semimajoraxis.
  local e_anom_deg is arctan2( sqrt(1-ecc^2)*sin(ta_deg), ecc + cos(ta_deg) ).
  local e_anom_rad is e_anom_deg * pi/180.
  local m_anom_rad is e_anom_rad - ecc*sin(e_anom_deg).

  return m_anom_rad / sqrt( orbit_in:body:mu / sma^3 ).
}
function orbit_normal 
{
  parameter orbit_in.

  return VCRS( orbit_in:body:position - orbit_in:position,
               orbit_in:velocity:orbit ):NORMALIZED.
}
function find_ascending_node_ta 
{
  parameter orbit_1, orbit_2. // orbits to predict for

  local normal_1 is orbit_normal(orbit_1).
  local normal_2 is orbit_normal(orbit_2).

  // unit vector pointing from body's center toward the node:
  local vec_body_to_node is VCRS(normal_1,normal_2).

  // vector pointing from body's center to orbit 1's current position:
  local pos_1_body_rel is orbit_1:position - orbit_1:body:position.

  // how many true anomaly degrees ahead of my current true anomaly:
  local ta_ahead is VANG(vec_body_to_node, pos_1_body_rel).

  local sign_check_vec is VCRS(vec_body_to_node, pos_1_body_rel).

  if VDOT(normal_1,sign_check_vec) < 0 {
    set ta_ahead to 360 - ta_ahead.
  }

  // Add current true anomaly to get the absolute true anomaly:
  return mod( orbit_1:trueanomaly + ta_ahead, 360).
}
function inclination_match_burn 
{
  parameter
    vessel_1, // vessel of the object that will execute the burn
    orbit_2.  // orbit of the object that orbit 1 will match with

  local normal_1 is orbit_normal(vessel_1:obt).
  local normal_2 is orbit_normal(orbit_2).

  // true anomaly of the ascending node:
  local node_ta is find_ascending_node_ta(vessel_1:obt, orbit_2).

  // Pick whichever node, An or Dn, is higher altitude
  // (closer to Ap than Pe):
  if node_ta < 90 or node_ta > 270 {
    set node_ta to mod(node_ta + 180, 360).
  }

  // burn's eta, unit vector direction, and magnitude of burn:
  local burn_eta is eta_to_ta(vessel_1:obt, node_ta).
  local burn_ut is time:seconds + burn_eta.
  local burn_unit is (normal_1 + normal_2 ):NORMALIZED.
  local vel_at_eta is VELOCITYAT(vessel_1,burn_ut):ORBIT.
  local burn_mag is -2*vel_at_eta:MAG*COS(VANG(vel_at_eta,burn_unit)).

  return LIST(burn_ut, burn_mag*burn_unit).
}
function orbit_altitude_at_ta 
{
  parameter
    orbit_in,  // orbit to check for.
    true_anom. // in degrees.

  local sma is orbit_in:semimajoraxis.
  local ecc is orbit_in:eccentricity.
  local r is sma*(1-ecc^2)/(1+ecc*cos(true_anom)).

  return r - orbit_in:body:radius.
}
function ta_offset 
{
  parameter orbit_1, orbit_2.

  // obt 1 periapsis longitude (relative to solar system, not to kerbin).
  local pe_lng_1 is
    orbit_1:argumentofperiapsis +
    orbit_1:longitudeofascendingnode.

  // obt 2 periapsis longitude (relative to solar system, not to kerbin).
  local pe_lng_2 is
    orbit_2:argumentofperiapsis +
    orbit_2:longitudeofascendingnode.

  // how far ahead is obt1's true_anomaly measures from obt2's, in degrees?
  return pe_lng_1 - pe_lng_2.
}
function orbit_cross_ta 
{
  parameter
    orbit_1, // orbit to report TA for.
    orbit_2, // orbit to find intersect with.
    max_epsilon, // how coarse to do the search at first - too big and it might miss a hit.
    min_epsilon. // how tight to trim the search before accepting the answer.

  local pe_ta_off is ta_offset( orbit_1, orbit_2 ).

  local incr is max_epsilon.
  local prev_diff is 0.
  local start_ta is orbit_1:trueanomaly. // start search where the ship currently is.
  local ta is start_ta.

  until ta > start_ta+360 or abs(incr) < min_epsilon {
    local diff is orbit_altitude_at_ta(orbit_1, ta) -
                  orbit_altitude_at_ta(orbit_2, pe_ta_off + ta).

    // If pos/neg signs of diff and prev_diff differ and neither are zero:
    if diff * prev_diff < 0 {
      // Then this is a hit, so we reverse direction and go slower
      set incr to -incr/10.
    }
    set prev_diff to diff.

    set ta to ta + incr.
  }

  if ta > start_ta+360 {
    return -1.
  } else {
    return mod(ta,360).
  }
}
FUNCTION landTimeToLong 
{
    PARAMETER lng.

    LOCAL SDAY IS SHIP:BODY:ROTATIONPERIOD. // Duration of Body day in seconds
    LOCAL KAngS IS 360/SDAY. // Rotation angular speed.
    LOCAL P IS SHIP:ORBIT:PERIOD.
    LOCAL SAngS IS (360/P) - KAngS. // Ship angular speed acounted for Body rotation.
    LOCAL TgtLong IS utilLongitudeTo360(lng).
    LOCAL ShipLong is utilLongitudeTo360(SHIP:LONGITUDE). 
    LOCAL DLong IS TgtLong - ShipLong. 
    IF DLong < 0 {
        RETURN (DLong + 360) / SAngS. 
    }
    ELSE {
        RETURN DLong / SAngS.
    }
}
FUNCTION landDeorbitDeltaV 
{
    parameter alt.
    // From node_apo.ks
    local mu is body:mu.
    local br is body:radius.

    // present orbit properties
    local vom is ship:obt:velocity:orbit:mag.      // actual velocity
    local r is br + altitude.                      // actual distance to body
    local ra is r.                                 // radius at burn apsis
    //local v1 is sqrt( vom^2 + 2*mu*(1/ra - 1/r) ). // velocity at burn apsis
    local v1 is vom.
    // true story: if you name this "a" and call it from circ_alt, its value is 100,000 less than it should be!
    local sma1 is obt:semimajoraxis.

    // future orbit properties
    local r2 is br + periapsis.                    // distance after burn at periapsis
    local sma2 is (alt + 2*br + periapsis)/2. // semi major axis target orbit
    local v2 is sqrt( vom^2 + (mu * (2/r2 - 2/r + 1/sma1 - 1/sma2 ) ) ).

    // create node
    local deltav is v2 - v1.
    return deltav.
}
FUNCTION MSTOKMH
{
    PARAMETER MS.
    RETURN MS * 3.6.
}
FUNCTION TerrainNormal 
{
    // Thanks to Ozin
    // Returns a vector normal to the terrain
    parameter radius is 5. //Radius of the terrain sample
    local p1 to body:geopositionof(facing:vector*radius).
    local p2 to body:geopositionof(facing:vector * -radius + facing:starvector * radius).
    local p3 to body:geopositionof(facing:vector * -radius + facing:starvector * -radius).

    local p3p1 to p3:position - p1:position.
    local p2p1 to p2:position - p1:position.

    local normalvec to vcrs(p2p1,p3p1).
    return normalvec.
}
FUNCTION partsDisableReactionWheels 
{
	parameter tag is "".
	return partsDoAction("ModuleReactionWheel", "deactivate", tag).
}
FUNCTION partsEnableReactionWheels 
{
	parameter tag is "".
	return partsDoAction("ModuleReactionWheel", "activate", tag).
}
FUNCTION partsDoAction 
{
	parameter module.
	parameter action.
	parameter tag is "".
	
	local success is false.
	if Career():canDoActions {
		set action to "^"+action+"\b". // match first word
		local maxStage is -1.
		if tag = "" and (defined stagingMaxStage)
			set maxStage to stagingMaxStage-1. //see lib_staging
		for p in ship:partsTagged(tag) {
			if p:stage >= maxStage and p:modules:contains(module) {
				local m is p:getModule(module).
				for a in m:allActionNames() {
					if a:matchesPattern(action) {
						m:doAction(a,True).
						set success to true.
					}
				}
			}
		}
	}
	return success.
}
FUNCTION partsPercentEC 
{
	for R in ship:resources {
		if R:NAME = "ELECTRICCHARGE" {
			return R:AMOUNT / R:CAPACITY * 100.
		}
	}
	return 0.
}
FUNCTION partsPercentLFO 
{
	local LFCAP is 0.
	local LFAMT is 0.
	local OXCAP is 0.
	local OXAMT is 0.
	local SURPLUS is 0.
	for R in ship:resources {
		if R:NAME = "LIQUIDFUEL" {
			set LFCAP to R:CAPACITY.
			set LFAMT to R:AMOUNT.
		}
		else if R:NAME = "OXIDIZER" {
			set OXCAP to R:CAPACITY.
			set OXAMT to R:AMOUNT.
		}
	}
	if OXCAP = 0 OR LFCAP = 0 {
		return 0.
	}
	else {
		if OXCAP * (11/9) < LFCAP { // Surplus fuel
			return OXAMT/OXCAP*100.
		}
		else { // Surplus oxidizer or proportional amonts
			return LFAMT/LFCAP*100.
		}
	}
}
FUNCTION partsPercentMP 
{
	for R in ship:resources {
		if R:NAME = "MONOPROPELLANT" {
			return R:AMOUNT / R:CAPACITY * 100.
		}
	}
	return 0.
}
function ListScienceModules {
	declare local scienceModules to list().
	declare local partList to ship:parts.

	for thePart in partList { // loop through all of the parts
	    print thePart.
	    declare local moduleList to thePart:modules.
	    for theModule in moduleList { // loop through all of the modules of this part
	        // yust check for the Module Name. This might be extended in the future.
	        if (theModule = "ModuleScienceExperiment") or (theModule = "DMModuleScienceAnimate") {
	                scienceModules:add(thePart:getmodule(theModule)). // add it to the list					
	        }
	    }
	}
	return scienceModules.
}

// GetSpecifiedResource takes one parameter, a search term, and returns the resource with that search term
function GetSpecifiedResource {
	declare parameter searchTerm.

	declare local allResources to ship:resources.
	declare local theResult to "".

	for theResource in allResources {
		if theResource:name = searchTerm {
			set theResult to theResource.
			break.
		}
	}
	return theResult.
}

// Given some science data to transmit,
// - verify that sufficient electrical capacity exists to attempt to transmit
// - wait until sufficient charge before transmitting
function WaitForCharge {
	declare parameter scienceData.

	// This value are from http://wiki.kerbalspaceprogram.com/wiki/Antenna
	// for the Communotron 16 antenna.
	// It'd be better if I could search for the antenna and get these values,
	// but they don't appear to be there
	declare local electricalPerData to 6.

	declare local electricalResource to GetSpecifiedResource("ElectricCharge").
	declare local chargeMargin to 1.05. // Want to have not just enough, but a 5% margin
	declare local canTransmit to true.
	declare local neededCharge to scienceData:dataamount * electricalPerData * chargeMargin.

	if electricalResource:capacity > neededCharge {
		if (electricalResource:amount < neededCharge) {
			// current electrical capacity is insufficient, so wait and display messages
			until electricalResource:amount > neededCharge {
				print "Waiting for sufficient electrical charge" at (1,2).
				print "Need: " + round(neededCharge, 1) + "  Have: " + round(electricalResource:amount, 1) + "   " at (1,3).
				wait 1.
			}
		}
	} else {
		print "Insufficient electrical capacity to attempt transmission" at (1,2).
		set canTransmit to false.
	}
	return canTransmit.
}
// Function to run all re-runnable science experiments and transmit the results
function PerformScienceExperiments 
{
	declare local scienceModules to ListScienceModules().

	clearscreen.
	// start by looking for existing science from previous experiments; transmit if found
	for theModule in scienceModules {
		if theModule:hasdata {
			print "Existing data found in " + theModule:part:title at (1,1).
			if addons:rt:hasconnection(ship)
			{
				theModule:TRANSMIT().
			}
		}
	}

	// Now, loop through the operable, re-runnable experiments, running them
	for theModule in scienceModules {
		clearscreen.
		print "Working with: " + theModule:part:title at (1,1).
		wait 1.
		// Only perform operable, re-runnable experiments on modules that don't have data
		if (not theModule:inoperable) and (theModule:rerunnable) and (not theModule:hasdata) {
			print "Collecting data                                               " at (1,2).
			theModule:deploy(). // collect science, waiting for results to be ready
			wait 5.
		}
		wait 1.
	}
	clearscreen.
	print "All data collection and transmission complete".
}
function TransmitScienceExperiments 
{
	declare local scienceModules to ListScienceModules().
	for theModule in scienceModules 
	{
		clearscreen.
		if (theModule:hasdata)
		{
			for sd in theModule:data 
			{
				if addons:rt:hasconnection(ship) and (sd:transmitvalue > 0)
				{
					theModule:TRANSMIT().
					print "Working with: " + theModule:part:title at (1,1).
					wait 1.
					print "Transmitting data                                               " at (1,2).
					wait 5.
				}
				else if not addons:rt:hasconnection(ship) {clearscreen. Print "No Connection".}
				else if sd:transmitvalue = 0 {clearscreen. PRINT "No Trasmit value".}
			}
		}
	}
}

FUNCTION fversioncheck
{
	local libversion is fversion().
	LOCAL L TO LEXICON().
	if EXISTS("1:fversion.json")
	{
		clearscreen.
		print "Functions version checker".
		wait 1.
		LOCAL RL TO READJSON("fversion.json").
		clearscreen.
		if (RL["libversion"] = fversion())
		{
			print "Functions up to date".
			print "Functions version = " + RL["libversion"].
			wait 2.
		}
		else 
		{
			print "Functions file is updating".
			PRINT "Current version = " + RL["libversion"].
			PRINT "New version = " + fversion().
			wait 2.
			clearscreen.
			PRINT "Rebooting for updates to take effect......".
			deletepath("1:fversion.json").
			wait 2.
			reboot.
		}
	}
	else
	{
		L:ADD("libversion", libversion).
		WRITEJSON(L, "fversion.json").
	}
}

FUNCTION fversion
{
	clearscreen.
	LOCAL libversion to 0.044. 
	return libversion.
}
