run_node().
wait 1.
set whoiam to ship:body.
wait until not (ship:body = whoiam).
set myalt to 255000.
node_apo(myalt).
run_node().
wait 5.
node_apo(myalt).
run_node().
wait 5.
node_inc(90).
run_node().
set ship:name to "MunScan250".