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
	import com.junkbyte.console.CLog;
	import com.junkbyte.console.ConsoleLevel;
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.core.ModuleTypeMatcher;
	import com.junkbyte.console.interfaces.IConsoleLogProcessor;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.utils.makeConsoleChannel;
	import com.junkbyte.console.vos.Log;

	public class ConsoleLogger extends ConsoleModule
	{
		
		private var htmlProcessor:HTMLLogProcessor = new HTMLLogProcessor();
		private var _processors:Vector.<IConsoleLogProcessor> = new Vector.<IConsoleLogProcessor>();
		private var _logs:ConsoleLogs;

		public function ConsoleLogger()
		{
			super();

			_processors.push(new StandardLogProcessor());

			listenForLogsRegistery();
		}

		public function registerToStaticCLog():void
		{
			CLog = logger;
		}

		override public function getModuleName():String
		{
			return ConsoleModuleNames.LOGGER;
		}

		override protected function registeredToConsole():void
		{
			super.registeredToConsole();
			initAndRegisterLogsModule();
		}

		protected function initAndRegisterLogsModule():void
		{
			modules.registerModule(new ConsoleLogs());
		}

		protected function listenForLogsRegistery():void
		{
			addModuleRegisteryCallback(new ModuleTypeMatcher(ConsoleLogs), onLogsRegistered);
		}

		// this is so that if anyone wants to extend Logs and register it, it'll catch that new module as replacement.
		protected function onLogsRegistered(logs:ConsoleLogs):void
		{
			if (logs != null)
			{
				_logs = logs;
			}
		}

		public function get logs():ConsoleLogs
		{
			return _logs;
		}

		public function get processor():Vector.<IConsoleLogProcessor>
		{
			return _processors;
		}

		protected function createLogEntry(inputs:Array, channel:String = null, priority:int = 2):Log
		{
			var entry:Log = new Log();
			entry.inputs = inputs;
			entry.channel = channel;
			entry.priority = priority;
			return entry;
		}

		public function log(... strings):void
		{
			addEntry(createLogEntry(strings, null, ConsoleLevel.LOG));
		}

		public function info(... strings):void
		{
			addEntry(createLogEntry(strings, null, ConsoleLevel.INFO));
		}

		public function logch(channel:*, ... strings):void
		{
			addEntry(createLogEntry(strings, channel, ConsoleLevel.LOG));
		}

		public function infoch(channel:*, ... strings):void
		{
			addEntry(createLogEntry(strings, channel, ConsoleLevel.INFO));
		}
		
		public function addHTML(... strings):void
		{
			
		}

		public function addLine(strings:Array, priority:int = 0, channel:* = null, isRepeating:Boolean = false, html:Boolean = false, stacks:int = -1):void
		{
			if(html)
			{
				// TODO...
				var processors:Vector.<IConsoleLogProcessor> = Vector.<IConsoleLogProcessor>([htmlProcessor]);
				processors = processors.concat(_processors);
				addEntryUsingProcessors(createLogEntry(strings, channel, priority), processors);
			}
			else
			{
				addEntry(createLogEntry(strings, channel, priority));
			}
		}

		public function addEntry(entry:Log):void
		{
			addEntryUsingProcessors(entry, _processors);
		}
		
		public function addEntryUsingProcessors(entry:Log, processors:Vector.<IConsoleLogProcessor>):void
		{
			entry.setOutputUsingProcessors(processors);
			entry.channel = makeConsoleChannel(entry.channel);
			addProcessedEntry(entry);
		}

		public function addProcessedEntry(entry:Log):void
		{
			logs.addEntry(entry);
			entry.clearInput();
		}

		public function makeString(input:*):String
		{
			return createLogEntry([input]).makeOutputUsingProcessors(_processors);
		}

		//
		//
		override public function report(obj:* = '', priority:int = 0, skipSafe:Boolean = true, channel:String = null):void
		{
			if (!channel)
			{
				channel = console.mainPanel.traces.reportChannel;
			}
			addLine([obj], priority, channel, false, skipSafe, 0);
		}
	}
}
