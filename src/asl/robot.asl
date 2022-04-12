placement(obstacle, side).
placement(position, top ).

automaton(cleaner, inactive).
automaton(dustman, inactive).
automaton(mover,   inactive).
automaton(shopper, inactive).

stored(beer, fridge, 1).
trashed(can, 0).
threshold(beer, 5).
threshold(trash, 3).
buyBatch(beer, 3).

available(Product, Location) :-
	stored(Product, Location, Qtty) &
	Qtty > 0.

overThreshold(Product, Location) :-
	threshold(Product, Threshold) &
	stored(Product, Location, Qtty) & Qtty > Threshold.

full(dumpster) :-
	threshold(trash, Qtty) &
	trashed(can, Count) & Count >= Qtty.

cheapest(Provider, Product, Price) :-
	price(Provider, Product, Price) &
	not (price(Provider2, Product, Price2) & Provider2 \== Provider & Price2 < Price).

limit(beer, owner, 5, "The Department of Health does not allow me to give you more than 10 beers a day! I am very sorry about that!").

healthConstraint(Product, Agent, Message) :-
	limit(Product, Agent, Limit, Message) &
	.date(YY,MM,DD) &
	.count(consumed(YY,MM,DD,_,_,_,beer), Consumed) &
	qtdConsumed(YY,MM,DD,beer,Qtd)&
	Consumed+Qtd > Limit.

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

!initBot.
!createDatabase.

!dialogWithOwner. // TODO
!doHouseWork.

+!doHouseWork <-
	!manageBeer;
	!cleanHouse;
	!doHouseWork.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN initBot // TODO: PLACEHOLDER
// -------------------------------------------------------------------------

+!initBot <-
	makeArtifact("BOT","bot.ChatBOT",["bot"],BOT);
	focus(BOT);
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
	.date(YY,MM,DD);
	.send(database, askOne, qtdConsumed(YY,MM,DD,beer,Qtd), ConsumedResponse);
	+MoneyResponse;
	+ConsumedResponse.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN askForMoney(owner)
// -------------------------------------------------------------------------

+!askForMoney(owner) <-
	.println("Necesito dinero mi señor");
	.send(owner,achieve,pay(robot)). //TODO send in AIML

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN receive(money)
// -------------------------------------------------------------------------

+!receive(money) : pay(money, Qtd)[source(owner)] <-
	.println("Gracias por la paga de ", Qtd, " mi señor");
	?has(money, TotalMoney);
	+has(money, TotalMoney + Qtd);
	.abolish(has(money, TotalMoney));
	.send(database, achieve, add(money, Qtd));
	.abolish(pay(money, Qtd)).
+!receive(money) : not pay(money, Qtd)[source(owner)] <-
	.println("Estoy esperando a que Owner me pague");
	.wait(1000);
	!receive(money). //TODO consider delete this line if "extravío" is a possibility.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN dialogWithOwner // TODO: PLACEHOLDER
// -------------------------------------------------------------------------

+!dialogWithOwner : msg(Msg)[source(Ag)] & bot(Bot) <-
	chatSincrono(Msg,Answer);
	//chat(Msg) // De manera asíncrona devuelve una signal => answer(Answer)
	-msg(Msg)[source(Ag)];   
	.println("El agente ",Ag," ha dicho ",Msg);
	!doSomething(Answer,Ag);
	//.send(Ag,tell,answer(Answer)); //modificar adecuadamente
	!dialogWithOwner.
+!dialogWithOwner <- !dialogWithOwner.

+!doSomething(Answer,Ag) : service(Answer, Service) <-
	.println("Aqui debe ir el código del servicio:", Service," para el agente ",Ag).
	
+!doSomething(Answer,Ag) : not service(Answer, Service) <-
	.println("Le contesto al ",Ag," ",Answer);
	.send(Ag,tell,answer(Answer)). //modificar adecuadamente

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN cleanHouse // TODO
// -------------------------------------------------------------------------

