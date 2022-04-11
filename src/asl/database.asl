//REMEMBER TO DELETE TEMP IF THIS FILE IS CHANGED
// Beliefs and rules
has(money, 0).

qtdConsumed(YY,MM,DD,beer,Qtd) :-
	.date(YY,MM,DD) &
	.count(consumed(YY,MM,DD,_,_,_,beer), Qtd).

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
+!add(consumed,YY,MM,DD,HH,NN,SS,beer) <-
	?filename(Filename);
	+consumed(YY,MM,DD,HH,NN,SS,beer);
	.save_agent(Filename). 