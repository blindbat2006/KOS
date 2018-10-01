run once "functions".
parameter
  compass is 90,
  orbit_height is 80000,
  count is 5,
  second_height is -1,
  second_height_long is -1,
  atmo_end is 70000.

set ship:control:pilotmainthrottle to 0.

launcher(compass, orbit_height, true, second_height, second_height_long, atmo_end).
