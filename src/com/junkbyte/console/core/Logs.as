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
	import com.junkbyte.console.events.ConsoleEvent;
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.interfaces.IRemoter;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.modules.referencing.ConsoleReferencingModule;
	import com.junkbyte.console.utils.makeConsoleChannel;
	import com.junkbyte.console.vos.ConsoleModuleMatch;
	import com.junkbyte.console.vos.Log;
	
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.getQualifiedClassName;

	public class Logs extends ConsoleModule{
		
		public static const CHANNELS_CHANGED:String = "channelsChanged";
		
		public static const GLOBAL_CHANNEL:String = " * ";
		public static const DEFAULT_CHANNEL:String = "-";
		public static const CONSOLE_CHANNEL:String = "C";
		public static const FILTER_CHANNEL:String = "~";
		public static const INSPECTING_CHANNEL:String = "⌂";
		
		private var _channels:Object;
		private var _repeating:uint;
		private var _lastRepeat:Log;
		private var _newRepeat:Log;
		private var _hasNewLog:Boolean;
		private var _hadNewLog:Boolean;
		
		private var first:Log;
		public var last:Log;
		
		protected var remoter:IRemoter;
		protected var refs:ConsoleReferencingModule;
		
		private var _length:uint;
		//private var _lines:uint; // number of lines since start.
		
		public function Logs(){
			super();
			_channels = new Object();
			
			addModuleDependencyCallback(ConsoleModuleMatch.createForClass(IRemoter), onRemoterRegistered, onRemoterUnregistered);
			
			// TODO. tempoary dependency
			addModuleDependencyCallback(ConsoleModuleMatch.createForClass(ConsoleReferencingModule), onRefencerRegistered, onRefencerUnregistered);
		}
		
		override protected function registeredToConsole():void
		{
			super.registeredToConsole();
			console.addEventListener(ConsoleEvent.UPDATE_DATA, update);
		}
		
		override protected function unregisteredFromConsole():void
		{
			super.unregisteredFromConsole();
			console.removeEventListener(ConsoleEvent.UPDATE_DATA, update);
		}
		
		protected function onRemoterRegistered(remoter:IRemoter):void
		{
			this.remoter = remoter;
			remoter.addEventListener(Event.CONNECT, onRemoteConnection);
			remoter.registerCallback("log", function(bytes:ByteArray):void{
				add(Log.FromBytes(bytes));
			});
			if(remoter.connected)
			{
				onRemoteConnection();
			}
		}
		
		protected function onRemoterUnregistered(remoter:IRemoter):void
		{
			remoter.removeEventListener(Event.CONNECT, onRemoteConnection);
			remoter.registerCallback("log", null);
			this.remoter = null;
		}
		
		protected function onRefencerRegistered(ref:ConsoleReferencingModule):void
		{
			refs = ref;
		}
		
		protected function onRefencerUnregistered(ref:ConsoleReferencingModule):void
		{
			refs = null;
		}
		
		protected function onRemoteConnection(e:Event = null):void{
			var log:Log = first;
			while(log){
				send2Remote(log);
				log = log.next;
			}
		}
		
		private function send2Remote(line:Log):void{
			if(remoter != null && remoter.connected) {
				var bytes:ByteArray = new ByteArray();
				line.toBytes(bytes);
				remoter.send("log", bytes);
			}
		}
		
		
		protected function update(event:ConsoleEvent):void
		{
			_hadNewLog = _hasNewLog;
			_hasNewLog = false;
			if(_repeating > 0) _repeating--;
			if(_newRepeat){
				if(_lastRepeat) remove(_lastRepeat);
				_lastRepeat = _newRepeat;
				_newRepeat = null;
				push(_lastRepeat);
			}
		}
		
		public function get newLogsSincesLastUpdate():Boolean
		{
			return _hadNewLog;
		}
		
		public function addLine(strings:Array, priority:int = 0, channel:* = null, isRepeating:Boolean = false, html:Boolean = false, stacks:int = -1):void
		{
			var txt:String = "";
			var len:int = strings.length;
			for (var i:int = 0; i < len; i++)
			{
				txt += (i ? " " : "") + makeString(strings[i], null, html);
			}
			
			if (priority >= config.autoStackPriority && stacks < 0) stacks = config.defaultStackDepth;
			
			if (!html && stacks > 0)
			{
				txt += getStack(stacks, priority);
			}
			add(new Log(txt, makeConsoleChannel(channel), priority, isRepeating, html));
		}

		public function makeString(o:*, prop:* = null, html:Boolean = false, maxlen:int = -1):String
		{
			return refs.makeString(o, prop, html, maxlen);
		}
		
		public function getStack(depth:int, priority:int):String{
			var e:Error = new Error();
			var str:String = e.hasOwnProperty("getStackTrace")?e.getStackTrace():null;
			if(!str) return "";
			var txt:String = "";
			var lines:Array = str.split(/\n\sat\s/);
			var len:int = lines.length;
			var classStrs:Array = new Array("Function", getQualifiedClassName(Console), getQualifiedClassName(Logs));
			
			if(config.stackTraceExitClasses)
			{
				for each(var obj:Object in config.stackTraceExitClasses)
				{
					classStrs.push(getQualifiedClassName(obj));
				}
			}
			
			var reg:RegExp = new RegExp(classStrs.join("|"));
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
		
		public function add(line:Log):void{
			_hasNewLog = true;
			addChannel(line.ch);
			send2Remote(line);
			if (line.repeat) {
				if(_repeating > 0 && _lastRepeat){
					//line.line = _lastRepeat.line;
					_newRepeat = line;
					return;
				}else{
					_repeating = config.maxRepeats;
					_lastRepeat = line;
				}
			}
			//_lines++;
			//line.line = _lines;
			//
			push(line);
			while(_length > config.maxLines && config.maxLines > 0){
				remove(first);
			}
			//
			if ( config.tracing && config.traceCall != null) {
				config.traceCall(line.ch, line.plainText(), line.priority);
			}
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
			announceChannelChanged()
		}
		private function announceChannelChanged():void
		{
			dispatchEvent(new Event(CHANNELS_CHANGED));
		}
		public function getLogsAsString(splitter:String, incChNames:Boolean = true, filter:Function = null):String{
			var str:String = "";
			var line:Log = first;
			while(line){
				if(filter == null || filter(line)){
					if(first != line) str += splitter;
					str += incChNames?line.toString():line.plainText();
				}
				line = line.next;
			}
			return str;
		}
		public function getChannels():Array{
			var arr:Array = new Array(GLOBAL_CHANNEL);
			addIfexist(DEFAULT_CHANNEL, arr);
			addIfexist(FILTER_CHANNEL, arr);
			addIfexist(INSPECTING_CHANNEL, arr);
			addIfexist(CONSOLE_CHANNEL, arr);
			var others:Array = new Array();
			for(var X:String in _channels){
				if(arr.indexOf(X)<0) others.push(X);
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
			if(_channels[n] === undefined)
			{
				_channels[n] = null;
				announceChannelChanged();
			}
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