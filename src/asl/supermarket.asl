currentOrderId(1).

buyBatch(beer, 10).
minBatch(beer, 10).

cost(beer, 1). // TODO REMOVE; dependent on market
price(beer, 3).

!offerBeer.
!buyBeer.
!sellBeer.
!createStore.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN createStore
// -------------------------------------------------------------------------

+!createStore <-
	.create_agent(store, "store.asl");
	.wait(1000);
	.send(store, askOne, has(beer, N), has(beer, N));
	//.send(store, askOne, has(beer, N));
	+has(beer, N);
	.send(store, askOne, has(money, N), has(money, N));
	+has(money, N).

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
	.abolish(has(beer, _)); +has(beer, StoredQtty+BatchQtty); .send(store, achieve, add(beer,BatchQtty));
	.abolish(has(money, _)); +has(money, Balance-Cost*BatchQtty); .send(store, achieve, del(money,Cost*BatchQtty));
	!buyBeer.
+!buyBeer <- !buyBeer.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN sellBeer
// -------------------------------------------------------------------------

+!sellBeer :
	currentOrderId(OrderId) & order(OrderId, Ag, beer, OrderedQtty) &
	has(beer, StoredQtty) & StoredQtty >= OrderedQtty
<-
	.println("Procesando pedido de ", OrderedQtty, " cervezas recibido de ", Ag, " (en stock)");
	-+currentOrderId(OrderId+1);
	deliver(beer, OrderedQtty);
	.abolish(has(beer, _)); +has(beer, StoredQtty-OrderedQtty);
	?price(beer, Price);
	.send(Ag, tell, delivered(OrderId, beer, OrderedQtty, OrderedQtty*Price));
	.send(store, achieve, del(beer,Qtd));
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
	.println("Pago de ", TotalPrice, " recibido de ", Ag);
	-+has(money,Qtd+TotalPrice);
	 .send(store, achieve, add(money,TotalPrice)).