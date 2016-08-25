set kerb_orb to 100000.
set ignore_autofairing to true.
run launch(kerb_orb,90).
set_altitude(ETA:APOAPSIS,kerb_orb).
run_node().


FUNCTION drogchute {
	FOR drogchutes IN drog {
			drogchutes:GETMODULE("RealChuteFAR"):SETFIELD("ALTITUDE", 4000).
			drogchutes:GETMODULE("RealChuteFAR"):SETFIELD("Min pressure", 0.3).
	}
}
FUNCTION drogchutedeploy {
	FOR drogchutes IN drog {
		if drogchutes:GETMODULE("RealChuteFAR"):HASEVENT("Deploy Chute") {
			drogchutes:GETMODULE("RealChuteFAR"):DOACTION("Deploy Chute",TRUE).
			clearscreen.
			print "All drogs armed".
		}
	}
}
FUNCTION chutesetup {
	SET para TO LIST().
	SET drog TO LIST().
	set nopara to list().
	LIST parts in partList.
	for parts in partList {
		for module in parts:modules {
			if module = "RealChuteFAR" {
				if parts:getmodule(module):GETFIELD("ALTITUDE") {
					parts:getmodule(module):SETFIELD("ALTITUDE", 600).
					parts:GETMODULE(module):SETFIELD("Min pressure", 0.4).
					parts:GETMODULE("RealChuteFAR"):DOACTION("Disarm chute",TRUE).
					para:add(parts).
				}
			}
			else{
				nopara:add(parts).
			}
		}
		if parts:name = "parachuteDrogue" {
				drog:add(parts).
		}.
		if parts:name = "radialDrogue" {
			drog:add(parts).
		}.
	}
	clearscreen.
	print "All chutes".
	print para.
	drogchute().
	print "All drogs setup".
	print drog.
}
FUNCTION chutedeploy {
	FOR chute IN para {
		if chute:GETMODULE("RealChuteFAR"):HASEVENT("Deploy Chute") {
			chute:GETMODULE("RealChuteFAR"):DOACTION("Deploy Chute",TRUE).
			clearscreen.
			print "All chutes armed".
		}
	}
}
set AG8 to false.
chutesetup().
drogchute().
wait 3.
set kerb_orb to 100000.
run launch(kerb_orb,0).
set_altitude(ETA:APOAPSIS,kerb_orb).
wait 1.
sas off.
tts().
wait 1.
sas on.
wait 5.
clearscreen.
drogchutedeploy().
wait 1.
chutedeploy().
wait 1.
stage.
wait 3.
checkStages().
wait 1.
clearscreen.
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
m1:SETFIELD("target", "minmus").
set m2 to antList[2]:GETMODULE("ModuleRTAntenna").
m2:SETFIELD("target", "active-vessel").
clearscreen.
print "AG8 to Circ".
set ag8 to false.
wait until ag8 = true.
wait 1.
set ag8 to false.
run_node().
