time(auction,    10000).  // Time between auctions will be 10s
time(bid,        1000).   // Time between bids will be 1s.

auction(0, beer, 10).

// -------------------------------------------------------------------------
// SERVICE INIT AND HELPER METHODS
// -------------------------------------------------------------------------

service(Query, bid) :-
	checkTag("<bid>", Query).

checkTag(Tag, String) :-
	.substring(Tag, String).

tagValue(Tag, Query, Literal) :-
	.substring(Tag, Query, Fst) &
	.length(Tag, N) &
	.delete(0, Tag, RestTag) &
	.concat("</", RestTag, EndTag) &
	.substring(EndTag, Query, End) &
	.substring(Query, Parse, Fst+N, End) &
	.term2string(Literal, Parse).

filter(Query, bid, [AuctionNum, Amount]) :-
	tagValue("<auction-num>", Query, AuctionNum) &
	tagValue("<amount>", Query, Amount).

// -------------------------------------------------------------------------
// PRIORITIES AND PLAN INITIALIZATION
// -------------------------------------------------------------------------

!initMarket.
!dialog.
!auction.

+!initMarket <-
  !initBot;
  +marketInit.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN initBot
// -------------------------------------------------------------------------

+!initBot <-
	makeArtifact("marketBot", "bot.ChatBOT", ["marketBot"], BotId);
	focus(BotId).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN dialog
// -------------------------------------------------------------------------

+!dialog : marketInit & msg(Msg)[source(Ag)] <-
	.abolish(msg(Msg)[source(Ag)]);
	chatSincrono(Msg, Answer);
	!doService(Answer, Ag);
	!dialog.
+!dialog <- !dialog.

// -------------------------------------------------------------------------
// DEFINITION FOR ACTION SERVICES
// -------------------------------------------------------------------------

// # PAYMENT SERVICE
+!doService(Query, Ag) : service(Query, bid) & filter(Query, bid, [AuctionNum, Amount]) <-
	.println("He recibido una puja de ", Amount, " de ", Ag, " para la subasta ", AuctionNum);
  +bid(AuctionNum, Amount, Ag).

// # COMMUNICATION SERVICE
+!doService(Answer, Ag) : not service(Query, Service) <-
	.println("-> [", Ag, "] ", Answer);
	.send(Ag, tell, answer(Answer)).

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN auction
// -------------------------------------------------------------------------

+!auction : marketInit & not auctionInProgress <-
  ?auction(AuctionNum, Product, Qtty); ?time(bid, Delay);
	.println("[E] Comenzara la subasta ", AuctionNum, " (", Product, "x", Qtty, ")");
	+auctionInProgress;
  +numBids(AuctionNum, 0);
  +bids(AuctionNum, []);
  .concat("La subasta ", AuctionNum, " acaba de empezar, se subastan ", Qtty, " cervezas", Msg);
  .all_names(L);
  for (.member(Ag, L)) {
    if (.substring("supermarket", Ag)) {
      .send(Ag, tell, msg(Msg));
    }
  }
  .wait(Delay*2);
  !auction.
+!auction : marketInit &
  auctionInProgress & auction(AuctionNum, Product, Qtty) & numBids(AuctionNum, LastNumBids) &
  .findall(Value, bid(AuctionNum, Value, Bidder), BidValuesList) & .length(BidValuesList, CurrentNumBids) & CurrentNumBids > LastNumBids
<-
  ?time(bid, BidTime);
  .max(BidValuesList, Max);
  ?bid(AuctionNum, Max, Winner);
  -+winner(AuctionNum, Winner, Max);
  -+numBids(AuctionNum, CurrentNumBids);
  .println("> La puja mas alta para la subasta ", AuctionNum, " (", Product, "x", Qtty, ") es de ", Winner, " por ", Max);
  .concat("La subasta ", AuctionNum, " de ", Qtty, " cervezas ahora tiene la puja mas alta por parte de ", Winner, " que ha ofrecido ", Max, Msg);
  .all_names(L);
  for (.member(Ag, L)) {
    if (.substring("supermarket", Ag)) {
      .send(Ag, tell, msg(Msg));
    }
  }
  .wait(BidTime);
  !auction.
+!auction : marketInit &
  auctionInProgress & auction(AuctionNum, Product, Qtty) & numBids(AuctionNum, LastNumBids) &
  .findall(Value, bid(AuctionNum, Value, Bidder), BidValuesList) & .length(BidValuesList, CurrentNumBids) & CurrentNumBids <= LastNumBids &
  winner(AuctionNum, Winner, Value)
<-
  ?time(auction, Cd);
  -bids(AuctionNum, Bids);
  -winner(AuctionNum, Winner, Value);
  -+auction(AuctionNum+1, Product, Qtty);
  .abolish(bid(AuctionNum, _, _));
	.print("> El ganador de la subasta ", AuctionNum, " es ", Winner);
  .broadcast(tell, auction(finish, AuctionNum, Product, Qtty, Winner, Value));
  .concat("La subasta ", AuctionNum, " ha terminado, ", Winner, " ha comprado ", Qtty, " cervezas por un valor total de ", Value, Msg);
  .all_names(L);
  for (.member(Ag, L)) {
    if (.substring("supermarket", Ag)) {
      .send(Ag, tell, msg(Msg));
    }
  }
  .wait(Cd);
	-auctionInProgress;
  !auction.
+!auction : marketInit &
  auctionInProgress & auction(AuctionNum, Product, Qtty) & numBids(AuctionNum, LastNumBids) &
  .findall(Value, bid(AuctionNum, Value, Bidder), BidValuesList) & .length(BidValuesList, CurrentNumBids) & CurrentNumBids <= LastNumBids &
  not winner(AuctionNum, Winner, Value)
<-
  ?time(auction, Cd);
	.println("> Subasta terminada. No se recibieron pujas");
  -+auction(AuctionNum+1, Product, Qtty);
  .abolish(bid(AuctionNum, _, _));
  .wait(Cd);
	-auctionInProgress;
  !auction.
+!auction <- !auction.
