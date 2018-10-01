copypath("1:satcom.updates.ks","0:backup/satcom.updates.ks").
set Geosat to 2863333.52.
node_apo(Geosat).
run_node().
wait 5.
node_peri(Geosat).
run_node().
wait 5.
node_inc(0).
run_node().
tts().
set ship:name to KerSat1.