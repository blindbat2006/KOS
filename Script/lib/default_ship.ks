clearscreen.
SET TERMINAL:WIDTH to 56.
SET TERMINAL:HEIGHT to 22.
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
if addons:rt:hasconnection(ship)
{
	clearscreen.
	copypath("0:/lib/functions","1:").
	run functions.
	copypath("0:/lib/default_ship.ks","1:").
	set core:bootfilename to "default_ship.ks".
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
}else
{
	clearscreen.
	print "No connection. Waiting .....".
	wait until addons:rt:haskscconnection(ship).
	set core:bootfilename to "default_ship.ks".
	SET SHIP:CONTROL:NEUTRALIZE to TRUE.
	reboot.
}
