FUNCTION drogchute {
	FOR drogchutes IN drog {
			drogchutes:GETMODULE("RealChuteFAR"):SETFIELD("ALTITUDE", 4000).
			drogchutes:GETMODULE("RealChuteFAR"):SETFIELD("Min pressure", 0.3).
	}
}
FUNCTION drogchutedeploy {
	if not ignore_realchute{
		FOR drogchutes IN drog {
			if drogchutes:GETMODULE("RealChuteFAR"):HASEVENT("Deploy Chute") {
				drogchutes:GETMODULE("RealChuteFAR"):DOACTION("Deploy Chute",TRUE).
				clearscreen.
				print "All drogs armed".
			}
		}
	}
	else {
		for RealChute in ship:modulesNamed("RealChuteModule") {
			RealChute:doevent("arm parachute").
			clearscreen.
			print "All Chutes armed".
		}
	}
}
FUNCTION chutesetup {
	if not (defined ignore_realchute) {
		global ignore_realchute to false.
	}
	if not ignore_realchute{
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
	else{
		for RealChute in ship:modulesNamed("RealChuteModule") {
			if RealChute:HASEVENT("disarm parachute"){
					RealChute:doevent("disarm parachute").
			}
	 	}
	print "RealChute enabled".
	}
}
FUNCTION chutedeploy {
	if not ignore_realchute{
		FOR chute IN para {
			if chute:GETMODULE("RealChuteFAR"):HASEVENT("Deploy Chute") {
				chute:GETMODULE("RealChuteFAR"):DOACTION("Deploy Chute",TRUE).
				clearscreen.
				print "All chutes armed".
			}
		}
	}
	else{
		for RealChute in ship:modulesNamed("RealChuteModule") {
			RealChute:doevent("Deploy chute").
			clearscreen.
			print "All Chutes deploying".
		}
	}
}
set realchutelist to list().
for RealChute in ship:modulesNamed("RealChuteModule") {
	realchutelist:add(RealChute:part:name).
}
if realchutelist:length > 0 {
	set ignore_realchute to true.
}
clearscreen.
chutesetup().
clearscreen.
drogchutedeploy().
clearscreen.
chutedeploy().
