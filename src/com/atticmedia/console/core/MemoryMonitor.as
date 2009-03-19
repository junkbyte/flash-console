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
	import flash.system.System;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;	

	public class MemoryMonitor {
		
		private var _namesList:Object;
		private var _objectsList:Dictionary;
		private var _minMemory:uint;
		private var _maxMemory:uint;
		private var _previousMemory:uint;
		//
		public function MemoryMonitor() {
			_namesList = new Object();
			_objectsList = new Dictionary(true);
		}
		public function watch(obj:Object, n:String = null):String{
			if(!n){
				n = String(obj)+"@"+getTimer();
			}
			if(_objectsList[obj]){
				if(_namesList[_objectsList[obj]]){
					unwatch(_objectsList[obj]);
				}
			}
			if(_namesList[n] && _objectsList[obj] != n){
				var nn:String = n+"@"+getTimer()+"_"+Math.floor(Math.random()*100);
				n = nn;
			}
			_namesList[n] = true;
			_objectsList[obj] = n;
			return n;
		}
		public function unwatch(n:String):void{
			for (var X in _objectsList) {
				if(_objectsList[X] == n){
					delete _objectsList[X];
				}
			}
			delete _namesList[n];
		}
		//
		//
		//
		public function update():Array {
			var m:uint = currentMemory;
			if(m<_minMemory || _minMemory == 0){
				_minMemory = m;
			}
			if(m>_maxMemory){
				_maxMemory = m;
			}
			//
			var arr:Array = new Array();
			var o:Object = new Object();
			for (var X in _objectsList) {
				o[_objectsList[X]] = true;
			}
			for(var Y in _namesList){
				if(!o[Y]){
					arr.push(Y);
					delete _namesList[Y];
				}
			}
			/*
			//
			//this don't seem to be working well..
			if(m<_previousMemory){
				dispatchEvent(new garbageCollected(_previousMemory));
			}
			*/
			_previousMemory = m;
			return arr;
		}
		public function get minMemory():uint {
			return _minMemory;
		}
		public function get maxMemory():uint {
			return _maxMemory;
		}
		public function get currentMemory():uint {
			return System.totalMemory;
		}
		//
		// only works in debugger player version
		//
		public function gc():Boolean {
			if(System["gc"] != null){
				System["gc"]();
				return true;
			}
			return false;
		}
	}
}