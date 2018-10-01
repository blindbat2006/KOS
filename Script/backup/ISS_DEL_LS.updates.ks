copypath("0:iss_return","1:").
set target to vessel("ISS").
approach(0).
dock("ISS"). //Main port at front
//dock("ISS_TUG"). // Tug position
//dock("ISS_FUEL"). //Fuel Transfers
//dock("ISS_Supplies"). //LS Tranfers

//dock("ISS_LFO1").
//dock("ISS_LFO2").
//dock("ISS_MONO").
//dock("ISS_CarbonExt").
//dock("ISS_Purifier").
//dock("ISS_Sabatier").
//dock("ISS_FOOD").
//dock("ISS_O2").
//dock("ISS_H2O").
//dock().
SET SHIP:CONTROL:NEUTRALIZE to TRUE.
run iss_return.