var dirURI = fl.scriptURI.substring(0, fl.scriptURI.lastIndexOf("build"));

fl.outputPanel.clear();
var isnew = fl.documents.length == 0;

var buildVersion = "";
var buildStage = "";
var buildNumber = "";
var buildpropfile=dirURI+"build/build.properties";
var txt=FLfile.read(buildpropfile);
var lines=txt.split("\r\n");
for(var i = 0; i<lines.length; i++){
	var line = lines[i];
	var parts = line.split("=");
	var key = parts[0];
	var val = parts[1];
	if(key == "build.version")
	{
		version = parts[1];
	}
	if(key == "build.stage")
	{
		buildStage = parts[1];
	}
	if(key == "build.number")
	{
		buildNumber = parts[1];
	}
}
fl.trace("Version: "+version+" "+buildStage+". build:"+buildNumber);

var flaPath = dirURI+"samples/flash/sample.fla";
var swcPath = dirURI+"bin/Console"+version+buildStage+".swc";

fl.openDocument(flaPath);
var document = fl.getDocumentDOM();
var library = document.library;


fl.trace("Output SWC path: "+swcPath);
for each (var item in library.items)
{
	if (item.symbolType == "movie clip" && item.name == "Console")
	{
		fl.trace("Found Console MC");
		library.editItem(item.name);
      		var timeline = document.getTimeline();
		for(var j=0; j < timeline.layers.length; j++){
			for(var k=0; k < timeline.layers[j].frames.length; k++){
				var elements = timeline.layers[j].frames[k].elements;
				for(var l in elements){
					var element = elements[l];
					if(element.elementType == "text"){
						fl.trace("Found version text field!");
						element.setTextString(version+(buildStage?(" "+buildStage):"")+", build "+buildNumber);
					}
				}
			}
		}
		item.exportSWC(swcPath);
		fl.trace("Exported!");
		break;
	}
}

fl.trace("Publishing document");
document.publish();
fl.trace("Published!");

if(isnew)
{
	fl.quit();
}