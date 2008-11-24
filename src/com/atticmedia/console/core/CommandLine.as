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
package com.atticmedia.console.core{
	import flash.display.*;
	import flash.utils.getDefinitionByName;
	import flash.utils.*;
	import flash.events.*;
	public class CommandLine extends EventDispatcher {

		public static const SEARCH_REQUEST:String = "SearchRequest";
		
		private var _saved:Weak;
		private var _lastSearchTerm:String;
		private var _reportFunction:Function;
		
		public var reserved:Array;

		public function CommandLine(base:Object, reportFunction:Function = null) {
			_reportFunction = reportFunction;
			_saved = new Weak();
			_saved.set("_base",base);
			_saved.set("returned",base);
			reserved = new Array("_base", "returned","_lastMapBase");
		}
		public function set base(obj:Object):void {
			var old:Object = _saved.get("_base");
			_saved.set("_base",obj);
			if (old) {
				report("Set new commandLine base from "+old+ " to "+ obj, 10);
			}else{
				_saved.set("returned",obj);
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
		public function store(n:String, obj:Object):String {
			n = n.replace(/[^\w]*/g, "");
			if(reserved.indexOf(n)>=0){
				report("ERROR: The name ["+n+ "] is reserved",10);
				return null;
			}else{
				// if it is a function it needs to be strong reference atm, 
				// otherwise it fails if the function passed is from a dynamic class/instance
				_saved.set(n, obj, (obj is Function?true:false));
			}
			return n;
		}
		public function get searchTerm():String{
			return _lastSearchTerm;
		}
		public function run(str:String):void {
			report("&gt; "+str, 0);
			var line:Array = str.split(" ");
			var len:int = line.length;
			if (line[0] == "/help") {
				printHelp();
			} else if (line[0] == "/remap") {
				// this is a special case... no user will be able to do this command
				line.shift();
				reMap(line.join(""));
			} else if (line[0] == "/save") {
				if (_saved.get("returned")) {
					if(reserved.indexOf(line[1])>=0){
						report("ERROR: The name ["+line[1]+ "] is reserved",10);
					}else{
						_saved.set(line[1], _saved.get("returned"));
						report("SAVED "+_saved.get("returned") + " at "+ line[1]);
					}
				} else {
					report("Nothing to save", 10);
				}
			} else if (line[0] == "/filter") {
				_lastSearchTerm = str.substring(8);
				dispatchEvent(new Event(SEARCH_REQUEST));
			} else if (line[0] == "/inspect" || line[0] == "/inspectfull") {
				if (_saved.get("returned")) {
					var viewAll:Boolean = (line[0] == "/inspectall")? true: false;
					report(inspect(_saved.get("returned"),viewAll));
				} else {
					report("Empty", 10);
				}
			} else if (line[0] == "/map") {
				if (_saved.get("returned")) {
					map(_saved.get("returned") as DisplayObjectContainer);
				} else {
					report("Empty", 10);
				}
			} else if (line[0] == "/base") {
				var b:Object = _saved.get("_base");
				_saved.set("returned", b);
				report("Returned "+ getQualifiedClassName(b) +": "+b,10);
			} else {
				var base:Object = _saved.get("returned");
				var tree:Array = new Array(base);
				var SET:Object;
				var isSaving:Boolean = false;
				try {
					for (var i:int=0; i<len; i++) {
						var part:String = line[i];
						var funIndex:int = part.indexOf("(");
						var funIndex2:int = part.indexOf(")");
						if (part == "this" && !isSaving) {
							base = _saved.get("_base");
						} else if (part.charAt(0)=="*") {
							base = getDefinitionByName(part.substring(1));
							tree.push(base);
						} else if (part.charAt(0)=="$" && funIndex<0) {
							if (isSaving) {
								SET = _saved.get(part.substring(1));
								tree[tree.length-2][line[i-2]] = SET;
								report("SET "+tree[tree.length-2]+"."+line[i-2]+ " @ $"+SET, 10);
								break;
							} else {
								base = _saved.get(part.substring(1));
								tree.push(base);
							}
						} else if (part == "=") {
							isSaving = true;
						} else if ( funIndex > 0 ) {
							//
							//
							//
							var fun:Function;
							var funstr:String = part.substring(0,funIndex);
							if (funstr.charAt(0) == "$") {
								fun = _saved.get(funstr.substring(1)) as Function;
							}else{
								fun = base[funstr];
							}
							var funArgs:Array = new Array();
							if((funIndex+1) != funIndex2){
								funArgs = part.substring(funIndex+1,funIndex2).split(",");
								for(var X:String in funArgs){
									funArgs[X] = reType(funArgs[X]);
								}
							}
							report("Run: "+base + "."+funstr+"("+funArgs+")",0);
							base = fun.apply(base,funArgs);
							tree.push(base);
							//
							//
							//
						} else {
							if (isSaving) {
								SET = line[i];
								SET = reType(SET);
								tree[tree.length-2][line[i-2]] = SET;
								report("SET "+tree[tree.length-2]+"."+line[i-2]+ " = "+SET, 10);
								break;
							} else {
								if (base[line[i]] == undefined) {
									report("[<b>"+line[i]+"</b>] doesn't exist in <b>"+base+"</b>.", 10);
									base = null;
									break;
								}
								base = base[line[i]];
								tree.push(base);
							}
						}
					}
				} catch (e:Error) {
					report(e.getStackTrace(),10);
					base = null;
				}
				if (base != null && !isSaving) {
					if(typeof(base) == "object"){
						_saved.set("returned", base);
					}
					report("Returned "+ getQualifiedClassName(base) +": "+base,10);
				} else {
					_saved.set("returned", null);
				}
			}
		}
		private function reType(str:Object):Object{
			if (str == "true") {
				str = true;
			}else if (str == "false") {
				str = false;
			}else if (!isNaN(Number(str))) {
				str = Number(str);
			}else if (str == "null") {
				str = null;
			}else if (str == "this") {
				str = _saved.get("_base");
			}else if ((str as String).charAt(0) == "$") {
				str =  _saved.get((str as String).substring(1));
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
				for (var X in obj) {
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
			_saved.set("_lastMapBase", base); 
			
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
			for (var X in list){
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
				report(str,mcDO is DisplayObjectContainer?5:2);
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
				_saved.set("returned", child);
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
			report("root.oObj => <b>oObj</b>",5);
			report("(save obj reference) => <b>/save obj1</b>",5);
			report("(load obj reference) => <b>$obj1</b>",5);
			report("root.oObj2.myProperty => <b>oObj2 myProperty</b>",5);
			report("root.oObj2.myProperty = oObj => <b>oObj2 myProperty = $obj1</b>",5);
			report("(view info) => <b>/inspect obj1</b>",5);
			report("(view all info) => <b>/inspectfull obj2</b>",5);
			report("(see display map) => <b>/map</b>",5);
			report("__Use * to access static classes",10);
			report("com.atticmedia.console.C => <b>*com.atticmedia.console.C</b>",5);
			report("(save reference) => <b>/save c</b>",5);
			report("com.atticmedia.console.C.add('test',10) => <b>$c add(test,10)</b>",5);
			report("__Other useful examples:",10);
			report("<b>stage width</b>",5);
			report("<b>stage scaleMode = noScale</b>",5);
			report("<b>stage frameRate = 12</b>",5);
			report("",0);
			report("__________",10);
		}
		private function report(txt:String, prio:Number=5):void {
			if (_reportFunction != null) {
				_reportFunction(new LogLineVO(txt,null,prio,false,true));
			} else {
				trace("C: "+ txt);
			}
		}
	}
}