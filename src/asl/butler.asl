placement(obstacle, side).
placement(position, top ).

automaton(cleaner, inactive).
automaton(dustman, inactive).
automaton(mover,   inactive).
automaton(shopper, inactive).

limit(min, fridge,   beer,  3 ). //Mínimo de cervezas que debería haber en el frigo, si hay menos se ordenan más
limit(max, dumpster, trash, 5 ).
limit(max, owner,    beer,  10).
limit(min, buy,      beer,  3 ). //Cantidad de cervezas a pedirle al súper (en cada orden)

stored(beer,  fridge,   1).
stored(trash, dumpster, 0).

available(Product, Location) :-
	stored(Product, Location, Qtty) &
	Qtty > 0.

overLimit(Type, Product, Location) :-
	limit(Type, Location, Product, Limit) &
	stored(Product, Location, Qtty) & Qtty >= Limit.

cheapest(Provider, Product, Price) :-
	price(Provider, Product, Price) &
	not (price(Provider2, Product, Price2) & Provider2 \== Provider & Price2 < Price).

consumedSafe(YY,MM,DD, Product, Qtty) :-
	consumed(YY,MM,DD, Product, Qtty) | Qtty = 0.

healthConstraint(Product, Agent, Message) :-
	.date(YY,MM,DD) &
	limit(max, Agent, Product, Limit) & consumed(YY,MM,DD, Product, Consumed) & Consumed >= Limit &
	.concat("The Department of Health does not allow me to give you more than ", Qtty, " beers a day! I am very sorry about that!", Message).

// -------------------------------------------------------------------------
// SERVICE INIT AND HELPER METHODS // TODO: PLACEHOLDER
// -------------------------------------------------------------------------

// Check if bot answer requires a service
service(Answer, translating) :- // Translating service
	checkTag("<translate>",Answer).
service(Answer, addingBot) :-   // Adding a bot property service
	checkTag("<botprop>",Answer).

// Checking a concrete service required by the bot ia as simple as find the required tag
// as a substring on the string given by the second parameter
checkTag(Service,String) :-
	.substring(Service,String).

// Gets into Val the first substring contained by a tag Tag into String
getValTag(Tag,String,Val) :- 
	.substring(Tag,String,Fst) &       // First: find the Fst Posicition of the tag string              
	.length(Tag,N) &                   // Second: calculate the length of the tag string
	.delete(0,Tag,RestTag) &     
	.concat("</",RestTag,EndTag) &     // Third: build the terminal of the tag string
	.substring(EndTag,String,End) &    // Four: find the Fst Position of the terminal tag string
	.substring(String,Val,Fst+N,End).  // Five: get the Val tagged
	
	/*
		Another way to get the value will consist to delete from String the prefix, sufix and tags
		in order to let only the required Val
	*/  

// Filter the answer to be showed when the service indicated as second arg is done
filter(Answer, translating, [To,Msg]):-
	getValTag("<to>",Answer,To) &
	getValTag("<msg>",Answer,Msg).

filter(Answer, addingBot, [ToWrite,Route]):-
	getValTag("<name>",Answer,Name) &
	getValTag("<val>",Answer,Val) &
	.concat(Name,":",Val,ToWrite) &
	bot(Bot) &
	.concat("/bots/",Bot,BotName) &
	.concat(BotName,"/config/properties.txt",Route).

// -------------------------------------------------------------------------
// PRIORITIES AND PLAN INITIALIZATION
// -------------------------------------------------------------------------

!initButler.

+!initButler <-
	!initBot;
	!createDatabase;
	!createAutomaton(cleaner);
	!createAutomaton(dustman);
	!createAutomaton(mover);
	!doHouseWork.
+!doHouseWork <-
	!dialogWithOwner; // TODO
	!manageBeer;
	!cleanHouse;
	!doHouseWork.

// -------------------------------------------------------------------------
// TRIGGERS
// -------------------------------------------------------------------------

