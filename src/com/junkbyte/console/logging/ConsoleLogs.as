/*
 *
 * Copyright (c) 2008-2011 Lu Aye Oo
 *
 * @author 		Lu Aye Oo
 *
 * http://code.google.com/p/flash-console/
 * http://junkbyte.com
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
package com.junkbyte.console.logging
{
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.core.ModuleTypeMatcher;
	import com.junkbyte.console.events.ConsoleLogEvent;
	import com.junkbyte.console.interfaces.IRemoter;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.vos.Log;

	import flash.events.Event;
	import flash.utils.ByteArray;

	[Event(name = "entryadded", type = "com.junkbyte.console.events.ConsoleLogEvent")]
	[Event(name = "entriesChanged", type = "com.junkbyte.console.events.ConsoleLogEvent")]
	[Event(name = "channelAdded", type = "com.junkbyte.console.events.ConsoleLogEvent")]
	[Event(name = "channelsChanged", type = "com.junkbyte.console.events.ConsoleLogEvent")]
	public class ConsoleLogs extends ConsoleModule
	{
		public static const CHANNELS_CHANGED:String = "channelsChanged";
		public static const GLOBAL_CHANNEL:String = " * ";
		public static const DEFAULT_CHANNEL:String = "-";
		public static const CONSOLE_CHANNEL:String = "C";
		public static const FILTER_CHANNEL:String = "~";
		public static const INSPECTING_CHANNEL:String = "⌂";
		private var _channels:Object;
		/**
		 * Maximum number of logs Console should remember.
		 * 0 = unlimited. Setting to very high will take up more memory and potentially slow down.
		 */
		public var maxLines:uint = 2000;
		public var first:Log;
		public var last:Log;
		protected var remoter:IRemoter;
		private var _length:uint;

		// private var _lines:uint; // number of lines since start.
		public function ConsoleLogs()
		{
			super();
			_channels = new Object();

			addModuleRegisteryCallback(new ModuleTypeMatcher(IRemoter), onRemoterRegistered, onRemoterUnregistered);
		}

		override public function getModuleName():String
		{
			return ConsoleModuleNames.LOGS;
		}

		protected function onRemoterRegistered(remoter:IRemoter):void
		{
			this.remoter = remoter;
			remoter.addEventListener(Event.CONNECT, onRemoteConnection);
			remoter.registerCallback("log", function(bytes:ByteArray):void
			{
				add(Log.FromBytes(bytes));
			});
			if (remoter.connected)
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

		protected function onRemoteConnection(e:Event = null):void
		{
			var log:Log = first;
			while (log)
			{
				send2Remote(log);
				log = log.next;
			}
		}

		private function send2Remote(line:Log):void
		{
			if (remoter != null && remoter.connected)
			{
				var bytes:ByteArray = new ByteArray();
				line.toBytes(bytes);
				remoter.send("log", bytes);
			}
		}

		public function addEntry(entry:Log):void
		{
			add(entry);

			var event:ConsoleLogEvent = new ConsoleLogEvent(ConsoleLogEvent.ENTRTY_ADDED);
			event.entry = entry;
			dispatchEvent(event);
		}

		public function add(line:Log):void
		{
			addChannel(line.channel);
			send2Remote(line);
			//
			push(line);
			while (_length > maxLines && maxLines > 0)
			{
				remove(first);
			}
			announceLogsChanged();
		}

		public function clear(channel:String = null):void
		{
			if (channel)
			{
				var line:Log = first;
				while (line)
				{
					if (line.channel == channel)
					{
						remove(line);
					}
					line = line.next;
				}
				delete _channels[channel];
			}
			else
			{
				first = null;
				last = null;
				_length = 0;
				_channels = new Object();
			}
			announceChannelChanged();
			announceLogsChanged();
		}

		private function announceChannelChanged():void
		{
			dispatchEvent(new ConsoleLogEvent(ConsoleLogEvent.CHANNELS_CHANGED));
		}

		private function announceLogsChanged():void
		{
			dispatchEvent(new ConsoleLogEvent(ConsoleLogEvent.ENTRIES_CHANGED));
		}

		public function getAllLog(splitter:String = "\r\n"):String
		{
			return getLogsAsString(splitter);
		}

		public function getLogsAsString(splitter:String, incChNames:Boolean = true, filter:Function = null):String
		{
			var str:String = "";
			var line:Log = first;
			while (line)
			{
				if (filter == null || filter(line))
				{
					if (first != line)
					{
						str += splitter;
					}
					str += incChNames ? line.toString() : line.plainText();
				}
				line = line.next;
			}
			return str;
		}

		public function getChannels():Array
		{
			var arr:Array = new Array(GLOBAL_CHANNEL);
			addIfexist(DEFAULT_CHANNEL, arr);
			addIfexist(FILTER_CHANNEL, arr);
			addIfexist(INSPECTING_CHANNEL, arr);
			addIfexist(CONSOLE_CHANNEL, arr);
			var others:Array = new Array();
			for (var X:String in _channels)
			{
				if (arr.indexOf(X) < 0)
				{
					others.push(X);
				}
			}
			return arr.concat(others.sort(Array.CASEINSENSITIVE));
		}

		private function addIfexist(n:String, arr:Array):void
		{
			if (_channels.hasOwnProperty(n))
			{
				arr.push(n);
			}
		}

		public function cleanChannels():void
		{
			_channels = new Object();
			var line:Log = first;
			while (line)
			{
				addChannel(line.channel);
				line = line.next;
			}
		}

		public function addChannel(n:String):void
		{
			if (_channels[n] === undefined)
			{
				_channels[n] = null;
				announceChannelChanged();
			}
		}

		//
		// Log chain controls
		//
		private function push(v:Log):void
		{
			if (last == null)
			{
				first = v;
			}
			else
			{
				last.next = v;
				v.prev = last;
			}
			last = v;
			_length++;
		}

		/*
		// Made code for these function part of another function to save compile size.
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
		private function remove(log:Log):void
		{
			if (first == log)
			{
				first = log.next;
			}
			if (last == log)
			{
				last = log.prev;
			}
			if (log.next != null)
			{
				log.next.prev = log.prev;
			}
			if (log.prev != null)
			{
				log.prev.next = log.next;
			}
			_length--;
		}
	}
}
