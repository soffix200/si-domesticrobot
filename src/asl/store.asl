beer(0).
money(100).

deliveryTime(butler, -1).
deliveryCost(butler, -1).

!initStore.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN initStore
// -------------------------------------------------------------------------

+!initStore <-
	.my_name(StoreName);
	.concat("./tmp/", StoreName, ".asl", Filename);
	+filename(Filename).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN substract
// -------------------------------------------------------------------------

+!del(beer,N) : beer(M) & M >= N <-
	?filename(Filename);
	-+beer(M-N);
	.save_agent(Filename).
+!del(beer,N) : beer(M) & M < N <-
	?filename(Filename);
	// TODO response: not enough
	.save_agent(Filename).
+!del(money,N) : money(M) <-
	?filename(Filename);
	-+money(M-N);
	.save_agent(Filename).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN add
// -------------------------------------------------------------------------

+!add(beer,N) : beer(M) <-
	?filename(Filename);
	-+beer(M+N);
	.save_agent(Filename).
+!add(money,N) : money(M) <-
	?filename(Filename);
	-+beer(money, M+N);
	.save_agent(Filename).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN addDeliveryTime & addDeliveryCost
// -------------------------------------------------------------------------

+!addDeliveryTime(Ag, Time) <-
	?filename(Filename);
	.abolish(deliveryTime(Ag, _)); +deliveryTime(Ag, Time);
	.save_agent(Filename).

+!addDeliveryCost(Ag, Cost) <-
	?filename(Filename);
	.abolish(deliveryCost(Ag, _)); +deliveryCost(Ag, Cost);
	.save_agent(Filename).
