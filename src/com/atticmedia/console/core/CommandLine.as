/*
* 
* Copyright (c) 2008-2009 Lu Aye Oo
* 
* @author 		Lu Aye Oo
* 
* http://code.google.com/p/flash-console/
* 
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
*/
package com.atticmedia.console.core {
	import flash.events.Event;

	import com.atticmedia.console.Console;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.EventDispatcher;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;		

	public class CommandLine extends EventDispatcher {
		public static const CHANGED_SCOPE:String = "changedScope";
		
		private static const VALUE_CONST:String = "^";
		private static const MAX_INTERNAL_STACK_TRACE:int = 1;
		
		private var _saved:WeakObject;
		
		private var _returned:*;
		private var _returned2:*;
		private var _mapBases:WeakObject;
		private var _mapBaseIndex:uint = 1;
		private var _reserved:Array;
		private var _values:Array;
		
		private var _master:Console;
		
		public var useStrong:Boolean;
		public var permission:uint = 1;	//TODO: to implement level 1 security

		public function CommandLine(m:Console) {
			_master = m;
			_saved = new WeakObject();
			_mapBases = new WeakObject();
			_returned = m;
			_saved.set("C", m);
			_reserved = new Array("base", "C");
		}
		public function set base(obj:Object):void {
			if (base) {
				report("Set new commandLine base from "+base+ " to "+ obj, 10);
			}else{
				_returned = obj;
				dispatchEvent(new Event(CHANGED_SCOPE));
			}
			_saved.set("base", obj, useStrong);
		}
		public function get base():Object {
			return _saved.get("base");
		}
		public function destory():void {
			_saved = null;
			_master = null;
			_reserved = null;
		}
		public function store(n:String, obj:Object, strong:Boolean = false):String {
			n = n.replace(/[^\w]*/g, "");
			if(_reserved.indexOf(n)>=0){
				report("ERROR: The name ["+n+"] is reserved",10);
				return null;
			}else{
				// if it is a function it needs to be strong reference atm, 
				// otherwise it fails if the function passed is from a dynamic class/instance
				_saved.set(n, obj, strong?true:(obj is Function?true:useStrong));
			}
			return n;
		}
		public function get scopeString():String{
			var str:String = getQualifiedClassName(_returned);
			var ind:int = str.lastIndexOf("::");
			if(ind>=0){
				str = str.substring(ind+2);
			}
			return str;
		}
		public function run(str:String):* {
			report("&gt; "+str,5, false);
			if(str.charAt(0) == "/"){
				try{
					doCommand(str);
				}catch(e:Error){
					reportStackTrace(e.getStackTrace());
				}
				return;
			}
			// incase you are calling a new command from commandLine... paradox?
			// EXAMPLE: $C.runCommand('/help') - but why would you?
			var isclean:Boolean = _values?false:true;
			if(isclean){
				_values = [];
			}
			// STRIP empty strings "",''
			var matchstring:String;
			var strReg:RegExp = /('')|("")/g;
			var result:Object = strReg.exec(str);
			while(result != null){
				var ind:int = result["index"];
				matchstring = result[0];
				str = Utils.replaceByIndexes(str, VALUE_CONST+_values.length, ind, ind+matchstring.length);
				_values.push(new Value("", "", matchstring));
				strReg.lastIndex = ind+1;
				result = strReg.exec(str);
			}
			// STRIP strings - '...' and "..." wihle ignoring \' \" inside.
			// have to do again after empty string strip because matching string got extra first char
			strReg = /([^\\]'(.*?[^\\])')|([^\\]"(.*?[^\\])")/g;
			result = strReg.exec(str);
			while(result != null){
				matchstring = result[0];
				var substring:String = result[2]?result[2]:result[4]?result[4]:"";
				var ind2:int = result["index"]+matchstring.indexOf(substring);
				strReg.lastIndex = ind2+1;
				str = Utils.replaceByIndexes(str, VALUE_CONST+_values.length, ind2-1, ind2+substring.length+1);
				report(VALUE_CONST+_values.length+" = "+substring, 2, false);
				_values.push(new Value(substring));
				result = strReg.exec(str);
			}
			// All strings will have replaced by ^0, ^1, etc
			//
			// Run each line
			var v:* = null;
			var lineBreaks:Array = str.split(/\s*;\s*/);
			for each(var line:String in lineBreaks){
				if(line.length){
					v = runLine(line);
				}
			}
			if(isclean){
				_values = null;
			}
			return v;
		}
		// com.atticmedia.console.C.instance.visible
		// com.atticmedia.console.C.instance.addGraph('test',stage,'mouseX')
		// test('simple stuff. what ya think?');
		// test('He\'s cool! (not really)','',"yet 'another string', what ya think?");
		// this.getChildAt(0); 
		// stage.addChild(root.addChild(this.getChildAt(0)));
		// third(second(first('console'))).final(0).alpha;
		// getChildByName(String('Console')).getChildByName('message').alpha = 0.5;
		// getChildByName(String('Console').abcd().asdf).getChildByName('message').alpha = 0.5;
		// com.atticmedia.console.C.add('Hey how are you?');
		// $f = this;
		private function runLine(line:String):*{
			try{
				var majorParts:Array = line.split(/\s*\=\s*/);
				majorParts.reverse();
				var v:Value = execChunk(majorParts[0]);
				for(var i:int = 1;i<majorParts.length;i++){
					var vtoset:Value = execChunk(majorParts[i]);
					//report("Target base = "+vtoset.base + " prop = "+vtoset.prop);
					vtoset.base[vtoset.prop] = v.value;
					report("<b>SET</b> "+getQualifiedClassName(vtoset.base)+"."+vtoset.prop+" = <b>"+v.value+"</b>", -2);
				}
				doReturn(v.value);
				return v.value;
			}catch(e:Error){
				reportStackTrace(e.getStackTrace());
			}
			return null;
		}
		private function doReturn(returned:*, isNew:Boolean = false):void{
			var newb:Boolean = false;
			if(returned && (returned is Function || isNew || (returned != _returned && typeof(returned) == "object") && !(returned is Array) && !(returned is Date))){
				newb = true;
				_returned2 = _returned;
				_returned = returned;
				dispatchEvent(new Event(CHANGED_SCOPE));
			}
			report((newb?"<b>+</b> ":"")+"Returned "+ getQualifiedClassName(returned) +": <b>"+returned+"</b>", -2);
		}
		private function execChunk(line:String):Value{
			// exec values inside functions (params of functions)
			var indOpen:int = line.lastIndexOf("(");
			while(indOpen>0){
				var firstchar:String = line.charAt(indOpen+1);
				if(firstchar!=")"){
					// increment closing if there r more opening inside
					var indopen2:int = indOpen;
					var indClose:int = indOpen+1;
					while(indopen2>=0 && indopen2<indClose){
						indopen2++;
						indopen2 = line.indexOf("(",indopen2);
						indClose = line.indexOf(")",indClose+1);
					}
					//
					var inside:String = line.substring(indOpen+1, indClose);
					line = Utils.replaceByIndexes(line, VALUE_CONST+_values.length, indOpen+1, indClose);
					var params:Array = inside.split(",");
					_values.push(new Value(params));
					for(var X:String in params){
						params[X] = execNest(params[X].replace(/\s*(.+)\s*/,"$1")).value;
					}
					//report("^"+_values.length+" stores params ["+params+"]");
					//report(line);
				}
				indOpen = line.lastIndexOf("(", indOpen-1);
			}
			return execNest(line);
		}
		private function execNest(str:String):Value{
			var v:Value = new Value();
			
			var reg:RegExp = /\.|\(/g;
			var result:Object = reg.exec(str);
			if(result==null || !isNaN(Number(str))){
				return execValue(str, null);
			}
			// AUTOMATICALLY detect classes in packages rather than using *...* 
			var firstparts:Array = str.split("(")[0].split(".");
			if(firstparts.length>0){
				while(firstparts.length){
					var classstr:String = firstparts.join(".");
					try{
						var def:* = getDefinitionByName(classstr);
						var havemore:Boolean = str.length>classstr.length;
						//report(classstr+" is a class "+def);
						str = Utils.replaceByIndexes(str, VALUE_CONST+_values.length, 0, classstr.length);
						_values.push(new Value(def, def, classstr));
						if(havemore){
							reg.lastIndex = 0;
							result = reg.exec(str);
						}else{
							return execValue(str, null);
						}
						break;
					}catch(e:Error){
						firstparts.pop();
					}
				}
			}
			//
			// dot syntex and simple function steps
			//
			var previndex:int = 0;
			while(result != null){
				var index:int = result.index;
				var isFun:Boolean = str.charAt(index)=="(";
				var basestr:String = str.substring(previndex, index);
				//report("scopestr = "+basestr+ " v.base = "+v.base);
				var newv:Value = execValue(basestr, v.base);
				var newbase:* = newv.value;
				v.base = newv.base;
				//report("scope = "+newbase+"  isFun:"+isFun);
				if(isFun){
					var closeindex:int = str.indexOf(")", index);
					var paramstr:String = str.substring(index+1, closeindex);
					var params:Array = [];
					if(paramstr){
						params = execValue(paramstr).value;
					}
					//report("params = "+params.length+" - ["+ params+"]");
					v.value = (newbase as Function).apply(v.base, params);
					v.base = v.value;
					index = closeindex+1;
				}else{
					v.value = newbase;
				}
				v.prop = basestr;
				previndex = index+1;
				reg.lastIndex = index+1;
				result = reg.exec(str);
				if(result != null){
					v.base = v.value;
				}else if(index+1 < str.length){
					//report("no more result: index="+index+" str.length="+str.length);
					//report("LEFT: "+str.substring(index+1, str.length));
					v.base = v.value;
					reg.lastIndex = str.length;
					result = {index:str.length};
				}
			}
			return v;
		}
		private function execValue(str:String, base:* = null):Value{
			var nobase:Boolean = base?false:true;
			base = base?base:_returned;
			var v:Value = new Value(null, base, str);
			if (str == "true") {
				v.value = true;
			}else if (str == "false") {
				v.value = false;
			}else if (str == "this") {
				v.base = _returned;
				v.value = _returned;
			}else if (str == "null") {
				v.value = null;
			}else if (str == "NaN") {
				v.value = NaN;
			}else if (!isNaN(Number(str))) {
				v.value = Number(str);
			}else if(str.indexOf(VALUE_CONST)==0){
				var vv:Value = _values[str.substring(VALUE_CONST.length)];
				//report(VALUE_CONST+str.substring(VALUE_CONST.length)+" = " +vv);
				v.base = vv.base;
				v.value = vv.value;
			}else if(str.charAt(0) == "$"){
				v.base = _saved[str.substring(1)];
				v.value = v.base;
			}else if(nobase){
				try{
					v.value = getDefinitionByName(str);
					v.base = v.value;
				}catch(e:Error){
					v.value = v.base[str];
				}
			}else{
				v.value = v.base[str];
			}
			//report("value: "+str+" = "+getQualifiedClassName(v.value)+" - "+v.value+" base:"+v.base);
			return v;
		}
		private function doCommand(str:String):void{
			var brk:int = str.indexOf(" ");
			var cmd:String = str.substring(1, brk>0?brk:str.length);
			var param:String = brk>0?str.substring(brk+1):"";
			//report("doCommand: "+ cmd+(param?(": "+param):""));
			if (cmd == "help") {
				printHelp();
			} else if (cmd == "remap") {
				// this is a special case... no user will be able to do this command
				reMap(param);
			} else if (cmd == "strong") {
				if(param == "true"){
					useStrong = true;
					report("Now using STRONG referencing.", 10);
				}else if (param == "false"){
					useStrong = false;
					report("Now using WEAK referencing.", 10);
				}else if(useStrong){
					report("Using STRONG referencing. '/strong false' to use weak", -2);
				}else{
					report("Using WEAK referencing. '/strong true' to use strong", -2);
				}
			} else if (cmd == "save") {
				if (_returned) {
					if(!param){
						report("ERROR: Give a name to save.",10);
					}else if(_reserved.indexOf(param)>=0){
						report("ERROR: The name ["+param+ "] is reserved",10);
					}else{
						_saved.set(param, _returned,useStrong);
						report("SAVED "+getQualifiedClassName(_returned) + " at "+ param);
					}
				} else {
					report("Nothing to save", 10);
				}
			} else if (cmd == "string") {
				report("String with "+param.length+" chars stored. Use /save <i>(name)</i> to save.", -2);
				_returned = param;
				dispatchEvent(new Event(CHANGED_SCOPE));
			} else if (cmd == "saved") {
				report("Saved vars: ", -1);
				var sii:uint = 0;
				var sii2:uint = 0;
				for(var X:String in _saved){
					var sao:* = _saved[X];
					sii++;
					if(sao==null) sii2++;
					report("<b>$"+X+"</b> = "+(sao==null?"null":getQualifiedClassName(sao)), -2);
				}
				report("Found "+sii+" item(s), "+sii2+" empty (or garbage collected).", -1);
			} else if (cmd == "filter") {
				_master.filterText = str.substring(8);
			} else if (cmd == "inspect" || cmd == "inspectfull") {
				if (_returned) {
					var viewAll:Boolean = (cmd == "inspectfull")? true: false;
					report(inspect(_returned,viewAll), 5);
				} else {
					report("Empty", 10);
				}
			} else if (cmd == "map") {
				if (_returned) {
					map(_returned as DisplayObjectContainer);
				} else {
					report("Empty", 10);
				}
			} else if (cmd == "/") {
				doReturn(_returned2?_returned2:base);
			} else if (cmd == "base") {
				doReturn(base);
			} else if (cmd == "new") {
				// TODO: accept params
				doReturn(new (getDefinitionByName(param))(), true);
			}else{
				report("Undefined commandLine syntex <b>/help</b> for info.",10);
			}
		}
		private function reportStackTrace(str:String):void{
			var lines:Array = str.split(/\n\s*/);
			var p:int = 10;
			var internalerrs:int = 0;
			var self:String = getQualifiedClassName(this);
			var block:String = "";
			var len:int = lines.length;
			for (var i:int = 0; i < len; i++){
				var line:String = lines[i];
				if(MAX_INTERNAL_STACK_TRACE >=0 && line.search(new RegExp("\\s*at "+self)) == 0 ){
					// don't trace too many internal errors :)
					if(internalerrs>=MAX_INTERNAL_STACK_TRACE && i > 0) {
						break;
					}
					internalerrs++;
				}
				block += "<p"+p+">&gt;&nbsp;"+line.replace(/\s/, "&nbsp;")+"</p"+p+">\n";
				if(p>6) p--;
			}
			report(block, 9);
			
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
				for each (var method:XML in nodes) {
					if ( typeStr == method.@declaredBy || viewAll) {
						str += "<b>"+method.@name+"</b>(<i>"+method.children().length()+"</i>):"+method.@returnType+"; ";
					}
				}
				str += "<br><font color=\"#FF0000\"><b>Accessors:</b></font> ";
				nodes = V..accessor;
				var s:String;
				for each (var accessor:XML  in nodes) {
					if ( typeStr == accessor.@declaredBy || viewAll) {
						s = (accessor.@access=="readonly") ? "<i>"+accessor.@name+"</i>" : accessor.@name;
						if(viewAll){
							try {
								str += "<br><b>"+s+"</b>="+ obj[accessor.@name];
							}catch (e:Error){
								str += "<br><b>"+s+"</b>; ";
							}
						}else{
							str += s+"; ";
						}
					}
				}
				str += "<br><font color=\"#FF0000\"><b>Variables:</b></font> ";
				nodes = V..variable;
				for each (var variable:XML in nodes) {
					s = variable.@name+"("+variable.@type+")";
					if(viewAll){
						try {
							str += "<br><b>"+s+"</b>="+ obj[variable.@name];
						}catch (e:Error){
							str += "<br><b>"+s+"</b>; ";
						}
					}else{
						str += s+"; ";
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
			_mapBases[_mapBaseIndex] = base;
			var basestr:String = _mapBaseIndex+Console.MAPPING_SPLITTER;
			
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
				var n:String = "<a href='event:clip_"+basestr+indexes.join(Console.MAPPING_SPLITTER)+"'>"+mcDO.name+"</a>";
				if(mcDO is DisplayObjectContainer){
					n = "<b>"+n+"</b>";
				}else{
					n = "<i>"+n+"</i>";
				}
				str += n+" ("+getQualifiedClassName(mcDO)+")";
				report(str,mcDO is DisplayObjectContainer?5:2);
				lastmcDO = mcDO;
			}
			_mapBaseIndex++;
			report(base.name+":"+getQualifiedClassName(base)+" has "+list.length+" children/sub-children.", 10);
			report("Click on the name to return a reference to the child clip. <br/>Note that clip references will be broken when display list is changed",-2);
		}
		public function reMap(path:String, mc:DisplayObjectContainer = null):void{
			var pathArr:Array = path.split(Console.MAPPING_SPLITTER);
			if(!mc){
				var first:String = pathArr.shift();
				if(first == "0"){
					mc = _master.stage;
				}else{
					mc = _mapBases[first];
				}
			}
			var child:DisplayObject = mc as DisplayObject;
			try{
				for each(var nn:String in pathArr){
					if(!nn) break;
					child = mc.getChildByName(nn);
					if(child is DisplayObjectContainer){
						mc = child as DisplayObjectContainer;;
					}else{
						// assume it reached to end since there can no longer be a child
						break;
					}
				}
				doReturn(child);
			} catch (e:Error) {
				report("Problem getting the clip reference. Display list must have changed since last map request",10);
				//reportStackTrace(e.getStackTrace());
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
			report("__Filtering:",10);
			report("/filter &lt;text you want to filter&gt;",5);
			report("This will create a new channel called filtered with all matching lines",5);
			report("__Other useful examples:",10);
			report("<b>stage.width</b>",5);
			report("<b>stage.scaleMode = noScale</b>",5);
			report("<b>stage.frameRate = 12</b>",5);
			report("__________",10);
		}
		public function report(obj:*,priority:Number = 1, skipSafe:Boolean = true):void{
			_master.report(obj, priority, skipSafe);
		}
	}
}
class Value{
	// this is a class to remember the base object and property name that holds the value...
	public var base:Object;
	public var prop:String;
	public var value:*;
	
	public function Value(v:* = null, b:Object = null, p:String = null):void{
		base = b;
		prop = p;
		value = v;
	}
}