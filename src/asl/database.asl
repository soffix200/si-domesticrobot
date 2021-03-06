// REMEMBER TO DELETE TEMP IF THIS FILE IS CHANGED

has(money, 0).

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

+!del(money,N) : has(money, M) <-
	?filename(Filename);
	.abolish(has(money, _)); +has(money, (M-N));
	.save_agent(Filename).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN add
// -------------------------------------------------------------------------

+!add(money,N) : has(money, M) <-
	?filename(Filename);
	.abolish(has(money, _)); +has(money, (M+N));
	.save_agent(Filename).
+!add(consumed(YY,MM,DD, Product, Qtty)) <-
	?filename(Filename);
	.abolish(consumed(YY,MM,DD, Product, _)); +consumed(YY,MM,DD, Product, Qtty);
	.save_agent(Filename).