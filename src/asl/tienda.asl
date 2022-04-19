currentOrderId(1).

cost(beer, 2).

//paymentMoment(beforeDelivery | afterDelivery). // If not set here, defined randomly. If set, must delete "!setPaymentMoment;"

limit(min, reeval, price, 20000).
limit(min, stock,  beer,  10).
limit(max, cost,   beer,  3).

fastest(Provider, Product, Price, Cost, DeliveryCost, Time) :-
	price(Provider, Product, Price, Cost, DeliveryCost, Time) &
	not (price(Provider2, Product, Price2, Cost2, DeliveryCost2, Time2) & Provider2 \== Provider & Time > Time2).

// -------------------------------------------------------------------------
// SERVICE INIT AND HELPER METHODS
// -------------------------------------------------------------------------

service(Query, buy) :-
	checkTag("<buy>", Query).
service(Query, order) :-
	checkTag("<order>", Query).
service(Query, pay) :-
	checkTag("<pay>", Query).

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

// -------------------------------------------------------------------------
// PRIORITIES AND PLAN INITIALIZATION
// -------------------------------------------------------------------------

!initSupermarket.
!dialog.
!sellBeer.

+!initSupermarket <-
	!initBot;
	+tiendaInit.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN initBot
// -------------------------------------------------------------------------

+!initBot <-
	.my_name(Name); .concat(Name, "Bot", BotName);
	makeArtifact(BotName, "bot.ChatBOT", ["supermarketBot"], BotId);
	focus(BotId).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN dialog
// -------------------------------------------------------------------------

+!dialog : tiendaInit & msg(Msg)[source(Ag)] <-
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
	?currentOrderId(OrderId);
	.findall(Provider, price(Provider, beer, _, _, _, _), ProviderList);
	.length(ProviderList, NumProviders);
	basemath.floor(Qtty/(NumProviders), AssignedQtty);
	RemainingQtty = Qtty - (AssignedQtty*(NumProviders-1));
	-+totalPrice(0);
	for (.member(Provider, ProviderList)) {
		?price(Provider, beer, Price, _, _, _);
		?totalPrice(T1);
		-+totalPrice(T1 + AssignedQtty*Price);
	}
	?fastest(FastestProvider, beer, FastestPrice, _, FastestDeliveyCost, _);
	?totalPrice(T2);
	-+totalPrice(T2 + (RemainingQtty - AssignedQtty)*FastestPrice + FastestDeliveyCost);
	?totalPrice(TotalPrice);
	basemath.truncate(TotalPrice, PendingPayment);
	+pendingPayment(OrderId, PendingPayment);
	+order(OrderId, Ag, Product, Qtty).

// # ORDER SERVICE
+!doService(Query, Ag) : service(Query, order) & filter(Query, order, [rejected, OrderId]) <-
	?order(OrderId, Ag, Product, Qtty);
	.println("Pedido ", OrderId, " rechazado por ", Ag);
	.abolish(order(OrderId, _, _, _));
	.abolish(accepted(OrderId));
	.abolish(pendingPayment(OrderId, _)).
+!doService(Query, Ag) : service(Query, order) & filter(Query, order, [received, OrderId]) <-
	.println("Pedido ", OrderId, " recibido por ", Ag).

// # PAY SERVICE
+!doService(Query, Ag) : service(Query, pay) & filter(Query, pay, [Amount]) &
	pendingPayment(OrderId, Amount)
<-
	.println("Pago de ", Amount, " recibido de ", Ag);
	.abolish(pendingPayment(OrderId, Amount)).
+!doService(Query, Ag) : service(Query, pay) & filter(Query, pay, [Amount]) &
	not pendingPayment(OrderId, Amount)
<-
	?pendingPayment(OrderId, TEST);
	.println("Pago de ", Amount, " recibido de ", Ag, " (invalido)", "!", TEST);
	.concat("El pago no es valido, te devuelvo tus ", Amount, Msg);
	.send(Ag, tell, msg(Msg)).

// # COMMUNICATION SERVICE
+!doService(Answer, Ag) : not service(Answer, Service) <-
	.println("-> [", Ag, "] ", Answer);
	.send(Ag, tell, answer(Answer)).

