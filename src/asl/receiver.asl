batch(beer, 10).

location(beer, fridge).

cheapest(Product, Provider, Price) :-
	price(Product, Provider, Price) &
	price(Product, Provider2, Price2) &
	Price <= Price2.

// --------------------------------------------------------------------

+msg(M)[source(butler)] <-
  .println("He recibido un mensaje de butler");
  if (M == "Recoge 10 cervezas") {
    !receive(beer, 10);
  }
  .abolish(msg(M)[source(butler)]).

// --------------------------------------------------------------------

+!receive(Product, Qtty) : location(Product, Storage) <-
  !go_at(delivery);
  pick(Product, Qtty);
  !go_at(Storage);
  open(Storage);
  deposit(Storage, Product, Qtty);
  close(Storage);
  .concat(Qtty, " " , Product, " repuestos en ", Storage, M);
  .send(butler, tell, msg(M)).

// --------------------------------------------------------------------

+!go_at(P) : .my_name(Robot) & at(Robot, P) <- true.
+!go_at(P) : .my_name(Robot) & not at(Robot, P) <-
  move_towards(P);
  !go_at(P).