// rover.ks
// Written by KK4TEE
// License: GPLv3
//
// This program provides stability assistance
// for manually driven rovers

// GUI, Stability control and other improvements by FellipeC 2017

parameter turnfactor is 8. // Allow for passing the turnfactor for different rovers.
parameter maxspeed is 39. // Allow for passing the speedlimit. Default is 39 m/s, almost 88mph ;)

set speedlimit to maxspeed. //All speeds are in m/s 
lock turnlimit to min(1, turnfactor / GROUNDSPEED). //Scale the 
//turning radius based on current speed
set looptime to 0.01.
set loopEndTime to TIME:SECONDS.
set eWheelThrottle to 0. // Error between target speed and actual speed
set iWheelThrottle to 0. // Accumulated speed error
set wtVAL to 0. //Wheel Throttle Value
set kTurn to 0. //Wheel turn value.
set targetspeed to 0. //Cruise control starting speed
//set targetHeading to 90. //Used for autopilot steering
//set NORTHPOLE to latlng( 90, 0). //Reference heading
//set CruiseControl to False. //Enable/Disable Cruise control
//set StartJump to 0. //Used to track airtime
//set StartLand to 0. //Used to track time after recover from a jump
//set LongJump to False. //Use by jump recovery

DECLARE LOCAL speed_pid IS pidloop().
SET speed_pid:minoutput TO -1.0.
SET speed_pid:maxoutput TO 1.0.
SET speed_pid:setpoint TO 0.0.
LOCK wheelthrottle TO speed_pid:update(time:seconds,ship:groundspeed).
// Create a GUI window
LOCAL gui IS GUI(250).
SET gui:x TO 30.
SET gui:y TO 100.
LOCAL labelMode IS gui:ADDLABEL("").
SET labelMode:STYLE:ALIGN TO "CENTER".
SET labelMode:STYLE:HSTRETCH TO True. 
LOCAL apsettings to gui:ADDVLAYOUT().
//SPEED Settings
LOCAL labelSPDTitle IS apsettings:ADDLABEL("<b><size=15>Desidered Speed</size></b>").
SET labelSPDTitle:STYLE:ALIGN TO "CENTER".
SET labelSPDTitle:STYLE:HSTRETCH TO True. 
LOCAL SPDsettings to apsettings:ADDHBOX().
LOCAL ButtonSPDM TO SPDsettings:ADDBUTTON("▼").
SET ButtonSPDM:Style:WIDTH TO 40.
SET ButtonSPDM:Style:HEIGHT TO 25.
LOCAL LabelSPD TO SPDsettings:ADDLABEL("").
SET LabelSPD:Style:HEIGHT TO 25.
SET LabelSPD:STYLE:ALIGN TO "CENTER".
LOCAL ButtonSPDP TO SPDsettings:ADDBUTTON("▲").
SET ButtonSPDP:Style:WIDTH TO 40.
SET ButtonSPDP:Style:HEIGHT TO 25.
SET ButtonSPDM:ONCLICK  TO { 
    SET targetspeed TO ROUND(targetspeed) -1.
}.
SET ButtonSPDP:ONCLICK  TO { 
    SET targetspeed TO ROUND(targetspeed) +1.
}.
//Dashboard
LOCAL dashboard to gui:ADDHBOX().
LOCAL DashLeft to dashboard:ADDVLAYOUT().
LOCAL LabelDashSpeed to DashLeft:ADDLABEL("").
SET LabelDashSpeed:STYLE:ALIGN TO "LEFT".
SET LabelDashSpeed:STYLE:HSTRETCH TO True. 
SET LabelDashSpeed:STYLE:TEXTCOLOR TO Yellow.  
LOCAL LabelDashEC to DashLeft:ADDLABEL("").
SET LabelDashEC:STYLE:ALIGN TO "LEFT".
SET LabelDashEC:STYLE:HSTRETCH TO True. 
SET LabelDashEC:STYLE:TEXTCOLOR TO Yellow.  
LOCAL LabelDashLFO to DashLeft:ADDLABEL("").
SET LabelDashLFO:STYLE:ALIGN TO "LEFT".
SET LabelDashLFO:STYLE:HSTRETCH TO True. 
SET LabelDashLFO:STYLE:TEXTCOLOR TO Yellow.  
LOCAL SliderSteering to DashLeft:ADDHSLIDER(0,1,-1).
LOCAL LabelControls  to DashLeft:ADDLABEL("<color=#aaaaaa88>▲ Steering | Throttle ▶</color>").
SET LabelControls:STYLE:ALIGN TO "RIGHT".
SET LabelControls:STYLE:HSTRETCH TO True. 
LOCAL SliderThrottle to Dashboard:ADDVSLIDER(0,1,-1).
LOCAL ButtonStop TO gui:ADDBUTTON("Stop script").
SET ButtonStop:ONCLICK TO { set runmode to -1 . WAIT 0.}.
LOCAL ok TO gui:ADDBUTTON("Reboot kOS").
SET ok:ONCLICK TO {
    gui:HIDE().
    SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
    reboot.
}.
gui:SHOW().

