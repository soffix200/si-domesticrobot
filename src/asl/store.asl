// beliefs and rules
has(beer, 0).
has(money, 100).

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

+!del(beer,N) : has(beer, M) & M >= N <-
	?filename(Filename);
	.abolish(has(beer, _)); +has(beer, (M-N));
	.save_agent(Filename).
+!del(beer,N) : has(beer, M) & M < N <-
	?filename(Filename);
	// TODO response: not enough
	.save_agent(Filename).
+!del(money,N) : has(money, M) <-
	?filename(Filename);
	.abolish(has(money, _)); +has(money, (M-N));
	.save_agent(Filename).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN add
// -------------------------------------------------------------------------

+!add(beer,N) : has(beer, M) <-
	?filename(Filename);
	.abolish(has(beer, _)); +has(beer, (M+N));
	.save_agent(Filename).
+!add(money,N) : has(money, M) <-
	?filename(Filename);
	.abolish(has(money, _)); +has(money, (M+N));
	.save_agent(Filename).
