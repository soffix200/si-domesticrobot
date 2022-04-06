import jason.environment.grid.GridWorldModel;
import jason.environment.grid.Location;

/** class that implements the Model of Domestic Robot application */
public class HouseModel extends GridWorldModel {

	// constants for the grid objects
	public static final int ROBOT    = 0;
	public static final int OWNER    = 1;
	public static final int FRIDGE   = 16;
	public static final int DELIVERY = 32;
	public static final int DUMPSTER = 64;
	public static final int CAN      = 1024;

	// the grid size
	public static final int GSize = 11;

	boolean fridgeOpen   = false; // whether the fridge is open
	boolean carryingBeer = false; // whether the robot is carrying beer
	boolean carryingCan  = false; // whether the robot is carrying an empty beer can
	int sipCount         = 0; // how many sip the owner did
	int availableBeers   = 3; // how many beers are available
	int trashCount 		   = 0; // how many trash cans are in dumpster

	Location lBase     = new Location(GSize/2, GSize/2);
	Location lOwner    = new Location(GSize-1, GSize-1); 
	Location lFridge   = new Location(0,0);
	Location lDelivery = new Location(0, GSize-1);
	Location lDumpster = new Location(0, 1);
	Location lExit     = new Location(0, GSize-1);
	Location lCan 	   = null;
		
	boolean atBase     = false;
	boolean atOwner    = false;
	boolean atFridge   = false;
	boolean atDelivery = false;
	boolean atDumpster = false;
	boolean atExit     = false;

	public HouseModel() {
		// create a 11x11 grid with two mobile agents
		super(GSize, GSize, 2);

		// Base location of agents
		setAgPos(ROBOT, lBase);
		setAgPos(OWNER, lOwner);

		// initial location of various furniture
		add(FRIDGE,   lFridge);
		add(OWNER,    lOwner);
		add(DELIVERY, lDelivery);
		add(DUMPSTER, lDumpster);
	}
	
	boolean openFridge() {
		if (!fridgeOpen) {
			fridgeOpen = true;
			return true;
		} else {
			return false;
		}
	}

	boolean closeFridge() {
		if (fridgeOpen) {
			fridgeOpen = false;
			return true;
		} else {
			return false;
		}
	}

	boolean nearPos(Location a, Location b) {
		return 
			a.equals(b) ||
			a.equals(new Location(b.x, b.y+1)) ||
			a.equals(new Location(b.x, b.y-1)) ||
			a.equals(new Location(b.x+1, b.y)) ||
			a.equals(new Location(b.x-1, b.y+1));
	}
	boolean atPos(Location a, Location b) {
		return a.equals(b);
	}

	// TODO MAY NEED TO AVOID OBJECTS AS OBSTACLES
	boolean moveTowards(String agent, Location dest) {
		int agentCode = -1;
		if (agent.equals("robot")) {
			agentCode = ROBOT;
		} else if (agent.equals("dustman")) {
			agentCode = DUSTMAN;
		}
		Location loc = getAgPos(agentCode);
		if (dest.equals(lOwner) || dest.equals(lDelivery) || dest.equals(lDumpster)) {
			if (!nearPos(loc, dest)) {
				if (loc.x < dest.x+1)      loc.x++;
				else if (loc.x > dest.x-1) loc.x--;
				else if (loc.y < dest.y+1) loc.y++;
				else if (loc.y > dest.y-1) loc.y--;
			}
		} else {
			if (!atPos(loc, dest)) {
				if (loc.x < dest.x)      loc.x++;
				else if (loc.x > dest.x) loc.x--;
				else if (loc.y < dest.y) loc.y++;
				else if (loc.y > dest.y) loc.y--;
			}
		}
		setAgPos(agentCode, loc);

		atBase     = atPos(loc, lBase);
		atOwner    = nearPos(loc, lOwner);
		atFridge   = atPos(loc, lFridge);
		atDelivery = nearPos(loc, lDelivery);
		atDumpster = nearPos(loc, lDumpster);
		atExit     = atPos(loc, lExit);

		if (view != null) {
			view.update(lBase.x,     lBase.y);
			view.update(lOwner.x,    lOwner.y);
			view.update(lFridge.x,   lFridge.y);
			view.update(lDelivery.x, lDelivery.y);
			view.update(lDumpster.x, lDumpster.y);
			view.update(lExit.x,     lExit.y);
		}
		return true;
	}

	boolean getBeer() {
		if (fridgeOpen && availableBeers > 0 && !carryingBeer) {
			availableBeers--;
			carryingBeer = true;
			if (view != null)
				view.update(lFridge.x,lFridge.y);
			return true;
		} else {
			return false;
		}
	}

	boolean getCan() {
		if (!carryingCan) {
			if (hasObject(CAN, getAgPos(ROBOT))) {
				remove(CAN, getAgPos(ROBOT));
				if (view != null)
					view.update(lCan.x,lCan.y);
			}
			carryingCan = true;
			return true;
		}
		return false;
	}

	boolean addBeer(int n) {
		availableBeers += n;
		if (view != null)
			view.update(lFridge.x,lFridge.y);
		return true;
	}

	boolean handInBeer() {
		if (carryingBeer) {
			sipCount = 10;
			carryingBeer = false;
			if (view != null)
				view.update(lOwner.x,lOwner.y);
			return true;
		} else {
			return false;
		}
	}

	boolean recycleCan() {
		if (carryingCan) {
			carryingCan = false;
			trashCount++;
			return true;
		}
		return false;
	}

	boolean sipBeer() {
		if (sipCount > 0) {
			sipCount--;
			if (view != null)
				view.update(lOwner.x,lOwner.y);
			return true;
		} else {
			return false;
		}
	}

	// TODO MAY NEED TO BE MORE THAN ONE CAN
	boolean throwCan() {
		Random rand = new Random();
		lCan = new Location(rand.nextInt(GSize-1), rand.nextInt(GSize-1));
		add(CAN, lCan);
		return true;
	}

	boolean collectTrash() {
		if (trashCount > 0) {
			trashCount = 0;
		}
		return true;
	}
}