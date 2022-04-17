status(inactive).
obstacles([]).

// -------------------------------------------------------------------------
// TRIGGERS
// -------------------------------------------------------------------------

+activate(cleaner, depot(DepX, DepY), dumpster(DumpX, DumpY), bounds(BX, BY)) :
	status(active) | status(idle) | status (activating)
<-
	.abolish(activate(cleaner, depot(DepX, DepY), dumpster(DumpX, DumpY), bounds(BX, BY))).
+activate(cleaner, depot(DepX, DepY), dumpster(DumpX, DumpY), bounds(BX, BY)) :
	status(inactive) | status(deactivating)
<-
	.abolish(activate(cleaner, depot(DepX, DepY), dumpster(DumpX, DumpY), bounds(BX, BY)));
	!activate(cleaner, depot(DepX, DepY), dumpster(DumpX, DumpY), bounds(BX, BY)).

+deactivate(cleaner) : status(inactive) | status(deactivating) <-
	.abolish(deactivate(cleaner)).
+deactivate(cleaner) : status(idle) | status(active) | status(activating) <-
	!deactivate(cleaner);
	.abolish(deactivate(cleaner)).

+clean(Object, floor(X, Y), Obstacles) <-
	-+obstacles(Obstacles);
	+requestedCleanup(Object, floor(X, Y));
	.abolish(clean(Object, floor(X, Y), Obstacles)).

+clean(Object, location(Agent, X, Y, Placement), Obstacles) <-
	-+obstacles(Obstacles);
	+requestedCleanup(Object, location(Agent, X, Y, Placement));
	.abolish(clean(Object, location(Agent, X, Y, Placement), Obstacles)).

// ## HELPER PLAN activate

+!activate(cleaner, depot(DepX, DepY), dumpster(DumpX, DumpY), bounds(BX, BY)) :
	status(inactive)
<-
	-+status(activating);
	.println("Activando cleaner");
	enter(map);
	-+at(cleaner, DepX, DepY);
	-+depot(DepX, DepY);
	-+dumpster(DumpX, DumpY);
	-+bounds(BX, BY);
	-+status(idle);
	!clean.
+!activate(cleaner, depot(DepX, DepY), dumpster(DumpX, DumpY), bounds(BX, BY)) :
	status(deactivating) 
<-
	.wait(100);
	!activate(cleaner, depot(DepX, DepY), dumpster(DumpX, DumpY), bounds(BX, BY)).

// ## HELPER PLAN deactivate

+!deactivate(cleaner) : status(idle) <-
	-+status(deactivating);
	.println("Desactivando cleaner");
	?depot(X, Y);
	!goAtLocation(X, Y, top);
	exit(map);
	-at(cleaner, _, _);
	-+status(inactive).
+!deactivate(cleaner) : status(active) | status(deactivating) <-
	.wait(100);
	!deactivate(cleaner).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN clean
// -------------------------------------------------------------------------

+!clean :
	status(idle) &
	requestedCleanup(Object, floor(X, Y))
<-
	-+status(active);
	.println("Intentando limpiar ", Object, " en (", X, ", ", Y, ")");
	.abolish(requestedCleanup(Object, floor(X, Y)));
	.println("Desplazandose a (", X, ", ", Y, ")");
	!goAtLocation(X, Y, top);
	.println("Cogiendo ", Object);
	!pick(Object, floor);
	.println("Desplazandose a dumpster");
	?dumpster(DumpX, DumpY);
	!goAtLocation(DumpX, DumpY, side);
	.println("Tirando ", Object);
	!trash(Object);
	.send(butler, tell, cleaned(success, Object, floor(X, Y)));
	-+status(idle);
	!clean.
+!clean :
	status(idle) &
	requestedCleanup(Object, location(Agent, X, Y, Placement))
<-
	-+status(active);
	.println("Intentando recoger ", Object, " de ", Agent);
	.abolish(requestedCleanup(Object, location(Agent, X, Y, Placement)));
	.println("Desplazandose a ", Agent);
	!goAtLocation(X, Y, Placement);
	.println("Cogiendo ", Object);
	!pick(Object, Agent);
	.println("Desplazandose a dumpster");
	?dumpster(DumpX, DumpY);
	!goAtLocation(DumpX, DumpY, side);
	.println("Tirando ", Object);
	!trash(Object);
	.send(butler, tell, cleaned(success, Object, Agent));
	-+status(idle);
	!clean.
+!clean : status(idle) <- !clean.
+!clean : status(inactive) | status(activating) | status(activating) <- true.

-!clean <- // Reactivates clean plan after failure
	-+status(idle);
	!clean.

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