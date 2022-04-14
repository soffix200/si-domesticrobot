limit(max, owner, waitTime,       10000).
limit(min, owner, waitTime,       2000).
limit(max, robot, dailyPayment,   50).
limit(max, owner, monthlyPension, 2000).

politeness(owner, 0).
status(owner, animado).

healthConstraint(Product) :-
	.date(YY,MM,DD) &
	healthConstraint(Product,YY,MM,DD).

!setupTool("Owner", "Robot"). // THIS MAY CRASH

!initOwner.
// !cheerUp. TODO

!talkRobot.
// !cleanHouse // TODO
!drinkBeer.
// !wakeUp // TODO

+!initOwner <-
	!createPostIt;
	!expectPension.

// -------------------------------------------------------------------------
// TRIGGERS
// -------------------------------------------------------------------------

+pay(robot, Amount) : has(money, Balance) & Balance >= Amount <-
	.date(YY,MM,DD);
	?limit(max, robot, dailyPayment, Limit);
	if (paid(YY,MM,DD, AmountPaid)) {
		if (AmountPaid + Amount <= Limit) {
			.println("Tengo dinero, ahora le pago a robot los ", Amount, " que me ha pedido");
			-+paid(YY,MM,DD, AmountPaid+Amount);
			.send(robot, tell, msg("Ten los ", Amount, " que me has pedido."));
			.send(robot, tell, pay(Amount)); // TODO AIML
			.send(postit, achieve, add(paid, YY,MM,DD, AmountPaid+Amount));
		} else {
			.println("No puedo gastar más en cervezas hoy o me desahuciarán");
			.send(robot, tell, cannotpay(Amount));
		}
	} else {
		if (Amount < Limit){
			.println("Tengo dinero, ahora le pago a robot los ", Amount, " que me ha pedido");
			-+paid(YY,MM,DD, Amount);
			.send(robot, tell, msg("Ten los ", Amount, " que me has pedido."));
			.send(robot, tell, pay(Amount)); // TODO AIML
			.send(postit, achieve, add(paid, YY,MM,DD, Amount));
		} else {
			.println("Esa cantidad est� por encima de mi presupuesto diario!");
			.send(robot, tell, cannotpay(Amount));
		}
	}
	.abolish(pay(robot, Amount)).
+pay(robot, Amount) : has(money, Balance) & Balance < Amount<-
	.println("No me queda dinero, a ver si la pensi�n llega pronto");
	.send(robot, tell, cannotpay(Amount));
	.abolish(pay(robot, Amount)).

// -------------------------------------------------------------------------
// DEFINITION FOR createPostIt
// -------------------------------------------------------------------------

+!createPostIt <-
	.list_files("./tmp/","postit.asl", L);
	if (.length(L, 0)) {
		.create_agent("postit", "postit.asl");
	} else {
		.create_agent("postit", "./tmp/postit.asl"); 
	}
	.send(postit, askOne, has(money, X), MoneyResponse);
	.date(YY,MM,DD);
	.send(postit, askOne, paid(YY,MM,DD, Money), PaidResponse);
	-+MoneyResponse;
	-+PaidResponse.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN expectPension
// -------------------------------------------------------------------------

+!expectPension : .date(YY,MM,1) & not lastPension(YY,MM) <-
	?has(money, Balance);
	?limit(max, owner, monthlyPension, Amount);
	.println("Qué felicidad! Me ha llegado una pensión de ", Amount);
	-+lastPension(YY,MM);
	.abolish(has(money, Balance));
	+has(money, Balance+Amount);
	.send(postit, achieve, add(money, Amount));
	.wait(3600000);
	!expectPension.
+!expectPension <-
	.wait(3600000);
	!expectPension.

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
	?limit(min, owner, waitTime, MinWaitTime);
	?limit(max, owner, waitTime, MaxWaitTime);
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

// ## HELPER TRIGGER has

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
