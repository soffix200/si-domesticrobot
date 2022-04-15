limit(max, talk,  waitTime,       10000 ).
limit(min, talk,  waitTime,       2000  ).
limit(min, nap,   time,           120000).
limit(max, nap,   time,           720000).
limit(max, mood,  sipMoodCount,   6     ).
limit(max, robot, dailyPayment,   50    ).
limit(max, owner, monthlyPension, 2000  ).
limit(max, owner, cleanChance,    10    ).

nextMood(Current, Next) :- Current == despierto  & Next = animado.
nextMood(Current, Next) :- Current == animado    & Next = euforico.
nextMood(Current, Next) :- Current == euforico   & Next = crispado.
nextMood(Current, Next) :- Current == crispado   & Next = amodorrado.
nextMood(Current, Next) :- Current == amodorrado & Next = dormido.
nextMood(Current, Next) :- Current == dormido    & Next = despierto.

healthConstraint(Product) :-
	.date(YY,MM,DD) &
	healthConstraint(Product,YY,MM,DD).

!setupTool("Owner", "Robot"). // THIS MAY CRASH

!initOwner.
!talkRobot.
!expectPension.

+!initOwner <-
	!createAssistant;
	!cheerUp.
+!cheerUp : assistantCreated <-
	!cleanHouse; // TODO
	!drinkBeer;
	!wakeUp;
	!cheerUp.
