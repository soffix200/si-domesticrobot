import jason.environment.grid.GridWorldModel;
import jason.environment.grid.Location;

import java.util.Random;
import java.util.Set;
import java.util.HashSet;

/** class that implements the Model of Domestic Robot application */
public class HouseModel extends GridWorldModel {

	// constants for the grid objects
	public static final int ROBOT    = 0;
	public static final int OWNER    = 1;
	public static final int CLEANER  = 2;
	public static final int DUSTMAN  = 3;
	public static final int MOVER    = 4;

	public static final int FRIDGE   = 16;
	public static final int DELIVERY = 32;
	public static final int DUMPSTER = 64;
	public static final int DEPOT    = 128;
	public static final int CAN      = 1024;

	// the grid size
	public static final int GSize = 11;

	boolean fridgeOpen   = false; // whether the fridge is open
	int sipCount         = 0; // how many sip the owner did
	int trashCount 		   = 0; // how many trash cans are in dumpster
	int beersInFridge    = 3; // how many beers are available
	int beersInDelivery  = 0; // how many beers have been delivered to the delivery location

	Set<Integer> carryingBeer  = new HashSet<Integer>(); // agentCodes of agents carrying beer
	Set<Integer> carryingCan   = new HashSet<Integer>(); // agentCodes of agents carrying cans
	Set<Integer> carryingTrash = new HashSet<Integer>(); // agentCodes of agents carrying trash

	Location lBase     = new Location(GSize/2, GSize/2);
	Location lOwner    = new Location(GSize-1, GSize-1); 
	Location lFridge   = new Location(0, 0);
	Location lDelivery = new Location(0, GSize-1);
	Location lDumpster = new Location(0, 1);
	Location lDepot    = new Location(GSize-1, 0);
	Location lExit     = new Location(0, GSize-1);
	Location lCan 	   = null;
		
	boolean atBase     = false;
	boolean atOwner    = false;
	boolean atFridge   = false;
	boolean atDelivery = false;
	boolean atDumpster = false;
	boolean atDepot    = false;
	boolean atExit     = false;
	boolean atCan      = false;

	public HouseModel() {
		// create a 11x11 grid with two mobile agents
		super(GSize, GSize, 5);

		// Base location of agents
		setAgPos(ROBOT, lBase);
		setAgPos(OWNER, lOwner);

		// initial location of various furniture
		add(FRIDGE,   lFridge);
		add(OWNER,    lOwner);
		add(DELIVERY, lDelivery);
		add(DUMPSTER, lDumpster);
		add(DEPOT,    lDepot);
	}

	int getAgentCode(String ag) {
		if (ag.equals("robot"))   return ROBOT;
		if (ag.equals("owner"))   return OWNER;
		if (ag.equals("cleaner")) return CLEANER;
		if (ag.equals("dustman")) return DUSTMAN;
		if (ag.equals("mover"))   return MOVER;
		return -1;
	}

	boolean nearPos(Location a, Location b) {
		return 
			a.equals(b) ||
			a.equals(new Location(b.x, b.y+1)) ||
			a.equals(new Location(b.x, b.y-1)) ||
			a.equals(new Location(b.x+1, b.y)) ||
			a.equals(new Location(b.x-1, b.y));
	}
	boolean atPos(Location a, Location b) {
		return a.equals(b);
	}

	boolean moveTowards(String ag, String direction) {
		int agentCode = getAgentCode(ag);
		Location loc = getAgPos(agentCode);

		if (direction.equals("left")) {
			loc.x--;
		}
		else if (direction.equals("right")) {
			loc.x++;
		}
		else if (direction.equals("down")) {
			loc.y++;
		}
		else if (direction.equals("up")) {
			loc.y--;
		}
		
		setAgPos(agentCode, loc);

		if (agentCode == ROBOT) {
			atBase     = atPos(loc, lBase);
			atOwner    = nearPos(loc, lOwner);
			atFridge   = nearPos(loc, lFridge);
			atDelivery = atPos(loc, lDelivery);
			atDumpster = nearPos(loc, lDumpster);
			atDepot    = atPos(loc, lDepot);
			atExit     = atPos(loc, lExit);
			atCan      = lCan != null && atPos(loc, lCan);
		}

		if (view != null) {
			view.update(lBase.x,     lBase.y);
			view.update(lOwner.x,    lOwner.y);
			view.update(lFridge.x,   lFridge.y);
			view.update(lDelivery.x, lDelivery.y);
			view.update(lDumpster.x, lDumpster.y);
			view.update(lDepot.x,    lDepot.y);
			view.update(lExit.x,     lExit.y);
			if (lCan != null) view.update(lCan.x, lCan.y);
		}
		return true;
	}

