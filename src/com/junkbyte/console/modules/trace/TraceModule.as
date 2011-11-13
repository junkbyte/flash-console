package com.junkbyte.console.modules.trace
{
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.core.ModuleNameMatcher;
	import com.junkbyte.console.events.ConsoleLogEvent;
	import com.junkbyte.console.logging.LogEntry;
	import com.junkbyte.console.logging.Logs;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	
	public class TraceModule extends ConsoleModule
	{
		public function TraceModule()
		{
			super();
			
			addModuleRegisteryCallback(new ModuleNameMatcher(ConsoleModuleNames.LOGS), onLogsAdded, onLogsRemoved);
		}
		
		private function onLogsAdded(logs:Logs):void
		{
			logs.addEventListener(ConsoleLogEvent.ENTRTY_ADDED, onLogsEntryAdded);
		}
		
		private function onLogsRemoved(logs:Logs):void
		{
			logs.removeEventListener(ConsoleLogEvent.ENTRTY_ADDED, onLogsEntryAdded);
		}
		
		private function onLogsEntryAdded(event:ConsoleLogEvent):void
		{
			traceCall(event.entry);
		}
		
		protected function traceCall(entry:LogEntry):void
		{
			trace("["+entry.channel+"] "+entry.getPlainOutput());
		};
	}
}