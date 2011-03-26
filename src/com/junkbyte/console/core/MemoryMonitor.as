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
	import com.junkbyte.console.Console;

	import flash.system.System;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;

	public class MemoryMonitor extends ConsoleCore{
		
		private var _namesList:Object;
		private var _objectsList:Dictionary;
		private var _count:uint;
		//
		//
		public function MemoryMonitor(m:Console) {
			super(m);
			_namesList = new Object();
			_objectsList = new Dictionary(true);
			
			console.remoter.registerCallback("gc", gc);
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
		public function update():void {
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
		
		public function gc():void {
			if(remoter.remoting == Remoting.RECIEVER){
				try{
					//report("Sending garbage collection request to client",-1);
					remoter.send("gc");
				}catch(e:Error){
					report(e,10);
				}
			}else{
				var ok:Boolean;
				try{
					// have to put in brackes cause some compilers will complain.
					if(System["gc"] != null){
						System["gc"]();
						ok = true;
					}
				}catch(e:Error){ }
				
				var str:String = "Manual garbage collection "+(ok?"successful.":"FAILED. You need debugger version of flash player.");
				report(str,(ok?-1:10));
			}
		}
	}
}