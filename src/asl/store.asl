beer(0).
money(100).

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
