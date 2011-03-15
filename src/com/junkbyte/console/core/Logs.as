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
	import com.junkbyte.console.vos.Log;

	public class Logs extends ConsoleCore{
		
		private var _channels:Object;
		private var _repeating:uint;
		private var _lastRepeat:Log;
		private var _newRepeat:Log;
		
		public var first:Log;
		public var last:Log;
		
		private var _length:uint;
		
		public function Logs(console:Console){
			super(console);
			_channels = new Object();
		}
		
		public function update():void{
			if(_repeating > 0) _repeating--;
			if(_newRepeat){
				if(_lastRepeat) remove(_lastRepeat);
				_lastRepeat = _newRepeat;
				_newRepeat = null;
				push(_lastRepeat);
			}
		}
		public function add(line:Log):Boolean{
			addChannel(line.ch);
			if (line.repeat) {
				if(_repeating > 0 && _lastRepeat){
					_newRepeat = line;
					return false;
				}else{
					_repeating = config.maxRepeats;
					_lastRepeat = line;
				}
			}
			push(line);
			if(config.maxLines > 0 ){
				var off:int = _length - config.maxLines;
				//shift(off)
				while(off>0 && first){
					if(first == _lastRepeat) _lastRepeat = null;
					first = first.next;
					first.prev = null;
					off--;
					_length--;
				}
			}
			return true;
		}
		public function clear(channel:String = null):void{
			if(channel){
				var line:Log = first;
				while(line){
					if(line.ch == channel){
						remove(line);
					}
					line = line.next;
				}
				delete _channels[channel];
			}else{
				first = null;
				last = null;
				_length = 0;
				_channels = new Object();
			}
		}
		public function getLogsAsString(splitter:String):String{
			var str:String = "";
			var line:Log = first;
			while(line){
				str += line.toString()+(line.next?splitter:"");
				line = line.next;
			}
			return str;
		}
		public function getChannels():Array{
			var arr:Array = new Array(Console.GLOBAL_CHANNEL);
			addIfexist(Console.DEFAULT_CHANNEL, arr);
			addIfexist(Console.FILTER_CHANNEL, arr);
			addIfexist(LogReferences.INSPECTING_CHANNEL, arr);
			addIfexist(Console.CONSOLE_CHANNEL, arr);
			var others:Array = new Array();
			for(var X:String in _channels){
				if(arr.indexOf(X)<0){
					others.push(X);
				}
			}
			return arr.concat(others.sort(Array.CASEINSENSITIVE));
		}
		private function addIfexist(n:String, arr:Array):void{
			if(_channels.hasOwnProperty(n)) arr.push(n);
		}
		public function cleanChannels():void{
			_channels = new Object();
			var line:Log = first;
			while(line){
				addChannel(line.ch);
				line = line.next;
			}
		}
		public function addChannel(n:String):void{
			_channels[n] = null;
		}
		//
		// Log chain controls
		//
		private function push(v:Log):void{
			if(last==null) {
				first = v;
			}else{
				last.next = v;
				v.prev = last;
			}
			last = v;
			_length++;
		}
		/*
		 //Made code for these function part of another function to save compile size.
		 private function pop():void{
			if(last) {
				if(last == _lastRepeat) _lastRepeat = null;
				last = last.prev;
				last.next = null;
				_length--;
			}
		}
		private function shift(count:uint = 1):void{
			while(first != null && count>0){
				if(first == _lastRepeat) _lastRepeat = null;
				first = first.next;
				first.prev = null;
				count--;
				_length--;
			}
		}*/
		private function remove(log:Log):void{
			if(first == log) first = log.next;
			if(last == log) last = log.prev;
			if(log == _lastRepeat) _lastRepeat = null;
			if(log == _newRepeat) _newRepeat = null;
			if(log.next != null) log.next.prev = log.prev;
			if(log.prev != null) log.prev.next = log.next;
			_length--;
		}
	}
}