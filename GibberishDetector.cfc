component {

/* 
Based on Python gibberish detector written by Rob Renaud. 
Ported into Java by Shir Fiszman.
Ported into CFScript by John Thwaites and heavily modified.

You can find the original here: https://github.com/rrenaud/Gibberish-Detector
The Java version here: https://github.com/paypal/Gibberish-Detector-Java
*/

variables.trained = false;	// Trained if settings loaded from JSon or trainig text used
variables.MIN_COUNT_VAL = 10;
variables.maxAcronymLen = 6;
variables.settings = structNew();
variables.settings.spaceCharacter = " ";
variables.settings.alphabet = "abcdefghijklmnopqrstuvwxyz";
variables.settings.alphabetUCase = ucase("abcdefghijklmnopqrstuvwxyz");
variables.settings.threshold = 0;
variables.settings.logProbabilityMatrix = structNew();

variables.defaultTrainingText = "some text";
variables.defaultGoodText = "This is good text for the gibberish detector";
variables.defaultBadText = "qweqwe adfasdfa sdfasfasdf asdfasdfasfasdfaseqw";

//variable.timer = getTickCount();

load();

/* 
	Load settings an precalculated probability matrix from JSON file.
	If no file supplied then defaults to gibberish.json in same directory
*/
public function load(string aFile="") {
	var sf = (aFile neq "") ? aFile : GetDirectoryFromPath(GetCurrentTemplatePath()) & "/gibberish.json";
	
	if (fileExists(sf)) {
		var js = fileRead(sf);
		variables.settings = DeserializeJSON(js, true);
		variables.settings.alphabetUCase = ucase(variables.settings.alphabet);
		variables.trained = true;
	}
	else {
		train(variables.defaultTrainingText, variables.defaultGoodText, variables.defaultBadText, variables.settings.alphabet);
	}
}

/**
 * determines if a sentence is gibberish or not.
 * @param text to be classified as gibberish or not.
 * @return true if the sentence is gibberish, false otherwise.
 * 
 * If not Trained then always return False
 */
public boolean function isGibberish(required string text) {
	return variables.trained and (getAvgTransitionProbability(text, variables.settings.logProbabilityMatrix, true) le variables.settings.threshold);
}

private numeric function getAvgTransitionProbability(required string text, required struct logProbabilityMatrix, boolean aFilterAcronyms=false) {
	var logProb = 0;
	var transitionCount = 0;
	var normalizedText = normalize(text, aFilterAcronyms);

	for (var p = 1; p lt normalizedText.len() - 1; p++) {
		var c1 = normalizedText.mid(p, 1);
		var c2 = normalizedText.mid(p+1, 1);

		logProb += variables.settings.logProbabilityMatrix[c1][c2];
		transitionCount++;				
	}

	return exp(logProb / max(transitionCount, 1));
}

/* Filter non alphabet characters (keep spaces) */
private string function normalize(required string aText, boolean aFilterAcronyms="false") {
 	// Replace all non alpha characters with space. 
	// Need to keep space to allow filtering of Acronyms
	var r = REReplace(" " & aText & " ","[^#variables.settings.alphabet##variables.settings.alphabetUCase#]"," ","all");

	if (aFilterAcronyms) {
		r = filterAcronyms(r);
	}
 
	if (variables.settings.spaceCharacter neq " ")
		// Replace all spaces with special Space Character so compare to matrix works
		r = r.replace(" ", variables.settings.spaceCharacter, "All");

	return lcase(r);
}

/* filter out upper case words less than max acronym length */
private string function filterAcronyms(required string aText) {
	var r = aText;
	var a = reMatch("\b[#variables.settings.alphabetUCase#]+\b", " " & r & " ");

	for (var w in a) {
		if (trim(w) neq '') {
			if (w.len() lt variables.maxAcronymLen + 2) {
				r = r.replace(w, " ", "all");
			}
		}
	}
	return r;
}

/* TRAINING FUNCTIONS */

/*
	Trains algorithm from sample files and builds probability matrix.
	Returns JSon version of training restults so they can 
	be samed to a JSon file to be used by the load function to 
	make start up much faster.
*/
public string function train(required string trainingText, required string goodText, required string badText, required String alphabet) {
	variables.trained = false;

	if (trim(alphabet) neq "") {
		variables.settings.alphabet = trim(alphabet);
		variables.settings.alphabetUCase = ucase(variables.settings.alphabet);
	}

	var alphabetCouplesMatrix = buildAlphaBetCouplesMatrix(trainingText);
	variables.settings.logProbabilityMatrix = buildLogProbabilityMatrix(alphabetCouplesMatrix);

	var goodProbability = getAvgTransitionProbability(goodText, variables.settings.logProbabilityMatrix);
	var badProbability = getAvgTransitionProbability(badText, variables.settings.logProbabilityMatrix);

	variables.settings.threshold = getThreshold(goodProbability, badProbability);

	if (trim(trainingText) neq "") {
		if (goodProbability <= badProbability) {
			throw("cannot create a threshold");
		}
		variables.trained = true;
	}

	return SerializeJSON(variables.settings);
}

/* populate matrix with touple (letter pair) counts */
private struct function buildAlphaBetCouplesMatrix(required string trainingText) {
	var counts = buildNewArrayStruct(variables.MIN_COUNT_VAL);
	var normalizedText = normalize(trainingText);

	for (var p = 1; p lt normalizedText.len() - 2; p++) {
		var c1 = normalizedText.mid(p, 1);
		var c2 = normalizedText.mid(p+1, 1);

		if (not (c1 eq "" and c2 eq ""))	// FIlter out if we have 2 spaces together
			counts[c1][c2]++;				
	}

	return duplicate(counts);
}

/* populate matrix with letter pair probabilities */
private struct function buildLogProbabilityMatrix(required struct alphabetCouplesMatrix) {
	var logProbabilityMatrix = buildNewArrayStruct(0);
	for (var i in structKeyList(alphabetCouplesMatrix)) {
		var sum = getSum(alphabetCouplesMatrix[i]); 
		for (var j in  structKeyList(alphabetCouplesMatrix[i])) {				
			logProbabilityMatrix[i][j] = log(alphabetCouplesMatrix[i][j]/sum);
		}
	}
	return duplicate(logProbabilityMatrix);
}

/* sum values in provided structure */
private numeric function getSum(required struct aValues) {
	var sum = 0; 
	for (var i in structKeyList(aValues)) {
		sum += aValues[i];
	}
	return sum; 
}

// can be overridden for another threshold heuristic implementation
private numeric function  getThreshold(required numeric minGood, required numeric maxBad) {
	return (minGood + maxBad) / 2;
}



/* ADDED FUNCTIONS */

/* 
	Build an structure matrix keyed on alphabet elements
	and populate with value
 */
private struct function buildNewArrayStruct(required numeric aValue) {
	var r = structNew();
	var alphabetChars = rematch(".",variables.settings.alphabet & variables.settings.spaceCharacter);	// Convert string to array of characters

	for (var c1 in alphabetChars) {
		for (var c2 in alphabetChars) {
			r[c1][c2] = aValue;
		}
	}
	return duplicate(r);
}
/* 
function displayTimer(required string aText) {
	var d = getTickCount() - variable.timer;
	
	writeoutput("#aText# #d#<br>");

	variable.timer = getTickCount();
}
 */
}
