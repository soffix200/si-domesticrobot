currentOrderId(1).

cost(beer, 2).

//paymentMoment(beforeDelivery | afterDelivery). // If not set here, defined randomly. If set, must delete "!setPaymentMoment;"

limit(min, reeval, price, 20000).
limit(min, stock,  beer,  10).
limit(max, cost,   beer,  3).

// -------------------------------------------------------------------------
// SERVICE INIT AND HELPER METHODS
// -------------------------------------------------------------------------

service(Query, buy) :-
	checkTag("<buy>", Query).
service(Query, order) :-
	checkTag("<order>", Query).
service(Query, pay) :-
	checkTag("<pay>", Query).
service(Query, auction) :-
	checkTag("<auction>", Query).
service(Query, alliance) :-
	checkTag("<alliance>", Query).

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

filter(Query, buy, [Product, Qtty]) :-
	tagValue("<product>", Query, Product) &
	tagValue("<quantity>", Query, Qtty).
filter(Query, order, [Status, OrderId]) :-
	tagValue("<status>", Query, Status) &
	tagValue("<order-id>", Query, OrderId).
filter(Query, pay, [Amount]) :-
	tagValue("<amount>", Query, Amount).
filter(Query, auction, [Status, AuctionNum, Winner, Product, Qtty, Price]) :-
	tagValue("<status>", Query, Status) &
	tagValue("<auction-num>", Query, AuctionNum) &
	tagValue("<winner>", Query, Winner) &
	tagValue("<product>", Query, Product) &
	tagValue("<quantity>", Query, Qtty) &
	tagValue("<price>", Query, Price).
filter(Query, auction, [Status, AuctionNum, Product, Qtty]) :-
	tagValue("<status>", Query, Status) &
	tagValue("<auction-num>", Query, AuctionNum) &
	tagValue("<product>", Query, Product) &
	tagValue("<quantity>", Query, Qtty).
filter(Query, alliance, [Action, AuctionNum, Qtty, Product, Price]) :-
	tagValue("<action>", Query, Action) &
	tagValue("<auction-num>", Query, AuctionNum) &
	tagValue("<quantity>", Query, Qtty) &
	tagValue("<product>", Query, Product) &
	tagValue("<price>", Query, Price).
filter(Query, alliance, [Action, AuctionNum, MaxPrice]) :-
	tagValue("<action>", Query, Action) &
	tagValue("<auction-num>", Query, AuctionNum) &
	tagValue("<max-price>", Query, MaxPrice).
filter(Query, alliance, [Action, AuctionNum]) :-
	tagValue("<action>", Query, Action) &
	tagValue("<auction-num>", Query, AuctionNum).

// -------------------------------------------------------------------------
// PRIORITIES AND PLAN INITIALIZATION
// -------------------------------------------------------------------------

!initSupermarket.
!dialog.
!offerBeer.
!buyBeer.
!sellBeer.

+!initSupermarket <-
	!initBot;
	!createStore;
	!setDeliveryTime(butler);
	!setPaymentMoment;
	+supermarketInit.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN initBot
// -------------------------------------------------------------------------

+!initBot <-
	.my_name(Name); .concat(Name, "Bot", BotName);
	makeArtifact(BotName, "bot.ChatBOT", ["supermarketBot"], BotId);
	focus(BotId).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN createStore
// -------------------------------------------------------------------------

+!createStore <-
	.my_name(Name);
	.concat("store", Name, StoreName);
	.term2string(Store, StoreName);
	+store(Store);
	.concat(StoreName, ".asl", FileName);
	.list_files("./tmp/", FileName, L);
	if (.length(L, 0)) {
		.create_agent(Store, "store.asl");
	} else {
		.concat("tmp/", FileName, FilePath);
		.create_agent(Store, FilePath);
	}
	.send(Store, askOne, beer(BeerQtty), beer(BeerQtty)); +has(beer, BeerQtty);
	.send(Store, askOne, money(MoneyQtty), money(MoneyQtty));	+has(money, MoneyQtty);
	.send(Store, askOne, price(beer, Price), price(beer, Price)); +price(beer, Price);
	.send(Store, askOne, deliveryTime(butler, Time), deliveryTime(butler, Time));
	.send(Store, askOne, deliveryCost(butler, Cost), deliveryCost(butler, Cost));
	if (Time \== -1 & Cost \== -1) {
		+deliveryTime(butler, Time);
		+deliveryCost(butler, Cost);
	}.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN setDeliveryTime
