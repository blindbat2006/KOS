@LAZYGLOBAL OFF.
run lib_nav2.
// get burn time Free Fall Edition
// Rocket Equation against gravitation solved for t requires the Lambert W function.
// so we use a iterative solution.
function get_burn_t_ff {
	parameter r_start,r_ground.
	local dv is sqrt((2*BODY:MU*(r_start - r_ground))/(r_start * r_ground)).
	local m0 IS SHIP:MASS.
	local g_ground to BODY:MU/r_ground^2.
	local g_start to BODY:MU/r_start^2.
	local e to constant:e.
	local exp to 2.69.
	local g_mean to ((g_start^exp+g_ground^exp)/2)^(1/exp).
	local t_burn is 0.
	local dv_old is 0.
	local dv_new is 0.
	local dv_change is dv.
	local dv_total is 0.

	local eng_stats to get_engine_stats().
	local ch_rate is eng_stats[2].
	local v_e is eng_stats[3].

	until dv_change < 0.001 {

		set dv_total to dv_total + dv_change.
		set t_burn to SHIP:MASS*(1 - e^(-dv_total/v_e))/ch_rate.
		set dv_new to g_mean * t_burn.
		set dv_change to abs(dv_new - dv_old).
		set dv_old to dv_new.

	}
	print "burn_time FF: " + round (t_burn,2).
	return t_burn+0.06.
}

//
// Returns the altitude above sea level, when the burn has to start.
// returns a few meter extra to soften the landing.
function get_burn_height {
	parameter r_from,r_to.

	local grav_i is BODY:MU/r_to^2.
	local grav_o to BODY:MU/r_from^2.
	local exp to 2.69.
	local grav_mean to ((grav_i^exp + (grav_o^exp))/2)^(1/exp).

	local eng_stats to get_engine_stats().
	local ch_rate to  eng_stats[2].
	local v_e to  eng_stats[3].
	local M to SHIP:MASS.

	local r_burn_old is r_to.
	local r_burn_new is r_to.
	local r_burn_delta is 99.
	local r_burn to r_burn_new.

	local lock grav_b to BODY:MU/(r_burn^2).
	local lock grav_mean_b to (((grav_i^exp) + (grav_b^exp))/2)^(1/exp).

	local lock v_burn to sqrt((2*BODY:MU*(r_from - r_burn))/(r_from * r_burn)).
	local t to get_burn_t_ff(r_from,r_burn).

// These are all equivalent
//	local lock stopping_dist to v_burn*t + (grav_mean_b*t^2)/2 - (t*v_e - t*v_e * (ln(M/(M-t*ch_rate))/(M/(M-t*ch_rate)-1))).
//	local lock stopping_dist to v_burn*t + (0.5* grav_mean_b * (t^2)) - ((v_e * M/ch_rate) * ((1 - ch_rate * t/M) * ln(1 - ch_rate*t/M) + (ch_rate*t/M))).
	local lock stopping_dist to v_burn*t + (grav_mean_b*t^2)/2 - (v_e*(t - M/ch_rate) *ln(M/(M-t*ch_rate)) + v_e*t) .

	until abs ( r_burn_delta ) < 0.1 {

		set t to get_burn_t_ff(r_from,r_burn).
		set r_burn_new to r_to + stopping_dist.
		set r_burn_delta to r_burn_new-r_burn_old .
		set r_burn to (r_burn_old + (r_burn_delta*0.8)).
		set r_burn_old to r_burn.
	}

	print "Burning Altitude:       " + round((r_burn-BODY:RADIUS),1).
	print "Free Fall velocity:     " + round(v_burn,1).
	// add safety here; reduce 15 to 5 to stop at the surface (the trigger will not fire).
	return (15+r_burn -BODY:RADIUS).
}



// You want to call this function
function land_at_position{
	parameter lat,lng.
	local coordinates to latlng(lat,lng).
	stop_at(coordinates).
	do_suecide_burn().
	local d_target to round((SHIP:GEOPOSITION:POSITION - coordinates:POSITION):MAG,1).
	print "We landed "+d_target +" m from our target".
}



function stop_at{
	parameter spot.

	local node_lng to mod(360+Body:ROTATIONANGLE+spot:LNG,360).

	set_inc_lan_i(spot:LAT,node_lng-90,false).
	local my_node to NEXTNODE.
	// change node_eta to adjust for rotation:
	local t_wait_burn to my_node:ETA + OBT:PERIOD/4.

	local rot_angle to t_wait_burn*360/Body:ROTATIONPERIOD.
	remove my_node.
	set_inc_lan_i(spot:LAT,node_lng-90+rot_angle,false).
	wait 1.
	run_node().

	local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).
	local ship_2_node to mod((720 + node_lng+rot_angle - ship_ref),360).
	local node_eta to ship_2_node*OBT:PERIOD/360.
	local my_node to NODE(time:seconds + node_eta,0,0,-SHIP:VELOCITY:SURFACE:MAG).
	ADD my_node.

	run_stopping_node(spot).
}


