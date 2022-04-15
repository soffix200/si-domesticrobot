package basemath;

import jason.*;
import jason.asSyntax.*;
import jason.asSemantics.*;

public class truncate extends DefaultInternalAction {
	public static final Literal left  = Literal.parseLiteral("left");
	public static final Literal right = Literal.parseLiteral("right");
	public static final Literal up    = Literal.parseLiteral("up");
	public static final Literal down  = Literal.parseLiteral("down");
	public static final Literal here  = Literal.parseLiteral("here");

	@Override
	public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
    double value = ((NumberTerm)args[0]).solve();
    double trunc = Math.floor(value*100)/100;
    return un.unifies(new NumberTermImpl(trunc), args[1]);
  }
}