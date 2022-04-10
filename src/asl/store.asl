// beliefs and rules
has(beer, 0).
has(money, 100).

// -------------------------------------------------------------------------
// DEFINITION FOR substract
// -------------------------------------------------------------------------

+!del(beer,N) : has(beer, M) <- 
	-+has(beer,(M-N)); 
	.save_agent("store.asl").
+!del(beer,N) <- 
	.println("Holaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
	+has(beer,0); 
	.save_agent("store.asl").
+!del(money,N) : has(money, M) <- 
	-+has(money,(M-N)); 
	.save_agent("store.asl").

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN add
// -------------------------------------------------------------------------

+!add(beer,N) : has(beer, M) <- 
	-+has(beer, (M+N)); 
	.save_agent("store.asl").
+!add(money,N) : has(money, M) <- 
	-+has(money, (M+N)); 
	.save_agent("store.asl").