function run_stopping_node{
	parameter target_spot.
	SAS off.
	local nd to NEXTNODE.
	//print out node's basic parameters - ETA and deltaV
	print "Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).

	//now we just need to divide deltav:mag by our ship's max acceleration
	local burn_duration to get_burn_t(nd:deltav:mag).

	warpto (time:seconds + nd:eta - (burn_duration + 60)).

	local lock down_vector to vdot (UP:VECTOR,SHIP:VELOCITY:SURFACE)*UP:VECTOR.
	local lock burn_vector  to (-1* (SHIP:VELOCITY:SURFACE - down_vector)).

	local lock np to lookdirup(burn_vector, ship:facing:topvector).
	lock steering to np.
	print "waiting for the ship to turn".
	//now we need to wait until the burn vector and ship's facing are aligned
	wait until abs(np:pitch - facing:pitch) < 0.3 and abs(np:yaw - facing:yaw) < 0.3.

	//the ship is facing the right direction, let's wait for our burn time
	warpto (time:seconds + nd:eta - (burn_duration)).

	local eng_stats to get_engine_stats().
	local ch_rate to  eng_stats[2].
	local v_e to  eng_stats[3].
	local M to SHIP:MASS.
	local v_burn to SHIP:VELOCITY:SURFACE:MAG.

	local t to get_burn_t(v_burn).
	local stop_distance to v_burn*t - (v_e*(t - M/ch_rate) *ln(M/(M-t*ch_rate)) + v_e*t) .

	// wait until its time to start
	wait until (SHIP:POSITION - target_spot:ALTITUDEPOSITION(SHIP:ALTITUDE)):MAG <= (stop_distance + 40).

	local tset to 1.
	lock throttle to tset.

	local done to false.
	local max_acc is 0.

	until done
	{
		//recalculate current max_acceleration, as it changes while we burn through fuel
		set max_acc to ship:maxthrust/ship:mass.
		checkStages().
		//throttle is 100% until there is less than 1 second of time left to burn
		//when there is less than 1 second - decrease the throttle linearly
		set tset to min(SHIP:GROUNDSPEED/max_acc, 1).
		//we have very little left to burn
		if (SHIP:GROUNDSPEED) < 1 {

			unlock steering.
			wait 1.
			lock throttle to 0.
			print "End burn, remain speed  " + round(burn_vector:MAG,1) + "m/s".
			set done to True.
		}
	}
	//we no longer need the maneuver node
	lOCK STEERING to SHIP:RETROGRADE.
	RCS off.
	wait 3.
	remove nd.
	print "Vessel Stopped".


	//set throttle to 0 just in case.
	set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
	unlock throttle.
}

