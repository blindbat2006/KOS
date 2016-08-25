function autoversion {
	print "lib_auto version 1.6".
}
function HAS_FILE {
  PARAMETER name.
  PARAMETER vol.

  SWITCH TO vol.
  LIST FILES IN allFiles.
  FOR file IN allFiles {
    IF file:NAME = name {
      SWITCH TO 1.
      RETURN TRUE.
    }
  }

  SWITCH TO 1.
  RETURN FALSE.
}
function DOWNLOAD {
  PARAMETER name.

  DELAY().
  IF HAS_FILE(name, 1) {
    DELETE name.
  }
  IF HAS_FILE(name, 0) {
    COPY name FROM 0.
  }
}
FUNCTION DELAY {
  SET dTime TO ADDONS:RT:DELAY(SHIP) * 3. // Total delay time
  SET accTime TO 0.                       // Accumulated time

  UNTIL accTime >= dTime {
    SET start TO TIME:SECONDS.
    WAIT UNTIL (TIME:SECONDS - start) > (dTime - accTime) OR NOT ADDONS:RT:HASCONNECTION(SHIP).
    SET accTime TO accTime + TIME:SECONDS - start.
  }
}
function checkStages {
	if not (defined ignore_checkstages) {
		global ignore_checkstages to false.
	}
	if not ignore_checkstages{
		local myEngines is list().
  	list engines in myEngines.
  	for shipEngine in myEngines {
    	if ( shipEngine:flameout ) {
      	local currentStage to shipEngine:stage.
      	local parentPart to shipEngine.
      	local foundDecoupler to false.
      	until not(parentPart:hasparent) {
        	if (
          	parentPart:modules:contains("ModuleAnchoredDecoupler") and
          	parentPart:stage = shipEngine:stage - 1
        	) {
          	//print "found for " + shipEngine + " dec " + parentPart.
          	set foundDecoupler to true.
          	break.
        	}
        	set parentPart to parentPart:parent.
      	}
      	if ( foundDecoupler ) {
        	//print "stage flameout engines!".
        	stage.
					wait 3.
        	return 1.
      	}
    	}
    	//print e:stage + " " + e:parent:parent:stage.
  	}

  	IF (SHIP:LIQUIDFUEL > 0) AND (STAGE:LIQUIDFUEL < 0.01) AND (STAGE:SOLIDFUEL < 0.01) {
    	STAGE.
			wait 3.
    	return 1.
  	}
  	return 0.
	}
}
function RTantenna {
	declare parameter power.
	SET antennaList TO LIST().
	FOR RTmodule IN SHIP:MODULESNAMED("ModuleRTAntenna") {
		IF RTmodule:PART:MODULES:CONTAINS("ModuleAnimateGeneric") {
			antennaList:ADD(RTmodule:PART).
		}
	}
	if power = "on" {
		FOR antenna IN antennaList {
			antenna:GETMODULE("ModuleRTAntenna"):DOACTION("Activate", TRUE).
			HUDTEXT("Deploying Antenna", 3, 2, 30, YELLOW, FALSE).
		}
	}
	if power = "off" {
		FOR antenna IN antennaList {
			antenna:GETMODULE("ModuleRTAntenna"):DOACTION("Deactivate", TRUE).
			HUDTEXT("Retracting Antenna", 3, 2, 30, YELLOW, FALSE).
		}
	}
}
function tts {
	clearscreen.
	set result to 0.
	set done to 0.
	set sp to sun:position.
	lock steering to sp.
	wait 5.
	SET NoSolList TO LIST().
	SET SolList TO LIST().
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
	set bx to SolList[0]:GETMODULE("ModuleDeployableSolarPanel"):GETFIELD("status").
	until done = 1{
		if bx = "Direct Sunlight" {
			until result > 0.90 {
				clearscreen.
				set result to SolList[0]:GETMODULE("ModuleDeployableSolarPanel"):GETFIELD("sun exposure").
				print "Sun Exposure: " + round (result * 100, 2) + "%".
				wait 2.
				when result < 0.2 then {
					print "Sun has gone".
					set done to 3.
					set result to 1.
				}
			set done to 2.
			}
		}
		if done = 2{
			wait 10.
			print "Pointing at Sun".
			set done to 1.
		}
		if done = 3{
			wait 10.
			print "Pointing at Sun but just not enough juice Captain".
			set done to 1.
		}
		else {
			print "We are being blocked or".
			print "the solar panels are retracted".
			set done to 1.
			}
	}
	print "Unlocking steering".
	unlock steering.
}
function run_node{
	// execute maneuver node
	clearscreen.
	set nd to nextnode.
	print "T+" + round(missiontime) + " Node apoapsis: " + round(nd:orbit:apoapsis/1000,2) + "km, periapsis: " + round(nd:orbit:periapsis/1000,2) + "km".
	print "T+" + round(missiontime) + " Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).
	set maxa to maxthrust/mass.
	set dob to nd:deltav:mag/maxa.     // incorrect: should use tsiolkovsky formula
	print "T+" + round(missiontime) + " Max acc: " + round(maxa) + "m/s^2, Burn duration: " + round(dob) + "s".
	warpto(time:seconds + nd:eta - dob/2 - 30).
		// turn does not work during warp - so do now
	print "T+" + round(missiontime) + " Turning ship to burn direction.".
	sas off.
	rcs off.
	// workaround for steering:pitch not working with node assigned
	//set np to R(0,0,0) * nd:deltav. // old bit
	set np to lookdirup(nd:deltav, ship:facing:topvector). //points to node, keeping roll the same.
	lock steering to np.
	wait until abs(np:pitch - facing:pitch) < 0.1 and abs(np:yaw - facing:yaw) < 0.1.
	wait until time:seconds >= time:seconds + nd:eta - dob/2.
	sas off.
	print "T+" + round(missiontime) + " Orbital burn start " + round(nd:eta) + "s before apoapsis.".
	set tset to 0.
	lock throttle to tset.
	// keep ship oriented to burn direction even with small dv where node:prograde wanders off
	set np to R(0,0,0) * nd:deltav.
	lock steering to np.
	set done to False.
	set once to True.
	set dv0 to nd:deltav.
	until done {
		set maxa to maxthrust/mass.
		set tset to min(nd:deltav:mag/maxa, 1).
		checkStages().
		if once and tset < 1 {
			print "T+" + round(missiontime) + " Throttling down, remain dv " + round(nd:deltav:mag) + "m/s, fuel:" + round(stage:liquidfuel).
			set once to False.
		}
		if vdot(dv0, nd:deltav) < 0 {
			print "T+" + round(missiontime) + " End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
			lock throttle to 0.
			break.
		}
		if nd:deltav:mag < 0.1 {
			print "T+" + round(missiontime) + " Finalizing, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
			wait until vdot(dv0, nd:deltav) < 0.5.
			lock throttle to 0.
			print "T+" + round(missiontime) + " End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
			set done to True.
		}
	}
	unlock steering.
	print "T+" + round(missiontime) + " Apoapsis: " + round(apoapsis/1000,2) + "km, periapsis: " + round(periapsis/1000,2) + "km".
	print "T+" + round(missiontime) + " Fuel after burn: " + round(stage:liquidfuel).
	wait 1.
	remove nd.
	set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
	unlock throttle.
	unlock steering.
	wait 5.
}
