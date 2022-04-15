limit(max, talk,  waitTime,       10000 ).
limit(min, talk,  waitTime,       2000  ).
limit(min, nap,   time,           120000).
limit(max, nap,   time,           720000).
limit(max, mood,  sipMoodCount,   6     ).
limit(max, butler, dailyPayment,   50    ).
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

!setupTool("Owner", "Butler"). // THIS MAY CRASH

!initOwner.
!talkButler.
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

+pay(butler, Amount) : has(money, Balance) & Balance >= Amount <-
	.date(YY,MM,DD);
	?limit(max, butler, dailyPayment, Limit);
	if (paid(YY,MM,DD, AmountPaid)) {
		if (AmountPaid + Amount <= Limit) {
			.println("Tengo dinero, ahora le pago a butler los ", Amount, " que me ha pedido");
			-+paid(YY,MM,DD, AmountPaid+Amount);
			.abolish(has(money, Balance)); +has(money, Balance-Amount);
			.send(butler, tell, msg("Ten los ", Amount, " que me has pedido."));
			.send(butler, tell, pay(Amount)); // TODO AIML
			.send(assistant, achieve, remember(paid(YY,MM,DD, AmountPaid+Amount)));
			.send(assistant, achieve, remember(has(money, Balance-Amount)));
		} else {
			.println("No puedo gastar más en cervezas hoy o me desahuciarán");
			.send(butler, tell, cannotpay(Amount));
		}
	} else {
		if (Amount < Limit){
			.println("Tengo dinero, ahora le pago a butler los ", Amount, " que me ha pedido");
			-+paid(YY,MM,DD, Amount);
			.abolish(has(money, Balance)); +has(money, Balance-Amount);
			.send(butler, tell, msg("Ten los ", Amount, " que me has pedido."));
			.send(butler, tell, pay(Amount)); // TODO AIML
			.send(assistant, achieve, remember(paid(YY,MM,DD, Amount)));
			.send(assistant, achieve, remember(has(money, Balance-Amount)));
		} else {
			.println("Esa cantidad est� por encima de mi presupuesto diario!");
			.send(butler, tell, cannotpay(Amount));
		}
	}
	.abolish(pay(butler, Amount)).
+pay(butler, Amount) : has(money, Balance) & Balance < Amount<-
	.println("No me queda dinero, a ver si la pensi�n llega pronto");
	.send(butler, tell, cannotpay(Amount));
	.abolish(pay(butler, Amount)).

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
	.send(assistant, askOne, mood(owner, Mood), mood(owner, Mood)); -+mood(owner, Mood);
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

+!setupTool(Master, Butler) <-
	makeArtifact("GUI","gui.Console",[],GUI);
	setBotMasterName(Master);
	setBotName(Butler);
	focus(GUI). 

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN talkButler
// -------------------------------------------------------------------------

+!talkButler : not mood(owner, dormido) <- // TODO different messages for each mood
	.send(butler, tell, msg("Test message")); // TODO IMPLEMENT AIML
	.random(X);
	?limit(min, talk, waitTime, MinWaitTime);
	?limit(max, talk, waitTime, MaxWaitTime);
	.wait(MinWaitTime + (MaxWaitTime - MinWaitTime)*X);
	!talkButler.
+!talkButler <- !talkButler.

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
	-asked(butler, beer).
+!drinkBeer : not mood(owner, dormido) & has(owner, beer) & asked(butler, beer) <-
	.println("Voy a empezar a beber cerveza.");
	-asked(butler, beer);
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
+!drinkBeer : not mood(owner, dormido) & has(owner, beer) & not asked(butler, beer) <-
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
+!drinkBeer : not mood(owner, dormido) & hasnot(owner, beer) & asked(butler, beer) <-
	.println("Sigo esperando mi cerveza");
	.wait(1000).
+!drinkBeer : not mood(owner, dormido) & hasnot(owner, beer) & not asked(butler, beer) <-
	.println("Pido una cerveza al butler");
	.send(butler, tell, bring(beer));
	+asked(butler, beer).
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
	.send(butler, tell, msg("He tirado una lata"));
	.send(butler, tell, can(PX, PY)). // TODO AIML
+has(owner, can) : mood(owner, amodorrado) | mood(owner, dormido) | mood(owner, despierto) | mood(owner, animado) <-
	.println("Voy a pedirle al butler que venga a por la lata");
	.send(butler, tell, msg("Ven a por la lata")).
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
