currentOrderId(1).

has(beer,  0).
has(money, 100).

buyBatch(beer, 10).
minBatch(beer, 10).

cost(beer, 1). // TODO REMOVE; dependent on market
price(beer, 3).

!offerBeer.
!buyBeer.
!sellBeer.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN offerBeer
// -------------------------------------------------------------------------

+!offerBeer : price(beer, Price) <-
	.send(robot, tell, price(beer, Price)).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN buyBeer
// -------------------------------------------------------------------------

+!buyBeer :
	has(beer, StoredQtty) & minBatch(beer, Min) & StoredQtty < Min &
	has(money, Balance) & cost(beer, Cost) & minBatch(beer, BatchQtty) & Amount >= Cost*BatchQtty
<-
	-+has(beer, StoredQtty+BatchQtty);
	-+has(money, Balance-Cost*BatchQtty);
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
	-+has(beer, StoredQtty-OrderedQtty);
	.send(Ag, tell, delivered(OrderId, beer, OrderedQtty));
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