+pay(Amount)[source(owner)] <-
	.println("Gracias por la paga de ", Amount, " mi seÃ±or");
	?has(money, Balance);
	.abolish(has(money, _));
	+has(money, Balance + Amount);
	.send(database, achieve, add(money, Amount));
	.abolish(pay(_)).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN initBot // TODO: PLACEHOLDER
// -------------------------------------------------------------------------

+!initBot <-
	makeArtifact("butlerBot","bot.ChatBOT",["butlerBot"],BotId);
	focus(BotId);
	+bot("bot").

// -------------------------------------------------------------------------
// DEFINITION FOR createDatabase
// -------------------------------------------------------------------------

+!createDatabase <-
	.date(YY,MM,DD);
	.list_files("./tmp/","database.asl", L);
	if (.length(L, 0)) {
		.create_agent("database", "database.asl");
	} else {
		.create_agent("database", "./tmp/database.asl"); 
	}
	.send(database, askOne, has(money, X), MoneyResponse);
	.send(database, askOne, consumed(YY,MM,DD, beer, Qtd), ConsumedResponse);
	+MoneyResponse;
	+ConsumedResponse.

+!createAutomaton(Name) <-
	.concat("./src/asl/automaton/", Name, ".asl", Filename);
	.create_agent(Name, Filename, [agentArchClass("jaca.CAgentArch"), agentArchClass("MixedAgentArch")]).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN dialogWithOwner // TODO: PLACEHOLDER
// -------------------------------------------------------------------------

+!dialogWithOwner : msg(Msg)[source(Ag)] & bot(Bot) <-
	chatSincrono(Msg,Answer);
	-msg(Msg)[source(Ag)];
	.println("El agente ",Ag," ha dicho ",Msg);
	!doSomething(Answer,Ag).
+!dialogWithOwner <- true.

+!doSomething(Answer,Ag) : service(Answer, Service) <-
	.println("Aqui debe ir el cÃ³digo del servicio:", Service," para el agente ",Ag).
	
+!doSomething(Answer,Ag) : not service(Answer, Service) <-
	.println("Le contesto al ",Ag," ",Answer);
	.send(Ag,tell,answer(Answer)). //modificar adecuadamente

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN cleanHouse // TODO
// -------------------------------------------------------------------------

+!cleanHouse : requestedRetrieval(can, floor(X, Y)) & not cleaning(_, can, floor(X, Y)) <-
	.println("Owner ha tirado una lata al suelo, activo un autÃ³mata para que limpie");
	+cleaning(cleaner, can, floor(X, Y));
	if (automaton(cleaner, inactive)) {
		?location(depot, _, DepX, DepY); ?location(dumpster, _, DumpX, DumpY); ?bounds(BX, BY);
		.send(cleaner, tell, activate(cleaner, depot(DepX, DepY), dumpster(DumpX, DumpY), bounds(BX, BY)));
		.abolish(automaton(cleaner, inactive));
		+automaton(cleaner, active);
	}
	.findall(obstacle(OX, OY), location(_, obstacle, OX, OY), Obstacles);
	.send(cleaner, tell, clean(can, floor(X, Y), Obstacles)).
+!cleanHouse : requestedRetrieval(can, owner) & not cleaning(_, can, owner) <-
	.println("Owner me ha pedido que vaya a recoger una lata, activo un autÃ³mata para que la recoja");
	+cleaning(cleaner, can, owner);
	if (automaton(cleaner, inactive)) {
		?location(depot, _, DepX, DepY); ?location(dumpster, _, DumpX, DumpY); ?bounds(BX, BY);
		.send(cleaner, tell, activate(cleaner, depot(DepX, DepY), dumpster(DumpX, DumpY), bounds(BX, BY)));
		.abolish(automaton(cleaner, inactive));
		+automaton(cleaner, active);
	}
	.findall(obstacle(OX, OY), location(_, obstacle, OX, OY), Obstacles);
	?location(owner, Type, LX, LY); ?placement(Type, Placement);
	.send(cleaner, tell, clean(can, location(owner, LX, LY, Placement), Obstacles)).
