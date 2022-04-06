// Environment code for project prueba.mas2j
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
	
    /** Called before the MAS execution with the args informed in .mas2j */
    private Logger logger = Logger.getLogger("prueba.mas2j."+Chat.class.getName());
	private String botName;
	private String actualPath = getResourcesPath();

	private Bot bot;
	private Chat chatSession;
	private String response = "No tengo nada que decir";       
	
	void init(String botName) {
        this.botName = botName;
		bot = new Bot(botName, actualPath);
		chatSession  = new Chat(bot);
		
		defineObsProperty("bot",botName);
		logger.info(" Defino la propiedad: bot("+ botName +")");
		//defineObsProperty("response",response);
		//logger.info(" Defino la propiedad: response("+ response +")");
		logger.info("Me encuentro en el directorio: "+actualPath);

		MagicBooleans.trace_mode = false;
		bot.brain.nodeStats();                                                 
    }

	@OPERATION void chat (String request) {
		//logger.info(" He recibido el request: "+ request);
		
		response = chatSession.multisentenceRespond(request);
			
		while (response.contains("&lt;")) response = response.replace("&lt;", "<");
		while (response.contains("&gt;")) response = response.replace("&gt;", ">");
					
		signal("answer",response);
			
	}
 
	@OPERATION void chatSincrono (String request, OpFeedbackParam<String> answer) {
		//logger.info(" He recibido el request: "+ request);
		
		response = chatSession.multisentenceRespond(request);
			
		while (response.contains("&lt;")) response = response.replace("&lt;", "<");
		while (response.contains("&gt;")) response = response.replace("&gt;", ">");
				
		answer.set(response);

	}
 
 	private String parseResult(String inputJson) throws Exception {
  
		// inputJson for word 'hello' translated to language Hindi from English-
  
		JSONArray jsonArray = new JSONArray(inputJson);
		JSONArray jsonArray2 = (JSONArray) jsonArray.get(0);
		JSONArray jsonArray3 = (JSONArray) jsonArray2.get(0);
  
		return jsonArray3.get(0).toString();
	}

	private static String getResourcesPath() {
		File currDir = new File(".");
		String path = currDir.getAbsolutePath();
		path = path.substring(0, path.length() - 2);
		//System.out.println(path);
		//logger.info(path);
		String resourcesPath = path + File.separator + "src" + File.separator + "resources";
		return resourcesPath;
	}
	

}

