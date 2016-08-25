SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
clearscreen.
wait 5.
gear off.
panels off.
brakes off.
sas off.
rcs off.
lights on.
set runpro to ship:name.
copy lib_auto from 0.
copy lib_nav2 from 0.
copy launch from 0.
run once lib_nav2.
run once lib_auto.
print "Init startup".
print "checking systems".
print "BSOD".
print "Version 1.6".
wait 5.
if has_file(""+runpro+".ks",0){
	copy "" + runpro from 0.
	clearscreen.
	print "We have the file".
	wait 2.
}
else{
	copy default_ship from 0.
	rename default_ship to ""+ runpro + ".ks".
	clearscreen.
	print "Making it up now".
	wait 2.
}
log "run "+runpro+"." to tmp.ks.
set finished to false.
until finished = true{
	if ship:status = "PRELAUNCH" {
		local kerb_orb to 100000.
		//core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
		download(""+runpro+"to.ks").
		if has_file(""+runpro+"to.ks",1) {
			rename runpro+"to.ks" to tmpto.ks.
			delete runpro+"to.ks" from 0.
			clearscreen.
			print "Modified Launch".
			wait 5.
			run tmpto.
			delete tmpto.
			set finished to true.
		}
		else {
			clearscreen.
			print "Standard Launch - East - 100K ".
			wait 5.
			run launch(kerb_orb,90).
			clearscreen.
			wait 3.
			set_altitude(ETA:APOAPSIS,kerb_orb).
			run_node().
			set finished to true.
		}
	}
	else{
		set finished to true.
		clearscreen.
		print "Not waiting for launch".
		wait 5.
	}
}
run tmp. //run our ships name program
