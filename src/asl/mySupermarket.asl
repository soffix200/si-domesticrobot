// beliefs and rules
last_order_id(1).

// initial goals

!createStore.

!deliverBeer.

// plans from file: mySupermarket.asl

+!createStore <-
	.create_agent(store, "store.asl");
	.send(store, askOne, beer(N), beer(N)); // Modificar adecuadamente
	+beer(N).

+!deliverBeer : (last_order_id(N) & (orderFrom(Ag,Qtd) & beer(QtdB))) <- 
	-+last_order_id((N+1)); 
	-+beer((QtdB-Qtd)); 
	deliver(Product,Qtd); 
	.send(Ag,tell,delivered(Product,Qtd,OrderId)); // Modificar adecuadamente
	.send(store, achieve, delStore(beer,Qtd)); // Modificar adecuadamente
	-orderFrom(Ag,Qtd); 
	!deliverBeer.
+!deliverBeer <- !deliverBeer.

+!order(beer,Qtd)[source(Ag)] <- 
	+orderFrom(Ag,Qtd); 
	.println("Pedido de ",Qtd," cervezas recibido de ",Ag).