// -------------------------------------------------------------------------

+!setDeliveryTime(butler) : not deliveryTime(butler, Time) & not deliveryCost(butler, Cost) <-
	?store(Store);
	.random(X);
	basemath.truncate(X*20, Time);
	basemath.truncate(5-(X*5),  Cost);
	+deliveryTime(butler, Time);
	+deliveryCost(butler, Cost);
	.send(Store, achieve, addDeliveryTime(butler, Time));
	.send(Store, achieve, addDeliveryCost(butler, Cost)).
+!setDeliveryTime(_) <- true.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN setPaymentMoment
// -------------------------------------------------------------------------

+!setPaymentMoment : not paymentMoment(_) <-
	.random(X);
	if (X < 0.5) {
		+paymentMoment(beforeDelivery);
	} else {
		+paymentMoment(afterDelivery);
	}.
+!setPaymentMoment <- true.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN dialog
// -------------------------------------------------------------------------

+!dialog : supermarketInit & msg(Msg)[source(Ag)] <-
	// .println("<- [", Ag, "]: ", Msg);
	.abolish(msg(Msg)[source(Ag)]);
	chatSincrono(Msg, Answer);
	!doService(Answer, Ag);
	!dialog.
+!dialog <- !dialog.

// -------------------------------------------------------------------------
// DEFINITION FOR ACTION SERVICES
// -------------------------------------------------------------------------

// # BUY SERVICE
+!doService(Query, Ag) : service(Query, buy) & filter(Query, buy, [Product, Qtty]) <-
	.println("Pedido de ", Qtty, " ", Product, " recibido de ", Ag);
	?currentOrderId(OrderId); ?deliveryCost(Ag, Cost); ?price(Product, Price);
	basemath.truncate(Price*Qtty+Cost, PendingPayment);
	+pendingPayment(OrderId, PendingPayment);
	+order(OrderId, Ag, Product, Qtty).

// # ORDER SERVICE
+!doService(Query, Ag) : service(Query, order) & filter(Query, order, [rejected, OrderId]) <-
	?order(OrderId, Ag, Product, Qtty);
	.println("Pedido ", OrderId, " rechazado por ", Ag);
	.abolish(order(OrderId, _, _, _));
	.abolish(accepted(OrderId));
	.abolish(pendingPayment(OrderId, _));
	if (paymentMoment(afterDelivery)) {
		return(Product, Qtty);
	}.
+!doService(Query, Ag) : service(Query, order) & filter(Query, order, [received, OrderId]) <-
	.println("Pedido ", OrderId, " recibido por ", Ag).

// # PAY SERVICE
+!doService(Query, Ag) : service(Query, pay) & filter(Query, pay, [Amount]) &
	pendingPayment(OrderId, Amount)
<-
	.println("Pago de ", Amount, " recibido de ", Ag);
	?store(Store); ?has(money, Balance);
	.abolish(pendingPayment(OrderId, Amount));
	if (paymentMoment(afterDelivery)) {
		.abolish(order(OrderId, _, _, _));
	}
	.abolish(has(money, _)); +has(money, Balance+Amount);
	.send(Store, achieve, add(money, Amount)).
+!doService(Query, Ag) : service(Query, pay) & filter(Query, pay, [Amount]) &
	not pendingPayment(OrderId, Amount)
<-
	.println("Pago de ", Amount, " recibido de ", Ag, " (invalido)");
	.concat("El pago no es valido, te devuelvo tus ", Amount, Msg);
	.send(Ag, tell, msg(Msg)).

