currentOrderId(1).

cost(beer, 1). // TODO REMOVE; dependent on market
price(beer, 3).

limit(min, reeval, price, 20000).
limit(min, stock,  beer,  10).
limit(max, cost,   beer,  5).

!createStore.
!offerBeer.
!buyBeer.
!sellBeer.

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
	.send(Store, askOne, beer(BeerQtty), beer(BeerQtty));
	+has(beer, BeerQtty);
	.send(Store, askOne, money(MoneyQtty), money(MoneyQtty));
	+has(money, MoneyQtty).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN offerBeer
// -------------------------------------------------------------------------

+!offerBeer <-
	?price(beer, Price);
	.println("Ahora vendo beer a ", Price);
	.send(robot, tell, price(beer, Price));
	!evaluatePrice(beer).

// ## HELPER PLAN evaluatePrice(beer)

+!evaluatePrice(beer) <-
	?currentOrderId(N); ?limit(min, reeval, price, Timeout);
	-+lastEvaluatedOrderId(N);
	.wait(Timeout);
	!calculatePrice(beer).

// ## HELPER PLAN calculatePrice(beer)

+!calculatePrice(beer) : currentOrderId(N) & lastEvaluatedOrderId(M) & N == M <- // No beers sold; price must be reduced.
	?price(beer, Price); ?cost(beer, Cost);
	if(Price/2+1 > Cost) { // TODO this should be expressed mathematically. Take notice that may be float.
		-+price(beer, Price/2+1);
		!offerBeer;
	} else {
		if(Price-1 > Cost){
			-+price(beer, Price-1);
			!offerBeer;
		} else {
			-+price(beer, Cost);
			!evaluatePrice(beer);
		}
	}.
+!calculatePrice(beer) : currentOrderId(N) & lastEvaluatedOrderId(M) & N > M <- // Beers sold; price must be increased.
	?price(beer, Price);
	-+price(beer, Price+1);
	!offerBeer.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN buyBeer
// -------------------------------------------------------------------------

+!buyBeer : 
	has(beer, StoredQtty) & limit(min, stock, beer, Min) & StoredQtty < Min &
	not requestedPurchase(beer)
<-
	+requestedPurchase(beer);
	!buyBeer.
+!buyBeer <- !buyBeer.

// ## HELPER TRIGGERS auction

+auction(start, AuctionNum, Product, Qtty) :
	requestedPurchase(Product) &
	has(money, Balance) & Balance >= 1 &
	limit(max, cost, beer, Limit) & 1 <= Limit
<-
	.send(market, tell, placeBid(AuctionNum, 1));
	.abolish(auction, start, AuctionNum, Product, Qtty).

+auction(finish, AuctionNum, Product, Qtty, Winner, TotalPrice) : .my_name(Self) & Self == Winner <-
	?has(beer, StoredBeer); ?has(money, StoredMoney); ?store(Store);
	.abolish(has(beer, _)); +has(beer, StoredBeer+Qtty); .send(Store, achieve, add(beer, Qtty));
	.abolish(has(money, _)); +has(money, StoredMoney-TotalPrice); .send(Store, achieve, del(money, TotalPrice));
	-+cost(beer, TotalPrice/Qtty);
	.abolish(winningAuction(AuctionNum));
	.abolish(requestedPurchase(Product));
	.abolish(bid(_, AuctionNum, _, _));
	.abolish(auction(finish, AuctionNum, _, _, _, _)).
+auction(finish, AuctionNum, Product, Qtty, Winner, TotalPrice) : .my_name(Self) & Self \== Winner <-
	.abolish(winningAuction(AuctionNum));
	.abolish(bid(_, AuctionNum, _, _));
	.abolish(auction(finish, AuctionNum, _, _, _, _)).

+bid(max, AuctionNum, Bidder, Bid) : .my_name(Self) & Self == Bidder & requestedPurchase(Product)  <-
	-+winningAuction(AuctionNum).
+bid(max, AuctionNum, Bidder, Bid) :
	.my_name(Self) & Self \== Bidder &
	requestedPurchase(Product) &
	has(money, Balance) & Balance >= Bid &
	limit(max, cost, beer, Limit) & Bid+1 <= Limit
<-
	-winningAuction(Auction);
	.send(market, tell, placeBid(AuctionNum, Bid+1)).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN sellBeer
// -------------------------------------------------------------------------

+!sellBeer :
	currentOrderId(OrderId) & order(OrderId, Ag, beer, OrderedQtty) &
	has(beer, StoredQtty) & StoredQtty >= OrderedQtty
<-
	?store(Store); ?price(beer, Price);
	.println("Procesando pedido de ", OrderedQtty, " cervezas recibido de ", Ag, " (en stock)");
	-+currentOrderId(OrderId+1);
	deliver(beer, OrderedQtty);
	.abolish(has(beer, _)); +has(beer, StoredQtty-OrderedQtty);
	.send(Ag, tell, delivered(OrderId, beer, OrderedQtty, OrderedQtty*Price));
	.send(Store, achieve, del(beer, OrderedQtty));
	.abolish(order(OrderId, _, _, _));
	!sellBeer.
+!sellBeer :
	currentOrderId(OrderId) & order(OrderId, Ag, beer, OrderedQtty) &
	has(beer, StoredQtty) & StoredQtty < OrderedQtty
<-
	.println("Procesando pedido de ", OrderedQtty, " cervezas recibido de ", Ag, " (rechazado)");
	-+currentOrderId(OrderId+1);
	.send(Ag, tell, notEnough(OrderId, beer, OrderedQtty));
	.abolish(order(OrderId, _, _, _));
	!sellBeer.
+!sellBeer <- !sellBeer.

// ## HELPER TRIGGER order

+order(Product, Qtty)[source(Ag)] <-
	.println("Pedido de ", Qtty, " ", Product, " recibido de ", Ag);
	?currentOrderId(OrderId);
	+order(OrderId, Ag, Product, Qtty);
	.abolish(order(Product, Qtty)[source(Ag)]).

// ## HELPER TRIGGER pay

+pay(TotalPrice)[source(Ag)] : has(money,Qtd) <-
	?store(Store);
	.println("Pago de ", TotalPrice, " recibido de ", Ag);
	.abolish(has(money, _)); +has(money, Qtd+TotalPrice);
	.send(Store, achieve, add(money,TotalPrice)).

+reject(OrderId)[source(Ag)] : order(OrderId, Ag, Product, Qtty) <-
	return(Product, Qtty);
	.abolish(order(OrderId, Ag, Product, Qtty)).
