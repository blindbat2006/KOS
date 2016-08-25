@LAZYGLOBAL OFF.
function nav2version {
	print "lib_nav2 version 1.6".
}
function steering_dir {
   declare local parameter dir.
    return LOOKDIRUP(dir:VECTOR, FACING:TOPVECTOR).
}
function set_inc_lan{
	declare local parameter incl_t.
	declare local parameter lan_t.
	set_inc_lan_i(incl_t,lan_t,true).
}
function set_inc_lan_i {
	declare local parameter incl_t.
	declare local parameter lan_t.
	declare local parameter fast.
	print " ".
	local incl_i to SHIP:OBT:INCLINATION.
	local lan_i to SHIP:OBT:LAN.
	local Va to V(sin(incl_i)*cos(lan_i+90),sin(incl_i)*sin(lan_i+90),cos(incl_i)).
	local Vb to V(sin(incl_t)*cos(lan_t+90),sin(incl_t)*sin(lan_t+90),cos(incl_t)).
	local Vc to VCRS(Vb,Va).
	local d_inc to arccos (vdot(Va,Vb) ).
	local dvtgt to (2 * (SHIP:OBT:VELOCITY:ORBIT:MAG) * SIN(d_inc/2)).
	local node_lng to mod(arctan2(Vc:Y,Vc:X)+360,360).
	local ship_rad to mod(OBT:LAN+OBT:argumentofperiapsis+OBT:trueanomaly,360).
	local node_eta to SHIP:OBT:PERIOD * ((mod(node_lng - ship_rad + 360,360))) / 360.
	if node_eta > ((SHIP:OBT:PERIOD) / 2) AND fast {
		print "Switching to DN".
		set node_eta to ((SHIP:OBT:PERIOD / 2) + (node_eta-SHIP:OBT:PERIOD)).
		set dvtgt to 0-dvtgt.
	}
	print "inc_Burn dV: " + round(dvtgt,2).
	print "inc_Burn ETA: " + round(node_eta,2).
	local inc_node to NODE(time:seconds+node_eta, 0, 0, 0).
	set inc_node:NORMAL to dvtgt * cos(d_inc/2).
	set inc_node:PROGRADE to 0 - abs(dvtgt * sin(d_inc/2)).
	ADD inc_node.
}
function mk_change_inc_node {
	declare local parameter target_inc.
		set_inc_lan (target_inc,SHIP:OBT:LAN).
}
function match_plane {
	declare local parameter target_vs.
	if target_vs:BODY:NAME = SHIP:BODY:NAME {
		set_inc_lan (target_vs:OBT:INCLINATION,target_vs:OBT:LAN).
	} else {

		print "Target has different Body, this function needs more work".
	}
}
function set_altitude {
	declare local parameter node_eta,target_alt.
	local v_burn to VELOCITYAT(SHIP,time:seconds + node_eta).
	local r_burn to (POSITIONAT(SHIP,time:seconds + node_eta) - BODY:POSITION):MAG.
	local semi_major_axis_new to (r_burn + target_alt + BODY:RADIUS)/2.
	local v_target to sqrt(BODY:MU * (2/r_burn - 1/semi_major_axis_new)).
	local node_dv to v_target - v_burn:ORBIT:MAG.
	local my_node to NODE(time:seconds + node_eta,0,0,node_dv).
	add my_node.
}
function get_burn_t {
	declare local parameter dV.
	local e is CONSTANT:E.
	local eng_stats is get_engine_stats().
	local mass_rate is eng_stats[2].
	local v_e is eng_stats[3].
	local burn_t is  SHIP:MASS*(1 - e^(-dV/v_e))/mass_rate.
	return burn_t.
}
function get_engine_stats {
	local g is 9.82.
	local all_thrust is 0.
	local old_isp_devider is 0.
	local all_engines is LIST().
  	list ENGINES in all_engines.
	for eng in all_engines {
		if eng:IGNITION AND NOT eng:FLAMEOUT {
			set all_thrust to (all_thrust + eng:AVAILABLETHRUST).
			set old_isp_devider to (old_isp_devider + (eng:AVAILABLETHRUST / eng:VISP)).
		}
	}
	local mean_isp is (all_thrust / old_isp_devider).
	local ch_rate is all_thrust/(g*mean_isp).
	local exit_velocity is all_thrust/ch_rate.
	return list(all_thrust , mean_isp , ch_rate , exit_velocity).
}
function circularize {
	local th to 0.
	lock throttle to th.
	local dV is ship:facing:vector:normalized.
	lock steering to lookdirup(dV, ship:facing:topvector).
	ag1 off.
	local timeout is time:seconds + 9000.
	when dV:mag < 0.5 then set timeout to time:seconds + 3.
	until ag1 or dV:mag < 0.02 or time:seconds > timeout {
		local vecNormal to vcrs(up:vector,velocity:orbit).
		local vecHorizontal to -1 * vcrs(up:vector, vecNormal).
		set vecHorizontal:mag to sqrt(body:MU/(body:Radius + altitude)).
		set dV to vecHorizontal - velocity:orbit.
		if vang(ship:facing:vector,dV) > 1 {
			set th to 0.
		} else {
			set th to max(0,min(1,dV:mag/10)).
		}
		wait 0.
	}
	set th to 0.
}
function eta_true_anom {
	declare local parameter tgt_lng.
	local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).
	local node_true_anom to (mod (720+ tgt_lng - (obt:lan + obt:argumentofperiapsis),360)).
	print "Node anomaly   : " + round(node_true_anom,2).
	local node_eta to 0.
	local ecc to OBT:ECCENTRICITY.
	if ecc < 0.001 {
		set node_eta to SHIP:OBT:PERIOD * ((mod(tgt_lng - ship_ref + 360,360))) / 360.

	} else {
		local eccentric_anomaly to	arccos((ecc + cos(node_true_anom)) / (1 + ecc * cos(node_true_anom))).
		local mean_anom to (eccentric_anomaly - ((180 / (constant():pi)) * (ecc * sin(eccentric_anomaly)))).
		local time_2_anom to  SHIP:OBT:PERIOD * mean_anom /360.
		local my_time_in_orbit to ((OBT:MEANANOMALYATEPOCH)*OBT:PERIOD /360).
		set node_eta to mod(OBT:PERIOD + time_2_anom - my_time_in_orbit,OBT:PERIOD) .
	}
	return node_eta.
}
function set_inc_lan_ecc {
	declare local parameter incl_t.
	declare local parameter lan_t.
	local incl_i to SHIP:OBT:INCLINATION.
	local lan_i to SHIP:OBT:LAN.
	local Va to V(sin(incl_i)*cos(lan_i+90),sin(incl_i)*sin(lan_i+90),cos(incl_i)).
	local Vb to V(sin(incl_t)*cos(lan_t+90),sin(incl_t)*sin(lan_t+90),cos(incl_t)).
	local Vc to VCRS(Vb,Va).
	local dv_factor to 1.
	local node_lng to mod(arctan2(Vc:Y,Vc:X)+360,360).
	local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).
	local ship_2_node to mod((720 + node_lng - ship_ref),360).
	if ship_2_node > 180 {
		print "Switching to DN".
		set dv_factor to -1.
		set node_lng to mod(node_lng + 180,360).
	}
	local node_true_anom to 360- mod(720 + (obt:lan + obt:argumentofperiapsis) - node_lng , 360 ).
	local ecc to OBT:ECCENTRICITY.
	local my_radius to OBT:SEMIMAJORAXIS * (( 1 - ecc^2)/ (1 + ecc*cos(node_true_anom)) ).
	local my_speed1 to sqrt(SHIP:BODY:MU * ((2/my_radius) - (1/OBT:SEMIMAJORAXIS)) ).
	local node_eta to eta_true_anom(node_lng).
	local my_speed to VELOCITYAT(SHIP, time+node_eta):ORBIT:MAG.
	local d_inc to arccos (vdot(Vb,Va) ).
	local dvtgt to dv_factor* (2 * (my_speed) * SIN(d_inc/2)).
	local inc_node to NODE(node_eta, 0, 0, 0).
	set inc_node:NORMAL to dvtgt * cos(d_inc/2).
	set inc_node:PROGRADE to 0 - abs(dvtgt * sin(d_inc/2)).
	set inc_node:ETA to node_eta.
	ADD inc_node.
}
function impact_check{
	declare local parameter orb.
	local thrott to 0.
	lock throttle to thrott.
	local np to prograde.
	if ship:periapsis < orb {
		lock steering to np.
		wait until abs(np:pitch - facing:pitch) < 0.1 and abs(np:yaw - facing:yaw) < 0.1.
		set thrott to 0.3.
		wait until ship:periapsis > orb.
		set thrott to 0.
	}
}
function PID_init {
  parameter
    Kp,      // gain of position
    Ki,      // gain of integral
    Kd,      // gain of derivative
    cMin,  // the bottom limit of the control range (to protect against integral windup)
    cMax.  // the the upper limit of the control range (to protect against integral windup)

  local SeekP is 0. // desired value for P (will get set later).
  local P is 0.     // phenomenon P being affected.
  local I is 0.     // crude approximation of Integral of P.
  local D is 0.     // crude approximation of Derivative of P.
  local oldT is -1. // (old time) start value flags the fact that it hasn't been calculated
  local oldInput is 0. // previous return value of PID controller.

  // Because we don't have proper user structures in kOS (yet?)
  // I'll store the PID tracking values in a list like so:
  //
  local PID_array is list(Kp, Ki, Kd, cMin, cMax, SeekP, P, I, D, oldT, oldInput).

  return PID_array.
}.