+!cleanHouse : requestedRetrieval(can, floor(X, Y)) & not cleaning(_, can, floor(X, Y)) <-
	.println("Owner ha tirado una lata al suelo, activo un autómata para que limpie");
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
	.println("Owner me ha pedido que vaya a recoger una lata, activo un autómata para que la recoja");
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
+!cleanHouse : full(dumpster) & not takingout(_, trash) <-
	.println("El dumpster está lleno, activo un autómata para sacar la basura");
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
	?trashed(can, Qtty); -+trashed(can, Qtty+1);
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
	-+trashed(can, 0);
	.abolish(takingout(Dustman, trash));
	.abolish(tookout(success, trash)).

// ## HELPER TRIGGER [finished] takingout(dustman, trash)

-takingout(dustman, trash) : not full(dumpster) & not takingout(dustman, trash) & automaton(dustman, active) <-
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

+!manageBeer : asked(Ag, beer) & available(beer, fridge) & not moving(_, beer, fridge, Ag) & not healthConstraint(beer, Ag, _) <-
	.println(Ag, " me ha pedido un ", "beer", ", activo un autómata para que se lo lleve");
	+moving(mover, beer, fridge, Ag);
	if (automaton(mover, inactive)) {
		?location(depot, _, DepX, DepY); ?bounds(BX, BY);
		.send(mover, tell, activate(mover, depot(DepX, DepY), bounds(BX, BY)));
		.abolish(automaton(mover, inactive));
		+automaton(mover, active);
	}
	.findall(obstacle(X, Y), location(_, obstacle, X, Y), Obstacles);
	?location(Ag, DType, DX, DY); ?placement(DType, DPlacement);
	?location(fridge, OType, OX, OY); ?placement(OType, OPlacement);
	.send(mover, tell, move(beer, location(fridge, OX, OY, OPlacement), location(Ag, DX, DY, DPlacement), Obstacles)).
+!manageBeer : requestedPickUp(beer, delivery) & not moving(_, beer, delivery, fridge) <-
	.println("Voy a recoger las cervezas que me han entregado");
	+moving(mover, beer, delivery, fridge);
	if (automaton(mover, inactive)) {
		?location(depot, _, DepX, DepY); ?bounds(BX, BY);
		.send(mover, tell, activate(mover, depot(DepX, DepY), bounds(BX, BY)));
		.abolish(automaton(mover, inactive));
		+automaton(mover, active);
	}
	.findall(obstacle(X, Y), location(_, obstacle, X, Y), Obstacles);
	?location(delivery, OType, OX, OY); ?placement(OType, OPlacement);
	?location(fridge, DType, DX, DY); ?placement(DType, DPlacement);
	.send(mover, tell, move(beer, location(delivery, OX, OY, OPlacement), location(fridge, DX, DY, DPlacement), Obstacles)).
+!manageBeer : not overThreshold(beer, fridge) & not ordered(beer) & cheapest(Provider, beer, Price) <-
	.println("Tengo menos cerveza de la que debería, voy a comprar más");
	.println("Cheapest is ", Provider, " @", Price);
	?buyBatch(beer, Batch);
	.send(Provider, tell, order(beer, Batch));
	+ordered(beer).
+!manageBeer : asked(Ag, beer) & healthConstraint(beer, Ag, Msg) <-
	.println(Ag, " no puede beber más ", "beer");
	.send(Ag, tell, msg(Msg));
	.date(YY,MM,DD);
	.send(Ag, tell, healthConstraint(beer,YY,MM,DD));
	-asked(Ag, beer).
+!manageBeer <- true.

// ## HELPER TRIGGER moved

