placement(obstacle, side).
placement(position, top ).

automaton(cleaner, inactive).
automaton(dustman, inactive).
automaton(mover,   inactive).
automaton(shopper, inactive).

limit(min, fridge,   beer,  5 ). // Minimo de cervezas que deberia haber en el frigo, si hay menos se ordenan mas
limit(max, dumpster, trash, 5 ).
limit(max, owner,    beer,  10).
limit(min, buy,      beer,  3 ). // Cantidad de cervezas a pedirle al super (en cada orden)

stored(beer,  fridge,   1).      // Si se comienza sin la creencia de tener cerveza, no se va a la nevera y
                                 // por ende hay que esperar a que el pedido llegue para comprobar el stock
stored(trash, dumpster, 0).

available(Product, Location) :-
	stored(Product, Location, Qtty) &
	Qtty > 0.

overLimit(Type, Product, Location) :-
	limit(Type, Location, Product, Limit) &
	stored(Product, Location, Qtty) & Qtty >= Limit.

cheapest(Provider, Product, Price, Qtty) :-
	price(Provider, Product, Price, Cost, _, _) &
	not (price(Provider2, Product, Price2, Cost2, _, _) & Provider2 \== Provider & Price2*Qtty+Cost2 < Price*Qtty+Cost).

consumedSafe(YY,MM,DD, Product, Qtty) :-
	consumed(YY,MM,DD, Product, Qtty) | Qtty = 0.

healthConstraint(Product, Agent, Message) :-
	.date(YY,MM,DD) &
	limit(max, Agent, Product, Limit) & consumed(YY,MM,DD, Product, Consumed) & Consumed >= Limit &
	.concat("The Department of Health does not allow me to give you more than ", Qtty, " beers a day! I am very sorry about that!", Message).

// -------------------------------------------------------------------------
// SERVICE INIT AND HELPER METHODS
// -------------------------------------------------------------------------

service(Query, pay) :-
	checkTag("<pay>", Query).
service(Query, bring) :-
	checkTag("<bring>", Query).
service(Query, clean) :-
	checkTag("<clean>", Query).
service(Query, offer) :-
	checkTag("<offer>", Query).
service(Query, deliver) :-
	checkTag("<deliver>", Query).
service(Query, conversation) :-
	checkTag("<conversation>", Query).

checkTag(Tag, String) :-
	.substring(Tag, String).

tagValue(Tag, Query, Literal) :-         // Gets into Val the first substring contained by a tag Tag into String, as a Literal
	.substring(Tag, Query, Fst) &          // First: find the Fst Posicition of the tag string              
	.length(Tag, N) &                      // Second: calculate the length of the tag string
	.delete(0, Tag, RestTag) &
	.concat("</", RestTag, EndTag) &       // Third: build the terminal of the tag string
	.substring(EndTag, Query, End) &       // Four: find the Fst Position of the terminal tag string
	.substring(Query, Parse, Fst+N, End) & // Five: get the Val tagged
	.term2string(Literal, Parse).          // Six: convert to Literal

filter(Query, pay, [Status, Amount]) :-
	tagValue("<status>", Query, Status) &
	tagValue("<amount>", Query, Amount).
filter(Query, bring, [Product]) :-
	tagValue("<product>", Query, Product).
filter(Query, clean, [Object, Position]) :-
	tagValue("<object>", Query, Object) &
	tagValue("<position>", Query, Position).
filter(Query, floor, [FX, FY]) :-
	tagValue("<x>", Query, FX) &
	tagValue("<y>", Query, FY).
filter(Query, offer, [Product, Price, Cost, Time, Payment]) :-
	tagValue("<product>", Query, Product) &
	tagValue("<price>", Query, Price) &
	tagValue("<cost>", Query, Cost) &
	tagValue("<time>", Query, Time) &
	tagValue("<payment>", Query, Payment).
filter(Query, deliver, [Status, OrderId, Product, Qtty, Price]) :-
	tagValue("<status>", Query, Status) &
	tagValue("<order-id>", Query, OrderId) &
	tagValue("<product>", Query, Product) &
	tagValue("<quantity>", Query, Qtty) &
	tagValue("<price>", Query, Price).
filter(Query, conversation, [Topic]) :-
	tagValue("<topic>", Query, Topic).

// -------------------------------------------------------------------------
// PRIORITIES AND PLAN INITIALIZATION
// -------------------------------------------------------------------------

