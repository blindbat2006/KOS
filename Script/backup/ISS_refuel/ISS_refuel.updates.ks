//ISS Dragon
set myalt to 400000.
if eta:periapsis < eta:apoapsis
{
	node_apo(myalt).
	run_node().
}else
{
	node_peri(myalt).
	run_node().
}
set target to vessel("ISS").
approach(0).
clearscreen.
print "Get within 100m of target then docking will begin". 
wait until target:distance < 100.
dock("ISS_DOCK"). //Main port at front
SET SHIP:CONTROL:NEUTRALIZE to TRUE.
iss_returner().
paraland().