package com.atticmedia.console.core {
	import flash.utils.getTimer;	
	import flash.events.*; 
	import flash.system.System;
	import flash.utils.Dictionary;

	public class MemoryMonitor extends EventDispatcher{
		
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
		public function watch(obj:Object, n:String = null):void{
			
			if(!n){
				n = String(obj)+"@"+getTimer();
			}
			
			if(_objectsList[obj]){
				//c.ch("C","'"+obj+"' is already watched by GarbageMonitor for '"+_objectsList[obj]+"'. Replaced!",10);
				
				if(_namesList[_objectsList[obj]]){
					unwatch(_objectsList[obj]);
				}
			}
			if(_namesList[n] && _objectsList[obj] != n){
				var nn:String = n+"@"+getTimer()+"_"+Math.floor(Math.random()*100);
				//c.ch("C","'"+n+"' is already used in GarbageMonitor. Used new name: '"+nn+"'!",10);
				n = nn;
			}
			_namesList[n] = true;
			_objectsList[obj] = n;
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