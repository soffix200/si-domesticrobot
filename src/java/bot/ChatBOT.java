package bot;

import cartago.*;

import java.io.*;
import java.io.File;   
import java.io.BufferedReader;
import java.io.InputStreamReader;    

import java.util.*;
import java.util.Locale;
import java.util.logging.Logger; 
import java.util.Properties;                  

import org.alicebot.ab.Bot;
import org.alicebot.ab.Chat;
import org.alicebot.ab.History;
import org.alicebot.ab.MagicBooleans;
import org.alicebot.ab.MagicStrings;
import org.alicebot.ab.utils.IOUtils;

import org.json.*;
import org.json.JSONArray;   

public class ChatBOT extends Artifact {

	private String botName;
	private String actualPath = getResourcesPath();

	private Bot    bot;
	private Chat   chatSession;

	void init(String botName) {
		this.botName     = botName;
		this.actualPath  = getResourcesPath();
		this.bot         = new Bot(this.botName, this.actualPath);
		this.chatSession = new Chat(this.bot);

		defineObsProperty("bot",botName);

		MagicBooleans.trace_mode = false;
	}

	@OPERATION void chat(String request) {
		String toproc = request.replaceAll("\\.", "<point>");
		String response = chatSession.multisentenceRespond(toproc)
		                  .replaceAll("&lt;", "<").replaceAll("&gt;", ">")
											.replaceAll("<point>", "\\.");
		signal("answer", response);
	}

	@OPERATION void chatSincrono(String request, OpFeedbackParam<String> answer) {
		String toproc = request.replaceAll("\\.", "<point>");
		String response = chatSession.multisentenceRespond(toproc)
		                  .replaceAll("&lt;", "<").replaceAll("&gt;", ">")
											.replaceAll("<point>", "\\.");
		answer.set(response);
	}

	private static String getResourcesPath() {
		File currDir = new File(".");
		String path = currDir.getAbsolutePath();
		       path = path.substring(0, path.length() - 2);
		String resourcesPath = path + File.separator + "src" + File.separator + "resources";
		return resourcesPath;
	}

}