function PID_seek {
  parameter
    PID_array, // array built with PID_init.
    seekVal,   // value we want.
    curVal.    // value we currently have.

  // Using LIST() as a poor-man's struct.

  local Kp   is PID_array[0].
  local Ki   is PID_array[1].
  local Kd   is PID_array[2].
  local cMin is PID_array[3].
  local cMax is PID_array[4].
  local oldS   is PID_array[5].
  local oldP   is PID_array[6].
  local oldI   is PID_array[7].
  local oldD   is PID_array[8].
  local oldT   is PID_array[9]. // Old Time
  local oldInput is PID_array[10]. // prev return value, just in case we have to do nothing and return it again.

  local P is seekVal - curVal.
  local D is oldD. // default if we do no work this time.
  local I is oldI. // default if we do no work this time.
  local newInput is oldInput. // default if we do no work this time.

  local t is time:seconds.
  local dT is t - oldT.

  if oldT < 0 {
    // I have never been called yet - so don't trust any
    // of the settings yet.
  } else {
    if dT > 0 { // Do nothing if no physics tick has passed from prev call to now.
     set D to (P - oldP)/dT. // crude fake derivative of P
     local onlyPD is Kp*P + Kd*D.
     if (oldI > 0 or onlyPD > cMin) and (oldI < 0 or onlyPD < cMax) { // only do the I turm when within the control range
      set I to oldI + P*dT. // crude fake integral of P
     }.
     set newInput to onlyPD + Ki*I.
    }.
  }.

  set newInput to max(cMin,min(cMax,newInput)).

  // remember old values for next time.
  set PID_array[5] to seekVal.
  set PID_array[6] to P.
  set PID_array[7] to I.
  set PID_array[8] to D.
  set PID_array[9] to t.
  set PID_array[10] to newInput.

  return newInput.
}.
