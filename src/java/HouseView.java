import jason.environment.grid.*;

import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics;


/** class that implements the View of Domestic Robot application */
public class HouseView extends GridWorldView {

	HouseModel hmodel;

	public HouseView(HouseModel model) {
		super(model, "Domestic Robot", 700);
		hmodel = model;
		defaultFont = new Font("Arial", Font.BOLD, 16); // change default font
		setVisible(true);
		repaint();
	}

	/** draw application objects */
	@Override
	public void draw(Graphics g, int x, int y, int object) {
		Location lOwner   = hmodel.getAgPos(HouseModel.OWNER);
		Location lCleaner = hmodel.getAgPos(HouseModel.CLEANER);
		Location lDustman = hmodel.getAgPos(HouseModel.DUSTMAN);
		Location lMover   = hmodel.getAgPos(HouseModel.MOVER);
		super.drawObstacle(g,x,y);
		//super.drawAgent(g, x, y, Color.lightGray, -1);
		switch (object) {
			case HouseModel.FRIDGE:
				super.drawAgent(g, x, y, Color.white, -1);
				if (lOwner.equals(hmodel.lFridge)) {
					super.drawAgent(g, x, y, Color.yellow, -1);
				}
				g.setColor(Color.black);
				drawString(g, x, y, defaultFont, "Fridge ("+hmodel.beersInFridge+")");
				break;
			case HouseModel.DELIVERY:
				super.drawAgent(g, x, y, Color.green, -1);
				if (lOwner.equals(hmodel.lDelivery)) {
					super.drawAgent(g, x, y, Color.yellow, -1);
				}
				g.setColor(Color.black);
				drawString(g, x, y, defaultFont, "Delivery");
				break;
			case HouseModel.DUMPSTER:
				if (lOwner.equals(hmodel.lDumpster)) {
					super.drawAgent(g, x, y, Color.yellow, -1);
				}
				g.setColor(Color.black);   
				drawString(g, x, y, defaultFont, "Dumpster ("+hmodel.trashCount+")");
				break;
			case HouseModel.CAN:
				if (lOwner.equals(hmodel.lCan)) {
					super.drawAgent(g, x, y, Color.yellow, -1);
				}
				g.setColor(Color.black);   
				drawString(g, x, y, defaultFont, "Can");
				break;
			case HouseModel.OWNER:
				super.drawAgent(g, x, y, Color.red, -1);
				String o = "Own";
				if (hmodel.sipCount > 0) {
					o +=  " ("+hmodel.sipCount+")";
				}
				g.setColor(Color.black);
				drawString(g, x, y, defaultFont, o);
				break;
		}
		repaint();
	}

	@Override
	public void drawAgent(Graphics g, int x, int y, Color c, int id) {
		Location lOwner = hmodel.getAgPos(HouseModel.OWNER);
		switch (id) {
			case HouseModel.OWNER:
				if (!lOwner.equals(hmodel.lFridge) && !lOwner.equals(hmodel.lDelivery) && !lOwner.equals(hmodel.lDumpster) && !lOwner.equals(hmodel.lCan)) {
					c = Color.yellow;
					//if (hmodel.carryingBeer) c = Color.orange;
					super.drawAgent(g, x, y, c, -1);
					g.setColor(Color.black);
					super.drawString(g, x, y, defaultFont, "Owner");
				}
				break;
			case HouseModel.CLEANER:
				c = Color.yellow;
				super.drawAgent(g, x, y, c, -1);
				g.setColor(Color.black);
				super.drawString(g, x, y, defaultFont, "Cleaner");
				break;
			case HouseModel.DUSTMAN:
				c = Color.yellow;
				super.drawAgent(g, x, y, c, -1);
				g.setColor(Color.black);
				super.drawString(g, x, y, defaultFont, "Dustman");
				break;
			case HouseModel.MOVER:
				c = Color.yellow;
				super.drawAgent(g, x, y, c, -1);
				g.setColor(Color.black);
				super.drawString(g, x, y, defaultFont, "Mover");
				break;
		}
	}

}
