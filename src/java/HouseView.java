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
		switch (object) {
			case HouseModel.SOFA:
				g.setColor(Color.black);
				super.drawObstacle(g, x, y);
				super.drawAgent(g, x, y, Color.orange, -1);
				break;
			case HouseModel.FRIDGE:
				g.setColor(Color.black);
				super.drawObstacle(g, x, y);
				super.drawAgent(g, x, y, Color.lightGray, -1);
				g.setColor(Color.black);
				drawString(g, x, y, defaultFont, "Fdg ("+hmodel.beersInFridge+")");
				break;
			case HouseModel.DELIVERY:
				g.setColor(Color.white);
				super.drawObstacle(g, x, y);
				if (lOwner.equals(hmodel.lDelivery)) {
					super.drawAgent(g, x, y, Color.cyan, -1);
				} else {
					super.drawAgent(g, x, y, Color.green, -1);
				}
				g.setColor(Color.black);
				drawString(g, x, y, defaultFont, "Del ("+hmodel.beersInDelivery+")");
				break;
			case HouseModel.DUMPSTER:
				super.drawAgent(g, x, y, Color.gray, -1);
				g.setColor(Color.black);
				drawString(g, x, y, defaultFont, "Dump ("+hmodel.trashCount+")");
				break;
			case HouseModel.CAN:
				super.drawAgent(g, x, y, Color.red, -1);
				g.setColor(Color.black);
				drawString(g, x, y, defaultFont, "Can");
				break;
			case HouseModel.DEPOT:
				super.drawAgent(g, x, y, Color.cyan, -1);
				g.setColor(Color.black);
				drawString(g, x, y, defaultFont, "Depot");
				break;
			default:
				super.drawObstacle(g,x,y);
				break;
		}
		repaint();
	}

	@Override
	public void drawAgent(Graphics g, int x, int y, Color c, int id) {
		if (hmodel.carryingBeer.contains(id)) {
			super.drawAgent(g, x, y, Color.green, -1);
		} else if (hmodel.carryingCan.contains(id)) {
			super.drawAgent(g, x, y, Color.red, -1);
		} else if (hmodel.carryingTrash.contains(id)) {
			super.drawAgent(g, x, y, Color.gray, -1);
		} else {
			super.drawAgent(g, x, y, Color.yellow, -1);
		}
		switch (id) {
			case HouseModel.OWNER:
				g.setColor(Color.black);
				super.drawString(g, x, y, defaultFont, "Owner");
				break;
			case HouseModel.CLEANER:
				g.setColor(Color.black);
				super.drawString(g, x, y, defaultFont, "Cleaner");
				break;
			case HouseModel.DUSTMAN:
				g.setColor(Color.black);
				super.drawString(g, x, y, defaultFont, "Dustman");
				break;
			case HouseModel.MOVER:
				g.setColor(Color.black);
				super.drawString(g, x, y, defaultFont, "Mover");
				break;
		}
	}

}
