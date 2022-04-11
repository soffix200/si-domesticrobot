currentOrderId(1).

buyBatch(beer, 10).
minBatch(beer, 10).

cost(beer, 1). // TODO REMOVE; dependent on market
price(beer, 3).

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
	.send(Store, askOne, has(beer, X), BeerResponse);
	+BeerResponse;
	.send(Store, askOne, has(money, X), MoneyResponse);
	+MoneyResponse.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN offerBeer
// -------------------------------------------------------------------------

+!offerBeer <-
	?price(beer, Price);
	.send(robot, tell, price(beer, Price)).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN buyBeer
// -------------------------------------------------------------------------

+!buyBeer :
	has(beer, StoredQtty) & minBatch(beer, Min) & StoredQtty < Min &
	has(money, Balance) & cost(beer, Cost) & minBatch(beer, BatchQtty) & Amount >= Cost*BatchQtty
<-
	?store(Store);
	.abolish(has(beer, _)); +has(beer, StoredQtty+BatchQtty); .send(Store, achieve, add(beer,BatchQtty));
	.abolish(has(money, _)); +has(money, Balance-Cost*BatchQtty); .send(Store, achieve, del(money,Cost*BatchQtty));
	!buyBeer.
+!buyBeer <- !buyBeer.

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
	-order(OrderId, _, _, _);
	!sellBeer.
+!sellBeer :
	currentOrderId(OrderId) & order(OrderId, Ag, beer, OrderedQtty) &
	has(beer, StoredQtty) & StoredQtty < OrderedQtty
<-
	.println("Procesando pedido de ", OrderedQtty, " cervezas recibido de ", Ag, " (rechazado)");
	-+currentOrderId(OrderId+1);
	.send(Ag, tell, notEnough(OrderId, beer, OrderedQtty));
	-order(OrderId, _, _, _);
	!sellBeer.
+!sellBeer <- !sellBeer.

+order(Product, Qtty)[source(Ag)] <-
	.println("Pedido de ", Qtty, " ", Product, " recibido de ", Ag);
	?currentOrderId(OrderId);
	+order(OrderId, Ag, Product, Qtty);
	.abolish(order(Product, Qtty)[source(Ag)]).

// -------------------------------------------------------------------------
// DEFINITION FOR receive the money
// -------------------------------------------------------------------------

+pay(TotalPrice)[source(Ag)] : has(money,Qtd) <-
	?store(Store);
	.println("Pago de ", TotalPrice, " recibido de ", Ag);
	.abolish(has(money, _)); +has(money, Qtd+TotalPrice);
	.send(Store, achieve, add(money,TotalPrice)).