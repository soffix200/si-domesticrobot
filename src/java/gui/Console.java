package gui;

import javax.swing.*;
import javax.swing.text.AttributeSet;
import javax.swing.text.SimpleAttributeSet;
import javax.swing.text.StyleConstants;
import javax.swing.text.StyleContext;

import java.awt.event.*;
import java.awt.BorderLayout;
import java.awt.Container;
import java.awt.FlowLayout;
import java.awt.Color;
import java.awt.Insets;

import cartago.*;
import cartago.tools.*;

public class Console extends GUIArtifact {

	private MyFrame frame;

	private String botName       = "default";
	private String botMasterName = "botMaster";

	public void setup() {
		frame = new MyFrame();

		try { Thread.sleep(500); } catch (Exception e) {}

		linkActionEventToOp(frame.getButton(), "send");
		linkKeyStrokeToOp(frame.getTextField(), "ENTER", "send");
		linkWindowClosingEventToOp(frame, "closed");
		linkMouseEventToOp(frame, "mouseDragged", "mouseDraggedOp");

		frame.setVisible(true);
	}

	@INTERNAL_OPERATION void send(ActionEvent ev){
		String texto = frame.getTextField().getText();
		signal("msg", texto);

		frame.getTextField().setText("");
		frame.appendToPane(frame.getTextArea(), botMasterName, Color.DARK_GRAY);
		frame.appendToPane(frame.getTextArea(), " dice: ", Color.DARK_GRAY);
		frame.appendToPane(frame.getTextArea(), texto, Color.DARK_GRAY);
		frame.appendToPane(frame.getTextArea(), System.lineSeparator(), Color.DARK_GRAY);
	}

	@INTERNAL_OPERATION void closed(WindowEvent ev){
		signal("closed");
	}

	@INTERNAL_OPERATION void updateText(ActionEvent ev){
		String texto = frame.getText();
		signal("msg", texto);

		frame.getTextField().setText("");
		frame.appendToPane(frame.getTextArea(), botMasterName, Color.DARK_GRAY);
		frame.appendToPane(frame.getTextArea(), " pregunta: ", Color.DARK_GRAY);
		frame.appendToPane(frame.getTextArea(), texto, Color.DARK_GRAY);
		frame.appendToPane(frame.getTextArea(), System.lineSeparator(), Color.DARK_GRAY);
	}

	@OPERATION void setBotName(String name){
		this.botName = name;
	}
	@OPERATION void setBotMasterName(String name){
		this.botMasterName = name;
	}

	@OPERATION void show(String texto){
		frame.appendToPane(frame.getTextArea(), botName, Color.RED);
		frame.appendToPane(frame.getTextArea(), " dice: ", Color.RED);
		frame.appendToPane(frame.getTextArea(), texto, Color.RED);
		frame.appendToPane(frame.getTextArea(), System.lineSeparator(), Color.RED);
	}

}
