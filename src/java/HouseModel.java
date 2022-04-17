import jason.environment.grid.GridWorldModel;
import jason.environment.grid.Location;

import java.util.Random;
import java.util.Set;
import java.util.HashSet;

import java.io.File;
import java.io.FileWriter;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Scanner;

import org.json.*;

/** class that implements the Model of Domestic Robot application */
public class HouseModel extends GridWorldModel {

	// constants for the grid objects
	public static final int OWNER    = 0;
	public static final int CLEANER  = 1;
	public static final int DUSTMAN  = 2;
	public static final int MOVER    = 3;

	public static final int SOFA     = 8;
	public static final int FRIDGE   = 16;
	public static final int DELIVERY = 32;
	public static final int DUMPSTER = 64;
	public static final int DEPOT    = 128;
	public static final int CAN      = 1024;

	// the grid size
	public static final int GSize = 11;

	boolean fridgeOpen   = false; // whether the fridge is open
	int sipCount         = 0;     // how many sip the owner did
	int trashCount       = 0;     // how many trash cans are in dumpster
	int beersInFridge    = 3;     // how many beers are available
	int beersInDelivery  = 0;     // how many beers have been delivered to the delivery location

	Set<Integer> carryingBeer  = new HashSet<Integer>(); // agentCodes of agents carrying beer
	Set<Integer> carryingCan   = new HashSet<Integer>(); // agentCodes of agents carrying cans
	Set<Integer> carryingTrash = new HashSet<Integer>(); // agentCodes of agents carrying trash

	Location lBase     = new Location(GSize/2, GSize/2);
	Location lSofa     = new Location(GSize-1, GSize-1); 
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
		super(GSize, GSize, 4);

		setAgPos(OWNER, lSofa);

		add(SOFA,     lSofa);
		add(FRIDGE,   lFridge);
		add(DELIVERY, lDelivery);
		add(DUMPSTER, lDumpster);
		add(DEPOT,    lDepot);

		loadSavedStatus();
	}

	private void loadSavedStatus() {
		String content = "";
		try {
      File myObj = new File("tmp/environment.json");
      Scanner myReader = new Scanner(myObj);
      while (myReader.hasNextLine()) {
        content += myReader.nextLine();
      }
      myReader.close();
			JSONObject json = new JSONObject(content);
			trashCount = json.getInt("trashCount");
			beersInFridge = json.getInt("beersInFridge");
    } catch (FileNotFoundException ex1) {
      try {
				File myObj = new File("tmp/environment.json");
				myObj.createNewFile();
				saveStatus();
			} catch (IOException ex2) {
				System.out.println("An error occurred.");
				ex2.printStackTrace();
			}
    } catch (Exception ex3) {
			System.out.println("An error occurred.");
			ex3.printStackTrace();
		}
	}

	private void saveStatus() {
		try {
			JSONObject json = new JSONObject();
			json.put("trashCount", trashCount);
			json.put("beersInFridge", beersInFridge);
			FileWriter myWriter = new FileWriter("tmp/environment.json");
      myWriter.write(json.toString());
      myWriter.close();
		} catch (IOException ex1) {
			System.out.println("An error occurred.");
			ex1.printStackTrace();
		} catch (Exception ex2) {
			System.out.println("An error occurred.");
			ex2.printStackTrace();
		}
	}

	int getAgentCode(String ag) {
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
		Location previousLoc = getAgPos(agentCode);
		Location nextLoc     = getAgPos(agentCode);

		if (direction.equals("left"))       nextLoc.x--;
		else if (direction.equals("right"))	nextLoc.x++;
		else if (direction.equals("down"))  nextLoc.y++;
		else if (direction.equals("up"))    nextLoc.y--;
		
		setAgPos(agentCode, nextLoc);

		if (view != null) {
			view.update(previousLoc.x, previousLoc.y);
			view.update(nextLoc.x,     nextLoc.y);
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
			saveStatus();
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
				view.update(lSofa.x,lSofa.y);
			return true;
		}
		return false;
	}

	boolean addCanToDumpster(String ag) {
		int agentCode = getAgentCode(ag);
		if (carryingCan.contains(agentCode)) {
			trashCount++;
			carryingCan.remove(agentCode);
			saveStatus();
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
			saveStatus();
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
			saveStatus();
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
				view.update(lSofa.x,lSofa.y);
			return true;
		}
		return false;
	}

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
