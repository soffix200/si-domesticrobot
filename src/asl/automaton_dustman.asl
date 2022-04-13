status(inactive).
obstacles([]).

// -------------------------------------------------------------------------
// TRIGGERS
// -------------------------------------------------------------------------

+activate(dustman, depot(DepX, DepY, DepPlacement), dumpster(DumpX, DumpY, DumpPlacement), exit(EX, EY, EPlacement), bounds(BX, BY)) :
	status(active) | status(idle) | status (activating)
<-
	.abolish(activate(dustman, depot(DepX, DepY, DepPlacement), dumpster(DumpX, DumpY, DumpPlacement), exit(EX, EY, EPlacement), bounds(BX, BY))).
+activate(dustman, depot(DepX, DepY, DepPlacement), dumpster(DumpX, DumpY, DumpPlacement), exit(EX, EY, EPlacement), bounds(BX, BY)) :
	status(inactive) | status(deactivatng)
<-
	.abolish(activate(dustman, depot(DepX, DepY, DepPlacement), dumpster(DumpX, DumpY, DumpPlacement), exit(EX, EY, EPlacement), bounds(BX, BY)));
	!activate(dustman, depot(DepX, DepY, DepPlacement), dumpster(DumpX, DumpY, DumpPlacement), exit(EX, EY, EPlacement), bounds(BX, BY)).

+deactivate(dustman) : status(inactive) | status(deactivating) <-
	.abolish(deactivate(dustman)).
+deactivate(dustman) : status(idle) | status(active) | status(activating) <-
	!deactivate(dustman);
	.abolish(deactivate(dustman)).

+takeout(trash, Obstacles) <-
  -+obstacles(Obstacles);
  +requestedTakeout(trash);
  .abolish(takeout(trash, Obstacles)).

// ## HELPER PLAN activate

+!activate(dustman, depot(DepX, DepY, DepPlacement), dumpster(DumpX, DumpY, DumpPlacement), exit(EX, EY, EPlacement), bounds(BX, BY)) :
	status(inactive)
<-
	-+status(activating);
	.println("Activando dustman");
	enter(map);
	-+at(dustman, DepX, DepY);
	-+depot(DepX, DepY, DepPlacement);
  -+dumpster(DumpX, DumpY, DumpPlacement);
  -+exit(EX, EY, EPlacement);
	-+bounds(BX, BY);
	-+status(idle);
	!takeout(trash).
+!activate(dustman, depot(DepX, DepY, DepPlacement), dumpster(DumpX, DumpY, DumpPlacement), exit(EX, EY, EPlacement), bounds(BX, BY)) :
	status(deactivating) 
<-
	.wait(100);
	!activate(dustman, depot(DepX, DepY, DepPlacement), dumpster(DumpX, DumpY, DumpPlacement), exit(EX, EY, EPlacement), bounds(BX, BY)).

// ## HELPER PLAN deactivate

+!deactivate(dustman) : status(idle) <-
	-+status(deactivating);
	.println("Desactivando dustman");
	?depot(X, Y, Placement);
	!goAtLocation(X, Y, Placement);
	exit(map);
	-at(dustman, _, _);
	-+status(inactive).
+!deactivate(dustman) : status(active) | status(deactivating) <-
	.wait(100);
	!deactivate(dustman).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN takeout(trash)
// -------------------------------------------------------------------------

+!takeout(trash) :
  status(idle) &
  requestedTakeout(trash)
<-
	-+status(active);
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
	-+status(idle);
  !takeout(trash).
+!takeout(trash) : status(idle) <- !takeout(trash).
+!takeout(trash) : status(inactive) | status(activating) | status(deactivating) <- true.

-!takeout(trash) <- // Reactivates takeout plan after failure
	-+status(idle);
	!takeout(trash).

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