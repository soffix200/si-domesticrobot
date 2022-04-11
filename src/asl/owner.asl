waitTime(min,  2000).
waitTime(max, 10000).

// has(owner, beer).         // Perceived from environment
// has(owner, can).          // Not perceived from environment
// has(owner, halfemptycan). // Not perceived from environment

politeness(owner, 0).
status(owner, animado).
dailyPayment(50).

paidToday(robot) :-
	.date(YY,MM,DD) &
	.count(paid(YY,MM,DD,Money),QtdB) &
	QtdB > 0.

healthConstraint(Product) :-
	.date(YY,MM,DD) &
	healthConstraint(Product,YY,MM,DD).

!setupTool("Owner", "Robot").

!talkRobot.
// !cleanHouse // TODO
!drinkBeer.

// !wakeUp // TODO

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN dailyPayout
// -------------------------------------------------------------------------

+!pay(robot): not paidToday(robot) & dailyPayment(DailyPayout) <-
	.date(YY,MM,DD);
	+paid(YY,MM,DD,DailyPayout); //TODO PERSISTENCE
	.send(robot, tell, msg("Ten tus ", dailyPayout, " diarios."));
	.send(robot, tell, pay(money,50)); //TODO en AIML
	.wait(1000);
	.send(robot, achieve, receive(money)). //TODO en AIML
+!pay(robot) :  paidToday(robot) <-
	.println("No puedo gastar más en cervezas hoy o me desahuciarán, pídemelo mañana").

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN setupTool
// -------------------------------------------------------------------------

+!setupTool(Master, Robot) <-
	makeArtifact("GUI","gui.Console",[],GUI);
	setBotMasterName(Master);
	setBotName(Robot);
	focus(GUI). 

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN talkRobot
// -------------------------------------------------------------------------

+!talkRobot <-
	.send(robot, tell, msg("Test message")); // TODO IMPLEMENT AIML
	.random(X);
	?waitTime(min, MinWaitTime);
	?waitTime(max, MaxWaitTime);
	.wait(MinWaitTime + (MaxWaitTime - MinWaitTime)*X);
	!talkRobot.
	
// -------------------------------------------------------------------------
// DEFINITION FOR PLAN cleanHouse
// -------------------------------------------------------------------------

+!cleanHouse <- // Execute randomly
	// TODO; not yet implemented
	!cleanHouse.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN drinkBeer
// -------------------------------------------------------------------------

+!drinkBeer : healthConstraint(beer) <-
	.println("Owner ha bebido demasiado por hoy.");
	.wait(10000);
	-asked(robot, beer);
	!drinkBeer.
+!drinkBeer : has(owner, beer) & asked(robot, beer) <-
	.println("Voy a empezar a beber cerveza.");
	-asked(robot, beer);
	sip(beer);
	+has(owner, halfemptycan);
	!drinkBeer.
+!drinkBeer : has(owner, beer) & not asked(robot, beer) <-
	.println("Voy a beber un sorbo de cerveza.");
	sip(beer);
	+has(owner, halfemptycan);
	!drinkBeer.
+!drinkBeer : hasnot(owner, beer) & asked(robot, beer) <-
	.println("Sigo esperando mi cerveza");
	.wait(1000);
	!drinkBeer.
+!drinkBeer : hasnot(owner, beer) & not asked(robot, beer) <-
	.println("Pido una cerveza al robot");
	.send(robot, tell, bring(beer));
	+asked(robot, beer);
	!drinkBeer.
+!drinkBeer <- !drinkBeer.

+has(owner, halfemptycan) : hasnot(owner, beer) <-
	-has(owner, halfemptycan);
	+has(owner, can).
+has(owner, halfemptycan) <-
	-has(owner, halfemptycan).

+has(owner, can) : politeness(owner, 0) <-
	.println("Voy a tirar una lata");
	?bounds(BX, BY);
	.random(X); .random(Y);
	basemath.floor(X*BX, PX); basemath.floor(Y*BY, PY);
	while (location(_, obstacle, PX, PY)) {
		.random(X); .random(Y);
		basemath.floor(X*BX, PX); basemath.floor(Y*BY, PY);
	}
	throw(can, position(PX, PY));
	-has(owner, can);
	.send(robot, tell, msg("He tirado una lata"));
	.send(robot, tell, can(PX, PY)). // TODO AIML
+has(owner, can) : politeness(owner, 1) <-
	.println("Voy a pedirle al robot que venga a por la lata");
	.send(robot, tell, msg("Ven a por la lata")).
+has(owner, can) : politeness(owner, 2) <-
	.println("Voy a llevar la lata al cubo de basura").
	// TODO

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN wakeUp
// -------------------------------------------------------------------------

+!wakeup <-
	// TODO
	!wakeup.
