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

public class MyFrame extends JFrame {
	/** Scroll */
	private JScrollPane scroll;
	
	/** Area para mostrar la conversacion */
	private JTextPane textArea;
	
	/** Para pedir el texto al usuario */
	private JTextField textField;
	
	/** Boton para enviar el texto */
	private JButton boton; 
	                                                    
	public void appendToPane(JTextPane tp, String msg, Color c){
        StyleContext sc = StyleContext.getDefaultStyleContext();
        AttributeSet aset = sc.addAttribute(SimpleAttributeSet.EMPTY, StyleConstants.Foreground, c);

        aset = sc.addAttribute(aset, StyleConstants.FontFamily, "Lucida Console");
        aset = sc.addAttribute(aset, StyleConstants.Alignment, StyleConstants.ALIGN_JUSTIFIED);

        int len = tp.getDocument().getLength();
        tp.setCaretPosition(len);
        tp.setCharacterAttributes(aset, false);
        tp.replaceSelection(msg);
    }
	
	public MyFrame(){
		setTitle("Simple GUI ");
		setSize(600,400);
		
		Container contenedor = this.getContentPane();
		contenedor.setLayout(new BorderLayout());
		
		JPanel panel = new JPanel(new FlowLayout());
		setContentPane(contenedor);
		
		textArea = new JTextPane();
		textArea.setSize(400,200);
		textArea.setMargin(new Insets(5, 5, 5, 5));
		appendToPane(textArea, "/*  Information window for user interaction with the agent */", Color.BLUE);
		String salto = System.lineSeparator();
		appendToPane(textArea, salto, Color.BLUE);
		appendToPane(textArea, salto, Color.BLUE);
			
		scroll = new JScrollPane(textArea);

		textField = new JTextField(40);
		textField.setText("User Input Area");
		textField.setEditable(true);
			
		boton = new JButton("Send");
		boton.setSize(100,50);
			
		panel.add(boton);
		panel.add(textField);
			
		contenedor.add(scroll, BorderLayout.CENTER);
		contenedor.add(panel, BorderLayout.SOUTH);
		}
		 
		
	public String getText(){
		return textField.getText();
	}
	
	public void setText(String s, Color c){
		appendToPane(textArea, s, c);
	}  

	public JButton getButton(){
		return boton;
	} 
	
	public JTextField getTextField(){
		return textField;
	}

	public JTextPane getTextArea(){
		return textArea;
	}

	public void setButton(JButton btn){
		boton = btn;
	} 
	
	public void setTextField(JTextField txtF){
		textField = txtF;
	}

	public void setTextArea(JTextPane pane){
		textArea = pane;
	}
	
}

