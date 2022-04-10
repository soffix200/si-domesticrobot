// beliefs and rules
has(beer, 0).
has(money, 100).

// -------------------------------------------------------------------------
// DEFINITION FOR substract
// -------------------------------------------------------------------------

+!del(beer,N) : has(beer, M) <-
	.println("Store had ", M, " and now has ", M-N);
	.abolish(has(beer, _)); +has(beer, (M-N));
	//-+has(beer,(M-N)); 
	.save_agent("store.asl").
+!del(beer,N) <- // This seems not to be necessary
	.println("Holaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
	+has(beer,0); 
	.save_agent("store.asl").
+!del(money,N) : has(money, M) <- 
	.abolish(has(money, _)); +has(money, (M-N));
	.save_agent("store.asl").

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN add
// -------------------------------------------------------------------------

+!add(beer,N) : has(beer, M) <- 
	.abolish(has(beer, _)); +has(beer, (M+N)); 
	.save_agent("store.asl").
+!add(money,N) : has(money, M) <- 
	.abolish(has(money, _)); +has(money, (M+N)); 
	.save_agent("store.asl").
