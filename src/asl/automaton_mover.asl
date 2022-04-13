status(inactive).
obstacles([]).

available(Object, LocationDescriptor) :-
	stored(Object, LocationDescriptor, Qtty) & Qtty > 0.

// -------------------------------------------------------------------------
// TRIGGERS
// -------------------------------------------------------------------------

+activate(mover, depot(X, Y), bounds(BX, BY)) :
	status(active) | status(idle) | status (activating)
<-
	.abolish(activate(mover, depot(X, Y), bounds(BX, BY))).
+activate(mover, depot(X, Y), bounds(BX, BY)) :
	status(inactive) | status(deactivatng)
<-
	.abolish(activate(mover, depot(X, Y), bounds(BX, BY)));
	!activate(mover, depot(X, Y), bounds(BX, BY)).

+deactivate(mover) : status(inactive) | status(deactivating) <-
	.abolish(deactivate(mover)).
+deactivate(mover) : status(idle) | status(active) | status(activating) <-
	!deactivate(mover);
	.abolish(deactivate(mover)).

+move(Object, location(ODescriptor, OX, OY, OPlacement), location(DDescriptor, DX, DY, DPlacement), Obstacles) <-
	-+obstacles(Obstacles);
	+requestedMovement(Object, location(ODescriptor, OX, OY, OPlacement), location(DDescriptor, DX, DY, DPlacement));
	.abolish(move(Object, location(ODescriptor, OX, OY, OPlacement), location(DDescriptor, DX, DY, DPlacement), Obstacles)).

// ## HELPER PLAN activate

+!activate(mover, depot(X, Y), bounds(BX, BY)) :
	status(inactive)
<-
	-+status(activating);
	.println("Activando mover");
	enter(map);
	-+at(mover, X, Y);
	-+depot(X, Y);
	-+bounds(BX, BY);
	-+status(active);
	!move.
+!activate(mover, depot(X, Y), bounds(BX, BY)) :
	status(deactivating) 
<-
	.wait(100);
	!activate(mover, depot(X, Y), bounds(BX, BY)).

// ## HELPER PLAN deactivate

+!deactivate(mover) : status(idle) <-
	-+status(deactivating);
	.println("Desactivando mover");
	?depot(X, Y);
	!goAtLocation(X, Y, top);
	exit(map);
	-at(mover, _, _);
	-+status(inactive).
+!deactivate(mover) : status(active) | status(deactivating) <-
	.wait(100);
	!deactivate(mover).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN move
// -------------------------------------------------------------------------

+!move :
	status(idle) &
	requestedMovement(Object, location(ODescriptor, OX, OY, OPlacement), location(DDescriptor, DX, DY, DPlacement))
<-
	-+status(active);
	.println("Intentando mover ", Object, " de ", ODescriptor, " a ", DDescriptor);
	.abolish(requestedMovement(Object, location(ODescriptor, OX, OY, OPlacement), location(DDescriptor, DX, DY, DPlacement)));
	.println("Desplazándose a ", ODescriptor);
	!goAtLocation(OX, OY, OPlacement);
	.println("Cogiendo ", Object);
	!pick(Object, ODescriptor, DDescriptor);
	.println("Desplazándose a ", DDescriptor);
	!goAtLocation(DX, DY, DPlacement);
	.println("Dejando ", Object);
	!drop(Object, DDescriptor);
	.send(robot, tell, moved(success, Object, ODescriptor, DDescriptor));
	-+status(idle);
	!move.
+!move : status(idle) <- !move.
+!move : status(inactive) | status(activating) | status(deactivating) <- true.

-!move <- // Reactivates move plan after failure
	-+status(idle);
	!move.

// ## HELPER PLAN pick

+!pick(Object, LocationDescriptor, DDescriptor) :
	Object == beer & LocationDescriptor == fridge
<-
	open(LocationDescriptor);
	.wait(100);
	if (available(Object, LocationDescriptor)) {
		get(Object, LocationDescriptor);
		close(LocationDescriptor);
		?stored(Object, LocationDescriptor, Qtty);
		.send(robot, tell, stock(Object, LocationDescriptor, Qtty));
	} else {
		close(LocationDescriptor);
		.send(robot, tell, stock(Object, LocationDescriptor, 0));
		.send(robot, tell, moved(failure, Object, LocationDescriptor, DDescriptor));
		.fail;
	}.
+!pick(Object, LocationDescriptor, DDescriptor) :
	Object == beer & LocationDescriptor == delivery
<-
	.wait(100).
	// TODO grab them

// ## HELPER TRIGGER stock

+stock(Object, LocationDescriptor, Qtty) <-
	-+stored(Object, LocationDescriptor, Qtty).

// ## HELPER PLAN drop

+!drop(Object, LocationDescriptor) :
	Object == beer & LocationDescriptor == owner
<-
	hand_in(Object).
+!drop(Object, LocationDescriptor) :
	Object == beer & LocationDescriptor == fridge
<-
	open(LocationDescriptor);
	// TODO deposit in fridge
	close(LocationDescriptor);
	?stored(Object, LocationDescriptor, Qtty);
	.send(robot, tell, stock(Object, LocationDescriptor, Qtty)).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN goAtLocation
// -------------------------------------------------------------------------

+!goAtLocation(DX, DY, Placement) :
	at(mover, DX, DY) |
	(Placement == side & (at(mover, DX, DY+1) | at(mover, DX, DY-1) | at(mover, DX+1, DY) | at(mover(DX-1, DY))))
<-
	true.
+!goAtLocation(DX, DY, Placement) :
	not at(mover, DX, DY) &
	not (Placement == side & (at(mover, DX, DY+1) | at(mover, DX, DY-1) | at(mover, DX+1, DY) | at(mover(DX-1, DY))))
<-
	?at(mover, OX, OY); ?bounds(BX, BY); ?obstacles(Obstacles);
	movement.getDirection(origin(OX, OY), destination(DX, DY, Placement), bounds(BX, BY), Obstacles, Direction);
	move_towards(mover, Direction);
	!updateLocationBelief(Direction);
	!goAtLocation(DX, DY, Placement).

// ## HELPER PLAN updateLocationBelief

+!updateLocationBelief(Direction) : Direction == right <-
	?at(mover, X, Y);
	-+at(mover, X+1, Y).
+!updateLocationBelief(Direction) : Direction == left <-
	?at(mover, X, Y);
	-+at(mover, X-1, Y).
+!updateLocationBelief(Direction) : Direction == down <-
	?at(mover, X, Y);
	-+at(mover, X, Y+1).
+!updateLocationBelief(Direction) : Direction == up <-
	?at(mover, X, Y);
	-+at(mover, X, Y-1).