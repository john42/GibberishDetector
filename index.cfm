<cfscript>
cfparam (name="t", default=""); // Input text to be checked

doReload = (lcase(t) eq "reload"); // Reload pre-trained settings
doTrain = (lcase(t) eq "train");   // Retrain and generate fresh JSON

if (not structKeyExists(application, "objGibberishDetector")) {
    writeoutput("Loading Gibberish Detector<br><br>");
    application.objGibberishDetector = CreateObject("component", "GibberishDetector");
}
else if (doReload) {
    writeoutput("Loading Gibberish Detector<br><br>");
    application.objGibberishDetector.load();
    
    t = "";

    // Loading or Initialization when object is created causes the default Gibberish.json file to be loaded
    // Use the following load function to load a different pre-trained file

    //  mf = "#GetDirectoryFromPath(GetCurrentTemplatePath())#/Gibberish.json";
    //  application.objGibberishDetector.load(mf);
}
else if (doTrain) {
    writeoutput("Training Gibberish Detector<br><br>");
    json = trainDetector();
    
    t = "";
}

resultText = (application.objGibberishDetector.isGibberish(t)) ? "Text is Gibberish" : "Text is good";
</cfscript>

<cfoutput>
Gibberish Detector<br><br>
<form method="post">
<div>
<div style="vertical-align: text-top;">Text to check for Gibberish:</div> <input type="text"area" name="t" value="#t#" size="100" maxlen="250" autofocus>
<br>
Enter 'reload' to reload pre built json settings file<br>
Enter 'train' to retrain using text files and display new json settings
</div>
<br>
#resultText#
<br><br>
<button type="submit">Check</button>
</form>
</cfoutput>

<cfscript>
if (doTrain) {
    writeoutput("Training Gibberish Detector<br><br>");
    writeOutput("Save the following JSON to Gibberish.json to load pre-trained values from default JSON<br><br>");
    writeDump(json);
    writeOutput("<br><br>");
}

string function trainDetector () {
    var p = GetDirectoryFromPath(GetCurrentTemplatePath());

    var tl = fileRead("#p#/TrainingFiles/big.txt");
    var tg = fileRead("#p#/TrainingFiles/good.txt");
    var tb = fileRead("#p#/TrainingFiles/bad.txt");

    return application.objGibberishDetector.train(tl, tg, tb, "");
}
</cfscript>