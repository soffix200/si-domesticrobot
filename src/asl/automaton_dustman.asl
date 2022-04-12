status(inactive).
obstacles([]).

// -------------------------------------------------------------------------
// TRIGGERS
// -------------------------------------------------------------------------

+activate(dustman, depot(DepX, DepY, DepPlacement), dumpster(DumpX, DumpY, DumpPlacement), exit(EX, EY, EPlacement), bounds(BX, BY)) <-
	.println("Dustman activado");
	enter(map);
	-+at(dustman, DepX, DepY);
	-+depot(DepX, DepY, DepPlacement);
  -+dumpster(DumpX, DumpY, DumpPlacement);
  -+exit(EX, EY, EPlacement);
	-+bounds(BX, BY);
	-+status(active);
	.abolish(activate(dustman, depot(DepX, DepY, DepPlacement), dumpster(DumpX, DumpY, DumpPlacement), exit(EX, EY, EPlacement), bounds(BX, BY)));
	!takeout(trash).

+deactivate(dustman) <-
	.println("Dustman desactivado");
	?depot(X, Y);
	!goAtLocation(X, Y, top);
	exit(map);
	-at(dustman, _, _);
	-+status(inactive);
	.abolish(deactivate(dustman)).

+takeout(trash, Obstacles) <-
  -+obstacles(Obstacles);
  +requestedTakeout(trash);
  .abolish(takeout(trash, Obstacles)).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN takeout(trash)
// -------------------------------------------------------------------------

+!takeout(trash) :
  status(active) &
  requestedTakeout(trash)
<-
  .println("Intentando sacar la basura");
  .abolish(requestedTakeout(trash));
  .println("Desplazándose a dumpster");
  ?dumpster(DumpX, DumpY, DumpPlacement);
  !goAtLocation(DumpX, DumpY, DumpPlacement);
  .println("Recogiendo la basura");
  collect(trash);
  .println("Desplazándose a exit");
  ?exit(EX, EY, EPlacement);
  !goAtLocation(EX, EY, EPlacement);
  .send(robot, tell, tookout(success, trash));
  !takeout(trash).
+!takeout(trash) : status(active) <- !takeout(trash).
+!takeout(trash) : status(inactive) <- true.

-!takeout(trash) <- !takeout(trash). // Reactivates move plan after failure

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN goAtLocation
// -------------------------------------------------------------------------

+!goAtLocation(DX, DY, Placement) :
	at(dustman, DX, DY) |
	(Placement == side & (at(dustman, DX, DY+1) | at(dustman, DX, DY-1) | at(dustman, DX+1, DY) | at(dustman(DX-1, DY))))
<-
	true.
+!goAtLocation(DX, DY, Placement) :
	not at(dustman, DX, DY) &
	not (Placement == side & (at(dustman, DX, DY+1) | at(dustman, DX, DY-1) | at(dustman, DX+1, DY) | at(dustman(DX-1, DY))))
<-
	?at(dustman, OX, OY); ?bounds(BX, BY); ?obstacles(Obstacles);
	movement.getDirection(origin(OX, OY), destination(DX, DY, Placement), bounds(BX, BY), Obstacles, Direction);
	move_towards(dustman, Direction);
	!updateLocationBelief(Direction);
	!goAtLocation(DX, DY, Placement).

// ## HELPER PLAN updateLocationBelief

+!updateLocationBelief(Direction) : Direction == right <-
	?at(dustman, X, Y);
	-+at(dustman, X+1, Y).
+!updateLocationBelief(Direction) : Direction == left <-
	?at(dustman, X, Y);
	-+at(dustman, X-1, Y).
+!updateLocationBelief(Direction) : Direction == down <-
	?at(dustman, X, Y);
	-+at(dustman, X, Y+1).
+!updateLocationBelief(Direction) : Direction == up <-
	?at(dustman, X, Y);
	-+at(dustman, X, Y-1).