// # AUCTION SERVICE (START)
+!doService(Query, Ag) : service(Query, auction) & filter(Query, auction, [started, AuctionNum, Product, Qtty]) &
	requestedPurchase(Product) &
	has(money, Balance) & Balance >= 1 &
	limit(max, cost, beer, Limit) & 1 <= Limit*Qtty
<-
	if (not alliance(AuctionNum, _, _, _)) {
		Supermarkets = 0;
		.all_names(L);
		for ( .range(I,1,2) ) {
			.random(L, M);
			if (.substring("supermarket", M) & not .substring("store", M) & not .my_name(M) & not definedTarget) {
				.concat("Quieres aliarte conmigo para la subasta ", AuctionNum, " hasta un maximo de ", Balance, Msg);
				.send(M, tell, msg(Msg));
				+definedTarget;
			}
		}
		-definedTarget;
	}
	.println("< La subasta ", AuctionNum, " ha comenzado. Pujo 1");
	.concat("Me gustaria ofertar ", 1, " en la subasta ", AuctionNum, Msg2);
	.send(market, tell, msg(Msg2));
	-+winningAuction(AuctionNum).
+!doService(Query, Ag) : service(Query, auction) & filter(Query, auction, [started, AuctionNum, Product, Qtty]) <-
	.println("La subasta ", AuctionNum, " ha comenzado. No participo").

// # AUCTION SERVICE (UPDATE)
+!doService(Query, Ag) : service(Query, auction) & filter(Query, auction, [update, AuctionNum, Winner, Product, Qtty, Price]) &
	requestedPurchase(Product) &
	.my_name(Self) & Self == Winner
<-
	.println("< Voy ganando en la subasta ", AuctionNum, " con mi puja de ", Price);
	-+winningAuction(AuctionNum).
+!doService(Query, Ag) : service(Query, auction) & filter(Query, auction, [update, AuctionNum, Winner, Product, Qtty, Price]) &
	requestedPurchase(Product) &
	.my_name(Self) & Self \== Winner &
	has(money, Balance) & Balance >= Price &
	limit(max, cost, beer, Limit) & Price+1 <= Limit*Qtty &
	not alliance(AuctionNum, slave, me)
<-
	.findall(X, alliance(AuctionNum, X, _), AllianceMembers);
	if (not alliance(AuctionNum, _, _) | alliance(AuctionNum, master, me)) {
		.all_names(Agents);
		.difference(Agents, AllianceMembers, L);
		for ( .range(I,1,2) ) {
			.random(L, M);
			if (.substring("supermarket", M) & not .substring("store", M) & not .my_name(M) & not definedTarget) {
				.concat("Quieres aliarte conmigo para la subasta ", AuctionNum, " hasta un maximo de ", Balance, Msg);
				.send(M, tell, msg(Msg));
				+definedTarget;
			}
		}
		-definedTarget;
	}
	.println("< No voy ganando en la subasta ", AuctionNum, ". Pujo ", Price+1);
	-winningAuction(AuctionNum);
	.concat("Me gustaria ofertar ", Price+1, " en la subasta ", AuctionNum, Msg);
	.send(market, tell, msg(Msg));
	-+winningAuction(AuctionNum).
+!doService(Query, Ag) : service(Query, auction) & filter(Query, auction, [update, AuctionNum, Winner, Product, Qtty, Price]) &
	winningAuction(AuctionNum)
<-
	.println("< Dejo de participar en la subasta ", AuctionNum);
	-winningAuction(AuctionNum).
+!doService(Query, Ag) : service(Query, auction) & filter(Query, auction, [update, AuctionNum, Winner, Product, Qtty, Price]) &
	not winningAuction(AuctionNum)
<-
	true.

// # AUCTION SERVICE (FINISH)
+!doService(Query, Ag) : service(Query, auction) & filter(Query, auction, [finished, AuctionNum, Winner, Product, Qtty, Price]) &
	.my_name(Self) & Self == Winner
