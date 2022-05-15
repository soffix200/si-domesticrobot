// TODO participación en subasta en lugar de costes estáticos
// TODO comunicación en lenguaje natural
// TODO competencia entre supermercados
// TODO alianzas comerciales entre supermercados
// TODO traciones a las alianzas comerciales
// TODO pensar como guardar el estado de un agente generado proceduralmente a disco (no parece posible)

/* Initial beliefs and rules */

last_order_id(1).
has(money, 100).

has(beer, 0).
minimum(beer, 10).
buySize(beer, 10).
cost(beer, 2).
price(beer, 3).

enoughStored(P, OrderedQtd) :-
	has(P, StoredQtd) &
	StoredQtd >= OrderedQtd.

/* Initial goals */

!tellPrices.
!buyBeer.
!deliverBeer.

/* Plans */

+!buyBeer : 
	has(beer, StoredQtd) &
	minimum(beer, Min) &
	StoredQtd < Min &
	cost(beer, Cost) &
	has(money, Amount) &
	buySize(beer, Qtd) &
	Amount > Cost*Qtd
<-
	-+stored(beer, StoredQtd + Qtd);
	-+has(money, Amount - Cost*Qtd);
	!buyBeer.
+!buyBeer <- !buyBeer.

+!tellPrices : price(beer, Price) <-
	.send(butler, tell, price(beer, Price)).

+!deliverBeer : orderFrom(Ag, Qtd) & enoughStored(beer, Qtd) & lastOrderId(N) & stored(beer, StoredQtd) <-
	.println("Pedido de ", Qtd, " cervezas recibido de ", Ag, " (en stock)");
	OrderId = N+1; 
	-+lastOrderId(OrderId);
	deliver(beer, Qtd);
	.send(Ag, tell, delivered(beer, Qtd, OrderId));
	-+has(beer, StoredQtd - Qtd);
	-orderFrom(Ag, Qtd);
	!deliverBeer.
+!deliverBeer : orderFrom(Ag, Qtd) & not enoughSored(beer, Qtd) & stored(beer, StoredQtd) <-
	.println("Pedido de ", Qtd, " cervezas recibido de ", Ag, " (rechazado)");
	.send(Ag, tell, notEnough(beer, StoredQtd));
	-orderFrom(Ag, Qtd);
	!deliverBeer.
+!deliverBeer <- !deliverBeer.

+!pay(Amount) : has(money, Qtd) <-
	.println("Pago de ", Amount, "u.m. recibido.");
	-+has(money, Qtd+Amount).
	
+!reject(beer, Qtd) : stored(beer, StoredQtd) <-
	.println("Pedido de ", Qtd, " cervezas devuelto.");
	reject(beer, Qtd);
	-+stored(beer, StoredQtd + Qtd).
	
+!order(beer, Qtd)[source(Ag)] <- 
	.println("Pedido de ", Qtd, " cervezas recibido de ", Ag);
	+orderFrom(Ag, Qtd).