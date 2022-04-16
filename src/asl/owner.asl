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

// -------------------------------------------------------------------------
// SERVICE INIT AND HELPER METHODS
// -------------------------------------------------------------------------

service(Query, bring) :-
	checkTag("<bring>", Query).
service(Query, pay) :-
	checkTag("<pay>", Query).

checkTag(Tag, String) :-
	.substring(Tag, String).

tagValue(Tag, Query, Literal) :-
	.substring(Tag, Query, Fst) &
	.length(Tag, N) &
	.delete(0, Tag, RestTag) &
	.concat("</", RestTag, EndTag) &
	.substring(EndTag, Query, End) &
	.substring(Query, Parse, Fst+N, End) &
	.term2string(Literal, Parse).

filter(Query, bring, [Status]) :-
	tagValue("<status>", Query, Status).
filter(Query, pay, [Amount]) :-
	tagValue("<amount>", Query, Amount).

// -------------------------------------------------------------------------
// PRIORITIES AND PLAN INITIALIZATION
// -------------------------------------------------------------------------

!initOwner.
!dialog.
!talkButler.
!expectPension.
!cheerUp.

+!initOwner <-
	!initBot;
	!setupTool("Owner", "Butler");
	!createAssistant;
	+ownerInit.

+!cheerUp : ownerInit <-
	!cleanHouse; // TODO
	!drinkBeer;
	!wakeUp;
	!cheerUp.
+!cheerUp <- !cheerUp.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN initBot
// -------------------------------------------------------------------------

+!initBot <-
	makeArtifact("ownerBot", "bot.ChatBOT", ["ownerBot"], BotId);
	focus(BotId).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN setupTool
// -------------------------------------------------------------------------

+!setupTool(Master, Butler) <-
	makeArtifact("GUI","gui.Console",[],GUI);
	setBotMasterName(Master);
	setBotName(Butler);
	focus(GUI). 

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN createAssistant
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
	.send(assistant, askOne, sipMoodCount(owner, Count), SipMoodCountResponse); -+SipMoodCountResponse.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN dialog
// -------------------------------------------------------------------------

+!dialog : ownerInit & msg(Msg)[source(Ag)] <-
	.abolish(msg(Msg)[source(Ag)]);
	chatSincrono(Msg, Answer);
	!doService(Answer, Ag);
	!dialog.
+!dialog <- !dialog.

// -------------------------------------------------------------------------
// DEFINITION FOR ACTION SERVICES
// -------------------------------------------------------------------------

// # BRING SERVICE
+!doService(Query, Ag) : service(Query, bring) & filter(Query, bring, [notAvailable]) <-
	.println(Ag, " me ha dicho que no le quedan cervezas").

// # PAY SERVICE
+!doService(Query, Ag) : service(Query, pay) & filter(Query, pay, [Amount]) <-
	.println(Ag, " me ha pedido que le ceda ", Amount);
	!pay(Ag, Amount).

// ## HELPER PLAN pay(Ag, Amount)

+!pay(butler, Amount) : has(money, Balance) & Balance >= Amount <-
	.date(YY,MM,DD);
	?limit(max, butler, dailyPayment, Limit);
	if (paid(YY,MM,DD, AmountPaid)) {
		if (AmountPaid + Amount <= Limit) {
			.println("> Le pago a ", butler, " los ", Amount, " que me ha pedido");
			-+paid(YY,MM,DD, AmountPaid+Amount);
			.abolish(has(money, Balance)); +has(money, Balance-Amount);
			.concat("Ten los ", Amount, " que me pediste", Msg);
			.send(butler, tell, msg(Msg));
			.send(assistant, achieve, remember(paid(YY,MM,DD, AmountPaid+Amount)));
			.send(assistant, achieve, remember(has(money, Balance-Amount)));
		} else {
			.println("[!] No puedo gastar mas en cervezas hoy o me deshauciaran");
			.concat("No puedo pagarte ", Amount, Msg);
			.send(butler, tell, msg(Msg));
		}
	} else {
		if (Amount < Limit){
			.println("> Le pago a ", butler, " los ", Amount, " que me ha pedido");
			-+paid(YY,MM,DD, Amount);
			.abolish(has(money, Balance)); +has(money, Balance-Amount);
			.concat("Ten los ", Amount, " que me pediste", Msg);
			.send(butler, tell, msg(Msg));
			.send(assistant, achieve, remember(paid(YY,MM,DD, Amount)));
			.send(assistant, achieve, remember(has(money, Balance-Amount)));
		} else {
			.println("[!] No puedo gastar una cantidad mayor a mi presupuesto diario");
			.concat("No puedo pagarte ", Amount, Msg);
			.send(butler, tell, msg(Msg));
		}
	}.