<-
	.println("> He ganado la subasta ", AuctionNum, " de ", Product, "(x", Qtty, "). He pagado:",Price);
	?has(beer, StoredBeer); ?has(money, StoredMoney); ?store(Store);
	.abolish(has(money, _)); +has(money, StoredMoney-Price); .send(Store, achieve, del(money, Price));
	if (alliance(AuctionNum, master, me)) {
		.findall(A, alliance(AuctionNum, slave, A), AllianceMembers);
		.length(AllianceMembers, Count);
		basemath.floor(Qtty/(Count+1), AssignedQtty);
		RemeaningQtty = Qtty - (AssignedQtty*Count);
		for (.member(M, AllianceMembers)) {
			.println("> Reparto a ", M, " su parte proporcional de ", AssignedQtty);
			.concat("Por la alianza en la subasta ", AuctionNum, " te corresponden ", AssignedQtty, " cervezas a cambio de ", Price*(AssignedQtty/Qtty), " euros", Msg);
			.send(M, tell, msg(Msg));
		}
		.abolish(has(money, _)); +has(money, StoredMoney-Price+Price/Qtty*(Qtty-RemeaningQtty)); .send(Store, achieve, add(money, Price/Qtty*(Qtty-RemeaningQtty)));
		.println("> Me quedo con mi parte de ", RemeaningQtty);
		.abolish(has(beer, _)); +has(beer, StoredBeer+RemeaningQtty); .send(Store, achieve, add(beer, RemeaningQtty));
	} else {
		.abolish(has(beer, _)); +has(beer, StoredBeer+Qtty); .send(Store, achieve, add(beer, Qtty));
	}
	-+cost(beer, Price/Qtty);
	-winningAuction(AuctionNum);
	.abolish(requestedPurchase(Product));
	.abolish(formingAlliance(AuctionNum, _, _, _));
	.abolish(alliance(AuctionNum, _, _)).
+!doService(Query, Ag) : service(Query, auction) & filter(Query, auction, [finished, AuctionNum, Winner, Product, Qtty, Price]) <-
	.println("> No he ganado en la subasta ", AuctionNum);
	-winningAuction(AuctionNum);
	.abolish(formingAlliance(AuctionNum, _, _, _));
	.abolish(alliance(AuctionNum, _, _)).

// # ALLIANCE SERVICE
+!doService(Query, Ag) : service(Query, alliance) & filter(Query, alliance, [purpose, AuctionNum, MaxPrice]) &
	requestedPurchase(Product) & not alliance(AuctionNum, _, _) & not formingAlliance(AuctionNum, _, _, _) &
	has(money, Balance) & Balance >= MaxPrice/2
<-
	.concat("De acuerdo, compremos juntos en la subasta ", AuctionNum, Msg);
	.send(Ag, tell, msg(Msg));
	+formingAlliance(AuctionNum, MaxPrice, master, Ag);
	+formingAlliance(AuctionNum, MaxPrice, slave, me).
+!doService(Query, Ag) : service(Query, alliance) & filter(Query, alliance, [purpose, AuctionNum, MaxPrice]) <-
	.concat("No deseo aliarme para la subasta ", AuctionNum, Msg);
	.send(Ag, tell, msg(Msg)).
+!doService(Query, Ag) : service(Query, alliance) & filter(Query, alliance, [confirm, AuctionNum]) &
	not alliance(AuctionNum, slave, me) & not formingAlliance(AuctionNum, _, slave, me)
<-
	.println(Ag, " ha aceptado formar parte de mi alianza");
	+alliance(AuctionNum, master, me);
	+alliance(AuctionNum, slave, Ag);
	.concat("Alianza formada para la subasta ", AuctionNum, Msg);
	.send(Ag, tell, msg(Msg)).
+!doService(Query, Ag) : service(Query, alliance) & filter(Query, alliance, [confirm, AuctionNum]) &
	(alliance(AuctionNum, slave, me) | formingAlliance(AuctionNum, _, slave, me))