// Main program
clearscreen.
sas off.
rcs off.
lights on.
lock throttle to 0.
set runmode to 0.
if ship:status = "ORBITING" 
{
    set runmode to -1.
}
partsDisableReactionWheels().
until runmode = -1 
{
    if runmode = 0 
	{ //Govern the rover 
    
        //Wheel Throttle:
        set targetspeed to targetspeed + 0.05 * SHIP:CONTROL:PILOTWHEELTHROTTLE.
        set targetspeed to max(-1, min( speedlimit, targetspeed)).
        
        if targetspeed > 0 
		{ //If we should be going forward
            if ship:groundspeed < 1 
			{
                brakes off.
            }
            set eWheelThrottle to targetspeed - GROUNDSPEED.
            set iWheelThrottle to min( 1, max( -1, iWheelThrottle + (looptime * eWheelThrottle))).
            set wtVAL to eWheelThrottle + iWheelThrottle.//PI controler
            if GROUNDSPEED < 5 
			{
                //Safety adjustment to help reduce roll-back at low speeds
                set wtVAL to min( 1, max( -0.2, wtVAL)).
                }
		}
        else if targetspeed < 0 
		{ //Else if we're going backwards
            set wtVAL to SHIP:CONTROL:PILOTWHEELTHROTTLE.
            set targetspeed to 0. //Manual reverse throttle
            set iWheelThrottle to 0.
		}
        else 
		{ // If value is out of range or zero, stop.
            set wtVAL to 0.
            brakes on.
		}
        if brakes 
		{ //Disable cruise control if the brakes are turned on.
            set targetspeed to 0.
		}        
        set kturn to turnlimit * SHIP:CONTROL:PILOTWHEELSTEER.
        //Detect rollover
        if abs(vang(vxcl(ship:facing:vector,ship:facing:upvector),TerrainNormal())) > 5 
		{
            set turnfactor to max(1,turnfactor * 0.9). //Reduce turnfactor
            //set runmode to 2. //Engage Stability control
        }
    }    
    //Here it really control the rover.
    set wtVAL to min(1,(max(-1,wtVAL))).
    set kTurn to min(1,(max(-1,kTurn))).
    set SHIP:CONTROL:WHEELTHROTTLE to WTVAL.
    set SHIP:CONTROL:WHEELSTEER to kTurn.
    
    // Update the GUI
    if runmode = 0 
	{
        SET LabelSPD:TEXT to "<b>" + round( targetspeed, 1) + " m/s | "+ round (MSTOKMH(targetspeed),1) + " km/h</b>".
    }
    else if runmode = 1 
	{
        SET LabelSPD:TEXT to "<b>- m/s | - km/h</b>".
    }
    SET LabelDashSpeed:TEXT to "<b>Speed: </b>" + round( ship:groundspeed, 1) + " m/s | "+ round (MSTOKMH(ship:groundspeed),1) + " km/h".
    SET LabelDashEC:TEXT to "<b>Charge: </b>" + ROUND(partsPercentEC()) + "%".
    SET LabelDashLFO:TEXT to "<b>Fuel: </b>" + ROUND(partsPercentLFO()) + "%".
    SET SliderSteering:VALUE to kTurn.
    SET SliderThrottle:VALUE to wtVAL. 
	SET speed_pid:setpoint TO WTVAL.
    set looptime to TIME:SECONDS - loopEndTime.
    set loopEndTime to TIME:SECONDS.
    wait 0.01. // Waits for next physics tick.
}


//Clear before end
CLEARGUIS().
UNLOCK Throttle.
UNLOCK Steering.
SET ship:control:translation to v(0,0,0).
SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.