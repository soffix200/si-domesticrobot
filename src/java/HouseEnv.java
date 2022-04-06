import jaca.CartagoEnvironment;

import jason.asSyntax.*;
import jason.asSyntax.Literal;
import jason.asSyntax.Structure;               
import jason.environment.Environment;
import jason.environment.grid.Location;                               

import java.util.logging.Logger;

public class HouseEnv extends Environment {

	// common literals
	public static final Literal of  = Literal.parseLiteral("open(fridge)");
	public static final Literal clf = Literal.parseLiteral("close(fridge)");
	public static final Literal gb  = Literal.parseLiteral("get(beer)");
	public static final Literal hb  = Literal.parseLiteral("hand_in(beer)");
	public static final Literal sb  = Literal.parseLiteral("sip(beer)");
	public static final Literal tc  = Literal.parseLiteral("throw(can)");
	public static final Literal gc  = Literal.parseLiteral("get(can)");
	public static final Literal rc  = Literal.parseLiteral("recycle(can)");
	public static final Literal ct  = Literal.parseLiteral("collect(trash)");

	// TODO RETHINK
	public static final Literal hob = Literal.parseLiteral("has(owner,beer)");
	public static final Literal fob = Literal.parseLiteral("finished(owner,beer)");

	public static final Literal af = Literal.parseLiteral("at(robot,fridge)");
	public static final Literal ao = Literal.parseLiteral("at(robot,owner)");
	public static final Literal ad = Literal.parseLiteral("at(robot,delivery)");
	public static final Literal ab = Literal.parseLiteral("at(robot,base)");

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
		updatePercepts();
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
			  
	/** creates the agents percepts based on the HouseModel */
	void updatePercepts() {
		// get the robot location
		Location lRobot = model.getAgPos(0);

		// add agent location to its percepts
		//if (lRobot.equals(model.closeTolFridge)) {
		if (model.atFridge) {
			addPercept("robot", af);
		}
		//if (lRobot.equals(model.closeTolOwner)) {
		if (model.atOwner) {
			addPercept("robot", ao);
		}

		if (model.atDelivery) {
			addPercept("robot", ad);
		}

		if (model.atBase) {
			addPercept("robot", ab);
		}

		// add beer "status" the percepts
		if (model.fridgeOpen) {
			addPercept("robot", Literal.parseLiteral("stock(beer,"+model.availableBeers+")"));
		}
		
		// TODO RETHINK
		if (model.sipCount > 0) {
			addPercept("robot", hob);
			addPercept("owner", hob);
		} else {
			addPercept("owner", fob);
		}
	}


	@Override
	public boolean executeAction(String ag, Structure action) {
		System.out.println("["+ag+"] doing: " + action);
		clearPercepts();

		boolean succeed   = false;

		if (action.equals(of) & ag.equals("robot")) {
			succeed = model.openFridge()
		} else if (action.equals(clf) & ag.equals("myRobot")) {
			succeed = model.closeFridge();
		} else if (action.getFunctor().equals("move_towards")) {
			String agent = action.getTerm(0).toString();
			String location = action.getTerm(1).toString();
			Location dest = null;
			if (location.equals("fridge")) {
				dest = model.lFridge;
			} else if (location.equals("owner")) {
				dest = model.lOwner;
			} else if (location.equals("dumpster")) {
				dest = model.lDumpster;
			} else if (location.equals("exit")) {
				dest = model.lExit;
			}
			try {
				succeed = model.moveTowards(agent, dest);
			} catch (Exception e) {
				e.printStackTrace();
			}
		} else if (action.equals(gb) & ag.equals("robot")) {
			succeed = model.getBeer();
		} else if (action.equals(hb) & ag.equals("robot")) {
			succeed = model.handInBeer();
		} else if (action.equals(sb) & ag.equals("owner")) {
			succeed = model.sipBeer();
		} else if (action.equals(tc) & ag.equals("owner")) {
			succeed = model.throwCan();
		} else if (action.equals(gc) & ag.equals("robot")) {
			succeed = model.getCan();
		} else if (action.equals(rc) & (ag.equals("robot") || ag.equals("owner"))) {
			succeed = model.recycleCan();
		} else if (action.equals(ct)) { // TODO DUSTMAN
			succeed = model.collectTrash();
		} else if (action.getFunctor().equals("deliver") & ag.equals("supermarket")) {
			// wait 4 seconds to finish "deliver"
			try {
				Thread.sleep(4000);
				succeed = model.addBeer((int)((NumberTerm)action.getTerm(1)).solve());
			} catch (Exception e) {
				logger.info("Failed to execute action deliver!"+e);
			}
		} else if (action.getFunctor().equals("reject")) {
			try {
				result = model.addBeer(((int)((NumberTerm)action.getTerm(1)).solve())*-1);
			} catch (Exception e) {
				logger.info("Failed to execute action reject!" + e);
			}
		} else {
			logger.info("Failed to execute action "+action);
		}

		if (succeed) {
			updatePercepts();
			try { Thread.sleep(100); } catch (Exception e) {}
		}
		return succeed;
	}
}