+moved(success, Product, Origin, Destination)[source(Mover)] <-
	.println("Movement success: ", Origin, "->", Destination);
	if (Destination == owner) {
		.date(YY,MM,DD); .time(HH,NN,SS);
		+consumed(YY,MM,DD,HH,NN,SS, Product);
		.send(database, achieve, add(consumed,YY,MM,DD,HH,NN,SS, Product));
		-asked(Destination, Product);
	}
	if (Origin == delivery) {
		.println("Delivery deposit success");
		.abolish(requestedPickUp(Product, Origin));
		-ordered(Product);
	}
	.abolish(moving(Mover, Product, Origin, Destination));
	.abolish(moved(success, Product, Origin, Destination)[source(Mover)]).
+moved(failure, Product, Origin, Destination)[source(Mover)] <-
	.println("Movement failure");
	if (Destination == owner) {
		.send(Destination, tell, msg("No me queda, voy a comprar más"));
	}
	.abolish(moving(Mover, Product, Origin, Destination));
	.abolish(moved(failure, Product, Origin, Destination)[source(Mover)]).

// ## HELPER TRIGGER [finished] takingout(dustman, trash)

-moving(mover, beer, _, _) : not asked(_, beer) & not requestedPickUp(beer, _) & not moving(mover, beer, _, _) & automaton(mover, active) <-
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

+delivered(OrderId, Product, Qtty, TotalPrice)[source(Provider)] : // THIS COLLIDES
	has(money, Balance) & Balance >= TotalPrice 
<-
	.println("Recibido pedido de ", Qtty, " ", Product);
	+requestedPickUp(Product, delivery);
	.send(Provider, tell, received(OrderId));
	.send(Provider, tell, pay(TotalPrice));
	.send(database, achieve, del(money, TotalPrice));
	?has(money, Amount);
	+has(money, Amount-TotalPrice);
	.abolish(has(money, Amount)).
+delivered(OrderId, Product, Qtty, TotalPrice)[source(Provider)] :
	has(money, Balance) & Balance < TotalPrice 
<-
	.println("Recibido pedido de ", Qtty, " ", Product, " (sin dinero)");
	.send(Provider, tell, reject(OrderId)); // TODO not implemented
	-ordered(beer);
	!askForMoney(owner).

// ## HELPER TRIGGER stock

+stock(Object, LocationDescriptor, Qtty) <-
	.abolish(stock(Object, LocationDescriptor, _));
  -+stored(Object, LocationDescriptor, Qtty).

// -------------------------------------------------------------------------
// DEFINITION FOR PLANS goAtX
// -------------------------------------------------------------------------

+!goAtPlace(robot, Place) : at(robot, Place) <- true.
+!goAtPlace(robot, Place) :
	not at(robot, Place) &
	at(robot, OX, OY) & location(Place, Type, DX, DY) & placement(Type, Placement) & bounds(BX, BY)
<-
	.println("Going towards ", Place);
	.findall(obstacle(X, Y), location(_, obstacle, X, Y), Obstacles);
	movement.getDirection(origin(OX, OY), destination(DX, DY, Placement), bounds(BX, BY), Obstacles, Direction);
	move_towards(robot, Direction);
	!goAtPlace(robot, Place).
+!goAtPlace(robot, Place) <-
	.wait(100);
	!goAtPlace(robot, Place).

+!goAtLocation(robot, location(DX, DY)) : at(robot, DX, DY) <- true.
+!goAtLocation(robot, location(DX, DY)) : 
	not at(robot, DX, DY) &
	at(robot, OX, OY) & bounds(BX, BY)
<-
	.println("Going towards can");
	.findall(obstacle(X, Y), location(_, obstacle, X, Y), Obstacles);
	movement.getDirection(origin(OX, OY), destination(DX, DY, top), bounds(BX, BY), Obstacles, Direction);
	move_towards(robot, Direction);
	!goAtLocation(robot, location(DX, DY)).
+!goAtLocation(robot, location(DX, DY)) <-
	.wait(100);
	!goAtLocation(robot, location(DX, DY)).