member(X,[X|_]).
member(X,[_|Xs]) :- member(X,Xs).

agent(bringer,     []).
agent(cleaner,     []).
agent(dustman,     []).
agent(receiver,    []).
agent(supermarket, []).

available(beer).
has(money, 100).

batch(beer, 10).

cheapest(Product, Provider, Price) :-
	price(Product, Provider, Price) &
	price(Product, Provider2, Price2) &
	Price <= Price2.

healthConstraint(beer, owner, "The Department of Health does not allow me to give you more than 10 beers a day! I am very sorry about that!") :-
	.date(YY,MM,DD) &
	.count(consumed(YY,MM,DD,_,_,_,beer),QtdB) &
	QtdB > 10.

// --------------------------------------------------------------------

+msg(M)[source(owner)] <-
  .println("He recibido un mensaje de owner");
  bot.chat(M,A);
  if (A == "Ahora se la llevo") { // M == "Traeme una cerveza"
    !bring(beer, owner);
  }
  .send(owner, tell, msg(A));
  .abolish(msg(M)[source(owner)]).

+msg(M)[souce(Ag)] : agent(bringer, List) & member(Ag, List) <-
  .println("He recibido un mensaje de ", Ag);
  bot.chat(M,A);
  if (A == "Recibido") { // M == "He entregado Product a Agent"
    +consumed(YY,MM,DD,HH,NN,SS, beer);
  }
  if (A == "Ahora solicito más") { // M == "No queda Product"
    -available(beer);
    !order(beer);
  }
  .send(Ag, tell, msg(A));
  .abolish(msg(M)[source(Ag)]).

+msg(M)[souce(Ag)] : agent(cleaner, List) & member(Ag, List) <-
  .println("He recibido un mensaje de ", Ag);
  bot.chat(M,A);

  .send(Ag, tell, msg(A));
  .abolish(msg(M)[source(Ag)]).

+msg(M)[souce(Ag)] : agent(dustman, List) & member(Ag, List) <-
  .println("He recibido un mensaje de ", Ag);
  bot.chat(M,A);


  .send(Ag, tell, msg(A));
  .abolish(msg(M)[source(Ag)]).

+msg(M)[souce(Ag)] : agent(receiver, List) & member(Ag, List) <-
  .println("He recibido un mensaje de ", Ag);
  bot.chat(M,A);
  if (A == "Recibido") { // M == "10 beer repuestos en el fridge"
    +available(beer);
    -ordered(beer);
  }

  .send(Ag, tell, msg(A));
  .abolish(msg(M)[source(Ag)]).

+msg(M)[souce(Ag)] <-
  .println("He recibido un mensaje de ", Ag);
  if (M == "Pedido de 10 cervezas entregado") {
    !receive(beer, Agent, 10);
  }
  .abolish(msg(M)[source(Ag)]).

// --------------------------------------------------------------------

+!bring(Product, Agent) : healthConstraint(Product, Agent, HealthMessage) <- 
  .send(Agent, tell, msg(HealthMessage)).
+!bring(Product, Agent) : not healthConstraint(Product, Agent, HealthMessage) & available(beer) & agent(bringer, Bringers) &  <- 
	.println("Llevando ", Product, " a ", Agent);
  if (Bringers == []) {
    .create_agent(bringer1, "bringer.asl");
    Bringers = [bringer1];
  }
  [Bringer|_] = Bringers;
  .concat("Lleva ", Product, " a ", Agent, M);
  .send(Bringer, tell, msg(M)).
+!bring(Product, Agent) : not healthConstraint(Product, Agent, HealthMessage) & not available(beer) <-
  .send(Agent, tell, msg("Estoy esperando un pedido, en breves se lo llevo")).

// --------------------------------------------------------------------

+!order(Product) : cheapest(Product, Provider, Price) & batch(Product, Qtty) <-
  +ordered(beer);
  .println("Haciendo un pedido de ", Qtty, " ", Product);
  .concat("Quiero encargar ", Qtty, " ", Product);
  .send(Provider, tell, msg(M));

+!receive(Product, Provider, Qtty) : price(Product, Provider, Price) & has(money, Amount) & agent(receiver, Receivers) <-
  if (Receivers == []) {
    .create_agent(receiver1, "receiver.asl");
    Receivers = [receiver1];
  }
  [Receiver|_] = Receivers;
  .concat("Recoge ", Qtty, " ", Product, M1);
  .send(Receiver, tell, msg(M1));
  .concat("Aquí tienes tu pago: ", Qtty*Price, M2);
  .send(Provider, tell, msg(M2));
  -+has(money, Amount-Qtty*Price).