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
package com.junkbyte.console.core {
	import com.junkbyte.console.utils.ShortClassName;
	import com.junkbyte.console.vos.MonitorValue;
	import com.junkbyte.console.vos.WeakRef;
	
	import flash.events.EventDispatcher;
	import flash.utils.describeType;	

	public class ObjectsMonitor extends EventDispatcher{
		
		private var _list:Object;
		//
		//
		//
		public function ObjectsMonitor() {
			_list = new Object();
		}
		
		public function monitor(obj:Object, n:String = null):void{
			if(!n) n = "0";
			var v:MonitorValue = new MonitorValue();
			v.history.push(new WeakRef(obj, true));
			_list[n] = v;
		}
		public function monitorIn(i:String, n:String):void{
			var v:MonitorValue = _list[i];
			if(!v) return;
			var h:Array = v.history;
			var curref:WeakRef = h[h.length-1];
			var newobj:Object = curref.reference[n];
			if(newobj == null || typeof newobj != "object") {
				return;
			}else{
				curref.strong = false;
				v.history.push(new WeakRef(newobj, true));
			}
		}
		public function monitorOut(i:String):void{
			var v:MonitorValue = _list[i];
			if(!v) return;
			var h:Array = v.history;
			if(h.length<2) return;
			var newref:WeakRef = h[h.length-2];
			if(newref.reference != null){
				newref.strong = true;
				h.pop();
			}
		}
		public function getObject(n:String = null):Object{
			if(!n) n = "0";
			var mv:MonitorValue = _list[n];
			return mv?mv.history[mv.history.length-1].reference:null;
		}
		public function unmonitor(n:String = null):void{
			if(!n) n = "0";
			delete _list[n];
		}
		
		public function update():Object{
			var mvs:Object = {};
			for (var X:String in _list){
				var mv:MonitorValue = _list[X];
				var obj:Object = mv.history[mv.history.length-1].reference;
				var value:Object = {};
				var b:Boolean;
				for (var Y:String in obj){
					b = true;
					value[Y] = getStringOf(obj[Y]);
				}
				if(!b){
					var V:XML = describeType(obj);
					var nodes:XMLList, n:String;
					nodes = V.accessor;
					for each (var accessorX:XML in nodes) {
						if(accessorX.@access!="writeonly"){
							n = accessorX.@name;
							try{
								value[n] = getStringOf(obj[n]);
							}catch(err:Error){}
						}
					}
					nodes = V.variable;
					for each (var variableX:XML in nodes) {
						n = variableX.@name;
						value[n] = getStringOf(obj[n]);
					}
				}
				mv.values = value;
				mvs[X] = value;
			}
			return mvs;
		}
		private function getStringOf(v:*):String{
			var t:String = typeof v;
			if(t == "object" || t =="xml") return "["+ShortClassName(v)+"]";
			t = String(v);
			t = t.length<50?t:(t.substring(0,48)+"...");
			return t.replace(/</gm, "&lt;");
		}
	}
}