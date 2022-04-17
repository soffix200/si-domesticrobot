limit(max, talk,   waitTime,         4000).
limit(min, talk,   waitTime,         1000).
limit(min, nap,    time,           120000).
limit(max, nap,    time,           720000).
limit(max, mood,   sipMoodCount,        6).
limit(max, butler, dailyPayment,      50).
limit(max, owner,  monthlyPension,   2000).
limit(max, owner,  cleanChance,        10).

nextMood(Current, Next) :- Current == despierto  & Next = animado.
nextMood(Current, Next) :- Current == animado    & Next = euforico.
nextMood(Current, Next) :- Current == euforico   & Next = crispado.
nextMood(Current, Next) :- Current == crispado   & Next = amodorrado.
nextMood(Current, Next) :- Current == amodorrado & Next = dormido.
nextMood(Current, Next) :- Current == dormido    & Next = despierto.

conversation(time , despierto , "Hola butler, que hora es?").
conversation(time , animado   , "Hola butler, que hora tenemos por aqui?").
conversation(time , euforico  , "Ei dime que hora es colega").
conversation(time , crispado  , "Dime que hora es para poder irme ya a dormir").
conversation(time , amodorrado, "Que hora tenemos amigo mio?").

conversation(money, despierto , "Hola butler, podrias decirme cuanto dinero te queda del que te he dado?").
conversation(money, animado   , "Hola butler, cuanto dinero te sobra").
conversation(money, euforico  , "Cuanto dinero te queda ya? Dime que no te lo has gastado todo").
conversation(money, crispado  , "Butler, dime cuanto dinero te queda sin contar al que le has prendido fuego").
conversation(money, amodorrado, "Butler, dime cuanto dinero te queda por gastar").

conversation(chat , despierto , "A veces estoy un poco aburrido, pero agradezco mucho tu compania").
conversation(chat , animado   , "Deberias tomarte una cerveza tu tambien conmigo").
conversation(chat , euforico  , "Que bien me lo pago contigo!! Eres el mejor amigo que se puede tener").
conversation(chat , crispado  , "Robot, a veces no te da la sensacion de que vivimos en una realidad deformada por los canones establecidos y el capitalismo?").
conversation(chat , amodorrado, "Siempre he tenido la misma duda, ¿Tu no duermes nunca?").

conversation(time , response, despierto , "Muchas gracias").
conversation(time , response, animado   , "Gracias!!").
conversation(time , response, euforico  , "Que dices para eso ya ni duermo").
conversation(time , response, crispado  , "Todavia? Menuda basura").
conversation(time , response, amodorrado, "Creo que me tocara meterme en el sobre en breves").

conversation(money, response, despierto , "Muchas gracias, tu siempre tan servicial").
conversation(money, response, animado   , "Uf este mes va a ser complicado").
conversation(money, response, euforico  , "Mucho me parece, bebamos otra, ah perdon que tu no bebes").
conversation(money, response, crispado  , "Dios mio, siempre igual, no voy a volver a beber").
conversation(money, response, amodorrado, "A estas alturas ya todo me da igual, te daba el doble por irme ya a mi cama").

healthConstraint(Product) :-
	.date(YY,MM,DD) &
	healthConstraint(Product, YY,MM,DD).

// -------------------------------------------------------------------------
// SERVICE INIT AND HELPER METHODS
// -------------------------------------------------------------------------

service(Query, bring) :-
	checkTag("<bring>", Query).
service(Query, pay) :-
	checkTag("<pay>", Query).
service(Query, health) :-
	checkTag("<health>", Query).
service(Query, conversation) :-
	checkTag("<conversation>", Query).

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
filter(Query, health, [Beer]) :-
	tagValue("<beer>", Query, Beer).
filter(Query, conversation, [Topic]) :-
	tagValue("<topic>", Query, Topic).

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
	//!setupTool("Owner", "Butler"); //Uncomment to activate GUI
	!createAssistant;
	?bounds(BX, BY); +bounds(BX, BY);
	?location(owner, O, X, Y); +location(owner, O, X, Y); +at(owner, X, Y);
	?location(fridge, FO, FX, FY); +location(fridge, FO, FX, FY);
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
	.println("<- [", Ag, "]: ", Msg);
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

