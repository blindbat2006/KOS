delete launch.
set wakeup to false.
until wakeup{
	wait 5.
	if addons:rt:HASKSCCONNECTION(ship) = true {
		clearscreen.
		print "Connected".
		set wakeup to true.
	}
}
//Rest of the program below.
delete lib_auto.
copy rendezvous from 0.
copy docking from 0.
wait 2.
set target to vessel("KSS").
wait 2.
match_plane(target).
run_node().
clearscreen.
print "Now rendezvous within 15k".
print "".
print "".
print "".
print "".
print "Then run the test script".