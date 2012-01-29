package com.junkbyte.console.modules.trace
{
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.core.ModuleNameMatcher;
	import com.junkbyte.console.logging.ConsoleLogs;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.vos.Log;

	public class TraceModule extends ConsoleModule
	{
		public function TraceModule()
		{
			super();

			addModuleRegisteryCallback(new ModuleNameMatcher(ConsoleModuleNames.LOGS), onLogsAdded, onLogsRemoved);
		}

		private function onLogsAdded(logs:ConsoleLogs):void
		{
			logs.addEntryAddedCallback(onLogsEntryAdded);
		}

		private function onLogsRemoved(logs:ConsoleLogs):void
		{
			logs.removeEntryAddedCallback(onLogsEntryAdded);
		}

		private function onLogsEntryAdded(entry:Log):void
		{
			traceCall(entry);
		}

		protected function traceCall(entry:Log):void
		{
			trace("[" + entry.channel + "] " + entry.plainText());
		}

	}
}
