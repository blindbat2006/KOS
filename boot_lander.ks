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
FUNCTION DELAY {
  SET dTime TO ADDONS:RT:DELAY(SHIP) * 3. // Total delay time
  SET accTime TO 0.                       // Accumulated time

  UNTIL accTime >= dTime {
    SET start TO TIME:SECONDS.
    WAIT UNTIL (TIME:SECONDS - start) > (dTime - accTime) OR NOT ADDONS:RT:HASCONNECTION(SHIP).
    SET accTime TO accTime + TIME:SECONDS - start.
  }
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
wait until ship:altitude > 1000.
RTantenna("on").
download("lib_auto.ks").
download("lib_nav2.ks").
download("tl.ks").
panels on.
run lib_auto.
LIST PARTS in partlist.
SET antList TO LIST().
LIST PARTS in partlist.
SET antList TO LIST().
for ant in partlist {
    IF (ant:TITLE = "Communotron DTS-M1"){
        antList:ADD(ant).
	}
}
set m0 to antList[0]:GETMODULE("ModuleRTAntenna").
m0:SETFIELD("target", "kerbin").
