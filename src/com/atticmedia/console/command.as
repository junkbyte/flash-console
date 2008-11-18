/*
* Copyright (c) 2008 Lu Aye Oo (Atticmedia)
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


 * @class Command Line
 * @author Lu
 * @version 0.95
 * @requires AS3
 * 
 * A tool to access properties and methods via command during run time.
 * 
 
 
USAGE: 

//Start functionaly by first assigning the stage's root
command.base = root;


After evey line of command it saves the returned value.
use 'save' to save the return value to your custom named variable.


// referencing to objects, properties and methods
Obj.current=>Obj current
// return Obj's property current
Obj.current= 10=>Obj current = 10
// set property 'current' to 10
Obj.reset()=>Obj reset()
// execute Obj's 'reset()' method
Obj.withParameters(a,b,c)=>Obj withParameters(a,b,c)
//do not use space in arguments


//Classes
com.myPackage.myClass=>*com.myPackage.myClass
// saving and recalling
(save last return)=> save temp
(recall saved 'temp')=>$temp 
( it would return [class myClass] for this example )
(view temp's content) => /inspect temp
(view temp's content including super) => /inspectall temp

Example:
// example here shows with a static class with static methods width and height
// saves current width to variable 'w' and set the width to 640
// then set the height to variable w's value.

*com.atticmedia.console.console
save C
$C width
save w
$C add(CurrentConsoleWidth:,5)
$C add($w,10)
$C width = 640
$C height = $w




TODO:
usage of array
using space in text
*/
package com.atticmedia.console{
	import flash.display.*;
	import flash.utils.getDefinitionByName;
	import flash.utils.*;
	import flash.events.*;
	public class command extends EventDispatcher {

		public static const VERSION:Number = 0.97;
		public static const SEARCH_REQUEST:String = "SearchRequest";
		
		private var _saved:Weak;
		private var _lastSearchTerm:String;
		
		public var reserved:Array;

		public function command(base:Object) {
			_saved = new Weak();
			_saved.set("_base",base);
			_saved.set("returned",base);
			reserved = new Array("_base", "returned","_lastMapBase");
		}
		public function set base(mc:Object):void {
			var old:Object = _saved.get("_base");
			_saved.set("_base",mc);
			if (old) {
				report("Set new commandLine base from "+old+ " to "+ mc, 10);
			} else {
				report("Set new commandLine base to "+ mc, 10);
			}
		}
		public function get base():Object {
			return _saved.get("_base");
		}
		public function destory():void {
			_saved = null;
		}
		public function store(n:String, obj:Object):void {
			if(reserved.indexOf(n)>=0){
				report("ERROR: The name ["+n+ "] is reserved",10);
			}else{
				// if it is a function it needs to be strong reference atm, 
				// otherwise it fails if the function passed is from a dynamic class/instance
				_saved.set(n, obj, (obj is Function?true:false));
			}
		}
		public function get searchTerm():String{
			return _lastSearchTerm;
		}
		public function run(str:String):void {
			report(str, 0);
			var line:Array = str.split(" ");
			var len:int = line.length;
			if (line[0] == "/help") {
				printHelp();
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
			} else if (line[0] == "/inspect" || line[0] == "/inspectall") {
				if (line[1]) {
					_saved.set("returned",_saved.get(line[1]));
				} else if (_saved.get("returned") == null) {
					_saved.set("returned", _saved.get("_base"));
				}
				if (_saved.get("returned")) {
					var viewAll:Boolean = (line[0] == "/inspectall")? true: false;
					report(inspect(_saved.get("returned"),viewAll));
				} else {
					report("Empty", 10);
				}
			}else if (line[0] == "/map") {
				if (line[1]) {
					_saved.set("returned",_saved.get(line[1]));
				} else if (_saved.get("returned") == null) {
					_saved.set("returned", _saved.get("_base"));
				}
				if (_saved.get("returned")) {
					map(_saved.get("returned") as DisplayObjectContainer);
				} else {
					report("Empty", 10);
				}
			} else {
				var base:Object = _saved.get("returned");
				var tree:Array = new Array(base);
				//var base:Object = _saved.get("_base");
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
			
			report("Display map of "+base.name+":"+getQualifiedClassName(base)+"", 10);
			report("Click on the name to return a reference to that clip. <br/>Note that clip references will be broken when display list is changed",-2);
			
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
						indexes.push((lastmcDO as DisplayObjectContainer).getChildIndex(mcDO));
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
									indexes.push((lastmcDO as DisplayObjectContainer).getChildIndex(mcDO));
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
				var n:String = "<a href='event:clip_"+indexes.join(",")+"'>"+mcDO.name+"</a>";
				if(mcDO is DisplayObjectContainer){
					n = "<b>"+n+"</b>";
				}else{
					n = "<i>"+n+"</i>";
				}
				str += n+" ("+getQualifiedClassName(mcDO)+")";
				report(str,mcDO is DisplayObjectContainer?5:2);
				lastmcDO = mcDO;
			}
		}
		public function reportMapClipInfo(path:String):void{
			var mc:DisplayObjectContainer = _saved.get("_lastMapBase") as DisplayObjectContainer;
			var pathArr:Array = path.split(",");
			var child:DisplayObject = mc as DisplayObject;
			try{
				if(path.length>0){
					for each(var ind:int in pathArr){
						child = mc.getChildAt(ind);
						if(child is DisplayObjectContainer){
							mc = mc.getChildAt(ind) as DisplayObjectContainer;
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
			report("root.oObj => <b>root oObj</b>",5);
			report("(save obj reference) => <b>/save obj1</b>",5);
			report("(load obj reference) => <b>$obj1</b>",5);
			report("root.oObj2.myProperty => <b>root oObj2 myProperty</b>",5);
			report("root.oObj2.myProperty = oObj => <b>root oObj2 myProperty = $obj1</b>",5);
			report("(view info of last return) => <b>/inspect</b>",5);
			report("(view all info of last return) => <b>/inspectall</b>",5);
			report("(see display map of last return) => <b>/map</b>",5);
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
			if (c.exists) {
				c.ch("C", txt, prio,false,true);
			} else {
				trace("C: "+ txt);
			}
		}
	}
}