+!cheerUp <- !cheerUp.

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
			.abolish(has(money, Balance)); +has(money, Balance-Amount);
			.send(robot, tell, msg("Ten los ", Amount, " que me has pedido."));
			.send(robot, tell, pay(Amount)); // TODO AIML
			.send(assistant, achieve, remember(paid(YY,MM,DD, AmountPaid+Amount)));
			.send(assistant, achieve, remember(has(money, Balance-Amount)));
		} else {
			.println("No puedo gastar más en cervezas hoy o me desahuciarán");
			.send(robot, tell, cannotpay(Amount));
		}
	} else {
		if (Amount < Limit){
			.println("Tengo dinero, ahora le pago a robot los ", Amount, " que me ha pedido");
			-+paid(YY,MM,DD, Amount);
			.abolish(has(money, Balance)); +has(money, Balance-Amount);
			.send(robot, tell, msg("Ten los ", Amount, " que me has pedido."));
			.send(robot, tell, pay(Amount)); // TODO AIML
			.send(assistant, achieve, remember(paid(YY,MM,DD, Amount)));
			.send(assistant, achieve, remember(has(money, Balance-Amount)));
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
// DEFINITION FOR createAssistant
// -------------------------------------------------------------------------

+!createAssistant <-
	.list_files("./tmp/","assistant.asl", L);
	if (.length(L, 0)) {
		.create_agent("assistant", "assistant.asl");
	} else {
		.create_agent("assistant", "./tmp/assistant.asl"); 
	}
	.date(YY,MM,DD);
	.send(assistant, askOne, has(money, X), MoneyResponse); -+MoneyResponse;
	.send(assistant, askOne, lastPension(YY,MM), PensionResponse); -+PensionResponse;
	.send(assistant, askOne, paid(YY,MM,DD, Money), PaidResponse); -+PaidResponse;
	.send(assistant, askOne, mood(owner, Mood), MoodResponse); -+MoodResponse;
	.send(assistant, askOne, sipMoodCount(owner, Count), SipMoodCountResponse); -+SipMoodCountResponse;
	+assistantCreated.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN expectPension
// -------------------------------------------------------------------------

+!expectPension : assistantCreated & .date(YY,MM,1) & not lastPension(YY,MM) <-
	?has(money, Balance);
	?limit(max, owner, monthlyPension, Amount);
	.println("Qué felicidad! Me ha llegado una pensión de ", Amount);
	-+lastPension(YY,MM);
	.abolish(has(money, Balance)); +has(money, Balance+Amount);
	.send(assistant, achieve, remember(lastPension(YY,MM)));
	.send(assistant, achieve, remember(has(money, Balance+Amount)));
	.wait(3600000);
	!expectPension.
+!expectPension : assistantCreated <-
	.wait(3600000);
	!expectPension.
+!expectPension <- !expectPension.

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

+!talkRobot : not mood(owner, dormido) <- // TODO different messages for each mood
	.send(robot, tell, msg("Test message")); // TODO IMPLEMENT AIML
	.random(X);
	?limit(min, talk, waitTime, MinWaitTime);
	?limit(max, talk, waitTime, MaxWaitTime);
	.wait(MinWaitTime + (MaxWaitTime - MinWaitTime)*X);
	!talkRobot.
+!talkRobot <- !talkRobot.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN cleanHouse
// -------------------------------------------------------------------------

+!cleanHouse : mood(owner, despierto) <- true. // TODO; not yet implemented
+!cleanHouse : limit(max, owner, cleanChance, Chance) & .random(X) & X*100 <= Chance <- true. // TODO; not yet implemented
+!cleanHouse <- true.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN drinkBeer
// -------------------------------------------------------------------------

+!drinkBeer : not mood(owner, dormido) & healthConstraint(beer) <-
	.println("Owner ha bebido demasiado por hoy.");
	.wait(10000);
	-asked(robot, beer).
+!drinkBeer : not mood(owner, dormido) & has(owner, beer) & asked(robot, beer) <-
	.println("Voy a empezar a beber cerveza.");
	-asked(robot, beer);
	sip(beer);
	?sipMoodCount(owner, SipMoodCount); ?limit(max, mood, sipMoodCount, Limit);
	if ((SipMoodCount+1) == Limit) {
		!transitionMood;
		-+sipMoodCount(owner, 0);
		.send(assistant, achieve, remember(sipMoodCount(owner, 0)));
	} else {
		-+sipMoodCount(owner, SipMoodCount+1);
		.send(assistant, achieve, remember(sipMoodCount(owner, SipMoodCount+1)));
	}
	+has(owner, halfemptycan).
+!drinkBeer : not mood(owner, dormido) & has(owner, beer) & not asked(robot, beer) <-
	.println("Voy a beber un sorbo de cerveza.");
	sip(beer);
	?sipMoodCount(owner, SipMoodCount); ?limit(max, mood, sipMoodCount, Limit);
	-+sipMoodCount(owner, SipMoodCount+1);
	if ((SipMoodCount+1) == Limit) {
		!transitionMood;
		-+sipMoodCount(owner, 0);
		.send(assistant, achieve, remember(sipMoodCount(owner, 0)));
	} else {
		-+sipMoodCount(owner, SipMoodCount+1);
		.send(assistant, achieve, remember(sipMoodCount(owner, SipMoodCount+1)));
	}
	+has(owner, halfemptycan).
+!drinkBeer : not mood(owner, dormido) & hasnot(owner, beer) & asked(robot, beer) <-
	.println("Sigo esperando mi cerveza");
	.wait(1000).
+!drinkBeer : not mood(owner, dormido) & hasnot(owner, beer) & not asked(robot, beer) <-
	.println("Pido una cerveza al robot");
	.send(robot, tell, bring(beer));
	+asked(robot, beer).
+!drinkBeer <- true.

// ## HELPER TRIGGER has

+has(owner, halfemptycan) : hasnot(owner, beer) <-
	-has(owner, halfemptycan);
	+has(owner, can).
+has(owner, halfemptycan) <-
	-has(owner, halfemptycan).

+has(owner, can) : mood(owner, euforico) | mood(owner, crispado) <-
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
+has(owner, can) : mood(owner, amodorrado) | mood(owner, dormido) | mood(owner, despierto) | mood(owner, animado) <-
	.println("Voy a pedirle al robot que venga a por la lata");
	.send(robot, tell, msg("Ven a por la lata")).
+has(owner, can) : mood(owner, despierto) | mood(owner, animado) <- // TODO and remove from previous intention
	.println("Voy a llevar la lata al cubo de basura").

+retrieved(can) : has(owner, can) <-
	.abolish(has(owner, can)).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN wakeUp
// -------------------------------------------------------------------------

+!wakeUp : mood(owner, dormido) <-
	.println("Estoy cansado, voy a dormir una siesta");
	.random(X);
	?limit(min, nap, time, MinNapTime);
	?limit(max, nap, time, MaxNapTime);
	.wait(MinNapTime + (MaxNapTime - MinNapTime)*X);
	!transitionMood.
+!wakeUp <- true.

// ## HELPER PLAN transitionMood

+!transitionMood : mood(owner, CurrentMood) & nextMood(CurrentMood, NextMood) <-
	.println("Voy a estar ", NextMood);
	-+mood(owner, NextMood);
	.send(assistant, achieve, remember(mood(owner, NextMood))).
