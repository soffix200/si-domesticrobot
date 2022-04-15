time(auction,    10000).  // Time between auctions will be 10s
time(bid,        1000).   // Time between bids will be 1s.

auction(0, beer, 10).

!auction.

// -------------------------------------------------------------------------
// DEFINITION FOR PLAN auction
// -------------------------------------------------------------------------

+!auction : not auctionInProgress <-
  ?auction(AuctionNum, Product, Qtty); ?time(bid, Delay);
	+auctionInProgress;
  +numBids(AuctionNum, 0);
  +bids(AuctionNum, []);
	.println("Comenzará la subasta ", AuctionNum, " (", Product, "x", Qtty, ")");
  .broadcast(tell, auction(start, AuctionNum, Product, Qtty));
  .wait(Delay*2);
  !auction.
+!auction :
  auctionInProgress & auction(AuctionNum, Product, Qtty) & numBids(AuctionNum, LastNumBids) &
  .findall(Value, placeBid(AuctionNum, Value), BidValuesList) & .length(BidValuesList, CurrentNumBids) & CurrentNumBids > LastNumBids
<-
  ?time(bid, BidTime);
  .max(BidValuesList, Max);
  ?placeBid(AuctionNum, Max)[source(Winner)];
  -+winner(AuctionNum, Winner, Max);
  -+numBids(AuctionNum, CurrentNumBids);
  .println("La puja máx alta para la subasta ", AuctionNum, " (", Product, "x", Qtty, ") es de ", Winner, " por ", Max);
  .broadcast(tell, bid(max, AuctionNum, Winner, Max));
  .wait(BidTime);
  !auction.
+!auction :
  auctionInProgress & auction(AuctionNum, Product, Qtty) & numBids(AuctionNum, LastNumBids) &
  .findall(Value, placeBid(AuctionNum, Value), BidValuesList) & .length(BidValuesList, CurrentNumBids) & CurrentNumBids <= LastNumBids &
  winner(AuctionNum, Winner, Value)
<-
  ?time(auction, Cd);
  -bids(AuctionNum, Bids);
  -winner(AuctionNum, Winner, Value);
  -+auction(AuctionNum+1, Product, Qtty);
  .abolish(placeBid(AuctionNum, _, _));
	.print("El ganador de la subasta ", AuctionNum, " es ", Winner);
  .broadcast(tell, auction(finish, AuctionNum, Product, Qtty, Winner, Value));
  .wait(Cd);
	-auctionInProgress;
  !auction.
+!auction :
  auctionInProgress & auction(AuctionNum, Product, Qtty) & numBids(AuctionNum, LastNumBids) &
  .findall(Value, placeBid(AuctionNum, Value), BidValuesList) & .length(BidValuesList, CurrentNumBids) & CurrentNumBids <= LastNumBids &
  not winner(AuctionNum, Winner, Value)
<-
  ?time(auction, Cd);
	.println("Subasta terminada. No se recibieron pujas");
  -+auction(AuctionNum+1, Product, Qtty);
  .abolish(placeBid(AuctionNum, _, _));
  .wait(Cd);
	-auctionInProgress;
  !auction.