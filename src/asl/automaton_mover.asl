status(inactive).
obstacles([]).

available(Object, LocationDescriptor) :-
	stored(Object, LocationDescriptor, Qtty) & Qtty > 0.

// -------------------------------------------------------------------------
// TRIGGERS
// -------------------------------------------------------------------------

+activate(mover, depot(X, Y), bounds(BX, BY)) <-
	.println("Mover activado");
	enter(map);
	-+at(mover, X, Y);
	-+depot(X, Y);
	-+bounds(BX, BY);
	-+status(active);
	.abolish(activate(mover, depot(X, Y), bounds(BX, BY)));
	!move.

+deactivate(mover) <-
	.println("Mover desactivado");
	?depot(X, Y);
	!goAtLocation(X, Y, top);
	exit(map);
	-at(mover, _, _);
	-+status(inactive);
	.abolish(deactivate(mover)).

+move(Object, location(ODescriptor, OX, OY, OPlacement), location(DDescriptor, DX, DY, DPlacement), Obstacles) <-
	-+obstacles(Obstacles);
	+requestedMovement(Object, location(ODescriptor, OX, OY, OPlacement), location(DDescriptor, DX, DY, DPlacement));
	.abolish(move(Object, location(ODescriptor, OX, OY, OPlacement), location(DDescriptor, DX, DY, DPlacement), Obstacles)).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN move
// -------------------------------------------------------------------------

+!move :
	status(active) &
	requestedMovement(Object, location(ODescriptor, OX, OY, OPlacement), location(DDescriptor, DX, DY, DPlacement))
<-
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
	.send(robot, tell, movement(success, Object, ODescriptor, DDescriptor));
	!move.
+!move : status(active) <- !move.
+!move : status(inactive) <- true.

-!move <- !move. // Reactivates move plan after failure

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
		.send(robot, tell, movement(failure, Object, LocationDescriptor, DDescriptor));
		.fail;
	}.

// ## HELPER TRIGGER stock

+stock(Object, LocationDescriptor, Qtty) <-
	.abolish(stored(Object, LocationDescriptor, _));
	+stored(Object, LocationDescriptor, Qtty);
	.abolish(stock(Object, LocationDescriptor, Qtty)).

// ## HELPER PLAN drop

+!drop(Object, LocationDescriptor) :
	Object == beer & LocationDescriptor == owner
<-
	hand_in(Object).

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