!initButler.
!dialog.
!doHouseWork.

+!initButler <-
	!initBot;
	!createDatabase;
	!createAutomaton(cleaner);
	!createAutomaton(dustman);
	!createAutomaton(mover);
	+butlerInit.

+!doHouseWork : butlerInit<-
	!manageBeer;
	!cleanHouse;
	!doHouseWork.
+!doHouseWork <- !doHouseWork.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN initBot
// -------------------------------------------------------------------------

+!initBot <-
	makeArtifact("butlerBot", "bot.ChatBOT", ["butlerBot"], BotId);
	focus(BotId).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN createDatabase
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

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN createAutomaton
// -------------------------------------------------------------------------

+!createAutomaton(Name) <-
	.concat("./src/asl/automaton/", Name, ".asl", Filename);
	.create_agent(Name, Filename, [agentArchClass("jaca.CAgentArch"), agentArchClass("MixedAgentArch")]).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN dialog
// -------------------------------------------------------------------------

+!dialog : butlerInit & msg(Msg)[source(Ag)] <-
	.println("<- [", Ag, "]: ", Msg);
	.abolish(msg(Msg)[source(Ag)]);
	chatSincrono(Msg, Answer);
	!doService(Answer, Ag);
	!dialog.
+!dialog <- !dialog.

// -------------------------------------------------------------------------
// DEFINITION FOR ACTION SERVICES
// -------------------------------------------------------------------------

// # PAYMENT SERVICE
+!doService(Query, Ag) : service(Query, pay) & filter(Query, pay, [approved, Amount]) <-
	.println("He recibido un pago de ", Amount, " de ", Ag);
	?has(money, Balance);
	.abolish(has(money, _)); +has(money, Balance + Amount);
	.send(database, achieve, add(money, Amount)).
+!doService(Query, Ag) : service(Query, pay) & filter(Query, pay, [rejected, Amount]) <-
	.println(Ag, " ha rechazado el pago de ", Amount, " que la habia pedido");
	+cannotPay(owner, Amount).
+!doService(Query, Ag) : service(Query, pay) & filter(Query, pay, [returned, Amount]) <-
	.println("He realizado un pago invalido a ", Ag, ", me lo ha devuelto");
	?has(money, Balance);
	.abolish(has(money, _)); +has(money, Balance + Amount);
	.send(database, achieve, add(money, Amount)).

// # BRING SERVICE
+!doService(Query, Ag) : service(Query, bring) & filter(Query, bring, [Product]) <-
	.println(Ag, " me ha pedido que le lleve ", Product);
	+asked(Ag, Product).

// # CLEAN SERVICE
+!doService(Query, Ag) : service(Query, clean) & filter(Query, clean, [Object, owner]) <-
	.println(Ag, " me ha pedido que vaya a recoger un ", Object);
	+requestedRetrieval(Object, owner).
+!doService(Query, Ag) : service(Query, clean) & filter(Query, clean, [Object, Position]) & filter(Query, floor, [FX, FY]) <-
	.println(Ag, " me ha pedido que vaya a limpiar un ", Object, " del suelo (", FX, ",", FY, ")");
	+requestedRetrieval(Object, floor(FX, FY)).

// # OFFER SERVICE
+!doService(Query, Ag) : service(Query, offer) & filter(Query, offer, [Product, Price, Cost, Time, Payment]) <-
	if (Payment == beforeDelivery) {
		.println(Ag, " me vende un ", Product, " a ", Price, " y el envio me llega en ", Time, " costando ", Cost, " (pago al contado)");
	} else {
		.println(Ag, " me vende un ", Product, " a ", Price, " y el envio me llega en ", Time, " costando ", Cost, " (pago contrarreembolso)");
	}
	.abolish(price(Ag, Product, _, _, _, _));
	+price(Ag, Product, Price, Cost, Time, Payment).

// # DELIVER SERVICE
+!doService(Query, Ag) : service(Query, deliver) & filter(Query, deliver, [rejected, OrderId, Product, Qtty, Price]) <-
	.println(Ag, " ha rechazado mi pedido de ", Qtty, " ", Product, " #", OrderId);
	.abolish(price(Ag, Product, _, _, _, _));
	.wait(3000);
	-ordered(beer).
