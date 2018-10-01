set myalt to 1000000.
set target to "Mun".
HMTransfer().
wait 5.
node_apo(myalt).
run_node().
wait 5.
node_peri(myalt).
run_node().
wait 5.
node_inc(0).
run_node().