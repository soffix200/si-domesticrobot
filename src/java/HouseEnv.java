import jaca.CartagoEnvironment;

import jason.asSyntax.*;
import jason.asSyntax.Literal;
import jason.asSyntax.Structure;               
import jason.environment.Environment;
import jason.environment.grid.Location;                               

import java.util.logging.Logger;
import java.util.List;
import java.util.LinkedList;

public class HouseEnv extends Environment {

	// common literals
	public static final Literal moveTowards  = Literal.parseLiteral("move_towards");
	public static final Literal openFridge   = Literal.parseLiteral("open(fridge)");
	public static final Literal closeFridge  = Literal.parseLiteral("close(fridge)");
	public static final Literal get          = Literal.parseLiteral("get");
	public static final Literal handBeer     = Literal.parseLiteral("hand_in(beer)");
	public static final Literal sipBeer      = Literal.parseLiteral("sip(beer)");
	public static final Literal deliverBeer  = Literal.parseLiteral("deliver(beer)");
	public static final Literal returnBeer   = Literal.parseLiteral("return(beer)");
	public static final Literal storeBeer    = Literal.parseLiteral("store(beer)");
	public static final Literal throwCan     = Literal.parseLiteral("throw(can)");
	public static final Literal recycleCan   = Literal.parseLiteral("recycle(can)");
	public static final Literal collectTrash = Literal.parseLiteral("collect(trash)");
	public static final Literal enterMap     = Literal.parseLiteral("enter(map)");
	public static final Literal exitMap      = Literal.parseLiteral("exit(map)");

	// TODO RETHINK
	public static final Literal hob  = Literal.parseLiteral("has(owner,beer)");
	public static final Literal hnob = Literal.parseLiteral("hasnot(owner,beer)");

	static Logger logger = Logger.getLogger(HouseEnv.class.getName());
	
	private CartagoEnvironment cartagoEnv;

	HouseModel model; // the model of the grid

	@Override
	public void init(String[] args) {
		model = new HouseModel();
		HouseView view  = new HouseView(model);                        
		model.setView(view);
																	   
		startCartago(args);

		clearPercepts();
		updatePercepts("butler", new LinkedList<Literal>());
		updatePercepts("owner",  new LinkedList<Literal>());
	}
	
	public void startCartago(String[] args) { 
		// String[] myargs =  {"local", "Console"};
		cartagoEnv = new CartagoEnvironment();
		cartagoEnv.init(args);
	}  
	
	/** Called before the end of MAS execution */
	@Override
	public void stop() {
		super.stop();
		if (cartagoEnv != null)
			cartagoEnv.stop();
	}

	void updatePercepts(String agent, List<Literal> literals) {
		clearPercepts(agent);

		if (agent == "butler" || agent == "owner") {
			addPercept(agent, Literal.parseLiteral("bounds("+(model.GSize-1)+","+(model.GSize-1)+")"));

			addPercept(agent, Literal.parseLiteral("location(base,"+    "position,"+model.lBase.x+    ","+model.lBase.y+    ")"));
			addPercept(agent, Literal.parseLiteral("location(owner,"+   "obstacle,"+model.lOwner.x+   ","+model.lOwner.y+   ")"));
			addPercept(agent, Literal.parseLiteral("location(fridge,"+  "obstacle,"+model.lFridge.x+  ","+model.lFridge.y+  ")"));
			addPercept(agent, Literal.parseLiteral("location(delivery,"+"position,"+model.lDelivery.x+","+model.lDelivery.y+")"));
			addPercept(agent, Literal.parseLiteral("location(dumpster,"+"obstacle,"+model.lDumpster.x+","+model.lDumpster.y+")"));
			addPercept(agent, Literal.parseLiteral("location(depot   ,"+"position,"+model.lDepot.x+   ","+model.lDepot.y+   ")"));
			addPercept(agent, Literal.parseLiteral("location(exit,"+    "position,"+model.lExit.x+    ","+model.lExit.y+    ")"));
		}

		if (agent == "owner") {
			if (model.sipCount > 0) {
				addPercept(agent, hob);
			} else {
				addPercept(agent, hnob);
			}
		}

		for (Literal lit : literals) {
			addPercept(agent, lit);
		}
	}