+!doService(Query, Ag) : service(Query, deliver) & filter(Query, deliver, [delivered, OrderId, Product, Qtty, Price]) <-
	.println(Ag, " ha entregado mi pedido de ", Qtty, " ", Product, " #", OrderId);
	?price(Ag, Product, _, _, _, Payment);
	if (Payment == afterDelivery) {
		+requestedPayment(Ag, OrderId, Product, Qtty, Price);
	}
	.concat("He recibido la orden ", OrderId, Msg);
	.send(Ag, tell, msg(Msg));
	+requestedPickUp(Product, Qtty, delivery).
+!doService(Query, Ag) : service(Query, deliver) & filter(Query, deliver, [accepted, OrderId, Product, Qtty, Price]) <-
	.println(Ag, " ha aceptado mi pedido de ", Qtty, " ", Product, " #", OrderId);
	?price(Ag, Product, _, _, _, Payment);
	if (Payment == beforeDelivery) {
		+requestedPayment(Ag, OrderId, Product, Qtty, Price);
	}.

// # CONVERSATION SERVICE
+!doService(Query, Ag) : service(Query, conversation) & filter(Query, conversation, [time]) <-
	.time(HH,MM,SS);
	.concat("Son las ", HH, ":", MM, ":", SS, Msg);
	.println("-> [", Ag, "] ", Msg);
	.send(Ag, tell, msg(Msg)).
+!doService(Query, Ag) : service(Query, conversation) & filter(Query, conversation, [money]) <-
	?has(money, Balance);
	.concat("Me queda ", Balance, Msg);
	.println("-> [", Ag, "] ", Msg);
	.send(Ag, tell, msg(Msg)).

// # COMMUNICATION SERVICE
+!doService(Answer, Ag) : not service(Answer, Service) & Answer \== "I have no answer for that." <-
	.println("-> [", Ag, "] ", Answer);
	.send(Ag, tell, answer(Answer)).
+!doService(Answer, Ag) : not service(Answer, Service) & Answer == "I have no answer for that." <-
	true.
	
// -------------------------------------------------------------------------
// DEFINITION FOR PLAN cleanHouse
// -------------------------------------------------------------------------

+!cleanHouse : requestedRetrieval(can, floor(X, Y)) & not cleaning(_, can, floor(X, Y)) <-
	.println("> Activo un automata para limpiar la lata");
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
	.println("> Activo un automata para recoger la lata");
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
	.println("El dumpster esta lleno");
	.println("> Activo un automata para sacar la basura");
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
+!cleanHouse <- true.

// ## HELPER TRIGGER cleaned

+cleaned(success, Object, Position)[source(Cleaner)] <-
	.println("< Exito en la limpieza");
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
	.println("< Exito al tirar la basura");
	.abolish(stored(trash, dumpster, Qtty)); +stored(trash, dumpster, 0);
	.abolish(takingout(Dustman, trash));
	.abolish(tookout(success, trash)).

// ## HELPER TRIGGER [finished] takingout(dustman, trash)

-takingout(dustman, trash) : not overLimit(max, trash, dumpster) & not takingout(dustman, trash) & automaton(dustman, active) <-
	.send(dustman, tell, deactivate(dustman));
	.abolish(automaton(dustman, active));
	+automaton(dustman, inactive).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN manageBeer
// -------------------------------------------------------------------------

+!manageBeer : asked(Ag, beer) & available(beer, fridge) & not moving(_, beer, 1, fridge, Ag) & not healthConstraint(beer, Ag, _) <-
	.println("> Activo un automata para llevar ", beer, " a ", Ag);
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
+!manageBeer : requestedPickUp(beer, Qtty, delivery) & not requestedPayment(Ag, OrderId, Product, Qtty, Price) & not moving(_, beer, Qtty, delivery, fridge) <-
	.println("> Activo un automata para mover ", beer, ": ", delivery, "->", fridge);
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
+!manageBeer : not overLimit(min, beer, fridge) & not ordered(beer) & limit(min, buy, beer, BatchSize) & cheapest(Provider, beer, Price, BatchSize) <-
	.println("> Tengo menos cerveza de la que deberia, voy a comprar mas en ", Provider);
	if (BatchSize > 0) {
		.concat("Me gustaria comprarte ", BatchSize, " cervezas", Msg);
		.send(Provider, tell, msg(Msg));
	} else {
		.println("No puedo comprar cervezas en lotes de ", BatchSize);
	}
	+ordered(beer).