+!cleanHouse : overLimit(max, trash, dumpster) & not takingout(_, trash) <-
	.println("El dumpster estÃ¡ lleno, activo un autÃ³mata para sacar la basura");
	+takingout(dustman, trash);
	if (automaton(dustman, inactive)) {
		?location(depot, DepType, DepX, DepY); ?placement(DepType, DepPlacement);
		?location(dumpster, DumpType, DumpX, DumpY); ?placement(DumpType, DumpPlacement);
		?location(exit, EType, EX, EY); ?placement(EType, EPlacement);
		?bounds(BX, BY);
		.send(dustman, tell, activate(dustman, depot(DepX, DepY, DepPlacement), dumpster(DumpX, DumpY, DumpPlacement), exit(EX, EY, EPlacement), bounds(BX, BY)));
		.abolish(automaton(dustman, inactive));
		+automaton(dustman, active);
	}
	.findall(obstacle(OX, OY), location(_, obstacle, OX, OY), Obstacles);
	.send(dustman, tell, takeout(trash, Obstacles)).
+!cleanHouse <- true. // Execute randomly
	// TODO; not yet implemented

// ## HELPER TRIGGER cleaned

+cleaned(success, Object, Position)[source(Cleaner)] <-
	.println("Cleaning success");
	?stored(trash, dumpster, Qtty); .abolish(stored(trash, dumpster, Qtty)); +stored(trash, dumpster, Qtty+1);
	.abolish(requestedRetrieval(Object, Position));
	.abolish(cleaning(Cleaner, Object, Position));
	.abolish(cleaned(success, Object, Position)).

// ## HELPER TRIGGER [finished] cleaning(cleaner, can, _)

-cleaning(cleaner, can, _) : not requestedRetrieval(can, _) & not cleaning(cleaner, can, _) & automaton(cleaner, active) <-
	.send(cleaner, tell, deactivate(cleaner));
	.abolish(automaton(cleaner, active));
	+automaton(cleaner, inactive).

// ## HELPER TRIGGER tookout(trash)

+tookout(success, trash)[source(Dustman)] <-
	.println("Takeout success");
	.abolish(stored(trash, dumpster, Qtty)); +stored(trash, dumpster, 0);
	.abolish(takingout(Dustman, trash));
	.abolish(tookout(success, trash)).

// ## HELPER TRIGGER [finished] takingout(dustman, trash)

-takingout(dustman, trash) : not overLimit(max, trash, dumpster) & not takingout(dustman, trash) & automaton(dustman, active) <-
	.send(dustman, tell, deactivate(dustman));
	.abolish(automaton(dustman, active));
	+automaton(dustman, inactive).

// ## HELPER TRIGGER can

+can(PX, PY) <-
	+requestedRetrieval(can, floor(PX, PY));
	.abolish(can(PX, PY)).

+msg("Ven a por la lata") <-
	+requestedRetrieval(can, owner);
	.abolish(msg("Ven a por la lata")).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN manageBeer
// -------------------------------------------------------------------------

+!manageBeer : asked(Ag, beer) & available(beer, fridge) & not moving(_, beer, 1, fridge, Ag) & not healthConstraint(beer, Ag, _) <-
	.println(Ag, " me ha pedido un ", "beer", ", activo un autÃ³mata para que se lo lleve");
	+moving(mover, beer, 1, fridge, Ag);
	if (automaton(mover, inactive)) {
		?location(depot, _, DepX, DepY); ?bounds(BX, BY);
		.send(mover, tell, activate(mover, depot(DepX, DepY), bounds(BX, BY)));
		.abolish(automaton(mover, inactive));
		+automaton(mover, active);
	}
	.findall(obstacle(X, Y), location(_, obstacle, X, Y), Obstacles);
	?location(Ag, DType, DX, DY); ?placement(DType, DPlacement);
	?location(fridge, OType, OX, OY); ?placement(OType, OPlacement);
	.send(mover, tell, move(beer, 1, location(fridge, OX, OY, OPlacement), location(Ag, DX, DY, DPlacement), Obstacles)).
