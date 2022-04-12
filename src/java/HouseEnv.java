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
	public static final Literal of   = Literal.parseLiteral("open(fridge)");
	public static final Literal clf  = Literal.parseLiteral("close(fridge)");
	public static final Literal gb   = Literal.parseLiteral("get(beer, fridge)");
	public static final Literal hb   = Literal.parseLiteral("hand_in(beer)");
	public static final Literal sb   = Literal.parseLiteral("sip(beer)");
	public static final Literal tc   = Literal.parseLiteral("throw(can)");
	public static final Literal gc   = Literal.parseLiteral("get(can)");
	public static final Literal rc   = Literal.parseLiteral("recycle(can)");
	public static final Literal ct   = Literal.parseLiteral("collect(trash)");

	// TODO RETHINK
	public static final Literal hob  = Literal.parseLiteral("has(owner,beer)");
	public static final Literal hnob = Literal.parseLiteral("hasnot(owner,beer)");

	public static final Literal ab   = Literal.parseLiteral("at(robot,base)");
	public static final Literal ao   = Literal.parseLiteral("at(robot,owner)");
	public static final Literal af   = Literal.parseLiteral("at(robot,fridge)");
	public static final Literal adel = Literal.parseLiteral("at(robot,delivery)");
	public static final Literal adu  = Literal.parseLiteral("at(robot,dumpster)");
	public static final Literal adep = Literal.parseLiteral("at(robot,depot)");
	public static final Literal ae   = Literal.parseLiteral("at(robot,exit)");
	public static final Literal ac   = Literal.parseLiteral("at(robot,can)");

	public static final Literal enm  = Literal.parseLiteral("enter(map)");
	public static final Literal exm  = Literal.parseLiteral("exit(map)");

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
		updatePercepts("robot", new LinkedList<Literal>());
		updatePercepts("owner", new LinkedList<Literal>());
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

		if (agent == "robot" || agent == "owner") {
			addPercept(agent, Literal.parseLiteral("bounds("+(model.GSize-1)+","+(model.GSize-1)+")"));

			addPercept(agent, Literal.parseLiteral("location(base,"+    "position,"+model.lBase.x+    ","+model.lBase.y+    ")"));
			addPercept(agent, Literal.parseLiteral("location(owner,"+   "obstacle,"+model.lOwner.x+   ","+model.lOwner.y+   ")"));
			addPercept(agent, Literal.parseLiteral("location(fridge,"+  "obstacle,"+model.lFridge.x+  ","+model.lFridge.y+  ")"));
			addPercept(agent, Literal.parseLiteral("location(delivery,"+"position,"+model.lDelivery.x+","+model.lDelivery.y+")"));
			addPercept(agent, Literal.parseLiteral("location(dumpster,"+"obstacle,"+model.lDumpster.x+","+model.lDumpster.y+")"));
			addPercept(agent, Literal.parseLiteral("location(depot   ,"+"position,"+model.lDepot.x+   ","+model.lDepot.y+   ")"));
			addPercept(agent, Literal.parseLiteral("location(exit,"+    "position,"+model.lExit.x+    ","+model.lExit.y+    ")"));
		}

		if (agent == "robot") {
			Location lRobot = model.getAgPos(model.ROBOT);
			addPercept(agent, Literal.parseLiteral("at(robot,"+lRobot.x+","+lRobot.y+")"));

			if (model.atBase)     addPercept(agent, ab);
			if (model.atOwner)    addPercept(agent, ao);
			if (model.atFridge)   addPercept(agent, af);
			if (model.atDelivery) addPercept(agent, adel);
			if (model.atDumpster) addPercept(agent, adu);
			if (model.atDepot)    addPercept(agent, adep);
			if (model.atExit)     addPercept(agent, ae);
			if (model.atCan)      addPercept(agent, ac);
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
		System.out.println("["+ag+"] doing: " + action);

		boolean succeed = false;

		if (action.equals(of)) {
			succeed = model.openFridge();
			if (succeed) {
				addPercept(ag, Literal.parseLiteral("stock(beer,fridge,"+model.availableBeers+")"));
			}
		} else if (action.equals(clf)) {
			succeed = model.closeFridge();
		} else if (action.getFunctor().equals("move_towards")) {
			String agent     = action.getTerm(0).toString();
			String direction = action.getTerm(1).toString();
			try {
				succeed = model.moveTowards(agent, direction);
				updatePercepts("robot", new LinkedList<Literal>());
			} catch (Exception e) {
				e.printStackTrace();
			}
		} else if (action.equals(gb)) {
			succeed = model.getBeer();
		} else if (action.equals(hb)) {
			succeed = model.handInBeer();
			updatePercepts("owner", new LinkedList<Literal>());
		} else if (action.equals(sb) & ag.equals("owner")) {
			try {
				Thread.sleep(600);
				succeed = model.sipBeer();
				updatePercepts("owner", new LinkedList<Literal>());
			} catch (Exception e) {
				logger.info("Failed to execute action sip!"+e);
			}
		} else if (action.getFunctor().equals("throw") & ag.equals("owner")) {
			try {
				String object   = action.getTerm(0).toString();
				Location location = new Location (
					(int)((NumberTerm)((Structure)action.getTerm(1)).getTerm(0)).solve(),
					(int)((NumberTerm)((Structure)action.getTerm(1)).getTerm(1)).solve()
				);
				succeed = model.throwCan(location);
			} catch (Exception e) {
				logger.info("Failed to execute action deliver!"+e);
			}
		} else if (action.equals(gc)) {
			succeed = model.getCan(ag);
		} else if (action.equals(rc)) {
			succeed = model.recycleCan();
		} else if (action.equals(ct)) { // TODO DUSTMAN
			succeed = model.collectTrash();
		} else if (action.getFunctor().equals("deliver")) { // TODO; robot should move the beer from delivery location
			// wait 4 seconds to finish "deliver"
			try {
				Thread.sleep(4000);
				succeed = model.addBeer((int)((NumberTerm)action.getTerm(1)).solve());
			} catch (Exception e) {
				logger.info("Failed to execute action deliver!"+e);
			}
		} else if (action.getFunctor().equals("reject")) {
			try {
				succeed = model.addBeer(((int)((NumberTerm)action.getTerm(1)).solve())*-1);
			} catch (Exception e) {
				logger.info("Failed to execute action reject!" + e);
			}
		} else if (action.equals(enm) & (ag.equals("cleaner") || ag.equals("dustman") || ag.equals("mover"))) {
			try {
				succeed = model.enterMap(ag);
			} catch (Exception e) {
				logger.info("Failed to execute action enterMap!" + e);
			}
		} else if (action.equals(exm) & (ag.equals("cleaner") || ag.equals("dustman") || ag.equals("mover"))) {
			try {
				succeed = model.exitMap(ag);
			} catch (Exception e) {
				logger.info("Failed to execute action exitMap!" + e);
			}
		} else {
			logger.info("Failed to execute action "+action);
		}

		if (succeed) {
			try { Thread.sleep(100); } catch (Exception e) {}
		}
		return succeed;
	}
}