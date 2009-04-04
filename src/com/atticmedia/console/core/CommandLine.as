/*
* 
* Copyright (c) 2008 Atticmedia
* 
* @author 		Lu Aye Oo
*
* This software is provided 'as-is', without any express or implied
* warranty.  In no event will the authors be held liable for any damages
* arising from the use of this software.
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
* 1. The origin of this software must not be misrepresented; you must not
* claim that you wrote the original software. If you use this software
* in a product, an acknowledgment in the product documentation would be
* appreciated but is not required.
* 2. Altered source versions must be plainly marked as such, and must not be
* misrepresented as being the original software.
* 3. This notice may not be removed or altered from any source distribution.
* 
* 
*/
package com.atticmedia.console.core {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;	
	
	public class CommandLine extends EventDispatcher {

		public static const SEARCH_REQUEST:String = "SearchRequest";
		
		private var _saved:Weak;
		private var _lastSearchTerm:String;
		private var _reportFunction:Function;
		
		public var reserved:Array;
		public var useStrong:Boolean;

		public function CommandLine(base:Object, reportFunction:Function = null) {
			_reportFunction = reportFunction;
			_saved = new Weak();
			_saved.set("_base",base);
			_saved.set("_returned",base);
			reserved = new Array("_base", "_returned","_returned2","_lastMapBase");
		}
		public function set base(obj:Object):void {
			var old:Object = _saved.get("_base");
			_saved.set("_base",obj,useStrong);
			if (old) {
				report("Set new commandLine base from "+old+ " to "+ obj, 10);
			}else{
				_saved.set("_returned",obj,useStrong);
			}
		}
		public function get base():Object {
			return _saved.get("_base");
		}
		public function destory():void {
			_saved = null;
			_reportFunction = null;
			reserved = null;
		}
		public function store(n:String, obj:Object, strong:Boolean = false):String {
			n = n.replace(/[^\w]*/g, "");
			if(reserved.indexOf(n)>=0){
				report("ERROR: The name ["+n+"] is reserved",10);
				return null;
			}else{
				// if it is a function it needs to be strong reference atm, 
				// otherwise it fails if the function passed is from a dynamic class/instance
				_saved.set(n, obj, strong?true:(obj is Function?true:useStrong));
			}
			return n;
		}
		public function get searchTerm():String{
			return _lastSearchTerm;
		}
		public function run(str:String):Object {
			report("&gt; "+str, -1);
			var returned:Object;
			var line:Array = str.split(" ");
			if(line[0].charAt(0)=="/"){
				if (line[0] == "/help") {
					printHelp();
				} else if (line[0] == "/remap") {
					// this is a special case... no user will be able to do this command
					line.shift();
					reMap(line.join(""));
				} else if (line[0] == "/strong") {
					if(line[1] == "true"){
						useStrong = true;
						report("Now using STRONG referencing.", 10);
					}else if (line[1] == "false"){
						useStrong = false;
						report("Now using WEAK referencing.", 10);
					}else if(useStrong){
						report("Using STRONG referencing. '/strong false' to use weak", -2);
					}else{
						report("Using WEAK referencing. '/strong true' to use strong", -2);
					}
				} else if (line[0] == "/save") {
					if (_saved.get("_returned")) {
						if(!line[1]){
							report("ERROR: Give a name to save.",10);
						}else if(reserved.indexOf(line[1])>=0){
							report("ERROR: The name ["+line[1]+ "] is reserved",10);
						}else{
							_saved.set(line[1], _saved.get("_returned"),useStrong);
							report("SAVED "+getQualifiedClassName(_saved.get("_returned")) + " at "+ line[1]);
						}
					} else {
						report("Nothing to save", 10);
					}
				} else if (line[0] == "/filter") {
					_lastSearchTerm = str.substring(8);
					dispatchEvent(new Event(SEARCH_REQUEST));
				} else if (line[0] == "/inspect" || line[0] == "/inspectfull") {
					if (_saved.get("_returned")) {
						var viewAll:Boolean = (line[0] == "/inspectfull")? true: false;
						report(inspect(_saved.get("_returned"),viewAll));
					} else {
						report("Empty", 10);
					}
				} else if (line[0] == "/map") {
					if (_saved.get("_returned")) {
						map(_saved.get("_returned") as DisplayObjectContainer);
					} else {
						report("Empty", 10);
					}
				} else if (line[0] == "/base" || line[0] == "//") {
					var o:Object = line[0] == "//"?_saved.get("_returned2"):_saved.get("_base");
					_saved.set("_returned2",_saved.get("_returned"),useStrong);
					_saved.set("_returned", o,useStrong);
					report("Returned "+ getQualifiedClassName(o) +": "+o,10);
				} else{
					report("Undefined commandLine syntex <b>/help</b> for info.",10);
				}
			
			}else {
				
				try {
					
					// Get objects and values before operation, such as (, ), =
					var names:Array = new Array();
					var values:Array = new Array();
					line = str.split(/( |=|;)/);
					var lineLen:int = line.length;
					for (var i:int = 0;i<lineLen;i++){
						var strPart:String = line[i];
						if(!strPart || strPart==" " || strPart=="" || strPart==";"){
							// ignore
						}else if(strPart=="="){
							names.push(strPart);
							values.push(strPart);
						} else{
							var arr:Array = getPartData(line[i]);
							names.push(arr[0]);
							values.push(arr[1]);
						}
					}
					
					// APPLY operation
					for(i = 0;i<names.length;i++){
						strPart = names[i];
						if(strPart == "="){
							var tarValArr:Array = values[i-1];
							var tarNameArr:Array = names[i-1];
							var srcValueArr:Object = values[i+1];
							
							tarValArr[1][tarNameArr[0]] = srcValueArr[0];
							i++;
							report("SET "+getQualifiedClassName(tarValArr[1])+"."+tarNameArr[0]+" = "+srcValueArr[0], 10);
							returned = null;
						}else{
							returned = values[i][0];
						}
					}
					
					if (returned == null) {
						report("Ran successfully.",1, false, true);
					}else{
						var newb:Boolean = false;
						if(typeof(returned) == "object" && !(returned is Array) && !(returned is Date)){
							newb = true;
							_saved.set("_returned2",_saved.get("_returned"),useStrong);
							_saved.set("_returned", returned,useStrong);
						}
						report((newb?"+ ":"")+"Returned "+ getQualifiedClassName(returned) +": "+returned,10);
					}
				}catch (e:Error) {
					report(e.getStackTrace(),10);
				}
			}
			return returned;
		}
		private function getPartData(strPart:String):Array{
			try{
				var base:Object = _saved.get("_returned");
				var partNames:Array = new Array();
				var partValues:Array = new Array();
				
				if(strPart.charAt(0)=="*"){
					partNames.push(strPart.substring(1));
					partValues.push(getDefinitionByName(strPart.substring(1)));
				}else if(isTypeable(strPart)){
					partNames.push(strPart);
					partValues.push(reType(strPart));
				}else{
					var dotParts:Array = strPart.split(/(\.|\(|\)|\,)/);
					var dotLen:int = dotParts.length;
							
					var obj:Object = null;
					
					for(var j:int = 0;j<dotLen;j++){
						var dotPart:String = dotParts[j];
						if(dotPart.charAt(0)=="."){
							dotPart = null;
						}else if(dotPart.charAt(0)=="("){
							var funArr:Array = new Array();
							var endIndex:int = dotParts.indexOf(")", j);
							
							for(var jj:int = (j+1);jj<endIndex;jj++){
								if(dotParts[jj] && dotParts[jj] != ","){
									var data:Array = getPartData(dotParts[jj]);
									funArr.push(data[1][0]);
								}
							}
							obj = (obj as Function).apply(base,funArr);
							j = endIndex+1;
						}else if(dotPart.charAt(0)==","){
							dotPart = null;
						}else if(dotPart.charAt(0)==")"){
							dotPart = null;
						}else if(dotPart.charAt(0)=="$"){
							obj = _saved.get(dotPart.substring(1));
						}else if(dotLen == 1 && !base.hasOwnProperty(dotPart)){
							// this could be a string without '...'
							partNames.unshift(dotPart);
							partValues.unshift(dotPart);
							report("Assumed "+dotPart+" is a String as "+getQualifiedClassName(base)+" do not have this property.", 7, false, true);
							break;
						}else if(!obj){
							partNames.unshift(base);
							partValues.unshift(base);
							obj = base[dotPart];
						}else{
							obj = obj[dotPart];
						}
						if(dotPart){
							partNames.unshift(dotPart);
							partValues.unshift(obj);
						}
					}
				}
				if(partNames.length>0){
					return [partNames,partValues];
				}
			}catch(e:Error){
				report(e.getStackTrace(),10);
			}
			return [strPart,strPart];
		}
		private function isTypeable(str:String):Boolean{
			if (str == "true" || str == "false" || str == "this" || str == "null" || str == "NaN" || !isNaN(Number(str))) {
				return true;
			}
			if(str.charAt(0) == "'" && str.charAt(str.length-1) == "'"){
				return true;
			}
			return false;
		}
		private function reType(str:String):Object{
			if (str == "true") {
				return true;
			}else if (str == "false") {
				return false;
			}else if (str == "this") {
				return _saved.get("_returned");
			}else if (!isNaN(Number(str))) {
				return Number(str);
			}else if (str == "null") {
				return null;
			}else if (str == "NaN") {
				return NaN;
			}else if(str.charAt(0) == "'" && str.charAt(str.length-1) == "'"){
				return str.substring(1,(str.length-1));
			}
			return str;
		}
		public function inspect(obj:Object, viewAll:Boolean= true):String {
			var typeStr:String = getQualifiedClassName(obj);
			var str:String = "<font color=\"#FF6600\"><b>"+obj+" => "+typeStr+"</b></font><br>";
			var suptypeStr:String = getQualifiedSuperclassName(obj);
			str += "<font color=\"#FF6600\">"+suptypeStr+"</font><br>";

			if ( typeof(obj) == "object") {
				var V:XML = describeType(obj);
				str += "<font color=\"#FF0000\"><b>Methods:</b></font> ";
				var nodes:XMLList = V..method;
				for each (var node:XML in nodes) {
					if ( typeStr == node.@declaredBy || viewAll) {
						str += "<b>"+node.@name+"</b>(<i>"+node.children().length()+"</i>):"+node.@returnType+"; ";
					}
				}
				str += "<br><font color=\"#FF0000\"><b>Accessors:</b></font> ";
				nodes = V..accessor;
				for each (node in nodes) {
					if ( typeStr == node.@declaredBy || viewAll) {
						var s:String = (node.@access=="readonly") ? "<i>"+node.@name+"</i>" : node.@name;
						if(viewAll){
							try {
								str += "<br><b>"+s+"</b>="+ obj[node.@name];
							}catch (e:Error){
								str += "<br><b>"+s+"</b>; ";
							}
						}else{
							str += s+"; ";
						}
					}
				}
				var vals:String = "";
				for (var X:String in obj) {
					vals += X +"="+obj[X]+"; ";
				}
				if (vals) {
					str += "<br><font color=\"#FF0000\"><b>Values:</b></font> ";
					str += vals;
				}
				if (obj is DisplayObjectContainer) {
					var mc:DisplayObjectContainer = obj as DisplayObjectContainer;
					str += "<br><font color=\"#FF0000\"><b>Children:</b></font> ";
					var clen:int = mc.numChildren;
					for (var ci:int = 0; ci<clen; ci++) {
						var child:DisplayObject = mc.getChildAt(ci);
						str += "<b>"+child.name+"</b>:("+ci+")"+getQualifiedClassName(child)+"; ";
					}
					var theParent:DisplayObjectContainer = mc.parent;
					if (theParent) {
						str += "<br><font color=\"#FF0000\"><b>Parents:</b></font> ("+theParent.getChildIndex(mc)+"), ";
						while (theParent) {
							var pr:DisplayObjectContainer = theParent;
							theParent = theParent.parent;
							str += "<b>"+pr.name+"</b>:("+(theParent?theParent.getChildIndex(pr):"")+")"+getQualifiedClassName(pr)+"; ";
						}
					}
				}
			} else {
				str += String(obj);
			}
			return str;
		}
		public function map(base:DisplayObjectContainer):void{
			if(!base){
				report("It is not a DisplayObjectContainer", 10);
				return;
			}
			_saved.set("_lastMapBase", base,useStrong); 
			
			var list:Array = new Array();
			var index:int = 0;
			list.push(base);
			while(index<list.length){
				var mcDO:DisplayObject = list[index];
				if(mcDO is DisplayObjectContainer){
					var mc:DisplayObjectContainer = mcDO as DisplayObjectContainer;
					var numC:int = mc.numChildren;
					for(var i:int = 0;i<numC;i++){
						var child:DisplayObject = mc.getChildAt(i);
						list.splice((index+i+1),0,child);
					}
				}
				index++;
			}
			
			var steps:int = 0;
			var lastmcDO:DisplayObject = null;
			var indexes:Array = new Array();
			for (var X:String in list){
				mcDO = list[X];
				if(lastmcDO){
					if(lastmcDO is DisplayObjectContainer && (lastmcDO as DisplayObjectContainer).contains(mcDO)){
						steps++;
						//indexes.push((lastmcDO as DisplayObjectContainer).getChildIndex(mcDO));
						indexes.push(mcDO.name);
					}else{
						while(lastmcDO){
							lastmcDO = lastmcDO.parent;
							if(lastmcDO is DisplayObjectContainer){
								if(steps>0){
									indexes.pop();
									steps--;
								}
								if((lastmcDO as DisplayObjectContainer).contains(mcDO)){
									steps++;
									indexes.push(mcDO.name);
									break;
								}
							}
						}
					}
				}
				var str:String = "";
				for(i=0;i<steps;i++){
					str += (i==steps-1)?" ∟ ":" - ";
				}
				var n:String = "<a href='event:clip_"+indexes.join("|")+"'>"+mcDO.name+"</a>";
				if(mcDO is DisplayObjectContainer){
					n = "<b>"+n+"</b>";
				}else{
					n = "<i>"+n+"</i>";
				}
				str += n+" ("+getQualifiedClassName(mcDO)+")";
				report(str,mcDO is DisplayObjectContainer?5:2, true);
				lastmcDO = mcDO;
			}
			
			report(base.name+":"+getQualifiedClassName(base)+" has "+list.length+" children/sub-children.", 10);
			report("Click on the name to return a reference to the child clip. <br/>Note that clip references will be broken when display list is changed",-2);
		}
		private function reMap(path:String):void{
			var mc:DisplayObjectContainer = _saved.get("_lastMapBase") as DisplayObjectContainer;
			var pathArr:Array = path.split("|");
			var child:DisplayObject = mc as DisplayObject;
			try{
				if(path.length>0){
					for each(var ind:String in pathArr){
						child = mc.getChildByName(ind);
						if(child is DisplayObjectContainer){
							//mc = mc.getChildAt(ind) as DisplayObjectContainer;
							mc = child as DisplayObjectContainer;;
						}else{
							// assume it reached to end since there can no longer be a child
							break;
						}
					}
				}
				_saved.set("_returned", child,useStrong);
				report("Returned "+ child.name +": "+getQualifiedClassName(child),10);
			} catch (e:Error) {
				report("Problem getting the clip reference. Display list must have changed since last map request",10);
				report(e.getStackTrace(),10);
			}
		}
		private function printHelp():void {
			report("____Command Line Help___",10);
			report("Gives you limited ability to read/write/execute properties and methods of anything in stage or to static classes",0);
			report("__Example: ",10);
			report("root.mc => <b>root.mc</b>",5);
			report("(save mc's reference) => <b>/save mc</b>",5);
			report("(load mc's reference) => <b>$mc</b>",5);
			report("root.mc.myProperty => <b>$mc.myProperty</b>",5);
			report("root.mc.myProperty = \"newProperty\" => <b>$mc.myProperty = 'newProperty'</b>",5);
			report("(view info) => <b>/inspect</b>",5);
			report("(view all info) => <b>/inspectfull</b>",5);
			report("(see display map) => <b>/map</b>",5);
			report("__Use * to access static classes",10);
			report("com.atticmedia.console.C => <b>*com.atticmedia.console.C</b>",5);
			report("(save reference) => <b>/save c</b>",5);
			report("com.atticmedia.console.C.add('test',10) => <b>$c.add('test',10)</b>",5);
			report("Strings can not have spaces...",7);
			report("__Filtering:",10);
			report("/filter &lt;text you want to filter&gt;",5);
			report("This will create a new channel called filtered with all matching lines",5);
			report("__Other useful examples:",10);
			report("<b>stage.width</b>",5);
			report("<b>stage.scaleMode = 'noScale'</b>",5);
			report("<b>stage.frameRate = 12</b>",5);
			report("__________",10);
		}
		private function report(txt:String, prio:Number=5, skipSafe:Boolean = false, quiet:Boolean = false):void {
			if (_reportFunction != null) {
				_reportFunction(new LogLineVO(txt,null,prio,false,skipSafe), quiet);
			} else {
				trace("C: "+ txt);
			}
		}
	}
}