+!pay(butler, Amount) : has(money, Balance) & Balance < Amount<-
	.println("[!] No tengo dinero");
	.concat("No puedo pagarte ", Amount, Msg);
	.send(butler, tell, msg(Msg)).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN talkButler
// -------------------------------------------------------------------------

+!talkButler : ownerInit & not mood(owner, dormido) <- // TODO different messages for each mood
	.send(butler, tell, msg("Test message")); // TODO IMPLEMENT AIML
	.random(X);
	?limit(min, talk, waitTime, MinWaitTime);
	?limit(max, talk, waitTime, MaxWaitTime);
	.wait(MinWaitTime + (MaxWaitTime - MinWaitTime)*X);
	!talkButler.
+!talkButler <- !talkButler.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN expectPension
// -------------------------------------------------------------------------

+!expectPension : ownerInit & .date(YY,MM,1) & not lastPension(YY,MM) <-
	.println("[E] Me ha llegado una pension de ", Amount);
	?has(money, Balance);
	?limit(max, owner, monthlyPension, Amount);
	-+lastPension(YY,MM);
	.abolish(has(money, Balance)); +has(money, Balance+Amount);
	.send(assistant, achieve, remember(lastPension(YY,MM)));
	.send(assistant, achieve, remember(has(money, Balance+Amount)));
	.wait(3600000);
	!expectPension.
+!expectPension : ownerInit <-
	.wait(3600000);
	!expectPension.
+!expectPension <- !expectPension.

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
	.println("[!] He bebido demasiado");
	.wait(10000);
	-asked(butler, beer).
+!drinkBeer : not mood(owner, dormido) & has(owner, beer) & asked(butler, beer) <-
	.println("> Empiezo a beber cerveza");
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
	.println("> Bebo un sorbo de cerveza");
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
	.println("[!] Sigo esperando mi cerveza");
	.wait(1000).
+!drinkBeer : not mood(owner, dormido) & hasnot(owner, beer) & not asked(butler, beer) <-
	.println("> Pido una cerveza al butler");
	.send(butler, tell, msg("Traeme una cerveza"));
	+asked(butler, beer).
+!drinkBeer <- true.

// ## HELPER TRIGGER has

+has(owner, halfemptycan) : hasnot(owner, beer) <-
	-has(owner, halfemptycan);
	+has(owner, can).
+has(owner, halfemptycan) <-
	-has(owner, halfemptycan).

+has(owner, can) : mood(owner, euforico) | mood(owner, crispado) <-
	.println("> Tiro una lata");
	?bounds(BX, BY);
	.random(X); .random(Y);
	basemath.floor(X*BX, PX); basemath.floor(Y*BY, PY);
	while (location(_, obstacle, PX, PY)) {
		.random(X); .random(Y);
		basemath.floor(X*BX, PX); basemath.floor(Y*BY, PY);
	}
	throw(can, position(PX, PY));
	-has(owner, can);
	.concat("He tirado una lata a ", PX, " ", PY, Msg);
	.send(butler, tell, msg(Msg)).
+has(owner, can) : mood(owner, amodorrado) | mood(owner, dormido) | mood(owner, despierto) | mood(owner, animado) <-
	.println("> Pido a butler que venga a por la lata");
	.send(butler, tell, msg("Ven a por la lata")).
+has(owner, can) : mood(owner, despierto) | mood(owner, animado) <- // TODO and remove from previous intention
	.println("> Llevo la lata al cubo de basura").

+retrieved(can) : has(owner, can) <-
	.abolish(has(owner, can)).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN wakeUp
// -------------------------------------------------------------------------

+!wakeUp : mood(owner, dormido) <-
	.println("> Estoy cansado, voy a dormir una siesta");
	.random(X);
	?limit(min, nap, time, MinNapTime);
	?limit(max, nap, time, MaxNapTime);
	.wait(MinNapTime + (MaxNapTime - MinNapTime)*X);
	!transitionMood.
+!wakeUp <- true.

// ## HELPER PLAN transitionMood

+!transitionMood : mood(owner, CurrentMood) & nextMood(CurrentMood, NextMood) <-
	.println("> Voy a estar ", NextMood);
	-+mood(owner, NextMood);
	.send(assistant, achieve, remember(mood(owner, NextMood))).
