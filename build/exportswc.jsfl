var dirURI = fl.scriptURI.substring(0, fl.scriptURI.lastIndexOf("build"));

var flaPath = dirURI+"samples/flash/sample.fla";
var swcPath = dirURI+"bin/Console.swc";

fl.openDocument(flaPath);
fl.outputPanel.clear();
var document = fl.getDocumentDOM();
var library = document.library;

fl.trace("Output SWC path: "+swcPath);

for each (var item in library.items)
{
	if (item.symbolType == "movie clip" && item.name == "Console")
	{
		fl.trace("Found Console MC");
		item.exportSWC(swcPath);
		fl.trace("Exported!");
	}
}
fl.trace("Publishing document");
document.publish();
fl.trace("Published!");