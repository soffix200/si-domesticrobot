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

public class MyFrame extends JFrame {

	private JScrollPane scroll;
	private JTextPane   textArea;
	private JTextField  textField;
	private JButton     boton;
																											
	public void appendToPane(JTextPane tp, String msg, Color c){
		StyleContext sc = StyleContext.getDefaultStyleContext();
		AttributeSet aset = sc.addAttribute(SimpleAttributeSet.EMPTY, StyleConstants.Foreground, c);
		             aset = sc.addAttribute(aset, StyleConstants.FontFamily, "Lucida Console");
		             aset = sc.addAttribute(aset, StyleConstants.Alignment, StyleConstants.ALIGN_JUSTIFIED);

		tp.setCaretPosition(tp.getDocument().getLength());
		tp.setCharacterAttributes(aset, false);
		tp.replaceSelection(msg);
	}
	
	public MyFrame(){
		setTitle("Simple GUI");
		setSize(600, 400);

		Container contenedor = getContentPane();
		contenedor.setLayout(new BorderLayout());
		setContentPane(contenedor);

		textArea = new JTextPane();
		textArea.setSize(400,200);
		textArea.setMargin(new Insets(5, 5, 5, 5));
		appendToPane(textArea, "/* Information window for user interaction with the agent */", Color.BLUE);
		appendToPane(textArea, System.lineSeparator(), Color.BLUE);
		appendToPane(textArea, System.lineSeparator(), Color.BLUE);

		scroll = new JScrollPane(textArea);

		textField = new JTextField(40);
		textField.setText("User Input Area");
		textField.setEditable(true);

		boton = new JButton("Send");
		boton.setSize(100,50);

		JPanel panel = new JPanel(new FlowLayout());
		panel.add(boton);
		panel.add(textField);

		contenedor.add(scroll, BorderLayout.CENTER);
		contenedor.add(panel,  BorderLayout.SOUTH);
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
