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
package com.junkbyte.console.modules.garbageCollectionMonitor 
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.ConsoleModulesManager;
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.events.ConsoleEvent;

	import flash.events.Event;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;

	public class GarbageCollectionMonitor extends ConsoleModule{
		
		public static const NAME:String = "garbageCollectionMonitor";
		
		private var _namesList:Object;
		private var _objectsList:Dictionary;
		private var _count:uint;
		//
		//
		public function GarbageCollectionMonitor(m:ConsoleModulesManager) {
			super(m);
			_namesList = new Object();
			_objectsList = new Dictionary(true);
		}
		
		override public function registeredToConsole(console:Console):void
		{
			super.registeredToConsole(console);
			console.addEventListener(ConsoleEvent.UPDATE_DATA, update);
		}
	
		override public function getModuleName():String
		{
			return NAME;
		}
		
		public function watch(obj:Object, n:String):String{
			var className:String = getQualifiedClassName(obj);
			if(!n) n = className+"@"+getTimer();
			
			if(_objectsList[obj]){
				if(_namesList[_objectsList[obj]]){
					unwatch(_objectsList[obj]);
				}
			}
			if(_namesList[n]){
				if(_objectsList[obj] == n){
					_count--;
				}else{
					n = n+"@"+getTimer()+"_"+Math.floor(Math.random()*100);
				}
			}
			_namesList[n] = true;
			_count++;
			_objectsList[obj] = n;
			//if(!config.quiet) report("Watching <b>"+className+"</b> as <p5>"+ n +"</p5>.",-1);
			return n;
		}
		public function unwatch(n:String):void{
			for (var X:Object in _objectsList) {
				if(_objectsList[X] == n){
					delete _objectsList[X];
				}
			}
			if(_namesList[n])
			{
				delete _namesList[n];
				_count--;	
			}
		}
		//
		//
		//
		protected function update(event:Event):void {
			if(_count == 0) return;
			var arr:Array = new Array();
			var o:Object = new Object();
			for (var X:Object in _objectsList) {
				o[_objectsList[X]] = true;
			}
			for(var Y:String in _namesList){
				if(!o[Y]){
					arr.push(Y);
					delete _namesList[Y];
					_count--;
				}
			}
			if(arr.length) report("<b>GARBAGE COLLECTED "+arr.length+" item(s): </b>"+arr.join(", "),-2);
		}
		
		public function get count():uint{
			return _count;
		}
	}
}