function do_suecide_burn{
	function display_block {
		// Call to update the display of numbers
		parameter	startCol, startRow. // define where the block of text should be positioned

		local leg1diff to shipTerrHeight - leg1TerrHeight.
		local leg2diff to shipTerrHeight - leg2TerrHeight.
		local leg3diff to shipTerrHeight - leg3TerrHeight.
		local leg4diff to shipTerrHeight - leg4TerrHeight.

		print "ship Ter Height = " + round(shipTerrHeight, 3) + "      " at (startCol, StartRow + 0).
		print "leg1 Ter Height = " + round(leg1TerrHeight, 3) + "      " at (startCol, StartRow + 1).
		print "diff: " + round(leg1diff, 3) + "      " at (startCol + 25, StartRow + 1).
		print "leg2 Ter Height = " + round(leg2TerrHeight, 3) + "      " at (startCol, StartRow + 2).
		print "diff: " + round(leg2diff, 3) + "      " at (startCol + 25, StartRow + 2).
		print "leg3 Ter Height = " + round(leg3TerrHeight, 3) + "      " at (startCol, StartRow + 3).
		print "diff: " + round(leg3diff, 3) + "      " at (startCol + 25, StartRow + 3).
		print "leg4 Ter Height = " + round(leg4TerrHeight, 3) + "      " at (startCol, StartRow + 4).
		print "diff: " + round(leg4diff, 3) + "      " at (startCol + 25, StartRow + 4).

		local maxDiff to max(max(leg1diff, leg2diff), leg3diff).
		local minDiff to min(min(leg1diff, leg2diff), leg3diff).

		local midDiff to (maxDiff + minDiff) / 2.

		print "midDiff: " + round(midDiff, 3) + "     " at (startCol, startRow + 5).
		leg1Servo:moveto(leg1diff - midDiff, 4).
		leg2Servo:moveto(leg2diff - midDiff, 4).
		leg3Servo:moveto(leg3diff - midDiff, 4).
		leg4Servo:moveto(leg4diff - midDiff, 4).
	}
	function footVector {
		declare parameter leg.

		// These constants are for a vector, in terms of the landing leg's facing vector, from leg:position to the foot.
		// They are specific to the LT-2 Landing Strut
		local foreMult is -2.4.
		local topMult is -1.5.
		local starMult is 0.

		local returnVector is leg:position +
			(leg:facing:forevector * foreMult) +
			(leg:facing:topvector * topMult) +
			(leg:facing:starvector * starMult).

		return returnVector.
	}
	clearscreen.
	global radarOffset to 30.	 				// The value of alt:radar when landed (on gear)
	lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
	lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
	lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
	lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
	lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
	lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
	WAIT UNTIL ship:verticalspeed < -1.
	print "Preparing for hoverslam... V6".
	sas off.
	rcs on.
	brakes on.
	lock steering to srfretrograde.
	when impactTime < 5 then {
		gear on.
	}

	WAIT UNTIL trueRadar < stopDist.
	print "Performing hoverslam".
	lock throttle to idealThrottle.
	//WAIT UNTIL ship:verticalspeed > -0.5.
	wait until alt:radar < alt:radar + radarOffset.
	unlock throttle.
	print "Hoverslam completed".
	rcs off.
	clearscreen.
	local land to "LANDED".
	local splash to "SPLASHED".
	local touch_speed to 2.
	local descend_pid to PID_init(0.1, 0.01, 0.05, 0, 1).
	PID_seek(descend_pid, -touch_speed, ship:verticalspeed). // prime the PID values once
	wait 0.001.
	until status = land or status = splash{
		if ship:partstagged("Leg 1"):length > 0 {
			local Leg1Parts to ship:partstagged("Leg 1").
			local Leg2Parts to ship:partstagged("Leg 2").
			local Leg3Parts to ship:partstagged("Leg 3").
			local Leg4Parts to ship:partstagged("Leg 4").

			local gantriesList to list().
			local legsList to list().
			legsList:add(Leg1Parts[0]).
			legsList:add(Leg2Parts[0]).
			legsList:add(Leg3Parts[0]).
			legsList:add(Leg4Parts[0]).

			// Gantries
			local servos to addons:ir:allservos.
			global leg1Servo to 0.
			global leg2Servo to 0.
			global leg3Servo to 0.
			global leg4Servo to 0.
			for s in servos {
				if (s:name = "Leg 1 Height")
				{
					set leg1Servo to s.
				}
				if (s:name = "Leg 2 Height")
				{
					set leg2Servo to s.
				}
				if (s:name = "Leg 3 Height")
				{
					set leg3Servo to s.
				}
				if (s:name = "Leg 4 Height")
				{
					set leg4Servo to s.
				}
			}
			local servomin to leg1Servo:minposition.
			local servomax to leg1Servo:maxposition.

			lock shipPosition to ship:body:geopositionof(ship:position).
			lock shipTerrHeight to shipPosition:terrainheight.
			lock leg1TerrHeight to ship:body:geopositionof(footVector(legsList[0])):terrainheight.
			lock leg2TerrHeight to ship:body:geopositionof(footVector(legsList[1])):terrainheight.
			lock leg3TerrHeight to ship:body:geopositionof(footVector(legsList[2])):terrainheight.
			lock leg4TerrHeight to ship:body:geopositionof(footVector(legsList[3])):terrainheight.

			local lastTime to time:seconds.

			display_block(0, 10).
	}
	//PID_seek(descend_pid, -touch_speed, ship:verticalspeed).
	lock throttle to PID_seek(descend_pid, -touch_speed, ship:verticalspeed).
	if ship:groundspeed > 1{
		lock steering to srfretrograde.
	}
	if ship:groundspeed < 1{
		lock steering to up.
	}
	print "Vertical speed = " at (0,0).
	print "Ground speed = " at (0,1).
	print "Throttle = " at (0,3).
	print round(ship:verticalspeed,2) at (17,0).
	print round(ship:groundspeed,2) at (17,1).
	print round(throttle,2)*100 at (17,3).
	wait 1.
	clearscreen.
	}
	set ship:control:pilotmainthrottle to 0.
	lock steering to up.
	wait 5.
	sas on.
	unlock steering.
}
