package movement;

import jason.*;
import jason.asSyntax.*;
import jason.asSemantics.*;

import java.util.List;
import java.util.LinkedList;
import java.util.Map;
import java.util.HashMap;
import java.util.PriorityQueue;
import java.util.Comparator;
import java.util.Iterator;
import jason.environment.grid.Location;

public class getDirection extends DefaultInternalAction {

	public static final Literal left  = Literal.parseLiteral("left");
	public static final Literal right = Literal.parseLiteral("right");
	public static final Literal up    = Literal.parseLiteral("up");
	public static final Literal down  = Literal.parseLiteral("down");
	public static final Literal here  = Literal.parseLiteral("here");
	public static final Literal none  = Literal.parseLiteral("none");

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
			List<Location> obstacles = new LinkedList<Location>();
			for (Term obstacleLiteral : ((ListTerm)args[3]).getAsList()) {
				obstacles.add(new Location(
					(int)((NumberTerm)((Structure)obstacleLiteral).getTerm(0)).solve(),
					(int)((NumberTerm)((Structure)obstacleLiteral).getTerm(1)).solve()
				));
			}

			List<Location> path = path(origin, destination, destinationGap, bounds, obstacles);
			
			if (path.size() == 0)      return un.unifies(none, args[4]);
			if (path.size() == 1)      return un.unifies(here, args[4]);

			Location nextStep = path.get(1);
			if (nextStep.x < origin.x) return un.unifies(left,  args[4]);
			if (nextStep.x > origin.x) return un.unifies(right, args[4]);
			if (nextStep.y < origin.y) return un.unifies(up,    args[4]);
			if (nextStep.y > origin.y) return un.unifies(down,  args[4]);

			return null;

		} catch (ArrayIndexOutOfBoundsException e) {
			throw new JasonException("The internal action 'getDirection' has not received six arguments!");
		} catch (ClassCastException e) {
			throw new JasonException("The internal action 'getDirection' has received arguments that are not the expected type!");
		} catch (Exception e) {
			throw new JasonException("Error in 'getDirection'");
		}
	}

	class RelativeScoreLocationComparator implements Comparator<Location> {
		public Map<Location, Integer> fScore = null;

		public RelativeScoreLocationComparator(Map<Location, Integer> fScore) {
			this.fScore = fScore;
		}

		public int compare(Location a, Location b) {
			return fScore.get(a) - fScore.get(b);
		}
	}

	private List<Location> path(Location origin, Location destination, boolean destinationGap, Location bounds, List<Location> obstacles) {
		Map<Location, Integer> gScore = new HashMap<Location, Integer>();
		gScore.put(origin, 0);

		Map<Location, Integer> fScore = new HashMap<Location, Integer>();
		fScore.put(origin, distance(origin, destination));

		Map<Location, Location> cameFrom = new HashMap<Location, Location>();
		PriorityQueue<Location> openSet = new PriorityQueue<Location>(new RelativeScoreLocationComparator(fScore));
		openSet.add(origin);

		while (!openSet.isEmpty()) {
			Location current = openSet.poll();

			if (distance(current, destination) == (destinationGap ? 1 : 0)) {
				return reconstructPath(cameFrom, current);
			}

			for (Location adjacent : getAdjacentLocations(current, bounds, obstacles)) {
				int tentativeScore = gScore.get(current) + 1;
				int adjacentScore = (gScore.get(adjacent) != null) 
					? gScore.get(adjacent)
					: Integer.MAX_VALUE;
				if (tentativeScore < adjacentScore) {
					cameFrom.put(adjacent, current);
					gScore.put(adjacent, tentativeScore);
					fScore.put(adjacent, tentativeScore + distance(adjacent, destination));
					if (!openSet.contains(adjacent)) {
						openSet.add(adjacent);
					}
				}
			}
		}
		return new LinkedList<Location>();
	}

	private int distance(Location a, Location b) {
		return (Math.abs(a.x-b.x) + Math.abs(a.y-b.y));
	}

	private List<Location> getAdjacentLocations(Location loc, Location bounds, List<Location> obstacles) {
		List<Location> adjacentLocations = new LinkedList<Location>();

		if (loc.x < bounds.x) adjacentLocations.add(new Location(loc.x+1, loc.y));
		if (loc.y > 0)        adjacentLocations.add(new Location(loc.x, loc.y-1));
		if (loc.x > 0)        adjacentLocations.add(new Location(loc.x-1, loc.y));
		if (loc.y < bounds.y) adjacentLocations.add(new Location(loc.x, loc.y+1));

		Iterator<Location> it = adjacentLocations.iterator();
		while (it.hasNext()) {
			Location pos = it.next();
			for (Location obstacle : obstacles) {
				if (pos.equals(obstacle)) {
					it.remove();
					break;
				}
			}
		}

		return adjacentLocations;
	}

	private List<Location> reconstructPath(Map<Location, Location> cameFrom, Location current) {
		LinkedList<Location> path = new LinkedList<Location>();
		path.addFirst(current);
		while (cameFrom.containsKey(current)) {
			current = cameFrom.get(current);
			path.addFirst(current);
		}
		return path;
	}

}