<-
	.concat("Demasiado tarde, ya he formado una alianza para la subasta ", AuctionNum, Msg);
	.send(Ag, tell, msg(Msg)).
+!doService(Query, Ag) : service(Query, alliance) & filter(Query, alliance, [reject, AuctionNum]) <- true.
+!doService(Query, Ag) : service(Query, alliance) & filter(Query, alliance, [nack, AuctionNum]) <-
	.abolish(formingAlliance(AuctionNum, _, _, _)).
+!doService(Query, Ag) : service(Query, alliance) & filter(Query, alliance, [ack, AuctionNum]) <-
	.println("Me he unido satisfactoriamente a la alianza creada por ", Ag);
	+alliance(AuctionNum, master, Ag);
	+alliance(AuctionNum, slave, me);
	.abolish(formingAlliance(AuctionNum, _, _, _)).
+!doService(Query, Ag) : service(Query, alliance) & filter(Query, alliance, [distribute, AuctionNum, Qtty, Product, Price]) <-
	.println(Ag, " me entrega mi parte de la compra conjunta (", Qtty, " ", Product, ")");
	?has(beer, StoredBeer); ?has(money, StoredMoney); ?store(Store);
	.abolish(has(money, _)); +has(money, StoredMoney-Price); .send(Store, achieve, del(money, Price));
	.abolish(has(beer, _)); +has(beer, StoredBeer+Qtty); .send(Store, achieve, add(beer, Qtty));
	-+cost(beer, Price/Qtty).

// # COMMUNICATION SERVICE
+!doService(Answer, Ag) : not service(Answer, Service) <-
	.println("-> [", Ag, "] ", Answer);
	.send(Ag, tell, answer(Answer)).

// ####################################################################

+instantBuy(beer, Qtty, Amount) <-
	?store(Store);
	.abolish(has(beer, _)); +has(beer, StoredBeer-Qtty); .send(Store, achieve, del(beer, Qtty));
	.abolish(has(money, _)); +has(money, StoredMoney+Amount); .send(Store, achieve, add(money, Amount));
	.abolish(instantBuy(beer, _, _)).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN offerBeer
// -------------------------------------------------------------------------

+!offerBeer : supermarketInit & has(beer, Qtty) & Qtty > 0 <-
	?price(beer, Price); ?deliveryTime(butler, Time); ?cost(beer, Cost); ?deliveryCost(butler, DeliveryCost); ?paymentMoment(Moment);
	.send(tienda, tell, price(beer, Price, Cost, DeliveryCost, Time));
	if (Moment == beforeDelivery) {
		.concat("Vendo beer a ", Price, " ", DeliveryCost, " envio el pedido llega en ", Time, " pago al contado", Msg);
	} else {
		.concat("Vendo beer a ", Price, " ", DeliveryCost, " envio el pedido llega en ", Time, " pago contrarreembolso", Msg);
	}
	.println("> ", Msg);
	.send(butler, tell, msg(Msg));
	!evaluatePrice(beer).
+!offerBeer <- !offerBeer.

// ## HELPER PLAN evaluatePrice(beer)

+!evaluatePrice(beer) <-
	?currentOrderId(N); ?limit(min, reeval, price, Timeout);
	-+lastEvaluatedOrderId(N);
	.wait(Timeout);
	!calculatePrice(beer).

// ## HELPER PLAN calculatePrice(beer)

+!calculatePrice(beer) : currentOrderId(N) & lastEvaluatedOrderId(M) & N == M <- // No beers sold; price must be reduced.
	?price(beer, Price); ?cost(beer, Cost);
	if (Price > Cost+0.1 & Price-((Price-Cost)*0.5) > Cost) {
		basemath.truncate(Price-((Price-Cost)*0.5), NewPrice);
	} else {
		basemath.truncate(Cost, NewPrice);
	}
	?store(Store);
	-+price(beer, NewPrice);
	.send(Store, achieve, setPrice(beer, NewPrice));
	!offerBeer.
