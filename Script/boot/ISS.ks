if addons:rt:hasconnection(ship)
{
	clearscreen.
	copypath("0:/lib/functions","1:").
	run functions.
	fversioncheck().
	print "Checking for Missionfile".
	if EXISTS("0:" + ship:name +".updates.ks")
	{
		copypath("0:" + ship:name +".updates.ks","1:").
		copypath("0:" + ship:name +".updates.ks","0:backup/"+ship:name+"/"+ship:name+".updates.ks").
		wait 1.
		PRINT "File uploaded".
		deletepath("0:" + ship:name +".updates.ks").
		wait 1.
		PRINT "Removed file from Mainframe".
		wait 1.
		clearscreen.
		runpath(ship:name +".updates.ks").
		clearscreen.
		Print "Program Completed.".
		Print "Deleting file......".
		deletepath(ship:name +".updates.ks").
		SET SHIP:CONTROL:NEUTRALIZE to TRUE.
		reboot.
	}
	else
	{
		print "No Missionfile. Reboot when ready.".
	}
}	
SET SHIP:CONTROL:NEUTRALIZE to TRUE.
LIGHTS off.
RCS off.
SAS off.
lock steering to prograde.
wait until abs(steeringmanager:yawerror) < 2 and abs(steeringmanager:pitcherror) < 2 and abs(steeringmanager:rollerror) < 2.
PANELS off.
clearscreen.
print "ISS ready".
print "Start your dock procedure".
LIGHTS on.
set looping to false.
until looping
{
	lock steering to prograde.
	wait 1.
}