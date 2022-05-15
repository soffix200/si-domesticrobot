location(beer, fridge).

// --------------------------------------------------------------------

+msg(M)[source(butler)] <-
  .println("He recibido un mensaje de butler");
  if (M == "Lleva beer a owner") {
    !bring(beer, owner);
  }
  .abolish(msg(M)[source(butler)]).

// --------------------------------------------------------------------

+!bring(Product, Agent) : location(Product, Storage) <-
  !check(Product, Storage);
  !take(Product, Storage, Agent);

+!check(Product, Storage) <-
  !go_at(Storage);
  .println("Bringer está en ", Storage);
  open(Storage);
  .println("Bringer ha abierto ", Storage).

+!take(Product, Storage, Agent) : available(Product, Storage) <-
  get(Product);
  .println("Bringer ha cogido ", Product);
  close(Storage);
  .println("Bringer ha cerrado ", Storage).
  !go_at(Agent);
  .println("Bringer está con ", Agent);
  hand_in(Product);
  .println("Bringer ha entregado ", Product, " a ", Agent).
  .concat("He entregado ", Product, " a ", Agent);
	.send(butler, tell, msg(M).
+!take(Product, Storage, Agent) : not available(Product, Storage) <-
  .println("Bringer ha comprobado que no queda ", Product);
  close(Storage);
  .println("Bringer ha cerrado ", Storage).
  .concat("No queda ", Product, M);
  .send(butler, tell, msg(M)).

// --------------------------------------------------------------------

+stock(beer, 0) : available(beer,fridge) <-
	-available(beer, fridge).
+stock(beer, N) : N > 0 & not available(beer,fridge) <-
	-+available(beer, fridge).

+!go_at(P) : .my_name(Robot) & at(Robot, P) <- true.
+!go_at(P) : .my_name(Robot) & not at(Robot, P) <-
  move_towards(P);
  !go_at(P).