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
package com.luaye.console.core {
	import com.luaye.console.utils.WeakObject;
	import com.luaye.console.Console;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.utils.getQualifiedClassName;
	import flash.utils.describeType;

	public class CommandTools {
		
		private var _mapBases:WeakObject;
		private var _mapBaseIndex:uint = 1;
		private var _report:Function;
		
		public function CommandTools(f:Function) {
			_report = f;
			_mapBases = new WeakObject();
		}
		public function report(obj:*,priority:Number = 1, skipSafe:Boolean = true):void{
			_report(obj, priority, skipSafe);
		}
		public function inspect(obj:Object, viewAll:Boolean= true):void {
			//
			// Class extends... extendsClass
			// Class implements... implementsInterface
			// constant // statics
			// methods
			// accessors
			// varaibles
			// values
			// EVENTS .. metadata name="Event"
			//
			var V:XML = describeType(obj);
			var cls:Object = obj is Class?obj:obj.constructor;
			var clsV:XML = describeType(cls);
			var self:String = V.@name;
			var str:String = "<b>"+self+"</b>";
			var props:Array = [];
			var props2:Array = [];
			var staticPrefix:String = "<p1><i>[static]</i></p1>";
			var nodes:XMLList;
			if(V.@isDynamic=="true"){
				props.push("dynamic");
			}
			if(V.@isFinal=="true"){
				props.push("final");
			}
			if(V.@isStatic=="true"){
				props.push("static");
			}
			if(props.length > 0){
				str += " <p-1>"+props.join(" | ")+"</p-1>";
			}
			report(str+"<br/>", -2);
			//
			// extends...
			//
			props = [];
			nodes = V.extendsClass;
			for each (var extendX:XML in nodes) {
				props.push(extendX.@type.toString());
				if(!viewAll) break;
			}
			if(props.length){
				report("<p10>Extends:</p10> "+props.join("<p-1> &gt; </p-1>")+"<br/>", 5);
			}
			//
			// implements...
			//
			props = [];
			nodes = V.implementsInterface;
			for each (var implementX:XML in nodes) {
				props.push(implementX.@type.toString());
			}
			if(props.length){
				report("<p10>Implements:</p10> "+props.join("<p-1>; </p-1>")+"<br/>", 5);
			}
			//
			// constants...
			//
			props = [];
			nodes = clsV..constant;
			for each (var constantX:XML in nodes) {
				props.push(constantX.@name+"<p0>("+constantX.@type+")</p0>");
			}
			if(props.length){
				report("<p10>Constants:</p10> "+props.join("<p-1>; </p-1>")+"<br/>", 5);
			}
			//
			// methods
			//
			props = [];
			props2 = [];
			nodes = clsV..method; // '..' to include from <factory>
			for each (var methodX:XML in nodes) {
				var mparamsList:XMLList = methodX.parameter;
				str = methodX.parent().name()=="factory"?"":staticPrefix;
				if(viewAll){
					var params:Array = [];
					for each(var paraX:XML in mparamsList){
						params.push(paraX.@optional=="true"?("<i>"+paraX.@type+"</i>"):paraX.@type);
					}
					str += methodX.@name+"<p0>(<i>"+params.join(",")+"</i>):"+methodX.@returnType+"</p0>";
				}else{
					str += methodX.@name+"<p0>(<i>"+mparamsList.length()+"</i>):"+methodX.@returnType+"</p0>";
				}
				arr = (self==methodX.@declaredBy?props:props2);
				arr.push(str);
			}
			makeInheritLine(props, props2, viewAll, "Methods", viewAll?"<br/>":"<p-1>; </p-1>");
			//
			// accessors
			//
			var arr:Array;
			props = [];
			props2 = [];
			nodes = clsV..accessor; // '..' to include from <factory>
			for each (var accessorX:XML in nodes) {
				str = accessorX.parent().name()=="factory"?"":staticPrefix;
				str += (accessorX.@access=="readonly"?("<i>"+accessorX.@name+"</i>"):accessorX.@name)+"<p0>("+accessorX.@type+")</p0>";
				arr = (self==accessorX.@declaredBy?props:props2);
				arr.push(str);
			}
			makeInheritLine(props, props2, viewAll, "Accessors", "<p-1>; </p-1>");
			//
			// variables
			//
			props = [];
			nodes = clsV..variable;
			for each (var variableX:XML in nodes) {
				str = (variableX.parent().name()=="factory"?"":staticPrefix)+variableX.@name+"<p0>("+variableX.@type+")</p0>";
				props.push(str);
			}
			if(props.length){
				report("<p10>Variables:</p10> "+props.join("<p-1>; </p-1>")+"<br/>", 5);
			}
			//
			// dynamic values
			//
			props = [];
			for (var X:String in obj) {
				props.push(X+"<p0>("+getQualifiedClassName(obj[X])+")</p0>");
			}
			if(props.length){
				report("<p10>Values:</p10> "+props.join("<p-1>; </p-1>")+"<br/>", 5);
			}
			//
			// events
			// metadata name="Event"
			props = [];
			nodes = V.metadata;
			for each (var metadataX:XML in nodes) {
				if(metadataX.@name=="Event"){
					var mn:XMLList = metadataX.arg;
					props.push(mn.(@key=="name").@value+"<p0>("+mn.(@key=="type").@value+")</p0>");
				}
			}
			if(props.length){
				report("<p10>Events:</p10> "+props.join("<p-1>; </p-1>")+"<br/>", 5);
			}
			//
			// display's parents and direct children
			//
			if (viewAll && obj is DisplayObjectContainer) {
				props = [];
				var mc:DisplayObjectContainer = obj as DisplayObjectContainer;
				var clen:int = mc.numChildren;
				for (var ci:int = 0; ci<clen; ci++) {
					var child:DisplayObject = mc.getChildAt(ci);
					props.push("<b>"+child.name+"</b>:("+ci+")"+getQualifiedClassName(child));
				}
				if(props.length){
					report("<p10>Children:</p10> "+props.join("<p-1>; </p-1>")+"<br/>", 5);
				}
				var theParent:DisplayObjectContainer = mc.parent;
				if (theParent) {
					props = ["("+theParent.getChildIndex(mc)+")"];
					while (theParent) {
						var pr:DisplayObjectContainer = theParent;
						theParent = theParent.parent;
						props.push("<b>"+pr.name+"</b>:("+(theParent?theParent.getChildIndex(pr):"")+")"+getQualifiedClassName(pr));
					}
					if(props.length){
						report("<p10>Parents:</p10> "+props.join("<p-1>; </p-1>")+"<br/>", 5);
					}
				}
			}
			if(!viewAll){
				report("Tip: use /inspectfull to see full inspection with inheritance",-1);
			}
		}
		private function makeInheritLine(props:Array, props2:Array, viewAll:Boolean, type:String, breaker:String):void{
			var str:String = "";
			if(props.length || props2.length){
				str += "<p10>"+type+":</p10> "+props.join(breaker);
				if(viewAll){
					str += (props.length?breaker:"")+"<p2>"+props2.join(breaker)+"</p2>";
				}else if(props2.length){
					str += (props.length?breaker:"")+"<p2>+ "+props2.length+" inherited</p2>";
				}
				report(str+"<br/>", 5);
			}
		}
		public function map(base:DisplayObjectContainer, maxstep:uint = 0):void{
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
			var wasHiding:Boolean;
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
				if(maxstep<=0 || steps<=maxstep){
					wasHiding = false;
					var n:String = "<a href='event:clip_"+basestr+indexes.join(Console.MAPPING_SPLITTER)+"'>"+mcDO.name+"</a>";
					if(mcDO is DisplayObjectContainer){
						n = "<b>"+n+"</b>";
					}else{
						n = "<i>"+n+"</i>";
					}
					str += n+" ("+getQualifiedClassName(mcDO)+")";
					report(str,mcDO is DisplayObjectContainer?5:2);
				}else if(!wasHiding){
					wasHiding = true;
					report(str+"...",5);
				}
				lastmcDO = mcDO;
			}
			_mapBaseIndex++;
			report(base.name+":"+getQualifiedClassName(base)+" has "+list.length+" children/sub-children.", 10);
			report("Click on the name to return a reference to the child clip. <br/>Note that clip references will be broken when display list is changed",-2);
		}
		public function reMap(path:String, mc:DisplayObjectContainer):DisplayObject{
			var pathArr:Array = path.split(Console.MAPPING_SPLITTER);
			var first:String = pathArr.shift();
			if(first != "0") mc = _mapBases[first];
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
				return child;
			} catch (e:Error) {
				report("Problem getting the clip reference. Display list must have changed since last map request",10);
				//debug(e.getStackTrace());
			}
			return null;
		}
		public function printHelp():void {
			report("____Command Line Help___",10);
			report("/filter (text) = filter/search logs for matching text",5);
			report("// = return to previous scope",5);
			report("/base = return to base scope (same as typing $base)",5);
			report("/store (name) = store current scope to that name (default is weak reference). to call back: $(name)",5);
			report("/savestrong (name) = store current scope as strong reference",5);
			report("/stored = list all stored variables",5);
			report("/inspect = get info of your current scope.",5);
			report("/inspectfull = get more detailed info of your current scope.",5);
			report("/map = get the display list map starting from your current scope",5);
			report("/strong true = turn on strong referencing, you need to turn this on if you want to start manipulating with instances that are newly created.",5);
			report("/string = return the param of this command as a string. This is useful if you want to paste a block of text to use in commandline.",5);
			report("Press up/down arrow keys to recall previous commands",2);
			report("__Examples:",10);
			report("<b>stage.width</b>",5);
			report("<b>stage.scaleMode = flash.display.StageScaleMode.NO_SCALE</b>",5);
			report("<b>stage.frameRate = 12</b>",5);
			report("__________",10);
		}
	}
}