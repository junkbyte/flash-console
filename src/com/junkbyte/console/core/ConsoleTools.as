/*
* 
* Copyright (c) 2008-2010 Lu Aye Oo
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
package com.junkbyte.console.core 
{
	import flash.utils.ByteArray;
	import flash.utils.describeType;
	import com.junkbyte.console.Cc;
	import flash.utils.getQualifiedClassName;
	import com.junkbyte.console.Console;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;

	public class ConsoleTools extends ConsoleCore{
		
		public function ConsoleTools(console:Console) {
			super(console);
		}
		public function map(base:DisplayObjectContainer, maxstep:uint = 0, ch:String = null):void{
			if(!base){
				report("Not a DisplayObjectContainer.", 10, true, ch);
				return;
			}
			
			var steps:int = 0;
			var wasHiding:Boolean;
			var index:int = 0;
			var lastmcDO:DisplayObject = null;
			var list:Array = new Array();
			list.push(base);
			while(index<list.length){
				var mcDO:DisplayObject = list[index];
				index++;
				// add children to list
				if(mcDO is DisplayObjectContainer){
					var mc:DisplayObjectContainer = mcDO as DisplayObjectContainer;
					var numC:int = mc.numChildren;
					for(var i:int = 0;i<numC;i++){
						var child:DisplayObject = mc.getChildAt(i);
						list.splice(index+i,0,child);
					}
				}
				// figure out the depth and print it out.
				if(lastmcDO){
					if(lastmcDO is DisplayObjectContainer && (lastmcDO as DisplayObjectContainer).contains(mcDO)){
						steps++;
					}else{
						while(lastmcDO){
							lastmcDO = lastmcDO.parent;
							if(lastmcDO is DisplayObjectContainer){
								if(steps>0){
									steps--;
								}
								if((lastmcDO as DisplayObjectContainer).contains(mcDO)){
									steps++;
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
					var ind:uint = console.refs.setLogRef(mcDO);
					var n:String = mcDO.name;
					if(ind) n = "<a href='event:cl_"+ind+"'>"+n+"</a>";
					if(mcDO is DisplayObjectContainer){
						n = "<b>"+n+"</b>";
					}else{
						n = "<i>"+n+"</i>";
					}
					str += n+" "+console.refs.makeRefTyped(mcDO);
					report(str,mcDO is DisplayObjectContainer?5:2, true, ch);
				}else if(!wasHiding){
					wasHiding = true;
					report(str+"...",5, true, ch);
				}
				lastmcDO = mcDO;
			}
			report(base.name + ":" + console.refs.makeRefTyped(base) + " has " + (list.length - 1) + " children/sub-children.", 9, true, ch);
			if (config.commandLineAllowed) report("Click on the child display's name to set scope.", -2, true, ch);
		}
		
		
		public function explode(obj:Object, depth:int = 3, p:int = 9):String{
			var t:String = typeof obj;
			if(obj == null){ 
				// could be null, undefined, NaN, 0, etc. all should be printed as is
				return "<p-2>"+obj+"</p-2>";
			}else if(obj is String){
				return '"'+LogReferences.EscHTML(obj as String)+'"';
			}else if(t != "object" || depth == 0 || obj is ByteArray){
				return console.refs.makeString(obj);
			}
			if(p<0) p = 0;
			var V:XML = describeType(obj);
			var nodes:XMLList, n:String;
			var list:Array = [];
			//
			nodes = V["accessor"];
			for each (var accessorX:XML in nodes) {
				n = accessorX.@name;
				if(accessorX.@access!="writeonly"){
					try{
						list.push(stepExp(obj, n, depth, p));
					}catch(e:Error){}
				}else{
					list.push(n);
				}
			}
			//
			nodes = V["variable"];
			for each (var variableX:XML in nodes) {
				n = variableX.@name;
				list.push(stepExp(obj, n, depth, p));
			}
			//
			try{
				for (var X:String in obj) {
					list.push(stepExp(obj, X, depth, p));
				}
			}catch(e:Error){}
			return "<p"+p+">{"+LogReferences.ShortClassName(obj)+"</p"+p+"> "+list.join(", ")+"<p"+p+">}</p"+p+">";
		}
		private function stepExp(o:*, n:String, d:int, p:int):String{
			return n+":"+explode(o[n], d-1, p-1);
		}
		
		public function getStack(depth:int, priority:int):String{
			var e:Error = new Error();
			var str:String = e.hasOwnProperty("getStackTrace")?e.getStackTrace():null;
			if(!str) return "";
			var txt:String = "";
			var lines:Array = str.split(/\n\sat\s/);
			var len:int = lines.length;
			var reg:RegExp = new RegExp("Function|"+getQualifiedClassName(Console)+"|"+getQualifiedClassName(Cc));
			var found:Boolean = false;
			for (var i:int = 2; i < len; i++){
				if(!found && (lines[i].search(reg) != 0)){
					found = true;
				}
				if(found){
					txt += "\n<p"+priority+"> @ "+lines[i]+"</p"+priority+">";
					if(priority>0) priority--;
					depth--;
					if(depth<=0){
						break;
					}
				}
			}
			return txt;
		}
	}
}