	boolean openFridge() {
		if (!fridgeOpen) {
			fridgeOpen = true;
			return true;
		}
		return false;
	}

	boolean closeFridge() {
		if (fridgeOpen) {
			fridgeOpen = false;
			return true;
		}
		return false;
	}

	boolean addBeersToFridge(String ag, int n) {
		int agentCode = getAgentCode(ag);
		if (fridgeOpen && carryingBeer.contains(agentCode)) {
			beersInFridge += n;
			carryingBeer.remove(agentCode);
			if (view != null)
				view.update(lFridge.x,lFridge.y);
			return true;
		}
		return false;
	}

	boolean addBeersToDelivery(String ag, int n) {
		beersInDelivery += n;
		if (view != null)
			view.update(lDelivery.x,lDelivery.y);
		return true;
	}

	boolean handInBeer(String ag) {
		int agentCode = getAgentCode(ag);
		if (carryingBeer.contains(agentCode)) {
			sipCount = 10;
			carryingBeer.remove(agentCode);
			if (view != null)
				view.update(lOwner.x,lOwner.y);
			return true;
		}
		return false;
	}

	boolean addCanToDumpster(String ag) {
		int agentCode = getAgentCode(ag);
		if (carryingCan.contains(agentCode)) {
			trashCount++;
			carryingCan.remove(agentCode);
			if (view != null)
				view.update(lDumpster.x,lDumpster.y);
			return true;
		}
		return false;
	}

	boolean getBeerFromFridge(String ag) {
		int agentCode = getAgentCode(ag);
		if (fridgeOpen && beersInFridge > 0 && !carryingBeer.contains(agentCode)) {
			beersInFridge--;
			carryingBeer.add(agentCode);
			if (view != null)
				view.update(lFridge.x,lFridge.y);
			return true;
		}
		return false;
	}

	boolean getBeersFromDelivery(String ag, int n) {
		int agentCode = getAgentCode(ag);
		if (beersInDelivery >= n && !carryingBeer.contains(agentCode)) {
			beersInDelivery -= n;
			carryingBeer.add(agentCode);
			if (view != null)
				view.update(lDelivery.x,lDelivery.y);
			return true;
		}
		return false;
	}

	boolean removeBeersFromDelivery(int n) {
		if (beersInDelivery >= n) {
			beersInDelivery -= n;
			if (view != null)
				view.update(lDelivery.x,lDelivery.y);
			return true;
		}
		return false;
	}

	boolean getCan(String ag) {
		int agentCode = getAgentCode(ag);
		if (!carryingCan.contains(agentCode)) {
			carryingCan.add(agentCode);
			if (hasObject(CAN, getAgPos(agentCode))) {
				remove(CAN, getAgPos(agentCode));
				if (view != null)
					view.update(lCan.x,lCan.y);
			}
			return true;
		}
		return false;
	}

	boolean getTrashFromDumpster(String ag) {
		int agentCode = getAgentCode(ag);
		if (trashCount > 0 && !carryingTrash.contains(agentCode)) {
			trashCount = 0;
			carryingTrash.add(agentCode);
			if (view != null)
				view.update(lDumpster.x, lDumpster.y);
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
		}
		return false;
	}

	// TODO MAY NEED TO BE MORE THAN ONE CAN
	boolean throwCan(Location loc) {
		lCan = loc;
		add(CAN, lCan);
		if (view != null)
			view.update(lCan.x, lCan.y);
		return true;
	}

	boolean enterMap(String ag) {
		int agentCode = getAgentCode(ag);
		setAgPos(agentCode, lDepot);
		if (view != null)
			view.update(lDepot.x, lDepot.y);
		return true;
	}

	boolean exitMap(String ag) {
		int agentCode = getAgentCode(ag);
		if (lDepot.equals(getAgPos(agentCode))) {
			remove(AGENT, lDepot);
			if (view != null)
				view.update(lDepot.x, lDepot.y);
			return true;
		}
		return false;
	}
}
