set myalt to 25000.
set ag9 to false.
set target to "Minmus".
HMTransfer().
node_apo(myalt).
run_node().
node_apo(myalt).
run_node().
node_inc(0).
run_node().
wait until ag9.
set ship:name to "Ares3".
powerland().