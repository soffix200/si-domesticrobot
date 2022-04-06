/* Initial beliefs and rules */

/* Initial goals */

!drink(beer). 

!bored.

!setupTool("Owner", "Robot").

/* Plans */

// if I have not beer finish, in other case while I have beer, sip

+!setupTool(Name, Id)
	<- 	makeArtifact("GUI","gui.Console",[],GUI);
		setBotMasterName(Name);
		setBotName(Id);
		focus(GUI). 
		
+say(Msg) <-
	.println("Owner esta aburrido y desde la consola le dice ", Msg, " al Robot");
	.send(robot,tell,msg(Msg)).
	
+!bored <-
	.println("Owner esta aburrido y le dice Hola al Robot");
	.send(robot,tell,msg("Hola")).

+!drink(beer) : ~couldDrink(beer) <-
	.println("Owner ha bebido demasiado por hoy.").	
+!drink(beer) : has(owner,beer) & asked(beer) <-
	.println("Owner va a empezar a beber cerveza.");
	-asked(beer);
	sip(beer);
	!drink(beer).
+!drink(beer) : has(owner,beer) & not asked(beer) <-
	sip(beer);
	.println("Owner está bebiendo cerveza.");
	!drink(beer).
+!drink(beer) : not has(owner,beer) & not asked(beer) <-
	.println("Owner no tiene cerveza.");
	!get(beer);
	!drink(beer).
+!drink(beer) : not has(owner,beer) & asked(beer) <- 
	.println("Owner está esperando una cerveza.");
	.wait(5000);                                                                          
	!drink(beer).
	                                                                                                         
+!get(beer) : not asked(beer) <-
	.send(robot, achieve, bring(owner,beer)); //modificar adecuadamente
	//.send(robot, tell, msg("Necesito urgentemente una cerveza"));
	.println("Owner ha pedido una cerveza al robot.");
	+asked(beer).                                                                              

//Esta regla debe modificarse adecuadamente
+msg(M)[source(Ag)] <- 
	.print("Message from ",Ag,": ",M);
	+~couldDrink(beer);
	-msg(M).

+answer(Request) <-
	.println("El Robot ha contestado: ", Request);
	show(Request).
	
-answer(What) <- .println("He recibido desde el robot: ", What).