+!manageBeer : requestedPickUp(beer, Qtty, delivery) & not moving(_, beer, Qtty, delivery, fridge) <-
	.println("Voy a recoger las cervezas que me han entregado");
	+moving(mover, beer, Qtty, delivery, fridge);
	if (automaton(mover, inactive)) {
		?location(depot, _, DepX, DepY); ?bounds(BX, BY);
		.send(mover, tell, activate(mover, depot(DepX, DepY), bounds(BX, BY)));
		.abolish(automaton(mover, inactive));
		+automaton(mover, active);
	}
	.findall(obstacle(X, Y), location(_, obstacle, X, Y), Obstacles);
	?location(delivery, OType, OX, OY); ?placement(OType, OPlacement);
	?location(fridge, DType, DX, DY); ?placement(DType, DPlacement);
	.send(mover, tell, move(beer, Qtty, location(delivery, OX, OY, OPlacement), location(fridge, DX, DY, DPlacement), Obstacles)).
+!manageBeer : not overLimit(min, beer, fridge) & not ordered(beer) & cheapest(Provider, beer, Price) <-
	.println("Tengo menos cerveza de la que deberÃ­a, voy a comprar mÃ¡s");
	.println("Cheapest is ", Provider, " @", Price);
	?limit(min, buy, beer, BatchSize);
	.send(Provider, tell, order(beer, BatchSize));
	+ordered(beer).
+!manageBeer : asked(Ag, beer) & healthConstraint(beer, Ag, Msg) <-
	.println(Ag, " no puede beber mÃ¡s ", "beer");
	.send(Ag, tell, msg(Msg));
	.date(YY,MM,DD);
	.send(Ag, tell, healthConstraint(beer,YY,MM,DD));
	-asked(Ag, beer).
+!manageBeer <- true.

// ## HELPER TRIGGER moved

+moved(success, Product, Qtty, Origin, Destination)[source(Mover)] <-
	.println("Movement success: ", Origin, "->", Destination);
	if (Destination == owner) {
		.date(YY,MM,DD);
		?consumedSafe(YY,MM,DD, Product, ConsumedQtty);
		.abolish(consumed(YY,MM,DD, Product, _));
		+consumed(YY,MM,DD, Product, ConsumedQtty+1);
		.send(database, achieve, add(consumed(YY,MM,DD, Product, ConsumedQtty+1)));
		-asked(Destination, Product);
	}
	if (Origin == delivery) {
		.println("Delivery deposit success");
		.abolish(requestedPickUp(Product, Qtty, Origin));
		-ordered(Product);
	}
	.abolish(moving(Mover, Product, Qtty, Origin, Destination));
	.abolish(moved(success, Product, Qtty, Origin, Destination)[source(Mover)]).
+moved(failure, Product, Qtty, Origin, Destination)[source(Mover)] <-
	.println("Movement failure");
	if (Destination == owner) {
		.send(Destination, tell, msg("No me queda, voy a comprar mÃ¡s"));
	}
	.abolish(moving(Mover, Product, Qtty, Origin, Destination));
	.abolish(moved(failure, Product, Qtty, Origin, Destination)[source(Mover)]).

// ## HELPER TRIGGER [finished] takingout(dustman, trash)

-moving(mover, beer, _, _, _) : not asked(_, beer) & not requestedPickUp(beer, _, _) & not moving(mover, beer, _, _, _) & automaton(mover, active) <-
	.send(mover, tell, deactivate(mover));
	.abolish(automaton(mover, active));
	+automaton(mover, inactive).

// ## HELPER TRIGGER bring

+bring(Product)[source(Ag)] <- // TODO AIML
	+asked(Ag, Product);
	.abolish(bring(Product)[source(Ag)]).

// ## HELPER THIGGER price

+price(beer, NewPrice)[source(Provider)] :
	(not price(Provider, beer, OldPrice)) | (NewPrice \== OldPrice)
<-
	.println("Entendido, ", Provider, " ahora me vendes una beer a ", NewPrice);
	.abolish(price(Provider, beer, _));
	+price(Provider, beer, NewPrice);
	.abolish(price(beer, _)[source(Provider)]).

// ## HELPER TRIGGER delivered