	@Override
	public boolean executeAction(String ag, Structure action) {
		logger.info("["+ag+"] doing: " + action);
		boolean succeed = false;
		List updatedPercepts = new LinkedList<Literal>();

		try {
			if (action.equals(openFridge)) {
				succeed = model.openFridge();
				if (succeed) {
					updatedPercepts.add(Literal.parseLiteral("stock(beer,fridge,"+model.beersInFridge+")"));
					updatePercepts(ag, updatedPercepts);
				}
			} else if (action.equals(closeFridge)) {
				succeed = model.closeFridge();
			} else if (action.equals(handBeer)) {
				succeed = model.handInBeer(ag);
				updatePercepts("owner", updatedPercepts);
			} else if (action.equals(sipBeer) && ag.equals("owner")) {
				Thread.sleep(600);
				succeed = model.sipBeer();
				updatePercepts("owner", updatedPercepts);
			} else if (action.equals(recycleCan)) {
				succeed = model.addCanToDumpster(ag);
			} else if (action.equals(collectTrash)) {
				succeed = model.getTrashFromDumpster(ag);
			} else if (action.equals(enterMap)) {
				logger.info("P1");
				logger.info(ag);
				succeed = model.enterMap(ag);
			} else if (action.equals(exitMap)) {
				succeed = model.exitMap(ag);
			} else if (action.getFunctor().equals(moveTowards.getFunctor())) {
				String agent     = action.getTerm(0).toString();
				String direction = action.getTerm(1).toString();
				succeed = model.moveTowards(agent, direction);
				updatePercepts(ag, updatedPercepts);
			} else if (action.getFunctor().equals(deliverBeer.getFunctor())) {
				if (action.getTerm(0).equals(deliverBeer.getTerm(0))) {
					int beerNumber = (int)((NumberTerm)((Structure)action).getTerm(1)).solve();
					Thread.sleep(5000);
					succeed = model.addBeersToDelivery(ag, beerNumber);
				}
			} else if (action.getFunctor().equals(returnBeer.getFunctor())) {
				if (action.getTerm(0).equals(returnBeer.getTerm(0))) {
					int beerNumber = (int)((NumberTerm)((Structure)action).getTerm(1)).solve();
					succeed = model.removeBeersFromDelivery(beerNumber);
				}
			} else if (action.getFunctor().equals(storeBeer.getFunctor())) {
				if (action.getTerm(0).equals(storeBeer.getTerm(0))) {
					if (action.getTerm(1).toString().equals("fridge")) {
						int beerNumber = (int)((NumberTerm)((Structure)action).getTerm(2)).solve();
						succeed = model.addBeersToFridge(ag, beerNumber);
					}
				}
			} else if (action.getFunctor().equals(throwCan.getFunctor())) {
				if (action.getTerm(0).equals(throwCan.getTerm(0))) {
					Location location = new Location (
						(int)((NumberTerm)((Structure)action.getTerm(1)).getTerm(0)).solve(),
						(int)((NumberTerm)((Structure)action.getTerm(1)).getTerm(1)).solve()
					);
					succeed = model.throwCan(location);
				}
			} else if (action.getFunctor().equals(get.getFunctor())) {
				if (action.getTerm(0).toString().equals("beer")) {
					if (action.getTerm(1).toString().equals("fridge")) {
						succeed = model.getBeerFromFridge(ag);
					} else if (action.getTerm(1).toString().equals("delivery")) {
						int beerNumber = (int)((NumberTerm)((Structure)action).getTerm(2)).solve();
						succeed = model.getBeersFromDelivery(ag, beerNumber);
					}
				} else if (action.getTerm(0).toString().equals("can")) {
					succeed = model.getCan(ag);
				}
			}
		} catch (Exception e) {
			logger.info("Error occurred while attempting to execute action " + action);
		}

		if (succeed)
			try { Thread.sleep(100); } catch (Exception e) {}
		else logger.info("Failed to execute action " + action);
		return succeed;
	}
}