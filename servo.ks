for g in ADDONS:IR:GROUPS{
    //Print g:NAME + " contains " + g:SERVOS:LENGTH + " servos:".
    for s in g:servos{
        //print "    " + s:NAME + ", position: " + s:POSITION.
        if s:NAME = "Leg 1 Height" {
          print "hello".
          s:MOVETO(0,4).
        }

    }
}
