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
//import java.awt.event.ActionListener;
                                                                                                           
//import java.awt.Container;                                                                               

import cartago.*;
import cartago.tools.*;

public class Console extends GUIArtifact {

	private MyFrame frame;
	
	private String botName;
	private String botMasterName = "Ivan";
	
	public void setup() {
		frame = new MyFrame();
		
		linkActionEventToOp(frame.getButton(),"send");
		linkKeyStrokeToOp(frame.getTextField(),"ENTER","send");
		linkWindowClosingEventToOp(frame, "closed");
		linkMouseEventToOp(frame,"mouseDragged","mouseDraggedOp"); 
		
        frame.setVisible(true);
	}                             

	@INTERNAL_OPERATION void send(ActionEvent ev){
		String texto = frame.getTextField().getText();
 		//getObsProperty("say").updateValue(texto);
		signal("say",texto);
		
		frame.getTextField().setText("");
		
		frame.appendToPane(frame.getTextArea(), botMasterName, Color.DARK_GRAY);
		frame.appendToPane(frame.getTextArea(), " dice: ", Color.DARK_GRAY);
		frame.appendToPane(frame.getTextArea(), texto, Color.DARK_GRAY);
		String salto = System.lineSeparator();
		frame.appendToPane(frame.getTextArea(), salto, Color.DARK_GRAY);
	}

	@INTERNAL_OPERATION void closed(WindowEvent ev){
		signal("closed");
	}
	
	@INTERNAL_OPERATION void updateText(ActionEvent ev){
		String texto = frame.getText();
		//getObsProperty("say").updateValue(texto);
		signal("say",texto);
				
		frame.getTextField().setText("");
		
		frame.appendToPane(frame.getTextArea(), botMasterName, Color.DARK_GRAY);
		frame.appendToPane(frame.getTextArea(), " pregunta: ", Color.DARK_GRAY);
		frame.appendToPane(frame.getTextArea(), texto, Color.DARK_GRAY);
		String salto = System.lineSeparator();
		frame.appendToPane(frame.getTextArea(), salto, Color.DARK_GRAY);
	}

	@OPERATION void show(String texto){
		frame.appendToPane(frame.getTextArea(), botName, Color.RED);
		frame.appendToPane(frame.getTextArea(), " dice: ", Color.RED);
		frame.appendToPane(frame.getTextArea(), texto, Color.RED);
		String salto = System.lineSeparator();
		frame.appendToPane(frame.getTextArea(), salto, Color.RED);
	}

	@OPERATION void setBotName(String name){
        botName = name;
	}

	@OPERATION void setBotMasterName(String name){
        botMasterName = name;
	}

}
