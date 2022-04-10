package movement;

import jason.*;
import jason.asSyntax.*;
import jason.asSemantics.*;

import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;
import jason.environment.grid.Location;

public class getDirection extends DefaultInternalAction {

	public static final Literal left  = Literal.parseLiteral("left");
	public static final Literal right = Literal.parseLiteral("right");
	public static final Literal up    = Literal.parseLiteral("up");
	public static final Literal down  = Literal.parseLiteral("down");
	public static final Literal here  = Literal.parseLiteral("here");

	@Override
	public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
		try {
			Location origin = new Location(
				(int)((NumberTerm)((Structure)args[0]).getTerm(0)).solve(),
				(int)((NumberTerm)((Structure)args[0]).getTerm(1)).solve()
			);
			Location destination = new Location(
				(int)((NumberTerm)((Structure)args[1]).getTerm(0)).solve(),
				(int)((NumberTerm)((Structure)args[1]).getTerm(1)).solve()
			);
			boolean destinationGap = ((Structure)args[1]).getTerm(2).toString().equals("side");
			Location bounds = new Location(
				(int)((NumberTerm)((Structure)args[2]).getTerm(0)).solve(),
				(int)((NumberTerm)((Structure)args[2]).getTerm(1)).solve()
			);
			List<Location> obstacles = new ArrayList<Location>();
			for (Term obstacleLiteral : ((ListTerm)args[3]).getAsList()) {
				obstacles.add(new Location(
					(int)((NumberTerm)((Structure)obstacleLiteral).getTerm(0)).solve(),
					(int)((NumberTerm)((Structure)obstacleLiteral).getTerm(1)).solve()
				));
			}

			if (distance(origin, destination) == (destinationGap?1:0)) return un.unifies(here,  args[4]);
			obstacles.add(origin);

			List<Location> adyacentLocations = new ArrayList<Location>();
			if (origin.x < bounds.x) adyacentLocations.add(new Location(origin.x+1, origin.y));
			if (origin.y > 0)        adyacentLocations.add(new Location(origin.x, origin.y-1));
			if (origin.x > 0)        adyacentLocations.add(new Location(origin.x-1, origin.y));
			if (origin.y < bounds.y) adyacentLocations.add(new Location(origin.x, origin.y+1));

			Iterator<Location> it = adyacentLocations.iterator();
			while (it.hasNext()) {
				Location loc = it.next();
				for (Location obstacle : obstacles) {
					if (loc.equals(obstacle)) {
						it.remove();
						break;
					}
				}
			}

			adyacentLocations.sort((Location a, Location b) -> distance(a, destination) - distance(b, destination));

			for (Location loc : adyacentLocations) {
				boolean found = path(loc, destination, destinationGap, bounds, obstacles);
				if (found) {
					if (loc.x < origin.x) return un.unifies(left,  args[4]);
					if (loc.x > origin.x) return un.unifies(right, args[4]);
					if (loc.y < origin.y) return un.unifies(up,    args[4]);
					if (loc.y > origin.y) return un.unifies(down,  args[4]);
				}
			}

			obstacles.remove(origin);
			return null;

		} catch (ArrayIndexOutOfBoundsException e) {
			throw new JasonException("The internal action 'getDirection' has not received six arguments!");
		} catch (ClassCastException e) {
			throw new JasonException("The internal action 'getDirection' has received arguments that are not the expected type!");
		} catch (Exception e) {
			throw new JasonException("Error in 'getDirection'");
		}
	}

	private boolean path(Location origin, Location destination, boolean destinationGap, Location bounds, List<Location> obstacles) {
		if (distance(origin, destination) == (destinationGap?1:0)) return true;
		obstacles.add(origin);

		List<Location> adyacentLocations = new ArrayList<Location>();
		if (origin.x < bounds.x) adyacentLocations.add(new Location(origin.x+1, origin.y));
		if (origin.y > 0)        adyacentLocations.add(new Location(origin.x, origin.y-1));
		if (origin.x > 0)        adyacentLocations.add(new Location(origin.x-1, origin.y));
		if (origin.y < bounds.y) adyacentLocations.add(new Location(origin.x, origin.y+1));

		Iterator<Location> it = adyacentLocations.iterator();
		while (it.hasNext()) {
			Location loc = it.next();
			for (Location obstacle : obstacles) {
				if (loc.equals(obstacle)) {
					it.remove();
					break;
				}
			}
		}

		adyacentLocations.sort((Location a, Location b) -> distance(a, destination) - distance(b, destination));

		for (Location loc : adyacentLocations) {
			boolean found = path(loc, destination, destinationGap, bounds, obstacles);
			if (found) return found;
		}

		obstacles.remove(origin);
		return false;
	}

	private int distance(Location a, Location b) {
		return (Math.abs(a.x-b.x) + Math.abs(a.y-b.y));
	}
}

