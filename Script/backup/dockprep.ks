lights off.
RCS on.
SAS off.
lock radialvec to vxcl(prograde:vector, up:vector).
lock steering to radialvec.
wait 5.
lights on.
wait until abs(steeringmanager:yawerror) < 2 and abs(steeringmanager:pitcherror) < 2 and abs(steeringmanager:rollerror) < 2.
SAS on.