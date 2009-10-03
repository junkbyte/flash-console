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
	import flash.events.EventDispatcher;
	import flash.system.System;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;		

	public class MemoryMonitor extends EventDispatcher{
		
		//public static const GARBAGE_COLLECTED:String = "garbageCollected";
		//private static const DUMMY_GARBAGE:String = "_memoryMonitor_dummy_garbage";
		
		private var _namesList:Object;
		private var _objectsList:Dictionary;
		//private var _notifyGC:Boolean;
		//
		//
		public function MemoryMonitor() {
			_namesList = new Object();
			_objectsList = new Dictionary(true);
		}
		public function watch(obj:Object, n:String):String{
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
			for (var X:Object in _objectsList) {
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
			var arr:Array = new Array();
			var o:Object = new Object();
			for (var X:Object in _objectsList) {
				o[_objectsList[X]] = true;
			}
			//var gced:Boolean = false;
			for(var Y:String in _namesList){
				if(!o[Y]){
					//gced = true;
					//if(Y != DUMMY_GARBAGE){
						arr.push(Y);
					//}
					delete _namesList[Y];
				}
			}
			/*if(_notifyGC && gced){
				dispatchEvent(new Event(GARBAGE_COLLECTED));
				seedGCDummy();
			}*/
			return arr;
		}
		/*private function seedGCDummy():void{
			if(!_namesList[DUMMY_GARBAGE]){
				// using MovieClip as dummy garbate as it doenst get collected straight away like others
				watch(new MovieClip(), DUMMY_GARBAGE);
			}
		}
		public function set notifyGC(b:Boolean):void{
			if(_notifyGC != b){
				_notifyGC = b;
				if(b){
					seedGCDummy();
				}else if(!b){
					unwatch(DUMMY_GARBAGE);
				}
			}
		}
		public function get notifyGC():Boolean{
			return _notifyGC;
		}*/
		public function get get():String{
			return getInFormat(format);
		}
		public function getInFormat(preset:int):String{
			var str:String = "";
			switch(preset){
				case 0:
					return ""; // just for speed when turned off
				break;
				case 1:
					str += "<b>"+Math.round(_currentMemory/1048576)+"mb </b> ";
				break;
				case 2:
					str += Math.round(_minMemory/1048576)+"mb-";
					str += "<b>"+Math.round(_currentMemory/1048576)+"mb</b>-";
					str += ""+Math.round(_maxMemory/1048576)+"mb ";
				break;
				case 3:
					str += "<b>"+Math.round(_currentMemory/1024)+"kb </b> ";
				break;
				case 4:
					str += Math.round(_minMemory/1024)+"kb-";
					str += "<b>"+Math.round(_currentMemory/1024)+"kb</b>-";
					str += ""+Math.round(_maxMemory/1024)+"kb ";
				break;
				default:
					return "";
				break;
			}
			return str;
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