+!calculatePrice(beer) : currentOrderId(N) & lastEvaluatedOrderId(M) & N > M <- // Beers sold; price must be increased.
	?price(beer, Price); ?cost(beer, Cost);
	basemath.truncate(Price*1.2, NewPrice);
	?store(Store);
	-+price(beer, NewPrice);
	.send(Store, achieve, setPrice(beer, NewPrice));
	!offerBeer.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN buyBeer
// -------------------------------------------------------------------------

+!buyBeer : supermarketInit &
	has(beer, StoredQtty) & limit(min, stock, beer, Min) & StoredQtty < Min &
	not requestedPurchase(beer)
<-
	.println("> Necesito comprar mas cervezas, lo hare en la siguiente puja");
	+requestedPurchase(beer);
	!buyBeer.
+!buyBeer <- !buyBeer.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN sellBeer
// -------------------------------------------------------------------------

+!sellBeer : supermarketInit &
	currentOrderId(OrderId) & order(OrderId, Ag, beer, OrderedQtty) &
	has(beer, StoredQtty) & StoredQtty >= OrderedQtty &
	deliveryCost(Ag, Cost) & has(money, Balance) & Balance >= Cost &
	accepted(OrderId) & (paymentMoment(afterDelivery) | not pendingPayment(OrderId, _))
<-
	?store(Store); ?price(beer, Price); ?deliveryTime(Ag, Time); ?deliveryCost(Ag, Cost);
	.println("> Procesando pedido de ", OrderedQtty, " cervezas recibido de ", Ag, " (en envio)");
	.abolish(has(money, _)); +has(money, Balance-Cost);
	.send(Store, achieve, del(money, Cost));
	.abolish(has(beer, _)); +has(beer, StoredQtty-OrderedQtty);
	.send(Store, achieve, del(beer, OrderedQtty));
	deliver(beer, OrderedQtty, Time);
	basemath.truncate(OrderedQtty*Price+Cost, Amount);
	.concat("He entregado el pedido ", OrderId, " que contiene ", OrderedQtty, " cervezas, el importe asciende a ", Amount, Msg);
	.send(Ag, tell, msg(Msg));
	if (not pendingPayment(OrderId, _)) {
		.abolish(order(OrderId, _, _, _));
	}
	.abolish(accepted(OrderId));
	-+currentOrderId(OrderId+1);
	!sellBeer.
+!sellBeer : supermarketInit &
	currentOrderId(OrderId) & order(OrderId, Ag, beer, OrderedQtty) &
	has(beer, StoredQtty) & StoredQtty >= OrderedQtty &
	deliveryCost(Ag, Cost) & has(money, Balance) & Balance >= Cost &
	not accepted(OrderId)
<-
	?store(Store); ?price(beer, Price); ?deliveryTime(Ag, Time); ?deliveryCost(Ag, Cost);
	.println("> Procesando pedido de ", OrderedQtty, " cervezas recibido de ", Ag, " (aceptado)");
	basemath.truncate(OrderedQtty*Price+Cost, Amount);
	.concat("Pedido ", OrderId, " aprobado contiene ", OrderedQtty, " cervezas el importe asciende a ", Amount, " pendiente de pago", Msg);
	.send(Ag, tell, msg(Msg));
	+accepted(OrderId);
	!sellBeer.
+!sellBeer : supermarketInit &
	currentOrderId(OrderId) & order(OrderId, Ag, beer, OrderedQtty) &
	has(beer, StoredQtty) & StoredQtty < OrderedQtty &
	deliveryCost(Ag, Cost) & has(money, Balance) & Balance < Cost &
	not accepted(OrderId)
<-
	.println("> Procesando pedido de ", OrderedQtty, " cervezas recibido de ", Ag, " (sin stock)");
	-+currentOrderId(OrderId+1);
	.concat("Lo siento no puedo enviar el pedido ", OrderId, " que contiene ", OrderedQtty, " cervezas", Msg);
	.send(Ag, tell, msg(Msg));
	.abolish(order(OrderId, _, _, _));
	!sellBeer.
+!sellBeer <- !sellBeer.
