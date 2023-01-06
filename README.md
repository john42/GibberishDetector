# GibberishDetector-CFC

Ported to ColdFusion by John Thwaites.

Based on a port to Java by Shir Fiszman
Based on Python gibberish detector written by Rob Renaud.

You can find the original here: https://github.com/john42/GibberishDetector-CFC

This gibberish detector is not limmited to a certain language, and can be trained on files by the user's choice.

# How to use this library?
Creating an instance of GibberishDetector.cfc will load the default pre-built configuration based on the supplied training files.
The default configuration is loaded from the Gibberish.json file but a different configuration can be loaded from any json file.
Use the 'isGibberish' method in order to determine if a sentence is gibberish or not.

If you wish to select your own heuristic for setting the thrshold to classify sentences, you can override the method 'getThreshold'
and implement it yourself.

# Content
Coldfusion files:
- GibberishDetector.cfc - The core object that handles all functionality
- Index.cfm - Small one page application that allows testing and generation of the pre-build settings
- Application.cfc - Base bones Application object to persist object instance for testing

text files:
- big.txt, good.txt, bad.txt - text files used as inputs to train for english gibberish detector. Enhanced files from original.


# License

GibberishDetector-CFC is available under the MIT License.  See [LICENSE.txt](LICENSE.txt).
