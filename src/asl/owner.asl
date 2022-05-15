//polite(owner). // if polite, robot picks can at owner hand
trashed(can).

!drink(beer).
!trash(can).

// --------------------------------------------------------------------

+msg(M)[source(butler)] <-
  .println("He recibido un mensaje de butler");
	if (M == "The Department of Health does not allow me to give you more than 10 beers a day! I am very sorry about that!") {
		+healthConstraint.
	}
  .abolish(msg(M)[source(owner)]).

+msg(M)[source(Ag)] <-
  .println("He recibido un mensaje de un robot");
	if (M == "Vengo a recoger la lata") { // TODO
		-has(owner, can);
		-trashed(can);
	}
  .abolish(msg(M)[source(Ag)]).

// --------------------------------------------------------------------

+!drink(Beberage) : healthConstraint <-
	.println("He bebido demasiado por hoy");
	.wait(60000);
	.abolish(healthConstraint);
	!drink(Beberage).
+!drink(Beberage) : not healthConstraint & has(owner,Beberage) & asked(Beberage) <-
	.println("Voy a empezar a beber ", Beberage);
	-asked(Beberage);
	sip(Beberage);
	!drink(Beberage).
+!drink(Beberage) : not healthConstraint & has(owner,Beberage) & not asked(Beberage) <-
	.println("Estoy bebiendo ", Beberage);
	sip(Beberage);
	!drink(Beberage).
+!drink(Beberage) : not healthConstraint & not has(owner,Beberage) & asked(Beberage) <- 
	.println("Estoy esperando mi ", Beberage);
	.wait(1000);
	!drink(Beberage).
+!drink(Beberage) : not healthConstraint & not has(owner,Beberage) & not asked(Beberage) <-
	.println("No tengo ", Beberage);
	!get(Beberage);
	!drink(Beberage).

// --------------------------------------------------------------------

// TODO plantear la situación en que el propio owner se desplaza a por la bebida
+!get(Beberage) : not asked(Beberage) <-
	.println("Pido una ", Beberage);
	.concat("Tráeme una ", Beberage, M);
	.send(butler, tell, msg(M));
	+asked(Beberage).

// --------------------------------------------------------------------

// TODO plantear la situación en que el propio owner se desplaza a tirar la lata
+!trash(can) : finished(owner, beer) & not trashed(can) & polite(owner) <-
	.println("Estoy esperando a que el robot venga a por la lata vacía");
	+has(owner, can);
	.send(butler, tell, msg("Toma esta lata"));
	+trashed(can);
	!trash(can).
+!trash(can) : finished(owner, beer) & not trashed(can) & not polite(owner) <-
	.println("Tiro una lata vacía al suelo");
	throw(can);
	.send(butler, tell, msg("Recoge la lata"));
	+trashed(can);
	!trash(can).
+!trash(can) <- !trash(can).