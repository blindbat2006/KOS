set ag8 to false.
copy test from 0.
print "Tested copied".
wait 1.
run test.
print "Test run".
wait 1.
//set target to vessel("KSS").
print "Select the target ship".
print  "Then press AG8".
wait until ag8.
set AG8 to false.
clearscreen.
wait 1.
print "Now select the Targets Docking port (need to be less than 200m)".
print "Remember to tag your docking port to MyPort".
print  "Now press AG8".
wait until ag8.
clearscreen.
lock targetPort to target.
lock targetship to target:ship.
print "Target ships Name is: " + targetship.
print "and the target ports name is: " +targetPort.
wait 5.
set AG8 to false.
dok_dock(targetship, targetport, "MyPort").