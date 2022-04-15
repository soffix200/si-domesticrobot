// REMEMBER TO DELETE TMP IF THIS FILE IS CHANGED

has(money, 50).
lastPension(0, 0).

mood(owner, despierto).
sipMoodCount(owner, 0).

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
