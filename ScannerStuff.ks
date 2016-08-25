LIST PARTS in partlist.
SET antList TO LIST().
for ant in partlist {
    IF (ant:TITLE = "Communotron DTS-M1"){
        antList:ADD(ant).
	}
}
set m0 to antList[0]:GETMODULE("ModuleRTAntenna").
m0:SETFIELD("target", "mun").
set m1 to antList[1]:GETMODULE("ModuleRTAntenna").
m1:SETFIELD("target", "kerbin").
set m2 to antList[2]:GETMODULE("ModuleRTAntenna").
m2:SETFIELD("target", "active-vessel").
set target to minmus.
local tgtorb to 250000.
set AG8 to false.
download("lib_transfer.ks").
run lib_transfer.
clearscreen.
print "init Completed".
wait 5.
clearscreen.
match_plane(target).
run_node().
wait 2.
sas off.
tts().
wait 1.
sas on.
wait 3.
hm_trans(target,(tgtorb),"prograde").
run_node().
sas off.
tts().
wait 1.
sas on.
wait 3.
print "Setup PR and node for polar".
set ag8 to false.
wait until ag8 = true.
wait 1.
set ag8 to false.
clearscreen.
run_node().
wait 3.
sas off.
tts().
wait 1.
sas on.
wait 3.
print "AG8 to warp".
set ag8 to false.
wait until ag8 = true.
wait 1.
set ag8 to false.
clearscreen.
print "Going for the warp".
warpto(time:seconds + ETA:TRANSITION - 5).
wait until body:name = "minmus".
print "Where are in " +body:name + " SOI".
wait 20.
sas off.
impact_check(tgtorb).
tts().
sas on.
set_altitude (ETA:PERIAPSIS,tgtorb).
run_node().
sas off.
tts().
wait 3.
sas on.
set_altitude (ETA:PERIAPSIS,tgtorb).
run_node().
sas off.
tts().
wait 3.
sas on.
mk_change_inc_node(90).
sas off.
tts().
wait 3.
sas on.
run_node().
wait 1.
sas off.
tts().
wait 3.
sas on.