// # HEALTH SERVICE
+!doService(Query, Ag) : service(Query, health) & filter(Query, health, [Beer]) & Beer == tooMuch <-
	.println(Ag, " me ha dicho que he bebido demasiado por hoy");
	.date(YY,MM,DD);
	+healthConstraint(beer, YY,MM,DD).

// # CONVERSATION SERVICE
+!doService(Query, Ag) : service(Query, conversation) & filter(Query, conversation, [Topic]) <-
	?conversation(Topic, response, Mood, Msg);
	.println("-> [", Ag, "] ", Msg);
	.send(butler, tell, msg(Msg)).

// # COMMUNICATION SERVICE
+!doService(Answer, Ag) : not service(Answer, Service) & Answer \== "I have no answer for that." <-
	.println("-> [", Ag, "] ", Answer);
	.send(Ag, tell, answer(Answer)).
+!doService(Answer, Ag) : not service(Answer, Service) & Answer == "I have no answer for that." <-
	true.

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

+!talkButler : ownerInit & mood(owner, Mood) & Mood \== dormido <-
	.random([time, money, chat], Topic);
	?conversation(Topic, Mood, Msg);
	.send(butler, tell, msg(Msg));
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
+!drinkBeer : mood(owner, despierto) & hasnot(owner, beer) & not asked(butler, beer) <-
	.println("> Voy a por la cerveza");
	.println("Desplazandose a fridge");
	?location(fridge, _, FX, FY);
	!goAtLocation(FX, FY, side);
	.println("Cogiendo ", beer);
	open(fridge);
	.wait(200);
	?stock(beer, fridge, StoredQtty);
	if (StoredQtty > 0) {
		get(beer, fridge);
		hand_in(beer);
		close(fridge);
	} else {
		close(fridge);
		.println("> No quedan cervezas, pido una cerveza al butler");
		.send(butler, tell, msg("Traeme una cerveza"));
		+asked(butler, beer);
	}
	.println("Desplazandose al sofa");
	?location(owner, _, X, Y);
	!goAtLocation(X, Y, top).
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
+has(owner, can) : mood(owner, amodorrado) | mood(owner, dormido) <-
	.println("> Pido a butler que venga a por la lata");
	.send(butler, tell, msg("Ven a por la lata")).
+has(owner, can) : mood(owner, despierto) | mood(owner, animado) <-
	.println("> Llevo la lata al cubo de basura");
	get(can);
	.println("Desplazandose a dumpster");
	?location(dumpster, _, DumpX, DumpY);
	!goAtLocation(DumpX, DumpY, side);
	.println("Tirando ", can);
	recycle(can);
	.println("Desplazandose al sofa");
	?location(owner, _, X, Y);
	!goAtLocation(X, Y, top).

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

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN goAtLocation
// -------------------------------------------------------------------------

+!goAtLocation(DX, DY, Placement) :
	at(owner, DX, DY) |
	(Placement == side & (at(owner, DX, DY+1) | at(owner, DX, DY-1) | at(owner, DX+1, DY) | at(owner(DX-1, DY))))
<-
	true.
+!goAtLocation(DX, DY, Placement) :
	not at(owner, DX, DY) &
	not (Placement == side & (at(owner, DX, DY+1) | at(owner, DX, DY-1) | at(owner, DX+1, DY) | at(owner(DX-1, DY))))
<-
	?at(owner, OX, OY); ?bounds(BX, BY);
	.findall(obstacle(OX, OY), location(_, obstacle, OX, OY), Obstacles);
	movement.getDirection(origin(OX, OY), destination(DX, DY, Placement), bounds(BX, BY), Obstacles, Direction);
	move_towards(owner, Direction);
	!updateLocationBelief(Direction);
	!goAtLocation(DX, DY, Placement).

// ## HELPER PLAN updateLocationBelief

+!updateLocationBelief(Direction) : Direction == right <-
	?at(owner, X, Y);
	-+at(owner, X+1, Y).
+!updateLocationBelief(Direction) : Direction == left <-
	?at(owner, X, Y);
	-+at(owner, X-1, Y).
+!updateLocationBelief(Direction) : Direction == down <-
	?at(owner, X, Y);
	-+at(owner, X, Y+1).
+!updateLocationBelief(Direction) : Direction == up <-
	?at(owner, X, Y);
	-+at(owner, X, Y-1).
