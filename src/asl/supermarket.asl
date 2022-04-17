currentOrderId(1).

cost(beer, 2).

limit(min, reeval, price, 20000).
limit(min, stock,  beer,  10).
limit(max, cost,   beer,  5).

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
	basemath.truncate(X*5,  Cost);
	+deliveryTime(butler, Time);
	+deliveryCost(butler, Cost);
	.send(Store, achieve, addDeliveryTime(butler, Time));
	.send(Store, achieve, addDeliveryCost(butler, Cost)).
+!setDeliveryTime(_) <- true.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN dialog
// -------------------------------------------------------------------------

+!dialog : supermarketInit & msg(Msg)[source(Ag)] <-
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
	?currentOrderId(OrderId);
	+order(OrderId, Ag, Product, Qtty).

// # ORDER SERVICE
+!doService(Query, Ag) : service(Query, order) & filter(Query, order, [rejected, OrderId]) <-
	.println("Pedido ", OrderId, " rechazado por ", Ag);
	return(Product, Qtty).
+!doService(Query, Ag) : service(Query, order) & filter(Query, order, [received, OrderId]) <-
	.println("Pedido ", OrderId, " recibido por ", Ag).

// # PAY SERVICE
+!doService(Query, Ag) : service(Query, pay) & filter(Query, pay, [Amount]) <-
	.println("Pago de ", Amount, " recibido de ", Ag);
	?store(Store); ?has(money, Balance);
	.abolish(has(money, _)); +has(money, Balance+Amount);
	.send(Store, achieve, add(money, Amount)).

// # AUCTION SERVICE (START)
+!doService(Query, Ag) : service(Query, auction) & filter(Query, auction, [started, AuctionNum, Product, Qtty]) &
	requestedPurchase(Product) &
	has(money, Balance) & Balance >= 1 &
	limit(max, cost, beer, Limit) & 1 <= Limit
<-
	.println("La subasta ", AuctionNum, " ha comenzado. Pujo 1");
	.concat("Me gustaria ofertar ", 1, " en la subasta ", AuctionNum, Msg);
	.send(market, tell, msg(Msg));
	-+winningAuction(AuctionNum).
+!doService(Query, Ag) : service(Query, auction) & filter(Query, auction, [started, AuctionNum, Product, Qtty]) <-
	.println("La subasta ", AuctionNum, " ha comenzado. No participo").

// # AUCTION SERVICE (UPDATE)
+!doService(Query, Ag) : service(Query, auction) & filter(Query, auction, [update, AuctionNum, Winner, Product, Qtty, Price]) &
	requestedPurchase(Product) &
	.my_name(Self) & Self == Winner
<-
	.println("Voy ganando en la subasta ", AuctionNum);
	-+winningAuction(AuctionNum).
+!doService(Query, Ag) : service(Query, auction) & filter(Query, auction, [update, AuctionNum, Winner, Product, Qtty, Price]) &
	requestedPurchase(Product) &
	.my_name(Self) & Self \== Winner &
	has(money, Balance) & Balance >= Bid &
	limit(max, cost, beer, Limit) & Bid+1 <= Limit
<-
	-println("No voy ganando en la subasta ", AuctionNum, ". Pujo ", Bid+1);
	-winningAuction(AuctionNum);
	.concat("Me gustaria ofertar ", Bid+1, " en la subasta ", AuctionNum, Msg);
	.send(market, tell, msg(Msg));
	-+winningAuction(AuctionNum).
+!doService(Query, Ag) : service(Query, auction) & filter(Query, auction, [update, AuctionNum, Winner, Product, Qtty, Price]) &
	winningAuction(AuctionNum)
<-
	.println("Dejo de participar en la subasta ", AuctionNum);
	-winningAuction(AuctionNum).
+!doService(Query, Ag) : service(Query, auction) & filter(Query, auction, [update, AuctionNum, Winner, Product, Qtty, Price]) &
	not winningAuction(AuctionNum)
<-
	.println("Sigo sin participar en la subasta ", AuctionNum);
	-winningAuction(AuctionNum).

// # AUCTION SERVICE (FINISH)
+!doService(Query, Ag) : service(Query, auction) & filter(Query, auction, [finished, AuctionNum, Winner, Product, Qtty, Price]) &
	.my_name(Self) & Self == Winner
<-
	?has(beer, StoredBeer); ?has(money, StoredMoney); ?store(Store);
	.abolish(has(beer, _)); +has(beer, StoredBeer+Qtty); .send(Store, achieve, add(beer, Qtty));
	.abolish(has(money, _)); +has(money, StoredMoney-TotalPrice); .send(Store, achieve, del(money, TotalPrice));
	-+cost(beer, TotalPrice/Qtty);
	-winningAuction(AuctionNum);
	.abolish(requestedPurchase(Product));
	.abolish(bid(_, AuctionNum, _, _)).
+!doService(Query, Ag) : service(Query, auction) & filter(Query, auction, [finished, AuctionNum, Winner, Product, Qtty, Price]) <-
	.println("No he ganado en la subasta ", AuctionNum);
	-winningAuction(AuctionNum);
	.abolish(bid(_, AuctionNum, _, _)).

// # COMMUNICATION SERVICE
+!doService(Answer, Ag) : not service(Answer, Service) <-
	.println("-> [", Ag, "] ", Answer);
	.send(Ag, tell, answer(Answer)).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN offerBeer
// -------------------------------------------------------------------------

+!offerBeer : supermarketInit & has(beer, Qtty) & Qtty > 0 <-
	?price(beer, Price); ?deliveryTime(butler, Time); ?deliveryCost(butler, Cost);
	.concat("Vendo beer a ", Price, " ", Cost, " envio el pedido llega en ", Time, Msg);
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

+!buyBeer : 
	supermarketInit &
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

+!sellBeer :
	supermarketInit &
	currentOrderId(OrderId) & order(OrderId, Ag, beer, OrderedQtty) &
	has(beer, StoredQtty) & StoredQtty >= OrderedQtty &
	deliveryCost(Ag, Cost) & has(money, Balance) & Balance >= Cost
<-
	?store(Store); ?price(beer, Price); ?deliveryTime(Ag, Time); ?deliveryCost(Ag, Cost);
	.println("> Procesando pedido de ", OrderedQtty, " cervezas recibido de ", Ag, " (en stock)");
	-+currentOrderId(OrderId+1);
	.abolish(has(money, _)); +has(money, Balance-Cost);
	.send(Store, achieve, del(money, Cost));
	deliver(beer, OrderedQtty, Time);
	.abolish(has(beer, _)); +has(beer, StoredQtty-OrderedQtty);
	.concat("He entregado el pedido ", OrderId, " que contiene ", OrderedQtty, " cervezas, el importe asciende a ", OrderedQtty*Price+Cost, Msg);
	.send(Ag, tell, msg(Msg));
	.send(Store, achieve, del(beer, OrderedQtty));
	.abolish(order(OrderId, _, _, _));
	!sellBeer.
+!sellBeer :
	currentOrderId(OrderId) & order(OrderId, Ag, beer, OrderedQtty) &
	has(beer, StoredQtty) & StoredQtty < OrderedQtty
<-
	.println("> Procesando pedido de ", OrderedQtty, " cervezas recibido de ", Ag, " (sin stock)");
	-+currentOrderId(OrderId+1);
	.concat("Lo siento no puedo enviar el pedido ", OrderId, " que contiene ", OrderedQtty, " cervezas", Msg);
	.send(Ag, tell, msg(Msg));
	.abolish(order(OrderId, _, _, _));
	!sellBeer.
+!sellBeer <- !sellBeer.
