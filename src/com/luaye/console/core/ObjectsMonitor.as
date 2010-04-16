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
	import flash.utils.describeType;

	import com.luaye.console.utils.Utils;
	import com.luaye.console.vos.WeakObject;

	import flash.events.EventDispatcher;

	public class ObjectsMonitor extends EventDispatcher{
		
		private var _list:Object;
		//
		//
		//
		public function ObjectsMonitor() {
			_list = new Object();
		}
		
		public function monitor(obj:Object, n:String = null):void{
			if(!n) n = "default";
			_list[n] = obj;
		}
		public function monitorIn(i:String, n:String):void{
			var obj:Object = _list[i];
			obj = obj[n];
			if(obj == null || typeof obj != "object"){
				return;
			}
			_list[i] = obj;
		}
		public function unmonitorById(i:String):void{
			delete _list[i];
		}
		
		public function update():Object{
			var values:Object = {};
			for (var X:String in _list){
				var obj:Object =_list[X];
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
				values[X] = value;
			}
			return values;
		}
		private function getStringOf(v:*):String{
			var t:String = typeof v;
			if(t == "object" || t =="xml") return Utils.shortClassName(v);
			return String(v);
		}
	}
}