// #########################################################################

+price(Product, Price, Cost, DeliveryCost, Time)[source(Provider)] <-
	.abolish(price(Provider, _, _, _, _, _));
	+price(Provider, Product, Price, Cost, DeliveryCost, Time);
	.abolish(price(_, _, _, _, _)).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN sellBeer
// -------------------------------------------------------------------------

+!sellBeer : tiendaInit &
	currentOrderId(OrderId) & order(OrderId, Ag, beer, OrderedQtty) &
	accepted(OrderId) & not pendingPayment(OrderId, _)
<-
	.println("> Procesando pedido de ", OrderedQtty, " cervezas recibido de ", Ag, " (en envio)");
	.findall(Provider, price(Provider, beer, _, _, _, _), ProviderList);
	.length(ProviderList, NumProviders);
	basemath.floor(OrderedQtty/(NumProviders), AssignedQtty);
	RemainingQtty = OrderedQtty - (AssignedQtty*(NumProviders-1));
	-+totalPrice(0);
	for (.member(Provider, ProviderList)) {
		?price(Provider, beer, Price, _, _, _);
		?totalPrice(T1);
		-+totalPrice(T1 + AssignedQtty*Price);
	}
	?fastest(FastestProvider, beer, FastestPrice, _, FastestDeliveyCost, FastestTime);
	?totalPrice(T2);
	-+totalPrice(T2 + (RemainingQtty - AssignedQtty)*FastestPrice + FastestDeliveyCost);
	?totalPrice(TotalPrice);
	basemath.truncate(TotalPrice, PriceToPay);
	for (.member(Provider, ProviderList)) {
		.println(ProviderList);
		if (Provider \== FastestProvider) {
			.println("Compro ", AssignedQtty, " ", beer, " a ", Provider);
			.send(Provider, tell, instantBuy(beer, AssignedQtty, PriceToPay*AssignedQtty/OrderedQtty));
		} else {
			.println("Compro ", RemainingQtty, " ", beer, " a ", Provider);
			.send(Provider, tell, instantBuy(beer, RemainingQtty, PriceToPay*RemainingQtty/OrderedQtty));
		}
	}
	deliver(beer, OrderedQtty, FastestTime);
	.concat("He entregado el pedido ", OrderId, " que contiene ", OrderedQtty, " cervezas, el importe asciende a ", PriceToPay, Msg);
	.send(Ag, tell, msg(Msg));
	.abolish(order(OrderId, _, _, _));
	.abolish(accepted(OrderId));
	-+currentOrderId(OrderId+1);
	!sellBeer.
+!sellBeer : tiendaInit &
	currentOrderId(OrderId) & order(OrderId, Ag, beer, OrderedQtty) &
	not accepted(OrderId)
<-
	.println("> Procesando pedido de ", OrderedQtty, " cervezas recibido de ", Ag, " (aceptado)");
	.findall(Provider, price(Provider, beer, _, _, _, _), ProviderList);
	.length(ProviderList, NumProviders);
	basemath.floor(OrderedQtty/(NumProviders), AssignedQtty);
	RemainingQtty = OrderedQtty - (AssignedQtty*(NumProviders-1));
	-+totalPrice(0);
	for (.member(Provider, ProviderList)) {
		?price(Provider, beer, Price, _, _, _);
		?totalPrice(T1);
		-+totalPrice(T1 + AssignedQtty*Price);
	}
	?fastest(FastestProvider, beer, FastestPrice, _, FastestDeliveyCost, _);
	?totalPrice(T2);
	-+totalPrice(T2 + (RemainingQtty - AssignedQtty)*FastestPrice + FastestDeliveyCost);
	?totalPrice(TotalPrice);
	basemath.truncate(TotalPrice, PriceToPay);
	.concat("Pedido ", OrderId, " aprobado contiene ", OrderedQtty, " cervezas el importe asciende a ", PriceToPay, " pendiente de pago", Msg);
	.send(Ag, tell, msg(Msg));
	+accepted(OrderId);
	!sellBeer.
+!sellBeer <- !sellBeer.
