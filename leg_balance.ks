function display_block 
{
	// Call to update the display of numbers
	parameter	startCol, startRow. // define where the block of text should be positioned

	set leg1diff to shipTerrHeight - leg1TerrHeight.
	set leg2diff to shipTerrHeight - leg2TerrHeight.
	set leg3diff to shipTerrHeight - leg3TerrHeight.
	
	print "ship Ter Height = " + round(shipTerrHeight, 3) + "      " at (startCol, StartRow + 0).
	print "leg1 Ter Height = " + round(leg1TerrHeight, 3) + "      " at (startCol, StartRow + 1).
	print "diff: " + round(leg1diff, 3) + "      " at (startCol + 25, StartRow + 1).
	print "leg2 Ter Height = " + round(leg2TerrHeight, 3) + "      " at (startCol, StartRow + 2).
	print "diff: " + round(leg2diff, 3) + "      " at (startCol + 25, StartRow + 2).
	print "leg3 Ter Height = " + round(leg3TerrHeight, 3) + "      " at (startCol, StartRow + 3).
	print "diff: " + round(leg3diff, 3) + "      " at (startCol + 25, StartRow + 3).
	
	set maxDiff to max(max(leg1diff, leg2diff), leg3diff).
	set minDiff to min(min(leg1diff, leg2diff), leg3diff).
	
	set midDiff to (maxDiff + minDiff) / 2.
	
	print "midDiff: " + round(midDiff, 3) + "     " at (startCol, startRow + 5).
	leg1Servo:moveto(leg1diff - midDiff, 4).
	leg2Servo:moveto(leg2diff - midDiff, 4).
	leg3Servo:moveto(leg3diff - midDiff, 4).
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

set Leg1Parts to ship:partstagged("Leg 1").
set Leg2Parts to ship:partstagged("Leg 2").
set Leg3Parts to ship:partstagged("Leg 3").

set gantriesList to list().
set legsList to list().
legsList:add(Leg1Parts[0]).
legsList:add(Leg2Parts[0]).
legsList:add(Leg3Parts[0]).

// Gantries
set servos to addons:ir:allservos.
for s in servos
{
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

}

// Each servo is the same, so calculate max and min just once

set servomin to leg1Servo:minposition.
set servomax to leg1Servo:maxposition.

lock shipPosition to ship:body:geopositionof(ship:position).
lock shipTerrHeight to shipPosition:terrainheight.
lock leg1TerrHeight to ship:body:geopositionof(footVector(legsList[0])):terrainheight.
lock leg2TerrHeight to ship:body:geopositionof(footVector(legsList[1])):terrainheight.
lock leg3TerrHeight to ship:body:geopositionof(footVector(legsList[2])):terrainheight.

set lastTime to time:seconds.
until false {
	display_block(0, 0).

}