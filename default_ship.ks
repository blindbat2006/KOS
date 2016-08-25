SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
run lib_nav2.
run lib_auto.
set AG8 to false.
if has_file(ship:name +".ks",1){
	if has_file(boot_master.ks,1){
		delete boot_master.
		rename ship:name +".ks" to boot_master.ks.
	}
}.
if has_file(launch.ks,1){delete launch.}.
if has_file(tmp.ks,1){delete tmp.}.
if has_file(tmp.exec.ks,1){delete tmp.exec.ks.}.
set upfile to ship:name +"_updates.ks".
clearscreen.
until 0 {
	if addons:rt:hasconnection(ship){
		delay().
		clearscreen.
		print "Delay time " + round(dTime,3) + " secs.".
		wait 1.
		print "Checking for updates v1.6.".
		if has_file(""+upfile,0){
			print "Updates received and running.".
			download(""+upfile).
			delete ""+upfile from 0.
			wait 5.
			rename ""+upfile to tmp.exec.ks.
			wait 2.
			run tmp.exec.ks.
			wait 5.
			print "Now cleaning up files.".
			delete tmp.exec.ks.
			print "System reboot required.".
			wait 3.
			reboot.
		}
		else{
			delay().
			print "No more updates going to wait 20 secs".
			wait 20.
		}
  }
	else{
		clearscreen.
		print "No connection. Waiting .....".
		wait until addons:rt:haskscconnection(ship).
	}
}