+!manageBeer : requestedPayment(Provider, OrderId, Product, Qtty, Price) & has(money, Balance) & Balance >= Price <-
	.println("> Pago ", Price, " por el pedido #", OrderId);
	.concat("Toma tu pago de ", Price, Msg);
	.send(Provider, tell, msg(Msg));
	.send(database, achieve, del(money, Price));
	.abolish(has(money, Balance));
	+has(money, Balance-Price);
	.abolish(requestedPayment(Provider, OrderId, Product, Qtty, Price));
	.abolish(requestedMoney(owner, _)).
+!manageBeer : requestedPayment(Provider, OrderId, Product, Qtty, Price) & has(money, Balance) & Balance < Price & not requestedMoney(owner, _) <-
	.println("[!] No tengo dinero para pagar el pedido ", OrderId, ", se lo solicito a ", owner);
	.abolish(cannotPay(owner, _));
	.concat("Necesito ", Price-Balance, " euros para comprar cervezas", Msg);
	.send(owner, tell, msg(Msg));
	+requestedMoney(owner, Price-Balance).
+!manageBeer : requestedPayment(Provider, OrderId, Product, Qtty, Price) & has(money, Balance) & Balance < Price & cannotPay(owner, _) <-
	.println("> Devuelvo el pedido #", OrderId, ", ", owner, " no me ha concedido el dinero");
	.concat("Lo siento pero debo rechazar la orden ", OrderId, Msg);
	.send(Provider, tell, msg(Msg));
	.abolish(requestedPickUp(beer, Qtty, delivery));
	.abolish(requestedPayment(Provider, OrderId, Product, Qtty, Price));
	.abolish(requestedMoney(owner, _));
	.abolish(ordered(Product)).
+!manageBeer : asked(Ag, beer) & healthConstraint(beer, Ag, Msg) <-
	.println("[!] ", Ag, " no puede beber mas ", beer, " por hoy");
	.send(Ag, tell, msg(Msg));
	.date(YY,MM,DD);
	.send(Ag, tell, msg("Has bebido demasiada cerveza por hoy"));
	-asked(Ag, beer).
+!manageBeer <- true.

// ## HELPER TRIGGER moved

+moved(success, Product, Qtty, Origin, Destination)[source(Mover)] <-
	.println("< Exito moviendo ", Product, "(x", Qtty, "): ", Origin, "->", Destination);
	if (Destination == owner) {
		.date(YY,MM,DD);
		?consumedSafe(YY,MM,DD, Product, ConsumedQtty);
		.abolish(consumed(YY,MM,DD, Product, _));
		+consumed(YY,MM,DD, Product, ConsumedQtty+1);
		.send(database, achieve, add(consumed(YY,MM,DD, Product, ConsumedQtty+1)));
		-asked(Destination, Product);
	}
	if (Origin == delivery) {
		.abolish(requestedPickUp(Product, Qtty, Origin));
		-ordered(Product);
	}
	.abolish(moving(Mover, Product, Qtty, Origin, Destination));
	.abolish(moved(success, Product, Qtty, Origin, Destination)[source(Mover)]).
+moved(failure, Product, Qtty, Origin, Destination)[source(Mover)] <-
	.println("! Fallo moviendo ", Product, "(x", Qtty, "): ", Origin, "->", Destination);
	if (Destination == owner) {
		.send(Destination, tell, msg("No quedan cervezas en el frigo, comprare mas"));
	}
	.abolish(moving(Mover, Product, Qtty, Origin, Destination));
	.abolish(moved(failure, Product, Qtty, Origin, Destination)[source(Mover)]).

// ## HELPER TRIGGER [finished] takingout(dustman, trash)

-moving(mover, beer, _, _, _) : not asked(_, beer) & not requestedPickUp(beer, _, _) & not moving(mover, beer, _, _, _) & automaton(mover, active) <-
	.send(mover, tell, deactivate(mover));
	.abolish(automaton(mover, active));
	+automaton(mover, inactive).

// ## HELPER TRIGGER stock

+stock(Object, LocationDescriptor, Qtty) <-
	.abolish(stock(Object, LocationDescriptor, _));
	.abolish(stored(Object, LocationDescriptor, _)); +stored(Object, LocationDescriptor, Qtty).
