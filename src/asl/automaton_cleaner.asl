status(inactive).
obstacles([]).

// -------------------------------------------------------------------------
// TRIGGERS
// -------------------------------------------------------------------------

+activate(cleaner, depot(DepX, DepY), dumpster(DumpX, DumpY), bounds(BX, BY)) <-
	.println("Cleaner activado");
	enter(map);
	-+at(cleaner, DepX, DepY);
	-+depot(DepX, DepY);
	-+dumpster(DumpX, DumpY);
	-+bounds(BX, BY);
	-+status(active);
	.abolish(activate(cleaner, depot(X, Y), bounds(BX, BY)));
	!clean.

+deactivate(cleaner) <-
	.println("Cleaner desactivado");
	?depot(X, Y);
	!goAtLocation(X, Y, top);
	exit(map);
	-at(cleaner, _, _);
	-+status(inactive);
	.abolish(deactivate(cleaner)).

+clean(Object, floor(X, Y), Obstacles) <-
	-+obstacles(Obstacles);
	+requestedCleanup(Object, floor(X, Y));
	.abolish(clean(Object, floor(X, Y), Obstacles)).

+clean(Object, location(Agent, X, Y, Placement), Obstacles) <-
	-+obstacles(Obstacles);
	+requestedCleanup(Object, location(Agent, X, Y, Placement));
	.abolish(clean(Object, location(Agent, X, Y, Placement), Obstacles)).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN clean
// -------------------------------------------------------------------------

+!clean :
	status(active) &
	requestedCleanup(Object, floor(X, Y))
<-
	.println("Intentando limpiar ", Object, " en (", X, ", ", Y, ")");
	.abolish(requestedCleanup(Object, floor(X, Y)));
	.println("Desplazándose a (", X, ", ", Y, ")");
	!goAtLocation(X, Y, top);
	.println("Cogiendo ", Object);
	!pick(Object, floor);
	.println("Desplazándose a dumpster");
	?dumpster(DumpX, DumpY);
	!goAtLocation(DumpX, DumpY, side);
	.println("Tirando ", Object);
	!trash(Object);
	.send(robot, tell, cleaned(success, Object, floor(X, Y)));
	!clean.
+!clean :
	status(active) &
	requestedCleanup(Object, location(Agent, X, Y, Placement))
<-
	.println("Intentando recoger ", Object, " de ", Agent);
	.abolish(requestedCleanup(Object, location(Agent, X, Y, Placement)));
	.println("Desplazándose a ", Agent);
	!goAtLocation(X, Y, Placement);
	.println("Cogiendo ", Object);
	!pick(Object, Agent);
	.println("Desplazándose a dumpster");
	?dumpster(DumpX, DumpY);
	!goAtLocation(DumpX, DumpY, side);
	.println("Tirando ", Object);
	!trash(Object);
	.send(robot, tell, cleaned(success, Object, Agent));
	!clean.
+!clean : status(active) <- !clean.
+!clean : status(inactive) <- true.

-!clean <- !clean. // Reactivates clean plan after failure

// ## HELPER PLAN pick

+!pick(Object, floor) : Object == can <-
	get(Object).
+!pick(Object, Agent) : Object == can & Agent == owner <-
	get(Object).
	.send(Agent, tell, retrieved(Object)). // TODO not implemented

// ## HELPER PLAN trash

+!trash(Object) : Object == can <-
	recycle(Object).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN goAtLocation
// -------------------------------------------------------------------------

+!goAtLocation(DX, DY, Placement) :
	at(cleaner, DX, DY) |
	(Placement == side & (at(cleaner, DX, DY+1) | at(cleaner, DX, DY-1) | at(cleaner, DX+1, DY) | at(cleaner(DX-1, DY))))
<-
	true.
+!goAtLocation(DX, DY, Placement) :
	not at(cleaner, DX, DY) &
	not (Placement == side & (at(cleaner, DX, DY+1) | at(cleaner, DX, DY-1) | at(cleaner, DX+1, DY) | at(cleaner(DX-1, DY))))
<-
	?at(cleaner, OX, OY); ?bounds(BX, BY); ?obstacles(Obstacles);
	movement.getDirection(origin(OX, OY), destination(DX, DY, Placement), bounds(BX, BY), Obstacles, Direction);
	move_towards(cleaner, Direction);
	!updateLocationBelief(Direction);
	!goAtLocation(DX, DY, Placement).

// ## HELPER PLAN updateLocationBelief

+!updateLocationBelief(Direction) : Direction == right <-
	?at(cleaner, X, Y);
	-+at(cleaner, X+1, Y).
+!updateLocationBelief(Direction) : Direction == left <-
	?at(cleaner, X, Y);
	-+at(cleaner, X-1, Y).
+!updateLocationBelief(Direction) : Direction == down <-
	?at(cleaner, X, Y);
	-+at(cleaner, X, Y+1).
+!updateLocationBelief(Direction) : Direction == up <-
	?at(cleaner, X, Y);
	-+at(cleaner, X, Y-1).