+delivered(OrderId, Product, Qtty, TotalPrice)[source(Provider)] <-
	.println("Recibido pedido de ", Qtty, " ", Product);
	if (has(money, Balance) & Balance < TotalPrice) {
		.println("No tengo dinero, le pido a owner");
		.abolish(cannotpay(_));
		.send(owner, tell, pay(butler, TotalPrice-Balance));
		!waitMoneyForDelivery(OrderId, Provider, Product, Qtty, TotalPrice);
	} else {
		!receiveDelivery(OrderId, Provider, Product, Qtty, TotalPrice);
	}.

// ### HELPER PLAN waitMoneyForDelivery

+!waitMoneyForDelivery(OrderId, Provider, Product, Qtty, TotalPrice) :
	cannotpay(_)
<-
	.println("Recibido pedido de ", Qtty, " ", Product, " (sin dinero)");
	.send(Provider, tell, reject(OrderId));
	-ordered(beer).
+!waitMoneyForDelivery(OrderId, Provider, Product, Qtty, TotalPrice) :
	has(money, Balance) & Balance >= TotalPrice
<-
  .println("Recibido pedido de ", Qtty, " ", Product);
	!receiveDelivery(OrderId, Provider, Product, Qtty, TotalPrice).
+!waitMoneyForDelivery(OrderId, Provider, Product, Qtty, TotalPrice) :
	has(money, Balance) & Balance < TotalPrice
<-
	.wait(500);
	!waitMoneyForDelivery(OrderId, Provider, Product, Qtty, TotalPrice).

// ### HELPER PLAN receiveDelivery

+!receiveDelivery(OrderId, Provider, Product, Qtty, TotalPrice) <-
	+requestedPickUp(Product, Qtty, delivery);
	.send(Provider, tell, received(OrderId));
	.send(Provider, tell, pay(TotalPrice));
	.send(database, achieve, del(money, TotalPrice));
	?has(money, Amount);
	+has(money, Amount-TotalPrice);
	.abolish(has(money, Amount)).

// ### HELPER TRIGGER notEnough

+notEnough(OrderId, Product, Qtty)[source(Provider)] <-
	.abolish(price(Provider, Product, _));
	.wait(5000);
	-ordered(beer);
	.abolish(notEnough(OrderId, Product, Qtty)[source(Provider)]).

// ## HELPER TRIGGER stock

+stock(Object, LocationDescriptor, Qtty) <-
	.abolish(stock(Object, LocationDescriptor, _));
	.abolish(stored(Object, LocationDescriptor, _)); +stored(Object, LocationDescriptor, Qtty).

// -------------------------------------------------------------------------
// DEFINITION FOR PLANS goAtX
// -------------------------------------------------------------------------

+!goAtPlace(butler, Place) : at(butler, Place) <- true.
+!goAtPlace(butler, Place) :
	not at(butler, Place) &
	at(butler, OX, OY) & location(Place, Type, DX, DY) & placement(Type, Placement) & bounds(BX, BY)
<-
	.println("Going towards ", Place);
	.findall(obstacle(X, Y), location(_, obstacle, X, Y), Obstacles);
	movement.getDirection(origin(OX, OY), destination(DX, DY, Placement), bounds(BX, BY), Obstacles, Direction);
	move_towards(butler, Direction);
	!goAtPlace(butler, Place).
+!goAtPlace(butler, Place) <-
	.wait(100);
	!goAtPlace(butler, Place).

+!goAtLocation(butler, location(DX, DY)) : at(butler, DX, DY) <- true.
+!goAtLocation(butler, location(DX, DY)) : 
	not at(butler, DX, DY) &
	at(butler, OX, OY) & bounds(BX, BY)
<-
	.println("Going towards can");
	.findall(obstacle(X, Y), location(_, obstacle, X, Y), Obstacles);
	movement.getDirection(origin(OX, OY), destination(DX, DY, top), bounds(BX, BY), Obstacles, Direction);
	move_towards(butler, Direction);
	!goAtLocation(butler, location(DX, DY)).
+!goAtLocation(butler, location(DX, DY)) <-
	.wait(100);
	!goAtLocation(butler, location(DX, DY)).
