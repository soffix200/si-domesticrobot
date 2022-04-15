// REMEMBER TO DELETE TMP IF THIS FILE IS CHANGED

has(money, 50).

!initStore.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN initStore
// -------------------------------------------------------------------------

+!initStore <-
	.my_name(StoreName);
	.concat("./tmp/", StoreName, ".asl", Filename);
	+filename(Filename).

+!remember(Belief) <- 
	?filename(Filename);
	-+Belief;
	.save_agent(Filename).
