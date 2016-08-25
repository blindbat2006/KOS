@LAZYGLOBAL OFF.
run lib_nav2.
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
	local land to "LANDED".
	local splash to "SPLASHED".
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
	clearscreen.
	global radarOffset to 5.	 				// The value of alt:radar when landed (on gear)
	lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
	lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
	lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
	lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
	lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
	lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
	WAIT UNTIL ship:verticalspeed < -1.
	print "Preparing for hoverslam...".
	rcs on.
	brakes on.
	lock steering to srfretrograde.
	when impactTime < 3 then {gear on.}

	WAIT UNTIL trueRadar < stopDist.
	print "Performing hoverslam".
	lock throttle to idealThrottle.

	WAIT UNTIL ship:verticalspeed > -0.01.
	print "Hoverslam completed".
	set ship:control:pilotmainthrottle to 0.
	rcs off.
	}
}
