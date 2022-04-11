//REMEMBER TO DELETE TEMP IF THIS FILE IS CHANGED
// Beliefs and rules
has(money, 50).

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
	.abolish(has(money, _)); 
	+has(money, (M+N));
	.save_agent(Filename).
+!add(paid,YY,MM,DD,DailyPayout) <-
	?filename(Filename);
	+paid(YY,MM,DD, DailyPayout);
	.save_agent(Filename).