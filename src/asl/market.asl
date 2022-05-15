time(auction, 180000). // Time between auctions will be 180s
time(bid,     500).    // Time between bids will be 5s.

!startAuction(0, beer, 10).

// --------------------------------------------------------------------

+!startAuction(AuctionNum, Product, Qtty) : not auctionInProgress & time(auction, Cd) <-
	+auctionInProgress;
	.concat("Comenzará la subasta ", AuctionNum, ": ", Product, "x", Qtty);
	.println(M);
	.broadcast(tell, msg(M));
	.wait(Cd).
	!startAuction(AuctionNum+1, Product, Qtty).
+!startAuction(AuctionNum, Product, Qtty) : auctionInProgress <-
	!startAuction(AuctionNum, Product, Qtty).

+placeBid(AuctionNum, Bid)[source(Bidder)] :
	time(bid, Cd) &
	.findall(bid(Value, Agent), placeBid(AuctionNum, Value)[source(Agent)], List) &
	.max(List, bid(Value, Winner)) &
	.length(List, NumBids) &
	Winner == Bidder
<-
	.println("La puja de ", Bidder, " por valor de ", Bid, " ha sido registrada");
	+waiting(NumBids);
	.send(Bidder, tell, msg("Tu puja ha sido registrada"));
	.concat(Bidder, " ha pujado ", Value, M);
	.broadcast(tell, msg(M));
	.wait(Cd);
	-waiting(NumBids);
	!releaseAuctionResult;
+placeBid(AuctionNum, Bid)[source(Bidder)] :
	.findall(bid(Value, Agent), placeBid(AuctionNum, Value)[source(Agent)], List) &
	.max(List, bid(Value, Winner)) &
	.length(List, NumBids) &
	Winner != Bidder
<-
	.println("La puja de ", Bidder, " por valor de ", Bid, " no es lo suficientemente elevada");
	.abolish(placeBid(AuctionNum, Bid)[source(Bidder)]);
	.send(Bidder, tell, msg("Tu puja es demasiado baja"));

+!releaseAuctionResult :
	.findall(waiting(N), waiting(N), List) &
	.length(List, NumAwaits) & NumAwaits > 0
<-
	.println("Esperando recibir más pujas...").
+!releaseAuctionResult :
	.findall(waiting(N), waiting(N), AwaitList) &
	.length(AwaitList, NumAwaits) & NumAwaits == 0 &
	.findall(bid(Value, Agent), placeBid(AuctionNum, Value)[source(Agent)], BidList) &
	.length(BidList, Count) & Count == 0 &
<-
	-auctionInProgress;
	.println("Subasta terminada. No se recibieron pujas").
+!releaseAuctionResult :
	.findall(waiting(N), waiting(N), AwaitList) &
	.length(AwaitList, NumAwaits) & NumAwaits == 0 &
	.findall(bid(Value, Agent), placeBid(AuctionNum, Value)[source(Agent)], BidList) &
	.length(BidList, Count) & Count > 0 &
<-
	-auctionInProgress;
	.max(BidList, bid(Value, Winner));
	.concat("El ganador de la subasta ", AuctionNum, " es ", Winner, M);
	.print(M);
	.broadcast(tell, msg(M));
	.abolish(placeBid(AuctionNum,_)).