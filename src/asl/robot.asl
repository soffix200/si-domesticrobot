placement(obstacle, side).
placement(position, top ).

stored(beer, fridge, 1).
threshold(beer, 5).
buyBatch(beer, 8).

available(Product, Location) :-
	stored(Product, Location, Qtty) &
	Qtty > 0.

overThreshold(Product, Location) :-
	threshold(Product, Threshold) &
	stored(Product, Location, Qtty) & Qtty > Threshold.

cheapest(Product, Provider, Price) :-
	price(Product, Price)[source(Provider)] &
	price(Product, Price2)[source(Provider2)] &
	Price <= Price2.

limit(beer, owner, 1, "The Department of Health does not allow me to give you more than 10 beers a day! I am very sorry about that!").

healthConstraint(Product, Agent, Message) :-
	limit(Product, Agent, Limit, Message) &
	.date(YY,MM,DD) &
	.count(consumed(YY,MM,DD,_,_,_,beer), Consumed) &
	Consumed > Limit.

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
// DEFINITION FOR deleteOffers(beer)
// -------------------------------------------------------------------------

+!createDatabase : 	.date(YY,MM,DD) <-

	.list_files("./tmp/","database.asl", L);
	if (.length(L, 0)) {
	.create_agent("database", "database.asl");
	} else {
		.create_agent("database", "./tmp/database.asl"); 
	}
	.send(database, askOne, has(money, X), MoneyResponse);
	.date(YY,MM,DD);
	.send(database, askOne, consumed(YY,MM,DD,_,_,_,beer), ConsumedResponse);
	+MoneyResponse;
	+ConsumedResponse.

// -------------------------------------------------------------------------
// DEFINITION FOR deleteOffers(beer)
// -------------------------------------------------------------------------

+deleteOffers(beer)[source(Ag)] <-
	//.println("Entendido, ",Ag," por favor, dime los nuevos precios"); //DEBUG
	.abolish(price(beer,_)[source(Ag)]).

/*+price(beer,Price)[source(Ag)] <- //DEBUG
	.println("Entendido, ",Ag," ahora me vendes una beer a ", Price). */

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

+!cleanHouse : requestedRetrieval(can, floor(PX, PY)) <-
	!goAtLocation(robot, location(PX, PY));
	get(can);
	!goAtPlace(robot, dumpster);
	recycle(can);
	-requestedRetrieval(can, floor(PX, PY)).
+!cleanHouse : requestedRetrieval(can, owner) <-
	!goAtPlace(robot, owner);
	get(can);
	send(owner, tell, retrieved(can)); // TODO not implemented
	!goAtPlace(robot, dumpster);
	recycle(can);
	-requestedRetrieval(can, owner).
+!cleanHouse <- true. // Execute randomly
	// TODO; not yet implemented

+can(PX, PY) <-
	+requestedRetrieval(can, floor(PX, PY));
	.abolish(can(PX, PY)).

+msg("Ven a por la lata") <-
	+requestedRetrieval(can, owner);
	.abolish(msg("Ven a por la lata")).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN manageBeer
// -------------------------------------------------------------------------

+!manageBeer : asked(Ag, beer) & available(beer, fridge) & not healthConstraint(beer, Ag, _) <-
	.println(Ag, " me ha pedido un ", "beer", ", se lo llevo");
	!goAtPlace(robot, fridge);
	open(fridge);
	if (available(beer, fridge)) {
		get(beer, fridge);
		close(fridge);
		!goAtPlace(robot, owner);
		hand_in(beer);
		.date(YY,MM,DD); .time(HH,NN,SS);
		+consumed(YY,MM,DD,HH,NN,SS,beer);
		.send(database, achieve, add(consumed,YY,MM,DD,HH,NN,SS,beer));
		-asked(Ag, beer);
	} else {
		close(fridge);
		.send(Ag, tell, msg("No me queda, voy a comprar más"));
	}.
+!manageBeer : requestedPickUp(beer, delivery) <-
	.println("Voy a recoger las cervezas que me han entregado");
	!goAtPlace(robot, delivery);
	// TODO robot should grab the beers in inventory
	!goAtPlace(robot, fridge);
	open(fridge);
	// TODO robot should place the beers into fridge
	close(fridge);
	-requestedPickUp(beer, delivery);
	-ordered(beer).
+!manageBeer : not overThreshold(beer, fridge) & not ordered(beer) & cheapest(beer, Provider, Price) <-
	.println("Tengo menos cerveza de la que debería, voy a comprar más");
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

+bring(Product)[source(Ag)] <- // TODO AIML
	+asked(Ag, Product);
	.abolish(bring(Product)[source(Ag)]).

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

+stock(beer, N) <-
	-+stored(beer, fridge, N);
	.abolish(stock(beer, N)).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN goAtPlace
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