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
	import com.junkbyte.console.modules.ConsoleModuleNames;

	public class ConsoleLogger extends ConsoleModule
	{
		private var _processor:ConsoleLogProcessors;

		protected var defaultLogEntryClass:Class;

		private var _logs:Logs;

		public function ConsoleLogger()
		{
			super();

			defaultLogEntryClass = LogEntry;

			_processor = createProcessor();

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
			modules.registerModule(new Logs());
		}

		protected function listenForLogsRegistery():void
		{
			addModuleRegisteryCallback(new ModuleTypeMatcher(Logs), onLogsRegistered);
		}

		// this is so that if anyone wants to extend Logs and register it, it'll catch that new module as replacement.
		protected function onLogsRegistered(logs:Logs):void
		{
			if (logs != null)
			{
				_logs = logs;
			}
		}

		public function get logs():Logs
		{
			return _logs;
		}

		protected function createProcessor():ConsoleLogProcessors
		{
			return new ConsoleLogProcessors();
		}

		public function get processor():ConsoleLogProcessors
		{
			return _processor;
		}

		public function log(... strings):void
		{
			addEntry(new defaultLogEntryClass(strings, null, ConsoleLevel.LOG));
		}

		public function info(... strings):void
		{
			addEntry(new defaultLogEntryClass(strings, null, ConsoleLevel.INFO));
		}


		public function logch(channel:*, ... strings):void
		{
			addEntry(new defaultLogEntryClass(strings, channel, ConsoleLevel.LOG));
		}

		public function infoch(channel:*, ... strings):void
		{
			addEntry(new defaultLogEntryClass(strings, channel, ConsoleLevel.INFO));
		}

		public function addHTML(... strings):void
		{
			addEntry(new HTMLLogEntry(strings, null, ConsoleLevel.INFO));
		}

		public function addHTMLch(channel:*, priority:int, ... strings):void
		{
			addEntry(new HTMLLogEntry(strings, channel, priority));
		}

		public function addLine(strings:Array, priority:int = 0, channel:* = null, isRepeating:Boolean = false, html:Boolean = false, stacks:int = -1):void
		{
			addEntry(new defaultLogEntryClass(strings, channel, priority));
		}

		public function addEntry(entry:LogEntry):void
		{
			entry.setOutputUsingProcessor(processor);
			logs.addEntry(entry);
		}

		public function makeString(input:*):String
		{
			return processor.makeString(input);
		}

		//
		//
		override public function report(obj:* = '', priority:int = 0, skipSafe:Boolean = true, channel:String = null):void
		{
			if (!channel)
			{
				channel = console.mainPanel.traces.reportChannel;
			}
			addLine([ obj ], priority, channel, false, skipSafe, 0);
		}
	}
}
